import 'package:smart_laundry_locker/core/errors/failures.dart';
import 'package:dartz/dartz.dart';
import '../entities/paginated_transactions.dart';
import '../entities/spending_stats.dart';

abstract class TransactionRepository {
  Future<Either<Failure, PaginatedTransactions>> getTransactions({
    int page = 1,
    int limit = 10,
    String? fromDate,
    String? toDate,
    String? type,
  });

  Future<Either<Failure, SpendingStats>> getSpendingStats({String period = 'ALL'});
}

