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
    );
  }
}

class UpdateProfileParams {
  final String? fullName;
  final String? phoneNumber;

  const UpdateProfileParams({this.fullName, this.phoneNumber});

  factory UpdateProfileParams.fromForm({
    String? fullName,
    String? phoneNumber,
  }) {
    return UpdateProfileParams(fullName: fullName, phoneNumber: phoneNumber);
  }
}
