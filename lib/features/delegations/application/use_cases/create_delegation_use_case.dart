import 'package:smart_laundry_locker/core/errors/failures.dart';
import 'package:dartz/dartz.dart';
import 'package:smart_laundry_locker/features/delegations/domain/entities/delegation.dart';
import 'package:smart_laundry_locker/features/delegations/domain/repositories/delegation_repository.dart';

class CreateDelegationUseCase {
  final DelegationRepository _repository;

  CreateDelegationUseCase(this._repository);

  Future<Either<Failure, Delegation>> call({
    required String orderId,
    required String delegateeEmail,
  }) {
    return _repository.createDelegation(orderId, delegateeEmail);
  }
}
