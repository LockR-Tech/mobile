import 'package:latlong2/latlong.dart';

import 'mav_command.dart';

/// MAVLink coordinate frames used by the planner.
///
/// Home (item 0) is conventionally absolute (`GLOBAL`), while flight waypoints
/// use altitude relative to the launch point (`GLOBAL_RELATIVE_ALT`), matching
/// how Mission Planner / QGroundControl write `.waypoints` files.
class MavFrame {
  const MavFrame._();

  /// MAV_FRAME_GLOBAL — altitude is AMSL (above mean sea level).
  static const int global = 0;

  /// MAV_FRAME_GLOBAL_RELATIVE_ALT — altitude relative to the home point.
  static const int globalRelativeAlt = 3;
}

/// A single mission item: one row of a MAVLink mission / one `.waypoints` line.
///
/// Position-less commands (RTL, change-speed) keep [latitude]/[longitude] at 0
/// and are rendered inline in the waypoint list rather than on the map.
class MissionItem {
  MissionItem({
    required this.command,
    required this.latitude,
    required this.longitude,
    required this.altitude,
    this.frame = MavFrame.globalRelativeAlt,
    this.param1 = 0,
    this.param2 = 0,
    this.param3 = 0,
    this.param4 = 0,
    this.autoContinue = true,
  });

  /// Convenience constructor for a plain fly-to waypoint at [point].
  factory MissionItem.waypoint(LatLng point, double altitude) => MissionItem(
    command: MavCommand.waypoint,
    latitude: point.latitude,
    longitude: point.longitude,
    altitude: altitude,
  );

  final MavCommand command;
  final int frame;
  final double latitude;
  final double longitude;
  final double altitude;
  final double param1;
  final double param2;
  final double param3;
  final double param4;
  final bool autoContinue;

  /// The map position, or `null` for position-less commands.
  LatLng? get point =>
      command.hasPosition ? LatLng(latitude, longitude) : null;

  /// Value of the command's meaningful extra parameter (see
  /// [MavCommand.extraParam]), or `null` when the command has none.
  double? get extraValue {
    switch (command.extraParam) {
      case 1:
        return param1;
      case 2:
        return param2;
      case 3:
        return param3;
      case 4:
        return param4;
      default:
        return null;
    }
  }

  MissionItem copyWith({
    MavCommand? command,
    int? frame,
    double? latitude,
    double? longitude,
    double? altitude,
    double? param1,
    double? param2,
    double? param3,
    double? param4,
    bool? autoContinue,
  }) {
    return MissionItem(
      command: command ?? this.command,
      frame: frame ?? this.frame,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      altitude: altitude ?? this.altitude,
      param1: param1 ?? this.param1,
      param2: param2 ?? this.param2,
      param3: param3 ?? this.param3,
      param4: param4 ?? this.param4,
      autoContinue: autoContinue ?? this.autoContinue,
    );
  }

  /// Returns a copy with the command's extra parameter set to [value],
  /// writing into the correct `param{n}` slot.
  MissionItem withExtraValue(double value) {
    switch (command.extraParam) {
      case 1:
        return copyWith(param1: value);
      case 2:
        return copyWith(param2: value);
      case 3:
        return copyWith(param3: value);
      case 4:
        return copyWith(param4: value);
      default:
        return this;
    }
  }

  /// Returns a copy moved to [target] (no-op for position-less commands).
  MissionItem movedTo(LatLng target) => command.hasPosition
      ? copyWith(latitude: target.latitude, longitude: target.longitude)
      : this;

  Map<String, dynamic> toJson() => {
    'command': command.code,
    'frame': frame,
    'lat': latitude,
    'lng': longitude,
    'alt': altitude,
    'p1': param1,
    'p2': param2,
    'p3': param3,
    'p4': param4,
    'autoContinue': autoContinue,
  };

  factory MissionItem.fromJson(Map<String, dynamic> json) => MissionItem(
    command: MavCommand.fromCode((json['command'] as num?)?.toInt() ?? 16),
    frame: (json['frame'] as num?)?.toInt() ?? MavFrame.globalRelativeAlt,
    latitude: (json['lat'] as num?)?.toDouble() ?? 0,
    longitude: (json['lng'] as num?)?.toDouble() ?? 0,
    altitude: (json['alt'] as num?)?.toDouble() ?? 0,
    param1: (json['p1'] as num?)?.toDouble() ?? 0,
    param2: (json['p2'] as num?)?.toDouble() ?? 0,
    param3: (json['p3'] as num?)?.toDouble() ?? 0,
    param4: (json['p4'] as num?)?.toDouble() ?? 0,
    autoContinue: json['autoContinue'] as bool? ?? true,
  );
}
