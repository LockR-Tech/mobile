import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_laundry_locker/core/services/firebase_messaging_service.dart';
import 'package:smart_laundry_locker/features/drone_delivery/application/use_cases/get_drone_delivery_status_use_case.dart';
import 'package:smart_laundry_locker/features/drone_delivery/domain/entities/drone_delivery_status.dart';
import 'package:smart_laundry_locker/features/drone_delivery/infrastructure/repositories/drone_delivery_repository_impl.dart';
import 'package:smart_laundry_locker/features/notifications/infrastructure/services/realtime_notification_service.dart';

/// DI Riverpod cho luồng theo dõi giao drone (mirror `logistics_send_providers`).
final getDroneDeliveryStatusUseCaseProvider =
    Provider<GetDroneDeliveryStatusUseCase>((ref) {
      final repository = DroneDeliveryRepositoryImpl();
      return GetDroneDeliveryStatusUseCase(repository);
    });

/// Lắng nghe FCM stream, CHỈ giữ lại các push của đúng [orderId] và phát một
/// tick tăng dần để `droneDeliveryStatusProvider` refetch ngay khi có mốc mới.
///
/// Backend gửi mốc chặng giao với `type = ORDER_STATUS_CHANGED`,
/// `referenceType = DELIVERY` và `orderId` trong data; huỷ nhiệm vụ gửi
/// `DRONE_DELIVERY_STATUS_CHANGED` chỉ có `referenceId`. Khớp theo id đơn ở cả
/// hai field thay vì theo danh sách type, để không bỏ sót mốc nào.
final droneDeliveryFcmTickProvider = StreamProvider.autoDispose
    .family<int, String>((ref, orderId) {
      var tick = 0;
      return FirebaseMessagingService.instance.onMessageReceived
          .where(
            (message) =>
                message.data['orderId']?.toString() == orderId ||
                message.data['referenceId']?.toString() == orderId,
          )
          .map((_) => ++tick);
    });

/// Như trên nhưng qua STOMP `/user/queue/notifications` — tới ngay cả khi máy
/// không nhận được push (FCM chưa cấu hình, chạy web).
final droneDeliveryRealtimeTickProvider = StreamProvider.autoDispose
    .family<int, String>((ref, orderId) {
      var tick = 0;
      return RealtimeNotificationService.instance.notifications
          .where(
            (notification) =>
                notification.dataPayload?.referenceId == orderId,
          )
          .map((_) => ++tick);
    });

/// Trạng thái giao drone hiện tại theo [orderId]. Poll backend mỗi 3 giây để
/// timeline tiến triển ngay cả khi FCM đến trễ; FCM vẫn làm provider khởi tạo
/// lại để lấy mốc quan trọng sớm hơn.
final droneDeliveryStatusProvider = StreamProvider.autoDispose
    .family<DroneDeliveryStatus, String>((ref, orderId) async* {
      ref.watch(droneDeliveryFcmTickProvider(orderId));
      ref.watch(droneDeliveryRealtimeTickProvider(orderId));
      final useCase = ref.watch(getDroneDeliveryStatusUseCaseProvider);

      while (true) {
        final result = await useCase.execute(orderId);
        yield result.fold(
          (failure) => throw Exception(failure.message),
          (status) => status,
        );
        await Future<void>.delayed(const Duration(seconds: 3));
      }
    });
