import 'package:smart_laundry_locker/core/network/api_client.dart';
import 'package:flutter/foundation.dart';
import '../models/paginated_transactions_model.dart';
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
    // WalletController (payment-service) chỉ có GET /api/wallet/transactions, trả thẳng
    // List<WalletTransactionResponse> — không phân trang, không lọc theo ngày/loại, không
    // có endpoint chi tiết theo id. page/limit/fromDate/toDate/type giữ trong chữ ký hàm để
    // không phải sửa toàn bộ tầng gọi phía trên, nhưng backend hiện bỏ qua hết.
    final response = await apiClient.get<Map<String, dynamic>>(
      '/api/wallet/transactions',
    );

    if (response.data == null) {
      debugPrint('[TX][ds] response.data is NULL');
      throw ServerException('No data returned');
    }

    final items = response.data!['data'];
    if (items is! List) {
      debugPrint('[TX][ds] unexpected response shape: ${response.data}');
      throw ServerException('Unexpected response shape');
    }

    return PaginatedTransactionsModel.fromList(items);
  }

  @override
  Future<Map<String, dynamic>> getSpendingStats({String period = 'ALL'}) async {
    final response = await apiClient.get<Map<String, dynamic>>(
      '/api/wallet/spending-stats',
      queryParameters: {'period': period},
    );

    if (response.data == null) {
      throw ServerException('No data returned from spending stats');
    }

    final data = response.data!['data'];
    if (data is! Map<String, dynamic>) {
      throw ServerException('Invalid spending stats response shape');
    }

    return data;
  }

  @override
  Future<Map<String, dynamic>> getTotalByMethod({
    String? method,
    String period = 'ALL',
    String? fromDate,
    String? toDate,
  }) async {
    final queryParams = <String, dynamic>{
      'period': period,
    };
    if (method != null && method.isNotEmpty) {
      queryParams['method'] = method;
    }
    if (fromDate != null && fromDate.isNotEmpty) {
      queryParams['from'] = fromDate;
    }
    if (toDate != null && toDate.isNotEmpty) {
      queryParams['to'] = toDate;
    }

    final response = await apiClient.get<Map<String, dynamic>>(
      '/api/wallet/total-by-method',
      queryParameters: queryParams,
    );

    if (response.data == null) {
      throw ServerException('No data returned from total by method');
    }

    final data = response.data!['data'];
    if (data is! Map<String, dynamic>) {
      throw ServerException('Invalid total by method response shape');
    }

    return data;
  }
}
