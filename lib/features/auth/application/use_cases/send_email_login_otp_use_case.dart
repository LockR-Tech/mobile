import 'package:smart_laundry_locker/core/errors/failures.dart';
import 'package:smart_laundry_locker/features/auth/domain/repositories/auth_repository.dart';
import 'package:dartz/dartz.dart';

class SendEmailLoginOtpUseCase {
  final AuthRepository repository;

  SendEmailLoginOtpUseCase(this.repository);

  Future<Either<Failure, void>> call(String email) {
    return repository.sendEmailLoginOtp(email);
  }
}
