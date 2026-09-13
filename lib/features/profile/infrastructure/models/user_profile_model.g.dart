// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_profile_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserProfileModel _$UserProfileModelFromJson(Map<String, dynamic> json) =>
    UserProfileModel(
      id: json['id'] as String?,
      fullName: json['fullName'] as String?,
      email: json['email'] as String?,
      phoneNumber: json['phoneNumber'] as String?,
      status: json['status'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
      isVerified: json['isVerified'] as bool?,
      isActive: json['isActive'] as bool?,
    );

Map<String, dynamic> _$UserProfileModelToJson(UserProfileModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'fullName': instance.fullName,
      'email': instance.email,
      'phoneNumber': instance.phoneNumber,
      'status': instance.status,
      'avatarUrl': instance.avatarUrl,
      'isVerified': instance.isVerified,
      'isActive': instance.isActive,
    };
