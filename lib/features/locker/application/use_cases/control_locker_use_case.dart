import 'package:smart_laundry_locker/core/errors/failures.dart';
import 'package:smart_laundry_locker/features/locker/domain/repositories/locker_repository.dart';
import 'package:dartz/dartz.dart';

enum LockerControlType { open, close }

class ControlLockerUseCase {
  final LockerRepository _repository;

  ControlLockerUseCase(this._repository);

  Future<Either<Failure, Map<String, dynamic>>> call({
    required String lockerId,
    required LockerControlType type,
  }) {
    if (type == LockerControlType.open) {
      return _repository.openLocker(lockerId);
    }
    return _repository.closeLocker(lockerId);
  }
}
