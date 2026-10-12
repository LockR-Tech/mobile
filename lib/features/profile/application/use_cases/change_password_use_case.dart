import 'package:smart_laundry_locker/core/errors/failures.dart';
import 'package:smart_laundry_locker/features/profile/domain/password_change.dart';
import 'package:smart_laundry_locker/features/profile/domain/repositories/profile_repository.dart';
import 'package:dartz/dartz.dart';

class ChangePasswordUseCase {
  final ProfileRepository _repository;

  ChangePasswordUseCase(this._repository);

  Future<Either<Failure, PasswordChangeResult>> call(
    ChangePasswordParams params,
  ) {
    return _repository.changePassword(
      mode: params.mode,
      currentPassword: params.currentPassword,
      newPassword: params.newPassword,
    );
  }
}

class ChangePasswordParams {
  final PasswordFormMode mode;
  final String? currentPassword;
  final String newPassword;

  const ChangePasswordParams({
    required this.mode,
    this.currentPassword,
    required this.newPassword,
  });
}
