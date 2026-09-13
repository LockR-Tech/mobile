import 'dart:convert';

import 'package:latlong2/latlong.dart';

import '../domain/flight_mission.dart';
import '../domain/mav_command.dart';
import '../domain/mission_item.dart';

/// Thrown when a `.waypoints` / mission file cannot be parsed.
class MissionParseException implements Exception {
  MissionParseException(this.message);
  final String message;
  @override
  String toString() => 'MissionParseException: $message';
}

/// Serialises / parses [FlightMission]s in two formats:
///
/// * **QGC WPL 110** (`.waypoints`) — the de-facto interchange format read &
///   written by Mission Planner and QGroundControl. Tab-separated, item 0 is
///   the home point. This is what makes the planner interoperable with real
///   ArduPilot/PX4 ground stations.
/// * **App JSON** — a lossless internal format (keeps name, cruise speed,
///   default altitude, id, timestamp) so the app can reload a plan exactly.
class MissionCodec {
  const MissionCodec();

  static const String _qgcHeader = 'QGC WPL 110';

  // ── QGC WPL 110 ──────────────────────────────────────────────────────────

  /// Encodes [mission] as a QGC WPL 110 `.waypoints` document.
  String encodeWaypoints(FlightMission mission) {
    final buffer = StringBuffer()..writeln(_qgcHeader);

    // Item 0 = HOME (absolute frame, current waypoint flag = 1).
    buffer.writeln(
      _row(
        index: 0,
        current: 1,
        frame: MavFrame.global,
        command: MavCommand.waypoint.code,
        p1: 0,
        p2: 0,
        p3: 0,
        p4: 0,
        x: mission.home.latitude,
        y: mission.home.longitude,
        z: mission.homeAltitude,
        autoContinue: 1,
      ),
    );

    for (var i = 0; i < mission.items.length; i++) {
      final item = mission.items[i];
      buffer.writeln(
        _row(
          index: i + 1,
          current: 0,
          frame: item.frame,
          command: item.command.code,
          p1: item.param1,
          p2: item.param2,
          p3: item.param3,
          p4: item.param4,
          x: item.latitude,
          y: item.longitude,
          z: item.altitude,
          autoContinue: item.autoContinue ? 1 : 0,
        ),
      );
    }

    return buffer.toString();
  }

  /// Parses a QGC WPL 110 document into a [FlightMission]. [id] / [name] are
  /// applied to the result (the WPL format carries neither).
  FlightMission decodeWaypoints(
    String content, {
    required String id,
    String name = 'Kế hoạch nhập',
  }) {
    final lines = const LineSplitter()
        .convert(content)
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();

    if (lines.isEmpty || !lines.first.startsWith('QGC WPL')) {
      throw MissionParseException(
        'Thiếu header "QGC WPL 110" — không phải file mission hợp lệ.',
      );
    }

    var home = const LatLng(0, 0);
    var homeAlt = 0.0;
    final items = <MissionItem>[];

    for (var i = 1; i < lines.length; i++) {
      final cols = lines[i].split(RegExp(r'\s+'));
      if (cols.length < 12) {
        throw MissionParseException(
          'Dòng ${i + 1} thiếu cột (cần 12, có ${cols.length}).',
        );
      }
      final index = int.tryParse(cols[0]) ?? -1;
      final frame = int.tryParse(cols[2]) ?? MavFrame.globalRelativeAlt;
      final command = int.tryParse(cols[3]) ?? MavCommand.waypoint.code;
      final p1 = _parseDouble(cols[4]);
      final p2 = _parseDouble(cols[5]);
      final p3 = _parseDouble(cols[6]);
      final p4 = _parseDouble(cols[7]);
      final x = _parseDouble(cols[8]);
      final y = _parseDouble(cols[9]);
      final z = _parseDouble(cols[10]);
      final autoContinue = (int.tryParse(cols[11]) ?? 1) != 0;

      if (index == 0) {
        home = LatLng(x, y);
        homeAlt = z;
        continue;
      }

      items.add(
        MissionItem(
          command: MavCommand.fromCode(command),
          frame: frame,
          latitude: x,
          longitude: y,
          altitude: z,
          param1: p1,
          param2: p2,
          param3: p3,
          param4: p4,
          autoContinue: autoContinue,
        ),
      );
    }

    return FlightMission(
      id: id,
      name: name,
      home: home,
      homeAltitude: homeAlt,
      items: items,
    );
  }

  // ── App JSON ─────────────────────────────────────────────────────────────

  /// Encodes [mission] as pretty-printed internal JSON.
  String encodeJson(FlightMission mission) =>
      const JsonEncoder.withIndent('  ').convert(mission.toJson());

  /// Parses internal JSON back into a [FlightMission].
  FlightMission decodeJson(String content) {
    try {
      final map = json.decode(content) as Map<String, dynamic>;
      return FlightMission.fromJson(map);
    } on FormatException catch (e) {
      throw MissionParseException('JSON không hợp lệ: ${e.message}');
    } on TypeError {
      throw MissionParseException('Cấu trúc JSON mission không đúng.');
    }
  }

  // ── helpers ──────────────────────────────────────────────────────────────

  String _row({
    required int index,
    required int current,
    required int frame,
    required int command,
    required double p1,
    required double p2,
    required double p3,
    required double p4,
    required double x,
    required double y,
    required double z,
    required int autoContinue,
  }) {
    return [
      index,
      current,
      frame,
      command,
      _fmt(p1),
      _fmt(p2),
      _fmt(p3),
      _fmt(p4),
      _fmt(x),
      _fmt(y),
      _fmt(z),
      autoContinue,
    ].join('\t');
  }

  /// Fixed 8-decimal formatting — matches Mission Planner output and keeps
  /// lat/lng precise to ~1 mm.
  String _fmt(double v) => v.toStringAsFixed(8);

  double _parseDouble(String s) => double.tryParse(s) ?? 0;
}
