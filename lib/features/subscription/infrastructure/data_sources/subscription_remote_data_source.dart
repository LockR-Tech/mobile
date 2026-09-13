import 'package:smart_laundry_locker/features/subscription/domain/entities/plan_entity.dart';
import 'package:smart_laundry_locker/features/subscription/infrastructure/models/plan_model.dart';
import 'package:smart_laundry_locker/features/subscription/infrastructure/models/subscription_model.dart';

abstract class SubscriptionRemoteDataSource {
  Future<List<PlanModel>> getPlans();
  Future<List<PricingEntity>> getPricings({String? orderType});
  Future<PlanModel> getPlanDetail(String planId);
  Future<SubscriptionModel> getActiveSubscription();
  Future<SubscriptionModel> purchaseSubscription({
    required String planId,
    int durationMonths = 1,
  });
}
