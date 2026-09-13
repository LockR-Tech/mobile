import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:smart_laundry_locker/features/drone_telemetry/data/mavlink_crc.dart';
import 'package:smart_laundry_locker/features/drone_telemetry/data/mavlink_protocol.dart';
import 'package:smart_laundry_locker/features/drone_telemetry/domain/mav_messages.dart';

/// Builds a MAVLink v2 frame the way an autopilot would, so the parser is
/// tested against independently-CRC'd bytes (not just its own encoder).
Uint8List buildV2(int msgId, Uint8List payload, {int sysId = 1, int compId = 1}) {
  final len = payload.length;
  final frame = Uint8List(10 + len + 2);
  frame[0] = 0xFD;
  frame[1] = len;
  frame[2] = 0;
  frame[3] = 0;
  frame[4] = 0; // seq
  frame[5] = sysId;
  frame[6] = compId;
  frame[7] = msgId & 0xFF;
  frame[8] = (msgId >> 8) & 0xFF;
  frame[9] = (msgId >> 16) & 0xFF;
  frame.setRange(10, 10 + len, payload);
  final extra = MavlinkCrc.extraFor(msgId)!;
  final crc = MavlinkCrc.compute(frame.sublist(1, 10 + len), extra);
  frame[10 + len] = crc & 0xFF;
  frame[11 + len] = (crc >> 8) & 0xFF;
  return frame;
}

void main() {
  const le = Endian.little;

  group('CRC-16/MCRF4XX', () {
    test('matches the standard check value for "123456789"', () {
      var crc = 0xFFFF;
      for (final b in '123456789'.codeUnits) {
        crc = MavlinkCrc.accumulate(b, crc);
      }
      expect(crc, 0x6F91); // canonical MCRF4XX check value
    });
  });

  group('decode incoming telemetry', () {
    test('GLOBAL_POSITION_INT (#33)', () {
      final p = ByteData(28);
      p.setUint32(0, 1234, le); // time_boot_ms
      p.setInt32(4, 107626220, le); // lat 10.762622
      p.setInt32(8, 1066601720, le); // lon 106.660172
      p.setInt32(12, 100000, le); // alt 100 m
      p.setInt32(16, 50000, le); // rel alt 50 m
      p.setUint16(26, 9000, le); // hdg 90.00 deg
      final frame = buildV2(MavMsgId.globalPositionInt, p.buffer.asUint8List());

      final out = MavlinkProtocol().receive(frame);
      expect(out.length, 1);
      final msg = out.single.message;
      expect(msg, isA<GlobalPositionIntMsg>());
      final g = msg! as GlobalPositionIntMsg;
      expect(g.latDeg, closeTo(10.762622, 1e-6));
      expect(g.lonDeg, closeTo(106.660172, 1e-6));
      expect(g.relativeAltMeters, closeTo(50, 1e-6));
      expect(g.headingDeg, closeTo(90, 1e-6));
    });

    test('HEARTBEAT (#0) armed flag + custom mode', () {
      final p = ByteData(9);
      p.setUint32(0, 6, le); // custom_mode = RTL (ArduCopter)
      p.setUint8(4, 2); // type quadrotor
      p.setUint8(5, 3); // autopilot = ArduPilot
      p.setUint8(6, 0x80 | 0x01); // base_mode: SAFETY_ARMED | CUSTOM_MODE_ENABLED
      p.setUint8(7, 4); // system_status active
      final frame = buildV2(MavMsgId.heartbeat, p.buffer.asUint8List());

      final msg = MavlinkProtocol().receive(frame).single.message;
      expect(msg, isA<HeartbeatMsg>());
      final h = msg! as HeartbeatMsg;
      expect(h.armed, isTrue);
      expect(h.customMode, 6);
      expect(h.autopilot, 3);
    });

    test('SYS_STATUS (#1) battery fields', () {
      final p = ByteData(31);
      p.setUint16(14, 12600, le); // 12.6 V
      p.setInt16(16, 1500, le); // 15.0 A
      p.setInt8(30, 87); // 87 %
      final msg = MavlinkProtocol().receive(buildV2(MavMsgId.sysStatus, p.buffer.asUint8List())).single.message;
      final s = msg! as SysStatusMsg;
      expect(s.voltageVolts, closeTo(12.6, 1e-6));
      expect(s.currentAmps, closeTo(15.0, 1e-6));
      expect(s.remainingPercent, 87);
    });

    test('reassembles a frame split across two reads', () {
      final p = ByteData(28);
      p.setInt32(4, 100000000, le);
      p.setInt32(8, 1000000000, le);
      final frame = buildV2(MavMsgId.globalPositionInt, p.buffer.asUint8List());
      final proto = MavlinkProtocol();
      final first = proto.receive(frame.sublist(0, 8));
      expect(first, isEmpty); // incomplete
      final rest = proto.receive(frame.sublist(8));
      expect(rest.length, 1);
      expect(rest.single.message, isA<GlobalPositionIntMsg>());
    });

    test('drops a frame with a corrupted CRC', () {
      final p = ByteData(28)..setInt32(4, 12345, le);
      final frame = buildV2(MavMsgId.globalPositionInt, p.buffer.asUint8List());
      frame[12] ^= 0xFF; // flip a payload byte → CRC mismatch
      expect(MavlinkProtocol().receive(frame), isEmpty);
    });
  });

  group('encode outgoing commands', () {
    test('COMMAND_LONG round-trips through the parser with a valid CRC', () {
      final proto = MavlinkProtocol();
      final bytes = proto.encodeCommandLong(400, p1: 1); // ARM
      final out = MavlinkProtocol().receive(bytes);
      expect(out.length, 1);
      expect(out.single.messageId, MavMsgId.commandLong);
    });

    test('encoded HEARTBEAT decodes back as a GCS heartbeat', () {
      final bytes = MavlinkProtocol().encodeHeartbeat();
      final msg = MavlinkProtocol().receive(bytes).single.message;
      expect(msg, isA<HeartbeatMsg>());
      expect((msg! as HeartbeatMsg).type, 6); // MAV_TYPE_GCS
      expect((msg as HeartbeatMsg).armed, isFalse);
    });

    test('SET_MODE and REQUEST_DATA_STREAM produce parseable frames', () {
      final proto = MavlinkProtocol();
      for (final bytes in [proto.encodeSetMode(6), proto.encodeRequestDataStream()]) {
        expect(MavlinkProtocol().receive(bytes).length, 1);
      }
    });
  });
}
