import 'package:latlong2/latlong.dart';

class LockerLocationModel {
  final int id;
  final String name;
  final String address;
  final double latitude;
  final double longitude;
  final String? description;
  final bool isActive;

  const LockerLocationModel({
    required this.id,
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    this.description,
    this.isActive = true,
  });

  LatLng get coordinate => LatLng(latitude, longitude);

  // factory constructor để tạo từ JSON
  factory LockerLocationModel.fromJson(Map<String, dynamic> json) {
    return LockerLocationModel(
      id: json['id'] as int,
      name: json['name'] as String,
      address: json['address'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      description: json['description'] as String?,
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  // method convert sang JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'description': description,
      'is_active': isActive,
    };
  }

  LockerLocationModel copyWith({
    int? id,
    String? name,
    String? address,
    double? latitude,
    double? longitude,
    String? description,
    bool? isActive,
  }) {
    return LockerLocationModel(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      description: description ?? this.description,
      isActive: isActive ?? this.isActive,
    );
  }
}
