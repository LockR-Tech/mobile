import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:smart_laundry_locker/core/constants/api_constants.dart';
import 'package:smart_laundry_locker/core/services/token_service.dart';
import 'package:stomp_dart_client/stomp_dart_client.dart';

/// STOMP client nghe "tủ nào vừa đổi số ô trống" — cùng `/ws`, Bearer token, reconnect như
/// `DronePositionSocketService`, mở khi có màn đang nghe và đóng khi màn cuối cùng thôi nghe.
///
/// Backend (locker-service → notification-service) đẩy `{lockerId}` lên
/// `/topic/public/locker-availability` sau mỗi lần ô đổi trạng thái: đặt đơn, lấy hàng xong,
/// huỷ, hết hạn, báo hỏng… Màn đặt đơn tự tải lại ô trống của tủ đó.
class LockerAvailabilitySocketService {
  LockerAvailabilitySocketService._();
  static final LockerAvailabilitySocketService instance =
      LockerAvailabilitySocketService._();

  static const destination = '/topic/public/locker-availability';

  StompClient? _client;
  StompUnsubscribe? _subscription;
  StreamController<int>? _controller;

  /// Stream mã tủ vừa đổi số ô trống. Huỷ lắng nghe cuối cùng thì đóng socket.
  Stream<int> watch() {
    final controller = _controller ??= StreamController<int>.broadcast(
      onListen: () => unawaited(_connect()),
      onCancel: _disconnect,
    );
    return controller.stream;
  }

  Future<void> _connect() async {
    if (_client != null) return;
    final token = await TokenService.getAccessToken();
    if (token == null || token.isEmpty || _controller?.hasListener != true) {
      return;
    }
    _client = StompClient(
      config: StompConfig(
        url: _webSocketUrl(ApiConstants.apiBaseUrl),
        stompConnectHeaders: {'Authorization': 'Bearer $token'},
        webSocketConnectHeaders: {'Authorization': 'Bearer $token'},
        reconnectDelay: const Duration(seconds: 5),
        heartbeatIncoming: const Duration(seconds: 10),
        heartbeatOutgoing: const Duration(seconds: 10),
        connectionTimeout: const Duration(seconds: 15),
        onConnect: (_) => _subscribe(),
        onStompError: (frame) =>
            debugPrint('Locker availability STOMP error: ${frame.body}'),
        onWebSocketError: (error) =>
            debugPrint('Locker availability WebSocket error: $error'),
      ),
    )..activate();
  }

  void _subscribe() {
    try {
      _subscription?.call();
    } catch (_) {}
    _subscription = _client?.subscribe(
      destination: destination,
      callback: (frame) {
        final lockerId = parseLockerId(frame.body);
        if (lockerId != null) _controller?.add(lockerId);
      },
    );
  }

  /// `{"lockerId": 7, "timestamp": "..."}` → 7; khung lỗi trả null.
  @visibleForTesting
  static int? parseLockerId(String? body) {
    if (body == null || body.isEmpty) return null;
    try {
      final decoded = jsonDecode(body);
      if (decoded is! Map) return null;
      final value = decoded['lockerId'];
      return value is num ? value.toInt() : int.tryParse('$value');
    } catch (_) {
      return null;
    }
  }

  void _disconnect() {
    try {
      _subscription?.call();
    } catch (_) {}
    _subscription = null;
    _client?.deactivate();
    _client = null;
    unawaited(_controller?.close());
    _controller = null;
  }

  String _webSocketUrl(String baseUrl) {
    final uri = Uri.parse(baseUrl);
    final scheme = uri.scheme == 'https' ? 'wss' : 'ws';
    return uri
        .replace(scheme: scheme, path: '/ws', query: null, fragment: null)
        .toString();
  }
}
