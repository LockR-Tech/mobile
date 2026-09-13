import 'dart:async';
import 'package:flutter/foundation.dart';
import '../domain/entities/drone_order.dart';

/// Singleton in-memory store shared between user and drone-manager roles.
/// In production this would be replaced by WebSocket / FCM from backend.
class DroneDeliveryStore extends ChangeNotifier {
  DroneDeliveryStore._();
  static final DroneDeliveryStore instance = DroneDeliveryStore._();

  final List<DroneOrder> _orders = [];

  List<DroneOrder> get orders => List.unmodifiable(_orders);

  List<DroneOrder> get pendingOrders =>
      _orders.where((o) => o.status == DroneOrderStatus.pending).toList();

  // Stream so DroneTrackingPage can react to status changes in real-time.
  final _statusCtrl = StreamController<
    ({String orderId, DroneOrderStatus status})
  >.broadcast();

  Stream<({String orderId, DroneOrderStatus status})> get statusStream =>
      _statusCtrl.stream;

  /// User places a drone delivery order.
  void placeOrder(DroneOrder order) {
    _orders.add(order);
    notifyListeners();
  }

  /// Drone manager dispatches a drone for [orderId].
  void dispatch(String orderId) => _setStatus(orderId, DroneOrderStatus.dispatched);

  void _setStatus(String orderId, DroneOrderStatus status) {
    final i = _orders.indexWhere((o) => o.id == orderId);
    if (i < 0) return;
    _orders[i] = _orders[i].copyWith(status: status);
    notifyListeners();
    _statusCtrl.add((orderId: orderId, status: status));
  }

  DroneOrder? orderById(String id) {
    try {
      return _orders.firstWhere((o) => o.id == id);
    } catch (_) {
      return null;
    }
  }
}
