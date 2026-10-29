import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:smart_laundry_locker/core/theme/shadcn_theme.dart';
import 'package:smart_laundry_locker/features/drone_delivery/domain/entities/drone_delivery_stage.dart';
import 'package:smart_laundry_locker/features/drone_delivery/domain/entities/drone_delivery_status.dart';
import 'package:smart_laundry_locker/features/drone_delivery/domain/entities/drone_position_snapshot.dart';
import 'package:smart_laundry_locker/features/drone_delivery/domain/entities/drone_route_geometry.dart';
import 'package:smart_laundry_locker/features/drone_delivery/presentation/drone_live_map.dart';
import 'package:smart_laundry_locker/features/drone_delivery/presentation/providers/drone_live_map_providers.dart';
import 'package:smart_laundry_locker/features/drone_delivery/presentation/widgets/drone_coordinates_line.dart';
import 'package:smart_laundry_locker/features/drone_delivery/presentation/widgets/drone_marker.dart';
import 'package:smart_laundry_locker/features/drone_delivery/presentation/widgets/drone_base_tile_layer.dart';

/// Bản đồ tóm tắt hành trình: tủ gửi A, tủ nhận B, đoạn đã bay và vị trí drone
/// ước theo chặng hiện tại. Không cho kéo/zoom để cuộn trang không bị bản đồ "nuốt";
/// theo dõi vị trí thật từng giây ở màn live map.
class DroneRouteMapCard extends ConsumerWidget {
  const DroneRouteMapCard({
    super.key,
    required this.status,
    this.forOperator = false,
  });

  final DroneDeliveryStatus status;

  /// Màn KTV drone (chi tiết nhiệm vụ) không có nút mở bản đồ trực tiếp.
  final bool forOperator;

  static const Color _sourceColor = Color(0xFF0F766E);
  static const Color _plannedColor = Color(0xFF94A3B8);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final source = status.sourceLocker;
    final destination = status.destinationLocker;
    if (source == null ||
        destination == null ||
        !source.hasCoordinates ||
        !destination.hasCoordinates) {
      return const _Frame(
        child: Text(
          'Tủ gửi hoặc tủ nhận chưa có toạ độ nên chưa vẽ được bản đồ hành trình.',
          style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
        ),
      );
    }

    final a = LatLng(source.latitude!, source.longitude!);
    final b = LatLng(destination.latitude!, destination.longitude!);
    final stage = status.stage;
    final progress = _progress(stage);
    // Drone bay tới đâu bắn toạ độ về tới đó (STOMP); thẻ nghe trực tiếp trong lúc bay.
    final live = droneListensLivePosition(status)
        ? ref.watch(dronePositionStreamProvider(status.orderId!)).value
        : null;
    final position = droneReportedPosition(status, live, a, b);
    final drone = progress == null
        ? null
        : position?.point ??
              LatLng(
                a.latitude + (b.latitude - a.latitude) * progress,
                a.longitude + (b.longitude - a.longitude) * progress,
              );
    final totalKm = droneDistanceKm(a.latitude, a.longitude, b.latitude, b.longitude);
    final remainingKm = drone == null
        ? null
        : droneDistanceKm(drone.latitude, drone.longitude, b.latitude, b.longitude);
    final reportedLive = position != null && !position.estimated;

    return _Frame(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: SizedBox(
              height: 220,
              child: FlutterMap(
                options: MapOptions(
                  initialCameraFit: CameraFit.bounds(
                    bounds: LatLngBounds(a, b),
                    padding: const EdgeInsets.all(48),
                    maxZoom: 17,
                  ),
                  interactionOptions: const InteractionOptions(
                    flags: InteractiveFlag.none,
                  ),
                ),
                children: [
                  droneBaseTileLayer(),
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: [a, b],
                        color: _plannedColor,
                        strokeWidth: 3,
                        pattern: StrokePattern.dashed(segments: const [10, 6]),
                      ),
                      if (drone != null || _arrived(stage))
                        Polyline(
                          points: [a, drone ?? b],
                          color: AISLShadcnTheme.navyAccent,
                          strokeWidth: 4,
                        ),
                    ],
                  ),
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: a,
                        width: 34,
                        height: 34,
                        child: const _PointMarker(label: 'A', color: _sourceColor),
                      ),
                      Marker(
                        point: b,
                        width: 34,
                        height: 34,
                        child: const _PointMarker(
                          label: 'B',
                          color: AISLShadcnTheme.navyPrimary,
                        ),
                      ),
                      if (drone != null)
                        Marker(
                          point: drone,
                          width: 40,
                          height: 40,
                          child: DroneMarker(headingDeg: _bearing(a, b)),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _Stat(
                icon: LucideIcons.route,
                text: 'Quãng đường ${droneKmLabel(totalKm)}',
              ),
              if (remainingKm != null)
                _Stat(
                  icon: LucideIcons.navigation,
                  text: 'Còn khoảng ${droneKmLabel(remainingKm)}',
                ),
              _Stat(icon: stage.icon, text: stage.title, color: stage.color),
            ],
          ),
          if (position != null) ...[
            const SizedBox(height: 8),
            DroneCoordinatesLine(
              key: const ValueKey('drone-route-coordinates'),
              latitude: position.point.latitude,
              longitude: position.point.longitude,
              note: position.note,
            ),
          ],
          if (drone != null) ...[
            const SizedBox(height: 6),
            // KTV: số đo bay thật xem ở khung camera; khách: chỉ nhắc mở bản đồ trực tiếp khi màn có nút đó.
            Text(
              reportedLive
                  ? 'Toạ độ cập nhật mỗi khi drone gửi vị trí về. Bấm vào toạ độ để mở Google Maps.'
                  : forOperator
                  ? 'Vị trí drone ước theo chặng bay hiện tại. Số đo bay thật (GPS, pin, chế độ bay) xem ở khung camera phía trên.'
                  : (droneLiveMapAvailable(status)
                      ? 'Vị trí drone ước theo chặng bay hiện tại. Mở "Theo dõi trên bản đồ" để xem vị trí ${droneIsSimulated(status) ? 'mô phỏng' : 'trực tiếp'}.'
                      : 'Vị trí drone ước theo chặng bay hiện tại.'),
              style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
            ),
          ],
        ],
      ),
    );
  }

  /// Hàng đã tới tủ nhận thì cả đoạn A → B là đoạn đã bay.
  static bool _arrived(DroneDeliveryStage stage) =>
      stage == DroneDeliveryStage.readyForPickup ||
      stage == DroneDeliveryStage.completed;

  static double? _progress(DroneDeliveryStage stage) {
    if (_arrived(stage)) return null;
    return droneStageProgress(stage);
  }

  /// Hướng A → B, độ (0 = Bắc, thuận kim đồng hồ) — cho mũi drone trên bản đồ.
  static double _bearing(LatLng from, LatLng to) {
    final lat1 = from.latitudeInRad;
    final lat2 = to.latitudeInRad;
    final dLng = to.longitudeInRad - from.longitudeInRad;
    final y = math.sin(dLng) * math.cos(lat2);
    final x =
        math.cos(lat1) * math.sin(lat2) -
        math.sin(lat1) * math.cos(lat2) * math.cos(dLng);
    return (math.atan2(y, x) * 180 / math.pi + 360) % 360;
  }
}

/// Toạ độ drone đưa lên thẻ, theo thứ tự tin cậy: bản tin drone vừa bắn về (STOMP) → toạ độ API chi tiết
/// trả (cùng nguồn với bản tin) → ước theo chặng khi chưa có số nào. `estimated` = chỉ là ước lượng.
@visibleForTesting
({LatLng point, String note, bool estimated})? droneReportedPosition(
  DroneDeliveryStatus status,
  DronePositionSnapshot? live,
  LatLng source,
  LatLng destination,
) {
  final simulated = droneIsSimulated(status);
  if (live != null) {
    final t = live.timestamp.toLocal();
    String two(int v) => v.toString().padLeft(2, '0');
    return (
      point: LatLng(live.lat, live.lng),
      note:
          'Drone gửi về lúc ${two(t.hour)}:${two(t.minute)}:${two(t.second)}${simulated ? ' · mô phỏng' : ''}',
      estimated: false,
    );
  }
  final lat = status.currentLatitude;
  final lng = status.currentLongitude;
  if (lat != null && lng != null) {
    final atLocker = const {
      DroneDeliveryStage.readyForPickup,
      DroneDeliveryStage.completed,
    }.contains(status.stage);
    return (
      point: LatLng(lat, lng),
      note: atLocker
          ? 'Tại tủ nhận'
          : simulated
          ? 'Mô phỏng theo chặng bay'
          : 'Theo telemetry của drone',
      estimated: false,
    );
  }
  final guess = dronePositionOnRoute(status.stage, source, destination);
  if (guess == null) return null;
  return (
    point: guess.point,
    note: simulated ? '${guess.note} · mô phỏng' : guess.note,
    estimated: true,
  );
}

/// Vị trí drone hiển thị dưới dạng toạ độ: ước theo chặng khi đang bay, tủ gửi khi chưa cất cánh,
/// tủ nhận khi đã tới. Chặng lỗi / huỷ / báo rơi kiện thì không đoán vị trí.
@visibleForTesting
({LatLng point, String note})? dronePositionOnRoute(
  DroneDeliveryStage stage,
  LatLng source,
  LatLng destination,
) {
  final progress = droneStageProgress(stage);
  if (progress != null && progress < 1.0) {
    return (
      point: LatLng(
        source.latitude + (destination.latitude - source.latitude) * progress,
        source.longitude + (destination.longitude - source.longitude) * progress,
      ),
      note: 'Ước theo chặng bay',
    );
  }
  return switch (stage) {
    DroneDeliveryStage.arrived ||
    DroneDeliveryStage.readyForPickup ||
    DroneDeliveryStage.completed => (point: destination, note: 'Tại tủ nhận'),
    DroneDeliveryStage.awaitingDispatch ||
    DroneDeliveryStage.pickupAssigned ||
    DroneDeliveryStage.pickedUp ||
    DroneDeliveryStage.accepted => (
      point: source,
      note: 'Tại tủ gửi, chưa cất cánh',
    ),
    _ => null,
  };
}

class _Frame extends StatelessWidget {
  const _Frame({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: const Color(0xFFE2E8F0)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Row(
          children: [
            Icon(LucideIcons.map, size: 18, color: AISLShadcnTheme.navyPrimary),
            SizedBox(width: 8),
            Text(
              'Bản đồ hành trình',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ],
        ),
        const SizedBox(height: 14),
        child,
      ],
    ),
  );
}

class _PointMarker extends StatelessWidget {
  const _PointMarker({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: color,
      shape: BoxShape.circle,
      border: Border.all(color: Colors.white, width: 2.5),
      boxShadow: [
        BoxShadow(color: color.withValues(alpha: 0.35), blurRadius: 6),
      ],
    ),
    child: Text(
      label,
      style: const TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.w800,
        fontSize: 14,
      ),
    ),
  );
}

class _Stat extends StatelessWidget {
  const _Stat({
    required this.icon,
    required this.text,
    this.color = AISLShadcnTheme.navyPrimary,
  });

  final IconData icon;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(10),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ),
      ],
    ),
  );
}
