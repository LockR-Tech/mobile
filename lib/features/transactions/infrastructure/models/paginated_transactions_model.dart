import 'package:smart_laundry_locker/features/transactions/domain/entities/paginated_transactions.dart';
import 'package:json_annotation/json_annotation.dart';
import 'transaction_model.dart';

part 'paginated_transactions_model.g.dart';

@JsonSerializable(explicitToJson: true)
class PaginatedTransactionsModel extends PaginatedTransactions {
  @override
  @JsonKey(name: 'transactions', defaultValue: [])
  final List<TransactionModel> transactions;

  const PaginatedTransactionsModel({
    required this.transactions,
    required super.total,
    required super.page,
    required super.limit,
  }) : super(transactions: transactions);

  factory PaginatedTransactionsModel.fromJson(Map<String, dynamic> json) =>
      _$PaginatedTransactionsModelFromJson(json);

  Map<String, dynamic> toJson() => _$PaginatedTransactionsModelToJson(this);
}
