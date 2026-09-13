import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:smart_laundry_locker/core/theme/shadcn_theme.dart';
import 'package:smart_laundry_locker/features/drone_delivery/data/drone_delivery_store.dart';
import 'package:smart_laundry_locker/features/drone_delivery/domain/entities/drone_order.dart';

class DroneTrackingPage extends StatefulWidget {
  const DroneTrackingPage({super.key, required this.orderId});

  final String orderId;

  @override
  State<DroneTrackingPage> createState() => _DroneTrackingPageState();
}

class _DroneTrackingPageState extends State<DroneTrackingPage>
    with TickerProviderStateMixin {
  final _mapController = MapController();
  StreamSubscription<({String orderId, DroneOrderStatus status})>? _sub;

  DroneOrder? _order;
  DroneOrderStatus _status = DroneOrderStatus.pending;

  // Simulation
  LatLng? _dronePos;
  LatLng? _destination;
  List<LatLng> _flightPath = [];
  int _pathStep = 0;
  Timer? _moveTimer;
  Timer? _phaseTimer;

  // Drone heading animation
  double _heading = 0;

  @override
  void initState() {
    super.initState();
    _order = DroneDeliveryStore.instance.orderById(widget.orderId);
    if (_order != null) {
      _dronePos = _order!.origin;
      _destination = _buildDestination(_order!.origin);
    }

    // Listen for dispatch signal from drone manager
    _sub = DroneDeliveryStore.instance.statusStream.listen((event) {
      if (event.orderId != widget.orderId) return;
      if (!mounted) return;
      setState(() => _status = event.status);
      if (event.status == DroneOrderStatus.dispatched) {
        _startSimulation();
      }
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    _moveTimer?.cancel();
    _phaseTimer?.cancel();
    super.dispose();
  }

  /// Simulate a destination ~1.5–3 km away from origin.
  LatLng _buildDestination(LatLng origin) {
    const offsetLat = 0.018; // ~2 km north
    const offsetLng = 0.012; // ~1.3 km east
    return LatLng(
      origin.latitude + offsetLat,
      origin.longitude + offsetLng,
    );
  }

  /// Build a series of positions from origin to destination (80 steps).
  List<LatLng> _buildPath(LatLng from, LatLng to) {
    const steps = 80;
    return List.generate(steps + 1, (i) {
      final t = i / steps;
      return LatLng(
        from.latitude + (to.latitude - from.latitude) * t,
        from.longitude + (to.longitude - from.longitude) * t,
      );
    });
  }

  void _startSimulation() {
    if (_order == null || _destination == null) return;

    setState(() => _status = DroneOrderStatus.dispatched);
    _flightPath = _buildPath(_order!.origin, _destination!);
    _pathStep = 0;

    // Phase 1: Takeoff visual (2s delay) then start moving
    _phaseTimer = Timer(const Duration(seconds: 2), () {
      if (!mounted) return;
      setState(() => _status = DroneOrderStatus.inFlight);
      _fitBounds(_order!.origin, _destination!);
      _startMoving();
    });
  }

  void _startMoving() {
    _moveTimer?.cancel();
    // 80 steps × 150ms = 12s total flight
    _moveTimer = Timer.periodic(const Duration(milliseconds: 150), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      if (_pathStep >= _flightPath.length - 1) {
        t.cancel();
        _onApproaching();
        return;
      }
      setState(() {
        _pathStep++;
        _dronePos = _flightPath[_pathStep];

        // Calculate heading towards next point
        if (_pathStep < _flightPath.length - 1) {
          final next = _flightPath[_pathStep + 1];
          _heading = _calcHeading(_dronePos!, next);
        }
      });
      // Re-center map on drone during flight
      _mapController.move(_dronePos!, _mapController.camera.zoom);
    });
  }

  void _onApproaching() {
    setState(() => _status = DroneOrderStatus.approaching);
    _phaseTimer = Timer(const Duration(seconds: 3), () {
      if (!mounted) return;
      setState(() => _status = DroneOrderStatus.arrived);
      _mapController.move(_destination!, 17);
      _phaseTimer = Timer(const Duration(seconds: 3), () {
        if (!mounted) return;
        setState(() => _status = DroneOrderStatus.delivered);
      });
    });
  }

  double _calcHeading(LatLng from, LatLng to) {
    final dLon = to.longitude - from.longitude;
    final dLat = to.latitude - from.latitude;
    final angle = math.atan2(dLon, dLat);
    return angle * 180 / math.pi;
  }

  void _fitBounds(LatLng a, LatLng b) {
    final bounds = LatLngBounds(
      LatLng(
        a.latitude < b.latitude ? a.latitude : b.latitude,
        a.longitude < b.longitude ? a.longitude : b.longitude,
      ),
      LatLng(
        a.latitude > b.latitude ? a.latitude : b.latitude,
        a.longitude > b.longitude ? a.longitude : b.longitude,
      ),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _mapController.fitCamera(
        CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(60)),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final order = _order;
    final topPad = MediaQuery.of(context).padding.top;
    final botPad = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      body: Stack(
        children: [
          // ── Full-screen map ───────────────────────────────────────────────
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _dronePos ?? const LatLng(10.762622, 106.660172),
              initialZoom: 15,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.aisl.app',
              ),

              // Flight path polyline
              if (_flightPath.isNotEmpty)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: _flightPath,
                      color: const Color(0xFF6366F1).withValues(alpha: 0.4),
                      strokeWidth: 3,
                      pattern: const StrokePattern.dotted(),
                    ),
                    if (_pathStep > 0)
                      Polyline(
                        points: _flightPath.sublist(0, _pathStep + 1),
                        color: const Color(0xFF6366F1),
                        strokeWidth: 4,
                      ),
                  ],
                ),

              MarkerLayer(
                markers: [
                  // Origin: locker
                  if (order != null)
                    Marker(
                      point: order.origin,
                      width: 44,
                      height: 44,
                      child: Container(
                        decoration: BoxDecoration(
                          color: AISLShadcnTheme.navyPrimary,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(
                          Icons.lock_outline,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),

                  // Destination marker
                  if (_destination != null &&
                      _status != DroneOrderStatus.pending)
                    Marker(
                      point: _destination!,
                      width: 44,
                      height: 44,
                      child: const Icon(
                        Icons.location_on,
                        color: Colors.red,
                        size: 40,
                      ),
                    ),

                  // Drone marker (animated)
                  if (_dronePos != null &&
                      _status != DroneOrderStatus.pending &&
                      _status != DroneOrderStatus.delivered)
                    Marker(
                      point: _dronePos!,
                      width: 50,
                      height: 50,
                      child: Transform.rotate(
                        angle: _heading * math.pi / 180,
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF6366F1),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2.5),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF6366F1).withValues(
                                  alpha: 0.5,
                                ),
                                blurRadius: 12,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.flight,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                      ),
                    ),

                  // "Landed" marker when delivered
                  if (_destination != null &&
                      _status == DroneOrderStatus.delivered)
                    Marker(
                      point: _destination!,
                      width: 50,
                      height: 50,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2.5),
                        ),
                        child: const Icon(
                          Icons.check,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),

          // ── Top bar ───────────────────────────────────────────────────────
          Positioned(
            top: topPad + 10,
            left: 12,
            right: 12,
            child: Row(
              children: [
                _CircleButton(
                  onTap: () => Navigator.maybePop(context),
                  child: const Icon(
                    Icons.arrow_back_rounded,
                    color: AISLShadcnTheme.navyPrimary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x22000000),
                          blurRadius: 10,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.flight,
                          color: Color(0xFF6366F1),
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Theo dõi Drone · ${order?.lockerName ?? ''}',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AISLShadcnTheme.navyPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Status chip (floating) ─────────────────────────────────────
          if (_status == DroneOrderStatus.inFlight)
            Positioned(
              top: topPad + 66,
              left: 0,
              right: 0,
              child: Center(
                child: _StatusChip(status: _status),
              ),
            ),

          // ── Bottom card ───────────────────────────────────────────────────
          Align(
            alignment: Alignment.bottomCenter,
            child: _buildBottomCard(order, botPad),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomCard(DroneOrder? order, double botPad) {
    return Container(
      margin: EdgeInsets.fromLTRB(12, 0, 12, 12 + botPad),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A000000),
            blurRadius: 20,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Order header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEF2FF),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.flight,
                    color: Color(0xFF6366F1),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        order?.lockerName ?? '',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      Text(
                        'Ô #${order?.boxNumber ?? ''} · ${_shortId(order?.id)}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                _StatusBadge(status: _status),
              ],
            ),
          ),

          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Divider(height: 1),
          ),

          // Timeline
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
            child: _DroneTimeline(currentStatus: _status),
          ),
        ],
      ),
    );
  }

  String _shortId(String? id) {
    if (id == null) return '';
    return id.length > 12 ? '#${id.substring(id.length - 8)}' : '#$id';
  }
}

// ── Status chip shown while flying ────────────────────────────────────────────

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});
  final DroneOrderStatus status;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Color(0xFF6366F1),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            status.label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF6366F1),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Status badge (small pill) ─────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});
  final DroneOrderStatus status;

  Color get _color {
    switch (status) {
      case DroneOrderStatus.pending:
        return Colors.grey;
      case DroneOrderStatus.dispatched:
        return const Color(0xFF1E5A8A);
      case DroneOrderStatus.inFlight:
        return const Color(0xFF6366F1);
      case DroneOrderStatus.approaching:
        return const Color(0xFFD97706);
      case DroneOrderStatus.arrived:
        return const Color(0xFF4F46E5);
      case DroneOrderStatus.delivered:
        return Colors.green;
      case DroneOrderStatus.failed:
        return Colors.red;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _color.withValues(alpha: 0.4)),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: _color,
        ),
      ),
    );
  }
}

// ── Timeline widget ───────────────────────────────────────────────────────────

class _DroneTimeline extends StatelessWidget {
  const _DroneTimeline({required this.currentStatus});
  final DroneOrderStatus currentStatus;

  static const _phases = [
    DroneOrderStatus.pending,
    DroneOrderStatus.dispatched,
    DroneOrderStatus.inFlight,
    DroneOrderStatus.approaching,
    DroneOrderStatus.arrived,
    DroneOrderStatus.delivered,
  ];

  @override
  Widget build(BuildContext context) {
    final currentIdx = _phases.indexOf(currentStatus);

    return Column(
      children: List.generate(_phases.length, (i) {
        final phase = _phases[i];
        final isDone = i < currentIdx;
        final isCurrent = i == currentIdx;
        final isLast = i == _phases.length - 1;

        final Color dotColor;
        final Widget dotContent;
        if (isDone) {
          dotColor = Colors.green;
          dotContent = const Icon(Icons.check, color: Colors.white, size: 12);
        } else if (isCurrent) {
          dotColor = const Color(0xFF6366F1);
          dotContent = const SizedBox(
            width: 10,
            height: 10,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.white,
            ),
          );
        } else {
          dotColor = Colors.grey.shade300;
          dotContent = const SizedBox.shrink();
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Dot + line column
            SizedBox(
              width: 24,
              child: Column(
                children: [
                  Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: dotColor,
                      shape: BoxShape.circle,
                    ),
                    child: Center(child: dotContent),
                  ),
                  if (!isLast)
                    Container(
                      width: 2,
                      height: 20,
                      color: i < currentIdx
                          ? Colors.green.shade300
                          : Colors.grey.shade200,
                    ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(bottom: isLast ? 0 : 8),
                child: Text(
                  phase.label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight:
                        isCurrent ? FontWeight.bold : FontWeight.normal,
                    color: isCurrent
                        ? const Color(0xFF6366F1)
                        : (isDone ? Colors.black87 : Colors.grey),
                  ),
                ),
              ),
            ),
          ],
        );
      }),
    );
  }
}

// ── Helper: circle button ─────────────────────────────────────────────────────

class _CircleButton extends StatelessWidget {
  const _CircleButton({required this.onTap, required this.child});
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: const [
            BoxShadow(
              color: Color(0x22000000),
              blurRadius: 10,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Center(child: child),
      ),
    );
  }
}
