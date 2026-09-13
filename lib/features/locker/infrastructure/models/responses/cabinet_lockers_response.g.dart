// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cabinet_lockers_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CabinetLockersResponse _$CabinetLockersResponseFromJson(
  Map<String, dynamic> json,
) => CabinetLockersResponse(
  cabinet: CabinetModel.fromJson(json['cabinet'] as Map<String, dynamic>),
  lockers: (json['lockers'] as List<dynamic>)
      .map((e) => LockerModel.fromJson(e as Map<String, dynamic>))
      .toList(),
  pagination: PaginationResponse.fromJson(
    json['pagination'] as Map<String, dynamic>,
  ),
);

Map<String, dynamic> _$CabinetLockersResponseToJson(
  CabinetLockersResponse instance,
) => <String, dynamic>{
  'cabinet': instance.cabinet.toJson(),
  'lockers': instance.lockers.map((e) => e.toJson()).toList(),
  'pagination': instance.pagination.toJson(),
};
