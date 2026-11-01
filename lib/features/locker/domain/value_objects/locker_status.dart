import 'package:smart_laundry_locker/core/l10n/l10n.dart';
/// Value Object: LockerStatus
/// Enum đại diện cho trạng thái của locker.
enum LockerStatus {
  available('AVAILABLE'),
  inUse('IN_USE'),
  occupied('OCCUPIED'),
  reserved('RESERVED'),
  maintenance('MAINTENANCE'),
  outOfService('OUT_OF_SERVICE');

  final String value;

  const LockerStatus(this.value);

  String get displayName => switch (this) {
    available => L10n.current.lockerStatusAvailable,
    inUse || occupied => L10n.current.lockerStatusInUse,
    reserved => L10n.current.lockerStatusReserved,
    maintenance => L10n.current.lockerStatusMaintenance,
    outOfService => L10n.current.lockerStatusOutOfService,
  };

  /// Factory: Tạo từ string value
  static LockerStatus fromValue(String value) {
    return LockerStatus.values.firstWhere(
      (status) => status.value.toUpperCase() == value.toUpperCase(),
      orElse: () => LockerStatus.available,
    );
  }

  /// Business logic: Kiểm tra có thể thuê được không
  bool get canRent => this == LockerStatus.available;

  /// Business logic: Kiểm tra đang hoạt động
  bool get isOperational =>
      this != LockerStatus.maintenance && this != LockerStatus.outOfService;
}
