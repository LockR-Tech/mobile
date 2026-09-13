// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'location_cabinets_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LocationCabinetsResponse _$LocationCabinetsResponseFromJson(
  Map<String, dynamic> json,
) => LocationCabinetsResponse(
  location: LockerLocationModel.fromJson(
    json['location'] as Map<String, dynamic>,
  ),
  cabinets: (json['cabinets'] as List<dynamic>)
      .map((e) => CabinetModel.fromJson(e as Map<String, dynamic>))
      .toList(),
  pagination: PaginationResponse.fromJson(
    json['pagination'] as Map<String, dynamic>,
  ),
);

Map<String, dynamic> _$LocationCabinetsResponseToJson(
  LocationCabinetsResponse instance,
) => <String, dynamic>{
  'location': instance.location.toJson(),
  'cabinets': instance.cabinets.map((e) => e.toJson()).toList(),
  'pagination': instance.pagination.toJson(),
};
