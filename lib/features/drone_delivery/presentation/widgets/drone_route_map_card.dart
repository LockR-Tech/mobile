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
/// ước theo chặng hiện tại. Trong thẻ chỉ phóng to/thu nhỏ bằng hai ngón, chạm đúp
/// hoặc nút +/− (kéo một ngón vẫn để cuộn trang); nút ⤢ mở bản đồ toàn màn hình
/// kéo/zoom tự do. Theo dõi vị trí thật từng giây ở màn live map.
class DroneRouteMapCard extends ConsumerWidget {
  const DroneRouteMapCard({
    super.key,
    required this.status,
    this.forOperator = false,
  });

  final DroneDeliveryStatus status;

  /// Màn KTV drone (chi tiết nhiệm vụ) không có nút mở bản đồ trực tiếp.
  final bool forOperator;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final view = _routeView(ref, status);
    if (view == null) {
      return const _Frame(
        child: Text(
          'Tủ gửi hoặc tủ nhận chưa có toạ độ nên chưa vẽ được bản đồ hành trình.',
          style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
        ),
      );
    }
    final a = view.a;
    final b = view.b;
    final stage = status.stage;
    final position = view.position;
    final drone = view.drone;
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
              child: DroneRouteMap(
                view: view,
                fullScreen: false,
                onExpand: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => DroneRouteMapPage(status: status),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Chụm/mở hai ngón hoặc bấm +/− để phóng to; bấm ⤢ để xem toàn màn hình.',
            style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 10),
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

/// Những gì vẽ lên bản đồ hành trình — tính một lần, dùng chung cho thẻ và màn toàn màn hình.
class DroneRouteView {
  const DroneRouteView({
    required this.a,
    required this.b,
    required this.drone,
    required this.flown,
    required this.position,
  });

  /// Tủ gửi (A) và tủ nhận (B).
  final LatLng a;
  final LatLng b;

  /// Vị trí drone trên bản đồ; null khi chưa cất cánh / đã tới / chặng lỗi.
  final LatLng? drone;

  /// Có vẽ đoạn đã bay (A → drone, hoặc cả A → B khi đã tới) không.
  final bool flown;

  /// Toạ độ đưa lên dòng chữ dưới bản đồ (xem [droneReportedPosition]).
  final ({LatLng point, String note, bool estimated})? position;

  double get headingDeg => DroneRouteMapCard._bearing(a, b);

  /// Khung bao A, B và drone — dùng cho lần mở đầu và nút "về toàn tuyến".
  CameraFit get fit => CameraFit.bounds(
    bounds: LatLngBounds.fromPoints([a, b, if (drone != null) drone!]),
    padding: const EdgeInsets.all(48),
    maxZoom: 17,
  );
}

/// Null khi tủ gửi hoặc tủ nhận chưa có toạ độ.
DroneRouteView? _routeView(WidgetRef ref, DroneDeliveryStatus status) {
  final source = status.sourceLocker;
  final destination = status.destinationLocker;
  if (source == null ||
      destination == null ||
      !source.hasCoordinates ||
      !destination.hasCoordinates) {
    return null;
  }
  final a = LatLng(source.latitude!, source.longitude!);
  final b = LatLng(destination.latitude!, destination.longitude!);
  final progress = DroneRouteMapCard._progress(status.stage);
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
  return DroneRouteView(
    a: a,
    b: b,
    drone: drone,
    flown: drone != null || DroneRouteMapCard._arrived(status.stage),
    position: position,
  );
}

/// Bản đồ A → B có nút phóng to / thu nhỏ / về toàn tuyến. Giữ nguyên mức zoom người dùng đã chọn
/// khi drone đổi vị trí (chỉ lần mở đầu mới tự canh khung).
class DroneRouteMap extends StatefulWidget {
  const DroneRouteMap({
    super.key,
    required this.view,
    required this.fullScreen,
    this.onExpand,
  });

  final DroneRouteView view;

  /// Toàn màn hình: kéo/zoom tự do. Trong thẻ: chỉ hai ngón / chạm đúp để trang vẫn cuộn được.
  final bool fullScreen;

  /// Nút ⤢ mở toàn màn hình (chỉ có trong thẻ).
  final VoidCallback? onExpand;

  static const double minZoom = 3;
  static const double maxZoom = 19;

  @override
  State<DroneRouteMap> createState() => _DroneRouteMapState();
}

class _DroneRouteMapState extends State<DroneRouteMap> {
  static const Color _sourceColor = Color(0xFF0F766E);
  static const Color _plannedColor = Color(0xFF94A3B8);

  final MapController _controller = MapController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _zoomBy(double delta) {
    final camera = _controller.camera;
    _controller.move(
      camera.center,
      (camera.zoom + delta).clamp(DroneRouteMap.minZoom, DroneRouteMap.maxZoom),
    );
  }

  @override
  Widget build(BuildContext context) {
    final view = widget.view;
    final drone = view.drone;
    return Stack(
      children: [
        FlutterMap(
          mapController: _controller,
          options: MapOptions(
            initialCameraFit: view.fit,
            minZoom: DroneRouteMap.minZoom,
            maxZoom: DroneRouteMap.maxZoom,
            interactionOptions: InteractionOptions(
              flags: widget.fullScreen
                  ? InteractiveFlag.all & ~InteractiveFlag.rotate
                  : InteractiveFlag.pinchZoom |
                        InteractiveFlag.pinchMove |
                        InteractiveFlag.doubleTapZoom,
            ),
          ),
          children: [
            droneBaseTileLayer(),
            PolylineLayer(
              polylines: [
                Polyline(
                  points: [view.a, view.b],
                  color: _plannedColor,
                  strokeWidth: 3,
                  pattern: StrokePattern.dashed(segments: const [10, 6]),
                ),
                if (view.flown)
                  Polyline(
                    points: [view.a, drone ?? view.b],
                    color: AISLShadcnTheme.navyAccent,
                    strokeWidth: 4,
                  ),
              ],
            ),
            MarkerLayer(
              markers: [
                Marker(
                  point: view.a,
                  width: 34,
                  height: 34,
                  child: const _PointMarker(label: 'A', color: _sourceColor),
                ),
                Marker(
                  point: view.b,
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
                    child: DroneMarker(headingDeg: view.headingDeg),
                  ),
              ],
            ),
          ],
        ),
        Positioned(
          right: 8,
          top: 8,
          child: Column(
            children: [
              _MapButton(
                key: const ValueKey('drone-route-zoom-in'),
                icon: LucideIcons.plus,
                tooltip: 'Phóng to',
                onPressed: () => _zoomBy(1),
              ),
              const SizedBox(height: 6),
              _MapButton(
                key: const ValueKey('drone-route-zoom-out'),
                icon: LucideIcons.minus,
                tooltip: 'Thu nhỏ',
                onPressed: () => _zoomBy(-1),
              ),
              const SizedBox(height: 6),
              _MapButton(
                key: const ValueKey('drone-route-fit'),
                icon: LucideIcons.route,
                tooltip: 'Xem cả tuyến',
                onPressed: () => _controller.fitCamera(view.fit),
              ),
              if (widget.onExpand != null) ...[
                const SizedBox(height: 6),
                _MapButton(
                  key: const ValueKey('drone-route-expand'),
                  icon: LucideIcons.maximize2,
                  tooltip: 'Toàn màn hình',
                  onPressed: widget.onExpand!,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// Bản đồ hành trình toàn màn hình: kéo, chụm hai ngón, chạm đúp tự do. Vị trí drone vẫn cập nhật trực tiếp.
class DroneRouteMapPage extends ConsumerWidget {
  const DroneRouteMapPage({super.key, required this.status});

  final DroneDeliveryStatus status;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final view = _routeView(ref, status);
    return Scaffold(
      appBar: AppBar(title: const Text('Bản đồ hành trình')),
      body: view == null
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Tủ gửi hoặc tủ nhận chưa có toạ độ nên chưa vẽ được bản đồ hành trình.',
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : SafeArea(
              top: false,
              child: DroneRouteMap(view: view, fullScreen: true),
            ),
    );
  }
}

class _MapButton extends StatelessWidget {
  const _MapButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Tooltip(
    message: tooltip,
    child: Material(
      color: Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onPressed,
        child: SizedBox(
          width: 36,
          height: 36,
          child: Icon(icon, size: 18, color: AISLShadcnTheme.navyPrimary),
        ),
      ),
    ),
  );
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
