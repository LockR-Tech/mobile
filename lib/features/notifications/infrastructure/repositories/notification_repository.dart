import 'package:smart_laundry_locker/features/notifications/domain/entities/notification_model.dart';
import 'package:smart_laundry_locker/features/notifications/infrastructure/data_sources/notification_remote_data_source.dart';

class NotificationRepository {
  final NotificationRemoteDataSource _remoteDataSource;

  NotificationRepository(this._remoteDataSource);

  Future<void> registerDeviceToken({
    required String token,
    required String deviceType,
    required String deviceId,
  }) {
    return _remoteDataSource.registerDeviceToken(
      token: token,
      deviceType: deviceType,
      deviceId: deviceId,
    );
  }

  Future<void> unregisterDeviceToken(String token) {
    return _remoteDataSource.unregisterDeviceToken(token);
  }

  Future<NotificationListResponse> getNotifications({
    required int page,
    required int limit,
  }) {
    return _remoteDataSource.getNotifications(page: page, limit: limit);
  }

  Future<int> getUnreadCount() {
    return _remoteDataSource.getUnreadCount();
  }

  Future<void> markAsRead(String notificationId) {
    return _remoteDataSource.markAsRead(notificationId);
  }

  Future<void> markAllAsRead() {
    return _remoteDataSource.markAllAsRead();
  }
}
