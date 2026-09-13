import 'package:smart_laundry_locker/core/errors/failures.dart';
import 'package:smart_laundry_locker/features/locker/domain/entities/fixed_rent_entity.dart';
import 'package:smart_laundry_locker/features/locker/domain/repositories/locker_repository.dart';
import 'package:dartz/dartz.dart';

class FixedRentUseCase {
  final LockerRepository _repository;

  FixedRentUseCase(this._repository);

  Future<Either<Failure, FixedRentEntity>> call({
    required String cabinetId,
    required String lockerId,
    required int rentMonths,
    int? rentDays,
    String itemType = 'OTHER',
    bool skipPhysicalOpen = false,
    String? voucherId,
  }) {
    return _repository.fixedRentLocker(
      cabinetId: cabinetId,
      lockerId: lockerId,
      rentMonths: rentMonths,
      rentDays: rentDays,
      itemType: itemType,
      skipPhysicalOpen: skipPhysicalOpen,
      voucherId: voucherId,
    );
  }
}
