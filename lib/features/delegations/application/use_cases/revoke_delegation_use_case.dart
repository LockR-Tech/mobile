import 'package:smart_laundry_locker/core/errors/failures.dart';
import 'package:dartz/dartz.dart';
import 'package:smart_laundry_locker/features/delegations/domain/entities/delegation.dart';
import 'package:smart_laundry_locker/features/delegations/domain/repositories/delegation_repository.dart';

class RevokeDelegationUseCase {
  final DelegationRepository _repository;

  RevokeDelegationUseCase(this._repository);

  Future<Either<Failure, Delegation>> call(String id) {
    return _repository.revokeDelegation(id);
  }
}
