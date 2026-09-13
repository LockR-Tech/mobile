import 'package:smart_laundry_locker/core/network/api_client.dart';
import 'package:smart_laundry_locker/features/notifications/infrastructure/data_sources/notification_remote_data_source.dart';
import 'package:smart_laundry_locker/features/notifications/infrastructure/repositories/notification_repository.dart';
import 'package:smart_laundry_locker/features/notifications/presentation/providers/notification_provider.dart';

class NotificationInjection {
  static NotificationProvider provideNotificationProvider(ApiClient apiClient) {
    final remoteDataSource = NotificationRemoteDataSource(apiClient);
    final repository = NotificationRepository(remoteDataSource);
    return NotificationProvider(repository);
  }
}
