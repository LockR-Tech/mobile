import 'package:smart_laundry_locker/features/locker/domain/entities/locker_location.dart';
import 'package:json_annotation/json_annotation.dart';

part 'locker_location_model.g.dart';

/// Infrastructure Model: LockerLocationModel
/// Data model cho JSON serialization/deserialization với json_serializable.
@JsonSerializable()
class LockerLocationModel {
  final String id;
  final String name;
  final String address;
  final double latitude;
  final double longitude;
  final String? description;

  @JsonKey(name: 'isActive', defaultValue: true)
  final bool isActive;

  @JsonKey(name: 'imageUrl')
  final String? imageUrl;

  @JsonKey(name: 'createdAt')
  final DateTime? createdAt;

  @JsonKey(name: 'updatedAt')
  final DateTime? updatedAt;

  @JsonKey(name: 'storeId')
  final String? storeId;

  @JsonKey(name: 'online')
  final bool? online;

  @JsonKey(name: 'storeName')
  final String? storeName;

  @JsonKey(name: 'storeAddress')
  final String? storeAddress;

  @JsonKey(name: 'storeLatitude')
  final double? storeLatitude;

  @JsonKey(name: 'storeLongitude')
  final double? storeLongitude;

  const LockerLocationModel({
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
    this.storeId,
    this.online,
    this.storeName,
    this.storeAddress,
    this.storeLatitude,
    this.storeLongitude,
  });

  /// Factory: Tạo từ JSON
  factory LockerLocationModel.fromJson(Map<String, dynamic> json) {
    return LockerLocationModel(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      address: (json['address'] ?? '').toString(),
      latitude: (json['latitude'] as num?)?.toDouble() ?? double.nan,
      longitude: (json['longitude'] as num?)?.toDouble() ?? double.nan,
      description: json['description'] as String?,
      isActive: json['isActive'] as bool? ?? true,
      imageUrl: json['imageUrl'] as String?,
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.tryParse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] == null
          ? null
          : DateTime.tryParse(json['updatedAt'] as String),
      storeId: json['storeId']?.toString(),
      online: json['online'] as bool?,
      storeName: json['storeName'] as String?,
      storeAddress: json['storeAddress'] as String?,
      storeLatitude: (json['storeLatitude'] as num?)?.toDouble(),
      storeLongitude: (json['storeLongitude'] as num?)?.toDouble(),
    );
  }

  /// Convert sang JSON
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'address': address,
    'latitude': latitude,
    'longitude': longitude,
    'description': description,
    'isActive': isActive,
    'imageUrl': imageUrl,
    'createdAt': createdAt?.toIso8601String(),
    'updatedAt': updatedAt?.toIso8601String(),
    'storeId': storeId,
    'online': online,
    'storeName': storeName,
    'storeAddress': storeAddress,
    'storeLatitude': storeLatitude,
    'storeLongitude': storeLongitude,
  };

  /// Convert sang Domain Entity
  LockerLocation toEntity() {
    return LockerLocation(
      id: id,
      name: name,
      address: address,
      latitude: latitude,
      longitude: longitude,
      description: description,
      isActive: isActive,
      imageUrl: imageUrl,
      createdAt: createdAt,
      updatedAt: updatedAt,
      storeId: storeId,
      online: online,
      storeName: storeName,
      storeAddress: storeAddress,
      storeLatitude: storeLatitude,
      storeLongitude: storeLongitude,
    );
  }

  /// Factory: Tạo từ Domain Entity
  factory LockerLocationModel.fromEntity(LockerLocation entity) {
    return LockerLocationModel(
      id: entity.id,
      name: entity.name,
      address: entity.address,
      latitude: entity.latitude,
      longitude: entity.longitude,
      description: entity.description,
      isActive: entity.isActive,
      imageUrl: entity.imageUrl,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      storeId: entity.storeId,
      online: entity.online,
      storeName: entity.storeName,
      storeAddress: entity.storeAddress,
      storeLatitude: entity.storeLatitude,
      storeLongitude: entity.storeLongitude,
    );
  }
}
