import 'package:smart_laundry_locker/core/errors/failures.dart';
import 'package:smart_laundry_locker/features/locker/domain/entities/locker_location.dart';
import 'package:smart_laundry_locker/features/locker/domain/repositories/locker_repository.dart';
import 'package:dartz/dartz.dart';

/// Use Case: GetLocationDetailUseCase
/// Lấy chi tiết một location theo ID.
class GetLocationDetailUseCase {
  final LockerRepository _repository;

  GetLocationDetailUseCase(this._repository);

  /// Execute use case
  ///
  /// [id] - ID của location cần lấy
  /// Returns: Either<Failure, LockerLocation>
  Future<Either<Failure, LockerLocation>> call(String id) async {
    if (id.isEmpty) {
      return Left(ValidationFailure('Location ID không được để trống'));
    }
    return await _repository.getLocationById(id);
  }
}
