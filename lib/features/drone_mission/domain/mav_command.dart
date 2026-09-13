/// MAVLink mission commands (`MAV_CMD`) supported by the in-app Mission
/// Planner. The numeric [code] matches the upstream ArduPilot/PX4 / MAVLink
/// definition, so missions exported as QGC WPL 110 (`.waypoints`) load directly
/// in Mission Planner / QGroundControl.
///
/// Only the subset that a courier/inspection drone realistically needs is
/// modelled. Each command declares whether it carries a map position and which
/// numeric parameter (param1..param4) is meaningful, so the editor can show the
/// right field instead of a generic param soup.
enum MavCommand {
  /// MAV_CMD_NAV_TAKEOFF — climb to the given altitude from the home/launch
  /// point. param7 = altitude.
  takeoff(
    code: 22,
    label: 'Cất cánh',
    shortLabel: 'TAKEOFF',
    hasPosition: true,
  ),

  /// MAV_CMD_NAV_WAYPOINT — fly to a point and continue. param1 = hold time (s).
  waypoint(
    code: 16,
    label: 'Bay tới điểm',
    shortLabel: 'WAYPOINT',
    hasPosition: true,
    extraLabel: 'Giữ tại điểm',
    extraUnit: 'giây',
    extraParam: 1,
  ),

  /// MAV_CMD_NAV_LOITER_TIME — orbit a point for a number of seconds.
  /// param1 = seconds, param3 = radius (m).
  loiterTime(
    code: 19,
    label: 'Bay vòng (thời gian)',
    shortLabel: 'LOITER_TIME',
    hasPosition: true,
    extraLabel: 'Thời gian',
    extraUnit: 'giây',
    extraParam: 1,
  ),

  /// MAV_CMD_NAV_LOITER_TURNS — orbit a point for a number of turns.
  /// param1 = turns, param3 = radius (m).
  loiterTurns(
    code: 18,
    label: 'Bay vòng (số vòng)',
    shortLabel: 'LOITER_TURNS',
    hasPosition: true,
    extraLabel: 'Số vòng',
    extraUnit: 'vòng',
    extraParam: 1,
  ),

  /// MAV_CMD_NAV_LOITER_UNLIM — orbit a point indefinitely. param3 = radius (m).
  loiterUnlim(
    code: 17,
    label: 'Bay vòng vô hạn',
    shortLabel: 'LOITER_UNLIM',
    hasPosition: true,
  ),

  /// MAV_CMD_NAV_RETURN_TO_LAUNCH — fly back to the launch point. No position.
  returnToLaunch(
    code: 20,
    label: 'Về điểm xuất phát (RTL)',
    shortLabel: 'RTL',
    hasPosition: false,
  ),

  /// MAV_CMD_NAV_LAND — land at the given point. param7 = altitude (usually 0).
  land(
    code: 21,
    label: 'Hạ cánh',
    shortLabel: 'LAND',
    hasPosition: true,
  ),

  /// MAV_CMD_DO_CHANGE_SPEED — change the cruise speed. param2 = speed (m/s).
  changeSpeed(
    code: 178,
    label: 'Đổi tốc độ bay',
    shortLabel: 'CHANGE_SPEED',
    hasPosition: false,
    extraLabel: 'Tốc độ',
    extraUnit: 'm/s',
    extraParam: 2,
  );

  const MavCommand({
    required this.code,
    required this.label,
    required this.shortLabel,
    required this.hasPosition,
    this.extraLabel,
    this.extraUnit,
    this.extraParam,
  });

  /// MAVLink `MAV_CMD` numeric code (used in the QGC WPL export).
  final int code;

  /// Vietnamese display label for the editor.
  final String label;

  /// Compact uppercase label shown on chips / the waypoint list.
  final String shortLabel;

  /// Whether this command targets a map coordinate (lat/lng + altitude). When
  /// false the item is "attached" to the previous waypoint on the map.
  final bool hasPosition;

  /// Human label for the one meaningful extra parameter, if any (e.g. loiter
  /// time, change-speed target). `null` ⇒ no extra parameter to edit.
  final String? extraLabel;

  /// Unit shown next to the extra parameter.
  final String? extraUnit;

  /// Which `param{n}` (1..4) the extra parameter maps to in the MAVLink frame.
  final int? extraParam;

  bool get hasExtraParam => extraParam != null;

  /// Whether this command carries an editable altitude (param7).
  bool get hasAltitude => hasPosition;

  /// Resolve a [MavCommand] from a raw MAVLink code, falling back to
  /// [waypoint] for codes the planner does not model (so imports never crash).
  static MavCommand fromCode(int code) {
    for (final c in MavCommand.values) {
      if (c.code == code) return c;
    }
    return MavCommand.waypoint;
  }
}
