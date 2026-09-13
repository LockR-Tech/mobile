import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';

import '../data/mav_connection.dart';
import '../data/mavlink_protocol.dart';
import '../domain/drone_telemetry.dart';
import '../domain/flight_modes.dart';
import '../domain/mav_messages.dart';

enum LinkStatus { disconnected, connecting, connected, error }

enum MavTransport { udp, tcp }

/// Drives a live MAVLink link: owns the transport + codec, folds incoming
/// messages into [telemetry], keeps the link alive with a 1 Hz heartbeat, and
/// exposes vehicle commands. UI listens via [ChangeNotifier].
class FlightDataController extends ChangeNotifier {
  final MavlinkProtocol _protocol = MavlinkProtocol();

  MavConnection? _connection;
  StreamSubscription<List<int>>? _sub;
  Timer? _heartbeatTimer;
  bool _streamRequested = false;

  LinkStatus _status = LinkStatus.disconnected;
  DroneTelemetry _telemetry = const DroneTelemetry();
  final List<LatLng> _trail = [];
  final List<String> _messages = [];
  String? _error;

  LinkStatus get status => _status;
  DroneTelemetry get telemetry => _telemetry;
  List<LatLng> get trail => List.unmodifiable(_trail);
  List<String> get messages => List.unmodifiable(_messages);
  String? get error => _error;
  String get endpointLabel => _connection?.label ?? '—';

  bool get isConnected => _status == LinkStatus.connected;

  // ── lifecycle ──────────────────────────────────────────────────────────────

  Future<void> connect({
    required MavTransport transport,
    required String host,
    required int port,
    int localPort = 14550,
  }) async {
    await disconnect();
    _status = LinkStatus.connecting;
    _error = null;
    _streamRequested = false;
    notifyListeners();

    final connection = switch (transport) {
      MavTransport.udp => UdpMavConnection(
          remoteHost: host.trim().isEmpty ? null : host.trim(),
          remotePort: port,
          localPort: localPort,
        ),
      MavTransport.tcp => TcpMavConnection(host: host.trim(), port: port),
    };

    try {
      await connection.connect();
      _connection = connection;
      _sub = connection.inbound.listen(
        _onBytes,
        onError: (Object e) => _fail('$e'),
        onDone: () {
          if (_status == LinkStatus.connected) _fail('Link đã đóng.');
        },
      );
      _status = LinkStatus.connected;
      _heartbeatTimer = Timer.periodic(
        const Duration(seconds: 1),
        (_) => _tick(),
      );
      notifyListeners();
    } catch (e) {
      _connection = null;
      _fail('$e');
    }
  }

  Future<void> disconnect() async {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
    await _sub?.cancel();
    _sub = null;
    await _connection?.close();
    _connection = null;
    if (_status != LinkStatus.disconnected) {
      _status = LinkStatus.disconnected;
      notifyListeners();
    }
  }

  void _fail(String message) {
    _error = message;
    _status = LinkStatus.error;
    _heartbeatTimer?.cancel();
    notifyListeners();
  }

  // ── inbound ────────────────────────────────────────────────────────────────

  void _onBytes(List<int> bytes) {
    final frames = _protocol.receive(bytes);
    if (frames.isEmpty) return;
    var changed = false;
    for (final frame in frames) {
      final msg = frame.message;
      if (msg == null) continue;
      _telemetry = _telemetry.apply(msg);
      changed = true;

      if (msg is GlobalPositionIntMsg) {
        _pushTrail(LatLng(msg.latDeg, msg.lonDeg));
      } else if (msg is StatusTextMsg && msg.text.isNotEmpty) {
        _messages.insert(0, msg.text);
        if (_messages.length > 30) _messages.removeLast();
      } else if (msg is HeartbeatMsg && !_streamRequested) {
        // First heartbeat: ask ArduPilot to start streaming telemetry.
        _streamRequested = true;
        _connection?.send(_protocol.encodeRequestDataStream());
      }
    }
    if (changed) notifyListeners();
  }

  void _pushTrail(LatLng p) {
    if (_trail.isNotEmpty) {
      const d = Distance();
      if (d.as(LengthUnit.Meter, _trail.last, p) < 0.5) return; // dedupe jitter
    }
    _trail.add(p);
    if (_trail.length > 500) _trail.removeAt(0);
  }

  void _tick() {
    _connection?.send(_protocol.encodeHeartbeat());
    // Refresh link-alive derived state in the UI.
    notifyListeners();
  }

  // ── commands ───────────────────────────────────────────────────────────────

  void arm({bool force = false}) => _connection?.send(
        _protocol.encodeCommandLong(
          MavCmd.componentArmDisarm,
          p1: 1,
          p2: force ? 21196 : 0,
        ),
      );

  void disarm({bool force = false}) => _connection?.send(
        _protocol.encodeCommandLong(
          MavCmd.componentArmDisarm,
          p1: 0,
          p2: force ? 21196 : 0,
        ),
      );

  void setMode(int customMode) =>
      _connection?.send(_protocol.encodeSetMode(customMode));

  void returnToLaunch() => setMode(ArduCopterMode.rtl);
  void loiter() => setMode(ArduCopterMode.loiter);
  void guided() => setMode(ArduCopterMode.guided);
  void startMission() => setMode(ArduCopterMode.auto);

  void takeoff(double altMeters) => _connection?.send(
        _protocol.encodeCommandLong(MavCmd.navTakeoff, p7: altMeters),
      );

  void clearTrail() {
    _trail.clear();
    notifyListeners();
  }

  @override
  void dispose() {
    _heartbeatTimer?.cancel();
    _sub?.cancel();
    _connection?.close();
    super.dispose();
  }
}
