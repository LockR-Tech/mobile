import 'package:smart_laundry_locker/features/locker/domain/entities/fixed_rent_entity.dart';

class LockerRentState {
  final bool isSubmitting;
  final bool isTogglingLocker;
  final String? error;
  final String? successMessage;
  final FixedRentEntity? fixedRent;
  final FixedRentEntity? flexibleRent;

  const LockerRentState({
    this.isSubmitting = false,
    this.isTogglingLocker = false,
    this.error,
    this.successMessage,
    this.fixedRent,
    this.flexibleRent,
  });

  LockerRentState copyWith({
    bool? isSubmitting,
    bool? isTogglingLocker,
    String? error,
    String? successMessage,
    FixedRentEntity? fixedRent,
    FixedRentEntity? flexibleRent,
    bool clearError = false,
    bool clearSuccess = false,
  }) {
    return LockerRentState(
      isSubmitting: isSubmitting ?? this.isSubmitting,
      isTogglingLocker: isTogglingLocker ?? this.isTogglingLocker,
      error: clearError ? null : (error ?? this.error),
      successMessage: clearSuccess
          ? null
          : (successMessage ?? this.successMessage),
      fixedRent: fixedRent ?? this.fixedRent,
      flexibleRent: clearSuccess ? null : (flexibleRent ?? this.flexibleRent),
    );
  }
}
