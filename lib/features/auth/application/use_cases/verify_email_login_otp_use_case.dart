import 'package:smart_laundry_locker/core/errors/failures.dart';
import 'package:smart_laundry_locker/features/auth/domain/entities/auth_token_entity.dart';
import 'package:smart_laundry_locker/features/auth/domain/repositories/auth_repository.dart';
import 'package:dartz/dartz.dart';

class VerifyEmailLoginOtpParams {
  final String email;
  final String otp;

  VerifyEmailLoginOtpParams({required this.email, required this.otp});
}

class VerifyEmailLoginOtpUseCase {
  final AuthRepository repository;

  VerifyEmailLoginOtpUseCase(this.repository);

  Future<Either<Failure, AuthTokenEntity>> call(
    VerifyEmailLoginOtpParams params,
  ) {
    return repository.verifyEmailLoginOtp(params.email, params.otp);
  }
}
