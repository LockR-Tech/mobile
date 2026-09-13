import 'package:latlong2/latlong.dart';

import 'mission_item.dart';

/// A complete drone flight plan: an ordered list of [MissionItem]s plus a home
/// (launch) point and planning defaults. Pure data + geometry — no drone or
/// backend involved (Mảng 1 / Flight Plan).
class FlightMission {
  FlightMission({
    required this.id,
    required this.name,
    required this.home,
    required this.homeAltitude,
    required this.items,
    this.defaultAltitude = 50,
    this.cruiseSpeed = 8,
    DateTime? updatedAt,
  }) : updatedAt = updatedAt ?? DateTime.now();

  /// A fresh, empty mission centred on [home].
  factory FlightMission.empty({
    required String id,
    String name = 'Kế hoạch bay mới',
    LatLng? home,
  }) {
    return FlightMission(
      id: id,
      name: name,
      home: home ?? const LatLng(10.762622, 106.660172), // TP.HCM mặc định
      homeAltitude: 0,
      items: const [],
    );
  }

  final String id;
  final String name;

  /// Launch / RTL point (exported as mission item 0 in QGC WPL).
  final LatLng home;
  final double homeAltitude;

  final List<MissionItem> items;

  /// Default altitude (m, relative) applied to newly-dropped waypoints.
  final double defaultAltitude;

  /// Planning cruise speed (m/s) used only to estimate flight time.
  final double cruiseSpeed;

  final DateTime updatedAt;

  static const Distance _distance = Distance();

  /// Number of items that carry a map position (true waypoints).
  int get waypointCount => items.where((i) => i.command.hasPosition).length;

  /// Ordered list of geographic points the aircraft flies through, starting at
  /// [home], used to draw the route polyline.
  List<LatLng> get pathPoints => [
    home,
    for (final item in items)
      if (item.point != null) item.point!,
  ];

  /// Total ground path length in metres (sum of haversine legs over
  /// [pathPoints]).
  double get totalDistanceMeters {
    final points = pathPoints;
    var total = 0.0;
    for (var i = 0; i < points.length - 1; i++) {
      total += _distance.as(LengthUnit.Meter, points[i], points[i + 1]);
    }
    return total;
  }

  /// Rough flight-time estimate in seconds at [cruiseSpeed]; `0` when the speed
  /// is non-positive or there is nothing to fly.
  double get estimatedSeconds {
    if (cruiseSpeed <= 0) return 0;
    return totalDistanceMeters / cruiseSpeed;
  }

  FlightMission copyWith({
    String? name,
    LatLng? home,
    double? homeAltitude,
    List<MissionItem>? items,
    double? defaultAltitude,
    double? cruiseSpeed,
    DateTime? updatedAt,
  }) {
    return FlightMission(
      id: id,
      name: name ?? this.name,
      home: home ?? this.home,
      homeAltitude: homeAltitude ?? this.homeAltitude,
      items: items ?? this.items,
      defaultAltitude: defaultAltitude ?? this.defaultAltitude,
      cruiseSpeed: cruiseSpeed ?? this.cruiseSpeed,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  /// Returns a copy with a different [id] (used when importing so a file never
  /// clobbers an existing library entry that happens to share an id).
  FlightMission withId(String id) => FlightMission(
    id: id,
    name: name,
    home: home,
    homeAltitude: homeAltitude,
    items: items,
    defaultAltitude: defaultAltitude,
    cruiseSpeed: cruiseSpeed,
    updatedAt: updatedAt,
  );

  /// Appends [item] and returns a new mission.
  FlightMission addItem(MissionItem item) =>
      copyWith(items: [...items, item]);

  /// Replaces the item at [index].
  FlightMission updateItem(int index, MissionItem item) {
    final next = [...items]..[index] = item;
    return copyWith(items: next);
  }

  /// Removes the item at [index].
  FlightMission removeItem(int index) {
    final next = [...items]..removeAt(index);
    return copyWith(items: next);
  }

  /// Moves an item from [oldIndex] to [newIndex] (reorder).
  FlightMission reorder(int oldIndex, int newIndex) {
    final next = [...items];
    final moved = next.removeAt(oldIndex);
    next.insert(newIndex.clamp(0, next.length), moved);
    return copyWith(items: next);
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'homeLat': home.latitude,
    'homeLng': home.longitude,
    'homeAlt': homeAltitude,
    'defaultAltitude': defaultAltitude,
    'cruiseSpeed': cruiseSpeed,
    'updatedAt': updatedAt.toIso8601String(),
    'items': items.map((i) => i.toJson()).toList(),
  };

  factory FlightMission.fromJson(Map<String, dynamic> json) {
    final rawItems = (json['items'] as List?) ?? const [];
    return FlightMission(
      id: json['id'] as String? ?? DateTime.now().millisecondsSinceEpoch.toString(),
      name: json['name'] as String? ?? 'Kế hoạch bay',
      home: LatLng(
        (json['homeLat'] as num?)?.toDouble() ?? 0,
        (json['homeLng'] as num?)?.toDouble() ?? 0,
      ),
      homeAltitude: (json['homeAlt'] as num?)?.toDouble() ?? 0,
      defaultAltitude: (json['defaultAltitude'] as num?)?.toDouble() ?? 50,
      cruiseSpeed: (json['cruiseSpeed'] as num?)?.toDouble() ?? 8,
      updatedAt:
          DateTime.tryParse(json['updatedAt'] as String? ?? '') ?? DateTime.now(),
      items: rawItems
          .whereType<Map<String, dynamic>>()
          .map(MissionItem.fromJson)
          .toList(),
    );
  }
}
