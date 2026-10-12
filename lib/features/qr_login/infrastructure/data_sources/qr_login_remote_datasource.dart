import 'package:dio/dio.dart';
import 'package:smart_laundry_locker/core/network/dio_client.dart';
import 'package:smart_laundry_locker/features/qr_login/domain/kiosk_qr_payload.dart';

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
        throw const KioskQrLoginException(
          'Máy chủ chưa xác nhận đăng nhập kiosk. Vui lòng quét lại mã trên kiosk.',
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
      return 'Mã đăng nhập đã hết hạn. Hãy tạo mã mới trên kiosk rồi quét lại.';
    case 'KIOSK_QR_ALREADY_USED':
      return 'Mã đăng nhập này đã được dùng. Hãy tạo mã mới trên kiosk.';
    case 'KIOSK_QR_INVALID':
      // Server ghi rõ còn mấy lần thử / phiên đã huỷ — dùng nguyên câu đó.
      return serverMessage.isNotEmpty
          ? serverMessage
          : 'Mã đăng nhập kiosk không hợp lệ hoặc đã hết hiệu lực.';
    case 'AUTH_ACCOUNT_INACTIVE':
      return 'Tài khoản của bạn đang bị khoá hoặc chưa kích hoạt nên không đăng nhập kiosk được.';
    case 'AUTH_REQUIRED':
      return 'Phiên đăng nhập trên app đã hết. Vui lòng đăng nhập lại rồi quét mã.';
    case 'KIOSK_QR_RATE_LIMITED':
      return 'Thao tác quá nhanh. Vui lòng thử lại sau ít phút.';
  }

  switch (error.type) {
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.sendTimeout:
    case DioExceptionType.receiveTimeout:
    case DioExceptionType.connectionError:
      return 'Không kết nối được máy chủ. Kiểm tra mạng rồi thử lại.';
    default:
      break;
  }

  if (status == 401) {
    return 'Phiên đăng nhập trên app đã hết. Vui lòng đăng nhập lại rồi quét mã.';
  }
  if (status == 404) {
    // 404 không kèm mã nghiệp vụ = máy chủ chưa có tính năng này.
    return 'Máy chủ chưa hỗ trợ đăng nhập kiosk bằng mã QR. '
        'Vui lòng đăng nhập bằng số điện thoại trên kiosk.';
  }
  if (serverMessage.isNotEmpty) return serverMessage;
  return 'Không xác nhận được đăng nhập kiosk. Vui lòng thử lại.';
}
