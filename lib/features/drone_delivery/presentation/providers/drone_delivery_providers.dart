import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_laundry_locker/core/services/firebase_messaging_service.dart';
import 'package:smart_laundry_locker/features/drone_delivery/application/use_cases/get_drone_delivery_status_use_case.dart';
import 'package:smart_laundry_locker/features/drone_delivery/domain/entities/drone_delivery_status.dart';
import 'package:smart_laundry_locker/features/drone_delivery/infrastructure/repositories/drone_delivery_repository_impl.dart';
import 'package:smart_laundry_locker/features/notifications/infrastructure/services/realtime_notification_service.dart';
import 'package:smart_laundry_locker/core/l10n/l10n.dart';

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
///
/// Một lần gọi lỗi (mất mạng, server chập chờn) KHÔNG dừng việc theo dõi: phát
/// lỗi để UI báo "đang thử lại" nhưng vẫn giữ dữ liệu cũ (`AsyncError` mang giá
/// trị trước), rồi tự thử lại với nhịp giãn dần. Tắt retry mặc định của Riverpod
/// để vòng poll này là nơi duy nhất quyết định việc thử lại.
final droneDeliveryStatusProvider = StreamProvider.autoDispose
    .family<DroneDeliveryStatus, String>((ref, orderId) async* {
      ref.watch(droneDeliveryFcmTickProvider(orderId));
      ref.watch(droneDeliveryRealtimeTickProvider(orderId));
      final useCase = ref.watch(getDroneDeliveryStatusUseCaseProvider);

      var failures = 0;
      while (true) {
        final result = await useCase.execute(orderId);
        DroneDeliveryStatus? status;
        String? errorMessage;
        result.fold((f) => errorMessage = f.message, (s) => status = s);
        if (status != null) {
          failures = 0;
          yield status!;
        } else {
          failures++;
          yield* Stream<DroneDeliveryStatus>.error(
            DroneStatusLoadException(
              errorMessage ?? L10n.current.droneStatusLoadFailed,
            ),
          );
        }
        await Future<void>.delayed(droneStatusPollDelay(failures));
      }
    }, retry: (_, __) => null);

/// Nhịp poll: 3 giây khi ổn định; lỗi liên tiếp thì giãn dần (tối đa 30 giây).
Duration droneStatusPollDelay(int consecutiveFailures) {
  if (consecutiveFailures <= 0) return const Duration(seconds: 3);
  final seconds = 3 * (1 << (consecutiveFailures - 1).clamp(0, 4));
  return Duration(seconds: seconds > 30 ? 30 : seconds);
}

/// Lỗi tải trạng thái đơn drone; [message] là câu hiển thị cho khách.
class DroneStatusLoadException implements Exception {
  const DroneStatusLoadException(this.message);

  final String message;

  @override
  String toString() => message;
}
