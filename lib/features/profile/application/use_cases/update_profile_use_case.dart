import 'package:smart_laundry_locker/core/errors/failures.dart';
import 'package:smart_laundry_locker/features/profile/domain/entities/user_profile.dart';
import 'package:smart_laundry_locker/features/profile/domain/repositories/profile_repository.dart';
import 'package:dartz/dartz.dart';

class UpdateProfileUseCase {
  final ProfileRepository _repository;

  UpdateProfileUseCase(this._repository);

  Future<Either<Failure, UserProfile>> call(UpdateProfileParams params) async {
    return await _repository.updateProfile(
      fullName: params.fullName,
      phoneNumber: params.phoneNumber,
      email: params.email,
    );
  }
}

class UpdateProfileParams {
  final String? fullName;
  final String? phoneNumber;
  final String? email;

  const UpdateProfileParams({this.fullName, this.phoneNumber, this.email});

  factory UpdateProfileParams.fromForm({
    String? fullName,
    String? phoneNumber,
    String? email,
  }) {
    return UpdateProfileParams(
      fullName: fullName,
      phoneNumber: phoneNumber,
      email: email,
    );
  }
}
