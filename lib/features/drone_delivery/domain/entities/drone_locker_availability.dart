import 'package:smart_laundry_locker/features/drone_delivery/domain/entities/drone_route_geometry.dart';
import 'package:smart_laundry_locker/core/l10n/l10n.dart';

String? droneDestinationBlockReason({
  Object? status,
  Object? online,
  Object? landingPad,
  Object? landingPadStatus,
}) {
  if (online == false) return L10n.current.blockDisconnected;

  final lockerStatus = '${status ?? 'ACTIVE'}'.trim().toUpperCase();
  if (lockerStatus != 'ACTIVE') {
    return lockerStatus == 'MAINTENANCE' ? L10n.current.blockMaintenance : L10n.current.blockSuspended;
  }

  if (landingPad == false) return L10n.current.blockNoPad;

  final padStatus = landingPadStatus == null
      ? 'OK'
      : '$landingPadStatus'.trim().toUpperCase();
  if (padStatus.isEmpty || padStatus == 'OK') return null;
  return padStatus == 'MAINTENANCE'
      ? L10n.current.blockPadMaintenance
      : L10n.current.blockPadFault;
}

double? _asDouble(Object? value) =>
    value is num ? value.toDouble() : double.tryParse('$value');

int? _asInt(Object? value) =>
    value is num ? value.toInt() : int.tryParse('$value');

/// Khoảng cách đường chim bay (km) từ vị trí khách hàng [refLat], [refLng] tới [locker].
/// Trả về null khi thiếu toạ độ khách hoặc toạ độ tủ.
double? lockerDistanceKmFrom(
  Map<String, dynamic> locker,
  double? refLat,
  double? refLng,
) {
  if (refLat == null || refLng == null) return null;
  final lat = _asDouble(locker['latitude']);
  final lng = _asDouble(locker['longitude']);
  if (lat == null || lng == null) return null;
  return droneDistanceKm(refLat, refLng, lat, lng);
}

/// Sắp xếp danh sách tủ theo khoảng cách gần vị trí khách hàng nhất.
/// Các tủ chưa có toạ độ được xếp cuối theo thứ tự `id` tăng dần.
List<Map<String, dynamic>> sortLockersByCustomerDistance(
  Iterable<Map<String, dynamic>> lockers, {
  double? customerLatitude,
  double? customerLongitude,
}) {
  final list = lockers.toList(growable: false);
  if (customerLatitude == null || customerLongitude == null || list.length <= 1) {
    return list;
  }
  final indexed = List<int>.generate(list.length, (i) => i);
  final distances = <int, double?>{
    for (var i = 0; i < list.length; i++)
      i: lockerDistanceKmFrom(list[i], customerLatitude, customerLongitude),
  };
  indexed.sort((a, b) {
    final da = distances[a];
    final db = distances[b];
    if (da != null && db != null) {
      final cmp = da.compareTo(db);
      if (cmp != 0) return cmp;
    } else if (da != null) {
      return -1;
    } else if (db != null) {
      return 1;
    }
    final idA = _asInt(list[a]['id']) ?? a;
    final idB = _asInt(list[b]['id']) ?? b;
    return idA.compareTo(idB);
  });
  return [for (final idx in indexed) list[idx]];
}
