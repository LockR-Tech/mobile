import 'package:smart_laundry_locker/core/errors/failures.dart';
import 'package:smart_laundry_locker/features/orders/domain/repositories/order_repository.dart';
import 'package:dartz/dartz.dart' hide Order;

/// Use Case: Lấy chi tiết một đơn hàng
class GetOrderDetailUseCase {
  final OrderRepository _repository;

  GetOrderDetailUseCase(this._repository);

  Future<Either<Failure, OrderWithDetails>> call(String id) {
    return _repository.getMyOrderDetail(id);
  }
}
