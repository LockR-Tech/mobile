import 'package:smart_laundry_locker/features/locker/domain/entities/locker.dart';
import 'package:smart_laundry_locker/features/locker/domain/value_objects/locker_status.dart';
import 'package:smart_laundry_locker/features/locker/infrastructure/models/locker_size_model.dart';
import 'package:json_annotation/json_annotation.dart';

part 'locker_model.g.dart';

/// Infrastructure Model: LockerModel
/// Data model cho JSON serialization/deserialization với json_serializable.
@JsonSerializable(explicitToJson: true)
class LockerModel {
  final String id;

  @JsonKey(name: 'cabinetId')
  final String cabinetId;

  @JsonKey(name: 'sizeId')
  final String? sizeId;

  final int row;
  final int column;

  @JsonKey(defaultValue: 'AVAILABLE')
  final String status;

  @JsonKey(name: 'isOpen', defaultValue: false)
  final bool isOpen;

  @JsonKey(name: 'isLocked', defaultValue: true)
  final bool isLocked;

  @JsonKey(name: 'isActive', defaultValue: true)
  final bool isActive;

  /// Nested size object from API
  @JsonKey(name: 'sizeType')
  final LockerSizeModel? size;

  @JsonKey(name: 'createdAt')
  final DateTime? createdAt;

  @JsonKey(name: 'updatedAt')
  final DateTime? updatedAt;

  const LockerModel({
    required this.id,
    required this.cabinetId,
    this.sizeId,
    required this.row,
    required this.column,
    required this.status,
    this.isOpen = false,
    this.isLocked = true,
    this.isActive = true,
    this.size,
    this.createdAt,
    this.updatedAt,
  });

  /// Factory: Tạo từ JSON (generated)
  factory LockerModel.fromJson(Map<String, dynamic> json) =>
      _$LockerModelFromJson(json);

  /// Convert sang JSON (generated)
  Map<String, dynamic> toJson() => _$LockerModelToJson(this);

  /// Convert sang Domain Entity
  Locker toEntity() {
    return Locker(
      id: id,
      cabinetId: cabinetId,
      sizeId: sizeId,
      row: row,
      column: column,
      status: LockerStatus.fromValue(status),
      isOpen: isOpen,
      isLocked: isLocked,
      isActive: isActive,
      size: size?.toValueObject(),
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  /// Factory: Tạo từ Domain Entity
  factory LockerModel.fromEntity(Locker entity) {
    return LockerModel(
      id: entity.id,
      cabinetId: entity.cabinetId,
      sizeId: entity.sizeId,
      row: entity.row,
      column: entity.column,
      status: entity.status.value,
      isOpen: entity.isOpen,
      isLocked: entity.isLocked,
      isActive: entity.isActive,
      size: entity.size != null
          ? LockerSizeModel.fromValueObject(entity.size!)
          : null,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }
}
