// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'customer_cabinet_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CustomerCabinetModel _$CustomerCabinetModelFromJson(
  Map<String, dynamic> json,
) => CustomerCabinetModel(
  id: json['id'] as String,
  name: json['name'] as String,
  locationName: json['locationName'] as String?,
  address: json['address'] as String?,
);

Map<String, dynamic> _$CustomerCabinetModelToJson(
  CustomerCabinetModel instance,
) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'locationName': instance.locationName,
  'address': instance.address,
};
