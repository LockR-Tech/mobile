import 'package:smart_laundry_locker/core/errors/failures.dart';
import 'package:smart_laundry_locker/features/profile/domain/entities/courier_profile.dart';
import 'package:smart_laundry_locker/features/profile/domain/repositories/profile_repository.dart';
import 'package:dartz/dartz.dart';

class GetCourierProfileUseCase {
  final ProfileRepository _repository;

  GetCourierProfileUseCase(this._repository);

  Future<Either<Failure, CourierProfile>> call(String userId) async {
    return _repository.getCourierProfile(userId);
  }
}
