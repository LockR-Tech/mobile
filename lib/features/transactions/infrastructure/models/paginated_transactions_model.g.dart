// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'paginated_transactions_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PaginatedTransactionsModel _$PaginatedTransactionsModelFromJson(
  Map<String, dynamic> json,
) => PaginatedTransactionsModel(
  transactions:
      (json['transactions'] as List<dynamic>?)
          ?.map((e) => TransactionModel.fromJson(e as Map<String, dynamic>))
          .toList() ??
      [],
  total: (json['total'] as num).toInt(),
  page: (json['page'] as num).toInt(),
  limit: (json['limit'] as num).toInt(),
);

Map<String, dynamic> _$PaginatedTransactionsModelToJson(
  PaginatedTransactionsModel instance,
) => <String, dynamic>{
  'total': instance.total,
  'page': instance.page,
  'limit': instance.limit,
  'transactions': instance.transactions.map((e) => e.toJson()).toList(),
};
