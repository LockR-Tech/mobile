abstract class SubscriptionEvent {
  const SubscriptionEvent();
}

class FetchPlansCustomerEvent extends SubscriptionEvent {
  const FetchPlansCustomerEvent();
}

class FetchActiveSubscriptionEvent extends SubscriptionEvent {
  const FetchActiveSubscriptionEvent();
}

class PurchasePlanEvent extends SubscriptionEvent {
  final String planId;
  final int walletBalance;
  final int expectedTotalCost;
  final int durationMonths;

  const PurchasePlanEvent({
    required this.planId,
    required this.walletBalance,
    required this.expectedTotalCost,
    this.durationMonths = 1,
  });
}
