import 'package:smart_laundry_locker/features/orders/infrastructure/models/order_model.dart';
import 'package:smart_laundry_locker/features/orders/infrastructure/models/responses/orders_response.dart';

/// Remote Data Source: OrderRemoteDataSource
/// Interface định nghĩa các method để fetch order data từ API.
abstract class OrderRemoteDataSource {
  /// GET /orders/me
  Future<OrdersResponse> getMyOrders({
    int page = 1,
    int limit = 10,
    String? status,
    String? orderCode,
    String? userId,
    String? search,
    String? orderBy,
    String? orderDirection,
    String? orderType,
  });

  /// GET /orders/me/:id
  Future<OrderDetailResponse> getMyOrderDetail(String id);

  /// GET /orders/my/active
  Future<List<OrderModel>> getMyActiveOrders();

  /// POST /orders/pay-fee
  Future<double> payOverdueFee(String orderId);

  /// POST /orders/recreate-access-code
  Future<bool> recreateAccessCode(String orderDetailId);
}
