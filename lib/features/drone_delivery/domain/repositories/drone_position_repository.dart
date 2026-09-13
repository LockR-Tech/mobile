import 'package:smart_laundry_locker/features/drone_delivery/domain/entities/drone_position_snapshot.dart';

/// Nguồn vị trí drone real-time cho live map (Phase 2).
///
/// On-demand: chỉ mở kết nối khi UI gọi [watchPosition], và [stopWatching] khi
/// rời map — KHÔNG stream nền liên tục.
abstract class DronePositionRepository {
  /// Stream vị trí drone của [orderId]. Lần gọi đầu sẽ subscribe STOMP; caller
  /// phải gọi [stopWatching] khi không còn dùng để nhả subscription/socket.
  Stream<DronePositionSnapshot> watchPosition(String orderId);

  /// Ngừng theo dõi [orderId] (unsubscribe đúng subscription đó; đóng socket nếu
  /// không còn ai theo dõi).
  void stopWatching(String orderId);
}
