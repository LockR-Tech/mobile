import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:smart_laundry_locker/core/services/token_service.dart';
import 'package:smart_laundry_locker/features/locker_ops/data/locker_ops_service.dart';
import 'package:smart_laundry_locker/features/locker_ops/presentation/utils/locker_maps.dart';
import 'package:smart_laundry_locker/features/locker_ops/presentation/widgets/locker_picker.dart';
import 'package:smart_laundry_locker/features/locker_ops/presentation/widgets/ops_widgets.dart';
import 'package:smart_laundry_locker/shared/widgets/user_ui_kit.dart';
import 'package:smart_laundry_locker/core/routing/app_router.dart';

/// Home for the TECHNICIAN role: physical locker maintenance (fault cells,
/// work queue, preventive schedules, landing pad) + IoT device management.
/// Drone fleet operations live with the MAINTENANCE role.
class TechnicianHomePage extends StatefulWidget {
  const TechnicianHomePage({super.key});

  @override
  State<TechnicianHomePage> createState() => _TechnicianHomePageState();
}

class _TechnicianHomePageState extends State<TechnicianHomePage>
    with SingleTickerProviderStateMixin {
  final _service = LockerOpsService();
  late final TabController _tabs = TabController(length: 5, vsync: this);

  List<Map<String, dynamic>> _faults = [];
  List<Map<String, dynamic>> _reports = [];
  List<Map<String, dynamic>> _myReports = [];
  List<Map<String, dynamic>> _schedules = [];
  // Cảnh báo phần cứng toàn cục (GAP 2): ô cửa-mở-bất-thường trên mọi tủ.
  List<Map<String, dynamic>> _anomalies = [];
  bool _loading = true;
  String? _myUserId;
  Map<String, dynamic>? _ratingAverage;
  Map<String, dynamic>? _myPerformance;

  // Inspection tab state
  List<Map<String, dynamic>> _lockers = [];
  int? _selectedLockerId;
  Map<String, dynamic>? _layout;
  bool _layoutLoading = false;
  // Box-health (GAP 2): trạng thái phần cứng cửa từ iot-service cho tủ đang chọn.
  List<Map<String, dynamic>> _boxHealth = [];

  // IoT devices tab state
  List<Map<String, dynamic>> _devices = [];
  String? _devicesError;

  List<Map<String, dynamic>> get _lockerOptions => _lockers
      .where((locker) => _asInt(locker['id']) != null)
      .toList(growable: false);

  Map<String, dynamic>? get _selectedLocker {
    final selectedId = _selectedLockerId;
    if (selectedId == null) return null;
    for (final locker in _lockerOptions) {
      if (_asInt(locker['id']) == selectedId) return locker;
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      _myUserId = await TokenService.getUserId();
      final faults = await _service.faults();
      final reports = await _service.reports();
      final mine = await _service.reports(mine: true);
      final lockers = await _service.lockers();
      if (!mounted) return;
      setState(() {
        _faults = faults;
        _reports = reports;
        _myReports = mine;
        _lockers = lockers;
      });
      // Lịch bảo trì định kỳ — chỉ lịch của tủ; lịch drone thuộc đội bay
      // (MAINTENANCE). Không để vỡ trang nếu BE chưa deploy.
      try {
        final schedules = await _service.maintenanceSchedules();
        if (mounted) {
          setState(() => _schedules = schedules.toList(growable: false));
        }
      } catch (_) {}
      try {
        final avg = await _service.myRatingAverage();
        if (mounted) setState(() => _ratingAverage = avg);
      } catch (_) {}
      try {
        final perf = await _service.myPerformance();
        if (mounted) setState(() => _myPerformance = perf);
      } catch (_) {}
      // Cảnh báo phần cứng toàn cục (GAP 2) — best-effort, không vỡ trang nếu BE/IoT chưa có.
      try {
        final anomalies = await _service.boxAnomalies();
        if (mounted) setState(() => _anomalies = anomalies);
      } catch (_) {}
      // Thiết bị IoT — best-effort; tab riêng hiển thị lỗi nếu có.
      try {
        final devices = await _service.techDevices();
        if (mounted) {
          setState(() {
            _devices = devices;
            _devicesError = null;
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() => _devicesError = LockerOpsService.errorMessage(e));
        }
      }
      final validSelected = lockers.any(
        (locker) => _asInt(locker['id']) == _selectedLockerId,
      );
      final firstId = lockers.isNotEmpty ? _asInt(lockers.first['id']) : null;
      final nextSelectedId = validSelected ? _selectedLockerId : firstId;
      if (nextSelectedId == null) {
        setState(() {
          _selectedLockerId = null;
          _layout = null;
        });
      } else {
        await _selectLocker(nextSelectedId);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(LockerOpsService.errorMessage(e))),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _selectLocker(int lockerId) async {
    setState(() {
      _selectedLockerId = lockerId;
      _layoutLoading = true;
      _boxHealth = [];
    });
    try {
      final layout = await _service.layout(lockerId);
      if (!mounted) return;
      setState(() => _layout = layout);
      // Box-health phần cứng (GAP 2) — best-effort, không vỡ trang nếu BE chưa deploy.
      try {
        final health = await _service.boxHealth(lockerId);
        if (mounted && _selectedLockerId == lockerId) {
          setState(() => _boxHealth = health);
        }
      } catch (_) {}
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(LockerOpsService.errorMessage(e))),
        );
      }
    } finally {
      if (mounted) setState(() => _layoutLoading = false);
    }
  }

  Future<void> _logout() async {
    await TokenService.clearTokens();
    if (mounted) context.go('/onboarding');
  }

  void _showSlaRestrictedDialog(String message) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Color(0xFFDC2626), size: 28),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Hạn chế nhận việc mới',
                style: TextStyle(fontSize: 16.5, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFCA5A5)),
              ),
              child: Text(
                message,
                style: const TextStyle(
                  color: Color(0xFF991B1B),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Quy chế SLA: Kỹ thuật viên có từ 3 phiếu sự cố quá hạn sẽ tạm thời không thể nhận thêm việc mới. Vui lòng chuyển sang tab "Việc của tôi" và hoàn tất các công việc tồn đọng.',
              style: TextStyle(fontSize: 12.5, color: opsMutedText),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Đã hiểu'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(ctx).pop();
              _tabs.animateTo(2); // Jump to "Việc của tôi" tab
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: opsPrimary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            icon: const Icon(Icons.arrow_forward, size: 16),
            label: const Text('Xem việc của tôi'),
          ),
        ],
      ),
    );
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
        final msg = LockerOpsService.errorMessage(e);
        if (msg.contains('SLA_RESTRICTED') ||
            msg.contains('hạn chế nhận thêm') ||
            msg.contains('quá hạn SLA')) {
          _showSlaRestrictedDialog(msg);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: const Color(0xFFDC2626),
              content: Text(msg),
            ),
          );
        }
      }
    }
  }

  Future<void> _openDirections(Map<String, dynamic> item) async {
    final opened = await openLockerDirections(
      latitude: _asDouble(item['lockerLatitude'] ?? item['latitude']),
      longitude: _asDouble(item['lockerLongitude'] ?? item['longitude']),
      address: (item['lockerAddress'] ?? item['address'])?.toString(),
    );
    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tủ này chưa có vị trí để chỉ đường.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final openCount = _reports.where((r) => r['status'] != 'RESOLVED').length;
    final mineCount =
        _myReports.where((r) => r['status'] == 'IN_PROGRESS').length;
    final dueCount = _schedules.where((s) => s['due'] == true).length;
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FA),
      body: Column(
        children: [
          BrandHeroHeader(
            title: 'Kỹ thuật viên',
            subtitle: openCount > 0
                ? '$openCount phiếu sự cố đang chờ xử lý'
                : 'Không có phiếu sự cố nào đang mở',
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                BrandCircleIconButton(
                  icon: Icons.flight,
                  onTap: () => context.push(AppRouter.maintenanceHome),
                ),
                const SizedBox(width: 8),
                BrandCircleIconButton(icon: Icons.refresh, onTap: _load),
                const SizedBox(width: 8),
                BrandCircleIconButton(icon: Icons.logout, onTap: _logout),
              ],
            ),
          ),
          Material(
            color: Colors.white,
            child: TabBar(
              controller: _tabs,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              padding: EdgeInsets.zero,
              indicatorColor: opsPrimary,
              labelColor: opsDark,
              unselectedLabelColor: opsMutedText,
              tabs: [
                const Tab(text: 'Kiểm tra tủ'),
                Tab(text: 'Sự cố ($openCount)'),
                Tab(text: 'Việc của tôi ($mineCount)'),
                Tab(text: 'Định kỳ ($dueCount)'),
                Tab(text: 'Thiết bị IoT (${_devices.length})'),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(color: AislBrand.navy),
                  )
                : TabBarView(
                    controller: _tabs,
                    children: [
                      _buildInspect(),
                      _buildQueue(),
                      _buildMine(),
                      _buildSchedules(),
                      _buildIotDevices(),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  // ---- Tab 1: inspect lockers (browse cabinet, see cell status, report/clear) ----
  Widget _buildInspect() {
    final cells =
        (_layout?['cells'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final lockerOptions = _lockerOptions;
    final selectedLocker = _selectedLocker;
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const OpsSectionLabel('Chọn tủ để kiểm tra', icon: Icons.warehouse_outlined),
          if (lockerOptions.isEmpty)
            const OpsEmptyState(
              icon: Icons.warehouse_outlined,
              title: 'Chưa có tủ nào',
            )
          else
            LockerPickerField(
              lockers: lockerOptions,
              selectedId: _selectedLockerId,
              onSelected: (l) {
                final id = _asInt(l['id']);
                if (id != null) _selectLocker(id);
              },
            ),
          const SizedBox(height: 12),
          if (selectedLocker != null) ...[
            _selectedLockerCard(selectedLocker, cells),
            const SizedBox(height: 12),
          ],
          if (_layoutLoading)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator(color: opsPrimary)),
            )
          else if (_layout != null) ...[
            _layoutSummary(),
            const SizedBox(height: 8),
            _statusLegend(),
            const SizedBox(height: 12),
            if (_layout?['landingPad'] == true) _landingPadCard(),
            OpsCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Icon(Icons.grid_view_rounded, size: 16, color: opsPrimary),
                        SizedBox(width: 6),
                        Text(
                          'Sơ đồ vật lý Kiosk (Cột vali XL & Hàng 1: Drone)',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: opsDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildPhysicalCabinet(cells),
                  const SizedBox(height: 10),
                  const OpsBanner(
                    tone: OpsBannerTone.info,
                    icon: Icons.touch_app_outlined,
                    text: 'Chạm vào một ô để báo hỏng, mở khẩn cấp hoặc mở lại ô sau khi sửa.',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _boxHealthCard(),
          ],
        ],
      ),
    );
  }

  /// Dựng sơ đồ vật lý Kiosk đồng bộ với Admin:
  /// Cột trái: khoang đứng XL (#10) cao suốt các hàng
  /// Cột phải: các hàng 1 (Drone), 2, 3...
  /// Bất cứ ô nào Admin thêm mới vào hàng/cột đều tự động render đúng vị trí!
  Widget _buildPhysicalCabinet(List<Map<String, dynamic>> cells) {
    if (cells.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(
          child: Text(
            'Chưa có ô tủ nào được cấu hình.',
            style: TextStyle(color: opsMutedText),
          ),
        ),
      );
    }

    // Lọc ô vali đứng XL
    final xlCells = cells.where((c) {
      final type = (c['cellType'] ?? '').toString().toUpperCase();
      final col = _asInt(c['colIndex']);
      final num = _asInt(c['boxNumber']);
      return type == 'XL' || col == 0 || num == 10;
    }).toList();

    // Các ô thường và Drone
    final standardCells = cells.where((c) => !xlCells.contains(c)).toList();

    // Gom các ô theo rowIndex
    final rowsMap = <int, List<Map<String, dynamic>>>{};
    for (final c in standardCells) {
      final r = _asInt(c['rowIndex']) ?? 1;
      rowsMap.putIfAbsent(r, () => []).add(c);
    }
    final sortedRowKeys = rowsMap.keys.toList()..sort();

    // Nếu không có ô XL thì render các hàng bình thường
    if (xlCells.isEmpty) {
      return Column(
        children: [
          for (final r in sortedRowKeys) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Text(
                    'Hàng $r ${r == 1 ? '(Drone)' : ''}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: opsMutedText,
                    ),
                  ),
                ],
              ),
            ),
            Row(
              children: [
                for (final c in _sortCellsByColumn(rowsMap[r]!))
                  Expanded(child: _cellTile(c)),
              ],
            ),
            const SizedBox(height: 8),
          ],
        ],
      );
    }

    // Khi có ô XL, mô phỏng đúng cấu trúc tủ vật lý Kiosk như bên Admin:
    // Cột trái: Ô XL cao
    // Cột phải: Các hàng 1, 2, 3...
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Cột trái: Ô vali lớn XL
          SizedBox(
            width: 100,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 4),
                  child: Text(
                    'Cột vali XL',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: opsMutedText,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                Expanded(
                  child: Column(
                    children: [
                      for (final xl in xlCells)
                        Expanded(child: _cellTile(xl, isTall: true)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Cột phải: Các hàng ô thường / Drone
          Expanded(
            child: Column(
              children: [
                for (final r in sortedRowKeys) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Text(
                          'Hàng $r ${r == 1 ? '(Drone)' : ''}',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: opsMutedText,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      for (final c in _sortCellsByColumn(rowsMap[r]!)) ...[
                        Expanded(child: _cellTile(c)),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Box-health (GAP 2): trạng thái phần cứng cửa (cabinet báo qua IoT) đặt cạnh
  /// trạng thái logic theo đơn; nổi bật ô "cần chú ý" (cửa mở trên ô không có đồ).
  Widget _boxHealthCard() {
    final health = _boxHealth;
    final attention =
        health.where((b) => b['needsAttention'] == true).toList();
    return OpsCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.sensor_door_outlined, size: 18, color: opsPrimary),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Tình trạng phần cứng ô',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
                ),
              ),
              if (attention.isNotEmpty)
                _MiniPill(
                  icon: Icons.warning_amber_rounded,
                  text: '${attention.length} cần chú ý',
                  color: const Color(0xFFDC2626),
                ),
            ],
          ),
          const SizedBox(height: 10),
          if (health.isEmpty)
            const OpsBanner(
              tone: OpsBannerTone.info,
              icon: Icons.info_outline,
              text:
                  'Chưa có dữ liệu cảm biến cửa cho tủ này (cabinet chưa báo hoặc dịch vụ IoT chưa bật).',
            )
          else ...[
            if (attention.isNotEmpty) ...[
              OpsBanner(
                tone: OpsBannerTone.danger,
                icon: Icons.error_outline,
                text:
                    '${attention.length} ô có cửa đang MỞ nhưng không ở trạng thái "có đồ" — nên kiểm tra (cửa kẹt/quên đóng).',
              ),
              const SizedBox(height: 10),
            ],
            for (final b in health) _boxHealthRow(b),
          ],
        ],
      ),
    );
  }

  Widget _boxHealthRow(Map<String, dynamic> b) {
    final boxNumber = b['boxNumber'];
    final logical = b['logicalStatus']?.toString();
    final hw = b['hwState']?.toString();
    final doorOpen = b['doorOpen'] == true;
    final needsAttention = b['needsAttention'] == true;
    final reported = b['lastReportedAt'];
    final Color accent = needsAttention
        ? const Color(0xFFDC2626)
        : hw == null
            ? const Color(0xFF6B7280)
            : doorOpen
                ? const Color(0xFFD97706)
                : const Color(0xFF16A34A);
    final String doorText = hw == null
        ? 'Chưa có tín hiệu cửa'
        : doorOpen
            ? 'Cửa đang MỞ'
            : 'Cửa đóng';
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: needsAttention ? accent.withValues(alpha: 0.06) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: needsAttention
              ? accent.withValues(alpha: 0.35)
              : const Color(0xFFE2E8F0),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '${boxNumber ?? '?'}',
              style: TextStyle(fontWeight: FontWeight.w800, color: accent),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      doorOpen ? Icons.sensor_door : Icons.meeting_room_outlined,
                      size: 15,
                      color: accent,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      doorText,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: accent,
                      ),
                    ),
                  ],
                ),
                if (reported != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      'Báo lúc ${fmtDateTime(reported)}',
                      style: const TextStyle(fontSize: 11, color: opsMutedText),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          StatusChip(logical),
        ],
      ),
    );
  }

  // ---- #6 Bãi đáp drone trên nóc tủ: hiển thị + đổi trạng thái bảo trì ----
  Widget _landingPadCard() {
    const purple = Color(0xFF7C3AED);
    final status = _layout?['landingPadStatus']?.toString() ?? 'OK';
    final color = _landingPadColor(status);
    return Container(
      padding: const EdgeInsets.all(10),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: purple.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.flight_land, color: purple, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Bãi đáp drone trên nóc · marker ${_layout?['landingMarkerId'] ?? ''}',
                  style: const TextStyle(fontSize: 12, color: purple),
                ),
              ),
              _MiniPill(
                icon: Icons.circle,
                text: _landingPadLabel(status),
                color: color,
              ),
            ],
          ),
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: _landingPadStatusFlow,
              icon: const Icon(Icons.build_outlined, size: 16, color: purple),
              label: const Text('Cập nhật bãi đáp',
                  style: TextStyle(color: purple)),
            ),
          ),
        ],
      ),
    );
  }

  String _landingPadLabel(String status) => switch (status) {
        'FAULT' => 'Lỗi',
        'MAINTENANCE' => 'Đang bảo trì',
        _ => 'Hoạt động',
      };

  Color _landingPadColor(String status) => switch (status) {
        'FAULT' => const Color(0xFFDC2626),
        'MAINTENANCE' => const Color(0xFFD97706),
        _ => const Color(0xFF16A34A),
      };

  /// Dialog đổi trạng thái bãi đáp; bắt nhập lý do khi không phải OK.
  Future<void> _landingPadStatusFlow() async {
    final lockerId = _selectedLockerId;
    if (lockerId == null) return;
    final reasonCtrl = TextEditingController();
    String selected = _layout?['landingPadStatus']?.toString() ?? 'OK';
    const options = ['OK', 'MAINTENANCE', 'FAULT'];

    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Trạng thái bãi đáp drone'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                children: [
                  for (final s in options)
                    ChoiceChip(
                      label: Text(_landingPadLabel(s)),
                      selected: selected == s,
                      onSelected: (_) => setLocal(() => selected = s),
                    ),
                ],
              ),
              if (selected != 'OK') ...[
                const SizedBox(height: 12),
                TextField(
                  controller: reasonCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Lý do (khuyến nghị)',
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
                shape:
                    RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () => Navigator.pop(ctx, selected),
              child: const Text('Lưu'),
            ),
          ],
        ),
      ),
    );
    final reason = reasonCtrl.text.trim();
    reasonCtrl.dispose();
    if (result == null) return;
    await _runCellAction(
      () => _service.updateLandingPadStatus(
        lockerId,
        result,
        reason: reason.isEmpty ? null : reason,
      ),
      'Đã cập nhật bãi đáp drone',
    );
  }

  Widget _selectedLockerCard(
    Map<String, dynamic> locker,
    List<Map<String, dynamic>> cells,
  ) {
    final status = locker['status']?.toString();
    final address = locker['address']?.toString();
    final reserved = _countCells(cells, 'RESERVED');
    final occupied = _countCells(cells, 'OCCUPIED');
    final hasLocation =
        _asDouble(locker['latitude']) != null ||
        (address != null && address.trim().isNotEmpty);

    return OpsCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.inventory_2_outlined, color: opsPrimary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${locker['name'] ?? 'Tủ'} · ${locker['code'] ?? 'N/A'}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    color: opsDark,
                  ),
                ),
              ),
              StatusChip(status),
            ],
          ),
          if (address != null && address.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(
                  Icons.location_on_outlined,
                  size: 15,
                  color: opsMutedText,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    address,
                    style: const TextStyle(fontSize: 12, color: opsMutedText),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _MiniPill(
                icon: Icons.event_available_outlined,
                text: 'Đã giữ chỗ: $reserved',
                color: statusColor('RESERVED'),
              ),
              _MiniPill(
                icon: Icons.inventory_outlined,
                text: 'Có đồ: $occupied',
                color: statusColor('OCCUPIED'),
              ),
              _MiniPill(
                icon: Icons.grid_view_outlined,
                text:
                    'STANDARD ${_countCells(cells, 'STANDARD', field: 'cellType')}',
              ),
              _MiniPill(
                icon: Icons.luggage_outlined,
                text: 'XL ${_countCells(cells, 'XL', field: 'cellType')}',
              ),
              _MiniPill(
                icon: Icons.flight_takeoff,
                text:
                    'DRONE ${_countCells(cells, 'DRONE', field: 'cellType')}',
                color: const Color(0xFF7C3AED),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Kiểm tra trực quan từng ô rồi chỉ báo hỏng khi xác nhận lỗi vật lý tại tủ.',
                  style: const TextStyle(fontSize: 12, color: opsMutedText),
                ),
              ),
              TextButton.icon(
                onPressed: hasLocation ? () => _openDirections(locker) : null,
                icon: const Icon(Icons.map_outlined, size: 16, color: opsPrimary),
                label: const Text('Chỉ đường', style: TextStyle(color: opsPrimary)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _layoutSummary() {
    final total = _layout?['totalCells'] ?? 0;
    final available = _layout?['availableCells'] ?? 0;
    final fault = _layout?['faultCells'] ?? 0;
    return Row(
      children: [
        Expanded(
          child: _MetricCard(
            label: 'Tổng ô',
            value: '$total',
            color: const Color(0xFF2563EB),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _MetricCard(
            label: 'Sẵn sàng',
            value: '$available',
            color: const Color(0xFF16A34A),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _MetricCard(
            label: 'Ô lỗi',
            value: '$fault',
            color: const Color(0xFFDC2626),
          ),
        ),
      ],
    );
  }

  Widget _statusLegend() {
    const items = <String>[
      'AVAILABLE',
      'RESERVED',
      'OCCUPIED',
      'FAULT',
      'OUT_OF_SERVICE',
      'CLEANING',
    ];
    return Wrap(
      spacing: 10,
      runSpacing: 6,
      children: [
        for (final s in items)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: statusColor(s),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(width: 4),
              Text(
                statusLabel(s),
                style: const TextStyle(fontSize: 11, color: opsMutedText),
              ),
            ],
          ),
      ],
    );
  }

  Widget _cellTile(Map<String, dynamic> cell, {bool isTall = false}) {
    final color = statusColor(cell['status'] as String?);
    final type = cell['cellType'] as String? ?? 'STANDARD';
    return Padding(
      padding: const EdgeInsets.all(3),
      child: Material(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => _cellActions(cell),
          child: Container(
            height: isTall ? double.infinity : null,
            padding: EdgeInsets.symmetric(
              vertical: isTall ? 16 : 10,
              horizontal: 6,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: color.withValues(alpha: 0.6),
                width: isTall ? 1.5 : 1.0,
              ),
            ),
            child: Column(
              mainAxisAlignment: isTall
                  ? MainAxisAlignment.center
                  : MainAxisAlignment.start,
              children: [
                if (isTall) ...[
                  Icon(Icons.luggage, size: 28, color: color),
                  const SizedBox(height: 8),
                ],
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '#${cell['boxNumber']}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: color,
                        fontSize: isTall ? 16 : 13,
                      ),
                    ),
                    if (!isTall && type == 'DRONE')
                      const Padding(
                        padding: EdgeInsets.only(left: 2),
                        child: Icon(Icons.flight, size: 12),
                      ),
                    if (!isTall && type == 'XL')
                      const Padding(
                        padding: EdgeInsets.only(left: 2),
                        child: Icon(Icons.luggage, size: 12),
                      ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  statusLabel(cell['status'] as String?),
                  style: TextStyle(
                    fontSize: isTall ? 11 : 10,
                    fontWeight: isTall ? FontWeight.w600 : FontWeight.normal,
                    color: color,
                  ),
                ),
                Text(
                  _cellTypeLabel(type),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: isTall ? 10 : 9,
                    color: opsMutedText,
                  ),
                ),
                if (isTall) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'Khoang đứng XL',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: opsDark,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Bottom sheet hành động cho 1 ô, tuỳ theo trạng thái hiện tại của ô.
  Future<void> _cellActions(Map<String, dynamic> cell) async {
    final boxId = _asInt(cell['id']);
    if (boxId == null) return;
    final status = cell['status'] as String? ?? 'AVAILABLE';
    final color = statusColor(status);
    final reason = cell['faultReason'] as String?;

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

        final actions = <Widget>[];
        switch (status) {
          case 'FAULT':
            actions.add(tile(
              Icons.check_circle,
              'Đã sửa xong — mở lại ô',
              const Color(0xFF16A34A),
              () => _runCellAction(
                () => _service.clearFault(boxId),
                'Ô đã hoạt động lại',
              ),
            ));
            break;
          case 'OUT_OF_SERVICE':
          case 'CLEANING':
            actions.add(tile(
              Icons.restart_alt,
              status == 'CLEANING' ? 'Hoàn tất vệ sinh' : 'Khôi phục ô',
              const Color(0xFF16A34A),
              () => _runCellAction(
                () => _service.returnToService(boxId),
                'Ô đã hoạt động lại',
              ),
            ));
            break;
          case 'OCCUPIED':
          case 'RESERVED':
            actions.add(tile(
              Icons.report_problem,
              'Báo hỏng ô',
              const Color(0xFFDC2626),
              () => _reportFaultFlow(cell),
            ));
            break;
          default: // AVAILABLE và các trạng thái khác
            actions.add(tile(
              Icons.report_problem,
              'Báo hỏng ô',
              const Color(0xFFDC2626),
              () => _reportFaultFlow(cell),
            ));
            actions.add(tile(
              Icons.do_not_disturb_on,
              'Ngưng dùng ô',
              const Color(0xFF6B7280),
              () => _outOfServiceFlow(cell),
            ));
            actions.add(tile(
              Icons.cleaning_services,
              'Đánh dấu đang vệ sinh',
              const Color(0xFF0891B2),
              () => _runCellAction(
                () => _service.cleaning(boxId),
                'Ô đang vệ sinh',
              ),
            ));
        }

        // Luôn có sẵn bất kể trạng thái — override khẩn cấp, luôn ghi audit log.
        actions.add(tile(
          Icons.lock_open,
          'Mở tủ khẩn cấp',
          const Color(0xFFEA580C),
          () => _forceOpenFlow(boxId),
        ));

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
                    Container(
                      width: 44,
                      height: 44,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(
                        '#${cell['boxNumber']}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: color,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Ô #${cell['boxNumber']} · ${_cellTypeLabel(cell['cellType'] as String?)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                              color: opsDark,
                            ),
                          ),
                          Text(
                            'Trạng thái: ${statusLabel(status)}'
                            '${(reason != null && reason.isNotEmpty) ? ' · $reason' : ''}',
                            style: const TextStyle(fontSize: 12, color: opsMutedText),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ...actions,
              ],
            ),
          ),
        );
      },
    );
  }

  /// Mở tủ khẩn cấp không cần PIN khách — luôn xác nhận trước vì hành động
  /// được ghi vào audit log (credential MASTER) phía backend.
  Future<void> _forceOpenFlow(int boxId) async {
    final reasons = [
      'Khách hàng quên mã PIN / không liên lạc được',
      'Cửa tủ bị kẹt cơ học / lỗi chốt từ',
      'Kiểm tra định kỳ theo yêu cầu Ban Quản Lý',
      'Sự cố khẩn cấp / nghi ngờ rò rỉ hoặc dị vật',
    ];
    String selectedReason = reasons.first;
    XFile? incidentPhoto;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.lock_open, color: Color(0xFFEA580C), size: 24),
              SizedBox(width: 8),
              Expanded(
                child: Text('Mở tủ khẩn cấp (Master)', style: TextStyle(fontSize: 16)),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Tủ sẽ được mở qua lệnh Master MQTT. Hành động này sẽ được lưu vào hệ thống Audit Log bảo mật.',
                  style: TextStyle(fontSize: 12.5, color: opsMutedText),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Lý do can thiệp:',
                  style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                DropdownButtonFormField<String>(
                  initialValue: selectedReason,
                  isExpanded: true,
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  items: reasons
                      .map((r) => DropdownMenuItem(
                            value: r,
                            child: Text(r, style: const TextStyle(fontSize: 12)),
                          ))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) setLocal(() => selectedReason = val);
                  },
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    OutlinedButton.icon(
                      onPressed: () async {
                        final picker = ImagePicker();
                        final img = await picker.pickImage(
                          source: ImageSource.camera,
                          maxWidth: 1000,
                          maxHeight: 1000,
                        );
                        if (img != null) {
                          setLocal(() => incidentPhoto = img);
                        }
                      },
                      icon: Icon(
                        incidentPhoto != null ? Icons.check : Icons.camera_alt_outlined,
                        size: 16,
                        color: incidentPhoto != null ? const Color(0xFF16A34A) : opsPrimary,
                      ),
                      label: Text(
                        incidentPhoto != null ? 'Đã chụp hiện trường' : 'Chụp ảnh hiện trường',
                        style: TextStyle(
                          fontSize: 12,
                          color: incidentPhoto != null ? const Color(0xFF16A34A) : opsPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEA580C),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Xác nhận mở'),
            ),
          ],
        ),
      ),
    );
    if (ok != true) return;
    await _runCellAction(() => _service.forceOpenBox(boxId), 'Đã gửi lệnh mở tủ khẩn cấp (Lý do: $selectedReason)');
  }

  /// Chạy 1 thao tác đổi trạng thái ô + báo kết quả + reload danh sách.
  Future<void> _runCellAction(
    Future<dynamic> Function() action,
    String successMsg,
  ) async {
    try {
      await action();
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(successMsg)));
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

  /// Dialog nhập lý do rồi báo hỏng ô.
  Future<void> _reportFaultFlow(Map<String, dynamic> cell) async {
    final boxId = _asInt(cell['id']);
    if (boxId == null) return;
    final reasonCtrl = TextEditingController(text: 'Hỏng khóa');
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Báo hỏng ô #${cell['boxNumber']}'),
        content: TextField(
          controller: reasonCtrl,
          decoration: const InputDecoration(labelText: 'Lý do hỏng'),
          minLines: 1,
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Báo hỏng'),
          ),
        ],
      ),
    );
    final reason = reasonCtrl.text.trim();
    reasonCtrl.dispose();
    if (ok != true) return;
    if (reason.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vui lòng nhập lý do hỏng.')),
        );
      }
      return;
    }
    await _runCellAction(
      () => _service.reportFault(boxId, reason),
      'Đã báo hỏng ô',
    );
  }

  /// Dialog xác nhận (lý do tuỳ chọn) rồi ngưng dùng ô.
  Future<void> _outOfServiceFlow(Map<String, dynamic> cell) async {
    final boxId = _asInt(cell['id']);
    if (boxId == null) return;
    final reasonCtrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Ngưng dùng ô #${cell['boxNumber']}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Ô sẽ bị loại khỏi phân phối cho khách tới khi được khôi phục.',
              style: TextStyle(fontSize: 12, color: opsMutedText),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: reasonCtrl,
              decoration: const InputDecoration(labelText: 'Lý do (tùy chọn)'),
              minLines: 1,
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6B7280),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Ngưng dùng'),
          ),
        ],
      ),
    );
    final reason = reasonCtrl.text.trim();
    reasonCtrl.dispose();
    if (ok != true) return;
    await _runCellAction(
      () => _service.outOfService(boxId, reason: reason.isEmpty ? null : reason),
      'Đã ngưng dùng ô',
    );
  }

  /// Mở nhật ký xử lý (work-log) của 1 phiếu để xem + thêm ghi chú tiến trình.
  Future<void> _reportLogSheet(Map<String, dynamic> report) async {
    final reportId = _asInt(report['id']);
    if (reportId == null) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _RepairLogSheet(
        reportId: reportId,
        service: _service,
        title: '#${report['id']} · ${report['title'] ?? ''}',
      ),
    );
    if (mounted) await _load();
  }

  /// Cảnh báo phần cứng toàn cục (GAP 2): mọi ô cửa-mở-bất-thường trên tất cả
  /// tủ, để KTV thấy ngay ở đầu tab Sự cố mà không phải chọn từng tủ. Ẩn khi
  /// không có ô nào bất thường.
  Widget _boxAnomaliesSection() {
    final anomalies = _anomalies;
    if (anomalies.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const OpsSectionLabel(
          'Cảnh báo phần cứng (cửa mở bất thường)',
          icon: Icons.sensor_door_outlined,
        ),
        OpsBanner(
          tone: OpsBannerTone.danger,
          icon: Icons.error_outline,
          text:
              '${anomalies.length} ô có cửa đang MỞ nhưng không có đồ — nên kiểm tra (cửa kẹt/quên đóng).',
        ),
        const SizedBox(height: 10),
        for (final a in anomalies)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: OpsCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.sensor_door, color: Color(0xFFD97706)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${a['lockerName'] ?? 'Tủ ${a['lockerId']}'} · Ô #${a['boxNumber']} (${a['cellType']})',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      StatusChip(a['logicalStatus']?.toString()),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded,
                          size: 15, color: Color(0xFFD97706)),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          a['lastReportedAt'] != null
                              ? 'Cửa MỞ · báo lúc ${fmtDateTime(a['lastReportedAt'])}'
                              : 'Cửa MỞ',
                          style: const TextStyle(
                              fontSize: 12.5, color: opsMutedText),
                        ),
                      ),
                    ],
                  ),
                  if (a['lockerLatitude'] != null ||
                      a['lockerAddress'] != null) ...[
                    const SizedBox(height: 4),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: () => _openDirections(a),
                        icon: const Icon(Icons.directions_outlined,
                            size: 16, color: opsPrimary),
                        label: const Text('Chỉ đường',
                            style: TextStyle(color: opsPrimary)),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildQueue() {
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          _buildShiftSummary(),
          const SizedBox(height: 16),
          _boxAnomaliesSection(),
          if (_faults.isNotEmpty) ...[
            const OpsSectionLabel('Ô đang lỗi vật lý', icon: Icons.warning_amber_rounded),
            for (final f in _faults)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: OpsCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.warning_amber,
                            color: Color(0xFFDC2626),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '${f['lockerName'] ?? 'Tủ ${f['lockerId']}'} · Ô #${f['boxNumber']} (${f['cellType']})',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: opsDark,
                              ),
                            ),
                          ),
                          const StatusChip('FAULT'),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        f['faultReason'] as String? ?? 'Không rõ lý do',
                        style: const TextStyle(fontSize: 12, color: opsMutedText),
                      ),
                      if ((f['lockerAddress'] ?? '').toString().isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.location_on_outlined,
                                size: 15,
                                color: opsMutedText,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  f['lockerAddress'].toString(),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: opsMutedText,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 8),
                      Wrap(
                        alignment: WrapAlignment.end,
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          TextButton.icon(
                            onPressed: () => _openDirections(f),
                            icon: const Icon(Icons.map_outlined, size: 16, color: opsPrimary),
                            label: const Text('Chỉ đường', style: TextStyle(color: opsPrimary)),
                          ),
                          TextButton(
                            onPressed: () => _run(
                              () => _service.clearFault(f['boxId'] as int),
                              'Ô đã hoạt động lại',
                            ),
                            child: const Text('Đã sửa', style: TextStyle(color: Color(0xFF16A34A))),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 8),
          ],
          const OpsSectionLabel('Phiếu sự cố', icon: Icons.assignment_outlined),
          if (_reports.isEmpty)
            const OpsEmptyState(
              icon: Icons.task_alt_outlined,
              title: 'Không có phiếu nào',
              subtitle: 'Mọi sự cố đã được xử lý hết.',
            ),
          for (final r in _reports) _reportCard(r),
        ],
      ),
    );
  }

  Widget _buildShiftSummary() {
    final open = _reports.where((r) => r['status'] == 'OPEN').length;
    final inProgress = _reports
        .where((r) => r['status'] == 'IN_PROGRESS')
        .length;
    final mineActive = _myReports
        .where((r) => r['status'] != 'RESOLVED')
        .length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const OpsSectionLabel('Tổng quan ca trực', icon: Icons.dashboard_outlined),
        Row(
          children: [
            Expanded(
              child: _MetricCard(
                label: 'Ô lỗi',
                value: '${_faults.length}',
                color: const Color(0xFFDC2626),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _MetricCard(
                label: 'Phiếu mới',
                value: '$open',
                color: const Color(0xFFEA580C),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _MetricCard(
                label: 'Đang xử lý',
                value: '$inProgress',
                color: const Color(0xFFD97706),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _MetricCard(
                label: 'Của tôi',
                value: '$mineActive',
                color: const Color(0xFF2563EB),
              ),
            ),
          ],
        ),
        if ((_ratingAverage?['count'] as int?) != null &&
            (_ratingAverage!['count'] as int) > 0) ...[
          const SizedBox(height: 8),
          OpsBanner(
            text:
                'Điểm đánh giá của bạn: ${_ratingAverage!['average']}/5 (${_ratingAverage!['count']} lượt)',
            icon: Icons.star_rate_rounded,
            tone: OpsBannerTone.success,
          ),
        ],
        if (_myPerformance != null) ...[
          const SizedBox(height: 10),
          _buildSlaPenaltyCard(_myPerformance!),
        ],
        const SizedBox(height: 10),
        const OpsBanner(
          text:
              'Quy trình chuẩn: kiểm tra vị trí tủ, nhận phiếu, tới đúng ô, chụp ảnh nghiệm thu rồi hoàn tất để clear fault.',
          icon: Icons.engineering,
          tone: OpsBannerTone.info,
        ),
      ],
    );
  }

  Widget _buildSlaPenaltyCard(Map<String, dynamic> perf) {
    final penaltyLevel = perf['penaltyLevel']?.toString() ?? 'NORMAL';
    final overdue = (perf['overdue'] as num?)?.toInt() ?? 0;
    final resolved = (perf['resolved'] as num?)?.toInt() ?? 0;
    final inProgress = (perf['inProgress'] as num?)?.toInt() ?? 0;
    final reason = perf['penaltyReason']?.toString() ?? '';

    Color bg;
    Color border;
    Color textColor;
    IconData icon;
    String title;
    String badgeText;

    switch (penaltyLevel) {
      case 'RESTRICTED':
        bg = const Color(0xFFFEF2F2);
        border = const Color(0xFFFCA5A5);
        textColor = const Color(0xFF991B1B);
        icon = Icons.block;
        title = 'Đang bị hạn chế nhận việc mới';
        badgeText = 'HẠN CHẾ (Mức 2)';
        break;
      case 'WARNING':
        bg = const Color(0xFFFFFBEB);
        border = const Color(0xFFFDE68A);
        textColor = const Color(0xFF92400E);
        icon = Icons.warning_amber_rounded;
        title = 'Cảnh báo vi phạm thời gian SLA';
        badgeText = 'CẢNH BÁO (Mức 1)';
        break;
      case 'SUSPENDED':
        bg = const Color(0xFF450A0A);
        border = const Color(0xFFDC2626);
        textColor = Colors.white;
        icon = Icons.cancel;
        title = 'Tài khoản trong diện đình chỉ';
        badgeText = 'ĐÌNH CHỈ (Mức 3)';
        break;
      default:
        bg = const Color(0xFFF0FDF4);
        border = const Color(0xFFBBF7D0);
        textColor = const Color(0xFF166534);
        icon = Icons.verified_user_outlined;
        title = 'Hồ sơ kỹ thuật viên tốt';
        badgeText = 'BÌNH THƯỜNG';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: textColor, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13.5,
                    color: textColor,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: textColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  badgeText,
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: textColor,
                  ),
                ),
              ),
            ],
          ),
          if (reason.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              reason,
              style: TextStyle(fontSize: 12, color: textColor.withValues(alpha: 0.9)),
            ),
          ],
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                'Đã hoàn thành: $resolved',
                style: TextStyle(fontSize: 11.5, color: textColor.withValues(alpha: 0.8)),
              ),
              const SizedBox(width: 12),
              Text(
                'Đang làm: $inProgress',
                style: TextStyle(fontSize: 11.5, color: textColor.withValues(alpha: 0.8)),
              ),
              const SizedBox(width: 12),
              Text(
                'Quá hạn SLA: $overdue',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: overdue > 0 ? FontWeight.bold : FontWeight.normal,
                  color: overdue > 0 ? const Color(0xFFDC2626) : textColor.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMine() {
    final active = _myReports.where((r) => r['status'] != 'RESOLVED').toList();
    final done = _myReports.where((r) => r['status'] == 'RESOLVED').toList();
    final isRestricted = _myPerformance?['penaltyLevel'] == 'RESTRICTED';
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          if (isRestricted) ...[
            OpsBanner(
              tone: OpsBannerTone.danger,
              icon: Icons.block,
              text:
                  'Tài khoản đang bị giới hạn nhận việc mới do có phiếu quá hạn. '
                  'Vui lòng ưu tiên nghiệm thu và hoàn tất các phiếu dưới đây.',
            ),
            const SizedBox(height: 12),
          ],
          if (active.isEmpty && done.isEmpty)
            const OpsEmptyState(
              icon: Icons.engineering_outlined,
              title: 'Bạn chưa nhận việc nào',
              subtitle: 'Nhận phiếu từ tab "Sự cố" để bắt đầu xử lý.',
            ),
          for (final r in active) _reportCard(r),
          if (done.isNotEmpty) ...[
            const SizedBox(height: 8),
            const OpsSectionLabel('Đã hoàn thành', icon: Icons.check_circle_outline),
            for (final r in done) _reportCard(r),
          ],
        ],
      ),
    );
  }

  // ---- Tab 4: bảo trì định kỳ (preventive) — chỉ lịch của tủ ----
  Widget _buildSchedules() {
    final due = _schedules.where((s) => s['due'] == true).toList();
    final upcoming = _schedules.where((s) => s['due'] != true).toList();
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          const OpsBanner(
            tone: OpsBannerTone.info,
            icon: Icons.event_repeat,
            text: 'Lịch kiểm tra định kỳ do quản trị tạo. Khi đến hạn, hãy kiểm '
                'tra tủ rồi bấm "Đã kiểm tra" để dời sang mốc kế tiếp.',
          ),
          const SizedBox(height: 12),
          if (_schedules.isEmpty)
            const OpsEmptyState(
              icon: Icons.event_available_outlined,
              title: 'Chưa có lịch bảo trì định kỳ nào',
            ),
          if (due.isNotEmpty) ...[
            const OpsSectionLabel('Đến hạn', icon: Icons.warning_amber_rounded),
            for (final s in due) _scheduleCard(s, due: true),
            const SizedBox(height: 8),
          ],
          if (upcoming.isNotEmpty) ...[
            const OpsSectionLabel('Sắp tới', icon: Icons.schedule_outlined),
            for (final s in upcoming) _scheduleCard(s, due: false),
          ],
        ],
      ),
    );
  }

  Widget _scheduleCard(Map<String, dynamic> s, {required bool due}) {
    final isDrone = s['droneUnitId'] != null;
    final targetLabel = isDrone 
        ? 'Drone ${s['droneCode'] ?? s['droneUnitId']}' 
        : (s['lockerName'] ?? 'Tủ ${s['lockerId']}');
    final targetIcon = isDrone ? Icons.flight_takeoff : Icons.inventory_2_outlined;
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
                _MiniPill(icon: targetIcon, text: targetLabel),
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
    final d = _parseDate(value);
    if (d == null) return null;
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(d.day)}/${two(d.month)}/${d.year}';
  }

  // ---- Tab 5: thiết bị IoT (router/controller gắn trên tủ) ----
  Widget _buildIotDevices() {
    if (_devicesError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: OpsBanner(
            tone: OpsBannerTone.warning,
            icon: Icons.construction_outlined,
            text: _devicesError!,
          ),
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          const OpsSectionLabel(
            'Thiết bị IoT',
            icon: Icons.device_hub_outlined,
          ),
          if (_devices.isEmpty)
            const OpsEmptyState(
              icon: Icons.device_hub_outlined,
              title: 'Không có thiết bị nào',
              subtitle: 'Chưa có thiết bị IoT nào được phân công.',
            )
          else
            for (final device in _devices)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: OpsCard(
                  onTap: () => _deviceSheet(device),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color:
                              _deviceStatusColor(device['status'] as String?)
                                  .withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.router_outlined,
                          color: _deviceStatusColor(
                            device['status'] as String?,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${device['name'] ?? 'Thiết bị #${device['id']}'}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 14,
                                color: opsDark,
                              ),
                            ),
                            if ((device['model'] ?? '').toString().isNotEmpty)
                              Text(
                                device['model'].toString(),
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: opsMutedText,
                                ),
                              ),
                          ],
                        ),
                      ),
                      _DeviceStatusBadge(device['status'] as String?),
                    ],
                  ),
                ),
              ),
          const SizedBox(height: 8),
          const OpsBanner(
            tone: OpsBannerTone.info,
            icon: Icons.touch_app_outlined,
            text: 'Chạm vào thiết bị để xem chi tiết, nhật ký và điều khiển.',
          ),
        ],
      ),
    );
  }

  /// Bottom sheet chi tiết + nhật ký + điều khiển (restart / đổi trạng thái)
  /// cho một thiết bị IoT.
  Future<void> _deviceSheet(Map<String, dynamic> device) async {
    final id = _asInt(device['id']);
    if (id == null) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (_) => _IotDeviceSheet(deviceId: id, service: _service),
    );
    if (mounted) await _load();
  }

  Color _deviceStatusColor(String? status) => switch (status) {
        'ONLINE' => const Color(0xFF16A34A),
        'OFFLINE' => const Color(0xFF6B7280),
        'ERROR' => const Color(0xFFEA580C),
        _ => opsMutedText,
      };

  (String, List<String>) _extractUserPhotosAndClean(
    dynamic desc,
    dynamic photoField,
  ) {
    final rawDesc = (desc ?? '').toString();
    final urls = <String>[];

    if (photoField is List) {
      for (final item in photoField) {
        final s = item?.toString().trim() ?? '';
        if (s.startsWith('http') && !urls.contains(s)) urls.add(s);
      }
    } else if (photoField is String && photoField.trim().startsWith('http')) {
      urls.add(photoField.trim());
    }

    final urlRegex = RegExp(r'https?://[^\s)\]"]+');
    for (final m in urlRegex.allMatches(rawDesc)) {
      var u = m.group(0)!;
      u = u.replaceAll(RegExp(r'[,.;:]$'), '');
      if (!urls.contains(u)) urls.add(u);
    }

    var cleaned = rawDesc
        .replaceAll(
          RegExp(r'\n*Ảnh minh chứng.*$', multiLine: true, caseSensitive: false),
          '',
        )
        .replaceAll(urlRegex, '')
        .trim();

    return (cleaned, urls);
  }

  void _viewFullPhoto(String url, String title) {
    showDialog<void>(
      context: context,
      builder: (dialogCtx) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: const EdgeInsets.all(12),
        child: Stack(
          children: [
            Center(
              child: InteractiveViewer(
                child: Image.network(
                  url,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Center(
                    child: Text(
                      'Không tải được ảnh',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 10,
              left: 14,
              child: Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
            Positioned(
              top: 4,
              right: 4,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.pop(dialogCtx),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _reportCard(Map<String, dynamic> r) {
    final status = r['status'] as String? ?? '';
    final assignedToMe = '${r['assignedToUserId'] ?? ''}' == (_myUserId ?? '');
    final lockerLabel = r['lockerName'] ?? 'Tủ ${r['lockerId']}';
    final boxLabel = r['boxNumber'] ?? r['boxId'];
    final createdAt = _parseDate(r['createdAt']);
    final ageLabel = createdAt == null ? null : _ageLabel(createdAt);
    final (cleanedDesc, userPhotos) = _extractUserPhotosAndClean(
      r['description'],
      r['photoUrls'] ?? r['photos'],
    );

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
                    '#${r['id']} · ${r['title'] ?? ''}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: opsDark,
                    ),
                  ),
                ),
                StatusChip(status),
              ],
            ),
            if (cleanedDesc.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                cleanedDesc,
                style: const TextStyle(fontSize: 12, color: opsMutedText),
              ),
            ],
            if (userPhotos.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(
                    Icons.photo_library_outlined,
                    size: 14,
                    color: Color(0xFFE11D48),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Ảnh từ User (${userPhotos.length} ảnh):',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFE11D48),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              SizedBox(
                height: 72,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: userPhotos.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, idx) {
                    final photoUrl = userPhotos[idx];
                    return GestureDetector(
                      onTap: () => _viewFullPhoto(
                        photoUrl,
                        'Ảnh từ User (#${idx + 1})',
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            border: Border.all(color: const Color(0xFFFDA4AF)),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Image.network(
                            photoUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Center(
                              child: Icon(
                                Icons.broken_image_outlined,
                                size: 24,
                                color: opsMutedText,
                              ),
                            ),
                            loadingBuilder: (_, child, prog) {
                              if (prog == null) return child;
                              return const Center(
                                child: SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                _MiniPill(
                  icon: Icons.inventory_2_outlined,
                  text:
                      '$lockerLabel${boxLabel != null ? ' · ô $boxLabel' : ''}',
                ),
                if (createdAt != null)
                  _MiniPill(
                    icon: Icons.access_time,
                    text: _formatFullDateTime(createdAt),
                  ),
                if ((r['reporterName'] ?? '').toString().isNotEmpty ||
                    (r['reporterPhone'] ?? '').toString().isNotEmpty)
                  _MiniPill(
                    icon: Icons.person_outline,
                    text: [
                      if ((r['reporterName'] ?? '').toString().isNotEmpty)
                        r['reporterName'].toString(),
                      if ((r['reporterPhone'] ?? '').toString().isNotEmpty)
                        r['reporterPhone'].toString(),
                    ].join(' · '),
                  ),
                if ((r['cellType'] ?? '').toString().isNotEmpty)
                  _MiniPill(
                    icon: Icons.grid_view_outlined,
                    text: r['cellType'].toString(),
                  ),
                if (r['overdue'] == true)
                  const _MiniPill(
                    icon: Icons.warning_amber_rounded,
                    text: 'Quá hạn SLA',
                    color: Color(0xFFDC2626),
                  ),
                if (ageLabel != null)
                  _MiniPill(
                    icon: Icons.schedule,
                    text: ageLabel,
                    color: r['overdue'] == true
                        ? const Color(0xFFDC2626)
                        : _slaColor(createdAt!),
                  ),
                if (r['assignedToUserId'] != null)
                  _MiniPill(
                    icon: Icons.engineering_outlined,
                    text:
                        'KTV #${r['assignedToUserId']}${assignedToMe ? ' (bạn)' : ''}',
                  ),
              ],
            ),
            if ((r['lockerAddress'] ?? '').toString().isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(
                    Icons.location_on_outlined,
                    size: 15,
                    color: opsMutedText,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      r['lockerAddress'].toString(),
                      style: const TextStyle(fontSize: 12, color: opsMutedText),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 8),
            Wrap(
              alignment: WrapAlignment.end,
              spacing: 8,
              runSpacing: 4,
              children: [
                TextButton.icon(
                  onPressed: () => _openDirections(r),
                  icon: const Icon(Icons.map_outlined, size: 16, color: opsPrimary),
                  label: const Text('Chỉ đường', style: TextStyle(color: opsPrimary)),
                ),
                TextButton.icon(
                  onPressed: () => _reportLogSheet(r),
                  icon: const Icon(Icons.history_edu_outlined, size: 16, color: opsPrimary),
                  label: const Text('Nhật ký', style: TextStyle(color: opsPrimary)),
                ),
                if (status == 'OPEN')
                  TextButton.icon(
                    onPressed: () => _run(
                      () => _service.claimReport(r['id'] as int),
                      'Đã nhận việc',
                    ),
                    icon: const Icon(Icons.pan_tool_alt, size: 16, color: opsPrimary),
                    label: const Text('Nhận việc', style: TextStyle(color: opsPrimary)),
                  ),
                if (status == 'IN_PROGRESS')
                  ElevatedButton.icon(
                    onPressed: () => _confirmResolveReport(r),
                    icon: const Icon(Icons.check, size: 16),
                    label: const Text('Hoàn tất'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF16A34A),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
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

  Future<void> _confirmResolveReport(Map<String, dynamic> report) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _ResolveVerificationSheet(
        report: report,
        service: _service,
        onResolved: _load,
      ),
    );
  }

  DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse('$value')?.toLocal();
  }

  String _formatFullDateTime(DateTime dt) {
    final d = dt.day.toString().padLeft(2, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final y = dt.year.toString().padLeft(4, '0');
    final hh = dt.hour.toString().padLeft(2, '0');
    final mm = dt.minute.toString().padLeft(2, '0');
    final ss = dt.second.toString().padLeft(2, '0');
    return '$hh:$mm:$ss $d/$m/$y';
  }

  String _ageLabel(DateTime createdAt) {
    final age = DateTime.now().difference(createdAt);
    if (age.inDays > 0) return 'Mở ${age.inDays} ngày';
    if (age.inHours > 0) return 'Mở ${age.inHours} giờ';
    if (age.inMinutes > 0) return 'Mở ${age.inMinutes} phút';
    return 'Vừa mở';
  }

  Color _slaColor(DateTime createdAt) {
    final age = DateTime.now().difference(createdAt);
    if (age.inHours >= 4) return const Color(0xFFDC2626);
    if (age.inHours >= 1) return const Color(0xFFD97706);
    return opsPrimary;
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }
}

/// Bottom sheet chi tiết thiết bị IoT: thông tin, nhật ký audit và điều khiển
/// (đổi trạng thái ONLINE/OFFLINE/ERROR, restart).
class _IotDeviceSheet extends StatefulWidget {
  const _IotDeviceSheet({required this.deviceId, required this.service});

  final int deviceId;
  final LockerOpsService service;

  @override
  State<_IotDeviceSheet> createState() => _IotDeviceSheetState();
}

class _IotDeviceSheetState extends State<_IotDeviceSheet> {
  Map<String, dynamic>? _device;
  List<Map<String, dynamic>> _logs = const [];
  bool _loading = true;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final detail = await widget.service.techDeviceDetail(widget.deviceId);
      final logs = await widget.service.techDeviceLogs(widget.deviceId);
      if (!mounted) return;
      setState(() {
        _device = detail;
        _logs = logs;
        _error = null;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = LockerOpsService.errorMessage(e);
        _loading = false;
      });
    }
  }

  Future<void> _changeStatus(String newStatus) async {
    setState(() => _busy = true);
    try {
      await widget.service.techUpdateStatus(widget.deviceId, newStatus);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Đã cập nhật trạng thái: $newStatus')),
        );
      }
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(LockerOpsService.errorMessage(e))),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _restart() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Restart thiết bị'),
        content: Text(
          'Thiết bị "${_device?['name'] ?? '#${widget.deviceId}'}" sẽ được restart. Xác nhận tiếp tục?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Restart'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    setState(() => _busy = true);
    try {
      await widget.service.techRestartDevice(widget.deviceId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã gửi lệnh restart thiết bị')),
        );
      }
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(LockerOpsService.errorMessage(e))),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _fieldLabel(String key) => switch (key) {
        'model' => 'Model',
        'firmwareVersion' => 'Firmware',
        'ipAddress' => 'IP',
        'macAddress' => 'MAC',
        'location' => 'Vị trí',
        'lastSeen' => 'Lần cuối thấy',
        _ => key,
      };

  String _fmtDate(dynamic value) {
    final d = DateTime.tryParse('$value')?.toLocal();
    if (d == null) return '';
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(d.hour)}:${two(d.minute)} ${two(d.day)}/${two(d.month)}/${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    final device = _device;
    final currentStatus = (device?['status'] as String?) ?? 'ONLINE';
    const statuses = ['ONLINE', 'OFFLINE', 'ERROR'];
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
        child: _loading
            ? const Padding(
                padding: EdgeInsets.all(24),
                child: Center(
                  child: CircularProgressIndicator(color: opsPrimary),
                ),
              )
            : _error != null
                ? Padding(
                    padding: const EdgeInsets.all(12),
                    child: OpsBanner(
                      tone: OpsBannerTone.warning,
                      icon: Icons.construction_outlined,
                      text: _error!,
                    ),
                  )
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.router_outlined, color: opsPrimary),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              '${device?['name'] ?? 'Thiết bị #${widget.deviceId}'}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 15,
                                color: opsDark,
                              ),
                            ),
                          ),
                          _DeviceStatusBadge(device?['status'] as String?),
                        ],
                      ),
                      const SizedBox(height: 12),
                      for (final field in [
                        'model',
                        'firmwareVersion',
                        'ipAddress',
                        'macAddress',
                        'location',
                        'lastSeen',
                      ])
                        if (device?[field] != null &&
                            '${device?[field]}'.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Row(
                              children: [
                                Text(
                                  _fieldLabel(field),
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: opsMutedText,
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  '${device?[field]}',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: opsDark,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      const SizedBox(height: 8),
                      const Text(
                        'Thay đổi trạng thái',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: opsDark,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 10,
                        children: [
                          for (final s in statuses)
                            ChoiceChip(
                              label: Text(s),
                              selected: currentStatus == s,
                              onSelected: _busy
                                  ? null
                                  : (selected) {
                                      if (selected) _changeStatus(s);
                                    },
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _busy ? null : _restart,
                          icon: _busy
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.restart_alt, size: 18),
                          label: const Text('Restart thiết bị'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFDC2626),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      const OpsSectionLabel(
                        'Nhật ký hoạt động',
                        icon: Icons.history_edu_outlined,
                      ),
                      if (_logs.isEmpty)
                        const Padding(
                          padding: EdgeInsets.only(bottom: 8),
                          child: Text(
                            'Chưa có nhật ký.',
                            style: TextStyle(
                              fontSize: 12,
                              color: opsMutedText,
                            ),
                          ),
                        )
                      else
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxHeight: 220),
                          child: ListView(
                            shrinkWrap: true,
                            children: [
                              for (final log in _logs)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: opsSurface,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: opsBorder),
                                    ),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Icon(
                                          Icons.circle,
                                          size: 8,
                                          color: opsPrimary,
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                '${log['message'] ?? log['event'] ?? log['action'] ?? ''}',
                                                style: const TextStyle(
                                                  fontSize: 13,
                                                  color: opsDark,
                                                ),
                                              ),
                                              if (log['createdAt'] != null)
                                                Text(
                                                  _fmtDate(log['createdAt']),
                                                  style: const TextStyle(
                                                    fontSize: 11,
                                                    color: opsMutedText,
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
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

/// Bottom sheet xem + thêm nhật ký xử lý (work-log) cho một phiếu bảo trì.
class _RepairLogSheet extends StatefulWidget {
  const _RepairLogSheet({
    required this.reportId,
    required this.service,
    required this.title,
  });

  final int reportId;
  final LockerOpsService service;
  final String title;

  @override
  State<_RepairLogSheet> createState() => _RepairLogSheetState();
}

class _RepairLogSheetState extends State<_RepairLogSheet> {
  final _noteCtrl = TextEditingController();
  final _picker = ImagePicker();
  List<XFile> _attachedPhotos = [];
  List<Map<String, dynamic>> _logs = const [];
  bool _loading = true;
  bool _sending = false;

  final _quickChips = const [
    '📸 Kiểm tra hiện trường',
    '🔧 Thay thế linh kiện',
    '⚡ Kiểm tra bo mạch nguồn',
    '🧹 Vệ sinh ô tủ sạch sẽ',
    '🚪 Cân chỉnh chốt & then',
  ];

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
      final logs = await widget.service.reportLogs(widget.reportId);
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

  /// Chụp 1 ảnh bằng camera
  Future<void> _pickCamera() async {
    try {
      final picked = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 80,
      );
      if (picked != null && mounted) {
        setState(() => _attachedPhotos.add(picked));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Không thể chụp ảnh: $e')),
        );
      }
    }
  }

  /// Chọn nhiều ảnh từ thư viện
  Future<void> _pickGalleryMulti() async {
    try {
      final picked = await _picker.pickMultiImage(
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 80,
      );
      if (picked.isNotEmpty && mounted) {
        setState(() => _attachedPhotos.addAll(picked));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Không thể chọn ảnh: $e')),
        );
      }
    }
  }

  void _showImagePickerOptions() {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined, color: opsPrimary),
              title: const Text('Chụp ảnh từ máy ảnh'),
              onTap: () {
                Navigator.pop(ctx);
                _pickCamera();
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined, color: opsPrimary),
              title: const Text('Chọn nhiều ảnh từ thư viện'),
              onTap: () {
                Navigator.pop(ctx);
                _pickGalleryMulti();
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _add() async {
    final note = _noteCtrl.text.trim();
    if (note.isEmpty && _attachedPhotos.isEmpty) return;
    setState(() => _sending = true);
    try {
      String fullNote = note;
      if (_attachedPhotos.isNotEmpty) {
        final photoList = _attachedPhotos
            .asMap()
            .entries
            .map((e) => 'Ảnh ${e.key + 1}: ${e.value.name}')
            .join(', ');
        fullNote = note.isNotEmpty
            ? '$note\n[Ảnh hiện trường: $photoList]'
            : '[Ảnh hiện trường: $photoList]';
      }
      await widget.service.addReportLog(widget.reportId, fullNote);
      _noteCtrl.clear();
      setState(() => _attachedPhotos = []);
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
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
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
                      'Nhật ký xử lý · ${widget.title}',
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
                        final noteText = '${log['note'] ?? ''}';
                        final hasPhoto = noteText.contains('[Ảnh') ||
                            noteText.contains('.jpg') ||
                            noteText.contains('.png');
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
                              Text(noteText),
                              if (hasPhoto) ...[
                                const SizedBox(height: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: opsPrimary.withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.photo_camera,
                                        size: 13,
                                        color: opsPrimary,
                                      ),
                                      SizedBox(width: 4),
                                      Text(
                                        'Đính kèm ảnh hiện trường',
                                        style: TextStyle(
                                          fontSize: 10.5,
                                          fontWeight: FontWeight.w600,
                                          color: opsPrimary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
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
            // Quick suggestions
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Row(
                children: [
                  for (final tag in _quickChips)
                    Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: ActionChip(
                        label: Text(tag, style: const TextStyle(fontSize: 11)),
                        padding: EdgeInsets.zero,
                        visualDensity: VisualDensity.compact,
                        onPressed: () {
                          final cur = _noteCtrl.text.trim();
                          _noteCtrl.text = cur.isEmpty ? tag : '$cur, $tag';
                        },
                      ),
                    ),
                ],
              ),
            ),
            if (_attachedPhotos.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.photo_library_outlined, size: 14, color: opsPrimary),
                        const SizedBox(width: 4),
                        Text(
                          '${_attachedPhotos.length} ảnh đính kèm',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: opsPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    SizedBox(
                      height: 68,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _attachedPhotos.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 6),
                        itemBuilder: (_, idx) => Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.file(
                                File(_attachedPhotos[idx].path),
                                width: 68,
                                height: 68,
                                fit: BoxFit.cover,
                              ),
                            ),
                            Positioned(
                              top: 2,
                              right: 2,
                              child: GestureDetector(
                                onTap: () => setState(() => _attachedPhotos.removeAt(idx)),
                                child: Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: const BoxDecoration(
                                    color: Colors.black54,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.close, size: 12, color: Colors.white),
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: 2,
                              left: 2,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                decoration: BoxDecoration(
                                  color: Colors.black54,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'Ảnh ${idx + 1}',
                                  style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w600),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 16, 12),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.camera_alt_outlined,
                      color: opsPrimary,
                    ),
                    tooltip: 'Chụp hoặc chọn ảnh',
                    onPressed: _showImagePickerOptions,
                  ),
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

/// Modal nghiệm thu hoàn tất sự cố kèm chụp ảnh trước/sau và ghi chú kỹ thuật.
class _ResolveVerificationSheet extends StatefulWidget {
  const _ResolveVerificationSheet({
    required this.report,
    required this.service,
    required this.onResolved,
  });

  final Map<String, dynamic> report;
  final LockerOpsService service;
  final Future<void> Function() onResolved;

  @override
  State<_ResolveVerificationSheet> createState() =>
      _ResolveVerificationSheetState();
}

class _ResolveVerificationSheetState extends State<_ResolveVerificationSheet> {
  final _noteCtrl = TextEditingController();
  final _picker = ImagePicker();
  XFile? _beforePhoto;
  XFile? _afterPhoto;
  bool _submitting = false;

  final _quickNotes = const [
    'Đã thay thế linh kiện khóa điện tử',
    'Đã cân chỉnh then & bản lề cửa ô tủ',
    'Đã kiểm tra bo mạch điều khiển & nguồn',
    'Đã vệ sinh sạch sẽ, test đóng mở 3 lần',
  ];

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage(bool isBefore, ImageSource source) async {
    try {
      final picked = await _picker.pickImage(
        source: source,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 80,
      );
      if (picked != null && mounted) {
        setState(() {
          if (isBefore) {
            _beforePhoto = picked;
          } else {
            _afterPhoto = picked;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Không chụp được ảnh: $e')),
        );
      }
    }
  }

  void _showImagePickerChoice(bool isBefore) {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined, color: opsPrimary),
              title: const Text('Chụp ảnh từ máy ảnh'),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(isBefore, ImageSource.camera);
              },
            ),
            ListTile(
              leading:
                  const Icon(Icons.photo_library_outlined, color: opsPrimary),
              title: const Text('Chọn ảnh từ thư viện'),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(isBefore, ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    final reportId = widget.report['id'] as int?;
    if (reportId == null) return;

    setState(() => _submitting = true);
    try {
      final noteText = _noteCtrl.text.trim();
      final buffer = StringBuffer('[NGHIỆM THU HOÀN TẤT]');
      if (noteText.isNotEmpty) {
        buffer.write('\nGhi chú: $noteText');
      } else {
        buffer.write('\nGhi chú: Đã hoàn tất sửa chữa và kiểm tra ô tủ.');
      }

      if (_beforePhoto != null) {
        buffer.write(
            '\n- Ảnh trước sửa: [Ảnh hiện trường: ${_beforePhoto!.name}]');
      }
      if (_afterPhoto != null) {
        buffer.write('\n- Ảnh sau sửa: [Ảnh hoàn tất: ${_afterPhoto!.name}]');
      }

      // Lưu nhật ký nghiệm thu
      await widget.service.addReportLog(reportId, buffer.toString());

      // Gọi resolve report để clear fault và đưa ô hoạt động lại
      await widget.service.resolveReport(reportId);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Color(0xFF16A34A),
            content:
                Text('Đã nghiệm thu và hoàn tất sự cố! Ô tủ đã hoạt động lại.'),
          ),
        );
      }
      await widget.onResolved();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFFDC2626),
            content: Text(LockerOpsService.errorMessage(e)),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Widget _buildPhotoSlot({
    required String title,
    required bool isBefore,
    required XFile? photo,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: opsSurface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: photo != null ? const Color(0xFF16A34A) : opsBorder,
            width: photo != null ? 1.5 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  photo != null ? Icons.check_circle : Icons.camera_alt_outlined,
                  size: 16,
                  color: photo != null ? const Color(0xFF16A34A) : opsMutedText,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.bold,
                      color: photo != null ? const Color(0xFF16A34A) : opsDark,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (photo != null) ...[
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(
                      File(photo.path),
                      height: 90,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        height: 90,
                        color: Colors.grey[200],
                        child: const Center(
                          child: Icon(Icons.broken_image, color: opsMutedText),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          if (isBefore) {
                            _beforePhoto = null;
                          } else {
                            _afterPhoto = null;
                          }
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.black54,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close,
                            size: 14, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                photo.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 10.5, color: opsMutedText),
              ),
            ] else ...[
              InkWell(
                onTap: () => _showImagePickerChoice(isBefore),
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  height: 90,
                  decoration: BoxDecoration(
                    color: opsPrimary.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: opsPrimary.withValues(alpha: 0.25),
                      style: BorderStyle.solid,
                    ),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.add_a_photo_outlined,
                            color: opsPrimary, size: 24),
                        const SizedBox(height: 4),
                        const Text(
                          'Chụp ảnh',
                          style: TextStyle(
                            fontSize: 12,
                            color: opsPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final reportTitle =
        widget.report['title'] ?? 'Sự cố #${widget.report['id']}';
    final lockerLabel =
        widget.report['lockerName'] ?? 'Tủ #${widget.report['lockerId']}';
    final boxLabel = widget.report['boxNumber'] ?? widget.report['boxId'];

    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF16A34A).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.verified_outlined,
                        color: Color(0xFF16A34A), size: 22),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Nghiệm thu hoàn tất sửa chữa',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        Text(
                          '$lockerLabel · Ô $boxLabel · #$reportTitle',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 12, color: opsMutedText),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                'Hình ảnh hiện trường (Trước & Sau khi sửa)',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _buildPhotoSlot(
                    title: 'Trước khi sửa',
                    isBefore: true,
                    photo: _beforePhoto,
                  ),
                  const SizedBox(width: 10),
                  _buildPhotoSlot(
                    title: 'Sau khi xong',
                    isBefore: false,
                    photo: _afterPhoto,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                'Ghi chú kỹ thuật & linh kiện',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _noteCtrl,
                minLines: 2,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText:
                      'Mô tả chi tiết linh kiện thay thế, các bước xử lý...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: opsBorder),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final qn in _quickNotes)
                    ActionChip(
                      label: Text(qn, style: const TextStyle(fontSize: 11)),
                      onPressed: () {
                        final current = _noteCtrl.text.trim();
                        if (current.isEmpty) {
                          _noteCtrl.text = qn;
                        } else {
                          _noteCtrl.text = '$current, $qn';
                        }
                      },
                    ),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _submitting ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF16A34A),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: _submitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.check_circle_outline),
                  label: Text(
                    _submitting
                        ? 'Đang lưu nghiệm thu...'
                        : 'Xác nhận & Hoàn tất sửa chữa',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Compact status badge for IoT devices (ONLINE/OFFLINE/ERROR).
class _DeviceStatusBadge extends StatelessWidget {
  const _DeviceStatusBadge(this.status);
  final String? status;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      'ONLINE' => const Color(0xFF16A34A),
      'OFFLINE' => const Color(0xFF6B7280),
      'ERROR' => const Color(0xFFEA580C),
      _ => opsMutedText,
    };
    final label = switch (status) {
      'ONLINE' => 'Online',
      'OFFLINE' => 'Offline',
      'ERROR' => 'Lỗi',
      _ => status ?? '',
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            margin: const EdgeInsets.only(right: 5),
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

double? _asDouble(dynamic value) {
  if (value is double) return value;
  if (value is num) return value.toDouble();
  return double.tryParse('$value');
}

int? _asInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse('$value');
}

List<Map<String, dynamic>> _sortCellsByColumn(
  List<Map<String, dynamic>> cells,
) {
  final sorted = [...cells];
  sorted.sort(
    (a, b) =>
        (_asInt(a['colIndex']) ?? 0).compareTo(_asInt(b['colIndex']) ?? 0),
  );
  return sorted;
}

int _countCells(
  List<Map<String, dynamic>> cells,
  String expected, {
  String field = 'status',
}) => cells
    .where((cell) => cell[field]?.toString().toUpperCase() == expected)
    .length;

String _cellTypeLabel(String? type) => switch (type) {
  'DRONE' => 'Drone',
  'XL' => 'XL',
  'STANDARD' => 'Chuẩn',
  null => 'Chuẩn',
  _ => type,
};

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 11,
              color: opsMutedText,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
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
