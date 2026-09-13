import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_laundry_locker/core/services/firebase_messaging_service.dart';
import 'package:smart_laundry_locker/features/drone_delivery/application/use_cases/get_drone_delivery_status_use_case.dart';
import 'package:smart_laundry_locker/features/drone_delivery/domain/entities/drone_delivery_status.dart';
import 'package:smart_laundry_locker/features/drone_delivery/infrastructure/repositories/drone_delivery_repository_impl.dart';

/// DI Riverpod cho luồng theo dõi giao drone (mirror `logistics_send_providers`).
final getDroneDeliveryStatusUseCaseProvider =
    Provider<GetDroneDeliveryStatusUseCase>((ref) {
      final repository = DroneDeliveryRepositoryImpl();
      return GetDroneDeliveryStatusUseCase(repository);
    });

/// Lắng nghe FCM stream, CHỈ giữ lại các event `drone_*` khớp [orderId] và phát
/// một tick tăng dần. Tách riêng để `droneDeliveryStatusProvider` `watch` và tự
/// refetch mỗi khi có mốc mới — mirror cách `NotificationProvider` nghe stream
/// rồi refetch.
final droneDeliveryFcmTickProvider = StreamProvider.autoDispose
    .family<int, String>((ref, orderId) {
      var tick = 0;
      return FirebaseMessagingService.instance.onMessageReceived
          .where(
            (message) =>
                message.data['orderId']?.toString() == orderId &&
                FirebaseMessagingService.droneDeliveryTypes.contains(
                  message.data['type'],
                ),
          )
          .map((_) => ++tick);
    });

/// Trạng thái giao drone hiện tại theo [orderId]. Poll backend mỗi 3 giây để
/// timeline tiến triển ngay cả khi FCM đến trễ; FCM vẫn làm provider khởi tạo
/// lại để lấy mốc quan trọng sớm hơn.
final droneDeliveryStatusProvider = StreamProvider.autoDispose
    .family<DroneDeliveryStatus, String>((ref, orderId) async* {
      ref.watch(droneDeliveryFcmTickProvider(orderId));
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
