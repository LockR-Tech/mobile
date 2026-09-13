import 'package:latlong2/latlong.dart';

import 'flight_modes.dart';
import 'mav_messages.dart';

/// Immutable snapshot of the vehicle's live state, folded from the stream of
/// incoming MAVLink messages. Fields are nullable until the matching message
/// has been received at least once.
class DroneTelemetry {
  const DroneTelemetry({
    this.position,
    this.altRelative,
    this.altMsl,
    this.headingDeg,
    this.groundspeed,
    this.airspeed,
    this.climb,
    this.throttle,
    this.roll = 0,
    this.pitch = 0,
    this.yaw = 0,
    this.armed = false,
    this.autopilot = 0,
    this.customMode = 0,
    this.batteryVolts,
    this.batteryAmps,
    this.batteryPercent,
    this.gpsFixType = 0,
    this.satellites,
    this.lastHeartbeatAt,
  });

  final LatLng? position;
  final double? altRelative; // m above home
  final double? altMsl; // m AMSL
  final double? headingDeg;
  final double? groundspeed; // m/s
  final double? airspeed; // m/s
  final double? climb; // m/s
  final int? throttle; // %

  final double roll; // rad
  final double pitch; // rad
  final double yaw; // rad

  final bool armed;
  final int autopilot;
  final int customMode;

  final double? batteryVolts;
  final double? batteryAmps;
  final int? batteryPercent;

  final int gpsFixType;
  final int? satellites;

  final DateTime? lastHeartbeatAt;

  String get modeName => flightModeName(autopilot, customMode);

  bool get hasFix => gpsFixType >= 3;

  String get gpsFixLabel => switch (gpsFixType) {
        0 || 1 => 'No Fix',
        2 => '2D',
        3 => '3D',
        4 => 'DGPS',
        5 => 'RTK Float',
        6 => 'RTK Fixed',
        _ => 'Fix $gpsFixType',
      };

  /// Whether a heartbeat has arrived within the last 3 seconds.
  bool get linkAlive {
    final t = lastHeartbeatAt;
    if (t == null) return false;
    return DateTime.now().difference(t) < const Duration(seconds: 3);
  }

  DroneTelemetry copyWith({
    LatLng? position,
    double? altRelative,
    double? altMsl,
    double? headingDeg,
    double? groundspeed,
    double? airspeed,
    double? climb,
    int? throttle,
    double? roll,
    double? pitch,
    double? yaw,
    bool? armed,
    int? autopilot,
    int? customMode,
    double? batteryVolts,
    double? batteryAmps,
    int? batteryPercent,
    int? gpsFixType,
    int? satellites,
    DateTime? lastHeartbeatAt,
  }) {
    return DroneTelemetry(
      position: position ?? this.position,
      altRelative: altRelative ?? this.altRelative,
      altMsl: altMsl ?? this.altMsl,
      headingDeg: headingDeg ?? this.headingDeg,
      groundspeed: groundspeed ?? this.groundspeed,
      airspeed: airspeed ?? this.airspeed,
      climb: climb ?? this.climb,
      throttle: throttle ?? this.throttle,
      roll: roll ?? this.roll,
      pitch: pitch ?? this.pitch,
      yaw: yaw ?? this.yaw,
      armed: armed ?? this.armed,
      autopilot: autopilot ?? this.autopilot,
      customMode: customMode ?? this.customMode,
      batteryVolts: batteryVolts ?? this.batteryVolts,
      batteryAmps: batteryAmps ?? this.batteryAmps,
      batteryPercent: batteryPercent ?? this.batteryPercent,
      gpsFixType: gpsFixType ?? this.gpsFixType,
      satellites: satellites ?? this.satellites,
      lastHeartbeatAt: lastHeartbeatAt ?? this.lastHeartbeatAt,
    );
  }

  /// Folds a single decoded [message] into a new snapshot.
  DroneTelemetry apply(MavMessage message) {
    switch (message) {
      case HeartbeatMsg m:
        return copyWith(
          armed: m.armed,
          autopilot: m.autopilot,
          customMode: m.customMode,
          lastHeartbeatAt: DateTime.now(),
        );
      case GlobalPositionIntMsg m:
        return copyWith(
          position: LatLng(m.latDeg, m.lonDeg),
          altMsl: m.altMeters,
          altRelative: m.relativeAltMeters,
          headingDeg: m.headingDeg,
        );
      case AttitudeMsg m:
        return copyWith(roll: m.roll, pitch: m.pitch, yaw: m.yaw);
      case VfrHudMsg m:
        return copyWith(
          groundspeed: m.groundspeed,
          airspeed: m.airspeed,
          climb: m.climb,
          throttle: m.throttle,
          altMsl: m.altMsl,
          headingDeg: m.headingDeg.toDouble(),
        );
      case SysStatusMsg m:
        return copyWith(
          batteryVolts: m.voltageVolts,
          batteryAmps: m.currentAmps,
          batteryPercent: m.remainingPercent,
        );
      case GpsRawIntMsg m:
        return copyWith(
          gpsFixType: m.fixType,
          satellites: m.satellitesVisible == 255 ? null : m.satellitesVisible,
        );
      case CommandAckMsg():
      case StatusTextMsg():
        return this;
    }
  }
}
