import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/shadcn_theme.dart';
import '../domain/drone_telemetry.dart';
import 'flight_data_controller.dart';
import 'widgets/attitude_indicator.dart';

/// Flight Data — live MAVLink telemetry & control (Mảng 2). Connects to a real
/// ArduPilot/PX4 flight controller (or SITL) over UDP/TCP, shows the drone live
/// on the map with a HUD, and issues commands.
class FlightDataPage extends StatefulWidget {
  const FlightDataPage({super.key});

  @override
  State<FlightDataPage> createState() => _FlightDataPageState();
}

class _FlightDataPageState extends State<FlightDataPage> {
  final FlightDataController _controller = FlightDataController();
  final MapController _map = MapController();
  LatLng? _lastCentered;
  bool _mapReady = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_follow);
  }

  @override
  void dispose() {
    _controller.removeListener(_follow);
    _controller.dispose();
    super.dispose();
  }

  void _follow() {
    if (!_mapReady) return; // MapController unusable until the map has rendered
    final pos = _controller.telemetry.position;
    if (pos == null) return;
    if (_lastCentered == null ||
        const Distance().as(LengthUnit.Meter, _lastCentered!, pos) > 1) {
      _lastCentered = pos;
      _map.move(pos, _map.camera.zoom);
    }
  }

  // ── connect sheet ──────────────────────────────────────────────────────────

  Future<void> _openConnectSheet() async {
    var transport = MavTransport.udp;
    final hostCtrl = TextEditingController();
    final portCtrl = TextEditingController(text: '14550');
    final localCtrl = TextEditingController(text: '14550');

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheet) {
            final bottom = MediaQuery.of(ctx).viewInsets.bottom +
                MediaQuery.of(ctx).padding.bottom;
            final isUdp = transport == MavTransport.udp;
            return Padding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottom),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Kết nối flight controller',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AISLShadcnTheme.navyPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'MAVLink qua UDP/TCP — tương thích ArduPilot/PX4 thật và SITL.',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 14),
                  SegmentedButton<MavTransport>(
                    segments: const [
                      ButtonSegment(value: MavTransport.udp, label: Text('UDP')),
                      ButtonSegment(value: MavTransport.tcp, label: Text('TCP')),
                    ],
                    selected: {transport},
                    onSelectionChanged: (s) => setSheet(() {
                      transport = s.first;
                      if (transport == MavTransport.tcp) {
                        if (hostCtrl.text.isEmpty) hostCtrl.text = '127.0.0.1';
                        portCtrl.text = '5760';
                      } else {
                        portCtrl.text = '14550';
                      }
                    }),
                  ),
                  const SizedBox(height: 14),
                  _field(
                    label: isUdp
                        ? 'Địa chỉ drone (để trống = chờ drone gửi tới)'
                        : 'Địa chỉ drone',
                    controller: hostCtrl,
                    hint: isUdp ? '192.168.4.1 hoặc trống' : '127.0.0.1',
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _field(
                          label: 'Cổng',
                          controller: portCtrl,
                          number: true,
                        ),
                      ),
                      if (isUdp) ...[
                        const SizedBox(width: 12),
                        Expanded(
                          child: _field(
                            label: 'Cổng local',
                            controller: localCtrl,
                            number: true,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: AISLShadcnTheme.navyPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      icon: const Icon(LucideIcons.plugZap, size: 18),
                      label: const Text('Kết nối'),
                      onPressed: () {
                        Navigator.pop(ctx);
                        _controller.connect(
                          transport: transport,
                          host: hostCtrl.text,
                          port: int.tryParse(portCtrl.text.trim()) ?? 14550,
                          localPort: int.tryParse(localCtrl.text.trim()) ?? 14550,
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ── build ───────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    return Scaffold(
      backgroundColor: const Color(0xFF0B1220),
      body: ListenableBuilder(
        listenable: _controller,
        builder: (context, _) {
          final t = _controller.telemetry;
          return Stack(
            children: [
              FlutterMap(
                mapController: _map,
                options: MapOptions(
                  initialCenter: const LatLng(10.762622, 106.660172),
                  initialZoom: 17,
                  onMapReady: () => _mapReady = true,
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.aisl.app',
                  ),
                  if (_controller.trail.length > 1)
                    PolylineLayer(
                      polylines: [
                        Polyline(
                          points: _controller.trail,
                          color: const Color(0xFFFFC107),
                          strokeWidth: 3,
                        ),
                      ],
                    ),
                  if (t.position != null)
                    MarkerLayer(markers: [_droneMarker(t)]),
                ],
              ),
              _topBar(topPad, t),
              _hudPanel(topPad, t),
              Align(alignment: Alignment.bottomCenter, child: _commandBar(t)),
            ],
          );
        },
      ),
    );
  }

  Marker _droneMarker(DroneTelemetry t) {
    final headingRad = (t.headingDeg ?? 0) * math.pi / 180;
    return Marker(
      point: t.position!,
      width: 46,
      height: 46,
      child: Transform.rotate(
        angle: headingRad,
        child: Container(
          decoration: BoxDecoration(
            color: (t.armed ? const Color(0xFFEF4444) : const Color(0xFF16A34A))
                .withValues(alpha: 0.18),
            shape: BoxShape.circle,
          ),
          child: Icon(
            LucideIcons.navigation2,
            color: t.armed ? const Color(0xFFEF4444) : const Color(0xFF16A34A),
            size: 30,
          ),
        ),
      ),
    );
  }

  Widget _topBar(double topPad, DroneTelemetry t) {
    final status = _controller.status;
    final (label, color) = switch (status) {
      LinkStatus.connected =>
        t.linkAlive ? ('Đang nhận telemetry', const Color(0xFF16A34A)) : ('Đã nối · chờ dữ liệu', const Color(0xFFF59E0B)),
      LinkStatus.connecting => ('Đang kết nối...', const Color(0xFFF59E0B)),
      LinkStatus.error => (_controller.error ?? 'Lỗi kết nối', const Color(0xFFEF4444)),
      LinkStatus.disconnected => ('Chưa kết nối', const Color(0xFF64748B)),
    };
    return Positioned(
      top: topPad + 10,
      left: 12,
      right: 12,
      child: Row(
        children: [
          _fab(Icons.arrow_back_rounded, () => Navigator.maybePop(context)),
          const SizedBox(width: 10),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF111A2E),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white12),
              ),
              child: Row(
                children: [
                  Container(width: 9, height: 9, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      label,
                      style: const TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          if (_controller.isConnected)
            _fab(LucideIcons.plugZap, _controller.disconnect, danger: true)
          else
            _fab(LucideIcons.plug, _openConnectSheet),
        ],
      ),
    );
  }

  Widget _hudPanel(double topPad, DroneTelemetry t) {
    return Positioned(
      top: topPad + 64,
      left: 12,
      child: Container(
        width: 168,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: const Color(0xCC0B1220),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(child: AttitudeIndicator(roll: t.roll, pitch: t.pitch, size: 140)),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _chip(t.armed ? 'ARMED' : 'DISARMED',
                    t.armed ? const Color(0xFFEF4444) : const Color(0xFF16A34A)),
                _chip(t.modeName, AISLShadcnTheme.navyAccent),
              ],
            ),
            const SizedBox(height: 8),
            _readout('Cao (rel)', _fmt(t.altRelative, 'm')),
            _readout('Tốc độ đất', _fmt(t.groundspeed, 'm/s')),
            _readout('Leo/xuống', _fmt(t.climb, 'm/s')),
            _readout('Hướng', t.headingDeg == null ? '—' : '${t.headingDeg!.round()}°'),
            _readout('Pin', t.batteryVolts == null
                ? '—'
                : '${t.batteryVolts!.toStringAsFixed(1)}V'
                    '${t.batteryPercent == null ? '' : ' · ${t.batteryPercent}%'}'),
            _readout('GPS', '${t.gpsFixLabel}${t.satellites == null ? '' : ' · ${t.satellites} sat'}'),
          ],
        ),
      ),
    );
  }

  Widget _commandBar(DroneTelemetry t) {
    final enabled = _controller.isConnected;
    final bottomPad = MediaQuery.of(context).padding.bottom;
    return Container(
      margin: EdgeInsets.fromLTRB(12, 0, 12, 12 + bottomPad),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xCC0B1220),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        alignment: WrapAlignment.center,
        children: [
          if (t.armed)
            _cmd('DISARM', LucideIcons.power, const Color(0xFFEF4444),
                enabled ? () => _confirmCmd('Disarm động cơ?', _controller.disarm) : null)
          else
            _cmd('ARM', LucideIcons.power, const Color(0xFF16A34A),
                enabled ? () => _confirmCmd('Arm động cơ? Cánh quạt sẽ quay.', _controller.arm) : null),
          _cmd('RTL', LucideIcons.undo2, AISLShadcnTheme.navyAccent,
              enabled ? () => _confirmCmd('Về điểm xuất phát (RTL)?', _controller.returnToLaunch) : null),
          _cmd('LOITER', LucideIcons.locateFixed, AISLShadcnTheme.navyAccent,
              enabled ? _controller.loiter : null),
          _cmd('GUIDED', LucideIcons.gamepad2, AISLShadcnTheme.navyAccent,
              enabled ? _controller.guided : null),
          _cmd('AUTO', LucideIcons.play, AISLShadcnTheme.navyAccent,
              enabled ? () => _confirmCmd('Chạy mission (AUTO)?', _controller.startMission) : null),
          _cmd('TAKEOFF', LucideIcons.planeTakeoff, const Color(0xFFF59E0B),
              enabled ? _takeoffDialog : null),
        ],
      ),
    );
  }

  // ── small UI helpers ───────────────────────────────────────────────────────

  Future<void> _takeoffDialog() async {
    final ctrl = TextEditingController(text: '10');
    final alt = await showDialog<double>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cất cánh (GUIDED)'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Drone phải ở chế độ GUIDED và đã ARM. Nhập độ cao (m):'),
            const SizedBox(height: 10),
            TextField(
              controller: ctrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
              decoration: const InputDecoration(suffixText: 'm'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Huỷ')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, double.tryParse(ctrl.text.trim())),
            child: const Text('Cất cánh'),
          ),
        ],
      ),
    );
    if (alt != null && alt > 0) _controller.takeoff(alt);
  }

  Future<void> _confirmCmd(String message, VoidCallback action) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        content: Text(message),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Huỷ')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Gửi lệnh')),
        ],
      ),
    );
    if (ok ?? false) action();
  }

  Widget _field({
    required String label,
    required TextEditingController controller,
    String? hint,
    bool number = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: number ? TextInputType.number : TextInputType.text,
          inputFormatters:
              number ? [FilteringTextInputFormatter.digitsOnly] : null,
          decoration: InputDecoration(
            isDense: true,
            hintText: hint,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ],
    );
  }

  Widget _readout(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white54, fontSize: 11)),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  Widget _chip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(text,
          style: TextStyle(color: color, fontSize: 10.5, fontWeight: FontWeight.w800)),
    );
  }

  Widget _cmd(String label, IconData icon, Color color, VoidCallback? onTap) {
    final on = onTap != null;
    return Opacity(
      opacity: on ? 1 : 0.4,
      child: Material(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 16, color: color),
                const SizedBox(width: 6),
                Text(label,
                    style: TextStyle(color: color, fontSize: 12.5, fontWeight: FontWeight.w800)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _fab(IconData icon, VoidCallback onTap, {bool danger = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: const Color(0xFF111A2E),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white12),
        ),
        child: Icon(icon,
            color: danger ? const Color(0xFFEF4444) : Colors.white, size: 20),
      ),
    );
  }

  String _fmt(double? v, String unit) =>
      v == null ? '—' : '${v.toStringAsFixed(1)} $unit';
}
