import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:smart_laundry_locker/core/routing/app_router.dart';
import 'package:smart_laundry_locker/core/theme/shadcn_theme.dart';
import 'package:smart_laundry_locker/features/drone_delivery/domain/entities/drone_labels.dart';
import 'package:smart_laundry_locker/features/drone_delivery/domain/entities/drone_position_snapshot.dart';
import 'package:smart_laundry_locker/features/drone_delivery/domain/entities/drone_route_geometry.dart';
import 'package:smart_laundry_locker/features/drone_delivery/presentation/providers/drone_delivery_providers.dart';
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

  /// Tủ nhận — đích để tính quãng đường còn lại và giờ tới nơi.
  LatLng? _destination;

  /// Tốc độ mặt đất (m/s): backend gửi thì dùng, không thì tự đo giữa hai snapshot
  /// và làm mượt để ETA không nhảy loạn theo từng điểm GPS.
  double? _speedMps;

  /// Giờ dự kiến tới tủ nhận, tính lại mỗi snapshot; đồng hồ đếm ngược chạy theo giây.
  DateTime? _arrivalAt;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(vsync: this, duration: _tweenDuration)
      ..addListener(() => setState(() {}));
    _watchdog = Timer.periodic(const Duration(seconds: 1), (_) {
      _checkSignal();
      // Đếm ngược giờ tới nơi theo từng giây giữa hai snapshot.
      if (mounted && _arrivalAt != null) setState(() {});
    });
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
    _updateSpeed(_latest, snap);
    _latest = snap;
    _lastSnapshotAt = DateTime.now();
    _signalLost = false;
    _updateArrival(snap);

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

  void _updateSpeed(DronePositionSnapshot? previous, DronePositionSnapshot current) {
    final reported = current.speedMps;
    if (reported != null && reported > 0) {
      _speedMps = reported;
      return;
    }
    if (previous == null) return;
    final seconds =
        current.timestamp.difference(previous.timestamp).inMilliseconds / 1000;
    if (seconds <= 0) return;
    final meters =
        droneDistanceKm(previous.lat, previous.lng, current.lat, current.lng) * 1000;
    final measured = meters / seconds;
    // Trung bình trượt: 30% điểm mới, 70% lịch sử.
    _speedMps = _speedMps == null ? measured : _speedMps! * 0.7 + measured * 0.3;
  }

  void _updateArrival(DronePositionSnapshot snap) {
    final remaining = _remainingKm(LatLng(snap.lat, snap.lng));
    final speed = _speedMps;
    if (remaining != null && speed != null && speed > 0.5) {
      _arrivalAt = DateTime.now().add(
        Duration(seconds: (remaining * 1000 / speed).round()),
      );
    } else if (snap.etaMinutes != null) {
      // Chưa đo được tốc độ: dùng ước lượng theo chặng của backend.
      _arrivalAt = DateTime.now().add(Duration(minutes: snap.etaMinutes!));
    } else {
      _arrivalAt = null;
    }
  }

  double? _remainingKm(LatLng from) {
    final destination = _destination;
    if (destination == null) return null;
    return droneDistanceKm(
      from.latitude,
      from.longitude,
      destination.latitude,
      destination.longitude,
    );
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

    // Toạ độ tủ gửi/tủ nhận lấy từ read model hành trình (cùng provider màn timeline).
    final route = ref.watch(droneDeliveryStatusProvider(widget.orderId)).value;
    final source = route?.sourceLocker;
    final destination = route?.destinationLocker;
    final sourcePoint = source != null && source.hasCoordinates
        ? LatLng(source.latitude!, source.longitude!)
        : null;
    _destination = destination != null && destination.hasCoordinates
        ? LatLng(destination.latitude!, destination.longitude!)
        : null;

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
              if (sourcePoint != null && _destination != null)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: [sourcePoint, _destination!],
                      color: const Color(0xFF94A3B8),
                      strokeWidth: 3,
                      pattern: StrokePattern.dashed(segments: const [10, 6]),
                    ),
                  ],
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
              MarkerLayer(
                markers: [
                  if (sourcePoint != null)
                    Marker(
                      point: sourcePoint,
                      width: 32,
                      height: 32,
                      child: const _LockerPin(label: 'A', color: Color(0xFF0F766E)),
                    ),
                  if (_destination != null)
                    Marker(
                      point: _destination!,
                      width: 32,
                      height: 32,
                      child: const _LockerPin(
                        label: 'B',
                        color: AISLShadcnTheme.navyPrimary,
                      ),
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
            bottom: MediaQuery.of(context).padding.bottom + 250,
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

          if (_latest != null)
            _BottomStatusCard(
              snapshot: _latest!,
              remainingKm: _remainingKm(pos),
              arrivalAt: _arrivalAt,
              speedMps: _speedMps,
            ),
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

class _LockerPin extends StatelessWidget {
  final String label;
  final Color color;
  const _LockerPin({required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: color,
      shape: BoxShape.circle,
      border: Border.all(color: Colors.white, width: 2.5),
    ),
    child: Text(
      label,
      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
    ),
  );
}

class _BottomStatusCard extends StatelessWidget {
  final DronePositionSnapshot snapshot;
  final double? remainingKm;
  final DateTime? arrivalAt;
  final double? speedMps;

  const _BottomStatusCard({
    required this.snapshot,
    this.remainingKm,
    this.arrivalAt,
    this.speedMps,
  });

  String get _subtitle {
    final at = arrivalAt;
    if (at == null) return 'Đang trên đường tới tủ nhận';
    final left = at.difference(DateTime.now());
    if (left.inSeconds <= 0) return 'Sắp tới nơi';
    return 'Còn ${droneDurationLabel(left)}';
  }

  @override
  Widget build(BuildContext context) {
    final stage = snapshot.stage;
    final at = arrivalAt;
    final speed = speedMps;
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
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
                        _subtitle,
                        style: TextStyle(color: Colors.grey[600], fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                _Metric(
                  label: 'Dự kiến đến',
                  value: at == null
                      ? '—'
                      : '${at.hour.toString().padLeft(2, '0')}:'
                            '${at.minute.toString().padLeft(2, '0')}:'
                            '${at.second.toString().padLeft(2, '0')}',
                ),
                _Metric(
                  label: 'Còn lại',
                  value: remainingKm == null ? '—' : droneKmLabel(remainingKm!),
                ),
                _Metric(
                  label: 'Tốc độ',
                  value: speed == null
                      ? '—'
                      : '${(speed * 3.6).toStringAsFixed(1).replaceAll('.', ',')} km/h',
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(
                  LucideIcons.mapPin,
                  size: 14,
                  color: Color(0xFF64748B),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Vĩ độ, kinh độ: '
                    '${droneCoordinateLabel(snapshot.lat, snapshot.lng)}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF475569),
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  final String label;
  final String value;
  const _Metric({required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Expanded(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: AISLShadcnTheme.navyPrimary,
          ),
        ),
      ],
    ),
  );
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
