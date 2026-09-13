// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'locations_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LocationsResponse _$LocationsResponseFromJson(Map<String, dynamic> json) =>
    LocationsResponse(
      locations: (json['locations'] as List<dynamic>)
          .map((e) => LockerLocationModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      pagination: PaginationResponse.fromJson(
        json['pagination'] as Map<String, dynamic>,
      ),
    );

Map<String, dynamic> _$LocationsResponseToJson(LocationsResponse instance) =>
    <String, dynamic>{
      'locations': instance.locations.map((e) => e.toJson()).toList(),
      'pagination': instance.pagination.toJson(),
    };
