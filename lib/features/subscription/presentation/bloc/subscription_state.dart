import 'package:smart_laundry_locker/features/subscription/domain/entities/plan_entity.dart';
import 'package:smart_laundry_locker/features/subscription/domain/entities/subscription_entity.dart';

abstract class SubscriptionState {
  final List<PlanEntity> plans;
  final SubscriptionEntity? activeSubscription;

  const SubscriptionState({this.plans = const [], this.activeSubscription});
}

class SubscriptionInitial extends SubscriptionState {
  const SubscriptionInitial();
}

class SubscriptionLoading extends SubscriptionState {
  const SubscriptionLoading({super.plans, super.activeSubscription});
}

class PlansLoaded extends SubscriptionState {
  const PlansLoaded({required super.plans, super.activeSubscription});
}

class SubscriptionSuccess extends SubscriptionState {
  final String message;

  const SubscriptionSuccess({
    required this.message,
    required super.plans,
    super.activeSubscription,
  });
}

class SubscriptionFailure extends SubscriptionState {
  final String message;

  const SubscriptionFailure({
    required this.message,
    super.plans,
    super.activeSubscription,
  });
}
