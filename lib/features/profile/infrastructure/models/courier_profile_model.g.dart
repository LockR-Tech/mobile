// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'courier_profile_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CourierProfileModel _$CourierProfileModelFromJson(Map<String, dynamic> json) =>
    CourierProfileModel(
      id: json['id'] as String,
      vehicleType: _readVehicleType(json, 'vehicleType') as String? ?? '',
      licensePlate: _readLicensePlate(json, 'licensePlate') as String? ?? '',
      frontVehicleImageUrl:
          _readFrontVehicleImageUrl(json, 'frontVehicleImageUrl') as String?,
      backVehicleImageUrl:
          _readBackVehicleImageUrl(json, 'backVehicleImageUrl') as String?,
      portraitUrl: _readPortraitUrl(json, 'portraitUrl') as String?,
      status: json['status'] as String? ?? '',
    );

Map<String, dynamic> _$CourierProfileModelToJson(
  CourierProfileModel instance,
) => <String, dynamic>{
  'id': instance.id,
  'vehicleType': instance.vehicleType,
  'licensePlate': instance.licensePlate,
  'frontVehicleImageUrl': instance.frontVehicleImageUrl,
  'backVehicleImageUrl': instance.backVehicleImageUrl,
  'portraitUrl': instance.portraitUrl,
  'status': instance.status,
};
