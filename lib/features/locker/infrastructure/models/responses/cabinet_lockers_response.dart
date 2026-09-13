import 'package:smart_laundry_locker/features/locker/infrastructure/models/cabinet_model.dart';
import 'package:smart_laundry_locker/features/locker/infrastructure/models/locker_model.dart';
import 'package:smart_laundry_locker/features/locker/infrastructure/models/pagination_response.dart';
import 'package:json_annotation/json_annotation.dart';

part 'cabinet_lockers_response.g.dart';

/// GET /cabinets/:id/lockers Response
@JsonSerializable(explicitToJson: true)
class CabinetLockersResponse {
  final CabinetModel cabinet;
  final List<LockerModel> lockers;
  final PaginationResponse pagination;

  const CabinetLockersResponse({
    required this.cabinet,
    required this.lockers,
    required this.pagination,
  });

  factory CabinetLockersResponse.fromJson(Map<String, dynamic> json) =>
      _$CabinetLockersResponseFromJson(json);

  Map<String, dynamic> toJson() => _$CabinetLockersResponseToJson(this);
}
