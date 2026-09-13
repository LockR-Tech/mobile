import 'package:dartz/dartz.dart';
import 'package:smart_laundry_locker/core/errors/failures.dart';
import 'package:smart_laundry_locker/features/auth/domain/repositories/auth_repository.dart';

/// Hai bước của luồng quên mật khẩu: gửi OTP về email đã đăng ký,
/// rồi xác thực OTP + đặt mật khẩu mới (backend thu hồi refresh token cũ).
class ForgotPasswordUseCase {
  final AuthRepository _repository;

  ForgotPasswordUseCase(this._repository);

  Future<Either<Failure, bool>> sendOtp(String email) {
    return _repository.sendPasswordResetOtp(email: email);
  }

  Future<Either<Failure, bool>> resetPassword(ResetPasswordParams params) {
    return _repository.resetPassword(
      email: params.email,
      otp: params.otp,
      newPassword: params.newPassword,
      confirmPassword: params.confirmPassword,
    );
  }
}

class ResetPasswordParams {
  final String email;
  final String otp;
  final String newPassword;
  final String confirmPassword;

  const ResetPasswordParams({
    required this.email,
    required this.otp,
    required this.newPassword,
    required this.confirmPassword,
  });
}
