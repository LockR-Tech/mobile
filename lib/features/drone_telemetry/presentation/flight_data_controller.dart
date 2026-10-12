import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';

import '../data/mav_connection.dart';
import '../data/mavlink_protocol.dart';
import '../domain/drone_telemetry.dart';
import '../domain/flight_command_policy.dart';
import '../domain/flight_modes.dart';
import '../domain/mav_messages.dart';

enum LinkStatus { disconnected, connecting, connected, error }

enum MavTransport { udp, tcp }

/// Kết quả lệnh gần nhất: chờ phản hồi, drone nhận, drone từ chối, hết giờ.
enum CommandOutcome { pending, accepted, rejected, timeout }

class CommandFeedback {
  const CommandFeedback({
    required this.command,
    required this.outcome,
    required this.message,
  });

  final FlightCommand command;
  final CommandOutcome outcome;
  final String message;
}

class _PendingCommand {
  _PendingCommand({
    required this.command,
    required this.ackId,
    required this.timer,
  });

  final FlightCommand command;

  /// `command` mong đợi trong COMMAND_ACK (MAV_CMD, hoặc id SET_MODE = 11 với
  /// ArduPilot).
  final int ackId;
  final Timer timer;
}

/// Drives a live MAVLink link: owns the transport + codec, folds incoming
/// messages into [telemetry], keeps the link alive with a 1 Hz heartbeat, and
/// exposes vehicle commands. UI listens via [ChangeNotifier].
///
/// Lệnh chỉ được gửi khi [flightCommandBlockReason] cho phép (đã có heartbeat,
/// biết địa chỉ drone, …); mỗi lệnh chờ COMMAND_ACK (hoặc heartbeat xác nhận)
/// trong [kCommandAckTimeout] rồi báo kết quả qua [lastFeedback].
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
  _PendingCommand? _pending;
  CommandFeedback? _lastFeedback;

  LinkStatus get status => _status;
  DroneTelemetry get telemetry => _telemetry;
  List<LatLng> get trail => List.unmodifiable(_trail);
  List<String> get messages => List.unmodifiable(_messages);
  String? get error => _error;
  String get endpointLabel => _connection?.label ?? '—';

  bool get isConnected => _status == LinkStatus.connected;

  /// Đã biết địa chỉ drone để gửi lệnh (UDP học từ gói tin đầu tiên).
  bool get peerKnown => _connection?.peerKnown ?? false;

  /// Đã nhận ít nhất một HEARTBEAT trong phiên kết nối này.
  bool get heartbeatSeen => _telemetry.lastHeartbeatAt != null;

  bool get commandPending => _pending != null;
  CommandFeedback? get lastFeedback => _lastFeedback;

  FlightCommandState commandState({bool missionLocked = false}) =>
      FlightCommandState(
        connected: isConnected,
        peerKnown: peerKnown,
        heartbeatSeen: heartbeatSeen,
        linkAlive: _telemetry.linkAlive,
        armed: _telemetry.armed,
        modeName: _telemetry.modeName,
        commandPending: commandPending,
        missionLocked: missionLocked,
      );

  // ── lifecycle ──────────────────────────────────────────────────────────────

  Future<void> connect({
    required MavTransport transport,
    required String host,
    required int port,
    int localPort = 14550,
  }) async {
    final connection = switch (transport) {
      MavTransport.udp => UdpMavConnection(
          remoteHost: host.trim().isEmpty ? null : host.trim(),
          remotePort: port,
          localPort: localPort,
        ),
      MavTransport.tcp => TcpMavConnection(host: host.trim(), port: port),
    };
    await attach(connection);
  }

  /// Mở [connection] và bắt đầu nhận dữ liệu (tách riêng để kiểm thử bằng
  /// transport giả).
  @visibleForTesting
  Future<void> attach(MavConnection connection) async {
    await disconnect();
    _status = LinkStatus.connecting;
    _error = null;
    _streamRequested = false;
    _telemetry = const DroneTelemetry();
    _lastFeedback = null;
    notifyListeners();

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
    _clearPending();
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
    _clearPending();
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
      } else if (msg is CommandAckMsg) {
        _onAck(msg);
      } else if (msg is HeartbeatMsg) {
        if (!_streamRequested) {
          // First heartbeat: ask ArduPilot to start streaming telemetry.
          _streamRequested = true;
          _connection?.send(_protocol.encodeRequestDataStream());
        }
        _confirmFromHeartbeat(msg);
      }
    }
    if (changed) notifyListeners();
  }

  void _onAck(CommandAckMsg ack) {
    final pending = _pending;
    if (pending == null || ack.command != pending.ackId) return;
    if (ack.result == 5) {
      // IN_PROGRESS: drone đang thực hiện, tiếp tục chờ kết quả cuối.
      _lastFeedback = CommandFeedback(
        command: pending.command,
        outcome: CommandOutcome.pending,
        message: '${pending.command.label}: ${mavResultLabel(ack.result)}',
      );
      return;
    }
    _finish(
      ack.accepted ? CommandOutcome.accepted : CommandOutcome.rejected,
      '${pending.command.label}: ${mavResultLabel(ack.result)}',
    );
  }

  /// Một số autopilot không trả COMMAND_ACK cho SET_MODE/ARM: heartbeat cho
  /// thấy đúng chế độ / trạng thái arm mới cũng coi là drone đã nhận.
  void _confirmFromHeartbeat(HeartbeatMsg heartbeat) {
    final pending = _pending;
    if (pending == null) return;
    final command = pending.command;
    final targetMode = command.targetMode;
    final confirmed = switch (command) {
      FlightCommand.arm => heartbeat.armed,
      FlightCommand.disarm => !heartbeat.armed,
      _ => targetMode != null && heartbeat.customMode == targetMode,
    };
    if (!confirmed) return;
    _finish(
      CommandOutcome.accepted,
      targetMode == null
          ? '${command.label}: drone đã thực hiện'
          : '${command.label}: drone đã chuyển sang ${ArduCopterMode.names[targetMode] ?? command.label}',
    );
  }

  void _finish(CommandOutcome outcome, String message) {
    final pending = _pending;
    if (pending == null) return;
    pending.timer.cancel();
    _pending = null;
    _lastFeedback = CommandFeedback(
      command: pending.command,
      outcome: outcome,
      message: message,
    );
  }

  void _clearPending() {
    _pending?.timer.cancel();
    _pending = null;
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

  /// Gửi [command] nếu chính sách cho phép; trả về lý do bị chặn, hoặc `null`
  /// khi đã gửi (kết quả xem ở [lastFeedback]). [altitudeM] bắt buộc cho
  /// TAKEOFF và phải trong trần [kMaxTakeoffAltitudeM].
  String? sendCommand(
    FlightCommand command, {
    double? altitudeM,
    bool missionLocked = false,
  }) {
    final blocked = flightCommandBlockReason(
      command,
      commandState(missionLocked: missionLocked),
    );
    if (blocked != null) return blocked;
    if (command == FlightCommand.takeoff) {
      final altitudeError = takeoffAltitudeError(altitudeM);
      if (altitudeError != null) return altitudeError;
    }
    final connection = _connection;
    if (connection == null) return 'Chưa kết nối flight controller.';

    final (bytes, ackId) = switch (command) {
      FlightCommand.arm => (
        _protocol.encodeCommandLong(MavCmd.componentArmDisarm, p1: 1),
        MavCmd.componentArmDisarm,
      ),
      FlightCommand.disarm => (
        _protocol.encodeCommandLong(MavCmd.componentArmDisarm, p1: 0),
        MavCmd.componentArmDisarm,
      ),
      FlightCommand.takeoff => (
        _protocol.encodeCommandLong(MavCmd.navTakeoff, p7: altitudeM!),
        MavCmd.navTakeoff,
      ),
      FlightCommand.rtl ||
      FlightCommand.loiter ||
      FlightCommand.guided ||
      FlightCommand.auto => (
        _protocol.encodeSetMode(command.targetMode!),
        MavMsgId.setMode,
      ),
    };
    connection.send(bytes);
    _pending = _PendingCommand(
      command: command,
      ackId: ackId,
      timer: Timer(kCommandAckTimeout, () {
        if (_pending?.command != command) return;
        _finish(
          CommandOutcome.timeout,
          '${command.label}: hết giờ — không nhận được phản hồi từ drone',
        );
        notifyListeners();
      }),
    );
    _lastFeedback = CommandFeedback(
      command: command,
      outcome: CommandOutcome.pending,
      message: '${command.label}: đã gửi, đang chờ drone phản hồi…',
    );
    notifyListeners();
    return null;
  }

  void clearTrail() {
    _trail.clear();
    notifyListeners();
  }

  @override
  void dispose() {
    _heartbeatTimer?.cancel();
    _clearPending();
    _sub?.cancel();
    _connection?.close();
    super.dispose();
  }
}
