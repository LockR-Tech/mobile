/// Value Object: LockerStatus
/// Enum đại diện cho trạng thái của locker.
enum LockerStatus {
  available('AVAILABLE', 'Có sẵn'),
  inUse('IN_USE', 'Đang sử dụng'),
  occupied('OCCUPIED', 'Đang sử dụng'),
  reserved('RESERVED', 'Đã đặt trước'),
  maintenance('MAINTENANCE', 'Đang bảo trì'),
  outOfService('OUT_OF_SERVICE', 'Ngừng hoạt động');

  final String value;
  final String displayName;

  const LockerStatus(this.value, this.displayName);

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
