import 'package:smart_laundry_locker/core/errors/failures.dart';
import 'package:smart_laundry_locker/features/profile/domain/repositories/profile_repository.dart';
import 'package:dartz/dartz.dart';

class ChangePasswordUseCase {
  final ProfileRepository _repository;

  ChangePasswordUseCase(this._repository);

  Future<Either<Failure, bool>> call(ChangePasswordParams params) async {
    return _repository.changePassword(
      email: params.email,
      newPassword: params.newPassword,
    );
  }
}

class ChangePasswordParams {
  final String email;
  final String newPassword;

  const ChangePasswordParams({required this.email, required this.newPassword});
}
