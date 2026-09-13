import 'package:smart_laundry_locker/features/delegations/domain/entities/delegation.dart';
import 'package:smart_laundry_locker/features/delegations/domain/repositories/delegation_repository.dart';
import 'package:smart_laundry_locker/core/errors/failures.dart';
import 'package:dartz/dartz.dart';

class GetDelegationsByPhoneUseCase {
  final DelegationRepository _repository;

  GetDelegationsByPhoneUseCase(this._repository);

  Future<Either<Failure, List<Delegation>>> call(String phoneNumber) async {
    return await _repository.getDelegationsByPhone(phoneNumber);
  }
}
