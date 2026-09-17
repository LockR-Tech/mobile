import 'package:smart_laundry_locker/features/transactions/domain/entities/transaction.dart';

/// Khớp `WalletTransactionResponse` (payment-service, `GET /api/wallet/transactions`).
///
/// Trước đây model này tự đặt ra field `code`/`walletId`/`orderId` không tồn tại trên
/// backend, và ép `id`/`walletId` về String trong khi backend trả số — mọi request đều
/// throw lúc parse JSON. Viết `fromJson` tay (bỏ `json_serializable`) để khớp đúng những
/// gì backend thật sự trả, không phải cấu trúc tưởng tượng.
class TransactionModel extends Transaction {
  const TransactionModel({
    required super.id,
    super.referenceId,
    super.relatedOrderId,
    super.orderCode,
    required super.amount,
    required super.type,
    required super.source,
    required super.description,
    required super.balanceAfter,
    required super.createdAt,
  });

  factory TransactionModel.fromJson(Map<String, dynamic> json) =>
      TransactionModel(
        id: '${json['id']}',
        referenceId: json['referenceId'] as String?,
        relatedOrderId: _asInt(json['relatedOrderId']),
        orderCode: json['orderCode'] as String?,
        amount: _asDouble(json['amount']) ?? 0,
        type: json['type'] as String? ?? '',
        source: json['source'] as String? ?? '',
        description: json['description'] as String? ?? '',
        balanceAfter: _asDouble(json['balanceAfter']) ?? 0,
        createdAt:
            DateTime.tryParse('${json['createdAt']}')?.toLocal() ??
            DateTime.now(),
      );
}

int? _asInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse('$value');
}

double? _asDouble(dynamic value) {
  if (value == null) return null;
  if (value is double) return value;
  if (value is num) return value.toDouble();
  return double.tryParse('$value');
}
