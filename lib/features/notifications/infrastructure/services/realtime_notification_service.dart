import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:smart_laundry_locker/core/constants/api_constants.dart';
import 'package:smart_laundry_locker/core/services/token_service.dart';
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

  StompClient? _client;
  StompUnsubscribe? _unsubscribeNotif;
  StompUnsubscribe? _unsubscribeOrders;
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
    } catch (_) {
      // Best effort; the underlying client may already be down.
    }
    _unsubscribeNotif = null;
    _unsubscribeOrders = null;
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
