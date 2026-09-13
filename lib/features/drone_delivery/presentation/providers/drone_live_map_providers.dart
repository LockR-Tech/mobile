import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_laundry_locker/features/drone_delivery/domain/entities/drone_position_snapshot.dart';
import 'package:smart_laundry_locker/features/drone_delivery/domain/repositories/drone_position_repository.dart';
import 'package:smart_laundry_locker/features/drone_delivery/infrastructure/repositories/drone_position_repository_impl.dart';

/// DI Riverpod cho live map (mirror `drone_delivery_providers`).
final dronePositionRepositoryProvider = Provider<DronePositionRepository>((ref) {
  return DronePositionRepositoryImpl();
});

/// Stream vị trí drone của [orderId] — ON-DEMAND:
/// subscribe STOMP khi widget đầu tiên watch (mở map), `ref.onDispose` gọi
/// `stopWatching` khi rời map (autoDispose khi hết listener). Không stream nền.
final dronePositionStreamProvider = StreamProvider.autoDispose
    .family<DronePositionSnapshot, String>((ref, orderId) {
      final repository = ref.watch(dronePositionRepositoryProvider);
      ref.onDispose(() => repository.stopWatching(orderId));
      return repository.watchPosition(orderId);
    });
