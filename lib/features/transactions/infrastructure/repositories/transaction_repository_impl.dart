import 'package:smart_laundry_locker/core/errors/failures.dart';
import 'package:dartz/dartz.dart';
import 'package:smart_laundry_locker/core/network/api_client.dart';
import 'package:smart_laundry_locker/features/transactions/domain/entities/paginated_transactions.dart';
import 'package:smart_laundry_locker/features/transactions/domain/entities/transaction.dart';
import 'package:smart_laundry_locker/features/transactions/domain/repositories/transaction_repository.dart';
import 'package:flutter/foundation.dart';
import '../data_sources/transaction_remote_data_source.dart';

class TransactionRepositoryImpl implements TransactionRepository {
  final TransactionRemoteDataSource remoteDataSource;

  TransactionRepositoryImpl(this.remoteDataSource);

  @override
  Future<Either<Failure, PaginatedTransactions>> getTransactions({
    int page = 1,
    int limit = 10,
    String? fromDate,
    String? toDate,
    String? type,
  }) async {
    try {
      final result = await remoteDataSource.getTransactions(
        page: page,
        limit: limit,
        fromDate: fromDate,
        toDate: toDate,
        type: type,
      );
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      debugPrint('[TX][repo] getTransactions CATCH-ALL: $e');
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Transaction>> getTransactionDetail(String id) async {
    try {
      final result = await remoteDataSource.getTransactionDetail(id);
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      debugPrint('[TX][repo] getTransactionDetail CATCH-ALL: $id - $e');
      return Left(UnknownFailure(e.toString()));
    }
  }
}
