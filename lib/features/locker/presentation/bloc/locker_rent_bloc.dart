import 'package:smart_laundry_locker/features/locker/application/use_cases/control_locker_use_case.dart';
import 'package:smart_laundry_locker/features/locker/application/use_cases/fixed_rent_use_case.dart';
import 'package:smart_laundry_locker/features/locker/application/use_cases/rent_locker_flexible_use_case.dart';
import 'package:smart_laundry_locker/features/locker/presentation/bloc/locker_rent_event.dart';
import 'package:smart_laundry_locker/features/locker/presentation/bloc/locker_rent_state.dart';
import 'package:smart_laundry_locker/features/locker/infrastructure/models/fixed_rent_response_model.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class LockerRentBloc extends Bloc<LockerRentEvent, LockerRentState> {
  final FixedRentUseCase _fixedRentUseCase;
  final RentLockerFlexibleUseCase _rentLockerFlexibleUseCase;
  final ControlLockerUseCase _controlLockerUseCase;

  LockerRentBloc({
    required FixedRentUseCase fixedRentUseCase,
    required RentLockerFlexibleUseCase rentLockerFlexibleUseCase,
    required ControlLockerUseCase controlLockerUseCase,
  }) : _fixedRentUseCase = fixedRentUseCase,
       _rentLockerFlexibleUseCase = rentLockerFlexibleUseCase,
       _controlLockerUseCase = controlLockerUseCase,
       super(const LockerRentState()) {
    on<OnConfirmFixedRent>(_onConfirmFixedRent);
    on<OnConfirmFlexibleRent>(_onConfirmFlexibleRent);
    on<OnToggleLockerStatus>(_onToggleLockerStatus);
  }

  Future<void> _onConfirmFixedRent(
    OnConfirmFixedRent event,
    Emitter<LockerRentState> emit,
  ) async {
    emit(
      state.copyWith(isSubmitting: true, clearError: true, clearSuccess: true),
    );

    final result = await _fixedRentUseCase(
      cabinetId: event.cabinetId,
      lockerId: event.lockerId,
      rentMonths: event.rentMonths,
      rentDays: event.rentDays,
      itemType: event.itemType,
      skipPhysicalOpen: event.skipPhysicalOpen,
      voucherId: event.voucherId,
    );

    result.fold(
      (failure) => emit(
        state.copyWith(
          isSubmitting: false,
          error: failure.message,
          clearSuccess: true,
        ),
      ),
      (data) => emit(
        state.copyWith(
          isSubmitting: false,
          fixedRent: data,
          successMessage: 'Thanh toán thành công',
          clearError: true,
        ),
      ),
    );
  }

  Future<void> _onConfirmFlexibleRent(
    OnConfirmFlexibleRent event,
    Emitter<LockerRentState> emit,
  ) async {
    emit(
      state.copyWith(isSubmitting: true, clearError: true, clearSuccess: true),
    );

    final result = await _rentLockerFlexibleUseCase(
      lockerId: event.lockerId,
      cabinetId: event.cabinetId,
      itemType: event.itemType,
      skipPhysicalOpen: event.skipPhysicalOpen,
      voucherId: event.voucherId,
    );

    result.fold(
      (failure) => emit(
        state.copyWith(
          isSubmitting: false,
          error: failure.message,
          clearSuccess: true,
        ),
      ),
      (data) => emit(
        state.copyWith(
          isSubmitting: false,
          flexibleRent: FixedRentResponseModel.fromJson(data).entity,
          successMessage: 'Thanh toán thành công',
          clearError: true,
        ),
      ),
    );
  }

  Future<void> _onToggleLockerStatus(
    OnToggleLockerStatus event,
    Emitter<LockerRentState> emit,
  ) async {
    emit(
      state.copyWith(
        isTogglingLocker: true,
        clearError: true,
        clearSuccess: true,
      ),
    );

    final result = await _controlLockerUseCase(
      lockerId: event.lockerId,
      type: event.type,
    );
    result.fold(
      (failure) => emit(
        state.copyWith(
          isTogglingLocker: false,
          error: failure.message,
          clearSuccess: true,
        ),
      ),
      (_) => emit(
        state.copyWith(
          isTogglingLocker: false,
          successMessage: event.type == LockerControlType.open
              ? 'Đã gửi lệnh mở tủ.'
              : 'Đã gửi lệnh đóng tủ.',
          clearError: true,
        ),
      ),
    );
  }
}
