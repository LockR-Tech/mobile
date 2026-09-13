/// Domain Entity: Cabinet
/// Đại diện cho một tủ locker lớn, chứa nhiều ngăn locker nhỏ.
class Cabinet {
  final String id;
  final String? locationId;
  final String name;
  final String? macAddress;
  final String? ipAddress;
  final String? firmwareVersion;
  final int totalRows;
  final int totalColumns;
  final String? locationName;
  final String? address;
  final double? latitude;
  final double? longitude;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Cabinet({
    required this.id,
    this.locationId,
    required this.name,
    this.macAddress,
    this.ipAddress,
    this.firmwareVersion,
    required this.totalRows,
    required this.totalColumns,
    this.locationName,
    this.address,
    this.latitude,
    this.longitude,
    this.createdAt,
    this.updatedAt,
  });

  /// Business logic: Tổng số locker trong cabinet
  int get totalLockers => totalRows * totalColumns;

  /// Business logic: Kiểm tra cabinet có kết nối không
  bool get isConnected =>
      macAddress != null &&
      macAddress!.isNotEmpty &&
      ipAddress != null &&
      ipAddress!.isNotEmpty;

  /// Business logic: Kiểm tra vị trí locker có hợp lệ không
  bool isValidPosition(int row, int column) {
    return row >= 0 && row < totalRows && column >= 0 && column < totalColumns;
  }

  Cabinet copyWith({
    String? id,
    String? locationId,
    String? name,
    String? macAddress,
    String? ipAddress,
    String? firmwareVersion,
    int? totalRows,
    int? totalColumns,
    String? locationName,
    String? address,
    double? latitude,
    double? longitude,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Cabinet(
      id: id ?? this.id,
      locationId: locationId ?? this.locationId,
      name: name ?? this.name,
      macAddress: macAddress ?? this.macAddress,
      ipAddress: ipAddress ?? this.ipAddress,
      firmwareVersion: firmwareVersion ?? this.firmwareVersion,
      totalRows: totalRows ?? this.totalRows,
      totalColumns: totalColumns ?? this.totalColumns,
      locationName: locationName ?? this.locationName,
      address: address ?? this.address,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Cabinet && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
