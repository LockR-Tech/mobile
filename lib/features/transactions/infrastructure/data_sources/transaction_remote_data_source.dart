import '../models/paginated_transactions_model.dart';
import '../models/transaction_model.dart';

abstract class TransactionRemoteDataSource {
  Future<PaginatedTransactionsModel> getTransactions({
    int page = 1,
    int limit = 10,
    String? fromDate,
    String? toDate,
    String? type,
  });

  Future<TransactionModel> getTransactionDetail(String id);
}
