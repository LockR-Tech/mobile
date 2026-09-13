import 'package:smart_laundry_locker/features/orders/domain/repositories/order_repository.dart';
import 'package:smart_laundry_locker/core/errors/failures.dart';
import 'package:dartz/dartz.dart';

class RecreateAccessCodeUseCase {
  final OrderRepository _repository;

  RecreateAccessCodeUseCase(this._repository);

  Future<Either<Failure, bool>> call(String orderDetailId) async {
    return await _repository.recreateAccessCode(orderDetailId);
  }
}
