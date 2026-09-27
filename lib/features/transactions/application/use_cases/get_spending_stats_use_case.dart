import 'package:dartz/dartz.dart';
import 'package:smart_laundry_locker/core/errors/failures.dart';
import '../../domain/entities/spending_stats.dart';
import '../../domain/repositories/transaction_repository.dart';

class GetSpendingStatsUseCase {
  final TransactionRepository repository;

  GetSpendingStatsUseCase(this.repository);

  Future<Either<Failure, SpendingStats>> call({String period = 'ALL'}) {
    return repository.getSpendingStats(period: period);
  }
}
