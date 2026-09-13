// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'locker_size_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LockerSizeModel _$LockerSizeModelFromJson(Map<String, dynamic> json) =>
    LockerSizeModel(
      id: json['id'] as String,
      label: json['name'] as String,
      width: (json['width'] as num).toDouble(),
      height: (json['height'] as num).toDouble(),
      depth: (json['depth'] as num).toDouble(),
      description: json['description'] as String?,
    );

Map<String, dynamic> _$LockerSizeModelToJson(LockerSizeModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.label,
      'width': instance.width,
      'height': instance.height,
      'depth': instance.depth,
      'description': instance.description,
    };
