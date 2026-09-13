import 'dart:typed_data';

import '../domain/mav_messages.dart';
import 'mavlink_crc.dart';

/// A successfully-parsed MAVLink frame plus its decoded [message] (when the id
/// is one we model).
class MavFrame {
  const MavFrame({
    required this.messageId,
    required this.systemId,
    required this.componentId,
    required this.message,
  });

  final int messageId;
  final int systemId;
  final int componentId;
  final MavMessage? message;
}

/// Hand-rolled MAVLink v1 + v2 codec covering the subset of messages used by
/// the Flight Data screen. Stateful: it buffers partial reads, learns the
/// vehicle's system/component id from incoming heartbeats, and stamps an
/// increasing sequence number on outgoing frames.
///
/// Deliberately dependency-free so it is fully unit-testable offline and we
/// keep exact control over the bytes sent to a real ArduPilot/PX4 autopilot.
class MavlinkProtocol {
  MavlinkProtocol({this.systemId = 255, this.componentId = 190});

  /// Our (ground station) identity stamped on outgoing frames.
  final int systemId;
  final int componentId;

  /// The vehicle we address commands to; learned from incoming heartbeats.
  int targetSystem = 1;
  int targetComponent = 1;

  static const Endian _le = Endian.little;

  final List<int> _buf = [];
  int _seq = 0;

  // ── receive ────────────────────────────────────────────────────────────────

  /// Feeds raw [bytes] from the transport and returns any complete frames.
  List<MavFrame> receive(List<int> bytes) {
    _buf.addAll(bytes);
    final frames = <MavFrame>[];
    var i = 0;

    while (i < _buf.length) {
      final magic = _buf[i];
      if (magic == 0xFD) {
        if (_buf.length - i < 10) break; // need v2 header
        final len = _buf[i + 1];
        final incompat = _buf[i + 2];
        final signed = (incompat & 0x01) != 0; // MAVLINK_IFLAG_SIGNED
        final total = 10 + len + 2 + (signed ? 13 : 0);
        if (_buf.length - i < total) break;
        final msgId = _buf[i + 7] | (_buf[i + 8] << 8) | (_buf[i + 9] << 16);
        final crc = _buf[i + 10 + len] | (_buf[i + 11 + len] << 8);
        final extra = MavlinkCrc.extraFor(msgId);
        if (extra == null) {
          i += total; // unknown id: skip whole frame
          continue;
        }
        final calc = MavlinkCrc.compute(_buf.sublist(i + 1, i + 10 + len), extra);
        if (calc != crc) {
          i += 1; // resync on bad CRC
          continue;
        }
        final frame = _frame(msgId, _buf[i + 5], _buf[i + 6],
            _buf.sublist(i + 10, i + 10 + len));
        if (frame != null) frames.add(frame);
        i += total;
      } else if (magic == 0xFE) {
        if (_buf.length - i < 6) break; // need v1 header
        final len = _buf[i + 1];
        final total = 6 + len + 2;
        if (_buf.length - i < total) break;
        final msgId = _buf[i + 5];
        final crc = _buf[i + 6 + len] | (_buf[i + 7 + len] << 8);
        final extra = MavlinkCrc.extraFor(msgId);
        if (extra == null) {
          i += total;
          continue;
        }
        final calc = MavlinkCrc.compute(_buf.sublist(i + 1, i + 6 + len), extra);
        if (calc != crc) {
          i += 1;
          continue;
        }
        final frame = _frame(msgId, _buf[i + 3], _buf[i + 4],
            _buf.sublist(i + 6, i + 6 + len));
        if (frame != null) frames.add(frame);
        i += total;
      } else {
        i += 1; // not a start byte
      }
    }

    _buf.removeRange(0, i);
    // Guard against unbounded growth from a stream that never frames.
    if (_buf.length > 4096) _buf.removeRange(0, _buf.length - 1024);
    return frames;
  }

  MavFrame? _frame(int msgId, int sysId, int compId, List<int> payload) {
    final message = _decode(msgId, payload);
    if (message is HeartbeatMsg && sysId != 0) {
      // Address commands to the first real vehicle we hear from.
      targetSystem = sysId;
      targetComponent = compId;
    }
    return MavFrame(
      messageId: msgId,
      systemId: sysId,
      componentId: compId,
      message: message,
    );
  }

  MavMessage? _decode(int msgId, List<int> payload) {
    switch (msgId) {
      case MavMsgId.heartbeat:
        final d = _view(payload, 9);
        return HeartbeatMsg(
          customMode: d.getUint32(0, _le),
          type: d.getUint8(4),
          autopilot: d.getUint8(5),
          baseMode: d.getUint8(6),
          systemStatus: d.getUint8(7),
        );
      case MavMsgId.sysStatus:
        final d = _view(payload, 31);
        return SysStatusMsg(
          voltageBatteryMv: d.getUint16(14, _le),
          currentBatteryCa: d.getInt16(16, _le),
          batteryRemaining: d.getInt8(30),
        );
      case MavMsgId.gpsRawInt:
        final d = _view(payload, 30);
        return GpsRawIntMsg(
          fixType: d.getUint8(28),
          satellitesVisible: d.getUint8(29),
        );
      case MavMsgId.attitude:
        final d = _view(payload, 28);
        return AttitudeMsg(
          roll: d.getFloat32(4, _le),
          pitch: d.getFloat32(8, _le),
          yaw: d.getFloat32(12, _le),
        );
      case MavMsgId.globalPositionInt:
        final d = _view(payload, 28);
        return GlobalPositionIntMsg(
          lat: d.getInt32(4, _le),
          lon: d.getInt32(8, _le),
          altMm: d.getInt32(12, _le),
          relativeAltMm: d.getInt32(16, _le),
          hdgCdeg: d.getUint16(26, _le),
        );
      case MavMsgId.vfrHud:
        final d = _view(payload, 20);
        return VfrHudMsg(
          airspeed: d.getFloat32(0, _le),
          groundspeed: d.getFloat32(4, _le),
          altMsl: d.getFloat32(8, _le),
          climb: d.getFloat32(12, _le),
          headingDeg: d.getInt16(16, _le),
          throttle: d.getUint16(18, _le),
        );
      case MavMsgId.commandAck:
        final d = _view(payload, 3);
        return CommandAckMsg(command: d.getUint16(0, _le), result: d.getUint8(2));
      case MavMsgId.statustext:
        final d = _view(payload, 51);
        final chars = <int>[];
        for (var k = 1; k <= 50; k++) {
          final c = d.getUint8(k);
          if (c == 0) break;
          chars.add(c);
        }
        return StatusTextMsg(
          severity: d.getUint8(0),
          text: String.fromCharCodes(chars),
        );
      default:
        return null;
    }
  }

  /// Zero-pads [payload] to at least [minLen] bytes so truncated v2 payloads
  /// still decode (MAVLink trims trailing zero bytes on the wire).
  ByteData _view(List<int> payload, int minLen) {
    final n = payload.length < minLen ? minLen : payload.length;
    final b = Uint8List(n)..setRange(0, payload.length, payload);
    return ByteData.sublistView(b);
  }

  // ── send ───────────────────────────────────────────────────────────────────

  /// MAV_CMD via COMMAND_LONG (#76).
  Uint8List encodeCommandLong(
    int command, {
    double p1 = 0,
    double p2 = 0,
    double p3 = 0,
    double p4 = 0,
    double p5 = 0,
    double p6 = 0,
    double p7 = 0,
    int confirmation = 0,
  }) {
    final p = ByteData(33);
    p.setFloat32(0, p1, _le);
    p.setFloat32(4, p2, _le);
    p.setFloat32(8, p3, _le);
    p.setFloat32(12, p4, _le);
    p.setFloat32(16, p5, _le);
    p.setFloat32(20, p6, _le);
    p.setFloat32(24, p7, _le);
    p.setUint16(28, command, _le);
    p.setUint8(30, targetSystem);
    p.setUint8(31, targetComponent);
    p.setUint8(32, confirmation);
    return _buildV2(MavMsgId.commandLong, p.buffer.asUint8List());
  }

  /// SET_MODE (#11) — base_mode + ArduPilot/PX4 custom flight mode number.
  Uint8List encodeSetMode(int customMode, {int baseMode = 1}) {
    final p = ByteData(6);
    p.setUint32(0, customMode, _le);
    p.setUint8(4, targetSystem);
    p.setUint8(5, baseMode); // MAV_MODE_FLAG_CUSTOM_MODE_ENABLED = 1
    return _buildV2(MavMsgId.setMode, p.buffer.asUint8List());
  }

  /// REQUEST_DATA_STREAM (#66) — ask the autopilot to start streaming telemetry
  /// at [rateHz] (ArduPilot honours this; PX4 streams by default).
  Uint8List encodeRequestDataStream({int rateHz = 4, bool start = true}) {
    final p = ByteData(6);
    p.setUint16(0, rateHz, _le);
    p.setUint8(2, targetSystem);
    p.setUint8(3, targetComponent);
    p.setUint8(4, 0); // MAV_DATA_STREAM_ALL
    p.setUint8(5, start ? 1 : 0);
    return _buildV2(MavMsgId.requestDataStream, p.buffer.asUint8List());
  }

  /// HEARTBEAT (#0) advertising us as a ground station (keeps the link alive).
  Uint8List encodeHeartbeat() {
    final p = ByteData(9);
    p.setUint32(0, 0, _le); // custom_mode
    p.setUint8(4, 6); // MAV_TYPE_GCS
    p.setUint8(5, 8); // MAV_AUTOPILOT_INVALID
    p.setUint8(6, 0); // base_mode
    p.setUint8(7, 0); // system_status
    p.setUint8(8, 3); // mavlink_version
    return _buildV2(MavMsgId.heartbeat, p.buffer.asUint8List());
  }

  Uint8List _buildV2(int msgId, Uint8List payload) {
    final len = payload.length;
    final frame = Uint8List(10 + len + 2);
    frame[0] = 0xFD;
    frame[1] = len;
    frame[2] = 0; // incompat_flags
    frame[3] = 0; // compat_flags
    frame[4] = _seq;
    frame[5] = systemId;
    frame[6] = componentId;
    frame[7] = msgId & 0xFF;
    frame[8] = (msgId >> 8) & 0xFF;
    frame[9] = (msgId >> 16) & 0xFF;
    frame.setRange(10, 10 + len, payload);
    _seq = (_seq + 1) & 0xFF;

    final extra = MavlinkCrc.extraFor(msgId)!;
    final crc = MavlinkCrc.compute(frame.sublist(1, 10 + len), extra);
    frame[10 + len] = crc & 0xFF;
    frame[11 + len] = (crc >> 8) & 0xFF;
    return frame;
  }
}
