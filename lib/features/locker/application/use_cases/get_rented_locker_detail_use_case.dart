import 'package:smart_laundry_locker/core/errors/failures.dart';
import 'package:smart_laundry_locker/features/locker/domain/repositories/locker_repository.dart';
import 'package:dartz/dartz.dart';

class GetRentedLockerDetailUseCase {
  final LockerRepository _repository;

  GetRentedLockerDetailUseCase(this._repository);

  Future<Either<Failure, Map<String, dynamic>>> call(
    String orderDetailId,
  ) async {
    return await _repository.getRentedLockerDetail(orderDetailId);
  }
}
