import 'package:latlong2/latlong.dart';

/// Domain Entity: LockerLocation
/// Đây là core business object, không phụ thuộc vào framework hay external services.
/// Entity này đại diện cho một địa điểm chứa các tủ locker.
class LockerLocation {
  final String id;
  final String name;
  final String address;
  final double latitude;
  final double longitude;
  final String? description;
  final bool isActive;
  final String? imageUrl;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const LockerLocation({
    required this.id,
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    this.description,
    this.isActive = true,
    this.imageUrl,
    this.createdAt,
    this.updatedAt,
  });

  /// Business logic: Lấy tọa độ LatLng
  LatLng get coordinate => LatLng(latitude, longitude);

  /// getter trả về true nếu latitude và longitude hợp lệ, false nếu không
  bool get hasValidCoordinate {
    if (!latitude.isFinite || !longitude.isFinite) return false;
    if (latitude < -90 || latitude > 90) return false;
    if (longitude < -180 || longitude > 180) return false;
    return true;
  }

  /// Business logic: Kiểm tra location có hoạt động hay không
  bool get isOperational => isActive;

  /// Business logic: Tính khoảng cách đến một điểm khác
  double distanceTo(LockerLocation other) {
    const distance = Distance();
    return distance.as(LengthUnit.Kilometer, coordinate, other.coordinate);
  }

  /// Business logic: Tính khoảng cách đến tọa độ
  double distanceToCoordinate(double lat, double lng) {
    const distance = Distance();
    return distance.as(LengthUnit.Kilometer, coordinate, LatLng(lat, lng));
  }

  LockerLocation copyWith({
    String? id,
    String? name,
    String? address,
    double? latitude,
    double? longitude,
    String? description,
    bool? isActive,
    String? imageUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return LockerLocation(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      description: description ?? this.description,
      isActive: isActive ?? this.isActive,
      imageUrl: imageUrl ?? this.imageUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LockerLocation &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
