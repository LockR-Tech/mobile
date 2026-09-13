/// Common MAV_CMD command ids the Flight Data screen issues.
class MavCmd {
  const MavCmd._();
  static const int componentArmDisarm = 400;
  static const int navTakeoff = 22;
  static const int navReturnToLaunch = 20;
  static const int navLand = 21;
  static const int missionStart = 300;
}

/// MAV_AUTOPILOT enum values we branch on for mode naming.
class MavAutopilot {
  const MavAutopilot._();
  static const int ardupilotmega = 3;
  static const int px4 = 12;
}

/// ArduCopter flight-mode numbers (the `custom_mode` field), used both to name
/// the active mode and to switch modes via SET_MODE.
class ArduCopterMode {
  const ArduCopterMode._();
  static const int stabilize = 0;
  static const int altHold = 2;
  static const int auto = 3;
  static const int guided = 4;
  static const int loiter = 5;
  static const int rtl = 6;
  static const int land = 9;
  static const int poshold = 16;
  static const int smartRtl = 21;

  static const Map<int, String> names = {
    0: 'STABILIZE',
    1: 'ACRO',
    2: 'ALT_HOLD',
    3: 'AUTO',
    4: 'GUIDED',
    5: 'LOITER',
    6: 'RTL',
    7: 'CIRCLE',
    9: 'LAND',
    11: 'DRIFT',
    13: 'SPORT',
    14: 'FLIP',
    15: 'AUTOTUNE',
    16: 'POSHOLD',
    17: 'BRAKE',
    18: 'THROW',
    20: 'GUIDED_NOGPS',
    21: 'SMART_RTL',
    22: 'FLOWHOLD',
    23: 'FOLLOW',
    24: 'ZIGZAG',
    27: 'AUTO_RTL',
  };
}

/// Resolves a human-readable flight-mode name from a heartbeat's autopilot type
/// and `custom_mode`. Falls back to a raw number when the dialect is unknown.
String flightModeName(int autopilot, int customMode) {
  if (autopilot == MavAutopilot.ardupilotmega) {
    return ArduCopterMode.names[customMode] ?? 'MODE $customMode';
  }
  // PX4 packs main/sub mode into the high bytes; surface the raw value rather
  // than guess the wrong label.
  return 'MODE $customMode';
}
