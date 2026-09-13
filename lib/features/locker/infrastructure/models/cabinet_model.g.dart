// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cabinet_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CabinetModel _$CabinetModelFromJson(Map<String, dynamic> json) => CabinetModel(
  id: json['id'] as String,
  locationId: json['locationId'] as String?,
  name: json['name'] as String,
  macAddress: json['macAddress'] as String?,
  ipAddress: json['ipAddress'] as String?,
  firmwareVersion: json['firmwareVersion'] as String?,
  totalRows: (json['totalRows'] as num?)?.toInt() ?? 0,
  totalColumns: (json['totalColumns'] as num?)?.toInt() ?? 0,
  locationName: json['locationName'] as String?,
  address: json['address'] as String?,
  createdAt: json['createdAt'] == null
      ? null
      : DateTime.parse(json['createdAt'] as String),
  updatedAt: json['updatedAt'] == null
      ? null
      : DateTime.parse(json['updatedAt'] as String),
);

Map<String, dynamic> _$CabinetModelToJson(CabinetModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'locationId': instance.locationId,
      'name': instance.name,
      'macAddress': instance.macAddress,
      'ipAddress': instance.ipAddress,
      'firmwareVersion': instance.firmwareVersion,
      'totalRows': instance.totalRows,
      'totalColumns': instance.totalColumns,
      'locationName': instance.locationName,
      'address': instance.address,
      'createdAt': instance.createdAt?.toIso8601String(),
      'updatedAt': instance.updatedAt?.toIso8601String(),
    };
