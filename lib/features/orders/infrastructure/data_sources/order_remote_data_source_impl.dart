import 'package:smart_laundry_locker/core/network/api_client.dart';
import 'package:smart_laundry_locker/features/orders/infrastructure/data_sources/order_remote_data_source.dart';
import 'package:smart_laundry_locker/features/orders/infrastructure/models/order_model.dart';
import 'package:smart_laundry_locker/features/orders/infrastructure/models/responses/orders_response.dart';
import 'package:dio/dio.dart';

/// Implementation của OrderRemoteDataSource
/// Sử dụng ApiClient để gọi API endpoints.
class OrderRemoteDataSourceImpl implements OrderRemoteDataSource {
  final ApiClient _apiClient;

  OrderRemoteDataSourceImpl(this._apiClient);

  /// Extract data field từ API response
  /// API trả về format: {statusCode, message, data: {...}}
  Map<String, dynamic> _extractData(Response<dynamic> response) {
    final responseData = response.data as Map<String, dynamic>;
    return responseData['data'] as Map<String, dynamic>? ?? responseData;
  }

  @override
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
  }) async {
    final queryParams = <String, dynamic>{
      'page': page,
      'limit': limit,
      if (status != null && status.isNotEmpty) 'status': status,
      if (orderCode != null && orderCode.isNotEmpty) 'orderCode': orderCode,
      if (userId != null && userId.isNotEmpty) 'userId': userId,
      if (search != null && search.isNotEmpty) 'search': search,
      if (orderBy != null && orderBy.isNotEmpty) 'orderBy': orderBy,
      if (orderDirection != null && orderDirection.isNotEmpty)
        'orderDirection': orderDirection,
      if (orderType != null && orderType.isNotEmpty && orderType != 'ALL')
        'orderType': orderType,
    };

    final response = await _apiClient.get<dynamic>(
      '/orders/me',
      queryParameters: queryParams,
    );

    return OrdersResponse.fromJson(_extractData(response));
  }

  @override
  Future<OrderDetailResponse> getMyOrderDetail(String id) async {
    final response = await _apiClient.get<dynamic>('/orders/me/$id');
    return OrderDetailResponse.fromJson(_extractData(response));
  }

  @override
  Future<List<OrderModel>> getMyActiveOrders() async {
    final response = await _apiClient.get<dynamic>('/orders/my/active');
    final data = _extractData(response);

    // API trả về mảng orders hoặc wrap trong object
    final ordersJson = data['orders'] as List<dynamic>?;
    if (ordersJson != null) {
      return ordersJson
          .map((e) => OrderModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    // Fallback: response data là mảng trực tiếp
    final responseData = response.data;
    if (responseData is Map<String, dynamic>) {
      final dataField = responseData['data'];
      if (dataField is List<dynamic>) {
        return dataField
            .map((e) => OrderModel.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    }

    return [];
  }

  @override
  Future<double> payOverdueFee(String orderId) async {
    final response = await _apiClient.post<dynamic>(
      '/orders/pay-fee',
      data: {'orderId': orderId},
    );
    final data = _extractData(response);

    if (data['success'] == true) {
      return (data['amountPaid'] as num).toDouble();
    }

    throw ServerException(data['message']?.toString() ?? 'Thanh toán thất bại');
  }

  @override
  Future<bool> recreateAccessCode(String orderDetailId) async {
    final response = await _apiClient.post<dynamic>(
      '/orders/recreate-access-code',
      data: {'orderDetailId': orderDetailId},
    );

    // Nếu request thành công, API trả về object access code
    // Dio/ApiClient sẽ quăng exception nếu status code không phải 2xx
    return response.statusCode == 200 || response.statusCode == 201;
  }

}
