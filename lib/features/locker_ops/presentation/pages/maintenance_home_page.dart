import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_laundry_locker/core/routing/app_router.dart';
import 'package:smart_laundry_locker/core/services/token_service.dart';
import 'package:smart_laundry_locker/features/locker_ops/data/locker_ops_service.dart';
import 'package:smart_laundry_locker/features/locker_ops/presentation/widgets/ops_widgets.dart';
import 'package:smart_laundry_locker/shared/widgets/user_ui_kit.dart';

/// Home for the MAINTENANCE role: drone fleet only (delivery dispatch queue
/// from the backend, fleet status/battery, mission planner, flight data,
/// drone maintenance schedules). Physical locker maintenance lives with the
/// TECHNICIAN role.
class MaintenanceHomePage extends StatefulWidget {
  const MaintenanceHomePage({super.key, this.service});

  final LockerOpsService? service;

  @override
  State<MaintenanceHomePage> createState() => _MaintenanceHomePageState();
}

class _MaintenanceHomePageState extends State<MaintenanceHomePage> {
  late final LockerOpsService _service = widget.service ?? LockerOpsService();

  List<Map<String, dynamic>> _drones = [];
  // Hàng đợi order-based cho đội bay theo Phase 2.
  List<Map<String, dynamic>> _deliveries = [];
  // Lịch bảo trì định kỳ của drone (droneUnitId != null) — lịch tủ thuộc TECHNICIAN.
  List<Map<String, dynamic>> _schedules = [];
  bool _loading = true;
  String? _myUserId;

  List<Map<String, dynamic>> get _awaitingDispatchDeliveries => _deliveries
      .where((d) => d['deliveryStage'] == 'AWAITING_DISPATCH')
      .toList(growable: false);

  List<Map<String, dynamic>> get _acceptedDeliveries => _deliveries
      .where((d) => d['deliveryStage'] == 'ACCEPTED')
      .toList(growable: false);

  List<Map<String, dynamic>> get _launchingDeliveries => _deliveries
      .where((d) => d['deliveryStage'] == 'LAUNCHING')
      .toList(growable: false);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      _myUserId = await TokenService.getUserId();
      // Đội drone — endpoint mới (V10); không để vỡ trang nếu BE chưa deploy.
      try {
        final drones = await _service.droneUnits();
        if (mounted) setState(() => _drones = drones);
      } catch (_) {}
      // Hàng đợi order-based cho đội bay (Phase 2) — best-effort như trên.
      try {
        final deliveries = await _service.droneOrderQueue();
        if (mounted) setState(() => _deliveries = deliveries);
      } catch (_) {}
      // Lịch bảo trì định kỳ drone — best-effort như trên.
      try {
        final schedules = await _service.maintenanceSchedules();
        if (mounted) {
          setState(
            () => _schedules = schedules
                .where((s) => s['droneUnitId'] != null)
                .toList(growable: false),
          );
        }
      } catch (_) {}
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _logout() async {
    await TokenService.clearTokens();
    if (mounted) context.go('/onboarding');
  }

  Future<void> _run(Future<Object?> Function() fn, String ok) async {
    try {
      await fn();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ok)));
      }
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(LockerOpsService.errorMessage(e))),
        );
      }
    }
  }

  /// Chạy 1 thao tác + báo kết quả + reload danh sách (giữ tên cũ để không
  /// đổi các flow drone gọi tới).
  Future<void> _runCellAction(
    Future<dynamic> Function() action,
    String successMsg,
  ) async {
    try {
      await action();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(successMsg)));
      }
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(LockerOpsService.errorMessage(e))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FA),
      body: Column(
        children: [
          BrandHeroHeader(
            title: 'Đội bay drone',
            subtitle: _awaitingDispatchDeliveries.isNotEmpty
                ? '${_awaitingDispatchDeliveries.length} đơn drone đang chờ tiếp nhận'
                : 'Không có đơn drone nào chờ tiếp nhận',
            onBack: context.canPop() ? () => context.pop() : null,
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                BrandCircleIconButton(icon: Icons.refresh, onTap: _load),
                if (!context.canPop()) ...[
                  const SizedBox(width: 8),
                  BrandCircleIconButton(icon: Icons.logout, onTap: _logout),
                ],
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(color: AislBrand.navy),
                  )
                : _buildDroneFleet(),
          ),
        ],
      ),
    );
  }

  // Entry card for a drone tool (Mission Planner / Flight Data).
  Widget _droneToolCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return OpsCard(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFF1E5A8A).withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: const Color(0xFF1E5A8A)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: Color(0xFF94A3B8)),
        ],
      ),
    );
  }

  // ---- Đội drone (thiết bị bay vật lý, khác ô tủ cellType=DRONE) ----
  Widget _buildDroneFleet() {
    final awaiting = _awaitingDispatchDeliveries;
    final accepted = _acceptedDeliveries;
    final launching = _launchingDeliveries;
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          // ── Đơn hàng drone order-based cho đội bay ───────────────────────
          if (awaiting.isNotEmpty) ...[
            OpsSectionLabel(
              'Chờ tiếp nhận (${awaiting.length})',
              icon: Icons.inbox_rounded,
            ),
            const SizedBox(height: 8),
            for (final order in awaiting)
              _deliveryCard(order, action: _DeliveryAction.accept),
            const SizedBox(height: 8),
          ],
          if (accepted.isNotEmpty) ...[
            OpsSectionLabel(
              'Sẵn sàng phóng (${accepted.length})',
              icon: Icons.rocket_launch,
            ),
            const SizedBox(height: 8),
            for (final order in accepted)
              _deliveryCard(
                order,
                action: _DeliveryAction.launch,
                onCancel: () => _cancelDeliveryFlow(order),
              ),
            const SizedBox(height: 8),
          ],
          if (launching.isNotEmpty) ...[
            OpsSectionLabel(
              'Đang khởi phóng (${launching.length})',
              icon: Icons.flight_takeoff,
            ),
            const SizedBox(height: 8),
            for (final order in launching)
              _deliveryCard(order, action: _DeliveryAction.launching),
            const SizedBox(height: 8),
          ],
          if (awaiting.isNotEmpty ||
              accepted.isNotEmpty ||
              launching.isNotEmpty) ...[
            const Divider(),
            const SizedBox(height: 8),
          ],

          const OpsBanner(
            tone: OpsBannerTone.info,
            icon: Icons.flight_outlined,
            text:
                'Pin và trạng thái bay do kỹ thuật viên cập nhật tay — '
                'chưa có telemetry thật từ drone.',
          ),
          const SizedBox(height: 12),
          _droneToolCard(
            icon: Icons.map_outlined,
            title: 'Lập kế hoạch bay (Mission Planner)',
            subtitle: 'Vẽ waypoint, đặt độ cao/lệnh, xuất file mission',
            onTap: () => context.push(AppRouter.droneMissionPlanner),
          ),
          const SizedBox(height: 10),
          _droneToolCard(
            icon: Icons.flight_takeoff,
            title: 'Telemetry & điều khiển (Flight Data)',
            subtitle: 'Kết nối MAVLink, xem vị trí/HUD live, gửi lệnh bay',
            onTap: () => context.push(AppRouter.droneFlightData),
          ),
          const SizedBox(height: 12),
          if (_drones.isEmpty)
            const OpsEmptyState(
              icon: Icons.flight_outlined,
              title: 'Chưa có drone nào',
              subtitle: 'Đội drone sẽ hiện ở đây khi được thêm vào hệ thống.',
            )
          else
            for (final d in _drones) _droneCard(d),

          // ── Lịch bảo trì định kỳ drone ──────────────────────────────
          if (_schedules.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            const OpsSectionLabel('Định kỳ drone', icon: Icons.event_repeat),
            for (final s in _schedules)
              _droneScheduleCard(s, due: s['due'] == true),
          ],
        ],
      ),
    );
  }

  Widget _droneScheduleCard(Map<String, dynamic> s, {required bool due}) {
    final droneLabel = 'Drone ${s['droneCode'] ?? s['droneUnitId']}';
    final nextDue = _fmtDate(s['nextDueAt']);
    final lastDone = _fmtDate(s['lastDoneAt']);
    final id = _asInt(s['id']);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: OpsCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${s['title'] ?? ''}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: opsDark,
                    ),
                  ),
                ),
                if (due)
                  const _MiniPill(
                    icon: Icons.warning_amber_rounded,
                    text: 'Đến hạn',
                    color: Color(0xFFDC2626),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                _MiniPill(icon: Icons.flight_takeoff, text: droneLabel),
                _MiniPill(
                  icon: Icons.repeat,
                  text: 'Mỗi ${s['intervalDays']} ngày',
                ),
                if (nextDue != null)
                  _MiniPill(icon: Icons.event, text: 'Hạn: $nextDue'),
                if (lastDone != null)
                  _MiniPill(icon: Icons.history, text: 'Lần trước: $lastDone'),
              ],
            ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton.icon(
                onPressed: id == null
                    ? null
                    : () => _run(
                        () => _service.completeSchedule(id),
                        'Đã ghi nhận kiểm tra — dời lịch kế tiếp',
                      ),
                icon: const Icon(Icons.check, size: 16),
                label: const Text('Đã kiểm tra'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF16A34A),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String? _fmtDate(dynamic value) {
    final d = DateTime.tryParse('$value')?.toLocal();
    if (d == null) return null;
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(d.day)}/${two(d.month)}/${d.year}';
  }

  /// Card một drone order trong queue điều phối.
  Widget _deliveryCard(
    Map<String, dynamic> order, {
    required _DeliveryAction action,
    VoidCallback? onCancel,
  }) {
    final orderId = _asInt(order['orderId']);
    final lockerId = _asInt(order['destinationLockerId']);
    final lockerName =
        order['lockerName'] ??
        (lockerId == null ? 'Tủ đích chưa rõ' : 'Tủ đích #$lockerId');
    final reservedBoxId = _asInt(order['reservedBoxId']);
    final description = order['description']?.toString();
    final droneCode = order['droneCode']?.toString();
    final missionStatus = order['missionStatus']?.toString();
    final createdAt = DateTime.tryParse('${order['createdAt']}')?.toLocal();
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFF6366F1).withValues(alpha: 0.35),
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF6366F1).withValues(alpha: 0.08),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
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
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$lockerName',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: opsDark,
                        ),
                      ),
                      Text(
                        [
                          if (reservedBoxId != null)
                            'Ô giữ chỗ #$reservedBoxId',
                          if (createdAt != null) _formatTime(createdAt),
                          if (droneCode != null) droneCode,
                        ].join(' · '),
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                if (!(action == _DeliveryAction.launch && onCancel != null))
                  FilledButton.icon(
                    onPressed: _actionEnabled(action, orderId)
                        ? () => _handleDeliveryAction(order, action)
                        : null,
                    style: FilledButton.styleFrom(
                      backgroundColor: switch (action) {
                        _DeliveryAction.accept => const Color(0xFF6366F1),
                        _DeliveryAction.launch => const Color(0xFF16A34A),
                        _DeliveryAction.launching => const Color(0xFF94A3B8),
                      },
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    icon: Icon(switch (action) {
                      _DeliveryAction.accept => Icons.send_rounded,
                      _DeliveryAction.launch => Icons.rocket_launch,
                      _DeliveryAction.launching => Icons.hourglass_top,
                    }, size: 15),
                    label: Text(
                      switch (action) {
                        _DeliveryAction.accept => 'Tiếp nhận',
                        _DeliveryAction.launch => 'Phóng',
                        _DeliveryAction.launching => 'Đang phóng',
                      },
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
              ],
            ),
            if (action == _DeliveryAction.launch && onCancel != null) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.end,
                children: [
                  FilledButton.icon(
                    onPressed: _actionEnabled(action, orderId)
                        ? () => _handleDeliveryAction(order, action)
                        : null,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF16A34A),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    icon: const Icon(Icons.rocket_launch, size: 15),
                    label: const Text(
                      'Phóng',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: onCancel,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFDC2626),
                      side: const BorderSide(color: Color(0xFFDC2626)),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    icon: const Icon(Icons.close_rounded, size: 15),
                    label: const Text(
                      'Hủy trước khi bay',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ],
            if (description != null && description.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Hàng: $description',
                style: const TextStyle(fontSize: 12, color: Colors.black54),
              ),
            ],
            if (missionStatus != null && missionStatus.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Mission: $missionStatus',
                style: const TextStyle(fontSize: 12, color: Colors.black45),
              ),
            ],
          ],
        ),
      ),
    );
  }

  bool _actionEnabled(_DeliveryAction action, int? orderId) {
    if (orderId == null) return false;
    return action != _DeliveryAction.launching;
  }

  Future<void> _handleDeliveryAction(
    Map<String, dynamic> order,
    _DeliveryAction action,
  ) async {
    final orderId = _asInt(order['orderId']);
    if (orderId == null) return;
    switch (action) {
      case _DeliveryAction.accept:
        await _acceptFlow(order);
      case _DeliveryAction.launch:
        await _run(
          () => _service.launchDroneOrder(
            orderId,
            idempotencyKey: _idempotencyKey('launch', orderId),
          ),
          'Đã phát lệnh phóng nhiệm vụ',
        );
      case _DeliveryAction.launching:
        return;
    }
  }

  Future<void> _cancelDeliveryFlow(Map<String, dynamic> order) async {
    final orderId = _asInt(order['orderId']);
    if (orderId == null) return;
    final noteCtrl = TextEditingController();
    var selectedReason = _cancelReasons.first;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text('Hủy nhiệm vụ trước khi bay'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final reason in _cancelReasons)
                    ChoiceChip(
                      label: Text(reason.label),
                      selected: selectedReason.code == reason.code,
                      onSelected: (_) =>
                          setLocal(() => selectedReason = reason),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: noteCtrl,
                minLines: 2,
                maxLines: 4,
                decoration: InputDecoration(
                  labelText: selectedReason.requiresNote
                      ? 'Ghi chú (bắt buộc)'
                      : 'Ghi chú (tùy chọn)',
                  isDense: true,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Hủy'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFDC2626),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {
                if (selectedReason.requiresNote &&
                    noteCtrl.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Cần nhập ghi chú khi chọn Khác'),
                    ),
                  );
                  return;
                }
                Navigator.pop(ctx, true);
              },
              child: const Text('Xác nhận hủy'),
            ),
          ],
        ),
      ),
    );

    if (confirmed != true) {
      return;
    }

    await _run(
      () => _service.cancelDroneOrder(
        orderId,
        reasonCode: selectedReason.code,
        note: noteCtrl.text.trim().isEmpty ? null : noteCtrl.text.trim(),
      ),
      'Đã hủy nhiệm vụ drone',
    );
  }

  String _formatTime(DateTime t) {
    final now = DateTime.now();
    final diff = now.difference(t);
    if (diff.inMinutes < 1) return 'Vừa xong';
    if (diff.inMinutes < 60) return '${diff.inMinutes} phút trước';
    return '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
  }

  /// Chọn drone IDLE rồi tiếp nhận nhiệm vụ theo `orderId`.
  Future<void> _acceptFlow(Map<String, dynamic> order) async {
    final id = _asInt(order['orderId']);
    if (id == null) return;
    final candidates = _drones
        .where((d) => d['status'] == 'IDLE')
        .toList(growable: false);
    if (candidates.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Không có drone IDLE để tiếp nhận nhiệm vụ'),
          ),
        );
      }
      return;
    }
    int? selectedDroneId = _asInt(candidates.first['id']);

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Row(
            children: [
              Icon(Icons.flight, color: Color(0xFF6366F1)),
              SizedBox(width: 8),
              Text('Tiếp nhận nhiệm vụ'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Giao tới ${order['lockerName'] ?? 'tủ đích #${order['destinationLockerId']}'}'
                '${order['reservedBoxId'] != null ? ' · ô giữ chỗ #${order['reservedBoxId']}' : ''}.',
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final d in candidates)
                    ChoiceChip(
                      label: Text(
                        '${d['code']} · ${d['batteryPercent'] ?? '?'}%',
                      ),
                      selected: selectedDroneId == _asInt(d['id']),
                      onSelected: (_) =>
                          setLocal(() => selectedDroneId = _asInt(d['id'])),
                    ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Hủy'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Tiếp nhận ngay'),
            ),
          ],
        ),
      ),
    );
    if (ok != true) return;
    if (selectedDroneId == null) return;
    await _run(
      () => _service.acceptDroneOrder(
        id,
        droneUnitId: selectedDroneId!,
        idempotencyKey: _idempotencyKey('accept', id),
      ),
      'Đã tiếp nhận và gán drone cho nhiệm vụ',
    );
  }

  String _idempotencyKey(String prefix, int orderId) =>
      '$prefix-$orderId-${DateTime.now().microsecondsSinceEpoch}';

  Widget _droneCard(Map<String, dynamic> drone) {
    final status = drone['status'] as String? ?? 'IDLE';
    final battery = _asInt(drone['batteryPercent']) ?? 0;
    final lockerLabel = drone['lockerName'] ?? 'Tủ ${drone['lockerId']}';
    final technicianName = (drone['assignedTechnicianName'] as String?)?.trim();
    final faultReason = drone['faultReason'] as String?;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: OpsCard(
        onTap: () => _droneActions(drone),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${drone['code'] ?? ''}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: opsDark,
                    ),
                  ),
                ),
                _DroneStatusChip(status),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                _MiniPill(icon: Icons.warehouse_outlined, text: '$lockerLabel'),
                _MiniPill(
                  icon: _droneBatteryIcon(battery),
                  text: '$battery% pin',
                  color: _droneBatteryColor(battery),
                ),
                _MiniPill(
                  icon: Icons.person_outline,
                  text: technicianName?.isNotEmpty == true
                      ? technicianName!
                      : 'Chưa nhận',
                ),
              ],
            ),
            if (faultReason != null && faultReason.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                faultReason,
                style: const TextStyle(fontSize: 12, color: Color(0xFFDC2626)),
              ),
            ],
          ],
        ),
      ),
    );
  }

  IconData _droneBatteryIcon(int percent) {
    if (percent <= 15) return Icons.battery_alert;
    if (percent <= 50) return Icons.battery_3_bar;
    if (percent <= 85) return Icons.battery_5_bar;
    return Icons.battery_full;
  }

  Color _droneBatteryColor(int percent) {
    if (percent <= 15) return const Color(0xFFDC2626);
    if (percent <= 50) return const Color(0xFFD97706);
    return const Color(0xFF16A34A);
  }

  /// Bottom sheet hành động cho 1 drone: nhận xử lý, đổi trạng thái, cập
  /// nhật pin, xem/ghi nhật ký bảo trì.
  Future<void> _droneActions(Map<String, dynamic> drone) async {
    final droneId = _asInt(drone['id']);
    if (droneId == null) return;
    final status = drone['status'] as String? ?? 'IDLE';
    final battery = _asInt(drone['batteryPercent']) ?? 0;
    final assignedToMe =
        drone['assignedTechnicianId'] != null &&
        '${drone['assignedTechnicianId']}' == _myUserId;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (sheetCtx) {
        Widget tile(IconData icon, String label, Color c, VoidCallback onTap) {
          return OpsSheetAction(
            icon: icon,
            label: label,
            color: c,
            onTap: () {
              Navigator.pop(sheetCtx);
              onTap();
            },
          );
        }

        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${drone['code'] ?? ''}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                          color: opsDark,
                        ),
                      ),
                    ),
                    _DroneStatusChip(status),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Pin $battery%'
                  '${assignedToMe ? ' · bạn đang phụ trách' : ''}',
                  style: const TextStyle(fontSize: 12, color: opsMutedText),
                ),
                const SizedBox(height: 16),
                if (!assignedToMe)
                  tile(
                    Icons.assignment_ind_outlined,
                    'Nhận xử lý',
                    opsPrimary,
                    () => _runCellAction(
                      () => _service.claimDrone(droneId),
                      'Đã nhận phụ trách drone',
                    ),
                  ),
                if (assignedToMe)
                  tile(
                    Icons.assignment_return_outlined,
                    'Nhả phụ trách',
                    const Color(0xFF6B7280),
                    () => _runCellAction(
                      () => _service.releaseDrone(droneId),
                      'Đã nhả phụ trách drone',
                    ),
                  ),
                tile(
                  Icons.sync_alt,
                  'Đổi trạng thái',
                  const Color(0xFF7C3AED),
                  () => _changeDroneStatusFlow(drone),
                ),
                tile(
                  Icons.battery_charging_full,
                  'Cập nhật pin %',
                  const Color(0xFF0891B2),
                  () => _updateDroneBatteryFlow(drone),
                ),
                tile(
                  Icons.history_edu_outlined,
                  'Nhật ký bảo trì',
                  opsMutedText,
                  () => _droneLogSheet(drone),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Dialog chọn trạng thái mới cho drone; bắt nhập lý do khi chọn FAULT.
  Future<void> _changeDroneStatusFlow(Map<String, dynamic> drone) async {
    final droneId = _asInt(drone['id']);
    if (droneId == null) return;
    final reasonCtrl = TextEditingController();
    String selected = drone['status'] as String? ?? 'IDLE';

    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text('Đổi trạng thái drone'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final s in _droneStatuses)
                    ChoiceChip(
                      label: Text(_droneStatusLabel(s)),
                      selected: selected == s,
                      onSelected: (_) => setLocal(() => selected = s),
                    ),
                ],
              ),
              if (selected == 'FAULT') ...[
                const SizedBox(height: 12),
                TextField(
                  controller: reasonCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Lý do (bắt buộc)',
                    isDense: true,
                  ),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: opsPrimary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () => Navigator.pop(ctx, selected),
              child: const Text('Xác nhận'),
            ),
          ],
        ),
      ),
    );
    final isFault = result == 'FAULT';
    // Lý do chỉ có ý nghĩa với FAULT — bỏ qua text sót lại nếu đổi sang trạng thái khác.
    final reason = isFault ? reasonCtrl.text.trim() : '';
    reasonCtrl.dispose();
    if (result == null) return;
    // Không gọi API nếu chọn lại đúng trạng thái cũ (trừ FAULT — cho phép cập nhật lý do mới).
    if (result == (drone['status'] as String?) && !isFault) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Trạng thái không thay đổi')),
        );
      }
      return;
    }
    if (isFault && reason.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cần nhập lý do khi chuyển sang FAULT')),
        );
      }
      return;
    }
    await _runCellAction(
      () => _service.updateDroneStatus(
        droneId,
        result,
        reason: reason.isEmpty ? null : reason,
      ),
      'Đã đổi trạng thái drone',
    );
  }

  /// Dialog nhập % pin hiện tại (nhập tay, chưa có telemetry thật).
  Future<void> _updateDroneBatteryFlow(Map<String, dynamic> drone) async {
    final droneId = _asInt(drone['id']);
    if (droneId == null) return;
    final ctrl = TextEditingController(
      text: '${drone['batteryPercent'] ?? 100}',
    );
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Cập nhật pin %'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Pin còn lại (0-100)'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: opsPrimary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
    final percent = int.tryParse(ctrl.text.trim());
    ctrl.dispose();
    if (ok != true || percent == null) return;
    if (percent < 0 || percent > 100) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pin phải trong khoảng 0-100')),
        );
      }
      return;
    }
    await _runCellAction(
      () => _service.updateDroneBattery(droneId, percent),
      'Đã cập nhật pin drone',
    );
  }

  /// Mở nhật ký bảo trì của 1 drone để xem + thêm ghi chú tiến trình.
  Future<void> _droneLogSheet(Map<String, dynamic> drone) async {
    final droneId = _asInt(drone['id']);
    if (droneId == null) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _DroneLogSheet(
        droneId: droneId,
        service: _service,
        title: '${drone['code'] ?? ''}',
      ),
    );
    if (mounted) await _load();
  }
}

/// Bottom sheet xem + thêm nhật ký bảo trì cho một drone.
class _DroneLogSheet extends StatefulWidget {
  const _DroneLogSheet({
    required this.droneId,
    required this.service,
    required this.title,
  });

  final int droneId;
  final LockerOpsService service;
  final String title;

  @override
  State<_DroneLogSheet> createState() => _DroneLogSheetState();
}

class _DroneLogSheetState extends State<_DroneLogSheet> {
  final _noteCtrl = TextEditingController();
  List<Map<String, dynamic>> _logs = const [];
  bool _loading = true;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final logs = await widget.service.droneLogs(widget.droneId);
      if (!mounted) return;
      setState(() {
        _logs = logs;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _add() async {
    final note = _noteCtrl.text.trim();
    if (note.isEmpty) return;
    setState(() => _sending = true);
    try {
      await widget.service.addDroneLog(widget.droneId, note);
      _noteCtrl.clear();
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(LockerOpsService.errorMessage(e))),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  String _fmt(dynamic value) {
    final d = DateTime.tryParse('$value')?.toLocal();
    if (d == null) return '';
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(d.hour)}:${two(d.minute)} ${two(d.day)}/${two(d.month)}';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
              child: Row(
                children: [
                  const Icon(
                    Icons.history_edu_outlined,
                    size: 18,
                    color: opsMutedText,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Nhật ký bảo trì · ${widget.title}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Flexible(
              child: _loading
                  ? const Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  : _logs.isEmpty
                  ? const OpsEmptyState(
                      icon: Icons.history_edu_outlined,
                      title: 'Chưa có ghi chú nào',
                      subtitle: 'Thêm bước xử lý đầu tiên bên dưới.',
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 8,
                      ),
                      itemCount: _logs.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (_, i) {
                        final log = _logs[i];
                        return Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: opsSurface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: opsBorder),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('${log['note'] ?? ''}'),
                              const SizedBox(height: 4),
                              Text(
                                '${_fmt(log['createdAt'])}'
                                '${log['actorUserId'] != null ? ' · KTV #${log['actorUserId']}' : ''}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: opsMutedText,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _noteCtrl,
                      minLines: 1,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: 'Thêm bước xử lý / ghi chú...',
                        isDense: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: opsBorder),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: _sending ? null : _add,
                    style: IconButton.styleFrom(backgroundColor: opsPrimary),
                    icon: _sending
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.send),
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

int? _asInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse('$value');
}

enum _DeliveryAction { accept, launch, launching }

class _DroneCancelReason {
  const _DroneCancelReason(this.code, this.label, {this.requiresNote = false});

  final int code;
  final String label;
  final bool requiresNote;
}

const _cancelReasons = [
  _DroneCancelReason(1, 'Thời tiết xấu'),
  _DroneCancelReason(2, 'Drone lỗi'),
  _DroneCancelReason(3, 'Bãi đáp không sẵn sàng'),
  _DroneCancelReason(4, 'Lý do vận hành'),
  _DroneCancelReason(5, 'Khác', requiresNote: true),
];

/// Trạng thái của 1 con drone vật lý (drone_units.status) — khác trạng thái
/// ô tủ cellType=DRONE ở trên.
const _droneStatuses = [
  'IDLE',
  'CHARGING',
  'IN_FLIGHT',
  'MAINTENANCE',
  'FAULT',
];

String _droneStatusLabel(String? status) => switch (status) {
  'IDLE' => 'Sẵn sàng',
  'CHARGING' => 'Đang sạc',
  'IN_FLIGHT' => 'Đang bay',
  'MAINTENANCE' => 'Đang bảo trì',
  'FAULT' => 'Lỗi',
  _ => status ?? '',
};

Color _droneStatusColor(String? status) => switch (status) {
  'IDLE' => const Color(0xFF16A34A),
  'CHARGING' => const Color(0xFF2563EB),
  'IN_FLIGHT' => const Color(0xFF7C3AED),
  'MAINTENANCE' => const Color(0xFFD97706),
  'FAULT' => const Color(0xFFDC2626),
  _ => opsMutedText,
};

class _DroneStatusChip extends StatelessWidget {
  const _DroneStatusChip(this.status);
  final String? status;

  @override
  Widget build(BuildContext context) {
    final color = _droneStatusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        _droneStatusLabel(status),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

class _MiniPill extends StatelessWidget {
  const _MiniPill({
    required this.icon,
    required this.text,
    this.color = opsPrimary,
  });

  final IconData icon;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
