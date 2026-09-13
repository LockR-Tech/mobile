import 'package:smart_laundry_locker/core/errors/failures.dart';
import 'package:dartz/dartz.dart';
import '../entities/transaction.dart';
import '../entities/paginated_transactions.dart';

abstract class TransactionRepository {
  Future<Either<Failure, PaginatedTransactions>> getTransactions({
    int page = 1,
    int limit = 10,
    String? fromDate,
    String? toDate,
    String? type,
  });

  Future<Either<Failure, Transaction>> getTransactionDetail(String id);
}
