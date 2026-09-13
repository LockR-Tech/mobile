// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'lockers_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LockersResponse _$LockersResponseFromJson(Map<String, dynamic> json) =>
    LockersResponse(
      lockers: (json['lockers'] as List<dynamic>)
          .map((e) => LockerModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      pagination: json['pagination'] == null
          ? null
          : PaginationResponse.fromJson(
              json['pagination'] as Map<String, dynamic>,
            ),
    );

Map<String, dynamic> _$LockersResponseToJson(LockersResponse instance) =>
    <String, dynamic>{
      'lockers': instance.lockers.map((e) => e.toJson()).toList(),
      'pagination': instance.pagination?.toJson(),
    };
