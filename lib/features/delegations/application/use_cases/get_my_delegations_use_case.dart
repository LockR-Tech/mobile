import 'package:smart_laundry_locker/core/errors/failures.dart';
import 'package:dartz/dartz.dart';
import 'package:smart_laundry_locker/features/delegations/domain/entities/delegation.dart';
import 'package:smart_laundry_locker/features/delegations/domain/repositories/delegation_repository.dart';

class GetMyDelegationsUseCase {
  final DelegationRepository _repository;

  GetMyDelegationsUseCase(this._repository);

  Future<Either<Failure, List<Delegation>>> call() {
    return _repository.getMyDelegations();
  }
}
