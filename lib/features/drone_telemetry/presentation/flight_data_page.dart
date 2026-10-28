import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/services/token_service.dart';
import '../../../core/theme/shadcn_theme.dart';
import '../../locker_ops/data/drone_technician_errors.dart';
import '../../locker_ops/data/locker_ops_service.dart';
import '../domain/drone_telemetry.dart';
import '../domain/flight_command_policy.dart';
import 'flight_data_controller.dart';
import 'widgets/attitude_indicator.dart';
import 'package:smart_laundry_locker/features/drone_delivery/presentation/widgets/drone_base_tile_layer.dart';

/// Flight Data — live MAVLink telemetry & control (Mảng 2). Connects to a real
/// ArduPilot/PX4 flight controller (or SITL) over UDP/TCP, shows the drone live
/// on the map with a HUD, and issues commands.
///
/// Chốt an toàn: chỉ dùng với SITL hoặc kênh điều khiển riêng (hệ thống không
/// điều khiển drone); lệnh chỉ bật sau heartbeat đầu tiên và khi biết địa chỉ
/// drone; mọi lệnh phải xác nhận; cất cánh có trần độ cao; hiện kết quả
/// COMMAND_ACK; drone mình phụ trách đang giao hàng thì khoá lệnh.
class FlightDataPage extends StatefulWidget {
  const FlightDataPage({super.key, this.service, this.controller});

  /// Dùng để kiểm tra drone mình phụ trách có đang làm nhiệm vụ giao hàng.
  final LockerOpsService? service;

  /// Cho phép kiểm thử với controller giả lập.
  final FlightDataController? controller;

  @override
  State<FlightDataPage> createState() => _FlightDataPageState();
}

/// Chặng còn nhiệm vụ giao hàng đang chạy (drone đã gán cho đơn).
const _activeMissionStages = {
  'ACCEPTED',
  'LAUNCHING',
  'DEPARTED',
  'EN_ROUTE',
  'APPROACHING',
  'ARRIVED',
};

class _FlightDataPageState extends State<FlightDataPage> {
  late final FlightDataController _controller =
      widget.controller ?? FlightDataController();
  final MapController _map = MapController();
  LatLng? _lastCentered;
  bool _mapReady = false;

  /// Drone mình phụ trách đang có nhiệm vụ giao hàng (mô tả để hiện).
  String? _missionConflict;
  String? _missionCheckError;
  bool _conflictAcknowledged = false;

  bool get _missionLocked => _missionConflict != null && !_conflictAcknowledged;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_follow);
    _checkClaimedDroneMissions();
  }

  /// Drone đang được mình phụ trách mà đang RESERVED/IN_FLIGHT hoặc gắn với đơn
  /// đang giao ⇒ khoá lệnh tay (kết nối có thể chính là drone đó).
  Future<void> _checkClaimedDroneMissions() async {
    final service = widget.service ?? LockerOpsService();
    try {
      final userId = await TokenService.getUserId();
      final results = await Future.wait([
        service.droneUnits(),
        service.droneOrderQueue(),
      ]);
      final drones = results[0];
      final orders = results[1];
      final busy = <String>[];
      for (final drone in drones) {
        if (userId == null || '${drone['assignedTechnicianId']}' != userId) {
          continue;
        }
        final code = '${drone['code'] ?? '#${drone['id']}'}';
        Map<String, dynamic>? activeOrder;
        for (final order in orders) {
          final sameDrone =
              (drone['id'] != null &&
                  '${order['droneUnitId']}' == '${drone['id']}') ||
              (drone['code'] != null && order['droneCode'] == drone['code']);
          if (sameDrone &&
              _activeMissionStages.contains('${order['deliveryStage']}')) {
            activeOrder = order;
            break;
          }
        }
        final status = '${drone['status']}';
        if (activeOrder != null) {
          busy.add(
            '$code (đơn ${activeOrder['orderCode'] ?? '#${activeOrder['orderId']}'})',
          );
        } else if (status == 'RESERVED' || status == 'IN_FLIGHT') {
          busy.add(code);
        }
      }
      if (!mounted) return;
      setState(() {
        _missionConflict = busy.isEmpty ? null : busy.join(', ');
        _missionCheckError = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(
        () => _missionCheckError =
            'Không kiểm tra được nhiệm vụ của drone bạn phụ trách '
            '(${droneTechnicianErrorMessage(error)}). Chỉ gửi lệnh khi chắc chắn '
            'kết nối này không phải drone đang giao hàng.',
      );
    }
  }

  Future<void> _acknowledgeConflict() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Mở khoá lệnh tay?'),
        content: Text(
          'Drone bạn phụ trách đang có nhiệm vụ giao hàng: $_missionConflict.\n\n'
          'Chỉ mở khoá khi chắc chắn kết nối hiện tại là SITL hoặc một drone khác, '
          'KHÔNG phải drone đang giao hàng.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Giữ khoá'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Tôi xác nhận, mở khoá'),
          ),
        ],
      ),
    );
    if (ok == true && mounted) setState(() => _conflictAcknowledged = true);
  }

  @override
  void dispose() {
    _controller.removeListener(_follow);
    if (widget.controller == null) _controller.dispose();
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
                        _checkClaimedDroneMissions();
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
                  droneBaseTileLayer(),
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
              _safetyBanner(topPad),
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

  /// Banner luôn hiện: màn này chỉ để thử với SITL / kênh điều khiển riêng.
  Widget _safetyBanner(double topPad) {
    return Positioned(
      top: topPad + 60,
      left: 12,
      right: 12,
      child: Container(
        key: const ValueKey('flight-data-safety-banner'),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xE6B45309),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.white, size: 18),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Chỉ dùng với SITL hoặc kênh điều khiển riêng — hệ thống không điều khiển drone',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _hudPanel(double topPad, DroneTelemetry t) {
    return Positioned(
      top: topPad + 112,
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
            // Khung chỉ rộng 168: tên chế độ dài (STABILIZE…) xuống dòng.
            Wrap(
              spacing: 6,
              runSpacing: 4,
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
    final bottomPad = MediaQuery.of(context).padding.bottom;
    final state = _controller.commandState(missionLocked: _missionLocked);
    String? reasonFor(FlightCommand command) =>
        flightCommandBlockReason(command, state);
    VoidCallback? action(FlightCommand command) => reasonFor(command) == null
        ? () => command == FlightCommand.takeoff
              ? _takeoffDialog()
              : _confirmAndSend(command)
        : null;
    // Lý do chung (link/heartbeat/khoá) — lấy theo một lệnh đổi chế độ.
    final hint = reasonFor(FlightCommand.loiter);
    final takeoffHint = hint == null ? reasonFor(FlightCommand.takeoff) : null;
    final feedback = _controller.lastFeedback;
    return Container(
      margin: EdgeInsets.fromLTRB(12, 0, 12, 12 + bottomPad),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xCC0B1220),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_missionConflict != null) ...[
            _missionBanner(),
            const SizedBox(height: 8),
          ] else if (_missionCheckError != null) ...[
            _note(_missionCheckError!, const Color(0xFFFBBF24)),
            const SizedBox(height: 8),
          ],
          if (feedback != null) ...[
            _feedbackRow(feedback),
            const SizedBox(height: 8),
          ],
          if (hint != null) ...[
            _note(hint, Colors.white70),
            const SizedBox(height: 8),
          ] else if (takeoffHint != null) ...[
            _note('TAKEOFF: $takeoffHint', Colors.white70),
            const SizedBox(height: 8),
          ],
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              if (t.armed)
                _cmd('DISARM', LucideIcons.power, const Color(0xFFEF4444),
                    action(FlightCommand.disarm))
              else
                _cmd('ARM', LucideIcons.power, const Color(0xFF16A34A),
                    action(FlightCommand.arm)),
              _cmd('RTL', LucideIcons.undo2, AISLShadcnTheme.navyAccent,
                  action(FlightCommand.rtl)),
              _cmd('LOITER', LucideIcons.locateFixed, AISLShadcnTheme.navyAccent,
                  action(FlightCommand.loiter)),
              _cmd('GUIDED', LucideIcons.gamepad2, AISLShadcnTheme.navyAccent,
                  action(FlightCommand.guided)),
              _cmd('AUTO', LucideIcons.play, AISLShadcnTheme.navyAccent,
                  action(FlightCommand.auto)),
              _cmd('TAKEOFF', LucideIcons.planeTakeoff, const Color(0xFFF59E0B),
                  action(FlightCommand.takeoff)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _missionBanner() {
    return Container(
      key: const ValueKey('flight-data-mission-lock'),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFDC2626).withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEF4444)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _conflictAcknowledged
                ? 'Cảnh báo: drone bạn phụ trách đang giao hàng ($_missionConflict). '
                      'Bạn đã xác nhận kết nối này không phải drone đó.'
                : 'Drone bạn phụ trách đang có nhiệm vụ giao hàng ($_missionConflict). '
                      'Lệnh tay bị khoá để không can thiệp chuyến bay.',
            style: const TextStyle(
              color: Color(0xFFFCA5A5),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (!_conflictAcknowledged)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _acknowledgeConflict,
                child: const Text('Kết nối này không phải drone đó'),
              ),
            ),
        ],
      ),
    );
  }

  Widget _feedbackRow(CommandFeedback feedback) {
    final (color, icon) = switch (feedback.outcome) {
      CommandOutcome.pending => (Colors.white70, Icons.hourglass_top_rounded),
      CommandOutcome.accepted => (
        const Color(0xFF4ADE80),
        Icons.check_circle_outline,
      ),
      CommandOutcome.rejected => (const Color(0xFFF87171), Icons.block),
      CommandOutcome.timeout => (
        const Color(0xFFFBBF24),
        Icons.timer_off_outlined,
      ),
    };
    return Row(
      key: const ValueKey('flight-data-command-feedback'),
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            feedback.message,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  Widget _note(String text, Color color) => Text(
    text,
    textAlign: TextAlign.center,
    style: TextStyle(color: color, fontSize: 11.5, fontWeight: FontWeight.w600),
  );

  // ── small UI helpers ───────────────────────────────────────────────────────

  /// Xác nhận rồi gửi lệnh; bị chặn thì báo lý do.
  Future<void> _confirmAndSend(FlightCommand command) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Gửi lệnh ${command.label}?'),
        content: Text(
          '${command.confirmMessage}\n\nChỉ gửi khi đang kết nối SITL hoặc kênh '
          'điều khiển riêng của đội bay.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Huỷ')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Gửi lệnh')),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    _send(command);
  }

  void _send(FlightCommand command, {double? altitudeM}) {
    final blocked = _controller.sendCommand(
      command,
      altitudeM: altitudeM,
      missionLocked: _missionLocked,
    );
    if (blocked != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Chưa gửi ${command.label}: $blocked')),
      );
    }
  }

  /// Cất cánh: hộp thoại này là bước xác nhận; độ cao phải trong trần cho phép.
  Future<void> _takeoffDialog() async {
    final ctrl = TextEditingController(text: '10');
    String? error;
    final alt = await showDialog<double>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: const Text('Xác nhận cất cánh (GUIDED)'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Drone đã ARM và ở chế độ GUIDED. Nhập độ cao cất cánh '
                '(${kMinTakeoffAltitudeM.toStringAsFixed(0)}–${kMaxTakeoffAltitudeM.toStringAsFixed(0)} m):',
              ),
              const SizedBox(height: 10),
              TextField(
                key: const ValueKey('flight-data-takeoff-altitude'),
                controller: ctrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
                decoration: InputDecoration(suffixText: 'm', errorText: error),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Huỷ')),
            FilledButton(
              onPressed: () {
                final value = double.tryParse(ctrl.text.trim());
                final message = takeoffAltitudeError(value);
                if (message != null) {
                  setLocal(() => error = message);
                  return;
                }
                Navigator.pop(ctx, value);
              },
              child: const Text('Cất cánh'),
            ),
          ],
        ),
      ),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => ctrl.dispose());
    if (alt == null || !mounted) return;
    _send(FlightCommand.takeoff, altitudeM: alt);
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
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700),
            ),
          ),
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
