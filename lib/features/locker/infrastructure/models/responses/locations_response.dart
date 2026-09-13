import 'package:smart_laundry_locker/features/locker/infrastructure/models/locker_location_model.dart';
import 'package:smart_laundry_locker/features/locker/infrastructure/models/pagination_response.dart';
import 'package:json_annotation/json_annotation.dart';

part 'locations_response.g.dart';

/// GET /locations Response
@JsonSerializable(explicitToJson: true)
class LocationsResponse {
  final List<LockerLocationModel> locations;
  final PaginationResponse pagination;

  const LocationsResponse({required this.locations, required this.pagination});

  factory LocationsResponse.fromJson(Map<String, dynamic> json) {
    final locationsJson = json['locations'];
    final paginationJson = json['pagination'];

    final locations = (locationsJson is List)
        ? locationsJson
              .whereType<Map<String, dynamic>>()
              .map(LockerLocationModel.fromJson)
              .toList()
        : <LockerLocationModel>[];

    final pagination = PaginationResponse.fromJson(
      paginationJson is Map<String, dynamic>
          ? paginationJson
          : <String, dynamic>{'total': 0, 'page': 1, 'limit': 10},
    );

    return LocationsResponse(locations: locations, pagination: pagination);
  }

  Map<String, dynamic> toJson() => _$LocationsResponseToJson(this);
}
