import 'package:latlong2/latlong.dart';

enum DroneOrderStatus {
  pending,
  dispatched,
  inFlight,
  approaching,
  arrived,
  delivered,
  failed;

  String get label {
    switch (this) {
      case DroneOrderStatus.pending:
        return 'Chờ điều phối';
      case DroneOrderStatus.dispatched:
        return 'Drone xuất phát';
      case DroneOrderStatus.inFlight:
        return 'Đang bay';
      case DroneOrderStatus.approaching:
        return 'Đang tiếp cận';
      case DroneOrderStatus.arrived:
        return 'Drone đã đến tủ';
      case DroneOrderStatus.delivered:
        return 'Đã thả hàng thành công';
      case DroneOrderStatus.failed:
        return 'Thất bại';
    }
  }
}

class DroneOrder {
  const DroneOrder({
    required this.id,
    required this.lockerName,
    required this.boxNumber,
    required this.origin,
    required this.createdAt,
    this.description,
    this.status = DroneOrderStatus.pending,
  });

  final String id;
  final String lockerName;
  final int boxNumber;
  final LatLng origin;
  final DateTime createdAt;
  final String? description;
  final DroneOrderStatus status;

  DroneOrder copyWith({DroneOrderStatus? status}) => DroneOrder(
    id: id,
    lockerName: lockerName,
    boxNumber: boxNumber,
    origin: origin,
    createdAt: createdAt,
    description: description,
    status: status ?? this.status,
  );
}
