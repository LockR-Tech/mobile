import 'package:dio/dio.dart';
import 'package:smart_laundry_locker/core/network/dio_client.dart';
import 'package:smart_laundry_locker/features/qr_login/domain/kiosk_qr_payload.dart';
import 'package:smart_laundry_locker/core/l10n/l10n.dart';

/// Kết quả khi server ghi nhận khách đã xác nhận đăng nhập kiosk.
class KioskQrConfirmResult {
  const KioskQrConfirmResult({this.lockerId, this.lockerName});

  final int? lockerId;

  /// Server hiện trả `null`; giữ để hiện tên tủ khi backend bổ sung.
  final String? lockerName;
}

/// Lỗi xác nhận đăng nhập kiosk, [message] đã là câu tiếng Việt cho khách.
class KioskQrLoginException implements Exception {
  const KioskQrLoginException(this.message, {this.code});

  final String message;
  final String? code;

  @override
  String toString() => message;
}

abstract class QrLoginRemoteDataSource {
  /// `POST /api/auth/kiosk/qr-sessions/{sid}/confirm` body `{confirmCode}`.
  Future<KioskQrConfirmResult> confirmKioskLogin(KioskQrPayload payload);
}

class QrLoginRemoteDataSourceImpl implements QrLoginRemoteDataSource {
  QrLoginRemoteDataSourceImpl({Dio? dioOverride})
    : dio = dioOverride ?? DioClient.instance.dio;

  final Dio dio;

  @override
  Future<KioskQrConfirmResult> confirmKioskLogin(KioskQrPayload payload) async {
    try {
      final response = await dio.post<dynamic>(
        '/api/auth/kiosk/qr-sessions/'
        '${Uri.encodeComponent(payload.sessionId)}/confirm',
        data: {'confirmCode': payload.confirmCode},
      );
      final body = response.data;
      final data = body is Map ? body['data'] : null;
      // Không thấy `confirmed: true` thì không báo thành công.
      if (data is! Map || data['confirmed'] != true) {
        throw KioskQrLoginException(
          L10n.current.qlNotConfirmed,
        );
      }
      final lockerId = data['lockerId'];
      final lockerName = data['lockerName']?.toString().trim();
      return KioskQrConfirmResult(
        lockerId: lockerId is num ? lockerId.toInt() : int.tryParse('$lockerId'),
        lockerName: (lockerName == null || lockerName.isEmpty) ? null : lockerName,
      );
    } on DioException catch (error) {
      throw KioskQrLoginException(
        kioskQrErrorMessage(error),
        code: _code(error.response?.data),
      );
    }
  }

  static String? _code(Object? data) =>
      data is Map ? data['code']?.toString() : null;
}

/// Câu báo lỗi theo mã của auth-service (CONTRACTS §1 + phần "THỰC TẾ ĐÃ LÀM").
String kioskQrErrorMessage(DioException error) {
  final data = error.response?.data;
  final code = data is Map ? data['code']?.toString() : null;
  final serverMessage = data is Map && data['message'] is String
      ? (data['message'] as String).trim()
      : '';
  final status = error.response?.statusCode;

  switch (code) {
    case 'KIOSK_QR_EXPIRED':
      return L10n.current.qlExpired;
    case 'KIOSK_QR_ALREADY_USED':
      return L10n.current.qlUsed;
    case 'KIOSK_QR_INVALID':
      // Server ghi rõ còn mấy lần thử / phiên đã huỷ — dùng nguyên câu đó.
      return serverMessage.isNotEmpty
          ? serverMessage
          : L10n.current.qlInvalid;
    case 'AUTH_ACCOUNT_INACTIVE':
      return L10n.current.qlInactive;
    case 'AUTH_REQUIRED':
      return L10n.current.qlSessionExpired;
    case 'KIOSK_QR_RATE_LIMITED':
      return L10n.current.qlTooFast;
  }

  switch (error.type) {
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.sendTimeout:
    case DioExceptionType.receiveTimeout:
    case DioExceptionType.connectionError:
      return L10n.current.qlNoConnection;
    default:
      break;
  }

  if (status == 401) {
    return L10n.current.qlSessionExpired;
  }
  if (status == 404) {
    // 404 không kèm mã nghiệp vụ = máy chủ chưa có tính năng này.
    return L10n.current.qlNotSupported;
  }
  if (serverMessage.isNotEmpty) return serverMessage;
  return L10n.current.qrKioskLoginFailed;
}
