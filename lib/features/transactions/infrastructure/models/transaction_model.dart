import 'package:smart_laundry_locker/features/transactions/domain/entities/transaction.dart';
import 'package:json_annotation/json_annotation.dart';

part 'transaction_model.g.dart';

@JsonSerializable()
class TransactionModel extends Transaction {
  const TransactionModel({
    required super.id,
    required super.code,
    required super.walletId,
    super.orderId,
    required super.amount,
    required super.type,
    required super.description,
    required super.balanceAfter,
    required super.createdAt,
  });

  factory TransactionModel.fromJson(Map<String, dynamic> json) =>
      TransactionModel(
        id: json['id'] as String,
        code: json['code'] as String,
        walletId: json['walletId'] as String,
        orderId: json['orderId'] as String?,
        amount: (json['amount'] as num).toDouble(),
        type: json['type'] as String,
        description: json['description'] as String,
        balanceAfter: (json['balanceAfter'] as num).toDouble(),
        createdAt: DateTime.parse(json['createdAt'] as String).toLocal(),
      );

  Map<String, dynamic> toJson() => _$TransactionModelToJson(this);
}
