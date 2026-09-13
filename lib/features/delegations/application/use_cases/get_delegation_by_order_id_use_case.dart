import 'package:smart_laundry_locker/core/errors/failures.dart';
import 'package:dartz/dartz.dart';
import 'package:smart_laundry_locker/features/delegations/domain/entities/delegation.dart';
import 'package:smart_laundry_locker/features/delegations/domain/repositories/delegation_repository.dart';

class GetDelegationByOrderIdUseCase {
  final DelegationRepository _repository;

  GetDelegationByOrderIdUseCase(this._repository);

  Future<Either<Failure, Delegation>> call(String orderId) {
    return _repository.getDelegationByOrderId(orderId);
  }
}
