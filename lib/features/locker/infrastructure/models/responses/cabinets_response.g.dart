// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cabinets_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CabinetsResponse _$CabinetsResponseFromJson(Map<String, dynamic> json) =>
    CabinetsResponse(
      cabinets: (json['cabinets'] as List<dynamic>)
          .map((e) => CabinetModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      pagination: PaginationResponse.fromJson(
        json['pagination'] as Map<String, dynamic>,
      ),
    );

Map<String, dynamic> _$CabinetsResponseToJson(CabinetsResponse instance) =>
    <String, dynamic>{
      'cabinets': instance.cabinets.map((e) => e.toJson()).toList(),
      'pagination': instance.pagination.toJson(),
    };
