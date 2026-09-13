import 'package:smart_laundry_locker/core/errors/failures.dart';
import 'package:smart_laundry_locker/features/profile/domain/repositories/profile_repository.dart';
import 'package:dartz/dartz.dart';

class VerifyCurrentPasswordUseCase {
  final ProfileRepository _repository;

  VerifyCurrentPasswordUseCase(this._repository);

  Future<Either<Failure, bool>> call(VerifyCurrentPasswordParams params) async {
    return _repository.verifyCurrentPassword(
      email: params.email,
      currentPassword: params.currentPassword,
    );
  }
}

class VerifyCurrentPasswordParams {
  final String email;
  final String currentPassword;

  const VerifyCurrentPasswordParams({
    required this.email,
    required this.currentPassword,
  });
}
