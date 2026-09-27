import 'package:dartz/dartz.dart';
import 'package:smart_laundry_locker/core/errors/failures.dart';
import '../../domain/entities/transaction_method_total.dart';
import '../../domain/repositories/transaction_repository.dart';

class GetTotalByMethodUseCase {
  final TransactionRepository repository;

  GetTotalByMethodUseCase(this.repository);

  Future<Either<Failure, TransactionMethodTotal>> call({
    String? method,
    String period = 'ALL',
    String? fromDate,
    String? toDate,
  }) {
    return repository.getTotalByMethod(
      method: method,
      period: period,
      fromDate: fromDate,
      toDate: toDate,
    );
  }
}
