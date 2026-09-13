// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'verify_otp_request_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

VerifyOtpRequestModel _$VerifyOtpRequestModelFromJson(
  Map<String, dynamic> json,
) => VerifyOtpRequestModel(
  phoneNumber: json['phoneNumber'] as String?,
  email: json['email'] as String?,
  otp: json['otp'] as String,
);

Map<String, dynamic> _$VerifyOtpRequestModelToJson(
  VerifyOtpRequestModel instance,
) => <String, dynamic>{
  'phoneNumber': ?instance.phoneNumber,
  'email': ?instance.email,
  'otp': instance.otp,
};
