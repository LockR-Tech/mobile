import 'transaction.dart';

class PaginatedTransactions {
  final List<Transaction> transactions;
  final int total;
  final int page;
  final int limit;

  const PaginatedTransactions({
    required this.transactions,
    required this.total,
    required this.page,
    required this.limit,
  });
}
