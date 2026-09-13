import 'package:smart_laundry_locker/core/errors/failures.dart';
import 'package:smart_laundry_locker/features/subscription/application/use_cases/get_active_subscription_use_case.dart';
import 'package:smart_laundry_locker/features/subscription/application/use_cases/get_plans_use_case.dart';
import 'package:smart_laundry_locker/features/subscription/application/use_cases/purchase_subscription_use_case.dart';
import 'package:smart_laundry_locker/features/subscription/presentation/bloc/subscription_event.dart';
import 'package:smart_laundry_locker/features/subscription/presentation/bloc/subscription_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SubscriptionBloc extends Bloc<SubscriptionEvent, SubscriptionState> {
  final GetPlansUseCase _getPlansUseCase;
  final GetActiveSubscriptionUseCase _getActiveSubscriptionUseCase;
  final PurchaseSubscriptionUseCase _purchaseSubscriptionUseCase;

  SubscriptionBloc({
    required GetPlansUseCase getPlansUseCase,
    required GetActiveSubscriptionUseCase getActiveSubscriptionUseCase,
    required PurchaseSubscriptionUseCase purchaseSubscriptionUseCase,
  }) : _getPlansUseCase = getPlansUseCase,
       _getActiveSubscriptionUseCase = getActiveSubscriptionUseCase,
       _purchaseSubscriptionUseCase = purchaseSubscriptionUseCase,
       super(const SubscriptionInitial()) {
    on<FetchPlansCustomerEvent>(_onFetchPlans);
    on<FetchActiveSubscriptionEvent>(_onFetchActiveSubscription);
    on<PurchasePlanEvent>(_onPurchasePlan);
  }

  Future<void> _onFetchPlans(
    FetchPlansCustomerEvent event,
    Emitter<SubscriptionState> emit,
  ) async {
    emit(
      SubscriptionLoading(
        plans: state.plans,
        activeSubscription: state.activeSubscription,
      ),
    );
    final result = await _getPlansUseCase();
    result.fold(
      (failure) => emit(
        SubscriptionFailure(
          message: failure.message,
          plans: state.plans,
          activeSubscription: state.activeSubscription,
        ),
      ),
      (plans) => emit(
        PlansLoaded(plans: plans, activeSubscription: state.activeSubscription),
      ),
    );
  }

  Future<void> _onFetchActiveSubscription(
    FetchActiveSubscriptionEvent event,
    Emitter<SubscriptionState> emit,
  ) async {
    final result = await _getActiveSubscriptionUseCase();
    result.fold(
      (failure) {
        if (failure is NotFoundFailure) {
          emit(PlansLoaded(plans: state.plans, activeSubscription: null));
          return;
        }
        emit(
          SubscriptionFailure(
            message: failure.message,
            plans: state.plans,
            activeSubscription: state.activeSubscription,
          ),
        );
      },
      (active) =>
          emit(PlansLoaded(plans: state.plans, activeSubscription: active)),
    );
  }

  Future<void> _onPurchasePlan(
    PurchasePlanEvent event,
    Emitter<SubscriptionState> emit,
  ) async {
    final selectedPlan = state.plans
        .where((p) => p.id == event.planId)
        .toList();
    if (selectedPlan.isEmpty) {
      emit(
        SubscriptionFailure(
          message: 'Không tìm thấy gói cước đã chọn.',
          plans: state.plans,
          activeSubscription: state.activeSubscription,
        ),
      );
      return;
    }

    final currentPlan = state.activeSubscription?.plan;
    if (currentPlan != null &&
        !currentPlan.isFreeDefault &&
        selectedPlan.first.price <= currentPlan.price) {
      emit(
        SubscriptionFailure(
          message: 'Hệ thống hiện chưa hỗ trợ hạ cấp gói cước.',
          plans: state.plans,
          activeSubscription: state.activeSubscription,
        ),
      );
      return;
    }

    if (event.walletBalance < event.expectedTotalCost) {
      emit(
        SubscriptionFailure(
          message: 'Số dư không đủ để mua gói.',
          plans: state.plans,
          activeSubscription: state.activeSubscription,
        ),
      );
      return;
    }

    emit(
      SubscriptionLoading(
        plans: state.plans,
        activeSubscription: state.activeSubscription,
      ),
    );

    final result = await _purchaseSubscriptionUseCase(
      planId: event.planId,
      durationMonths: event.durationMonths,
    );
    result.fold(
      (failure) => emit(
        SubscriptionFailure(
          message: failure.message,
          plans: state.plans,
          activeSubscription: state.activeSubscription,
        ),
      ),
      (subscription) => emit(
        SubscriptionSuccess(
          message: 'Mua gói thành công!',
          plans: state.plans,
          activeSubscription: subscription,
        ),
      ),
    );
  }
}
