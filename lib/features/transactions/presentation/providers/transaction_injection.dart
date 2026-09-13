import 'package:smart_laundry_locker/core/network/api_client.dart';
import 'package:smart_laundry_locker/features/transactions/application/use_cases/initiate_top_up_use_case.dart';
import 'package:smart_laundry_locker/features/transactions/application/use_cases/get_transaction_detail_use_case.dart';
import 'package:smart_laundry_locker/features/transactions/application/use_cases/get_transactions_use_case.dart';
import 'package:smart_laundry_locker/features/transactions/infrastructure/data_sources/top_up_remote_data_source_impl.dart';
import 'package:smart_laundry_locker/features/transactions/infrastructure/data_sources/transaction_remote_data_source_impl.dart';
import 'package:smart_laundry_locker/features/transactions/infrastructure/repositories/top_up_repository_impl.dart';
import 'package:smart_laundry_locker/features/transactions/infrastructure/repositories/transaction_repository_impl.dart';
import 'package:smart_laundry_locker/features/transactions/presentation/providers/transaction_provider.dart';

class TransactionInjection {
  static TransactionProvider provideTransactionProvider(ApiClient apiClient) {
    final remoteDataSource = TransactionRemoteDataSourceImpl(apiClient);
    final repository = TransactionRepositoryImpl(remoteDataSource);
    final getTransactionsUseCase = GetTransactionsUseCase(repository);
    final getTransactionDetailUseCase = GetTransactionDetailUseCase(repository);

    final topUpRemote = TopUpRemoteDataSourceImpl(apiClient);
    final topUpRepo = TopUpRepositoryImpl(topUpRemote);
    final initiateTopUpUseCase = InitiateTopUpUseCase(topUpRepo);

    return TransactionProvider(
      getTransactionsUseCase: getTransactionsUseCase,
      getTransactionDetailUseCase: getTransactionDetailUseCase,
      initiateTopUpUseCase: initiateTopUpUseCase,
    );
  }
}
