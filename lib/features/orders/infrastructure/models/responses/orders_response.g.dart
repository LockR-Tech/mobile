// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'orders_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

OrdersResponse _$OrdersResponseFromJson(Map<String, dynamic> json) =>
    OrdersResponse(
      orders:
          (json['orders'] as List<dynamic>?)
              ?.map((e) => OrderModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      pagination: PaginationData.fromJson(
        json['pagination'] as Map<String, dynamic>,
      ),
    );

Map<String, dynamic> _$OrdersResponseToJson(OrdersResponse instance) =>
    <String, dynamic>{
      'orders': instance.orders.map((e) => e.toJson()).toList(),
      'pagination': instance.pagination.toJson(),
    };

OrderDetailResponse _$OrderDetailResponseFromJson(Map<String, dynamic> json) =>
    OrderDetailResponse(
      order: OrderModel.fromJson(json['order'] as Map<String, dynamic>),
      orderDetails:
          (json['orderDetails'] as List<dynamic>?)
              ?.map((e) => OrderDetailModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );

Map<String, dynamic> _$OrderDetailResponseToJson(
  OrderDetailResponse instance,
) => <String, dynamic>{
  'order': instance.order.toJson(),
  'orderDetails': instance.orderDetails.map((e) => e.toJson()).toList(),
};

ActiveOrdersResponse _$ActiveOrdersResponseFromJson(
  Map<String, dynamic> json,
) => ActiveOrdersResponse(
  orders:
      (json['orders'] as List<dynamic>?)
          ?.map((e) => OrderModel.fromJson(e as Map<String, dynamic>))
          .toList() ??
      [],
);

Map<String, dynamic> _$ActiveOrdersResponseToJson(
  ActiveOrdersResponse instance,
) => <String, dynamic>{
  'orders': instance.orders.map((e) => e.toJson()).toList(),
};

PaginationData _$PaginationDataFromJson(Map<String, dynamic> json) =>
    PaginationData(
      total: (json['total'] as num?)?.toInt() ?? 0,
      page: (json['page'] as num?)?.toInt() ?? 1,
      limit: (json['limit'] as num?)?.toInt() ?? 10,
    );

Map<String, dynamic> _$PaginationDataToJson(PaginationData instance) =>
    <String, dynamic>{
      'total': instance.total,
      'page': instance.page,
      'limit': instance.limit,
    };
