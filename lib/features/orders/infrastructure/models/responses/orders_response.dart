import 'package:smart_laundry_locker/features/orders/infrastructure/models/order_model.dart';
import 'package:smart_laundry_locker/features/orders/infrastructure/models/order_detail_model.dart';
import 'package:json_annotation/json_annotation.dart';

part 'orders_response.g.dart';

/// Response wrapper cho danh sách orders (có pagination)
@JsonSerializable(explicitToJson: true)
class OrdersResponse {
  @JsonKey(defaultValue: [])
  final List<OrderModel> orders;
  final PaginationData pagination;

  const OrdersResponse({required this.orders, required this.pagination});

  factory OrdersResponse.fromJson(Map<String, dynamic> json) =>
      _$OrdersResponseFromJson(json);

  Map<String, dynamic> toJson() => _$OrdersResponseToJson(this);
}

/// Response wrapper cho chi tiết order
@JsonSerializable(explicitToJson: true)
class OrderDetailResponse {
  final OrderModel order;
  @JsonKey(defaultValue: [])
  final List<OrderDetailModel> orderDetails;

  const OrderDetailResponse({required this.order, required this.orderDetails});

  factory OrderDetailResponse.fromJson(Map<String, dynamic> json) =>
      _$OrderDetailResponseFromJson(json);

  Map<String, dynamic> toJson() => _$OrderDetailResponseToJson(this);
}

/// Response wrapper cho danh sách orders (không phân trang)
@JsonSerializable(explicitToJson: true)
class ActiveOrdersResponse {
  @JsonKey(defaultValue: [])
  final List<OrderModel> orders;

  const ActiveOrdersResponse({required this.orders});

  factory ActiveOrdersResponse.fromJson(Map<String, dynamic> json) =>
      _$ActiveOrdersResponseFromJson(json);

  Map<String, dynamic> toJson() => _$ActiveOrdersResponseToJson(this);
}

/// Pagination data từ API response
@JsonSerializable()
class PaginationData {
  @JsonKey(defaultValue: 0)
  final int total;
  @JsonKey(defaultValue: 1)
  final int page;
  @JsonKey(defaultValue: 10)
  final int limit;

  const PaginationData({
    required this.total,
    required this.page,
    required this.limit,
  });

  factory PaginationData.fromJson(Map<String, dynamic> json) =>
      _$PaginationDataFromJson(json);

  Map<String, dynamic> toJson() => _$PaginationDataToJson(this);
}
