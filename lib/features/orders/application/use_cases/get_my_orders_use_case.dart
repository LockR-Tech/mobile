import 'package:smart_laundry_locker/core/errors/failures.dart';
import 'package:smart_laundry_locker/features/orders/domain/entities/order.dart';
import 'package:smart_laundry_locker/core/domain/entities/pagination.dart';
import 'package:smart_laundry_locker/features/orders/domain/repositories/order_repository.dart';
import 'package:dartz/dartz.dart' hide Order;

/// Use Case: Lấy danh sách đơn hàng của user hiện tại
class GetMyOrdersUseCase {
  final OrderRepository _repository;

  GetMyOrdersUseCase(this._repository);

  Future<Either<Failure, PaginatedResult<Order>>> call({
    int page = 1,
    int limit = 10,
    String? status,
    String? orderCode,
    String? userId,
    String? search,
    String? orderBy,
    String? orderDirection,
    String? orderType,
  }) {
    return _repository.getMyOrders(
      page: page,
      limit: limit,
      status: status,
      orderCode: orderCode,
      userId: userId,
      search: search,
      orderBy: orderBy,
      orderDirection: orderDirection,
      orderType: orderType,
    );
  }
}
