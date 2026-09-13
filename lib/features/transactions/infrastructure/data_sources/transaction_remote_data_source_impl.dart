import 'package:smart_laundry_locker/core/network/api_client.dart';
import 'package:flutter/foundation.dart';
import '../models/paginated_transactions_model.dart';
import '../models/transaction_model.dart';
import 'transaction_remote_data_source.dart';

class TransactionRemoteDataSourceImpl implements TransactionRemoteDataSource {
  final ApiClient apiClient;

  TransactionRemoteDataSourceImpl(this.apiClient);

  @override
  Future<PaginatedTransactionsModel> getTransactions({
    int page = 1,
    int limit = 10,
    String? fromDate,
    String? toDate,
    String? type,
  }) async {
    final queryParams = <String, dynamic>{'page': page, 'limit': limit};
    if (fromDate != null) queryParams['fromDate'] = fromDate;
    if (toDate != null) queryParams['toDate'] = toDate;
    if (type != null) queryParams['type'] = type;

    final response = await apiClient.get<Map<String, dynamic>>(
      '/payments/transactions',
      queryParameters: queryParams,
    );

    if (response.data == null) {
      debugPrint('[TX][ds] response.data is NULL');
      throw ServerException('No data returned');
    }

    debugPrint('[TX][ds] raw response body: ${response.data}');

    final responseData = response.data!['data'] ?? response.data!;
    debugPrint('[TX][ds] extracted responseData: $responseData');

    return PaginatedTransactionsModel.fromJson(
      responseData as Map<String, dynamic>,
    );
  }

  @override
  Future<TransactionModel> getTransactionDetail(String id) async {
    final response = await apiClient.get<Map<String, dynamic>>(
      '/payments/transactions/$id',
    );

    if (response.data == null) {
      debugPrint('[TX][ds] detail ($id) response.data is NULL');
      throw ServerException('No data returned');
    }

    debugPrint('[TX][ds] detail ($id) raw response body: ${response.data}');

    final responseData = response.data!['data'] ?? response.data!;
    return TransactionModel.fromJson(responseData as Map<String, dynamic>);
  }
}
