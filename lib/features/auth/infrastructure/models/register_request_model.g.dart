// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'register_request_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RegisterRequestModel _$RegisterRequestModelFromJson(
  Map<String, dynamic> json,
) => RegisterRequestModel(
  phoneNumber: json['phoneNumber'] as String,
  password: json['password'] as String?,
  fullName: json['fullName'] as String?,
  email: json['email'] as String?,
  role: json['role'] as String? ?? 'CUSTOMER',
  notificationType: json['notificationType'] as String? ?? 'EMAIL',
);

Map<String, dynamic> _$RegisterRequestModelToJson(
  RegisterRequestModel instance,
) => <String, dynamic>{
  'phoneNumber': instance.phoneNumber,
  'password': ?instance.password,
  'fullName': ?instance.fullName,
  'email': ?instance.email,
  'role': instance.role,
  'notificationType': instance.notificationType,
};
