import 'package:flutter/material.dart';
import 'package:smart_laundry_locker/features/qr_login/domain/kiosk_qr_payload.dart';
import 'package:smart_laundry_locker/features/qr_login/infrastructure/data_sources/qr_login_remote_datasource.dart';

/// Khách xác nhận đăng nhập kiosk bằng mã QR trên màn hình tủ.
class QrLoginProvider extends ChangeNotifier {
  QrLoginProvider({QrLoginRemoteDataSource? remoteDataSource})
    : _remoteDataSource = remoteDataSource ?? QrLoginRemoteDataSourceImpl();

  final QrLoginRemoteDataSource _remoteDataSource;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  /// Trả kết quả khi server xác nhận; lỗi ⇒ `null` và [error] mang câu báo.
  Future<KioskQrConfirmResult?> confirmKioskLogin(KioskQrPayload payload) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final result = await _remoteDataSource.confirmKioskLogin(payload);
      return result;
    } on KioskQrLoginException catch (e) {
      _error = e.message;
      return null;
    } catch (_) {
      _error = 'Không xác nhận được đăng nhập kiosk. Vui lòng thử lại.';
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
