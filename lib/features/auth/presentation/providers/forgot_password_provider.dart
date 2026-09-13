import 'package:flutter/foundation.dart';
import 'package:smart_laundry_locker/features/auth/application/use_cases/forgot_password_use_case.dart';

/// Trạng thái luồng quên mật khẩu: bước 1 gửi OTP về email,
/// bước 2 nhập OTP + mật khẩu mới.
class ForgotPasswordProvider extends ChangeNotifier {
  final ForgotPasswordUseCase _useCase;

  ForgotPasswordProvider({required ForgotPasswordUseCase useCase})
    : _useCase = useCase;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  /// OTP đã gửi thành công — chuyển sang bước nhập OTP + mật khẩu mới.
  bool _otpSent = false;
  bool get otpSent => _otpSent;

  /// Mật khẩu đã đổi xong — quay về màn đăng nhập.
  bool _resetDone = false;
  bool get resetDone => _resetDone;

  Future<void> sendOtp(String email) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await _useCase.sendOtp(email.trim());
    result.fold(
      (failure) => _error = failure.message,
      (_) => _otpSent = true,
    );
    _isLoading = false;
    notifyListeners();
  }

  Future<void> resetPassword({
    required String email,
    required String otp,
    required String newPassword,
    required String confirmPassword,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await _useCase.resetPassword(
      ResetPasswordParams(
        email: email.trim(),
        otp: otp.trim(),
        newPassword: newPassword,
        confirmPassword: confirmPassword,
      ),
    );
    result.fold(
      (failure) => _error = failure.message,
      (_) => _resetDone = true,
    );
    _isLoading = false;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
