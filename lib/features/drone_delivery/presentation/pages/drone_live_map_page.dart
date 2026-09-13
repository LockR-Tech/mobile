import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:smart_laundry_locker/core/routing/app_router.dart';
import 'package:smart_laundry_locker/core/theme/shadcn_theme.dart';
import 'package:smart_laundry_locker/features/drone_delivery/domain/entities/drone_position_snapshot.dart';
import 'package:smart_laundry_locker/features/drone_delivery/presentation/providers/drone_live_map_providers.dart';
import 'package:smart_laundry_locker/features/drone_delivery/presentation/widgets/drone_marker.dart';

/// Live map theo dõi drone real-time cho NGƯỜI NHẬN (Phase 2).
///
/// On-demand: subscribe STOMP khi mở (qua `dronePositionStreamProvider`),
/// unsubscribe khi rời (autoDispose). Marker interpolate mượt giữa 2 snapshot;
/// mất tín hiệu >10s thì đóng băng marker + banner.
class DroneLiveMapPage extends ConsumerStatefulWidget {
  final String orderId;

  const DroneLiveMapPage({super.key, required this.orderId});

  @override
  ConsumerState<DroneLiveMapPage> createState() => _DroneLiveMapPageState();
}

class _DroneLiveMapPageState extends ConsumerState<DroneLiveMapPage>
    with SingleTickerProviderStateMixin {
  /// Khoảng interpolate giữa 2 snapshot (khớp nhịp downsample ~1–2s của backend).
  static const Duration _tweenDuration = Duration(milliseconds: 1500);

  /// Coi là mất tín hiệu nếu quá ngưỡng này không có snapshot mới.
  static const Duration _signalTimeout = Duration(seconds: 10);

  /// Tâm mặc định khi chưa có fix nào (TP.HCM) để map render được.
  static const LatLng _defaultCenter = LatLng(10.7769, 106.7009);

  final MapController _mapController = MapController();
  late final AnimationController _anim;
  Timer? _watchdog;

  LatLng? _from;
  LatLng? _to;
  double _fromHeading = 0;
  double _toHeading = 0;

  DronePositionSnapshot? _latest;
  DateTime? _lastSnapshotAt;
  bool _signalLost = false;
  bool _firstFix = false;
  bool _followDrone = true;
  final List<LatLng> _trail = [];

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(vsync: this, duration: _tweenDuration)
      ..addListener(() => setState(() {}));
    _watchdog = Timer.periodic(const Duration(seconds: 1), (_) => _checkSignal());
  }

  @override
  void dispose() {
    _anim.dispose();
    _watchdog?.cancel();
    super.dispose();
  }

  void _checkSignal() {
    final last = _lastSnapshotAt;
    if (last == null || _signalLost) return;
    if (DateTime.now().difference(last) > _signalTimeout) {
      // Đóng băng marker tại vị trí hiện tại, gắn nhãn — không để trôi vô định.
      _anim.stop();
      setState(() => _signalLost = true);
    }
  }

  void _applySnapshot(DronePositionSnapshot snap) {
    final target = LatLng(snap.lat, snap.lng);
    _latest = snap;
    _lastSnapshotAt = DateTime.now();
    _signalLost = false;

    if (!_firstFix) {
      _from = target;
      _to = target;
      _fromHeading = snap.headingDeg;
      _toHeading = snap.headingDeg;
      _firstFix = true;
      _trail.add(target);
      _moveCamera(target);
      setState(() {});
      return;
    }

    // Bắt đầu tween từ vị trí ĐANG interpolate (mượt kể cả khi snapshot tới giữa
    // chừng) tới target mới.
    _from = _currentLatLng();
    _fromHeading = _currentHeading();
    _to = target;
    _toHeading = snap.headingDeg;

    _trail.add(target);
    if (_trail.length > 500) _trail.removeAt(0);

    if (_followDrone) _moveCamera(target);
    _anim.forward(from: 0);
  }

  void _moveCamera(LatLng target) {
    final zoom = _firstFix ? _mapController.camera.zoom : 16.0;
    _mapController.move(target, zoom);
  }

  LatLng _currentLatLng() {
    final from = _from;
    final to = _to;
    if (from == null || to == null) return to ?? from ?? _defaultCenter;
    final t = Curves.easeOut.transform(_anim.value.clamp(0.0, 1.0));
    // latlong2 không có LatLng.lerp; nội suy tuyến tính (khoảng cách giao hàng
    // nhỏ nên đủ chính xác, không lo antimeridian).
    return LatLng(
      from.latitude + (to.latitude - from.latitude) * t,
      from.longitude + (to.longitude - from.longitude) * t,
    );
  }

  double _currentHeading() =>
      _lerpAngle(_fromHeading, _toHeading, _anim.value.clamp(0.0, 1.0));

  /// Nội suy góc theo cung NGẮN NHẤT (xử lý wrap 350°→10°).
  static double _lerpAngle(double a, double b, double t) {
    var diff = (b - a) % 360;
    if (diff > 180) diff -= 360;
    if (diff < -180) diff += 360;
    return a + diff * t;
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(dronePositionStreamProvider(widget.orderId));
    // Áp snapshot mới vào cơ chế interpolate (tách khỏi rebuild của watch).
    ref.listen<AsyncValue<DronePositionSnapshot>>(
      dronePositionStreamProvider(widget.orderId),
      (previous, next) {
        final snap = next.value;
        if (snap != null) _applySnapshot(snap);
      },
    );

    final pos = _currentLatLng();

    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _to ?? _defaultCenter,
              initialZoom: 16,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.aisl.app',
              ),
              if (_trail.length > 1)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: _trail,
                      color: AISLShadcnTheme.navyAccent,
                      strokeWidth: 4,
                    ),
                  ],
                ),
              if (_firstFix)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: pos,
                      width: 44,
                      height: 44,
                      child: DroneMarker(
                        headingDeg: _currentHeading(),
                        signalLost: _signalLost,
                      ),
                    ),
                  ],
                ),
            ],
          ),

          _TopBar(orderId: widget.orderId),

          if (_signalLost && _lastSnapshotAt != null)
            _SignalLostBanner(at: _lastSnapshotAt!),

          // Trạng thái kết nối trước fix đầu tiên / lỗi.
          if (!_firstFix)
            _ConnectingOverlay(
              error: async.hasError ? async.error.toString() : null,
            ),

          Positioned(
            right: 12,
            bottom: 160,
            child: _MapFab(
              icon: _followDrone ? LucideIcons.locateFixed : LucideIcons.locate,
              onTap: () {
                setState(() => _followDrone = !_followDrone);
                if (_followDrone && _latest != null) {
                  _moveCamera(LatLng(_latest!.lat, _latest!.lng));
                }
              },
            ),
          ),

          if (_latest != null) _BottomStatusCard(snapshot: _latest!),
        ],
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  final String orderId;
  const _TopBar({required this.orderId});

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    return Positioned(
      top: topPad + 8,
      left: 12,
      right: 12,
      child: Row(
        children: [
          _CircleButton(
            icon: LucideIcons.arrowLeft,
            onTap: () {
              if (context.canPop()) {
                context.pop();
              } else {
                // Quay lại timeline Phase 1 theo orderId.
                context.go(AppRouter.droneDeliveryTracking, extra: orderId);
              }
            },
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 8,
                ),
              ],
            ),
            child: const Text(
              'Theo dõi drone',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: AISLShadcnTheme.navyPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SignalLostBanner extends StatelessWidget {
  final DateTime at;
  const _SignalLostBanner({required this.at});

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    final hh = at.hour.toString().padLeft(2, '0');
    final mm = at.minute.toString().padLeft(2, '0');
    return Positioned(
      top: topPad + 60,
      left: 12,
      right: 12,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFF59E0B).withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(LucideIcons.wifiOff, color: Colors.white, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Mất tín hiệu · vị trí lúc $hh:$mm',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ConnectingOverlay extends StatelessWidget {
  final String? error;
  const _ConnectingOverlay({this.error});

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Container(
        color: Colors.white.withValues(alpha: 0.85),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (error == null) ...[
                const CircularProgressIndicator(
                  color: AISLShadcnTheme.navyPrimary,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Đang kết nối tới drone...',
                  style: TextStyle(
                    color: AISLShadcnTheme.navyPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ] else ...[
                const Icon(
                  LucideIcons.circleAlert,
                  color: Color(0xFFDC2626),
                  size: 48,
                ),
                const SizedBox(height: 12),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 40),
                  child: Text(
                    'Chưa nhận được vị trí drone. Đang thử lại...',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.black54),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _BottomStatusCard extends StatelessWidget {
  final DronePositionSnapshot snapshot;
  const _BottomStatusCard({required this.snapshot});

  @override
  Widget build(BuildContext context) {
    final stage = snapshot.stage;
    final eta = snapshot.etaMinutes;
    return Positioned(
      left: 12,
      right: 12,
      bottom: MediaQuery.of(context).padding.bottom + 16,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: stage.color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(stage.icon, color: stage.color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    stage.title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AISLShadcnTheme.navyPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    eta != null ? 'Còn khoảng $eta phút' : 'Đang trên đường tới bạn',
                    style: TextStyle(color: Colors.grey[600], fontSize: 13),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _CircleButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      elevation: 3,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Icon(icon, color: AISLShadcnTheme.navyPrimary, size: 22),
        ),
      ),
    );
  }
}

class _MapFab extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _MapFab({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      elevation: 3,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Icon(icon, color: AISLShadcnTheme.navyPrimary, size: 22),
        ),
      ),
    );
  }
}
