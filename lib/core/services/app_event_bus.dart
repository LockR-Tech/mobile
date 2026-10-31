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

/// A payment succeeded — order and payment history are now stale.
class PaymentCompletedEvent extends AppEvent {
  const PaymentCompletedEvent({this.orderId});
  final String? orderId;
}

/// A payment failed.
class PaymentFailedEvent extends AppEvent {
  const PaymentFailedEvent({this.orderId});
  final String? orderId;
}

/// A maintenance report status changed.
class ReportUpdatedEvent extends AppEvent {
  const ReportUpdatedEvent({this.reportId});
  final String? reportId;
}

/// Locker layout or box status changed (fault, lock, relocate, repair).
class LockerLayoutUpdatedEvent extends AppEvent {
  const LockerLayoutUpdatedEvent({this.lockerId, this.boxId});
  final String? lockerId;
  final String? boxId;
}

/// Điểm/tem thưởng đổi ngoài tay khách: cộng khi đơn hoàn tất, thu hồi khi
/// hoàn tiền, admin điều chỉnh.
class LoyaltyUpdatedEvent extends AppEvent {
  const LoyaltyUpdatedEvent();
}

/// Yêu cầu hoàn tiền của một đơn đổi trạng thái (admin duyệt/từ chối).
class RefundUpdatedEvent extends AppEvent {
  const RefundUpdatedEvent({this.orderId});
  final String? orderId;
}

/// Admin sửa dữ liệu công khai (`/topic/public/catalog`): khuyến mãi, cửa
/// hàng hoặc tủ. [entity] là [promotion], [store] hoặc [locker].
class CatalogChangedEvent extends AppEvent {
  const CatalogChangedEvent({required this.entity, this.id});
  final String entity;
  final String? id;

  static const promotion = 'PROMOTION';
  static const store = 'STORE';
  static const locker = 'LOCKER';

  bool get isPromotion => entity == promotion;
  bool get isStore => entity == store;
  bool get isLocker => entity == locker;
}

/// Việc bảo trì vừa đổi (`/topic/staff/maintenance`, chỉ KTV + ADMIN) — do KTV
/// khác, admin, khách hay hệ thống đổi. [entity] là một trong các hằng dưới.
class MaintenanceChangedEvent extends AppEvent {
  const MaintenanceChangedEvent({required this.entity, this.id, this.lockerId});
  final String entity;
  final String? id;
  final String? lockerId;

  static const report = 'REPORT';
  static const schedule = 'SCHEDULE';
  static const locker = 'LOCKER';
  static const drone = 'DRONE';
  static const droneOrder = 'DRONE_ORDER';
  static const droneIncident = 'DRONE_INCIDENT';
  static const device = 'DEVICE';

  bool get isReport => entity == report;
  bool get isSchedule => entity == schedule;
  bool get isLocker => entity == locker;
  bool get isDrone => entity == drone;
  bool get isDroneOrder => entity == droneOrder;
  bool get isDroneIncident => entity == droneIncident;
  bool get isDevice => entity == device;
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
