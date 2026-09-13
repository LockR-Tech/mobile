import 'dart:async';

// ── Typed domain events ───────────────────────────────────────────────────────

abstract class AppEvent {
  const AppEvent();
}

/// An order was created, updated, or its status changed.
class OrderChangedEvent extends AppEvent {
  const OrderChangedEvent({this.orderId});
  final String? orderId;
}

/// A payment succeeded — wallet balance is now stale.
class PaymentCompletedEvent extends AppEvent {
  const PaymentCompletedEvent({this.orderId});
  final String? orderId;
}

/// A payment failed.
class PaymentFailedEvent extends AppEvent {
  const PaymentFailedEvent({this.orderId});
  final String? orderId;
}

/// Wallet balance changed (top-up, payment, refund).
class WalletUpdatedEvent extends AppEvent {
  const WalletUpdatedEvent();
}

/// A maintenance report status changed.
class ReportUpdatedEvent extends AppEvent {
  const ReportUpdatedEvent({this.reportId});
  final String? reportId;
}

// ── Singleton bus ─────────────────────────────────────────────────────────────

/// App-wide synchronous event bus for domain events.
///
/// Emitters call [emit] after any API response or realtime notification.
/// Listeners (screens / providers) subscribe in initState / constructor and
/// cancel in dispose — no coupling between producers and consumers.
class AppEventBus {
  AppEventBus._();
  static final AppEventBus instance = AppEventBus._();

  final _controller = StreamController<AppEvent>.broadcast();

  /// Subscribe to all domain events.
  Stream<AppEvent> get events => _controller.stream;

  /// Emit a typed domain event to all current subscribers.
  void emit(AppEvent event) {
    if (!_controller.isClosed) _controller.add(event);
  }
}
