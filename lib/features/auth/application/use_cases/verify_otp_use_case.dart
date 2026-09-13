import 'package:dartz/dartz.dart';
import 'package:smart_laundry_locker/core/errors/failures.dart';
import 'package:smart_laundry_locker/features/auth/domain/entities/auth_token_entity.dart';
import 'package:smart_laundry_locker/features/auth/domain/repositories/auth_repository.dart';

class VerifyOtpUseCase {
  final AuthRepository _repository;

  VerifyOtpUseCase(this._repository);

  Future<Either<Failure, AuthTokenEntity>> call(VerifyOtpParams params) {
    return _repository.verifyOtp(
      phoneNumber: params.phoneNumber,
      email: params.email,
      otp: params.otp,
    );
  }
}

class VerifyOtpParams {
  final String? phoneNumber;
  final String? email;
  final String otp;

  const VerifyOtpParams({this.phoneNumber, this.email, required this.otp});

  factory VerifyOtpParams.fromForm({
    String? phoneNumber,
    String? email,
    required String otp,
  }) {
    return VerifyOtpParams(phoneNumber: phoneNumber, email: email, otp: otp);
  }
}
