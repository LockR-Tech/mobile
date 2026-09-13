import 'package:smart_laundry_locker/features/locker/application/use_cases/control_locker_use_case.dart';

abstract class LockerRentEvent {
  const LockerRentEvent();
}

class OnConfirmFixedRent extends LockerRentEvent {
  final String cabinetId;
  final String lockerId;
  final int rentMonths;
  final int? rentDays;
  final bool skipPhysicalOpen;
  final String itemType;
  final String? voucherId;

  const OnConfirmFixedRent({
    required this.cabinetId,
    required this.lockerId,
    required this.rentMonths,
    this.rentDays,
    this.skipPhysicalOpen = false,
    this.itemType = 'OTHER',
    this.voucherId,
  });
}

class OnConfirmFlexibleRent extends LockerRentEvent {
  final String cabinetId;
  final String lockerId;
  final bool skipPhysicalOpen;
  final String itemType;
  final String? voucherId;

  const OnConfirmFlexibleRent({
    required this.cabinetId,
    required this.lockerId,
    this.skipPhysicalOpen = false,
    this.itemType = 'OTHER',
    this.voucherId,
  });
}

class OnToggleLockerStatus extends LockerRentEvent {
  final String lockerId;
  final LockerControlType type;

  const OnToggleLockerStatus({required this.lockerId, required this.type});
}
