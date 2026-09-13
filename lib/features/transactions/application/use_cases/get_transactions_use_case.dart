import 'package:smart_laundry_locker/core/errors/failures.dart';
import 'package:smart_laundry_locker/features/transactions/domain/entities/paginated_transactions.dart';
import 'package:smart_laundry_locker/features/transactions/domain/repositories/transaction_repository.dart';
import 'package:dartz/dartz.dart';

class GetTransactionsUseCase {
  final TransactionRepository repository;

  GetTransactionsUseCase(this.repository);

  Future<Either<Failure, PaginatedTransactions>> call({
    int page = 1,
    int limit = 10,
    String? fromDate,
    String? toDate,
    String? type,
  }) {
    return repository.getTransactions(
      page: page,
      limit: limit,
      fromDate: fromDate,
      toDate: toDate,
      type: type,
    );
  }
}
