import 'dart:async';

import 'package:smart_laundry_locker/core/utils/app_date_time.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_laundry_locker/core/config/business_config_service.dart';
import 'package:smart_laundry_locker/core/routing/app_router.dart';
import 'package:smart_laundry_locker/core/services/token_service.dart';
import 'package:smart_laundry_locker/core/services/app_event_bus.dart';
import 'package:smart_laundry_locker/features/assistant/presentation/widgets/assistant_entry.dart';
import 'package:smart_laundry_locker/features/drone_delivery/domain/entities/drone_delivery_stage.dart';
import 'package:smart_laundry_locker/features/drone_delivery/domain/entities/drone_delivery_status.dart';
import 'package:smart_laundry_locker/features/drone_delivery/domain/entities/drone_labels.dart';
import 'package:smart_laundry_locker/features/drone_delivery/domain/entities/drone_parcel.dart';
import 'package:smart_laundry_locker/features/drone_delivery/infrastructure/models/drone_delivery_response.dart';
import 'package:smart_laundry_locker/features/drone_delivery/presentation/widgets/drone_delivery_detail.dart';
import 'package:smart_laundry_locker/features/locker_ops/data/locker_ops_service.dart';
import 'package:smart_laundry_locker/features/locker_ops/presentation/widgets/ops_widgets.dart';
import 'package:smart_laundry_locker/features/locker_ops/presentation/widgets/complete_inspection_sheet.dart';
import 'package:smart_laundry_locker/features/locker_ops/presentation/widgets/schedule_detail_modal_sheet.dart';
import 'package:smart_laundry_locker/features/locker_ops/presentation/pages/technician_profile_page.dart';
import 'package:smart_laundry_locker/features/maintenance/presentation/widgets/drone_report_detail_sheet.dart';
import 'package:smart_laundry_locker/features/profile/presentation/providers/profile_provider.dart';
import 'package:provider/provider.dart';
import 'package:smart_laundry_locker/shared/widgets/controller_disposer.dart';
import 'package:smart_laundry_locker/shared/widgets/user_ui_kit.dart';
import 'package:url_launcher/url_launcher.dart';

/// Home for the DRONE_TECHNICIAN role (kỹ thuật viên drone): drone fleet only
/// (delivery dispatch queue from the backend, fleet status/battery, mission
/// planner, flight data, drone maintenance schedules). Physical locker
/// maintenance lives with the LOCKER_TECHNICIAN role.
class MaintenanceHomePage extends StatefulWidget {
  const MaintenanceHomePage({super.key, this.service});

  final LockerOpsService? service;

  @override
  State<MaintenanceHomePage> createState() => _MaintenanceHomePageState();
}

class _MaintenanceHomePageState extends State<MaintenanceHomePage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(length: 6, vsync: this);
  late final LockerOpsService _service = widget.service ?? LockerOpsService();

  List<Map<String, dynamic>> _drones = [];
  // Hàng đợi order-based cho đội bay theo Phase 2.
  List<Map<String, dynamic>> _deliveries = [];
  // Chỉ chứa phiếu category=DRONE, lấy qua API riêng cho DRONE_TECHNICIAN.
  List<Map<String, dynamic>> _droneReports = [];
  List<Map<String, dynamic>> _myDroneReports = [];
  List<Map<String, dynamic>> _routedDroneReports = [];
  String? _droneReportLoadError;
  String _droneReportStatusFilter = 'ALL';
  String _droneReportAssignmentFilter = 'ALL';
  String _droneReportDroneFilter = 'ALL';
  String _droneReportTimeFilter = 'ALL';
  String _droneReportSort = 'NEWEST';
  int _droneReportVisibleCount = 20;
  final _droneReportSearchController = TextEditingController();
  String _myWorkTypeFilter = 'ALL';
  String _myWorkStatusFilter = 'ACTIVE';
  String _myWorkSort = 'DUE';
  final _myWorkSearchController = TextEditingController();
  // Lịch bảo trì định kỳ của drone (droneUnitId != null) — lịch tủ thuộc LOCKER_TECHNICIAN.
  List<Map<String, dynamic>> _schedules = [];
  String? _scheduleLoadError;
  bool _mySchedulesOnly = true;
  String _scheduleDueFilter = 'ALL';
  String _schedulePriorityFilter = 'ALL';
  String _scheduleSort = 'DUE';
  final _scheduleSearchController = TextEditingController();
  bool _loading = true;
  String? _myUserId;
  String? _myUserName;
  String? _myUserEmail;
  Map<String, dynamic>? _ratingAverage;
  String _dispatchFilter = 'ALL';
  Timer? _deliveryRefreshTimer;
  StreamSubscription<AppEvent>? _eventSubscription;

  /// Drone đã rời trạm, đang trên đường tới tủ nhận.
  List<Map<String, dynamic>> get _inFlightDeliveries => _deliveries
      .where(
        (d) => const {
          'DEPARTED',
          'EN_ROUTE',
          'APPROACHING',
          'ARRIVED',
        }.contains(d['deliveryStage']),
      )
      .toList(growable: false);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      try {
        final profileProvider = context.read<ProfileProvider>();
        if (profileProvider.profile == null) profileProvider.loadProfile();
      } catch (_) {}
    });
    _load();
    _deliveryRefreshTimer = Timer.periodic(
      const Duration(seconds: 3),
      (_) => _refreshDeliveries(),
    );
    _eventSubscription = AppEventBus.instance.events.listen((event) {
      if (event is OrderChangedEvent) _refreshDeliveries();
      if (event is ReportUpdatedEvent) _load();
    });
  }

  @override
  void dispose() {
    _tabs.dispose();
    _deliveryRefreshTimer?.cancel();
    _eventSubscription?.cancel();
    _droneReportSearchController.dispose();
    _myWorkSearchController.dispose();
    _scheduleSearchController.dispose();
    super.dispose();
  }

  Future<void> _refreshDeliveries() async {
    try {
      final deliveries = await _service.droneOrderQueue();
      if (mounted) setState(() => _deliveries = deliveries);
    } catch (_) {
      // Giữ dữ liệu cuối cùng khi mất mạng; lần poll sau sẽ thử lại.
    }
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      _myUserId = await TokenService.getUserId();
      _myUserName = await TokenService.getUserName();
      _myUserEmail = await TokenService.getUserEmail();
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
        final schedules = await _service.maintenanceSchedules(target: 'DRONE');
        if (mounted) {
          setState(() {
            _schedules = schedules
                .where((s) => s['droneUnitId'] != null)
                .toList(growable: false);
            _scheduleLoadError = null;
          });
        }
      } catch (e) {
        if (mounted) {
          setState(
            () => _scheduleLoadError =
                'Không tải được lịch bảo trì Drone: ${LockerOpsService.errorMessage(e)}',
          );
        }
      }
      await _loadDroneReports();
      try {
        final rating = await _service.myRatingAverage();
        if (mounted) setState(() => _ratingAverage = rating);
      } catch (_) {}
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadDroneReports() async {
    try {
      final reports = await _service.droneReports(all: true);
      final currentUserId = _myUserId;
      final mine = reports
          .where(
            (report) =>
                currentUserId != null &&
                '${report['assignedToUserId']}' == currentUserId,
          )
          .toList(growable: false);
      final routed = reports
          .where(
            (report) =>
                report['status'] == 'OPEN' &&
                (report['routedToUserId'] == null ||
                    '${report['routedToUserId']}' == currentUserId),
          )
          .toList(growable: false);
      if (!mounted) return;
      setState(() {
        _droneReports = reports;
        _myDroneReports = mine;
        _routedDroneReports = routed;
        _droneReportLoadError = null;
      });
    } catch (_) {
      // Nếu API tổng gặp lỗi riêng, vẫn thử API cá nhân để công việc đã được
      // phân công không biến mất hoàn toàn khỏi mobile.
      try {
        final mine = await _service.droneReports(mine: true);
        if (!mounted) return;
        setState(() {
          _myDroneReports = mine;
          _droneReports = mine;
          _routedDroneReports = const [];
          _droneReportLoadError = null;
        });
      } catch (_) {
        if (!mounted) return;
        setState(() {
          _droneReportLoadError =
              'Không tải được phiếu sự cố Drone. Kéo xuống để thử lại.';
        });
      }
    }
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.logout_rounded, color: Color(0xFFDC2626)),
            SizedBox(width: 10),
            Text('Đăng xuất ca trực'),
          ],
        ),
        content: const Text(
          'Bạn có chắc chắn muốn kết thúc ca trực và đăng xuất khỏi tài khoản KTV Drone không?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Hủy', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Đăng xuất'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await TokenService.clearTokens();
      if (mounted) context.go('/onboarding');
    }
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

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return '☀️ Chào buổi sáng';
    if (hour < 14) return '🌤️ Chào buổi trưa';
    if (hour < 18) return '🌅 Chào buổi chiều';
    return '🌙 Chào buổi tối';
  }

  String _resolvedTechnicianName(BuildContext context) {
    try {
      final name = context.watch<ProfileProvider>().profile?.fullName.trim();
      if (name != null && name.isNotEmpty && name != 'Người dùng') return name;
    } catch (_) {}
    if (_myUserName != null && _myUserName!.trim().isNotEmpty) {
      return _myUserName!.trim();
    }
    if (_myUserEmail != null && _myUserEmail!.trim().isNotEmpty) {
      return _myUserEmail!.trim();
    }
    return 'Kỹ thuật viên drone';
  }

  Widget _avatarFallback(String name) => Center(
    child: Text(
      AislBrand.initials(name),
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w800,
        color: Color(0xFFF1F5F9),
        letterSpacing: 0.5,
      ),
    ),
  );

  void _showDroneTechnicianProfile([String? resolvedName]) {
    String? profileName;
    String? profileEmail;
    String? profilePhone;
    String? profileAvatar;
    try {
      final profile = context.read<ProfileProvider>().profile;
      if (profile != null) {
        if (profile.fullName.trim().isNotEmpty &&
            profile.fullName.trim() != 'Người dùng') {
          profileName = profile.fullName.trim();
        }
        if (profile.email.trim().isNotEmpty) {
          profileEmail = profile.email.trim();
        }
        if (profile.phoneNumber.trim().isNotEmpty) {
          profilePhone = profile.phoneNumber.trim();
        }
        profileAvatar = profile.avatarUrl;
      }
    } catch (_) {}

    final techName =
        resolvedName ?? profileName ?? _myUserName ?? 'Kỹ thuật viên drone';
    final techEmail = profileEmail ?? _myUserEmail ?? 'ktv.drone@lockr.tech';
    final techPhone = profilePhone ?? 'Chưa cập nhật SĐT';
    final total = _deliveries.length;
    final working = _deliveries
        .where(
          (d) =>
              d['deliveryStage'] == 'ACCEPTED' ||
              d['deliveryStage'] == 'LAUNCHING',
        )
        .length;
    final completed = _deliveries
        .where((d) => d['deliveryStage'] == 'READY_FOR_PICKUP')
        .length;
    final flying = _inFlightDeliveries.length;
    final avgRating = _ratingAverage?['average']?.toString() ?? '5.0';
    final ratingCount = _ratingAverage?['count']?.toString() ?? '0';

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Stack(
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF0077B6), Color(0xFF00B4D8)],
                          ),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFF0077B6),
                            width: 2,
                          ),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: profileAvatar != null && profileAvatar.isNotEmpty
                            ? Image.network(
                                profileAvatar,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) =>
                                    _profileAvatarFallback(techName),
                              )
                            : _profileAvatarFallback(techName),
                      ),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            color: const Color(0xFF16A34A),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                techName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                  color: opsDark,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFDCFCE7),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'Trực ca',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF166534),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'KTV Drone (Đội bay) · Sẵn sàng',
                          style: TextStyle(
                            fontSize: 12.5,
                            color: opsMutedText,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          techEmail,
                          style: const TextStyle(
                            fontSize: 12,
                            color: opsMutedText,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _profileStatTile(
                      'Tổng ca',
                      '$total',
                      const Color(0xFF4F46E5),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _profileStatTile(
                      'Đang làm',
                      '$working',
                      const Color(0xFF2563EB),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _profileStatTile(
                      'Đã giao',
                      '$completed',
                      const Color(0xFF16A34A),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _profileStatTile(
                      'Đang bay',
                      '$flying',
                      const Color(0xFF0891B2),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.star_rounded,
                          color: Color(0xFFF59E0B),
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Đánh giá chất lượng: ',
                          style: TextStyle(fontSize: 13, color: opsDark),
                        ),
                        Text(
                          '$avgRating/5',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: opsDark,
                          ),
                        ),
                        Text(
                          ' ($ratingCount lượt)',
                          style: const TextStyle(
                            fontSize: 12,
                            color: opsMutedText,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Row(
                      children: [
                        Icon(
                          Icons.verified_user_outlined,
                          color: Color(0xFF16A34A),
                          size: 20,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Quy chế SLA: ',
                          style: TextStyle(fontSize: 13, color: opsDark),
                        ),
                        _DroneSlaBadge(),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(
                          Icons.phone_outlined,
                          color: opsMutedText,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'SĐT kỹ thuật: ',
                          style: TextStyle(fontSize: 13, color: opsDark),
                        ),
                        Expanded(
                          child: Text(
                            techPhone,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: opsDark,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const TechnicianProfilePage(),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: opsPrimary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.edit_note_rounded, size: 20),
                      label: const Text(
                        'Xem & Chỉnh sửa hồ sơ',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13.5,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  OutlinedButton.icon(
                    onPressed: () {
                      Navigator.of(ctx).pop();
                      _logout();
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFDC2626),
                      side: const BorderSide(color: Color(0xFFFCA5A5)),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.logout, size: 18),
                    label: const Text(
                      'Đăng xuất',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13.5,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _profileAvatarFallback(String name) => Center(
    child: Text(
      AislBrand.initials(name),
      style: const TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    ),
  );

  Widget _profileStatTile(String label, String value, Color color) => Container(
    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: color.withValues(alpha: 0.2)),
    ),
    child: Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.w600,
            color: color.withValues(alpha: 0.8),
          ),
        ),
      ],
    ),
  );

  Widget _buildDroneTechnicianHeader() {
    final waiting = _droneReports.where((r) => r['status'] == 'OPEN').length;
    final working = _myDroneReports
        .where((r) => r['status'] == 'IN_PROGRESS')
        .length;
    final inFlight = _inFlightDeliveries.length;
    final displayName = _resolvedTechnicianName(context);
    String? avatarUrl;
    try {
      avatarUrl = context.watch<ProfileProvider>().profile?.avatarUrl;
    } catch (_) {}

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF061A30), Color(0xFF0A2544), Color(0xFF103A63)],
          stops: [0.0, 0.52, 1.0],
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Color(0x38061A30),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Column(
            children: [
              Row(
                children: [
                  GestureDetector(
                    onTap: () => _showDroneTechnicianProfile(displayName),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              colors: [
                                Color(0xFF38BDF8),
                                Color(0xFF0284C7),
                                Color(0xFF10B981),
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(
                                  0xFF38BDF8,
                                ).withValues(alpha: 0.35),
                                blurRadius: 10,
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.all(2.5),
                          child: Container(
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Color(0xFF0A2342),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: avatarUrl != null && avatarUrl.isNotEmpty
                                ? Image.network(
                                    avatarUrl,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) =>
                                        _avatarFallback(displayName),
                                  )
                                : _avatarFallback(displayName),
                          ),
                        ),
                        Positioned(
                          bottom: 1,
                          right: 1,
                          child: Container(
                            width: 13,
                            height: 13,
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(0xFF061A30),
                                width: 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(
                                    0xFF10B981,
                                  ).withValues(alpha: 0.6),
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                _greeting(),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.8),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            _droneRoleBadge(),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          displayName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 19,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            const Icon(
                              Icons.verified_rounded,
                              size: 14,
                              color: Color(0xFF34D399),
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                working > 0
                                    ? 'SLA: Bình thường · $working ca đang xử lý'
                                    : 'SLA: Bình thường · Sẵn sàng nhận việc',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Color(0xFFA7F3D0),
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (context.canPop())
                    _droneHeaderAction(
                      Icons.arrow_back_rounded,
                      'Quay lại',
                      () => context.pop(),
                    )
                  else ...[
                    AssistantEntryGate(
                      builder: (context) => Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: _droneHeaderAction(
                          Icons.support_agent_rounded,
                          'Trợ lý hỏi đáp',
                          () => context.push(AppRouter.assistant),
                        ),
                      ),
                    ),
                    _droneHeaderAction(
                      Icons.person_outline_rounded,
                      'Hồ sơ & Chỉnh sửa',
                      () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const TechnicianProfilePage(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    _droneHeaderAction(
                      Icons.logout_rounded,
                      'Đăng xuất',
                      _logout,
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.12),
                  ),
                ),
                child: Row(
                  children: [
                    _droneHudChip(
                      Icons.warning_amber_rounded,
                      '$waiting',
                      'Chờ xử lý',
                      const Color(0xFFEF4444),
                      waiting > 0,
                      () => _selectDroneReportFilter('OPEN'),
                    ),
                    const SizedBox(width: 4),
                    _droneHudChip(
                      Icons.handyman_outlined,
                      '$working',
                      'Đang làm',
                      const Color(0xFF38BDF8),
                      false,
                      () => _tabs.animateTo(3),
                    ),
                    const SizedBox(width: 4),
                    _droneHudChip(
                      Icons.event_repeat_outlined,
                      '${_schedules.length}',
                      'Định kỳ',
                      const Color(0xFFA78BFA),
                      false,
                      () => _tabs.animateTo(4),
                    ),
                    const SizedBox(width: 4),
                    _droneHudChip(
                      Icons.flight_outlined,
                      '${_drones.length}',
                      'Đội bay',
                      const Color(0xFF34D399),
                      false,
                      () => _tabs.animateTo(1),
                    ),
                  ],
                ),
              ),
              if (inFlight > 0) ...[
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '$inFlight drone đang bay',
                    style: const TextStyle(
                      color: Color(0xFFBAE6FD),
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _droneRoleBadge() => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
    decoration: BoxDecoration(
      color: const Color(0xFF0284C7).withValues(alpha: 0.35),
      borderRadius: BorderRadius.circular(6),
      border: Border.all(color: const Color(0xFF38BDF8).withValues(alpha: 0.5)),
    ),
    child: const Text(
      'DRONE',
      style: TextStyle(
        fontSize: 9.5,
        fontWeight: FontWeight.w800,
        color: Color(0xFFBAE6FD),
        letterSpacing: 0.5,
      ),
    ),
  );

  Widget _droneHeaderAction(IconData icon, String tooltip, VoidCallback onTap) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
          ),
          alignment: Alignment.center,
          child: Icon(
            icon,
            size: 19,
            color: Colors.white.withValues(alpha: 0.95),
          ),
        ),
      ),
    );
  }

  Widget _droneHudChip(
    IconData icon,
    String value,
    String label,
    Color accentColor,
    bool isAlert,
    VoidCallback onTap,
  ) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(13),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          decoration: BoxDecoration(
            color: isAlert
                ? const Color(0xFFDC2626).withValues(alpha: 0.22)
                : Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(13),
            border: Border.all(
              color: isAlert
                  ? const Color(0xFFEF4444).withValues(alpha: 0.55)
                  : Colors.white.withValues(alpha: 0.12),
            ),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 13, color: accentColor),
                  const SizedBox(width: 4),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: isAlert ? const Color(0xFFFCA5A5) : Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 3),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withValues(alpha: 0.75),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _selectDroneReportFilter(String filter) {
    setState(() => _droneReportStatusFilter = filter);
    _tabs.animateTo(2);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FA),
      body: Column(
        children: [
          _buildDroneTechnicianHeader(),
          Material(
            color: Colors.white,
            elevation: 1,
            shadowColor: Colors.black12,
            child: TabBar(
              controller: _tabs,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              padding: const EdgeInsets.symmetric(horizontal: 4),
              indicatorColor: const Color(0xFF0077B6),
              indicatorWeight: 3,
              labelColor: const Color(0xFF0F172A),
              labelStyle: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
              ),
              unselectedLabelColor: const Color(0xFF64748B),
              unselectedLabelStyle: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
              tabs: [
                Tab(text: 'Điều phối (${_deliveries.length})'),
                Tab(text: 'Đội bay (${_drones.length})'),
                Tab(text: 'Sự cố (${_droneReports.length})'),
                Tab(
                  text:
                      'Việc của tôi (${_myDroneReports.length + _schedules.where(_isScheduleMine).length})',
                ),
                Tab(text: 'Định kỳ (${_schedules.length})'),
                const Tab(text: 'Công cụ bay'),
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
                      _buildDispatchQueue(),
                      _buildDroneFleet(),
                      _buildDroneIncidentQueue(),
                      _buildMyDroneWork(),
                      _buildMaintenanceSchedules(),
                      _buildFlightTools(),
                    ],
                  ),
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

  // ---- Tab điều phối đơn drone ----
  Widget _buildDispatchQueue() {
    final visibleDeliveries = _deliveries
        .where(_matchesDispatchFilter)
        .toList();
    final awaiting = visibleDeliveries
        .where((d) => d['deliveryStage'] == 'AWAITING_DISPATCH')
        .toList(growable: false);
    final awaitingLoading = visibleDeliveries
        .where(
          (d) =>
              d['deliveryStage'] == 'ACCEPTED' &&
              d['missionStatus'] == 'AWAITING_LOADING',
        )
        .toList(growable: false);
    final readyToLaunch = visibleDeliveries
        .where(
          (d) =>
              d['deliveryStage'] == 'ACCEPTED' &&
              d['missionStatus'] == 'READY_TO_LAUNCH',
        )
        .toList(growable: false);
    final launching = visibleDeliveries
        .where((d) => d['deliveryStage'] == 'LAUNCHING')
        .toList(growable: false);
    final inFlight = visibleDeliveries
        .where(
          (d) => const {
            'DEPARTED',
            'EN_ROUTE',
            'APPROACHING',
            'ARRIVED',
          }.contains(d['deliveryStage']),
        )
        .toList(growable: false);
    final delivered = visibleDeliveries
        .where((d) => d['deliveryStage'] == 'READY_FOR_PICKUP')
        .toList(growable: false);
    // Đơn đã đóng mà không giao được, kiện còn chờ trả cho người gửi: việc phải làm
    // nên luôn hiện, không phụ thuộc bộ lọc chặng.
    final parcelReturns = _deliveries
        .where((d) => d['parcelReturnPending'] == true)
        .toList(growable: false);
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          _buildDispatchFilters(),
          const SizedBox(height: 8),
          // ── Đơn hàng drone order-based cho đội bay ───────────────────────
          if (parcelReturns.isNotEmpty) ...[
            OpsSectionLabel(
              'Chờ trả kiện cho người gửi (${parcelReturns.length})',
              icon: Icons.assignment_return_outlined,
            ),
            const SizedBox(height: 8),
            for (final order in parcelReturns) _parcelReturnCard(order),
            const SizedBox(height: 8),
          ],
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
          if (awaitingLoading.isNotEmpty) ...[
            OpsSectionLabel(
              'Chờ nạp hàng (${awaitingLoading.length})',
              icon: Icons.inventory_2_outlined,
            ),
            const SizedBox(height: 8),
            for (final order in awaitingLoading)
              _deliveryCard(
                order,
                action: _DeliveryAction.load,
                onCancel: () => _cancelDeliveryFlow(order),
              ),
            const SizedBox(height: 8),
          ],
          if (readyToLaunch.isNotEmpty) ...[
            OpsSectionLabel(
              'Sẵn sàng phóng (${readyToLaunch.length})',
              icon: Icons.rocket_launch,
            ),
            const SizedBox(height: 8),
            for (final order in readyToLaunch)
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
          if (inFlight.isNotEmpty) ...[
            OpsSectionLabel(
              'Đang bay (${inFlight.length})',
              icon: Icons.flight,
            ),
            const SizedBox(height: 8),
            for (final order in inFlight)
              _deliveryCard(order, action: _DeliveryAction.track),
            const SizedBox(height: 8),
          ],
          if (delivered.isNotEmpty) ...[
            OpsSectionLabel(
              'Đã giao · chờ khách nhận (${delivered.length})',
              icon: Icons.inventory_outlined,
            ),
            const SizedBox(height: 8),
            for (final order in delivered)
              _deliveryCard(order, action: _DeliveryAction.track),
            const SizedBox(height: 8),
          ],
          if (awaiting.isNotEmpty ||
              parcelReturns.isNotEmpty ||
              awaitingLoading.isNotEmpty ||
              readyToLaunch.isNotEmpty ||
              launching.isNotEmpty ||
              inFlight.isNotEmpty ||
              delivered.isNotEmpty) ...[
            const Divider(),
            const SizedBox(height: 8),
          ],

          if (awaiting.isEmpty &&
              parcelReturns.isEmpty &&
              awaitingLoading.isEmpty &&
              readyToLaunch.isEmpty &&
              launching.isEmpty &&
              inFlight.isEmpty &&
              delivered.isEmpty)
            const OpsEmptyState(
              icon: Icons.inbox_outlined,
              title: 'Không có đơn drone đang chờ',
              subtitle: 'Đơn mới sẽ xuất hiện ở tab Điều phối.',
            ),
        ],
      ),
    );
  }

  bool _matchesDispatchFilter(Map<String, dynamic> delivery) {
    switch (_dispatchFilter) {
      case 'WAITING':
        return delivery['deliveryStage'] == 'AWAITING_DISPATCH';
      case 'WORKING':
        return delivery['deliveryStage'] == 'ACCEPTED' ||
            delivery['deliveryStage'] == 'LAUNCHING';
      case 'FLYING':
        return const {
          'DEPARTED',
          'EN_ROUTE',
          'APPROACHING',
          'ARRIVED',
        }.contains(delivery['deliveryStage']);
      case 'DONE':
        return delivery['deliveryStage'] == 'READY_FOR_PICKUP';
      default:
        return true;
    }
  }

  Widget _buildDispatchFilters() {
    int count(String filter) => _deliveries.where((d) {
      switch (filter) {
        case 'WAITING':
          return d['deliveryStage'] == 'AWAITING_DISPATCH';
        case 'WORKING':
          return d['deliveryStage'] == 'ACCEPTED' ||
              d['deliveryStage'] == 'LAUNCHING';
        case 'FLYING':
          return const {
            'DEPARTED',
            'EN_ROUTE',
            'APPROACHING',
            'ARRIVED',
          }.contains(d['deliveryStage']);
        case 'DONE':
          return d['deliveryStage'] == 'READY_FOR_PICKUP';
        default:
          return true;
      }
    }).length;

    final options = [
      ('ALL', 'Mọi trạng thái', Icons.filter_list_rounded, opsPrimary),
      ('WAITING', 'Chờ nhận', Icons.fiber_new_rounded, const Color(0xFFDC2626)),
      (
        'WORKING',
        'Đang xử lý',
        Icons.build_circle_outlined,
        const Color(0xFFD97706),
      ),
      ('FLYING', 'Đang bay', Icons.flight_outlined, const Color(0xFF2563EB)),
      ('DONE', 'Đã giao', Icons.check_circle_outline, const Color(0xFF16A34A)),
    ];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final option in options) ...[
            _droneFilterChip(
              label: '${option.$2} (${count(option.$1)})',
              selected: _dispatchFilter == option.$1,
              icon: option.$3,
              activeColor: option.$4,
              onTap: () => setState(() => _dispatchFilter = option.$1),
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }

  Widget _droneFilterChip({
    required String label,
    required bool selected,
    required IconData icon,
    required Color activeColor,
    required VoidCallback onTap,
  }) {
    return ChoiceChip(
      selected: selected,
      onSelected: (_) => onTap(),
      avatar: Icon(
        icon,
        size: 16,
        color: selected ? activeColor : const Color(0xFF64748B),
      ),
      label: Text(label),
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
        color: selected ? activeColor : const Color(0xFF475569),
      ),
      selectedColor: activeColor.withValues(alpha: 0.13),
      backgroundColor: Colors.white,
      side: BorderSide(
        color: selected
            ? activeColor.withValues(alpha: 0.55)
            : const Color(0xFFE2E8F0),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      showCheckmark: false,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
    );
  }

  // ---- Tab sự cố Drone / việc của tôi ----
  Widget _buildDroneIncidentQueue() {
    final query = _droneReportSearchController.text.trim().toLowerCase();
    final now = DateTime.now();
    final reports = _droneReports.where((report) {
      final statusMatches =
          _droneReportStatusFilter == 'ALL' ||
          report['status'] == _droneReportStatusFilter;
      final assignmentMatches = switch (_droneReportAssignmentFilter) {
        'MINE' => _isDroneReportAssignedToMe(report),
        'UNASSIGNED' => report['assignedToUserId'] == null,
        _ => true,
      };
      final droneCode = '${report['droneCode'] ?? report['droneUnitId'] ?? ''}';
      final droneMatches =
          _droneReportDroneFilter == 'ALL' ||
          droneCode == _droneReportDroneFilter;
      final createdAt = parseServerDateTime(report['createdAt']);
      final age = createdAt == null ? null : now.difference(createdAt);
      final timeMatches = switch (_droneReportTimeFilter) {
        'TODAY' =>
          createdAt != null &&
              createdAt.year == now.year &&
              createdAt.month == now.month &&
              createdAt.day == now.day,
        '7D' => age != null && !age.isNegative && age.inDays < 7,
        '30D' => age != null && !age.isNegative && age.inDays < 30,
        _ => true,
      };
      final searchable = [
        report['id'],
        report['title'],
        report['description'],
        report['droneCode'],
        report['reporterName'],
        report['orderCode'],
      ].where((value) => value != null).join(' ').toLowerCase();
      return statusMatches &&
          assignmentMatches &&
          droneMatches &&
          timeMatches &&
          (query.isEmpty || searchable.contains(query));
    }).toList();
    reports.sort(
      (a, b) => switch (_droneReportSort) {
        'OLDEST' => -_compareDroneReportsNewestFirst(a, b),
        'SLA' => _compareNullableDate(a['slaDueAt'], b['slaDueAt']),
        _ => _compareDroneReportsNewestFirst(a, b),
      },
    );
    final visibleReports = reports
        .take(_droneReportVisibleCount)
        .toList(growable: false);
    final openCount = _droneReports.where((r) => r['status'] == 'OPEN').length;
    final inProgressCount = _droneReports
        .where((r) => r['status'] == 'IN_PROGRESS')
        .length;
    final resolvedCount = _droneReports
        .where((r) => r['status'] == 'RESOLVED')
        .length;

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          if (_droneReportLoadError != null) ...[
            OpsBanner(
              tone: OpsBannerTone.danger,
              icon: Icons.cloud_off_outlined,
              text: _droneReportLoadError!,
            ),
            _retryButton(),
          ] else
            OpsBanner(
              tone: openCount > 0 ? OpsBannerTone.warning : OpsBannerTone.info,
              icon: openCount > 0
                  ? Icons.warning_amber_rounded
                  : Icons.flight_outlined,
              text: openCount > 0
                  ? 'Có $openCount phiếu sự cố Drone đang chờ KTV tiếp nhận xử lý.'
                  : 'Hàng đợi sự cố Drone. Phiếu mới được ưu tiên hiển thị để đội bay tiếp nhận kịp thời.',
            ),
          const SizedBox(height: 10),
          _buildSearchField(
            controller: _droneReportSearchController,
            hint: 'Tìm mã phiếu, tiêu đề, drone, người báo...',
            onChanged: (_) => setState(() => _droneReportVisibleCount = 20),
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final option in [
                  ('ALL', 'Tất cả', _droneReports.length, Icons.filter_list),
                  ('OPEN', 'Chờ nhận', openCount, Icons.fiber_new_rounded),
                  (
                    'IN_PROGRESS',
                    'Đang xử lý',
                    inProgressCount,
                    Icons.build_circle_outlined,
                  ),
                  (
                    'RESOLVED',
                    'Hoàn tất',
                    resolvedCount,
                    Icons.check_circle_outline,
                  ),
                ]) ...[
                  FilterChip(
                    selected: _droneReportStatusFilter == option.$1,
                    onSelected: (_) => setState(() {
                      _droneReportStatusFilter = option.$1;
                      _droneReportVisibleCount = 20;
                    }),
                    avatar: Icon(option.$4, size: 16),
                    label: Text('${option.$2} (${option.$3})'),
                    showCheckmark: false,
                    selectedColor: const Color(
                      0xFF0284C7,
                    ).withValues(alpha: 0.14),
                    side: BorderSide(
                      color: _droneReportStatusFilter == option.$1
                          ? const Color(0xFF0284C7)
                          : const Color(0xFFE2E8F0),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
              ],
            ),
          ),
          const SizedBox(height: 8),
          _buildReportAdvancedFilters(),
          const SizedBox(height: 12),
          if (_routedDroneReports.isNotEmpty &&
              _droneReportStatusFilter == 'ALL') ...[
            OpsSectionLabel(
              'Gửi trực tiếp cho bạn (${_routedDroneReports.length})',
              icon: Icons.assignment_ind_outlined,
            ),
            const SizedBox(height: 8),
          ],
          if (reports.isEmpty && _droneReportLoadError == null)
            const OpsEmptyState(
              icon: Icons.check_circle_outline,
              title: 'Không có phiếu sự cố Drone',
              subtitle: 'Đội bay hiện không có sự cố phù hợp bộ lọc.',
            )
          else
            for (final report in visibleReports) _droneReportCard(report),
          if (reports.length > visibleReports.length)
            Center(
              child: OutlinedButton.icon(
                onPressed: () => setState(() => _droneReportVisibleCount += 20),
                icon: const Icon(Icons.expand_more_rounded),
                label: Text(
                  'Xem thêm (${reports.length - visibleReports.length})',
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMyDroneWork() {
    final query = _myWorkSearchController.text.trim().toLowerCase();
    final mySchedules = _schedules.where(_isScheduleMine).toList();
    final tasks = <({String type, Map<String, dynamic> data})>[
      for (final report in _myDroneReports) (type: 'INCIDENT', data: report),
      for (final schedule in mySchedules) (type: 'MAINTENANCE', data: schedule),
    ];
    final pendingCount = tasks.where((task) {
      if (task.type == 'INCIDENT') return task.data['status'] == 'OPEN';
      return task.data['due'] == true;
    }).length;
    final progressCount = _myDroneReports
        .where((report) => report['status'] == 'IN_PROGRESS')
        .length;
    final completedCount = tasks.where((task) => _myTaskIsDone(task)).length;
    final filtered = tasks.where((task) {
      if (_myWorkTypeFilter != 'ALL' && task.type != _myWorkTypeFilter) {
        return false;
      }
      final done = _myTaskIsDone(task);
      if (_myWorkStatusFilter == 'ACTIVE' && done) return false;
      if (_myWorkStatusFilter == 'DONE' && !done) return false;
      final data = task.data;
      final searchable = [
        data['id'],
        data['title'],
        data['description'],
        data['droneCode'],
        data['orderCode'],
      ].where((value) => value != null).join(' ').toLowerCase();
      return query.isEmpty || searchable.contains(query);
    }).toList();
    filtered.sort((a, b) {
      if (_myWorkSort == 'NEWEST') {
        return _compareNullableDate(
          b.data['createdAt'] ?? b.data['lastDoneAt'],
          a.data['createdAt'] ?? a.data['lastDoneAt'],
        );
      }
      final firstDue = a.type == 'INCIDENT'
          ? a.data['slaDueAt']
          : a.data['nextDueAt'];
      final secondDue = b.type == 'INCIDENT'
          ? b.data['slaDueAt']
          : b.data['nextDueAt'];
      return _compareNullableDate(firstDue, secondDue);
    });

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          if (_droneReportLoadError != null) ...[
            OpsBanner(
              tone: OpsBannerTone.danger,
              icon: Icons.cloud_off_outlined,
              text: _droneReportLoadError!,
            ),
            _retryButton(),
          ] else
            OpsBanner(
              tone: filtered.isNotEmpty
                  ? OpsBannerTone.info
                  : OpsBannerTone.success,
              icon: filtered.isNotEmpty
                  ? Icons.engineering_outlined
                  : Icons.check_circle_outline,
              text:
                  'Công việc được giao gồm phiếu sự cố và lịch bảo trì Drone. Mọi thay đổi chỉ được ghi nhận sau khi Backend xác nhận.',
            ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _workMetric(
                  'Chưa làm',
                  pendingCount,
                  const Color(0xFFEA580C),
                ),
              ),
              const SizedBox(width: 7),
              Expanded(
                child: _workMetric(
                  'Đang làm',
                  progressCount,
                  const Color(0xFF0284C7),
                ),
              ),
              const SizedBox(width: 7),
              Expanded(
                child: _workMetric(
                  'Hoàn tất',
                  completedCount,
                  const Color(0xFF16A34A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _buildSearchField(
            controller: _myWorkSearchController,
            hint: 'Tìm công việc, drone, mã phiếu...',
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final option in const [
                  ('ALL', 'Mọi loại'),
                  ('INCIDENT', 'Sự cố'),
                  ('MAINTENANCE', 'Bảo trì'),
                ]) ...[
                  _droneFilterChip(
                    label: option.$2,
                    selected: _myWorkTypeFilter == option.$1,
                    icon: option.$1 == 'MAINTENANCE'
                        ? Icons.event_repeat
                        : option.$1 == 'INCIDENT'
                        ? Icons.warning_amber_rounded
                        : Icons.work_outline,
                    activeColor: const Color(0xFF0284C7),
                    onTap: () => setState(() => _myWorkTypeFilter = option.$1),
                  ),
                  const SizedBox(width: 7),
                ],
              ],
            ),
          ),
          const SizedBox(height: 6),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final option in const [
                  ('ACTIVE', 'Cần thực hiện'),
                  ('DONE', 'Đã hoàn tất'),
                  ('ALL', 'Tất cả'),
                ]) ...[
                  _droneFilterChip(
                    label: option.$2,
                    selected: _myWorkStatusFilter == option.$1,
                    icon: option.$1 == 'DONE'
                        ? Icons.check_circle_outline
                        : Icons.pending_actions_outlined,
                    activeColor: option.$1 == 'DONE'
                        ? const Color(0xFF16A34A)
                        : const Color(0xFF7C3AED),
                    onTap: () =>
                        setState(() => _myWorkStatusFilter = option.$1),
                  ),
                  const SizedBox(width: 7),
                ],
                _sortMenu(
                  value: _myWorkSort,
                  values: const {'DUE': 'Hạn gần nhất', 'NEWEST': 'Mới nhất'},
                  onSelected: (value) => setState(() => _myWorkSort = value),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          if (filtered.isEmpty)
            const OpsEmptyState(
              icon: Icons.engineering_outlined,
              title: 'Không có công việc phù hợp',
              subtitle: 'Thử đổi bộ lọc hoặc kéo xuống để tải lại dữ liệu.',
            )
          else
            for (final task in filtered)
              task.type == 'INCIDENT'
                  ? _droneReportCard(task.data)
                  : _droneScheduleCard(
                      task.data,
                      due: task.data['due'] == true,
                    ),
        ],
      ),
    );
  }

  bool _myTaskIsDone(({String type, Map<String, dynamic> data}) task) {
    if (task.type == 'INCIDENT') return task.data['status'] == 'RESOLVED';
    return task.data['due'] != true && task.data['lastDoneAt'] != null;
  }

  Widget _workMetric(String label, int value, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 9),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: color.withValues(alpha: 0.22)),
    ),
    child: Column(
      children: [
        Text(
          '$value',
          style: TextStyle(fontWeight: FontWeight.w900, color: color),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    ),
  );

  Widget _buildSearchField({
    required TextEditingController controller,
    required String hint,
    required ValueChanged<String> onChanged,
  }) => TextField(
    controller: controller,
    onChanged: onChanged,
    textInputAction: TextInputAction.search,
    decoration: InputDecoration(
      hintText: hint,
      prefixIcon: const Icon(Icons.search_rounded, size: 20),
      suffixIcon: controller.text.isEmpty
          ? null
          : IconButton(
              tooltip: 'Xóa tìm kiếm',
              onPressed: () {
                controller.clear();
                onChanged('');
              },
              icon: const Icon(Icons.close_rounded, size: 19),
            ),
      filled: true,
      fillColor: Colors.white,
      isDense: true,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
    ),
  );

  Widget _buildReportAdvancedFilters() {
    final drones =
        _droneReports
            .map((r) => '${r['droneCode'] ?? r['droneUnitId'] ?? ''}')
            .where((value) => value.isNotEmpty)
            .toSet()
            .toList()
          ..sort();
    final active =
        _droneReportAssignmentFilter != 'ALL' ||
        _droneReportDroneFilter != 'ALL' ||
        _droneReportTimeFilter != 'ALL' ||
        _droneReportSort != 'NEWEST' ||
        _droneReportSearchController.text.isNotEmpty;
    return Wrap(
      spacing: 8,
      runSpacing: 7,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        _compactDropdown(
          value: _droneReportAssignmentFilter,
          items: const {
            'ALL': 'Mọi phân công',
            'MINE': 'Giao cho tôi',
            'UNASSIGNED': 'Chưa phân công',
          },
          onChanged: (value) =>
              setState(() => _droneReportAssignmentFilter = value),
        ),
        _compactDropdown(
          value: _droneReportDroneFilter,
          items: {'ALL': 'Mọi drone', for (final drone in drones) drone: drone},
          onChanged: (value) => setState(() => _droneReportDroneFilter = value),
        ),
        _compactDropdown(
          value: _droneReportTimeFilter,
          items: const {
            'ALL': 'Mọi thời gian',
            'TODAY': 'Hôm nay',
            '7D': '7 ngày',
            '30D': '30 ngày',
          },
          onChanged: (value) => setState(() => _droneReportTimeFilter = value),
        ),
        _sortMenu(
          value: _droneReportSort,
          values: const {
            'NEWEST': 'Mới nhất',
            'OLDEST': 'Cũ nhất',
            'SLA': 'Hạn SLA',
          },
          onSelected: (value) => setState(() => _droneReportSort = value),
        ),
        if (active)
          TextButton.icon(
            onPressed: _resetDroneReportFilters,
            icon: const Icon(Icons.restart_alt_rounded, size: 17),
            label: const Text('Đặt lại'),
          ),
      ],
    );
  }

  Widget _compactDropdown({
    required String value,
    required Map<String, String> items,
    required ValueChanged<String> onChanged,
  }) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(999),
      border: Border.all(color: const Color(0xFFE2E8F0)),
    ),
    child: DropdownButtonHideUnderline(
      child: DropdownButton<String>(
        value: items.containsKey(value) ? value : items.keys.first,
        isDense: true,
        borderRadius: BorderRadius.circular(12),
        style: const TextStyle(
          fontSize: 12,
          color: Color(0xFF334155),
          fontWeight: FontWeight.w600,
        ),
        items: [
          for (final item in items.entries)
            DropdownMenuItem(value: item.key, child: Text(item.value)),
        ],
        onChanged: (next) {
          if (next != null) onChanged(next);
        },
      ),
    ),
  );

  Widget _sortMenu({
    required String value,
    required Map<String, String> values,
    required ValueChanged<String> onSelected,
  }) => PopupMenuButton<String>(
    initialValue: value,
    onSelected: onSelected,
    itemBuilder: (_) => [
      for (final item in values.entries)
        PopupMenuItem(value: item.key, child: Text(item.value)),
    ],
    child: Chip(
      avatar: const Icon(Icons.sort_rounded, size: 16),
      label: Text(values[value] ?? 'Sắp xếp'),
      backgroundColor: Colors.white,
      side: const BorderSide(color: Color(0xFFE2E8F0)),
    ),
  );

  void _resetDroneReportFilters() {
    _droneReportSearchController.clear();
    setState(() {
      _droneReportAssignmentFilter = 'ALL';
      _droneReportDroneFilter = 'ALL';
      _droneReportTimeFilter = 'ALL';
      _droneReportSort = 'NEWEST';
      _droneReportVisibleCount = 20;
    });
  }

  int _compareNullableDate(dynamic first, dynamic second) {
    final firstDate = parseServerDateTime(first);
    final secondDate = parseServerDateTime(second);
    if (firstDate == null && secondDate == null) return 0;
    if (firstDate == null) return 1;
    if (secondDate == null) return -1;
    return firstDate.compareTo(secondDate);
  }

  Widget _droneReportCard(Map<String, dynamic> report) {
    final status = '${report['status'] ?? 'OPEN'}';
    final reportId = _asInt(report['id']);
    final droneCode = report['droneCode']?.toString().trim();
    final created = _fmtDate(report['createdAt']);
    final assignedToMe = _isDroneReportAssignedToMe(report);
    final canClaim = _canClaimDroneReport(report);
    final isOverdue = report['overdue'] == true;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: OpsCard(
        onTap: () => _showDroneReportDetail(report),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A).withValues(alpha: 0.07),
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: Text(
                    'RPT-${reportId ?? '—'}',
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                      color: opsDark,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${report['title'] ?? 'Sự cố Drone'}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                      color: opsDark,
                    ),
                  ),
                ),
                StatusChip(status),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                _MiniPill(
                  icon: Icons.flight_outlined,
                  text: droneCode?.isNotEmpty == true
                      ? droneCode!
                      : 'Drone #${report['droneUnitId'] ?? '—'}',
                  color: const Color(0xFF0284C7),
                ),
                if (created != null)
                  _MiniPill(icon: Icons.schedule_outlined, text: created),
                if (isOverdue)
                  const _MiniPill(
                    icon: Icons.timer_off_outlined,
                    text: 'Quá hạn SLA',
                    color: Color(0xFFDC2626),
                  ),
              ],
            ),
            if ((report['description'] ?? '').toString().trim().isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                report['description'].toString(),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12, color: opsMutedText),
              ),
            ],
            if ((status == 'OPEN' && canClaim) ||
                (status == 'IN_PROGRESS' && assignedToMe)) ...[
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: status == 'OPEN'
                    ? ElevatedButton.icon(
                        onPressed: reportId == null
                            ? null
                            : () => _confirmClaimDroneReport(report),
                        icon: const Icon(
                          Icons.assignment_turned_in_outlined,
                          size: 17,
                        ),
                        label: const Text('Nhận xử lý'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0284C7),
                          foregroundColor: Colors.white,
                        ),
                      )
                    : TextButton.icon(
                        onPressed: () => _showDroneReportDetail(report),
                        icon: const Icon(Icons.build_outlined, size: 17),
                        label: const Text('Cập nhật xử lý'),
                      ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  bool _isDroneReportAssignedToMe(Map<String, dynamic> report) =>
      _myUserId != null &&
      _myUserId!.isNotEmpty &&
      '${report['assignedToUserId']}' == _myUserId;

  bool _canClaimDroneReport(Map<String, dynamic> report) {
    if (report['status'] != 'OPEN') return false;
    final routedTo = report['routedToUserId']?.toString();
    return routedTo == null || routedTo.isEmpty || routedTo == _myUserId;
  }

  Future<void> _confirmClaimDroneReport(Map<String, dynamic> report) async {
    final reportId = _asInt(report['id']);
    if (reportId == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Nhận xử lý sự cố Drone?'),
        content: Text(
          'Bạn sẽ trở thành KTV phụ trách phiếu RPT-$reportId của '
          'Drone ${report['droneCode'] ?? report['droneUnitId'] ?? '—'}.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Xác nhận nhận việc'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await _runCellAction(
      () => _service.claimDroneReport(reportId),
      'Đã nhận xử lý phiếu Drone RPT-$reportId',
    );
  }

  int _compareDroneReportsNewestFirst(
    Map<String, dynamic> first,
    Map<String, dynamic> second,
  ) {
    final firstDate = parseServerDateTime(first['createdAt']);
    final secondDate = parseServerDateTime(second['createdAt']);
    if (firstDate != null && secondDate != null) {
      return secondDate.compareTo(firstDate);
    }
    return (_asInt(second['id']) ?? 0).compareTo(_asInt(first['id']) ?? 0);
  }

  void _showDroneReportDetail(Map<String, dynamic> report) {
    DroneReportDetailSheet.show(
      context,
      report: report,
      service: _service,
      currentUserId: _myUserId,
      onChanged: _load,
    );
  }

  // ---- Tab đội bay ----
  Widget _buildDroneFleet() {
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          const OpsBanner(
            tone: OpsBannerTone.info,
            icon: Icons.flight_outlined,
            text:
                'Chưa có telemetry thật từ drone: pin do kỹ thuật viên cập nhật tay. '
                'Trạng thái đội bay được đồng bộ từ hệ thống.',
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
        ],
      ),
    );
  }

  // ---- Tab lịch bảo trì ----
  Widget _buildMaintenanceSchedules() {
    final query = _scheduleSearchController.text.trim().toLowerCase();
    final allSchedules = [..._schedules];
    final mine = allSchedules.where(_isScheduleMine).toList();
    final scope = _mySchedulesOnly ? mine : allSchedules;
    final dueCount = scope.where((s) => s['due'] == true).length;
    final upcomingCount = scope.length - dueCount;
    final schedules = scope.where((schedule) {
      final dueMatches = switch (_scheduleDueFilter) {
        'DUE' => schedule['due'] == true,
        'UPCOMING' => schedule['due'] != true,
        _ => true,
      };
      final priority = '${schedule['priority'] ?? 'NORMAL'}'.toUpperCase();
      final priorityMatches =
          _schedulePriorityFilter == 'ALL' ||
          priority == _schedulePriorityFilter;
      final searchable = [
        schedule['id'],
        schedule['title'],
        schedule['description'],
        schedule['droneCode'],
        schedule['lockerName'],
        schedule['lockerCode'],
        schedule['assignedTechnicianName'],
      ].where((value) => value != null).join(' ').toLowerCase();
      return dueMatches &&
          priorityMatches &&
          (query.isEmpty || searchable.contains(query));
    }).toList();
    schedules.sort(
      (a, b) => switch (_scheduleSort) {
        'NEWEST' => _compareNullableDate(b['createdAt'], a['createdAt']),
        'PRIORITY' => _schedulePriorityRank(
          a,
        ).compareTo(_schedulePriorityRank(b)),
        _ => _compareNullableDate(a['nextDueAt'], b['nextDueAt']),
      },
    );

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          const OpsBanner(
            tone: OpsBannerTone.info,
            icon: Icons.event_repeat,
            text:
                'Lịch bảo trì Drone do quản trị tạo. Đánh giá đủ từng mục checklist; '
                'nếu có mục không đạt, Drone chuyển sang trạng thái lỗi và hệ thống mở phiếu sự cố.',
          ),
          if (_scheduleLoadError != null) ...[
            const SizedBox(height: 8),
            OpsBanner(
              tone: OpsBannerTone.danger,
              icon: Icons.cloud_off_outlined,
              text: _scheduleLoadError!,
            ),
            _retryButton(),
          ],
          const SizedBox(height: 10),
          _buildSearchField(
            controller: _scheduleSearchController,
            hint: 'Tìm lịch, mã Drone, KTV phụ trách...',
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _droneFilterChip(
                  label: 'Của tôi (${mine.length})',
                  selected: _mySchedulesOnly,
                  icon: Icons.person_outline,
                  activeColor: const Color(0xFF7C3AED),
                  onTap: () => setState(() => _mySchedulesOnly = true),
                ),
                const SizedBox(width: 7),
                _droneFilterChip(
                  label: 'Tất cả (${allSchedules.length})',
                  selected: !_mySchedulesOnly,
                  icon: Icons.groups_outlined,
                  activeColor: const Color(0xFF0284C7),
                  onTap: () => setState(() => _mySchedulesOnly = false),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final option in [
                  (
                    'ALL',
                    'Mọi hạn (${scope.length})',
                    Icons.event_note_outlined,
                  ),
                  ('DUE', 'Đến hạn ($dueCount)', Icons.warning_amber_rounded),
                  (
                    'UPCOMING',
                    'Sắp tới ($upcomingCount)',
                    Icons.schedule_outlined,
                  ),
                ]) ...[
                  _droneFilterChip(
                    label: option.$2,
                    selected: _scheduleDueFilter == option.$1,
                    icon: option.$3,
                    activeColor: option.$1 == 'DUE'
                        ? const Color(0xFFDC2626)
                        : const Color(0xFF0284C7),
                    onTap: () => setState(() => _scheduleDueFilter = option.$1),
                  ),
                  const SizedBox(width: 7),
                ],
              ],
            ),
          ),
          const SizedBox(height: 7),
          Wrap(
            spacing: 8,
            runSpacing: 7,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _compactDropdown(
                value: _schedulePriorityFilter,
                items: const {
                  'ALL': 'Mọi ưu tiên',
                  'URGENT': 'Khẩn cấp',
                  'HIGH': 'Cao',
                  'NORMAL': 'Bình thường',
                  'LOW': 'Thấp',
                },
                onChanged: (value) =>
                    setState(() => _schedulePriorityFilter = value),
              ),
              _sortMenu(
                value: _scheduleSort,
                values: const {
                  'DUE': 'Hạn gần nhất',
                  'PRIORITY': 'Ưu tiên',
                  'NEWEST': 'Mới tạo',
                },
                onSelected: (value) => setState(() => _scheduleSort = value),
              ),
              if (_scheduleSearchController.text.isNotEmpty ||
                  _schedulePriorityFilter != 'ALL' ||
                  _scheduleDueFilter != 'ALL')
                TextButton.icon(
                  onPressed: _resetScheduleFilters,
                  icon: const Icon(Icons.restart_alt_rounded, size: 17),
                  label: const Text('Đặt lại'),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (schedules.isEmpty && _scheduleLoadError == null)
            OpsEmptyState(
              icon: Icons.event_available_outlined,
              title: _mySchedulesOnly
                  ? 'Không có lịch Drone được giao phù hợp'
                  : 'Không có lịch bảo trì Drone phù hợp',
              subtitle: 'Thử đổi bộ lọc hoặc kéo xuống để tải lại dữ liệu.',
            )
          else
            for (final s in schedules)
              _droneScheduleCard(s, due: s['due'] == true),
        ],
      ),
    );
  }

  // ---- Tab công cụ bay ----
  Widget _buildFlightTools() {
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(12),
        children: [
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
        ],
      ),
    );
  }

  Widget _droneScheduleCard(Map<String, dynamic> s, {required bool due}) {
    final droneLabel = 'Drone ${s['droneCode'] ?? s['droneUnitId']}';
    final nextDue = _fmtDate(s['nextDueAt']);
    final lastDone = _fmtDate(s['lastDoneAt']);
    final id = _asInt(s['id']);
    final assignedToMe = _isScheduleMine(s);
    final assignedId = s['assignedTechnicianId'];
    final pendingReportId = _asInt(s['pendingReportId']);
    final priority = '${s['priority'] ?? 'NORMAL'}'.toUpperCase();
    final priorityInfo = _priorityInfo(priority);
    final blocked =
        pendingReportId != null || (assignedId != null && !assignedToMe);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: OpsCard(
        onTap: () => _showDroneScheduleDetail(s),
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
                const SizedBox(width: 6),
                _MiniPill(
                  icon: Icons.flag_outlined,
                  text: priorityInfo.$1,
                  color: priorityInfo.$2,
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
                if (s['assignedTechnicianName'] != null)
                  _MiniPill(
                    icon: Icons.engineering_outlined,
                    text: '${s['assignedTechnicianName']}',
                    color: assignedToMe
                        ? const Color(0xFF7C3AED)
                        : const Color(0xFF64748B),
                  ),
              ],
            ),
            if (pendingReportId != null) ...[
              const SizedBox(height: 8),
              OpsBanner(
                tone: OpsBannerTone.warning,
                icon: Icons.report_problem_outlined,
                text:
                    'Cần hoàn tất phiếu RPT-$pendingReportId trước lần kiểm tra tiếp theo.',
              ),
            ],
            const SizedBox(height: 10),
            Row(
              children: [
                OutlinedButton.icon(
                  onPressed: () => _showDroneScheduleDetail(s),
                  icon: const Icon(Icons.info_outline, size: 16),
                  label: const Text('Chi tiết'),
                ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: id == null || blocked
                      ? null
                      : () => _showDroneInspectionSheet(s),
                  icon: const Icon(Icons.fact_check_outlined, size: 16),
                  label: Text(due ? 'Kiểm tra ngay' : 'Kiểm tra'),
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

  bool _isScheduleMine(Map<String, dynamic> schedule) =>
      _myUserId != null &&
      schedule['assignedTechnicianId']?.toString() == _myUserId;

  Widget _retryButton() => Align(
    alignment: Alignment.centerRight,
    child: TextButton.icon(
      onPressed: _load,
      icon: const Icon(Icons.refresh_rounded, size: 18),
      label: const Text('Thử lại'),
    ),
  );

  int _schedulePriorityRank(Map<String, dynamic> schedule) =>
      switch ('${schedule['priority'] ?? 'NORMAL'}'.toUpperCase()) {
        'URGENT' => 0,
        'HIGH' => 1,
        'NORMAL' => 2,
        'LOW' => 3,
        _ => 4,
      };

  (String, Color) _priorityInfo(String priority) => switch (priority) {
    'URGENT' => ('Khẩn cấp', const Color(0xFFDC2626)),
    'HIGH' => ('Ưu tiên cao', const Color(0xFFEA580C)),
    'LOW' => ('Ưu tiên thấp', const Color(0xFF64748B)),
    _ => ('Bình thường', const Color(0xFF0284C7)),
  };

  void _resetScheduleFilters() {
    _scheduleSearchController.clear();
    setState(() {
      _scheduleDueFilter = 'ALL';
      _schedulePriorityFilter = 'ALL';
      _scheduleSort = 'DUE';
    });
  }

  void _showDroneScheduleDetail(Map<String, dynamic> schedule) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => ScheduleDetailModalSheet(
        schedule: schedule,
        service: _service,
        isMine: _isScheduleMine(schedule),
        onOpenDirections: _openScheduleDirections,
        onOpenReport: _openDroneReportById,
        onStartInspection: _showDroneInspectionSheet,
      ),
    );
  }

  Future<void> _showDroneInspectionSheet(Map<String, dynamic> schedule) async {
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) =>
          CompleteInspectionSheet(schedule: schedule, service: _service),
    );
    if (result == null || !mounted) return;
    final failed = result['lastResult'] == 'FAILED';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: failed
            ? const Color(0xFFDC2626)
            : const Color(0xFF16A34A),
        content: Text(
          failed
              ? 'Đã ghi nhận bảo trì KHÔNG ĐẠT. Drone đã chuyển sang lỗi và phiếu sự cố được mở theo phản hồi Backend.'
              : 'Đã ghi nhận bảo trì ĐẠT và cập nhật chu kỳ tiếp theo.',
        ),
      ),
    );
    await _load();
  }

  void _openDroneReportById(int reportId) {
    Map<String, dynamic>? report;
    for (final item in _droneReports) {
      if (_asInt(item['id']) == reportId) {
        report = item;
        break;
      }
    }
    if (report != null) {
      _showDroneReportDetail(report);
      return;
    }
    _service
        .getDroneReport(reportId)
        .then((value) {
          if (mounted) _showDroneReportDetail(value);
        })
        .catchError((Object error) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(LockerOpsService.errorMessage(error))),
            );
          }
        });
  }

  Future<void> _openScheduleDirections(Map<String, dynamic> schedule) async {
    final address = '${schedule['address'] ?? ''}'.trim();
    if (address.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Lịch này chưa có địa chỉ trạm Drone.')),
        );
      }
      return;
    }
    final uri = Uri.https('www.google.com', '/maps/search/', {
      'api': '1',
      'query': address,
    });
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication) &&
        mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không thể mở ứng dụng bản đồ.')),
      );
    }
  }

  String? _fmtDate(dynamic value) {
    final d = parseServerDateTime(value);
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
    final reservedBoxId = _asInt(order['reservedBoxId']);
    final description = order['description']?.toString();
    final droneCode = order['droneCode']?.toString();
    final missionStatus = order['missionStatus']?.toString();
    final orderCode = order['orderCode']?.toString();
    final stage = DroneDeliveryStage.fromRaw(
      order['deliveryStage']?.toString(),
    );
    final boxNumber = _asInt(order['reservedBoxNumber']);
    final updatedAt = parseServerDateTime(order['updatedAt']);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: orderId == null ? null : () => _showDeliveryDetail(orderId),
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
                          '${_lockerPointName(order['sourceLocker'], order['sourceLockerId'], 'Tủ nguồn')} '
                          '→ ${_lockerPointName(order['destinationLocker'], lockerId, 'Tủ đích')}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: opsDark,
                          ),
                        ),
                        Text(
                          [
                            if (orderCode != null && orderCode.isNotEmpty)
                              orderCode,
                            if (boxNumber != null)
                              'Ô nhận số $boxNumber'
                            else if (reservedBoxId != null)
                              'Đã giữ ô nhận',
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
                  if (!((action == _DeliveryAction.load ||
                          action == _DeliveryAction.launch) &&
                      onCancel != null))
                    FilledButton.icon(
                      onPressed: _actionEnabled(action, orderId, order)
                          ? () => _handleDeliveryAction(order, action)
                          : null,
                      style: FilledButton.styleFrom(
                        backgroundColor: switch (action) {
                          _DeliveryAction.accept => const Color(0xFF6366F1),
                          _DeliveryAction.load => const Color(0xFFF59E0B),
                          _DeliveryAction.launch => const Color(0xFF16A34A),
                          _DeliveryAction.launching => const Color(0xFF94A3B8),
                          _DeliveryAction.track => const Color(0xFF1E5A8A),
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
                        _DeliveryAction.load => Icons.inventory_2_outlined,
                        _DeliveryAction.launch => Icons.rocket_launch,
                        _DeliveryAction.launching => Icons.hourglass_top,
                        _DeliveryAction.track => Icons.route,
                      }, size: 15),
                      label: Text(
                        switch (action) {
                          _DeliveryAction.accept => 'Tiếp nhận',
                          _DeliveryAction.load => 'Xác nhận nạp',
                          _DeliveryAction.launch => 'Phóng',
                          _DeliveryAction.launching => 'Đang phóng',
                          _DeliveryAction.track => 'Theo dõi',
                        },
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                ],
              ),
              if ((action == _DeliveryAction.load ||
                      action == _DeliveryAction.launch) &&
                  onCancel != null) ...[
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.end,
                  children: [
                    if (action == _DeliveryAction.load)
                      FilledButton.icon(
                        onPressed: _actionEnabled(action, orderId, order)
                            ? () => _handleDeliveryAction(order, action)
                            : null,
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFFF59E0B),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        icon: const Icon(Icons.inventory_2_outlined, size: 15),
                        label: const Text(
                          'Xác nhận nạp',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    if (action == _DeliveryAction.launch)
                      FilledButton.icon(
                        onPressed: _actionEnabled(action, orderId, order)
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
                      onPressed: _ownsMission(order) ? onCancel : null,
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
              if (_parcelSummary(order) != null) ...[
                const SizedBox(height: 4),
                Text(
                  'Kiện: ${_parcelSummary(order)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: order['fragile'] == true
                        ? const Color(0xFFB45309)
                        : Colors.black54,
                    fontWeight: order['fragile'] == true
                        ? FontWeight.w700
                        : FontWeight.w400,
                  ),
                ),
              ],
              if (_advanceLabel(order) != null) ...[
                if (order['liveTracking'] == true) ...[
                  const SizedBox(height: 8),
                  const _MiniPill(
                    icon: Icons.sensors,
                    text: 'Drone đang gửi tín hiệu · chặng bay tự cập nhật',
                    color: Color(0xFF0F766E),
                  ),
                ],
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () => _advanceFlow(order),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF0F766E),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    icon: const Icon(Icons.check_circle_outline, size: 16),
                    label: Text(
                      'Xác nhận ${_advanceLabel(order)}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
              if (_canReportFailure(order)) ...[
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    key: const ValueKey('drone-report-flight-failure'),
                    onPressed: () => _cancelDeliveryFlow(order, inFlight: true),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFDC2626),
                      side: const BorderSide(color: Color(0xFFDC2626)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    icon: const Icon(Icons.report_problem_outlined, size: 16),
                    label: const Text(
                      'Báo chuyến bay thất bại',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
              if (action == _DeliveryAction.accept && !_isPaid(order)) ...[
                const SizedBox(height: 8),
                const _MiniPill(
                  icon: Icons.payments_outlined,
                  text: 'Chưa thanh toán · chưa thể tiếp nhận',
                  color: Color(0xFFB45309),
                ),
              ],
              if (action == _DeliveryAction.accept &&
                  _isPaid(order) &&
                  !_parcelDropped(order)) ...[
                const SizedBox(height: 8),
                const _MiniPill(
                  icon: Icons.inventory_2_outlined,
                  text: 'Người gửi chưa bỏ kiện vào ô gửi · chưa thể tiếp nhận',
                  color: Color(0xFFB45309),
                ),
              ],
              if (action == _DeliveryAction.launch && !_isPaid(order)) ...[
                const SizedBox(height: 8),
                const _MiniPill(
                  icon: Icons.scale_outlined,
                  text: 'Kiện nặng hơn khai báo · chờ khách trả thêm phí',
                  color: Color(0xFFB45309),
                ),
              ],
              const SizedBox(height: 8),
              Text(
                [
                  'Chặng: ${stage.title}',
                  if (missionStatus != null && missionStatus.isNotEmpty)
                    'Nhiệm vụ: ${droneMissionStatusLabel(missionStatus)}',
                ].join(' · '),
                style: const TextStyle(fontSize: 12, color: Colors.black54),
              ),
              if (updatedAt != null) ...[
                const SizedBox(height: 4),
                Text(
                  'Cập nhật ${formatDateTimeVn(updatedAt)} · chạm để xem chi tiết',
                  style: const TextStyle(fontSize: 11, color: Colors.black45),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _lockerPointName(dynamic raw, dynamic fallbackId, String fallback) {
    final map = raw is Map ? raw : null;
    final name = map?['name'] ?? map?['code'];
    if (name != null && '$name'.trim().isNotEmpty) return '$name';
    return fallbackId == null ? fallback : '$fallback #$fallbackId';
  }

  /// Chi tiết nhiệm vụ + nhật ký hành trình, tự làm mới khi sheet đang mở.
  Future<void> _showDeliveryDetail(int orderId) async {
    await showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: const Color(0xFFF6F8FB),
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: .88,
        maxChildSize: .96,
        builder: (ctx, controller) => _DroneOrderDetailSheet(
          orderId: orderId,
          service: _service,
          scrollController: controller,
        ),
      ),
    );
  }

  bool _actionEnabled(
    _DeliveryAction action,
    int? orderId,
    Map<String, dynamic> order,
  ) {
    if (orderId == null) return false;
    if (action == _DeliveryAction.launching) return false;
    if (action == _DeliveryAction.track) return true;
    // Quy tắc backend: chưa PAID thì accept bị từ chối (DRONE_ORDER_UNPAID).
    // …và người gửi chưa bỏ kiện vào ô gửi thì cũng bị từ chối (DRONE_PARCEL_NOT_DROPPED).
    if (action == _DeliveryAction.accept) {
      return _isPaid(order) && _parcelDropped(order);
    }
    // Kiện nặng hơn khai báo làm đơn nợ phí chênh: chưa trả thì chưa phóng
    // (DRONE_SURCHARGE_UNPAID).
    if (action == _DeliveryAction.launch && !_isPaid(order)) return false;
    return _ownsMission(order);
  }

  static const _nextStageLabels = <String, String>{
    'LAUNCHING': 'drone đã rời trạm',
    'DEPARTED': 'drone đang trên đường',
    'EN_ROUTE': 'drone sắp tới tủ nhận',
    'APPROACHING': 'drone đã tới tủ nhận',
    'ARRIVED': 'hàng đã vào ô tủ nhận',
  };

  /// Nhãn chặng kế tiếp nếu điều phối viên này được xác nhận tay; null nếu không.
  /// Chỉ đơn drone thật: đơn DEMO do bộ giả lập tự đẩy chặng.
  String? _advanceLabel(Map<String, dynamic> order) {
    if ('${order['fulfillmentMode']}'.toUpperCase() == 'DEMO') return null;
    if (order['assignedByUserId'] == null || !_ownsMission(order)) return null;
    return _nextStageLabels['${order['deliveryStage']}'];
  }

  /// Chuyến bay đã phóng (kể cả đơn DEMO) mà không giao được: chỉ điều phối viên
  /// đã nhận nhiệm vụ được báo — khớp `reportFlightFailure` ở backend.
  bool _canReportFailure(Map<String, dynamic> order) =>
      order['assignedByUserId'] != null &&
      _ownsMission(order) &&
      const {
        'LAUNCHING',
        'DEPARTED',
        'EN_ROUTE',
        'APPROACHING',
        'ARRIVED',
      }.contains('${order['deliveryStage']}');

  Future<void> _advanceFlow(Map<String, dynamic> order) async {
    final orderId = _asInt(order['orderId']);
    final label = _advanceLabel(order);
    if (orderId == null || label == null) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Xác nhận chặng bay'),
        content: Text(
          'Xác nhận $label?\n\nKhách sẽ thấy chặng mới ngay và không hoàn tác được.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Chưa'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Xác nhận'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await _run(
      () => _service.advanceDroneOrder(orderId),
      'Đã xác nhận: $label',
    );
  }

  /// Server cũ chưa theo dõi mốc bỏ kiện (không trả `parcelReturnPending`) thì
  /// không chặn tiếp nhận ở client.
  bool _parcelDropped(Map<String, dynamic> order) =>
      order['parcelReturnPending'] == null || order['parcelDroppedAt'] != null;

  /// `Điện tử · 30 × 20 × 10 cm · DỄ VỠ`; null khi đơn không có khai báo kiện.
  String? _parcelSummary(Map<String, dynamic> order) {
    final category = order['parcelCategory']?.toString();
    final size = droneParcelSizeLabel(
      _asInt(order['parcelLengthCm']),
      _asInt(order['parcelWidthCm']),
      _asInt(order['parcelHeightCm']),
    );
    final parts = [
      if (category != null && category.isNotEmpty)
        droneParcelCategoryLabel(category),
      ?size,
      if (order['declaredValue'] != null)
        'khai báo ${fmtPrice(order['declaredValue'])}',
      if (order['fragile'] == true) 'DỄ VỠ',
    ];
    return parts.isEmpty ? null : parts.join(' · ');
  }

  /// Đơn không giao được mà kiện chờ trả: ai, kiện ở đâu, nút xác nhận đã trả.
  Widget _parcelReturnCard(Map<String, dynamic> order) {
    final orderId = _asInt(order['orderId']);
    final sourceBox = _asInt(order['sourceBoxNumber']);
    final inSourceBox =
        '${order['parcelHeldAt']}'.toUpperCase() == 'SOURCE_BOX';
    final sender = [
      order['customerName'],
      order['customerPhone'],
    ].where((v) => v != null && '$v'.trim().isNotEmpty).join(' · ');
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: orderId == null ? null : () => _showDeliveryDetail(orderId),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFFB45309).withValues(alpha: 0.4),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${order['orderCode'] ?? 'Đơn #$orderId'} · '
                '${DroneDeliveryStage.fromRaw(order['deliveryStage']?.toString()) == DroneDeliveryStage.failed ? 'chuyến bay thất bại' : 'đã huỷ'}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: opsDark,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                inSourceBox
                    ? 'Kiện còn trong ô gửi${sourceBox == null ? '' : ' số $sourceBox'} · '
                          '${_lockerPointName(order['sourceLocker'], order['sourceLockerId'], 'Tủ gửi')}'
                    : 'Kiện đang do đội bay giữ',
                style: const TextStyle(fontSize: 12, color: Colors.black54),
              ),
              if (sender.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  'Người gửi: $sender',
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                ),
              ],
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  key: ValueKey('drone-parcel-return-$orderId'),
                  onPressed: orderId != null && _ownsMission(order)
                      ? () => _confirmParcelReturnFlow(order)
                      : null,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFB45309),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  icon: const Icon(
                    Icons.assignment_turned_in_outlined,
                    size: 16,
                  ),
                  label: const Text(
                    'Xác nhận đã trả kiện',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmParcelReturnFlow(Map<String, dynamic> order) async {
    final orderId = _asInt(order['orderId']);
    if (orderId == null) return;
    final noteCtrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Xác nhận đã trả kiện'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Chỉ xác nhận khi kiện đã về tay người gửi. Ô gửi còn giữ cho đơn '
              'này sẽ được nhả.',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: noteCtrl,
              minLines: 1,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Ghi chú (tùy chọn)',
                isDense: true,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Chưa'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Đã trả kiện'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await _run(
      () => _service.confirmDroneParcelReturn(orderId, note: noteCtrl.text),
      'Đã ghi nhận trả kiện cho người gửi',
    );
  }

  bool _isPaid(Map<String, dynamic> order) =>
      '${order['paymentStatus']}'.toUpperCase() == 'PAID';

  String _routeLabel(Map<String, dynamic> order) =>
      '${_lockerPointName(order['sourceLocker'], order['sourceLockerId'], 'Tủ gửi')} '
      '→ ${_lockerPointName(order['destinationLocker'], order['destinationLockerId'], 'Tủ nhận')}';

  bool _ownsMission(Map<String, dynamic> order) {
    final assignedBy = order['assignedByUserId'];
    // Cho phép payload server cũ chưa có field này trong giai đoạn rolling deploy.
    return assignedBy == null || '$assignedBy' == _myUserId;
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
      case _DeliveryAction.load:
        await _confirmLoadingFlow(order);
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
      case _DeliveryAction.track:
        await _showDeliveryDetail(orderId);
    }
  }

  Future<void> _confirmLoadingFlow(Map<String, dynamic> order) async {
    final orderId = _asInt(order['orderId']);
    if (orderId == null) return;
    final weightCtrl = TextEditingController(
      text:
          // Mặc định là khối lượng khách khai báo (`parcelWeightGrams` của read
          // model; `expectedWeightGrams` là tên field ở response accept/launch).
          '${_asInt(order['payloadWeightGrams']) ?? _asInt(order['parcelWeightGrams']) ?? _asInt(order['expectedWeightGrams']) ?? 1200}',
    );
    // Mã niêm phong do hệ thống cấp cho lần nạp này — đội viên ghi/dán lên niêm
    // phong, không tự nhập.
    final sealCode = generateDroneSealCode();
    final config = BusinessConfigService.instance.current;
    final declaredGrams =
        _asInt(order['parcelWeightGrams']) ??
        _asInt(order['expectedWeightGrams']);
    final totalRaw = order['totalPrice'];
    final currentTotal = totalRaw is num ? totalRaw : num.tryParse('$totalRaw');
    // Phần thu thêm ước tính theo bảng giá; server tính lại khi xác nhận.
    int surchargeFor(String text) {
      final actual = int.tryParse(text.trim());
      if (actual == null || declaredGrams == null || currentTotal == null) {
        return 0;
      }
      return config.droneWeightSurcharge(
        declaredGrams: declaredGrams,
        actualGrams: actual,
        currentTotal: currentTotal,
      );
    }

    final noteCtrl = TextEditingController();
    var parcelMatched = false;
    var payloadSecured = false;
    var compartmentLocked = false;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text('Xác nhận nạp hàng'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Cân kiện và hoàn tất toàn bộ checklist trước khi cho phép phóng.',
                ),
                const SizedBox(height: 12),
                TextField(
                  key: const ValueKey('drone-loading-weight'),
                  controller: weightCtrl,
                  keyboardType: TextInputType.number,
                  onChanged: (_) => setLocal(() {}),
                  decoration: const InputDecoration(
                    labelText: 'Khối lượng thực tế (gram)',
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  declaredGrams == null
                      ? 'Khách chưa khai báo khối lượng.'
                      : 'Khách khai báo ${droneWeightLabel(declaredGrams)}'
                            '${currentTotal == null ? '' : ' · phí đã tính ${fmtPrice(currentTotal)}'}.',
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                ),
                if (surchargeFor(weightCtrl.text) > 0) ...[
                  const SizedBox(height: 6),
                  Text(
                    'Nặng hơn khai báo: khách phải trả thêm '
                    '${fmtPrice(surchargeFor(weightCtrl.text))}. Drone chỉ phóng được '
                    'sau khi khách thanh toán.',
                    key: const ValueKey('drone-loading-surcharge'),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFB45309),
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                InputDecorator(
                  key: const ValueKey('drone-loading-seal'),
                  decoration: const InputDecoration(
                    labelText: 'Mã niêm phong (hệ thống cấp)',
                    isDense: true,
                    helperText: 'Ghi mã này lên niêm phong của kiện.',
                  ),
                  child: SelectableText(
                    sealCode,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                CheckboxListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  value: parcelMatched,
                  onChanged: (value) =>
                      setLocal(() => parcelMatched = value ?? false),
                  title: const Text('Đúng kiện hàng và đúng đơn'),
                ),
                CheckboxListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  value: payloadSecured,
                  onChanged: (value) =>
                      setLocal(() => payloadSecured = value ?? false),
                  title: const Text('Kiện hàng đã được cố định'),
                ),
                CheckboxListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  value: compartmentLocked,
                  onChanged: (value) =>
                      setLocal(() => compartmentLocked = value ?? false),
                  title: const Text('Khoang hàng đã khóa'),
                ),
                TextField(
                  controller: noteCtrl,
                  minLines: 1,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Ghi chú (tùy chọn)',
                    isDense: true,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Đóng'),
            ),
            FilledButton(
              onPressed: () {
                final weight = int.tryParse(weightCtrl.text.trim());
                if (weight == null ||
                    weight <= 0 ||
                    !parcelMatched ||
                    !payloadSecured ||
                    !compartmentLocked) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Nhập khối lượng thực tế và hoàn tất checklist',
                      ),
                    ),
                  );
                  return;
                }
                Navigator.pop(ctx, true);
              },
              child: const Text('Xác nhận đã nạp'),
            ),
          ],
        ),
      ),
    );

    if (confirmed == true) {
      await _confirmLoading(
        orderId,
        payloadWeightGrams: int.parse(weightCtrl.text.trim()),
        sealCode: sealCode,
        parcelMatched: parcelMatched,
        payloadSecured: payloadSecured,
        compartmentLocked: compartmentLocked,
        note: noteCtrl.text,
      );
    }
    // showDialog hoàn tất future trước khi animation tháo hẳn route. Trì hoãn
    // dispose để TextField không còn subscribe controller trong frame cuối.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      weightCtrl.dispose();
      noteCtrl.dispose();
    });
  }

  /// Gửi xác nhận nạp hàng rồi báo theo kết quả server: kiện nặng hơn khai báo thì
  /// đơn nợ phần phí chênh và chưa phóng được.
  Future<void> _confirmLoading(
    int orderId, {
    required int payloadWeightGrams,
    required String sealCode,
    required bool parcelMatched,
    required bool payloadSecured,
    required bool compartmentLocked,
    required String note,
  }) async {
    String message;
    try {
      final result = await _service.confirmDroneLoading(
        orderId,
        payloadWeightGrams: payloadWeightGrams,
        sealCode: sealCode,
        parcelMatched: parcelMatched,
        payloadSecured: payloadSecured,
        compartmentLocked: compartmentLocked,
        note: note,
        idempotencyKey: _idempotencyKey('load', orderId),
      );
      final surchargeRaw = result['weightSurcharge'];
      final surcharge = surchargeRaw is num
          ? surchargeRaw
          : num.tryParse('$surchargeRaw') ?? 0;
      final seal = result['sealCode'] ?? sealCode;
      message = surcharge > 0
          ? 'Đã nạp hàng (niêm phong $seal). Kiện nặng hơn khai báo — chờ khách '
                'trả thêm ${fmtPrice(surcharge)} rồi mới phóng.'
          : 'Đã xác nhận nạp hàng (niêm phong $seal) — nhiệm vụ sẵn sàng phóng';
    } catch (e) {
      message = LockerOpsService.errorMessage(e);
    }
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
    await _load();
  }

  /// [inFlight] = drone đã phóng: báo chuyến bay thất bại thay vì huỷ trước khi bay.
  Future<void> _cancelDeliveryFlow(
    Map<String, dynamic> order, {
    bool inFlight = false,
  }) async {
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
          title: Text(
            inFlight ? 'Báo chuyến bay thất bại' : 'Hủy nhiệm vụ trước khi bay',
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (inFlight) ...[
                const Text(
                  'Đơn sẽ đóng lại và khách được hoàn tiền; drone chuyển sang '
                  'trạng thái lỗi cho tới khi bạn kiểm tra xong. Không hoàn tác được.',
                  style: TextStyle(fontSize: 13, color: Colors.black87),
                ),
                const SizedBox(height: 12),
              ],
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
              child: Text(inFlight ? 'Xác nhận thất bại' : 'Xác nhận hủy'),
            ),
          ],
        ),
      ),
    );

    if (confirmed != true) {
      return;
    }

    final note = noteCtrl.text.trim().isEmpty ? null : noteCtrl.text.trim();
    await _run(
      () => inFlight
          ? _service.failDroneOrder(
              orderId,
              reasonCode: selectedReason.code,
              note: note,
            )
          : _service.cancelDroneOrder(
              orderId,
              reasonCode: selectedReason.code,
              note: note,
            ),
      inFlight
          ? 'Đã báo chuyến bay thất bại · khách được hoàn tiền'
          : 'Đã hủy nhiệm vụ drone',
    );
  }

  /// Chọn drone IDLE rồi tiếp nhận nhiệm vụ theo `orderId`.
  Future<void> _acceptFlow(Map<String, dynamic> order) async {
    final id = _asInt(order['orderId']);
    if (id == null) return;
    final candidates = _drones
        .where(
          (d) =>
              d['status'] == 'IDLE' &&
              (_asInt(order['sourceLockerId']) == null ||
                  _asInt(d['lockerId']) == _asInt(order['sourceLockerId'])),
        )
        .toList(growable: false);
    if (candidates.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Tủ gửi của đơn không có drone nào đang sẵn sàng (IDLE)',
            ),
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
                'Tuyến ${_routeLabel(order)}'
                '${order['reservedBoxNumber'] != null ? ' · ô nhận số ${order['reservedBoxNumber']}' : ''}.\n'
                'Chọn drone đang sẵn sàng tại tủ gửi:',
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
              // Đợi bottom sheet bị tháo khỏi widget tree trước khi mở dialog
              // tiếp theo. Mở ngay trong cùng frame làm Flutter dispose route
              // trong khi các inherited dependencies của sheet còn được dùng.
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) onTap();
              });
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
                if (assignedToMe) ...[
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
                ],
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
    final currentStatus = drone['status'] as String? ?? 'IDLE';
    String selected = currentStatus;

    final result = await showDialog<String>(
      context: context,
      // reasonCtrl được huỷ khi dialog gỡ khỏi cây (sau hiệu ứng đóng).
      builder: (ctx) => ControllerDisposer(
        controllers: [reasonCtrl],
        child: StatefulBuilder(
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
                    for (final s in _manualDroneStatuses(currentStatus))
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
      ),
    );
    final isFault = result == 'FAULT';
    // Lý do chỉ có ý nghĩa với FAULT — bỏ qua text sót lại nếu đổi sang trạng thái khác.
    final reason = isFault ? reasonCtrl.text.trim() : '';
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
      // ctrl được huỷ khi dialog gỡ khỏi cây (sau hiệu ứng đóng).
      builder: (ctx) => ControllerDisposer(
        controllers: [ctrl],
        child: AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
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
      ),
    );
    final percent = int.tryParse(ctrl.text.trim());
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
    final d = parseServerDateTime(value);
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

enum _DeliveryAction { accept, load, launch, launching, track }

/// Nội dung sheet chi tiết nhiệm vụ. Hỏi lại server mỗi 3 giây và mỗi khi có
/// sự kiện đơn hàng, để điều phối viên thấy chặng mới mà không cần đóng/mở lại.
class _DroneOrderDetailSheet extends StatefulWidget {
  const _DroneOrderDetailSheet({
    required this.orderId,
    required this.service,
    required this.scrollController,
  });

  final int orderId;
  final LockerOpsService service;
  final ScrollController scrollController;

  @override
  State<_DroneOrderDetailSheet> createState() => _DroneOrderDetailSheetState();
}

class _DroneOrderDetailSheetState extends State<_DroneOrderDetailSheet> {
  DroneDeliveryStatus? _status;
  String? _error;
  Timer? _timer;
  StreamSubscription<AppEvent>? _events;
  bool _fetching = false;

  @override
  void initState() {
    super.initState();
    _refresh();
    _timer = Timer.periodic(const Duration(seconds: 3), (_) => _refresh());
    _events = AppEventBus.instance.events.listen((event) {
      if (event is OrderChangedEvent) _refresh();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _events?.cancel();
    super.dispose();
  }

  Future<void> _refresh() async {
    if (_fetching) return;
    _fetching = true;
    try {
      final detail = await widget.service.droneOrderDetail(widget.orderId);
      if (!mounted) return;
      setState(() {
        _status = DroneDeliveryResponse.fromJson(detail).toEntity();
        _error = null;
      });
    } catch (error) {
      // Giữ dữ liệu cuối cùng khi mất mạng; chỉ báo lỗi nếu chưa tải được lần nào.
      if (mounted && _status == null) {
        setState(() => _error = LockerOpsService.errorMessage(error));
      }
    } finally {
      _fetching = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = _status;
    return ListView(
      controller: widget.scrollController,
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
      children: [
        const Text(
          'Chi tiết nhiệm vụ drone',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 4),
        const Text(
          'Tự cập nhật theo thời gian thực',
          style: TextStyle(fontSize: 12, color: opsMutedText),
        ),
        const SizedBox(height: 14),
        if (status != null)
          DroneDeliveryDetail(status: status, forOperator: true)
        else if (_error != null)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 32),
            child: Column(
              children: [
                Text(_error!, textAlign: TextAlign.center),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: _refresh,
                  child: const Text('Thử lại'),
                ),
              ],
            ),
          )
        else
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 48),
            child: Center(
              child: CircularProgressIndicator(color: AislBrand.navy),
            ),
          ),
      ],
    );
  }
}

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
const _droneStatuses = ['IDLE', 'CHARGING', 'MAINTENANCE', 'FAULT'];

List<String> _manualDroneStatuses(String current) {
  if (current == 'RESERVED' || current == 'IN_FLIGHT') {
    return [current, 'FAULT'];
  }
  return _droneStatuses;
}

String _droneStatusLabel(String? status) => switch (status) {
  'IDLE' => 'Sẵn sàng',
  'RESERVED' => 'Đã giữ cho nhiệm vụ',
  'CHARGING' => 'Đang sạc',
  'IN_FLIGHT' => 'Đang bay',
  'MAINTENANCE' => 'Đang bảo trì',
  'FAULT' => 'Lỗi',
  _ => status ?? '',
};

Color _droneStatusColor(String? status) => switch (status) {
  'IDLE' => const Color(0xFF16A34A),
  'RESERVED' => const Color(0xFF0F766E),
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

class _DroneSlaBadge extends StatelessWidget {
  const _DroneSlaBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFFECFDF5),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFA7F3D0)),
      ),
      child: const Text(
        'Đạt chuẩn SLA',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: Color(0xFF166534),
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
