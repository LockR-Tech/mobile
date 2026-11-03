import 'package:smart_laundry_locker/core/l10n/l10n.dart';

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
    shortLabel: 'TAKEOFF',
    hasPosition: true,
  ),

  /// MAV_CMD_NAV_WAYPOINT — fly to a point and continue. param1 = hold time (s).
  waypoint(
    code: 16,
    shortLabel: 'WAYPOINT',
    hasPosition: true,
    extraParam: 1,
  ),

  /// MAV_CMD_NAV_LOITER_TIME — orbit a point for a number of seconds.
  /// param1 = seconds, param3 = radius (m).
  loiterTime(
    code: 19,
    shortLabel: 'LOITER_TIME',
    hasPosition: true,
    extraParam: 1,
  ),

  /// MAV_CMD_NAV_LOITER_TURNS — orbit a point for a number of turns.
  /// param1 = turns, param3 = radius (m).
  loiterTurns(
    code: 18,
    shortLabel: 'LOITER_TURNS',
    hasPosition: true,
    extraParam: 1,
  ),

  /// MAV_CMD_NAV_LOITER_UNLIM — orbit a point indefinitely. param3 = radius (m).
  loiterUnlim(
    code: 17,
    shortLabel: 'LOITER_UNLIM',
    hasPosition: true,
  ),

  /// MAV_CMD_NAV_RETURN_TO_LAUNCH — fly back to the launch point. No position.
  returnToLaunch(
    code: 20,
    shortLabel: 'RTL',
    hasPosition: false,
  ),

  /// MAV_CMD_NAV_LAND — land at the given point. param7 = altitude (usually 0).
  land(
    code: 21,
    shortLabel: 'LAND',
    hasPosition: true,
  ),

  /// MAV_CMD_DO_CHANGE_SPEED — change the cruise speed. param2 = speed (m/s).
  changeSpeed(
    code: 178,
    shortLabel: 'CHANGE_SPEED',
    hasPosition: false,
    extraParam: 2,
  );

  const MavCommand({
    required this.code,
    required this.shortLabel,
    required this.hasPosition,
    this.extraParam,
  });

  /// MAVLink `MAV_CMD` numeric code (used in the QGC WPL export).
  final int code;

  /// Display label for the editor, in the app language.
  String get label => switch (this) {
    takeoff => L10n.current.dtMavTakeoff,
    waypoint => L10n.current.dtMavWaypoint,
    loiterTime => L10n.current.dtMavLoiterTime,
    loiterTurns => L10n.current.dtMavLoiterTurns,
    loiterUnlim => L10n.current.dtMavLoiterUnlim,
    returnToLaunch => L10n.current.dtMavRtl,
    land => L10n.current.dtMavLand,
    changeSpeed => L10n.current.dtMavChangeSpeed,
  };

  /// Compact uppercase label shown on chips / the waypoint list.
  final String shortLabel;

  /// Whether this command targets a map coordinate (lat/lng + altitude). When
  /// false the item is "attached" to the previous waypoint on the map.
  final bool hasPosition;

  /// Human label for the one meaningful extra parameter, if any (e.g. loiter
  /// time, change-speed target). `null` ⇒ no extra parameter to edit.
  String? get extraLabel => switch (this) {
    waypoint => L10n.current.dtMavHoldAtPoint,
    loiterTime => L10n.current.dtMavDuration,
    loiterTurns => L10n.current.dtMavTurns,
    changeSpeed => L10n.current.dtMavSpeed,
    _ => null,
  };

  /// Unit shown next to the extra parameter.
  String? get extraUnit => switch (this) {
    waypoint || loiterTime => L10n.current.dtMavSeconds,
    loiterTurns => L10n.current.dtMavTurnsUnit,
    changeSpeed => 'm/s',
    _ => null,
  };

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
