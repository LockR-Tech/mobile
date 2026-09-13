import 'package:smart_laundry_locker/features/profile/domain/entities/user_profile.dart';
import 'package:dartz/dartz.dart';
import 'package:smart_laundry_locker/core/errors/failures.dart';
import 'package:smart_laundry_locker/features/delegations/domain/repositories/delegation_repository.dart';

class FindUserByPhoneUseCase {
  final DelegationRepository _repository;

  FindUserByPhoneUseCase(this._repository);

  Future<Either<Failure, UserProfile?>> call(String phoneNumber) async {
    return await _repository.findUserByPhone(phoneNumber);
  }
}
