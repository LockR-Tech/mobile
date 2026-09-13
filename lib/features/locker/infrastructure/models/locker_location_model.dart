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
  });

  /// Factory: Tạo từ JSON (generated)
  factory LockerLocationModel.fromJson(Map<String, dynamic> json) =>
      _$LockerLocationModelFromJson(json);

  /// Convert sang JSON (generated)
  Map<String, dynamic> toJson() => _$LockerLocationModelToJson(this);

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
    );
  }
}
