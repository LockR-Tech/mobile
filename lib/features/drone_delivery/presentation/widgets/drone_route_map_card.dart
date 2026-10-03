import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:smart_laundry_locker/core/theme/shadcn_theme.dart';
import 'package:smart_laundry_locker/features/drone_delivery/domain/entities/drone_delivery_stage.dart';
import 'package:smart_laundry_locker/features/drone_delivery/domain/entities/drone_delivery_status.dart';
import 'package:smart_laundry_locker/features/drone_delivery/domain/entities/drone_route_geometry.dart';
import 'package:smart_laundry_locker/features/drone_delivery/presentation/widgets/drone_marker.dart';

/// Bản đồ tóm tắt hành trình: tủ gửi A, tủ nhận B, đoạn đã bay và vị trí drone
/// ước theo chặng hiện tại. Không cho kéo/zoom để cuộn trang không bị bản đồ "nuốt";
/// theo dõi vị trí thật từng giây ở màn live map.
class DroneRouteMapCard extends StatelessWidget {
  const DroneRouteMapCard({super.key, required this.status});

  final DroneDeliveryStatus status;

  static const Color _sourceColor = Color(0xFF0F766E);
  static const Color _plannedColor = Color(0xFF94A3B8);

  @override
  Widget build(BuildContext context) {
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
    final drone = progress == null
        ? null
        : LatLng(
            a.latitude + (b.latitude - a.latitude) * progress,
            a.longitude + (b.longitude - a.longitude) * progress,
          );
    final totalKm = droneDistanceKm(a.latitude, a.longitude, b.latitude, b.longitude);
    final remainingKm = progress == null ? null : totalKm * (1 - progress);

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
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.aisl.app',
                  ),
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
          if (drone != null) ...[
            const SizedBox(height: 6),
            const Text(
              'Vị trí drone ước theo chặng bay hiện tại. Mở "Theo dõi trên bản đồ" để xem vị trí trực tiếp.',
              style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
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
