import 'package:smart_laundry_locker/core/errors/failures.dart';
import 'package:smart_laundry_locker/features/orders/domain/entities/order.dart';
import 'package:smart_laundry_locker/features/orders/domain/repositories/order_repository.dart';
import 'package:dartz/dartz.dart' hide Order;

/// Use Case: Lấy danh sách đơn hàng đang active
class GetActiveOrdersUseCase {
  final OrderRepository _repository;

  GetActiveOrdersUseCase(this._repository);

  Future<Either<Failure, List<Order>>> call() {
    return _repository.getMyActiveOrders();
  }
}
