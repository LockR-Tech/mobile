import 'package:smart_laundry_locker/core/errors/failures.dart';
import 'package:smart_laundry_locker/features/locker/domain/entities/cabinet.dart';
import 'package:smart_laundry_locker/features/locker/domain/repositories/locker_repository.dart';
import 'package:dartz/dartz.dart';

class GetCustomerCabinetsUseCase {
  final LockerRepository _repository;

  GetCustomerCabinetsUseCase(this._repository);

  Future<Either<Failure, List<Cabinet>>> call(String locationId) async {
    return await _repository.getCustomerCabinets(locationId);
  }
}
