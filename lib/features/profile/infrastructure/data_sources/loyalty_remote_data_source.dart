import 'package:smart_laundry_locker/core/network/api_client.dart';
import 'package:smart_laundry_locker/features/profile/domain/entities/loyalty.dart';

/// Điểm thưởng của chính người dùng. loyalty-service lấy người dùng từ token
/// (gateway gắn `X-User-Id`) — app không gửi userId.
class LoyaltyRemoteDataSource {
  final ApiClient _apiClient;

  LoyaltyRemoteDataSource([ApiClient? apiClient])
    : _apiClient = apiClient ?? ApiClient();

  Future<LoyaltySummary> getSummary() async {
    final response = await _apiClient.get<dynamic>('/api/loyalty/summary');
    final data = _data(response.data);
    if (data is! Map<String, dynamic>) {
      throw ServerException('Dữ liệu điểm thưởng không hợp lệ');
    }
    return LoyaltySummary.fromJson(data);
  }

  Future<List<PointTransaction>> getHistory() async {
    final response = await _apiClient.get<dynamic>(
      '/api/loyalty/points/history',
    );
    final data = _data(response.data);
    if (data is! List) return const [];
    return data
        .whereType<Map<String, dynamic>>()
        .map(PointTransaction.fromJson)
        .toList();
  }

  dynamic _data(dynamic body) =>
      body is Map<String, dynamic> && body.containsKey('data')
      ? body['data']
      : body;
}
