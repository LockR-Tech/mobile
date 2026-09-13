// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'transaction_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TransactionModel _$TransactionModelFromJson(Map<String, dynamic> json) =>
    TransactionModel(
      id: json['id'] as String,
      code: json['code'] as String,
      walletId: json['walletId'] as String,
      orderId: json['orderId'] as String?,
      amount: (json['amount'] as num).toDouble(),
      type: json['type'] as String,
      description: json['description'] as String,
      balanceAfter: (json['balanceAfter'] as num).toDouble(),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$TransactionModelToJson(TransactionModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'code': instance.code,
      'walletId': instance.walletId,
      'orderId': instance.orderId,
      'amount': instance.amount,
      'type': instance.type,
      'description': instance.description,
      'balanceAfter': instance.balanceAfter,
      'createdAt': instance.createdAt.toIso8601String(),
    };
