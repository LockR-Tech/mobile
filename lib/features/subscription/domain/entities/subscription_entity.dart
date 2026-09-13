import 'package:smart_laundry_locker/features/subscription/domain/entities/plan_entity.dart';

class SubscriptionEntity {
  final String id;
  final String status;
  final DateTime? startDate;
  final DateTime? endDate;
  final PlanEntity? plan;

  final String? receiverEmail;
  final String? receiverPhone;

  const SubscriptionEntity({
    required this.id,
    required this.status,
    this.startDate,
    this.endDate,
    this.plan,
    this.receiverEmail,
    this.receiverPhone,
  });
}
