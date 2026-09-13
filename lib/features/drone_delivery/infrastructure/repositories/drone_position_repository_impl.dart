import 'package:smart_laundry_locker/features/drone_delivery/domain/entities/drone_position_snapshot.dart';
import 'package:smart_laundry_locker/features/drone_delivery/domain/repositories/drone_position_repository.dart';
import 'package:smart_laundry_locker/features/drone_delivery/infrastructure/services/drone_position_socket_service.dart';

class DronePositionRepositoryImpl implements DronePositionRepository {
  final DronePositionSocketService _socket;

  DronePositionRepositoryImpl({DronePositionSocketService? socket})
    : _socket = socket ?? DronePositionSocketService.instance;

  @override
  Stream<DronePositionSnapshot> watchPosition(String orderId) =>
      _socket.watch(orderId);

  @override
  void stopWatching(String orderId) => _socket.stop(orderId);
}
