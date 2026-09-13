class LockerRentRequestModel {
  final String cabinetId;
  final String lockerId;
  final int rentMonths;
  final int? rentDays;
  final String itemType;
  final bool? skipPhysicalOpen;
  final String? voucherId;

  const LockerRentRequestModel({
    required this.cabinetId,
    required this.lockerId,
    required this.rentMonths,
    this.rentDays,
    this.itemType = 'OTHER',
    this.skipPhysicalOpen,
    this.voucherId,
  });

  Map<String, dynamic> toJson() {
    return {
      'cabinetId': cabinetId,
      'lockerId': lockerId,
      'rentMonths': rentMonths,
      if (rentDays != null) 'rentDays': rentDays,
      'itemType': itemType,
      if (skipPhysicalOpen != null) 'skipPhysicalOpen': skipPhysicalOpen,
      if (voucherId != null) 'voucherId': voucherId,
    };
  }
}
