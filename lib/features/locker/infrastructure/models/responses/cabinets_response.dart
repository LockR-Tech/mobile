import 'package:smart_laundry_locker/features/locker/infrastructure/models/cabinet_model.dart';
import 'package:smart_laundry_locker/features/locker/infrastructure/models/pagination_response.dart';
import 'package:json_annotation/json_annotation.dart';

part 'cabinets_response.g.dart';

/// GET /cabinets Response
@JsonSerializable(explicitToJson: true)
class CabinetsResponse {
  final List<CabinetModel> cabinets;
  final PaginationResponse pagination;

  const CabinetsResponse({required this.cabinets, required this.pagination});

  factory CabinetsResponse.fromJson(Map<String, dynamic> json) =>
      _$CabinetsResponseFromJson(json);

  Map<String, dynamic> toJson() => _$CabinetsResponseToJson(this);
}
