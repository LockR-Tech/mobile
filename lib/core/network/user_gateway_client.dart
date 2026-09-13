import 'package:dio/dio.dart';
import 'package:smart_laundry_locker/core/network/api_client.dart';
import 'package:smart_laundry_locker/core/services/token_service.dart';

abstract class UserGatewayClient {
  final ApiClient apiClient;

  const UserGatewayClient(this.apiClient);

  dynamic unwrap(Response<dynamic> response) {
    final data = response.data;
    if (data is Map<String, dynamic> && data.containsKey('data')) {
      return data['data'];
    }
    return data;
  }

  Map<String, dynamic> unwrapMap(Response<dynamic> response) {
    final data = unwrap(response);
    if (data is Map<String, dynamic>) return data;
    return <String, dynamic>{};
  }

  List<dynamic> unwrapList(Response<dynamic> response) {
    final data = unwrap(response);
    if (data is List) return data;
    if (data is Map<String, dynamic>) {
      final candidates = [
        data['content'],
        data['items'],
        data['orders'],
        data['notifications'],
        data['data'],
      ];
      for (final candidate in candidates) {
        if (candidate is List) return candidate;
      }
    }
    return const [];
  }

  Future<int> currentUserId() async {
    final userIdText = await TokenService.getUserId();
    final userId = int.tryParse(userIdText ?? '');
    if (userId == null) {
      throw AuthenticationException(
        'Khong xac dinh duoc userId tu token hien tai.',
      );
    }
    return userId;
  }
}
