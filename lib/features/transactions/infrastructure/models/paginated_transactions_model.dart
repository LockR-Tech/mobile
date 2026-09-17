import 'package:smart_laundry_locker/features/transactions/domain/entities/paginated_transactions.dart';
import 'transaction_model.dart';

/// `GET /api/wallet/transactions` trả thẳng một mảng `WalletTransactionResponse`, không
/// phải object `{transactions, total, page, limit}` — backend chưa hỗ trợ phân trang cho
/// endpoint này. Model cũ gọi `.fromJson` trên envelope tưởng tượng đó nên luôn parse ra
/// mảng rỗng. Giờ dựng trực tiếp từ mảng thật ở data source ([TransactionModel.fromList]),
/// coi cả danh sách là một trang duy nhất.
class PaginatedTransactionsModel extends PaginatedTransactions {
  const PaginatedTransactionsModel({
    required List<TransactionModel> transactions,
    required super.total,
    required super.page,
    required super.limit,
  }) : super(transactions: transactions);

  factory PaginatedTransactionsModel.fromList(List<dynamic> items) {
    final transactions = items
        .map((e) => TransactionModel.fromJson(e as Map<String, dynamic>))
        .toList();
    return PaginatedTransactionsModel(
      transactions: transactions,
      total: transactions.length,
      page: 1,
      limit: transactions.length,
    );
  }
}
