import 'package:smart_laundry_locker/core/errors/failures.dart';
import 'package:smart_laundry_locker/features/transactions/domain/entities/transaction.dart';
import 'package:smart_laundry_locker/features/transactions/domain/repositories/transaction_repository.dart';
import 'package:dartz/dartz.dart';

class GetTransactionDetailUseCase {
  final TransactionRepository repository;

  GetTransactionDetailUseCase(this.repository);

  Future<Either<Failure, Transaction>> call(String id) {
    return repository.getTransactionDetail(id);
  }
}
