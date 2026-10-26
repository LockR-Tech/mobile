import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:smart_laundry_locker/core/constants/api_constants.dart';
import 'package:smart_laundry_locker/core/services/token_service.dart';
import 'package:smart_laundry_locker/features/drone_delivery/infrastructure/services/locker_availability_socket_service.dart';
import 'package:smart_laundry_locker/features/notifications/domain/entities/notification_model.dart';
import 'package:stomp_dart_client/stomp_dart_client.dart';

/// Một tin cập nhật đơn qua `/user/queue/orders` — KHÔNG phải thông báo.
///
/// notification-service đẩy tin này kèm mỗi thông báo liên quan đơn (và cả sự
/// kiện đơn không có thông báo). Nó không có `id` thông báo, nhiều khi không có
/// tiêu đề, nên trước đây bị đọc thành [NotificationModel] rỗng: danh sách hiện
/// dòng "Thông báo" trống và badge tăng thêm 1. Giờ chỉ dùng để làm mới màn đơn.
class OrderUpdateMessage {
  final String? type;
  final String? orderId;
  final Map<String, dynamic> raw;

  const OrderUpdateMessage({this.type, this.orderId, required this.raw});

  factory OrderUpdateMessage.fromJson(Map<String, dynamic> json) {
    final type = json['type'] ?? json['status'];
    final orderId = json['orderId'] ?? json['referenceId'];
    return OrderUpdateMessage(
      type: type?.toString(),
      orderId: orderId?.toString(),
      raw: json,
    );
  }
}

/// Tin đồng bộ riêng tài khoản qua `/user/queue/events` — ví hoặc điểm thưởng
/// vừa đổi mà không kèm thông báo (`wallet.updated`, `loyalty.points.changed`).
class UserSyncMessage {
  final String? type;
  final String? referenceType;
  final String? referenceId;

  const UserSyncMessage({this.type, this.referenceType, this.referenceId});

  factory UserSyncMessage.fromJson(Map<String, dynamic> json) =>
      UserSyncMessage(
        type: json['type']?.toString(),
        referenceType: json['referenceType']?.toString(),
        referenceId: json['referenceId']?.toString(),
      );
}

/// Admin vừa sửa dữ liệu công khai (`/topic/public/catalog`): chỉ có loại
/// (`PROMOTION`, `STORE`, `LOCKER`) và mã.
class CatalogChangeMessage {
  final String entity;
  final String? id;

  const CatalogChangeMessage({required this.entity, this.id});

  /// Thiếu `entity` ⇒ null (khung lạ, bỏ qua).
  static CatalogChangeMessage? fromJson(Map<String, dynamic> json) {
    final entity = json['entity']?.toString().trim().toUpperCase() ?? '';
    if (entity.isEmpty) return null;
    return CatalogChangeMessage(entity: entity, id: json['id']?.toString());
  }
}

/// Việc bảo trì vừa đổi (`/topic/staff/maintenance`, chỉ KTV + ADMIN): loại
/// (`REPORT`, `SCHEDULE`, `LOCKER`, `DRONE`, `DRONE_ORDER`, `DRONE_INCIDENT`,
/// `DEVICE`), mã và mã tủ nếu có.
class MaintenanceChangeMessage {
  final String entity;
  final String? id;
  final String? lockerId;

  const MaintenanceChangeMessage({
    required this.entity,
    this.id,
    this.lockerId,
  });

  /// Thiếu `entity` ⇒ null (khung lạ, bỏ qua).
  static MaintenanceChangeMessage? fromJson(Map<String, dynamic> json) {
    final entity = json['entity']?.toString().trim().toUpperCase() ?? '';
    if (entity.isEmpty) return null;
    return MaintenanceChangeMessage(
      entity: entity,
      id: json['id']?.toString(),
      lockerId: json['lockerId']?.toString(),
    );
  }
}

/// Tài khoản được nghe topic nhân viên. Khách đăng ký sẽ bị server từ chối và
/// có thể làm rớt cả kết nối realtime ⇒ chỉ đăng ký khi đúng vai trò.
bool isMaintenanceStaff(List<String> roles) => roles.any((role) {
  final name = role.toUpperCase().replaceFirst('ROLE_', '');
  return name == 'ADMIN' ||
      name == 'LOCKER_TECHNICIAN' ||
      name == 'DRONE_TECHNICIAN';
});

class RealtimeNotificationService {
  RealtimeNotificationService._();
  static final RealtimeNotificationService instance =
      RealtimeNotificationService._();

  final _controller = StreamController<NotificationModel>.broadcast();

  /// Thông báo thật (`/user/queue/notifications`) — đã có trong DB, có `id`.
  Stream<NotificationModel> get notifications => _controller.stream;

  final _orderController = StreamController<OrderUpdateMessage>.broadcast();

  /// Tin cập nhật đơn (`/user/queue/orders`) — chỉ để làm mới màn hình.
  Stream<OrderUpdateMessage> get orderUpdates => _orderController.stream;

  final _userEventController = StreamController<UserSyncMessage>.broadcast();

  /// Ví/điểm thưởng đổi (`/user/queue/events`) — chỉ để làm mới màn hình.
  Stream<UserSyncMessage> get userEvents => _userEventController.stream;

  final _catalogController = StreamController<CatalogChangeMessage>.broadcast();

  /// Khuyến mãi/cửa hàng/tủ admin vừa sửa (`/topic/public/catalog`).
  Stream<CatalogChangeMessage> get catalogChanges => _catalogController.stream;

  final _availabilityController = StreamController<int>.broadcast();

  /// Mã tủ vừa đổi số ô trống (`/topic/public/locker-availability`): người
  /// khác đặt/trả ô, KTV khoá/mở ô… Đi chung kết nối này để các màn tủ không
  /// phải mở thêm socket.
  Stream<int> get lockerAvailability => _availabilityController.stream;

  final _maintenanceController =
      StreamController<MaintenanceChangeMessage>.broadcast();

  /// Việc bảo trì vừa đổi — chỉ có tin khi tài khoản là KTV/ADMIN.
  Stream<MaintenanceChangeMessage> get maintenanceChanges =>
      _maintenanceController.stream;

  StompClient? _client;
  StompUnsubscribe? _unsubscribeNotif;
  StompUnsubscribe? _unsubscribeOrders;
  StompUnsubscribe? _unsubscribeUserEvents;
  StompUnsubscribe? _unsubscribeCatalog;
  StompUnsubscribe? _unsubscribeAvailability;
  StompUnsubscribe? _unsubscribeMaintenance;
  String? _connectedToken;

  Future<void> connect() async {
    final token = await TokenService.getAccessToken();
    if (token == null || token.isEmpty) {
      disconnect();
      return;
    }

    if (_client?.connected == true && _connectedToken == token) return;

    disconnect();
    _connectedToken = token;
    final staff = isMaintenanceStaff(await TokenService.getCurrentRoles());
    final wsUrl = _webSocketUrl(ApiConstants.apiBaseUrl);

    _client = StompClient(
      config: StompConfig(
        url: wsUrl,
        stompConnectHeaders: {'Authorization': 'Bearer $token'},
        webSocketConnectHeaders: {'Authorization': 'Bearer $token'},
        reconnectDelay: const Duration(seconds: 5),
        heartbeatIncoming: const Duration(seconds: 10),
        heartbeatOutgoing: const Duration(seconds: 10),
        connectionTimeout: const Duration(seconds: 15),
        onConnect: (frame) {
          debugPrint('Realtime notifications connected');
          _unsubscribeNotif = _client?.subscribe(
            destination: '/user/queue/notifications',
            callback: _handleNotificationFrame,
          );
          _unsubscribeOrders = _client?.subscribe(
            destination: '/user/queue/orders',
            callback: _handleOrderFrame,
          );
          _unsubscribeUserEvents = _client?.subscribe(
            destination: '/user/queue/events',
            callback: _handleUserEventFrame,
          );
          _unsubscribeCatalog = _client?.subscribe(
            destination: '/topic/public/catalog',
            callback: _handleCatalogFrame,
          );
          _unsubscribeAvailability = _client?.subscribe(
            destination: LockerAvailabilitySocketService.destination,
            callback: _handleAvailabilityFrame,
          );
          if (staff) {
            _unsubscribeMaintenance = _client?.subscribe(
              destination: '/topic/staff/maintenance',
              callback: _handleMaintenanceFrame,
            );
          }
        },
        onDisconnect: (frame) =>
            debugPrint('Realtime notifications disconnected'),
        onStompError: (frame) =>
            debugPrint('Realtime notification STOMP error: ${frame.body}'),
        onWebSocketError: (error) =>
            debugPrint('Realtime notification WebSocket error: $error'),
      ),
    )..activate();
  }

  void disconnect() {
    try {
      _unsubscribeNotif?.call();
      _unsubscribeOrders?.call();
      _unsubscribeUserEvents?.call();
      _unsubscribeCatalog?.call();
      _unsubscribeAvailability?.call();
      _unsubscribeMaintenance?.call();
    } catch (_) {
      // Best effort; the underlying client may already be down.
    }
    _unsubscribeNotif = null;
    _unsubscribeOrders = null;
    _unsubscribeUserEvents = null;
    _unsubscribeCatalog = null;
    _unsubscribeAvailability = null;
    _unsubscribeMaintenance = null;
    _client?.deactivate();
    _client = null;
    _connectedToken = null;
  }

  void _handleNotificationFrame(StompFrame frame) {
    final decoded = _decode(frame);
    if (decoded == null) return;
    if (!isDisplayableNotificationJson(decoded)) {
      debugPrint('Bỏ qua thông báo realtime không có id/nội dung: $decoded');
      return;
    }
    _controller.add(NotificationModel.fromJson(decoded));
  }

  void _handleOrderFrame(StompFrame frame) {
    final decoded = _decode(frame);
    if (decoded == null) return;
    _orderController.add(OrderUpdateMessage.fromJson(decoded));
  }

  void _handleUserEventFrame(StompFrame frame) {
    final decoded = _decode(frame);
    if (decoded == null) return;
    _userEventController.add(UserSyncMessage.fromJson(decoded));
  }

  void _handleCatalogFrame(StompFrame frame) {
    final decoded = _decode(frame);
    if (decoded == null) return;
    final change = CatalogChangeMessage.fromJson(decoded);
    if (change != null) _catalogController.add(change);
  }

  void _handleAvailabilityFrame(StompFrame frame) {
    final lockerId = LockerAvailabilitySocketService.parseLockerId(frame.body);
    if (lockerId != null) _availabilityController.add(lockerId);
  }

  void _handleMaintenanceFrame(StompFrame frame) {
    final decoded = _decode(frame);
    if (decoded == null) return;
    final change = MaintenanceChangeMessage.fromJson(decoded);
    if (change != null) _maintenanceController.add(change);
  }

  Map<String, dynamic>? _decode(StompFrame frame) {
    final body = frame.body;
    if (body == null || body.isEmpty) return null;
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) return decoded;
    } catch (e) {
      debugPrint('Could not parse realtime message: $e');
    }
    return null;
  }

  String _webSocketUrl(String baseUrl) {
    final uri = Uri.parse(baseUrl);
    final scheme = uri.scheme == 'https' ? 'wss' : 'ws';
    return uri
        .replace(scheme: scheme, path: '/ws', query: null, fragment: null)
        .toString();
  }
}

/// Thông báo hiển thị được: có `id` (đã lưu ở server, xoá/đánh dấu đọc được)
/// và có tiêu đề hoặc nội dung.
bool isDisplayableNotificationJson(Map<String, dynamic> json) {
  final id = (json['id'] ?? json['notificationId'])?.toString().trim() ?? '';
  if (id.isEmpty) return false;
  final title = json['title']?.toString().trim() ?? '';
  final body =
      (json['body'] ?? json['content'] ?? json['message'])?.toString().trim() ??
      '';
  return title.isNotEmpty || body.isNotEmpty;
}
