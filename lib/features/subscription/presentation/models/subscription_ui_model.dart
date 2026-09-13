import 'package:smart_laundry_locker/features/subscription/presentation/models/plan_ui_model.dart';

class SubscriptionUIModel {
  final String id;
  final String userId;
  final String username;
  final String planId;
  final PlanUIModel? plan;
  final DateTime? startDate;
  final DateTime? endDate;
  final String status;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const SubscriptionUIModel({
    required this.id,
    required this.userId,
    required this.username,
    required this.planId,
    this.plan,
    this.startDate,
    this.endDate,
    required this.status,
    this.createdAt,
    this.updatedAt,
  });

  bool get isActive => status.toUpperCase() == 'ACTIVE';
}
