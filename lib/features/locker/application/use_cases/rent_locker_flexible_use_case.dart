import 'package:smart_laundry_locker/core/errors/failures.dart';
import 'package:smart_laundry_locker/features/locker/domain/repositories/locker_repository.dart';
import 'package:dartz/dartz.dart';

class RentLockerFlexibleUseCase {
  final LockerRepository _repository;

  RentLockerFlexibleUseCase(this._repository);

  Future<Either<Failure, Map<String, dynamic>>> call({
    required String lockerId,
    required String cabinetId,
    String itemType = 'OTHER',
    bool skipPhysicalOpen = false,
    String? voucherId,
  }) async {
    return await _repository.rentLockerFlexible(
      lockerId: lockerId,
      cabinetId: cabinetId,
      itemType: itemType,
      skipPhysicalOpen: skipPhysicalOpen,
      voucherId: voucherId,
    );
  }
}
