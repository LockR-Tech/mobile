import 'package:smart_laundry_locker/features/subscription/domain/entities/subscription_entity.dart';
import 'package:smart_laundry_locker/features/subscription/infrastructure/models/plan_model.dart';

class SubscriptionModel extends SubscriptionEntity {
  const SubscriptionModel({
    required super.id,
    required super.status,
    super.startDate,
    super.endDate,
    super.plan,
    super.receiverEmail,
    super.receiverPhone,
  });

  factory SubscriptionModel.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic value) {
      if (value is String && value.isNotEmpty) {
        return DateTime.tryParse(value);
      }
      return null;
    }

    final dynamic planRaw = json['plan'];

    return SubscriptionModel(
      id: (json['id'] ?? '').toString(),
      status: (json['status'] ?? '').toString(),
      startDate: parseDate(json['startDate'] ?? json['start_date']),
      endDate: parseDate(json['endDate'] ?? json['end_date']),
      plan: planRaw is Map<String, dynamic>
          ? PlanModel.fromJson(planRaw)
          : null,
      receiverEmail: json['receiverEmail']?.toString(),
      receiverPhone:
          json['receiverPhone']?.toString() ??
          json['receiverEmail']?.toString(),
    );
  }
}
