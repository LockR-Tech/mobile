import 'package:smart_laundry_locker/features/profile/domain/entities/courier_profile.dart';
import 'package:json_annotation/json_annotation.dart';

part 'courier_profile_model.g.dart';

Object? _readVehicleType(Map<dynamic, dynamic> json, String key) =>
    json['vehicleType'] ?? json['vehicle_type'];
Object? _readLicensePlate(Map<dynamic, dynamic> json, String key) =>
    json['licensePlate'] ?? json['license_plate'];
Object? _readFrontVehicleImageUrl(Map<dynamic, dynamic> json, String key) =>
    json['frontVehicleImageUrl'] ?? json['front_image'];
Object? _readBackVehicleImageUrl(Map<dynamic, dynamic> json, String key) =>
    json['backVehicleImageUrl'] ?? json['back_image'];
Object? _readPortraitUrl(Map<dynamic, dynamic> json, String key) =>
    json['portraitUrl'] ?? json['portrait_image'];

@JsonSerializable()
class CourierProfileModel {
  final String id;
  @JsonKey(readValue: _readVehicleType, defaultValue: '')
  final String vehicleType;
  @JsonKey(readValue: _readLicensePlate, defaultValue: '')
  final String licensePlate;
  @JsonKey(readValue: _readFrontVehicleImageUrl)
  final String? frontVehicleImageUrl;
  @JsonKey(readValue: _readBackVehicleImageUrl)
  final String? backVehicleImageUrl;
  @JsonKey(readValue: _readPortraitUrl)
  final String? portraitUrl;
  @JsonKey(defaultValue: '')
  final String status;

  const CourierProfileModel({
    required this.id,
    required this.vehicleType,
    required this.licensePlate,
    this.frontVehicleImageUrl,
    this.backVehicleImageUrl,
    this.portraitUrl,
    required this.status,
  });

  factory CourierProfileModel.fromJson(Map<String, dynamic> json) =>
      _$CourierProfileModelFromJson(json);

  Map<String, dynamic> toJson() => _$CourierProfileModelToJson(this);

  CourierProfile toEntity() {
    return CourierProfile(
      id: id,
      vehicleType: vehicleType,
      licensePlate: licensePlate,
      frontVehicleImageUrl: frontVehicleImageUrl,
      backVehicleImageUrl: backVehicleImageUrl,
      portraitUrl: portraitUrl,
      status: status,
    );
  }
}
