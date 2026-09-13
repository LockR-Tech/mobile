import 'package:smart_laundry_locker/features/locker/infrastructure/models/cabinet_model.dart';
import 'package:smart_laundry_locker/features/locker/infrastructure/models/locker_location_model.dart';
import 'package:smart_laundry_locker/features/locker/infrastructure/models/pagination_response.dart';
import 'package:json_annotation/json_annotation.dart';

part 'location_cabinets_response.g.dart';

/// GET /locations/:id/cabinets Response
@JsonSerializable(explicitToJson: true)
class LocationCabinetsResponse {
  final LockerLocationModel location;
  final List<CabinetModel> cabinets;
  final PaginationResponse pagination;

  const LocationCabinetsResponse({
    required this.location,
    required this.cabinets,
    required this.pagination,
  });

  factory LocationCabinetsResponse.fromJson(Map<String, dynamic> json) =>
      _$LocationCabinetsResponseFromJson(json);

  Map<String, dynamic> toJson() => _$LocationCabinetsResponseToJson(this);
}
