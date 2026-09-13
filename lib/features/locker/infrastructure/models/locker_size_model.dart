import 'package:smart_laundry_locker/features/locker/domain/value_objects/locker_size.dart';
import 'package:json_annotation/json_annotation.dart';

part 'locker_size_model.g.dart';

/// Infrastructure Model: LockerSizeModel
/// Data model cho LockerSize, dùng json_serializable.
@JsonSerializable()
class LockerSizeModel {
  final String id;
  @JsonKey(name: 'name')
  final String label;
  final double width;
  final double height;
  final double depth;
  final String? description;

  const LockerSizeModel({
    required this.id,
    required this.label,
    required this.width,
    required this.height,
    required this.depth,
    this.description,
  });

  /// Factory: Tạo từ JSON (generated)
  factory LockerSizeModel.fromJson(Map<String, dynamic> json) =>
      _$LockerSizeModelFromJson(json);

  /// Convert sang JSON (generated)
  Map<String, dynamic> toJson() => _$LockerSizeModelToJson(this);

  /// Convert sang Value Object
  LockerSize toValueObject() {
    return LockerSize(
      id: id,
      label: label,
      width: width,
      height: height,
      depth: depth,
      description: description,
    );
  }

  /// Factory: Tạo từ Value Object
  factory LockerSizeModel.fromValueObject(LockerSize size) {
    return LockerSizeModel(
      id: size.id,
      label: size.label,
      width: size.width,
      height: size.height,
      depth: size.depth,
      description: size.description,
    );
  }
}
