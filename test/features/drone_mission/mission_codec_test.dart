import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:smart_laundry_locker/features/drone_mission/data/mission_codec.dart';
import 'package:smart_laundry_locker/features/drone_mission/domain/flight_mission.dart';
import 'package:smart_laundry_locker/features/drone_mission/domain/mav_command.dart';
import 'package:smart_laundry_locker/features/drone_mission/domain/mission_item.dart';

void main() {
  const codec = MissionCodec();

  FlightMission sampleMission() => FlightMission(
    id: 'm1',
    name: 'Tuần tra khu A',
    home: const LatLng(10.762622, 106.660172),
    homeAltitude: 0,
    cruiseSpeed: 10,
    defaultAltitude: 60,
    items: [
      MissionItem(
        command: MavCommand.takeoff,
        latitude: 10.762622,
        longitude: 106.660172,
        altitude: 30,
      ),
      MissionItem.waypoint(const LatLng(10.7700, 106.6700), 60),
      MissionItem(
        command: MavCommand.loiterTime,
        latitude: 10.7750,
        longitude: 106.6750,
        altitude: 60,
        param1: 45, // 45s loiter
      ),
      MissionItem(
        command: MavCommand.returnToLaunch,
        latitude: 0,
        longitude: 0,
        altitude: 0,
      ),
    ],
  );

  group('QGC WPL 110', () {
    test('round-trips home, commands, coordinates and altitudes', () {
      final mission = sampleMission();
      final text = codec.encodeWaypoints(mission);

      expect(text.startsWith('QGC WPL 110'), isTrue);
      // Header + home row + 4 items = 6 lines.
      expect(text.trim().split('\n').length, 6);
      // Rows are tab-separated.
      expect(text.contains('\t'), isTrue);

      final decoded = codec.decodeWaypoints(text, id: 'imported');
      expect(decoded.home.latitude, closeTo(mission.home.latitude, 1e-6));
      expect(decoded.home.longitude, closeTo(mission.home.longitude, 1e-6));
      expect(decoded.items.length, mission.items.length);

      for (var i = 0; i < mission.items.length; i++) {
        final a = mission.items[i];
        final b = decoded.items[i];
        expect(b.command, a.command, reason: 'command[$i]');
        expect(b.altitude, closeTo(a.altitude, 1e-4), reason: 'alt[$i]');
        expect(b.latitude, closeTo(a.latitude, 1e-6), reason: 'lat[$i]');
        expect(b.longitude, closeTo(a.longitude, 1e-6), reason: 'lng[$i]');
      }
      // Loiter time param preserved.
      expect(decoded.items[2].extraValue, closeTo(45, 1e-6));
    });

    test('rejects content without the QGC WPL header', () {
      expect(
        () => codec.decodeWaypoints('not a mission file', id: 'x'),
        throwsA(isA<MissionParseException>()),
      );
    });

    test('unknown command codes fall back to WAYPOINT', () {
      const raw = 'QGC WPL 110\n'
          '0\t1\t0\t16\t0\t0\t0\t0\t10.0\t106.0\t0\t1\n'
          '1\t0\t3\t9999\t0\t0\t0\t0\t10.1\t106.1\t50\t1\n';
      final decoded = codec.decodeWaypoints(raw, id: 'x');
      expect(decoded.items.single.command, MavCommand.waypoint);
    });
  });

  group('App JSON', () {
    test('round-trips the full mission losslessly', () {
      final mission = sampleMission();
      final decoded = codec.decodeJson(codec.encodeJson(mission));

      expect(decoded.id, mission.id);
      expect(decoded.name, mission.name);
      expect(decoded.cruiseSpeed, mission.cruiseSpeed);
      expect(decoded.defaultAltitude, mission.defaultAltitude);
      expect(decoded.items.length, mission.items.length);
      expect(decoded.items.first.command, MavCommand.takeoff);
      expect(decoded.home.latitude, closeTo(mission.home.latitude, 1e-9));
    });

    test('throws on malformed JSON', () {
      expect(
        () => codec.decodeJson('{not json'),
        throwsA(isA<MissionParseException>()),
      );
    });
  });

  group('FlightMission geometry', () {
    test('total distance counts only positioned legs from home', () {
      final mission = sampleMission();
      // home -> takeoff(same pt) -> wp -> loiter -> (RTL has no position)
      expect(mission.pathPoints.length, 4); // home + 3 positioned items
      expect(mission.totalDistanceMeters, greaterThan(0));
      expect(mission.estimatedSeconds,
          closeTo(mission.totalDistanceMeters / mission.cruiseSpeed, 1e-6));
    });

    test('waypointCount ignores position-less commands', () {
      expect(sampleMission().waypointCount, 3);
    });
  });
}
