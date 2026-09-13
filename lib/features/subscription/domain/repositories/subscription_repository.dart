import 'package:smart_laundry_locker/core/errors/failures.dart';
import 'package:smart_laundry_locker/features/subscription/domain/entities/plan_entity.dart';
import 'package:smart_laundry_locker/features/subscription/domain/entities/subscription_entity.dart';
import 'package:dartz/dartz.dart';

abstract class ISubscriptionRepository {
  Future<Either<Failure, List<PlanEntity>>> getPlans();
  Future<Either<Failure, List<PricingEntity>>> getPricings({String? orderType});
  Future<Either<Failure, SubscriptionEntity>> getActiveSubscription();
  Future<Either<Failure, SubscriptionEntity>> purchaseSubscription({
    required String planId,
    int durationMonths = 1,
  });
}
