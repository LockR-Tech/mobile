import 'package:smart_laundry_locker/core/errors/failures.dart';
import 'package:smart_laundry_locker/core/network/api_client.dart';
import 'package:smart_laundry_locker/features/orders/domain/entities/order.dart';
import 'package:smart_laundry_locker/core/domain/entities/pagination.dart';
import 'package:smart_laundry_locker/features/orders/domain/repositories/order_repository.dart';
import 'package:smart_laundry_locker/features/orders/infrastructure/data_sources/order_remote_data_source.dart';
import 'package:dartz/dartz.dart' hide Order;

/// Implementation của OrderRepository
/// Chuyển đổi từ infrastructure models sang domain entities.
class OrderRepositoryImpl implements OrderRepository {
  final OrderRemoteDataSource _remoteDataSource;

  OrderRepositoryImpl(this._remoteDataSource);

  @override
  Future<Either<Failure, PaginatedResult<Order>>> getMyOrders({
    int page = 1,
    int limit = 10,
    String? status,
    String? orderCode,
    String? userId,
    String? search,
    String? orderBy,
    String? orderDirection,
    String? orderType,
  }) async {
    try {
      final response = await _remoteDataSource.getMyOrders(
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

      final orders = response.orders.map((m) => m.toDomain()).toList();
      final pagination = Pagination(
        total: response.pagination.total,
        page: response.pagination.page,
        limit: response.pagination.limit,
      );

      return Right(PaginatedResult(items: orders, pagination: pagination));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on AuthenticationException catch (e) {
      return Left(AuthenticationFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, OrderWithDetails>> getMyOrderDetail(String id) async {
    try {
      final response = await _remoteDataSource.getMyOrderDetail(id);

      final order = response.order.toDomain();
      final details = response.orderDetails.map((m) => m.toDomain()).toList();

      return Right(OrderWithDetails(order: order, orderDetails: details));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on NotFoundException catch (e) {
      return Left(NotFoundFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Order>>> getMyActiveOrders() async {
    try {
      final models = await _remoteDataSource.getMyActiveOrders();
      final orders = models.map((m) => m.toDomain()).toList();
      return Right(orders);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, double>> payOverdueFee(String orderId) async {
    try {
      final amountPaid = await _remoteDataSource.payOverdueFee(orderId);
      return Right(amountPaid);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on AuthenticationException catch (e) {
      return Left(AuthenticationFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> recreateAccessCode(String orderDetailId) async {
    try {
      final success = await _remoteDataSource.recreateAccessCode(orderDetailId);
      return Right(success);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

}
