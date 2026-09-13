import 'package:smart_laundry_locker/features/delegations/domain/entities/delegation.dart';
import 'package:smart_laundry_locker/features/orders/infrastructure/models/order_detail_model.dart';
import 'package:json_annotation/json_annotation.dart';

part 'delegation_model.g.dart';

Object? _readId(Map<dynamic, dynamic> json, String key) =>
    json['id'] ?? json['_id'];

DateTime? _parseDateTimeNullable(dynamic value) {
  if (value == null) return null;
  if (value is String) {
    return DateTime.tryParse(value)?.toLocal();
  }
  return null;
}

DateTime _parseDateTime(dynamic value) {
  return _parseDateTimeNullable(value) ?? DateTime.now();
}

/// DelegationModel - Infrastructure model cho Delegation entity
@JsonSerializable()
class DelegationModel {
  @JsonKey(readValue: _readId, defaultValue: '')
  final String id;
  @JsonKey(defaultValue: '')
  final String orderId;
  @JsonKey(defaultValue: '')
  final String orderDetailId;
  final String? delegateeId;
  @JsonKey(fromJson: _parseDateTime)
  final DateTime validFrom;
  @JsonKey(fromJson: _parseDateTime)
  final DateTime validTo;
  @JsonKey(defaultValue: '')
  final String status;
  @JsonKey(fromJson: _parseDateTime)
  final DateTime createdAt;
  @JsonKey(fromJson: _parseDateTime)
  final DateTime updatedAt;
  final String? accessCode;
  final OrderDetailModel? orderDetail;
  @JsonKey(fromJson: _parseDateTimeNullable)
  final DateTime? usedAt;
  @JsonKey(fromJson: _parseDateTimeNullable)
  final DateTime? expiredAt;

  const DelegationModel({
    required this.id,
    required this.orderId,
    required this.orderDetailId,
    this.delegateeId,
    required this.validFrom,
    required this.validTo,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.accessCode,
    this.orderDetail,
    this.usedAt,
    this.expiredAt,
  });

  factory DelegationModel.fromJson(Map<String, dynamic> json) =>
      _$DelegationModelFromJson(json);

  Map<String, dynamic> toJson() => _$DelegationModelToJson(this);

  /// Convert to domain entity
  Delegation toDomain() {
    return Delegation(
      id: id,
      orderId: orderId,
      orderDetailId: orderDetailId,
      delegateeId: delegateeId,
      validFrom: validFrom,
      validTo: validTo,
      status: status,
      createdAt: createdAt,
      updatedAt: updatedAt,
      accessCode: accessCode,
      orderDetail: orderDetail?.toDomain(),
      usedAt: usedAt,
      expiredAt: expiredAt,
    );
  }
}
