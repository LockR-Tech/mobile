import 'package:smart_laundry_locker/features/notifications/domain/entities/notification_model.dart';
import 'package:smart_laundry_locker/features/notifications/infrastructure/services/realtime_notification_service.dart';
import 'package:smart_laundry_locker/features/notifications/infrastructure/repositories/notification_repository.dart';
import 'package:smart_laundry_locker/core/services/firebase_messaging_service.dart';
import 'package:smart_laundry_locker/core/services/token_service.dart';
import 'package:smart_laundry_locker/core/services/app_event_bus.dart';
import 'package:smart_laundry_locker/core/utils/user_error_message.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';
import 'package:smart_laundry_locker/core/l10n/l10n.dart';

class NotificationProvider extends ChangeNotifier {
  final NotificationRepository _repository;
  StreamSubscription? _messageSubscription;
  StreamSubscription? _realtimeSubscription;
  StreamSubscription? _orderUpdateSubscription;
  StreamSubscription? _userEventSubscription;
  StreamSubscription? _catalogSubscription;
  StreamSubscription? _maintenanceSubscription;

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
          emitDomainEvent(
            message.data['type'] as String?,
            message.data['referenceId']?.toString(),
            referenceType: message.data['referenceType']?.toString(),
          );
        });
  }

  void _initRealtimeListener() {
    TokenService.authState.addListener(_handleAuthStateChanged);
    _handleAuthStateChanged();
    _realtimeSubscription = RealtimeNotificationService.instance.notifications
        .listen((notification) {
          // Thông báo không có id thì không lưu ở server (không xoá/đánh dấu
          // đọc được) — service đã lọc, chặn thêm ở đây cho chắc.
          if (notification.id.isEmpty) return;
          final exists = _notifications.any((n) => n.id == notification.id);
          if (!exists) {
            _notifications.insert(0, notification);
          }
          if (!notification.isRead) {
            _unreadCount = exists ? _unreadCount : _unreadCount + 1;
          }
          notifyListeners();
          // Propagate STOMP notification type to domain event bus
          emitDomainEvent(
            notification.dataPayload?.actionType,
            notification.dataPayload?.referenceId,
            referenceType: notification.dataPayload?.referenceType,
          );
        });
    // Tin cập nhật đơn (`/user/queue/orders`) chỉ làm mới màn đơn: không thêm
    // vào danh sách thông báo, không tăng badge (trước đây tạo dòng trống).
    // Mọi tin ở kênh này đều là đơn vừa đổi, kể cả loại không có chữ ORDER
    // (REFUND_COMPLETED, FEEDBACK_REPLY…) — trước đây các tin đó bị bỏ qua.
    _orderUpdateSubscription = RealtimeNotificationService.instance.orderUpdates
        .listen(
          (update) => emitDomainEvent(
            update.type,
            update.orderId,
            referenceType: 'ORDER',
          ),
        );
    // Ví/điểm thưởng đổi do người khác (admin, hệ thống) mà không kèm thông báo.
    _userEventSubscription = RealtimeNotificationService.instance.userEvents
        .listen(
          (event) => emitDomainEvent(
            event.type,
            event.referenceId,
            referenceType: event.referenceType,
          ),
        );
    _catalogSubscription = RealtimeNotificationService.instance.catalogChanges
        .listen(
          (change) => AppEventBus.instance.emit(
            CatalogChangedEvent(entity: change.entity, id: change.id),
          ),
        );
    // KTV: phiếu/lịch/tủ/drone/đơn drone/thiết bị đổi do người khác.
    _maintenanceSubscription = RealtimeNotificationService
        .instance
        .maintenanceChanges
        .listen(
          (change) => AppEventBus.instance.emit(
            MaintenanceChangedEvent(
              entity: change.entity,
              id: change.id,
              lockerId: change.lockerId,
            ),
          ),
        );
  }

  /// Dịch một tin realtime (thông báo, tin đơn, tin đồng bộ, push FCM) thành
  /// sự kiện miền để các màn đang mở tự tải lại.
  @visibleForTesting
  static void emitDomainEvent(
    String? actionType,
    String? referenceId, {
    String? referenceType,
  }) {
    final bus = AppEventBus.instance;
    final action = (actionType ?? '').toUpperCase();
    final refType = (referenceType ?? '').toUpperCase();

    // Gắn với đơn theo tên loại (ORDER_*, DELIVERY…) hoặc theo tham chiếu:
    // hoàn tiền, trả lời phản hồi… có `referenceType = ORDER` dù tên loại
    // không chứa chữ ORDER.
    if (action.contains('ORDER') ||
        action.contains('DELIVERY') ||
        refType == 'ORDER' ||
        refType == 'DELIVERY') {
      bus.emit(OrderChangedEvent(orderId: referenceId));
      bus.emit(const LockerLayoutUpdatedEvent());
    }

    // Admin duyệt/từ chối hoàn tiền, nhắc cập nhật STK nhận hoàn tiền.
    if (action.contains('REFUND') || refType == 'REFUND') {
      bus.emit(RefundUpdatedEvent(orderId: referenceId));
    }

    if (action.contains('LOYALTY') || refType == 'LOYALTY') {
      bus.emit(const LoyaltyUpdatedEvent());
    }

    if (action == 'PAYMENT_COMPLETED') {
      bus.emit(PaymentCompletedEvent(orderId: referenceId));
      bus.emit(OrderChangedEvent(orderId: referenceId));
    } else if (action == 'PAYMENT_FAILED') {
      bus.emit(PaymentFailedEvent(orderId: referenceId));
      bus.emit(OrderChangedEvent(orderId: referenceId));
    }

    if (action.contains('REPORT') ||
        action.contains('SCHEDULE') ||
        action.contains('RECOVERY') ||
        action.contains('RATING')) {
      bus.emit(ReportUpdatedEvent(reportId: referenceId));
    }

    if (action.contains('LOCKER') ||
        action.contains('BOX') ||
        action.contains('DEVICE') ||
        action.contains('IOT')) {
      bus.emit(LockerLayoutUpdatedEvent(lockerId: referenceId));
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
    _orderUpdateSubscription?.cancel();
    _userEventSubscription?.cancel();
    _catalogSubscription?.cancel();
    _maintenanceSubscription?.cancel();
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
    // Phải chặn trùng lệnh TRƯỚC khi xoá danh sách: bản cũ xoá xong mới thấy
    // `_isLoading` rồi `return`, nên một lần refresh trùng với lần nạp đang
    // chạy sẽ để lại danh sách rỗng cho tới lần nạp sau.
    if (_isLoading) return;

    if (refresh) {
      _currentPage = 1;
      _notifications.clear();
      _error = null;
    }

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
      _error = userErrorMessage(
        e,
        fallback: L10n.current.npLoadFailed,
      );
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
      _error = userErrorMessage(
        e,
        fallback: L10n.current.npLoadMoreFailed,
      );
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

  /// Xoá một thông báo (vuốt). Xoá ngay trên màn hình, lỗi thì trả lại chỗ cũ.
  /// Trả thông báo lỗi tiếng Việt hoặc `null` khi thành công.
  Future<String?> deleteNotification(String id) async {
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index == -1) return null;
    final removed = _notifications.removeAt(index);
    final wasUnread = !removed.isRead;
    if (wasUnread && _unreadCount > 0) _unreadCount--;
    notifyListeners();

    try {
      await _repository.deleteNotification(id);
      return null;
    } catch (e) {
      _notifications.insert(index.clamp(0, _notifications.length), removed);
      if (wasUnread) _unreadCount++;
      notifyListeners();
      debugPrint('Failed to delete notification: $e');
      return userErrorMessage(
        e,
        notFound: L10n.current.npDeleteNotFound,
        fallback: L10n.current.npDeleteFailed,
      );
    }
  }

  /// Xoá tất cả thông báo của tài khoản. Trả lỗi tiếng Việt hoặc `null`.
  Future<String?> deleteAllNotifications() async {
    if (_notifications.isEmpty) return null;
    final previous = List<NotificationModel>.from(_notifications);
    final previousUnread = _unreadCount;
    final previousPage = _currentPage;
    final previousTotalPages = _totalPages;
    _notifications = [];
    _unreadCount = 0;
    _currentPage = 1;
    _totalPages = 1;
    notifyListeners();

    try {
      await _repository.deleteAllNotifications();
      return null;
    } catch (e) {
      _notifications = previous;
      _unreadCount = previousUnread;
      _currentPage = previousPage;
      _totalPages = previousTotalPages;
      notifyListeners();
      debugPrint('Failed to delete all notifications: $e');
      return userErrorMessage(
        e,
        notFound: L10n.current.npDeleteNotSupported,
        fallback: L10n.current.npDeleteFailed,
      );
    }
  }
}
