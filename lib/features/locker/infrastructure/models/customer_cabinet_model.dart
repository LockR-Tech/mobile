import 'package:smart_laundry_locker/features/locker/domain/entities/cabinet.dart';
import 'package:json_annotation/json_annotation.dart';

part 'customer_cabinet_model.g.dart';

/// Infrastructure Model: CustomerCabinetModel
/// Specifically for the GET /locations/:id/customer/cabinets response
@JsonSerializable()
class CustomerCabinetModel {
  final String id;
  final String name;
  final String? locationName;
  final String? address;

  const CustomerCabinetModel({
    required this.id,
    required this.name,
    this.locationName,
    this.address,
  });

  factory CustomerCabinetModel.fromJson(Map<String, dynamic> json) =>
      _$CustomerCabinetModelFromJson(json);

  Map<String, dynamic> toJson() => _$CustomerCabinetModelToJson(this);

  /// Convert to Domain Entity
  Cabinet toEntity() {
    return Cabinet(
      id: id,
      name: name,
      locationName: locationName,
      address: address,
      // Default values for fields missing in this specific API
      locationId: null,
      totalRows: 0,
      totalColumns: 0,
    );
  }
}
