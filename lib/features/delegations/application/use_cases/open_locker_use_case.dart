import 'package:smart_laundry_locker/core/errors/failures.dart';
import 'package:smart_laundry_locker/features/delegations/domain/repositories/delegation_repository.dart';
import 'package:dartz/dartz.dart';

class OpenLockerUseCase {
  final DelegationRepository _repository;

  OpenLockerUseCase(this._repository);

  Future<Either<Failure, void>> call({required String accessCode}) {
    return _repository.openLocker(accessCode: accessCode);
  }
}
