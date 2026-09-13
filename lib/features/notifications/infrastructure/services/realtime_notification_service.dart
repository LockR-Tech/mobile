import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:smart_laundry_locker/core/constants/api_constants.dart';
import 'package:smart_laundry_locker/core/services/token_service.dart';
import 'package:smart_laundry_locker/features/notifications/domain/entities/notification_model.dart';
import 'package:stomp_dart_client/stomp_dart_client.dart';

class RealtimeNotificationService {
  RealtimeNotificationService._();
  static final RealtimeNotificationService instance =
      RealtimeNotificationService._();

  final _controller = StreamController<NotificationModel>.broadcast();
  Stream<NotificationModel> get notifications => _controller.stream;

  StompClient? _client;
  StompUnsubscribe? _unsubscribe;
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
          _unsubscribe = _client?.subscribe(
            destination: '/user/queue/notifications',
            callback: _handleFrame,
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
      _unsubscribe?.call();
    } catch (_) {
      // Best effort; the underlying client may already be down.
    }
    _unsubscribe = null;
    _client?.deactivate();
    _client = null;
    _connectedToken = null;
  }

  void _handleFrame(StompFrame frame) {
    final body = frame.body;
    if (body == null || body.isEmpty) return;
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        _controller.add(NotificationModel.fromJson(decoded));
      }
    } catch (e) {
      debugPrint('Could not parse realtime notification: $e');
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
