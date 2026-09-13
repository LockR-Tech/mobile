import 'package:smart_laundry_locker/features/notifications/domain/entities/notification_model.dart';
import 'package:smart_laundry_locker/features/notifications/infrastructure/services/realtime_notification_service.dart';
import 'package:smart_laundry_locker/features/notifications/infrastructure/repositories/notification_repository.dart';
import 'package:smart_laundry_locker/core/services/firebase_messaging_service.dart';
import 'package:smart_laundry_locker/core/services/token_service.dart';
import 'package:smart_laundry_locker/core/services/app_event_bus.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';

class NotificationProvider extends ChangeNotifier {
  final NotificationRepository _repository;
  StreamSubscription? _messageSubscription;
  StreamSubscription? _realtimeSubscription;

  NotificationProvider(this._repository) {
    _initMessageListener();
    _initRealtimeListener();
  }

  void _initMessageListener() {
    _messageSubscription = FirebaseMessagingService.instance.onMessageReceived
        .listen((message) {
          debugPrint(
            'New message received in NotificationProvider: refreshing count',
          );
          loadUnreadCount();
          // Propagate FCM data-type to domain event bus so screens auto-refresh
          _emitDomainEvent(
            message.data['type'] as String?,
            message.data['referenceId']?.toString(),
          );
        });
  }

  void _initRealtimeListener() {
    TokenService.authState.addListener(_handleAuthStateChanged);
    _handleAuthStateChanged();
    _realtimeSubscription = RealtimeNotificationService.instance.notifications
        .listen((notification) {
          final exists = _notifications.any((n) => n.id == notification.id);
          if (!exists) {
            _notifications.insert(0, notification);
          }
          if (!notification.isRead) {
            _unreadCount = exists ? _unreadCount : _unreadCount + 1;
          }
          notifyListeners();
          // Propagate STOMP notification type to domain event bus
          _emitDomainEvent(
            notification.dataPayload?.actionType,
            notification.dataPayload?.referenceId,
          );
        });
  }

  static void _emitDomainEvent(String? actionType, String? referenceId) {
    final bus = AppEventBus.instance;
    switch (actionType) {
      case 'ORDER_STATUS_CHANGED':
        bus.emit(OrderChangedEvent(orderId: referenceId));
      case 'PAYMENT_COMPLETED':
        bus.emit(PaymentCompletedEvent(orderId: referenceId));
        bus.emit(const WalletUpdatedEvent());
      case 'PAYMENT_FAILED':
        bus.emit(PaymentFailedEvent(orderId: referenceId));
      case 'LOCKER_REPORT_CLAIMED':
      case 'LOCKER_REPORT_RESOLVED':
        bus.emit(ReportUpdatedEvent(reportId: referenceId));
    }
  }

  void _handleAuthStateChanged() {
    if (TokenService.authState.value) {
      unawaited(RealtimeNotificationService.instance.connect());
    } else {
      RealtimeNotificationService.instance.disconnect();
    }
  }

  @override
  void dispose() {
    TokenService.authState.removeListener(_handleAuthStateChanged);
    _messageSubscription?.cancel();
    _realtimeSubscription?.cancel();
    RealtimeNotificationService.instance.disconnect();
    super.dispose();
  }

  List<NotificationModel> _notifications = [];
  List<NotificationModel> get notifications => _notifications;

  int _unreadCount = 0;
  int get unreadCount => _unreadCount;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isLoadingMore = false;
  bool get isLoadingMore => _isLoadingMore;

  String? _error;
  String? get error => _error;

  int _currentPage = 1;
  int _totalPages = 1;

  bool get hasMore => _currentPage < _totalPages;

  Future<void> loadUnreadCount() async {
    try {
      final count = await _repository.getUnreadCount();
      _unreadCount = count;
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to fetch unread count: $e');
    }
  }

  Future<void> loadNotifications({bool refresh = false}) async {
    if (refresh) {
      _currentPage = 1;
      _notifications.clear();
      _error = null;
    }

    if (_isLoading) return;

    _isLoading = true;
    notifyListeners();

    try {
      final response = await _repository.getNotifications(
        page: _currentPage,
        limit: 15,
      );

      _notifications.addAll(response.items);
      _totalPages = response.meta.totalPages;
      _error = null;

      // Also refresh unread count whenever we load notifications
      await loadUnreadCount();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadMore() async {
    if (_isLoadingMore || !hasMore || _isLoading) return;

    _isLoadingMore = true;
    _currentPage++;
    notifyListeners();

    try {
      final response = await _repository.getNotifications(
        page: _currentPage,
        limit: 15,
      );
      _notifications.addAll(response.items);
    } catch (e) {
      _error = e.toString();
      _currentPage--; // Revert page on failure
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  Future<void> markAsRead(String id) async {
    // Find notification locally and optimistic update
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index == -1 || _notifications[index].isRead) return;

    final originalState = _notifications[index];
    _notifications[index] = originalState.copyWith(isRead: true);
    if (_unreadCount > 0) _unreadCount--;
    notifyListeners();

    try {
      await _repository.markAsRead(id);
    } catch (e) {
      // Revert if failed
      _notifications[index] = originalState;
      _unreadCount++;
      notifyListeners();
      debugPrint('Failed to mark as read: $e');
    }
  }

  Future<void> markAllAsRead() async {
    if (_unreadCount == 0) return;

    // Optimistic update
    final List<NotificationModel> prevNotifications = List.from(_notifications);
    final prevCount = _unreadCount;

    for (int i = 0; i < _notifications.length; i++) {
      _notifications[i] = _notifications[i].copyWith(isRead: true);
    }
    _unreadCount = 0;
    notifyListeners();

    try {
      await _repository.markAllAsRead();
    } catch (e) {
      // Revert if failed
      _notifications = prevNotifications;
      _unreadCount = prevCount;
      notifyListeners();
      debugPrint('Failed to mark all as read: $e');
    }
  }
}
