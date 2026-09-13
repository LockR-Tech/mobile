/// Numeric MAVLink message ids the app understands.
class MavMsgId {
  const MavMsgId._();
  static const int heartbeat = 0;
  static const int sysStatus = 1;
  static const int gpsRawInt = 24;
  static const int attitude = 30;
  static const int globalPositionInt = 33;
  static const int vfrHud = 74;
  static const int commandAck = 77;
  static const int statustext = 253;
  // Outgoing (ground-station → vehicle).
  static const int setMode = 11;
  static const int requestDataStream = 66;
  static const int commandLong = 76;
}

/// Base type for a decoded MAVLink message we care about. Unknown messages are
/// dropped by the protocol layer rather than wrapped.
sealed class MavMessage {
  const MavMessage();
}

/// HEARTBEAT (#0) — liveness, vehicle type, base/custom mode, armed flag.
class HeartbeatMsg extends MavMessage {
  const HeartbeatMsg({
    required this.type,
    required this.autopilot,
    required this.baseMode,
    required this.customMode,
    required this.systemStatus,
  });

  final int type;
  final int autopilot;
  final int baseMode;
  final int customMode;
  final int systemStatus;

  /// MAV_MODE_FLAG_SAFETY_ARMED (bit 7) of `base_mode`.
  bool get armed => (baseMode & 0x80) != 0;
}

/// SYS_STATUS (#1) — battery voltage/current/remaining.
class SysStatusMsg extends MavMessage {
  const SysStatusMsg({
    required this.voltageBatteryMv,
    required this.currentBatteryCa,
    required this.batteryRemaining,
  });

  final int voltageBatteryMv; // mV (0xFFFF = unknown)
  final int currentBatteryCa; // cA (-1 = unknown)
  final int batteryRemaining; // % (-1 = unknown)

  double? get voltageVolts =>
      voltageBatteryMv == 0xFFFF ? null : voltageBatteryMv / 1000.0;
  double? get currentAmps =>
      currentBatteryCa == -1 ? null : currentBatteryCa / 100.0;
  int? get remainingPercent => batteryRemaining < 0 ? null : batteryRemaining;
}

/// GPS_RAW_INT (#24) — fix type and satellite count.
class GpsRawIntMsg extends MavMessage {
  const GpsRawIntMsg({required this.fixType, required this.satellitesVisible});
  final int fixType; // 0-1 no fix, 2 = 2D, 3 = 3D, 4 = DGPS, 5/6 = RTK
  final int satellitesVisible; // 255 = unknown
}

/// ATTITUDE (#30) — roll/pitch/yaw (radians).
class AttitudeMsg extends MavMessage {
  const AttitudeMsg({required this.roll, required this.pitch, required this.yaw});
  final double roll;
  final double pitch;
  final double yaw;
}

/// GLOBAL_POSITION_INT (#33) — fused global position.
class GlobalPositionIntMsg extends MavMessage {
  const GlobalPositionIntMsg({
    required this.lat,
    required this.lon,
    required this.altMm,
    required this.relativeAltMm,
    required this.hdgCdeg,
  });

  final int lat; // degE7
  final int lon; // degE7
  final int altMm; // mm AMSL
  final int relativeAltMm; // mm above home
  final int hdgCdeg; // cdeg (0..35999), 65535 = unknown

  double get latDeg => lat / 1e7;
  double get lonDeg => lon / 1e7;
  double get altMeters => altMm / 1000.0;
  double get relativeAltMeters => relativeAltMm / 1000.0;
  double? get headingDeg => hdgCdeg == 65535 ? null : hdgCdeg / 100.0;
}

/// VFR_HUD (#74) — airspeed/groundspeed/alt/climb/heading/throttle.
class VfrHudMsg extends MavMessage {
  const VfrHudMsg({
    required this.airspeed,
    required this.groundspeed,
    required this.altMsl,
    required this.climb,
    required this.headingDeg,
    required this.throttle,
  });

  final double airspeed; // m/s
  final double groundspeed; // m/s
  final double altMsl; // m
  final double climb; // m/s
  final int headingDeg; // deg 0..360
  final int throttle; // %
}

/// COMMAND_ACK (#77) — result of a command we sent.
class CommandAckMsg extends MavMessage {
  const CommandAckMsg({required this.command, required this.result});
  final int command;
  final int result; // 0 = MAV_RESULT_ACCEPTED
  bool get accepted => result == 0;
}

/// STATUSTEXT (#253) — autopilot text notice.
class StatusTextMsg extends MavMessage {
  const StatusTextMsg({required this.severity, required this.text});
  final int severity; // 0 = emergency .. 7 = debug
  final String text;
}
