import '../models/paginated_transactions_model.dart';

abstract class TransactionRemoteDataSource {
  Future<PaginatedTransactionsModel> getTransactions({
    int page = 1,
    int limit = 10,
    String? fromDate,
    String? toDate,
    String? type,
  });
}
