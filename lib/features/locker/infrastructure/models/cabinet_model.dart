import 'package:smart_laundry_locker/features/locker/domain/entities/cabinet.dart';
import 'package:json_annotation/json_annotation.dart';

part 'cabinet_model.g.dart';

/// Infrastructure Model: CabinetModel
/// Data model cho JSON serialization/deserialization với json_serializable.
@JsonSerializable()
class CabinetModel {
  final String id;

  @JsonKey(name: 'locationId')
  final String? locationId;

  final String name;

  @JsonKey(name: 'macAddress')
  final String? macAddress;

  @JsonKey(name: 'ipAddress')
  final String? ipAddress;

  @JsonKey(name: 'firmwareVersion')
  final String? firmwareVersion;

  @JsonKey(name: 'totalRows', defaultValue: 0)
  final int? totalRows;

  @JsonKey(name: 'totalColumns', defaultValue: 0)
  final int? totalColumns;

  @JsonKey(name: 'locationName')
  final String? locationName;

  @JsonKey(name: 'address')
  final String? address;

  @JsonKey(name: 'createdAt')
  final DateTime? createdAt;

  @JsonKey(name: 'updatedAt')
  final DateTime? updatedAt;

  const CabinetModel({
    required this.id,
    this.locationId,
    required this.name,
    this.macAddress,
    this.ipAddress,
    this.firmwareVersion,
    required this.totalRows,
    required this.totalColumns,
    this.locationName,
    this.address,
    this.createdAt,
    this.updatedAt,
  });

  /// Factory: Tạo từ JSON (generated)
  factory CabinetModel.fromJson(Map<String, dynamic> json) =>
      _$CabinetModelFromJson(json);

  /// Convert sang JSON (generated)
  Map<String, dynamic> toJson() => _$CabinetModelToJson(this);

  /// Convert sang Domain Entity
  Cabinet toEntity() {
    return Cabinet(
      id: id,
      locationId: locationId,
      name: name,
      macAddress: macAddress,
      ipAddress: ipAddress,
      firmwareVersion: firmwareVersion,
      totalRows: totalRows ?? 0,
      totalColumns: totalColumns ?? 0,
      locationName: locationName,
      address: address,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  /// Factory: Tạo từ Domain Entity
  factory CabinetModel.fromEntity(Cabinet entity) {
    return CabinetModel(
      id: entity.id,
      locationId: entity.locationId,
      name: entity.name,
      macAddress: entity.macAddress,
      ipAddress: entity.ipAddress,
      firmwareVersion: entity.firmwareVersion,
      totalRows: entity.totalRows,
      totalColumns: entity.totalColumns,
      locationName: entity.locationName,
      address: entity.address,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }
}
