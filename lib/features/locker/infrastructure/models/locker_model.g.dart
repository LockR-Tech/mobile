// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'locker_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LockerModel _$LockerModelFromJson(Map<String, dynamic> json) => LockerModel(
  id: json['id'] as String,
  cabinetId: json['cabinetId'] as String,
  sizeId: json['sizeId'] as String?,
  row: (json['row'] as num).toInt(),
  column: (json['column'] as num).toInt(),
  status: json['status'] as String? ?? 'AVAILABLE',
  isOpen: json['isOpen'] as bool? ?? false,
  isLocked: json['isLocked'] as bool? ?? true,
  isActive: json['isActive'] as bool? ?? true,
  size: json['sizeType'] == null
      ? null
      : LockerSizeModel.fromJson(json['sizeType'] as Map<String, dynamic>),
  createdAt: json['createdAt'] == null
      ? null
      : DateTime.parse(json['createdAt'] as String),
  updatedAt: json['updatedAt'] == null
      ? null
      : DateTime.parse(json['updatedAt'] as String),
);

Map<String, dynamic> _$LockerModelToJson(LockerModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'cabinetId': instance.cabinetId,
      'sizeId': instance.sizeId,
      'row': instance.row,
      'column': instance.column,
      'status': instance.status,
      'isOpen': instance.isOpen,
      'isLocked': instance.isLocked,
      'isActive': instance.isActive,
      'sizeType': instance.size?.toJson(),
      'createdAt': instance.createdAt?.toIso8601String(),
      'updatedAt': instance.updatedAt?.toIso8601String(),
    };
