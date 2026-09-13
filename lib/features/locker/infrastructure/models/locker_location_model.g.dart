// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'locker_location_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LockerLocationModel _$LockerLocationModelFromJson(Map<String, dynamic> json) =>
    LockerLocationModel(
      id: json['id'] as String,
      name: json['name'] as String,
      address: json['address'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      description: json['description'] as String?,
      isActive: json['isActive'] as bool? ?? true,
      imageUrl: json['imageUrl'] as String?,
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] == null
          ? null
          : DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$LockerLocationModelToJson(
  LockerLocationModel instance,
) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'address': instance.address,
  'latitude': instance.latitude,
  'longitude': instance.longitude,
  'description': instance.description,
  'isActive': instance.isActive,
  'imageUrl': instance.imageUrl,
  'createdAt': instance.createdAt?.toIso8601String(),
  'updatedAt': instance.updatedAt?.toIso8601String(),
};
