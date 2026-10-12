import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:smart_laundry_locker/features/drone_telemetry/data/mav_connection.dart';
import 'package:smart_laundry_locker/features/drone_telemetry/data/mavlink_crc.dart';
import 'package:smart_laundry_locker/features/drone_telemetry/domain/flight_command_policy.dart';
import 'package:smart_laundry_locker/features/drone_telemetry/domain/flight_modes.dart';
import 'package:smart_laundry_locker/features/drone_telemetry/domain/mav_messages.dart';
import 'package:smart_laundry_locker/features/drone_telemetry/presentation/flight_data_controller.dart';

const _le = Endian.little;

/// Khung MAVLink v2 như autopilot gửi (sysid 1).
Uint8List _frame(int msgId, Uint8List payload) {
  final len = payload.length;
  final frame = Uint8List(10 + len + 2);
  frame[0] = 0xFD;
  frame[1] = len;
  frame[5] = 1;
  frame[6] = 1;
  frame[7] = msgId & 0xFF;
  frame[8] = (msgId >> 8) & 0xFF;
  frame[9] = (msgId >> 16) & 0xFF;
  frame.setRange(10, 10 + len, payload);
  final crc = MavlinkCrc.compute(
    frame.sublist(1, 10 + len),
    MavlinkCrc.extraFor(msgId)!,
  );
  frame[10 + len] = crc & 0xFF;
  frame[11 + len] = (crc >> 8) & 0xFF;
  return frame;
}

Uint8List _heartbeat({required int mode, bool armed = false}) {
  final p = ByteData(9);
  p.setUint32(0, mode, _le);
  p.setUint8(4, 2); // MAV_TYPE_QUADROTOR
  p.setUint8(5, MavAutopilot.ardupilotmega);
  p.setUint8(6, 1 | (armed ? 0x80 : 0));
  p.setUint8(7, 4);
  p.setUint8(8, 3);
  return _frame(MavMsgId.heartbeat, p.buffer.asUint8List());
}

Uint8List _ack(int command, int result) {
  final p = ByteData(3);
  p.setUint16(0, command, _le);
  p.setUint8(2, result);
  return _frame(MavMsgId.commandAck, p.buffer.asUint8List());
}

class _FakeConnection implements MavConnection {
  final _inbound = StreamController<List<int>>.broadcast();
  final sent = <List<int>>[];
  bool peer = true;

  @override
  Stream<List<int>> get inbound => _inbound.stream;

  @override
  String get label => 'fake';

  @override
  bool get peerKnown => peer;

  @override
  Future<void> connect() async {}

  @override
  void send(List<int> bytes) => sent.add(bytes);

  @override
  Future<void> close() async {
    if (!_inbound.isClosed) await _inbound.close();
  }

  void receive(List<int> bytes) => _inbound.add(bytes);

  /// Gói lệnh đã gửi (bỏ heartbeat/yêu cầu stream của GCS).
  List<List<int>> sentWithId(int msgId) =>
      sent.where((frame) => frame[7] == msgId).toList();
}

FlightCommandState _state({
  bool connected = true,
  bool peerKnown = true,
  bool heartbeatSeen = true,
  bool linkAlive = true,
  bool armed = false,
  String modeName = 'STABILIZE',
  bool commandPending = false,
  bool missionLocked = false,
}) => FlightCommandState(
  connected: connected,
  peerKnown: peerKnown,
  heartbeatSeen: heartbeatSeen,
  linkAlive: linkAlive,
  armed: armed,
  modeName: modeName,
  commandPending: commandPending,
  missionLocked: missionLocked,
);

void main() {
  group('flightCommandBlockReason', () {
    test('mọi lệnh bị chặn khi link chưa sẵn sàng', () {
      for (final command in FlightCommand.values) {
        expect(
          flightCommandBlockReason(command, _state(connected: false)),
          isNotNull,
        );
        expect(
          flightCommandBlockReason(command, _state(peerKnown: false)),
          contains('địa chỉ drone'),
        );
        expect(
          flightCommandBlockReason(command, _state(heartbeatSeen: false)),
          contains('heartbeat'),
        );
        expect(
          flightCommandBlockReason(command, _state(linkAlive: false)),
          contains('Mất heartbeat'),
        );
      }
    });

    test('drone đang giao hàng hoặc đang chờ phản hồi ⇒ khoá lệnh', () {
      expect(
        flightCommandBlockReason(
          FlightCommand.loiter,
          _state(missionLocked: true),
        ),
        contains('nhiệm vụ giao hàng'),
      );
      expect(
        flightCommandBlockReason(
          FlightCommand.rtl,
          _state(commandPending: true),
        ),
        contains('phản hồi'),
      );
    });

    test('đổi chế độ và ARM được phép khi link sẵn sàng', () {
      for (final command in [
        FlightCommand.arm,
        FlightCommand.rtl,
        FlightCommand.loiter,
        FlightCommand.guided,
        FlightCommand.auto,
      ]) {
        expect(flightCommandBlockReason(command, _state()), isNull);
      }
      expect(
        flightCommandBlockReason(FlightCommand.disarm, _state()),
        isNotNull,
      );
    });

    test('TAKEOFF chỉ khi đã ARM và ở GUIDED', () {
      expect(
        flightCommandBlockReason(FlightCommand.takeoff, _state()),
        contains('ARM'),
      );
      expect(
        flightCommandBlockReason(
          FlightCommand.takeoff,
          _state(armed: true, modeName: 'LOITER'),
        ),
        contains('GUIDED'),
      );
      expect(
        flightCommandBlockReason(
          FlightCommand.takeoff,
          _state(armed: true, modeName: 'GUIDED'),
        ),
        isNull,
      );
    });

    test('độ cao cất cánh có trần', () {
      expect(takeoffAltitudeError(null), isNotNull);
      expect(takeoffAltitudeError(0.5), isNotNull);
      expect(takeoffAltitudeError(kMaxTakeoffAltitudeM + 1), isNotNull);
      expect(takeoffAltitudeError(kMaxTakeoffAltitudeM), isNull);
      expect(takeoffAltitudeError(10), isNull);
    });
  });

  group('FlightDataController', () {
    late _FakeConnection link;
    late FlightDataController controller;

    setUp(() async {
      link = _FakeConnection();
      controller = FlightDataController();
      await controller.attach(link);
    });

    tearDown(() => controller.dispose());

    Future<void> deliver(List<int> bytes) async {
      link.receive(bytes);
      await Future<void>.delayed(Duration.zero);
    }

    test('không gửi lệnh trước heartbeat đầu tiên', () {
      expect(controller.sendCommand(FlightCommand.loiter), contains('heartbeat'));
      expect(link.sentWithId(MavMsgId.setMode), isEmpty);
    });

    test('không gửi lệnh khi chưa biết địa chỉ drone', () async {
      link.peer = false;
      await deliver(_heartbeat(mode: ArduCopterMode.stabilize));
      expect(
        controller.sendCommand(FlightCommand.loiter),
        contains('địa chỉ drone'),
      );
      expect(link.sentWithId(MavMsgId.setMode), isEmpty);
    });

    test('đổi chế độ chờ COMMAND_ACK rồi báo đã nhận', () async {
      await deliver(_heartbeat(mode: ArduCopterMode.stabilize));
      expect(controller.sendCommand(FlightCommand.loiter), isNull);
      expect(link.sentWithId(MavMsgId.setMode), hasLength(1));
      expect(controller.lastFeedback!.outcome, CommandOutcome.pending);
      // Đang chờ phản hồi thì lệnh khác bị chặn.
      expect(controller.sendCommand(FlightCommand.rtl), isNotNull);

      await deliver(_ack(MavMsgId.setMode, 0));
      expect(controller.lastFeedback!.outcome, CommandOutcome.accepted);
      expect(controller.commandPending, isFalse);
    });

    test('ARM bị drone từ chối ⇒ hiện từ chối', () async {
      await deliver(_heartbeat(mode: ArduCopterMode.stabilize));
      expect(controller.sendCommand(FlightCommand.arm), isNull);
      await deliver(_ack(MavCmd.componentArmDisarm, 2));
      expect(controller.lastFeedback!.outcome, CommandOutcome.rejected);
      expect(controller.lastFeedback!.message, contains('DENIED'));
    });

    test('TAKEOFF vượt trần độ cao không được gửi', () async {
      await deliver(_heartbeat(mode: ArduCopterMode.guided, armed: true));
      expect(
        controller.sendCommand(FlightCommand.takeoff, altitudeM: 50),
        contains('tối đa'),
      );
      expect(controller.sendCommand(FlightCommand.takeoff, altitudeM: 20), isNull);
      final sent = link.sentWithId(MavMsgId.commandLong);
      expect(sent, hasLength(1));
      final payload = ByteData.sublistView(Uint8List.fromList(sent.single), 10);
      expect(payload.getUint16(28, _le), MavCmd.navTakeoff);
      expect(payload.getFloat32(24, _le), 20);
    });
  });

  testWidgets('không có phản hồi ⇒ báo hết giờ', (tester) async {
    final link = _FakeConnection();
    final controller = FlightDataController();
    await controller.attach(link);
    link.receive(_heartbeat(mode: ArduCopterMode.stabilize));
    await tester.pump();

    expect(controller.sendCommand(FlightCommand.guided), isNull);
    await tester.pump(kCommandAckTimeout + const Duration(seconds: 1));

    expect(controller.lastFeedback!.outcome, CommandOutcome.timeout);
    expect(controller.commandPending, isFalse);
    controller.dispose();
  });
}
