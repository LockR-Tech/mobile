import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:smart_laundry_locker/core/constants/api_constants.dart';
import 'package:smart_laundry_locker/core/services/token_service.dart';
import 'package:smart_laundry_locker/features/drone_delivery/domain/entities/drone_position_snapshot.dart';
import 'package:smart_laundry_locker/features/drone_delivery/infrastructure/models/drone_position_response.dart';
import 'package:stomp_dart_client/stomp_dart_client.dart';

/// STOMP client theo dõi vị trí drone real-time — mirror `RealtimeNotificationService`
/// (cùng `/ws`, Bearer token, reconnect, heartbeat) nhưng subscribe THEO orderId
/// và mở/đóng ON-DEMAND.
///
/// Backend đẩy snapshot đã downsample tới `/topic/deliveries/{orderId}/position`.
/// Nhiều màn cùng theo dõi nhiều đơn → mỗi orderId một subscription + stream riêng;
/// khi không còn ai theo dõi thì đóng hẳn socket.
class DronePositionSocketService {
  DronePositionSocketService._();
  static final DronePositionSocketService instance =
      DronePositionSocketService._();

  StompClient? _client;
  String? _connectedToken;

  final Map<String, StompUnsubscribe> _subscriptions = {};
  final Map<String, StreamController<DronePositionSnapshot>> _controllers = {};

  static String destinationFor(String orderId) =>
      '/topic/deliveries/$orderId/position';

  /// Bắt đầu theo dõi [orderId]. Trả stream vị trí; tự (re)connect nếu cần.
  Stream<DronePositionSnapshot> watch(String orderId) {
    final controller = _controllers.putIfAbsent(
      orderId,
      () => StreamController<DronePositionSnapshot>.broadcast(),
    );
    unawaited(_ensureConnected(subscribeOrderId: orderId));
    return controller.stream;
  }

  /// Ngừng theo dõi [orderId]: unsubscribe đúng subscription, đóng stream; nếu
  /// không còn đơn nào theo dõi thì đóng socket.
  void stop(String orderId) {
    try {
      _subscriptions.remove(orderId)?.call();
    } catch (_) {
      // Best effort; client có thể đã down.
    }
    _controllers.remove(orderId)?.close();
    if (_controllers.isEmpty) {
      _disconnect();
    }
  }

  Future<void> _ensureConnected({required String subscribeOrderId}) async {
    final token = await TokenService.getAccessToken();
    if (token == null || token.isEmpty) {
      _disconnect();
      return;
    }

    // Đã connect với đúng token → chỉ cần subscribe đơn mới.
    if (_client?.connected == true && _connectedToken == token) {
      _subscribe(subscribeOrderId);
      return;
    }

    // Token đổi hoặc chưa connect → dựng lại client.
    _disconnect(keepControllers: true);
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
          debugPrint('Drone position socket connected');
          // Re-subscribe tất cả đơn đang theo dõi (cả sau khi reconnect).
          for (final orderId in _controllers.keys.toList()) {
            _subscribe(orderId);
          }
        },
        onDisconnect: (frame) => debugPrint('Drone position socket disconnected'),
        onStompError: (frame) =>
            debugPrint('Drone position STOMP error: ${frame.body}'),
        onWebSocketError: (error) =>
            debugPrint('Drone position WebSocket error: $error'),
      ),
    )..activate();
  }

  void _subscribe(String orderId) {
    final client = _client;
    if (client == null || client.connected != true) return;
    if (!_controllers.containsKey(orderId)) return;

    // Nhả subscription cũ (nếu có) để tránh nhân đôi khi reconnect.
    try {
      _subscriptions.remove(orderId)?.call();
    } catch (_) {}

    _subscriptions[orderId] = client.subscribe(
      destination: destinationFor(orderId),
      callback: (frame) => _handleFrame(orderId, frame),
    );
  }

  void _handleFrame(String orderId, StompFrame frame) {
    final body = frame.body;
    if (body == null || body.isEmpty) return;
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        final snapshot = DronePositionResponse.fromJson(decoded, orderId);
        if (snapshot != null) {
          _controllers[orderId]?.add(snapshot);
        }
      }
    } catch (e) {
      debugPrint('Could not parse drone position frame: $e');
    }
  }

  void _disconnect({bool keepControllers = false}) {
    for (final unsub in _subscriptions.values) {
      try {
        unsub();
      } catch (_) {}
    }
    _subscriptions.clear();
    _client?.deactivate();
    _client = null;
    _connectedToken = null;
    if (!keepControllers) {
      for (final controller in _controllers.values) {
        controller.close();
      }
      _controllers.clear();
    }
  }

  String _webSocketUrl(String baseUrl) {
    final uri = Uri.parse(baseUrl);
    final scheme = uri.scheme == 'https' ? 'wss' : 'ws';
    return uri
        .replace(scheme: scheme, path: '/ws', query: null, fragment: null)
        .toString();
  }
}
