import 'package:smart_laundry_locker/core/network/api_client.dart';
import 'package:smart_laundry_locker/features/notifications/domain/entities/notification_model.dart';

class NotificationRemoteDataSource {
  final ApiClient _apiClient;

  NotificationRemoteDataSource(this._apiClient);

  Future<void> registerDeviceToken({
    required String token,
    required String deviceType,
    required String deviceId,
  }) async {
    await _apiClient.post<dynamic>(
      '/api/notifications/fcm-tokens',
      data: {'token': token, 'deviceType': deviceType, 'deviceId': deviceId},
    );
  }

  Future<void> unregisterDeviceToken(String token) async {
    await _apiClient.delete<dynamic>(
      '/api/notifications/fcm-tokens',
      data: {'token': token},
    );
  }

  Future<NotificationListResponse> getNotifications({
    required int page,
    required int limit,
  }) async {
    final response = await _apiClient.get<dynamic>(
      '/api/notifications',
      queryParameters: {'page': page, 'limit': limit},
    );

    final payload = response.data;
    if (payload is Map<String, dynamic>) {
      return NotificationListResponse.fromApiPayload(
        payload['data'],
        page: page,
        limit: limit,
      );
    }
    return NotificationListResponse.fromApiPayload(
      null,
      page: page,
      limit: limit,
    );
  }

  Future<int> getUnreadCount() async {
    final response = await _apiClient.get<dynamic>(
      '/api/notifications/unread/count',
    );
    final payload = response.data;
    if (payload is Map<String, dynamic>) {
      final data = payload['data'];
      if (data is int) return data;
      if (data is num) return data.toInt();
      if (data is Map<String, dynamic>) {
        return (data['unreadCount'] as num?)?.toInt() ?? 0;
      }
    }
    return 0;
  }

  Future<void> markAsRead(String notificationId) async {
    await _apiClient.patch<dynamic>('/api/notifications/$notificationId/read');
  }

  Future<void> markAllAsRead() async {
    await _apiClient.patch<dynamic>('/api/notifications/read-all');
  }
}
