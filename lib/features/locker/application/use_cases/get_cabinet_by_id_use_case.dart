import 'package:smart_laundry_locker/core/errors/failures.dart';
import 'package:smart_laundry_locker/features/locker/domain/entities/cabinet.dart';
import 'package:smart_laundry_locker/features/locker/domain/repositories/locker_repository.dart';
import 'package:dartz/dartz.dart';

class GetCabinetByIdUseCase {
  final LockerRepository _repository;

  GetCabinetByIdUseCase(this._repository);

  Future<Either<Failure, Cabinet>> call(String cabinetId) async {
    return await _repository.getCabinetById(cabinetId);
  }
}
