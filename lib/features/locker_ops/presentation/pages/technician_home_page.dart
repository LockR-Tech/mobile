import 'package:smart_laundry_locker/core/utils/app_date_time.dart';
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_laundry_locker/core/config/business_config_service.dart';
import 'package:smart_laundry_locker/core/media/media.dart';
import 'package:smart_laundry_locker/core/routing/app_router.dart';
import 'package:smart_laundry_locker/core/services/token_service.dart';
import 'package:smart_laundry_locker/features/assistant/presentation/widgets/assistant_entry.dart';
import 'package:smart_laundry_locker/features/locker_ops/data/locker_ops_service.dart';
import 'package:smart_laundry_locker/features/locker_ops/presentation/utils/locker_maps.dart';
import 'package:smart_laundry_locker/features/locker_ops/presentation/widgets/complete_inspection_sheet.dart';
import 'package:smart_laundry_locker/features/locker_ops/presentation/widgets/locker_picker.dart';
import 'package:smart_laundry_locker/features/locker_ops/presentation/widgets/ops_widgets.dart';
import 'package:provider/provider.dart';
import 'package:smart_laundry_locker/features/profile/presentation/providers/profile_provider.dart';
import 'package:smart_laundry_locker/shared/widgets/user_ui_kit.dart';
import 'package:smart_laundry_locker/features/locker_ops/presentation/pages/technician_profile_page.dart';

/// Home for the LOCKER_TECHNICIAN role (kỹ thuật viên tủ): physical locker
/// maintenance (fault cells, work queue, preventive schedules, landing pad)
/// + IoT device management. Drone fleet operations live with the
/// DRONE_TECHNICIAN role.
class TechnicianHomePage extends StatefulWidget {
  const TechnicianHomePage({this.initialTab = 0, super.key});

  /// Tab mở sẵn (xem `technicianTabs` trong role_routes) — noti KTV tủ trỏ tới.
  final int initialTab;

  @override
  State<TechnicianHomePage> createState() => _TechnicianHomePageState();
}

class _TechnicianHomePageState extends State<TechnicianHomePage>
    with SingleTickerProviderStateMixin {
  final _service = LockerOpsService();
  late final TabController _tabs = TabController(
    length: 5,
    vsync: this,
    initialIndex: widget.initialTab.clamp(0, 4),
  );

  List<Map<String, dynamic>> _faults = [];
  List<Map<String, dynamic>> _reports = [];
  List<Map<String, dynamic>> _myReports = [];
  // Phiếu OPEN của các tủ mình phụ trách, chờ mình nhận (`reports?routed=true`).
  List<Map<String, dynamic>> _routedReports = [];
  // Tủ mình phụ trách (`lockers?mine=true`).
  List<Map<String, dynamic>> _myLockers = [];
  String _queueView = 'ALL';

  /// Lọc tab Sự cố theo trạng thái phiếu: ALL / OPEN / IN_PROGRESS / RESOLVED.
  String _reportStatusFilter = 'ALL';
  List<Map<String, dynamic>> _schedules = [];
  String _scheduleFilter = 'ALL';
  // Của tôi (lịch giao cho mình) / Tất cả lịch tủ.
  bool _mySchedulesOnly = true;
  // Cảnh báo phần cứng toàn cục (GAP 2): ô cửa-mở-bất-thường trên mọi tủ.
  List<Map<String, dynamic>> _anomalies = [];
  bool _loading = true;
  String? _myUserId;
  String? _jwtUserName;
  String? _jwtUserEmail;
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

  // Local SLA extensions cache (đồng bộ với Admin localStorage: locker_sla_extensions_v1)
  Map<int, Map<String, dynamic>> _localSlaExtensions = {};

  Future<void> _loadLocalSlaExtensions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('locker_sla_extensions_v1');
      if (raw != null && raw.isNotEmpty) {
        final decoded = jsonDecode(raw);
        if (decoded is Map) {
          _localSlaExtensions = decoded.map((k, v) =>
              MapEntry(int.parse('$k'), Map<String, dynamic>.from(v as Map)));
        }
      }
    } catch (_) {}
  }

  Future<void> _saveLocalSlaExtensions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final mapped =
          _localSlaExtensions.map((k, v) => MapEntry(k.toString(), v));
      await prefs.setString('locker_sla_extensions_v1', jsonEncode(mapped));
    } catch (_) {}
  }

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
    _loadLocalSlaExtensions().then((_) {
      if (mounted) setState(() {});
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        try {
          final profileProvider = context.read<ProfileProvider>();
          if (profileProvider.profile == null) {
            profileProvider.loadProfile();
          }
        } catch (_) {}
      }
    });
    _load();
  }

  @override
  void didUpdateWidget(covariant TechnicianHomePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Bấm noti khi đang ở sẵn trang này ⇒ chỉ đổi tab.
    if (widget.initialTab != oldWidget.initialTab) {
      _tabs.animateTo(widget.initialTab.clamp(0, 4));
    }
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      _myUserId = await TokenService.getUserId();
      _jwtUserName = await TokenService.getUserName();
      _jwtUserEmail = await TokenService.getUserEmail();
      List<Map<String, dynamic>> rawFaults = [];
      try {
        rawFaults = await _service.faults();
      } catch (_) {}

      List<Map<String, dynamic>> rawReports = [];
      try {
        rawReports = await _service.allKioskReports();
      } catch (_) {}

      List<Map<String, dynamic>> rawMine = [];
      try {
        rawMine = await _service.reports(mine: true);
      } catch (_) {}

      List<Map<String, dynamic>> rawRouted = [];
      try {
        rawRouted = await _service.routedReports();
      } catch (_) {}

      List<Map<String, dynamic>> lockers = [];
      try {
        lockers = await _service.lockers();
      } catch (_) {}

      List<Map<String, dynamic>> myLockers = [];
      try {
        myLockers = await _service.myLockers();
      } catch (_) {}
      if (!mounted) return;
      final kioskAllReports = rawReports.where((r) => !_isDroneReport(r)).toList();
      // `assignedToUserId` là nguồn sự thật: phiếu KTV tủ tự báo đã được server
      // tự giao (IN_PROGRESS) — không đoán "của tôi" theo người báo nữa.
      final Map<dynamic, Map<String, dynamic>> myReportsMap = {};
      for (final r in [...rawMine, ...kioskAllReports]) {
        final id = r['id'];
        if (id != null && !_isDroneReport(r) && _isAssignedToMe(r)) {
          myReportsMap.putIfAbsent(id, () => r);
        }
      }
      final myReportsList = myReportsMap.values.toList();
      setState(() {
        _faults = rawFaults.where((f) => !_isDroneFault(f)).toList();
        _reports = kioskAllReports;
        _myReports = myReportsList;
        _routedReports = rawRouted.where((r) => !_isDroneReport(r)).toList();
        _lockers = lockers;
        _myLockers = myLockers;
      });
      // Lịch bảo trì định kỳ — chỉ lịch của tủ (target=LOCKER); lịch drone thuộc
      // đội bay (DRONE_TECHNICIAN). Lọc "Của tôi" làm tại chỗ theo
      // `assignedTechnicianId` (đúng như `mine=true` của server) để đổi bộ lọc
      // không phải gọi lại. Không để vỡ trang nếu BE chưa deploy.
      try {
        final schedules = await _service.maintenanceSchedules(target: 'LOCKER');
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
        if (mounted) {
          setState(() => _anomalies = anomalies.where((a) => !_isDroneAnomaly(a)).toList());
        }
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
      // Mặc định mở tủ đầu tiên mình phụ trách (nếu có).
      final myFirstId = myLockers
          .map((l) => _asInt(l['id']))
          .firstWhere(
            (id) => id != null && lockers.any((l) => _asInt(l['id']) == id),
            orElse: () => null,
          );
      final firstId = myFirstId ??
          (lockers.isNotEmpty ? _asInt(lockers.first['id']) : null);
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
          'Bạn có chắc chắn muốn kết thúc ca trực và đăng xuất khỏi tài khoản KTV Kiosk không?',
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

  void _showKtvProfileSheet([String? resolvedName]) {
    final calculatedOverdue = _myReports
        .where((r) => r['status'] == 'IN_PROGRESS' && _isReportOverdue(r))
        .length;
    final myOverdue = calculatedOverdue;
    final myResolved = _myReports.where((r) => r['status'] == 'RESOLVED').length;
    final myInProgress = _myReports.where((r) => r['status'] == 'IN_PROGRESS').length;
    final myTotal = _myReports.length;
    final avgRating = _ratingAverage?['average']?.toString() ?? '5.0';
    final ratingCount = _ratingAverage?['count']?.toString() ?? '0';

    String? profileName;
    String? profileEmail;
    String? profilePhone;
    String? profileAvatar;

    try {
      final profile = context.read<ProfileProvider>().profile;
      if (profile != null) {
        if (profile.fullName.trim().isNotEmpty && profile.fullName.trim() != 'Người dùng') {
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

    final techName = resolvedName ?? profileName ?? _jwtUserName ?? 'Kỹ thuật viên Kiosk';
    final techEmail = profileEmail ?? _jwtUserEmail ?? 'ktv.kiosk@laundrylocker.vn';
    final techPhone = profilePhone ?? 'Chưa cập nhật SĐT';

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          top: false,
          child: Padding(
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
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            shape: BoxShape.circle,
                            border: Border.all(color: const Color(0xFF0077B6), width: 2),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: (profileAvatar != null && profileAvatar.isNotEmpty)
                              ? Image.network(
                                  profileAvatar,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Center(
                                    child: Text(
                                      AislBrand.initials(techName),
                                      style: const TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                )
                              : Center(
                                  child: Text(
                                    AislBrand.initials(techName),
                                    style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
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
                                  style: const TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold,
                                    color: opsDark,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
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
                            'KTV Kiosk (Tủ & Phần cứng) · Sẵn sàng',
                            style: TextStyle(fontSize: 12.5, color: opsMutedText, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            techEmail,
                            style: const TextStyle(fontSize: 12, color: opsMutedText),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(height: 1),
                const SizedBox(height: 14),
                // Work statistics grid
                Row(
                  children: [
                    Expanded(
                      child: _buildProfileStatTile('Tổng ca', '$myTotal', const Color(0xFF4F46E5)),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildProfileStatTile('Đang làm', '$myInProgress', const Color(0xFF2563EB)),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildProfileStatTile('Đã xong', '$myResolved', const Color(0xFF16A34A)),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildProfileStatTile(
                        'Quá hạn',
                        '$myOverdue',
                        myOverdue > 0 ? const Color(0xFFDC2626) : const Color(0xFF16A34A),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                // SLA & Rating card
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
                          const Icon(Icons.star_rounded, color: Color(0xFFF59E0B), size: 20),
                          const SizedBox(width: 8),
                          const Text('Đánh giá chất lượng: ', style: TextStyle(fontSize: 13, color: opsDark)),
                          Text('$avgRating/5', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: opsDark)),
                          Text(' ($ratingCount lượt)', style: const TextStyle(fontSize: 12, color: opsMutedText)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            myOverdue == 0 ? Icons.verified_user_outlined : Icons.warning_amber_rounded,
                            color: myOverdue == 0 ? const Color(0xFF16A34A) : const Color(0xFFD97706),
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          const Text('Quy chế SLA: ', style: TextStyle(fontSize: 13, color: opsDark)),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: myOverdue == 0 ? const Color(0xFFECFDF5) : const Color(0xFFFFFBEB),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: myOverdue == 0 ? const Color(0xFFA7F3D0) : const Color(0xFFFDE68A)),
                            ),
                            child: Text(
                              myOverdue == 0 ? 'Đạt chuẩn SLA' : 'Cảnh báo SLA (Mức 1)',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: myOverdue == 0 ? const Color(0xFF166534) : const Color(0xFF92400E),
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (techPhone.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.phone_outlined, color: opsMutedText, size: 18),
                            const SizedBox(width: 8),
                            const Text('SĐT kỹ thuật: ', style: TextStyle(fontSize: 13, color: opsDark)),
                            Text(techPhone, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: opsDark)),
                          ],
                        ),
                      ],
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
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: const Icon(Icons.edit_note_rounded, size: 20),
                        label: const Text('Xem & Chỉnh sửa hồ sơ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
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
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.logout, size: 18),
                      label: const Text('Đăng xuất', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildProfileStatTile(String label, String value, Color color) {
    return Container(
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
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: color.withValues(alpha: 0.8)),
          ),
        ],
      ),
    );
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

  Future<bool> _run(Future<Object?> Function() fn, String ok) async {
    try {
      await fn();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ok)));
      }
      await _load();
      return true;
    } catch (e) {
      _showError(e);
      return false;
    }
  }

  /// Báo lỗi server (message tiếng Việt từ ApiResponse). `REPORT_OPEN` (ô/bãi
  /// đáp còn phiếu mở) kèm nút mở phiếu đó để nghiệm thu đúng quy trình.
  void _showError(Object e) {
    if (!mounted) return;
    final msg = LockerOpsService.errorMessage(e);
    if (msg.contains('SLA_RESTRICTED') ||
        msg.contains('hạn chế nhận thêm') ||
        msg.contains('quá hạn SLA')) {
      _showSlaRestrictedDialog(msg);
      return;
    }
    final openReportId = LockerOpsService.errorCode(e) == 'REPORT_OPEN'
        ? int.tryParse(RegExp(r'#(\d+)').firstMatch(msg)?.group(1) ?? '')
        : null;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFFDC2626),
        duration: Duration(seconds: openReportId != null ? 6 : 4),
        content: Text(msg),
        action: openReportId == null
            ? null
            : SnackBarAction(
                label: 'Mở phiếu',
                textColor: Colors.white,
                onPressed: () => _resolveViaTicket(openReportId),
              ),
      ),
    );
  }

  void _showInfo(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  bool _isAssignedToMe(Map<String, dynamic> r) {
    final me = _myUserId;
    return me != null &&
        me.isNotEmpty &&
        r['assignedToUserId']?.toString() == me;
  }

  Set<int> get _myLockerIds =>
      _myLockers.map((l) => _asInt(l['id'])).whereType<int>().toSet();

  Map<String, dynamic>? _findReport(int reportId) {
    for (final r in [..._myReports, ..._routedReports, ..._reports]) {
      if (_asInt(r['id']) == reportId) return r;
    }
    return null;
  }

  /// Phiếu còn mở của 1 ô: `openReportId` trong danh sách ô lỗi, hoặc phiếu
  /// chưa RESOLVED gắn ô đó.
  int? _openReportIdForBox(int boxId) {
    for (final f in _faults) {
      if (_asInt(f['boxId']) == boxId && _asInt(f['openReportId']) != null) {
        return _asInt(f['openReportId']);
      }
    }
    for (final r in [..._myReports, ..._reports]) {
      if (_asInt(r['boxId']) == boxId && r['status'] != 'RESOLVED') {
        return _asInt(r['id']);
      }
    }
    return null;
  }

  /// "Đã sửa" cho ô FAULT. Ô còn phiếu mở ⇒ hoàn tất qua phiếu (ảnh nghiệm
  /// thu, đúng luật backend); chỉ gọi clear-fault khi ô không có phiếu nào.
  Future<void> _markFaultFixed(int boxId, {int? openReportId}) async {
    final reportId = openReportId ?? _openReportIdForBox(boxId);
    if (reportId != null) {
      await _resolveViaTicket(reportId);
      return;
    }
    try {
      await _service.clearFault(boxId);
      _showInfo('Ô đã hoạt động lại');
      await _load();
    } catch (e) {
      _showError(e);
      // REPORT_OPEN / BOX_NOT_FAULT: dữ liệu trên máy đã cũ ⇒ tải lại.
      final code = LockerOpsService.errorCode(e);
      if (code == 'REPORT_OPEN' || code == 'BOX_NOT_FAULT') await _load();
    }
  }

  /// Mở luồng hoàn tất (nghiệm thu + ảnh) cho phiếu [reportId]: phiếu của mình
  /// ⇒ mở sheet nghiệm thu; phiếu OPEN chưa ai nhận ⇒ nhận phiếu rồi nghiệm thu;
  /// phiếu KTV khác đang giữ ⇒ báo rõ, không gọi API.
  Future<void> _resolveViaTicket(int reportId) async {
    Map<String, dynamic>? ticket = _findReport(reportId);
    try {
      ticket = await _service.getMaintenanceReport(reportId);
    } catch (_) {}
    if (!mounted) return;
    if (ticket == null || ticket.isEmpty) {
      _showInfo('Không tải được phiếu #$reportId');
      return;
    }
    final status = ticket['status']?.toString();
    if (status == 'RESOLVED') {
      _showInfo('Phiếu #$reportId đã được hoàn tất.');
      await _load();
      return;
    }
    if (_isAssignedToMe(ticket)) {
      await _confirmResolveReport(ticket);
      return;
    }
    if (status != 'OPEN') {
      _showInfo(
        'Phiếu #$reportId đang do KTV #${ticket['assignedToUserId']} xử lý — '
        'chỉ người được giao mới hoàn tất được.',
      );
      return;
    }
    final claim = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Phiếu #$reportId chưa có người nhận'),
        content: const Text(
          'Ô/bãi đáp này đang có phiếu sự cố mở. Nhận phiếu rồi nghiệm thu '
          '(chụp ảnh sau khi sửa) để đưa về hoạt động.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF59E0B),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Nhận & nghiệm thu'),
          ),
        ],
      ),
    );
    if (claim != true || !mounted) return;
    try {
      final claimed = await _service.claimReport(reportId);
      if (!mounted) return;
      await _confirmResolveReport({...ticket, ...claimed});
    } catch (e) {
      _showError(e);
    }
    await _load();
  }

  /// Mở chi tiết phiếu theo id (badge "Chờ phiếu #id" của lịch định kỳ).
  Future<void> _openReportById(int reportId) async {
    Map<String, dynamic>? ticket = _findReport(reportId);
    if (ticket == null) {
      try {
        ticket = await _service.getMaintenanceReport(reportId);
      } catch (e) {
        _showError(e);
        return;
      }
    }
    if (mounted && ticket.isNotEmpty) _showReportDetailModal(ticket);
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

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return '☀️ Chào buổi sáng';
    if (hour < 14) return '🌤️ Chào buổi trưa';
    if (hour < 18) return '🌅 Chào buổi chiều';
    return '🌙 Chào ca tối';
  }

  String _getResolvedTechnicianName(BuildContext context) {
    try {
      final profile = context.watch<ProfileProvider>().profile;
      final pName = profile?.fullName.trim();
      if (pName != null && pName.isNotEmpty && pName != 'Người dùng') {
        return pName;
      }
    } catch (_) {}
    if (_jwtUserName != null && _jwtUserName!.trim().isNotEmpty) {
      return _jwtUserName!.trim();
    }
    if (_jwtUserEmail != null && _jwtUserEmail!.trim().isNotEmpty) {
      return _jwtUserEmail!.trim();
    }
    for (final r in _myReports) {
      final name = (r['assigneeName'] ?? r['reporterName'] ?? '').toString().trim();
      if (name.isNotEmpty && !name.toLowerCase().contains('customer')) {
        return name;
      }
    }
    return 'Kỹ thuật viên Kiosk';
  }

  Widget _avatarFallback(String name) {
    return Center(
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
  }

  Widget _headerActionButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
    bool isLoading = false,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isLoading ? null : onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.18),
                width: 1,
              ),
            ),
            alignment: Alignment.center,
            child: isLoading
                ? const SizedBox(
                    width: 17,
                    height: 17,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF38BDF8)),
                    ),
                  )
                : Icon(
                    icon,
                    size: 19,
                    color: Colors.white.withValues(alpha: 0.95),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildHudChip({
    required IconData icon,
    required String value,
    required String label,
    required Color accentColor,
    required VoidCallback onTap,
    bool isAlert = false,
  }) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
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
                width: 1,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
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
      ),
    );
  }

  Widget _buildTechnicianHeader({
    required String displayName,
    required List<Map<String, dynamic>> openReports,
    required int openCount,
    required int mineInProgress,
    required int mineCount,
    required List<Map<String, dynamic>> kioskSchedules,
  }) {
    String? avatarUrl;
    try {
      avatarUrl = context.watch<ProfileProvider>().profile?.avatarUrl;
    } catch (_) {}

    final overdueCount = _myReports
        .where((r) => r['status'] == 'IN_PROGRESS' && _isReportOverdue(r))
        .length;
    final inProgressCount =
        _myReports.where((r) => r['status'] == 'IN_PROGRESS').length;

    final IconData slaIcon;
    final Color slaColor;
    final String slaText;
    final Color slaTextColor;

    if (overdueCount >= 5) {
      slaIcon = Icons.cancel;
      slaColor = const Color(0xFFEF4444);
      slaText = 'SLA: Đình chỉ ($overdueCount ca trễ hạn)';
      slaTextColor = const Color(0xFFFCA5A5);
    } else if (overdueCount >= 3) {
      slaIcon = Icons.block;
      slaColor = const Color(0xFFF87171);
      slaText = 'SLA: Hạn chế ($overdueCount ca trễ hạn)';
      slaTextColor = const Color(0xFFFCA5A5);
    } else if (overdueCount >= 1) {
      slaIcon = Icons.warning_amber_rounded;
      slaColor = const Color(0xFFFBBF24);
      slaText = 'SLA: Cảnh báo ($overdueCount ca trễ hạn)';
      slaTextColor = const Color(0xFFFDE68A);
    } else {
      slaIcon = Icons.verified_rounded;
      slaColor = const Color(0xFF34D399);
      slaTextColor = const Color(0xFFA7F3D0);
      if (inProgressCount > 0) {
        slaText = 'SLA: Bình thường ($inProgressCount ca trong hạn)';
      } else {
        slaText = 'SLA: Bình thường · Đạt chuẩn';
      }
    }

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF061A30), // Deep Dark Navy
            Color(0xFF0A2544), // Brand Slate Navy
            Color(0xFF103A63), // High-Tech Deep Cyan/Blue
          ],
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
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)),
        child: Stack(
          children: [
            // Decorative background glowing ambient orbs
            Positioned(
              top: -45,
              right: -30,
              child: Container(
                width: 170,
                height: 170,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF00B4D8).withValues(alpha: 0.14),
                ),
              ),
            ),
            Positioned(
              bottom: -40,
              left: -30,
              child: Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF0077B6).withValues(alpha: 0.12),
                ),
              ),
            ),
            SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Top identity row
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Avatar with glowing ring & online dot
                        GestureDetector(
                          onTap: () => _showKtvProfileSheet(displayName),
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
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF38BDF8).withValues(alpha: 0.35),
                                      blurRadius: 10,
                                      offset: const Offset(0, 2),
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
                                  child: (avatarUrl != null && avatarUrl.isNotEmpty)
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
                                        color: const Color(0xFF10B981)
                                            .withValues(alpha: 0.6),
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
                        // Technician Name, Greeting & Status
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      _greeting(),
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white.withValues(alpha: 0.8),
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 1.5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF0284C7)
                                          .withValues(alpha: 0.35),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                        color: const Color(0xFF38BDF8)
                                            .withValues(alpha: 0.5),
                                        width: 0.8,
                                      ),
                                    ),
                                    child: const Text(
                                      'KIOSK',
                                      style: TextStyle(
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.w800,
                                        color: Color(0xFFBAE6FD),
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                displayName,
                                style: const TextStyle(
                                  fontSize: 19,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  letterSpacing: -0.3,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              InkWell(
                                onTap: () => _tabs.animateTo(2),
                                borderRadius: BorderRadius.circular(6),
                                child: Row(
                                  children: [
                                    Icon(
                                      slaIcon,
                                      size: 13,
                                      color: slaColor,
                                    ),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        slaText,
                                        style: TextStyle(
                                          fontSize: 11.5,
                                          fontWeight: overdueCount > 0
                                              ? FontWeight.w700
                                              : FontWeight.w600,
                                          color: slaTextColor,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Action buttons (Assistant, Profile & Logout)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Trợ lý hỏi đáp — chỉ hiện khi trợ lý đang bật.
                            AssistantEntryGate(
                              builder: (context) => Padding(
                                padding: const EdgeInsets.only(right: 6),
                                child: _headerActionButton(
                                  icon: Icons.support_agent_rounded,
                                  tooltip: 'Trợ lý hỏi đáp',
                                  onTap: () =>
                                      context.push(AppRouter.assistant),
                                ),
                              ),
                            ),
                            _headerActionButton(
                              icon: Icons.person_outline_rounded,
                              tooltip: 'Hồ sơ & Chỉnh sửa',
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => const TechnicianProfilePage(),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(width: 6),
                            _headerActionButton(
                              icon: Icons.logout_rounded,
                              tooltip: 'Đăng xuất',
                              onTap: _logout,
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    // Quick Cockpit HUD Bar
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.12),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          _buildHudChip(
                            icon: Icons.report_problem_outlined,
                            value: '${openReports.length}',
                            label: 'Chờ xử lý',
                            accentColor: openReports.isNotEmpty
                                ? const Color(0xFFEF4444)
                                : const Color(0xFF10B981),
                            isAlert: openReports.isNotEmpty,
                            onTap: () => _tabs.animateTo(1),
                          ),
                          const SizedBox(width: 4),
                          _buildHudChip(
                            icon: Icons.handyman_outlined,
                            value: '$mineInProgress',
                            label: 'Đang làm',
                            accentColor: const Color(0xFF38BDF8),
                            onTap: () => _tabs.animateTo(2),
                          ),
                          const SizedBox(width: 4),
                          _buildHudChip(
                            icon: Icons.event_repeat_outlined,
                            value: '${kioskSchedules.length}',
                            label: 'Định kỳ',
                            accentColor: const Color(0xFFA78BFA),
                            onTap: () => _tabs.animateTo(3),
                          ),
                          const SizedBox(width: 4),
                          _buildHudChip(
                            icon: Icons.meeting_room_outlined,
                            value: '${_lockers.length}',
                            label: 'Trạm tủ',
                            accentColor: const Color(0xFF34D399),
                            onTap: () => _tabs.animateTo(0),
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
    );
  }

  @override
  Widget build(BuildContext context) {
    // Tab Sự cố: Đếm tất cả sự cố Kiosk (OPEN + IN_PROGRESS + RESOLVED) — khớp với Admin portal
    final openReports = _reports.where((r) => r['status'] == 'OPEN').toList();
    final openCount = _reports.length; // Tổng phiếu toàn hệ thống, giống Admin portal

    // Tab Việc của tôi: Đếm các sự cố do chính KTV đang phụ trách xử lý
    final mineInProgress = _myReports.where((r) => r['status'] == 'IN_PROGRESS').length;
    final mineCount = mineInProgress > 0
        ? mineInProgress
        : _myReports.where((r) => r['status'] != 'RESOLVED').length;

    // Tab định kỳ của KTV Kiosk chỉ đếm và hiển thị các việc của Kiosk
    final kioskSchedules = _schedules.where((s) => !_isDroneSchedule(s)).toList();
    final resolvedTechName = _getResolvedTechnicianName(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FA),
      body: Column(
        children: [
          _buildTechnicianHeader(
            displayName: resolvedTechName,
            openReports: openReports,
            openCount: openCount,
            mineInProgress: mineInProgress,
            mineCount: mineCount,
            kioskSchedules: kioskSchedules,
          ),
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
              labelStyle: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700),
              unselectedLabelColor: const Color(0xFF64748B),
              unselectedLabelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
              tabs: [
                const Tab(text: 'Kiểm tra tủ'),
                Tab(text: 'Sự cố ($openCount)'),
                Tab(text: 'Việc của tôi ($mineCount)'),
                Tab(text: 'Định kỳ (${kioskSchedules.length})'),
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
                          'Sơ đồ vật lý trạm Kiosk',
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
            if (_layout?['landingPad'] == true && _selectedLockerId != null) ...[
              const SizedBox(height: 12),
              _landingPadCard(_selectedLockerId!),
            ],
          ],
        ],
      ),
    );
  }

  static const _landingPadStatuses = ['OK', 'FAULT', 'MAINTENANCE'];

  String _landingPadLabel(String status) => switch (status) {
    'OK' => 'Hoạt động tốt',
    'FAULT' => 'Hỏng',
    'MAINTENANCE' => 'Đang bảo trì',
    _ => status,
  };

  Color _landingPadColor(String status) => switch (status) {
    'OK' => const Color(0xFF16A34A),
    'FAULT' => const Color(0xFFDC2626),
    _ => const Color(0xFFD97706),
  };

  /// Phiếu LANDING_PAD còn mở của tủ (tối đa 1 phiếu mở mỗi bãi đáp).
  Map<String, dynamic>? _openLandingPadReport(int lockerId) {
    for (final r in [..._myReports, ..._reports]) {
      if (r['category'] == 'LANDING_PAD' &&
          _asInt(r['lockerId']) == lockerId &&
          r['status'] != 'RESOLVED') {
        return r;
      }
    }
    return null;
  }

  /// Bãi đáp drone của tủ đang chọn (#6): KTV tủ đổi OK / FAULT / MAINTENANCE.
  Widget _landingPadCard(int lockerId) {
    final status = (_layout?['landingPadStatus'] ?? 'OK').toString();
    final markerId = _layout?['landingMarkerId']?.toString();
    final openTicket = _openLandingPadReport(lockerId);
    final color = _landingPadColor(status);
    return OpsCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.flight_land, size: 18, color: opsPrimary),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Bãi đáp drone',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
                ),
              ),
              _MiniPill(
                icon: Icons.circle,
                text: _landingPadLabel(status),
                color: color,
              ),
            ],
          ),
          if (markerId != null && markerId.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              'Marker: $markerId',
              style: const TextStyle(fontSize: 12, color: opsMutedText),
            ),
          ],
          if (openTicket != null) ...[
            const SizedBox(height: 8),
            InkWell(
              onTap: () => _showReportDetailModal(openTicket),
              borderRadius: BorderRadius.circular(999),
              child: _MiniPill(
                icon: Icons.pending_actions,
                text: 'Phiếu #${openTicket['id']} đang mở',
                color: const Color(0xFFEA580C),
              ),
            ),
          ],
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              for (final s in _landingPadStatuses)
                _buildScheduleChip(
                  label: _landingPadLabel(s),
                  selected: status == s,
                  activeColor: _landingPadColor(s),
                  onTap: () {
                    if (status != s) _changeLandingPad(lockerId, s, openTicket);
                  },
                ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Báo Hỏng/Bảo trì ⇒ mở phiếu bãi đáp giao cho bạn. Về "Hoạt động tốt" '
            'khi còn phiếu ⇒ nghiệm thu phiếu (ảnh sau khi sửa).',
            style: TextStyle(fontSize: 11.5, color: opsMutedText),
          ),
        ],
      ),
    );
  }

  /// Về OK khi còn phiếu bãi đáp ⇒ hoàn tất qua phiếu (luật ảnh nghiệm thu);
  /// FAULT/MAINTENANCE cần lý do — thành mô tả phiếu server mở.
  Future<void> _changeLandingPad(
    int lockerId,
    String status,
    Map<String, dynamic>? openTicket,
  ) async {
    final ticketId = _asInt(openTicket?['id']);
    if (status == 'OK' && ticketId != null) {
      await _resolveViaTicket(ticketId);
      return;
    }
    String? reason;
    if (status != 'OK') {
      reason = await _askLandingPadReason(status);
      if (reason == null) return;
    }
    try {
      await _service.updateLandingPadStatus(lockerId, status, reason: reason);
      _showInfo(
        status == 'OK'
            ? 'Bãi đáp đã hoạt động lại'
            : 'Bãi đáp: ${_landingPadLabel(status)}'
                  '${ticketId == null ? ' — đã mở phiếu sự cố giao cho bạn' : ''}',
      );
      await _load();
    } catch (e) {
      _showError(e);
    }
  }

  Future<String?> _askLandingPadReason(String status) async {
    final ctrl = TextEditingController();
    String? error;
    final reason = await showDialog<String>(
      context: context,
      // ctrl được huỷ khi dialog gỡ khỏi cây (sau hiệu ứng đóng).
      builder: (ctx) => ControllerDisposer(
        controllers: [ctrl],
        child: StatefulBuilder(
          builder: (ctx, setLocal) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Text('Bãi đáp: ${_landingPadLabel(status)}'),
            content: TextField(
              controller: ctrl,
              autofocus: true,
              minLines: 1,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Lý do',
                hintText: status == 'FAULT'
                    ? 'VD: Marker bong tróc, mặt đáp nứt...'
                    : 'VD: Vệ sinh, sơn lại marker...',
                errorText: error,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Hủy'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _landingPadColor(status),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  final text = ctrl.text.trim();
                  if (text.isEmpty) {
                    setLocal(() => error = 'Vui lòng nhập lý do.');
                    return;
                  }
                  Navigator.pop(ctx, text);
                },
                child: const Text('Xác nhận'),
              ),
            ],
          ),
        ),
      ),
    );
    return reason;
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
                    'Hàng $r',
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
                          'Hàng $r',
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
              if (_myLockerIds.contains(_asInt(locker['id'])))
                const _MiniPill(
                  icon: Icons.assignment_ind_outlined,
                  text: 'Tủ bạn phụ trách',
                  color: Color(0xFFD97706),
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
    final openReportId = status == 'FAULT' ? _openReportIdForBox(boxId) : null;

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
            // Ô còn phiếu mở ⇒ đóng qua phiếu (nghiệm thu + ảnh), không clear thẳng.
            actions.add(tile(
              Icons.check_circle,
              openReportId != null
                  ? 'Đã sửa xong — nghiệm thu phiếu #$openReportId'
                  : 'Đã sửa xong — mở lại ô',
              const Color(0xFF16A34A),
              () => _markFaultFixed(boxId, openReportId: openReportId),
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
      _showError(e);
    }
  }

  /// Dialog nhập lý do (+ ảnh hiện trường tuỳ chọn) rồi báo hỏng ô.
  /// Ảnh được upload ngay trong dialog để thấy tiến độ từng ảnh.
  Future<void> _reportFaultFlow(Map<String, dynamic> cell) async {
    final boxId = _asInt(cell['id']);
    if (boxId == null) return;
    final reasonCtrl = TextEditingController(text: 'Hỏng khóa');
    // Ảnh stage REPORT ⇒ giới hạn mỗi lần của người báo (admin cấu hình).
    final photos = PhotoPickerController(
      maxPhotos:
          BusinessConfigService.instance.current.reportPhotosPerRequestReporter,
    );
    var uploading = false;
    String? dialogError;
    List<Map<String, dynamic>> attachments = const [];
    final ok = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      // photos + reasonCtrl được huỷ khi dialog gỡ khỏi cây (sau hiệu ứng đóng).
      builder: (ctx) => ControllerDisposer(
        controllers: [photos, reasonCtrl],
        child: StatefulBuilder(
          builder: (ctx, setLocal) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Text('Báo hỏng ô #${cell['boxNumber']}'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: reasonCtrl,
                    enabled: !uploading,
                    decoration: const InputDecoration(labelText: 'Lý do hỏng'),
                    minLines: 1,
                    maxLines: 3,
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Ảnh hiện trường (tuỳ chọn, tối đa ${photos.maxPhotos})',
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  PhotoPickerField(
                    controller: photos,
                    enabled: !uploading,
                    thumbSize: 64,
                    accentColor: opsPrimary,
                  ),
                  if (dialogError != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      dialogError!,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFFDC2626),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: uploading ? null : () => Navigator.pop(ctx, false),
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
                onPressed: uploading
                    ? null
                    : () async {
                        if (reasonCtrl.text.trim().isEmpty) {
                          setLocal(
                            () => dialogError = 'Vui lòng nhập lý do hỏng.',
                          );
                          return;
                        }
                        setLocal(() {
                          uploading = true;
                          dialogError = null;
                        });
                        try {
                          attachments = await photos.uploadAll();
                          if (ctx.mounted) Navigator.pop(ctx, true);
                        } catch (e) {
                          if (ctx.mounted) {
                            setLocal(() {
                              uploading = false;
                              dialogError = LockerOpsService.errorMessage(e);
                            });
                          }
                        }
                      },
                child: Text(uploading ? 'Đang tải ảnh...' : 'Báo hỏng'),
              ),
            ],
          ),
        ),
      ),
    );
    final reason = reasonCtrl.text.trim();
    if (ok != true || reason.isEmpty) return;
    await _runCellAction(
      () => _service.reportFault(boxId, reason, attachments: attachments),
      attachments.isEmpty
          ? 'Đã báo hỏng ô'
          : 'Đã báo hỏng ô kèm ${attachments.length} ảnh',
    );
  }

  /// Dialog xác nhận (lý do tuỳ chọn) rồi ngưng dùng ô.
  Future<void> _outOfServiceFlow(Map<String, dynamic> cell) async {
    final boxId = _asInt(cell['id']);
    if (boxId == null) return;
    final reasonCtrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      // reasonCtrl được huỷ khi dialog gỡ khỏi cây (sau hiệu ứng đóng).
      builder: (ctx) => ControllerDisposer(
        controllers: [reasonCtrl],
        child: AlertDialog(
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
      ),
    );
    final reason = reasonCtrl.text.trim();
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
                          '${a['lockerName'] ?? 'Chưa tra được tên tủ'} · Ô #${a['boxNumber']} (${a['cellType']})',
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
    // Tab "Sự cố": Toàn bộ sự cố Kiosk để KTV duyệt — OPEN thì nhận việc, còn lại là tham khảo.
    // Dữ liệu từ /api/admin/lockers/reports — khớp 100% với Admin portal.
    // Bộ lọc trạng thái: khi chọn một trạng thái thì các nhóm còn lại rỗng nên
    // danh sách bên dưới chỉ còn đúng nhóm đó.
    bool statusShown(String status) =>
        _reportStatusFilter == 'ALL' || _reportStatusFilter == status;
    final openReports = statusShown('OPEN')
        ? _reports.where((r) => r['status'] == 'OPEN').toList()
        : <Map<String, dynamic>>[];
    final inProgressReports = statusShown('IN_PROGRESS')
        ? _reports.where((r) => r['status'] == 'IN_PROGRESS').toList()
        : <Map<String, dynamic>>[];
    final resolvedReports = statusShown('RESOLVED')
        ? _reports.where((r) => r['status'] == 'RESOLVED').toList()
        : <Map<String, dynamic>>[];
    // "Tủ tôi phụ trách": phiếu OPEN server định tuyến cho mình + ô lỗi của các tủ đó.
    final routedView = _queueView == 'ROUTED';
    final myLockerIds = _myLockerIds;
    final faults = routedView
        ? _faults
            .where((f) => myLockerIds.contains(_asInt(f['lockerId'])))
            .toList()
        : _faults;

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildScheduleChip(
                  label: 'Tất cả (${_reports.length})',
                  selected: !routedView,
                  icon: Icons.public,
                  onTap: () => setState(() => _queueView = 'ALL'),
                ),
                const SizedBox(width: 8),
                _buildScheduleChip(
                  label: 'Tủ tôi phụ trách (${_routedReports.length})',
                  selected: routedView,
                  icon: Icons.assignment_ind_outlined,
                  activeColor: const Color(0xFFD97706),
                  onTap: () => setState(() => _queueView = 'ROUTED'),
                ),
              ],
            ),
          ),
          if (!routedView) ...[
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final option in const [
                    ('ALL', 'Mọi trạng thái', Icons.filter_list),
                    ('OPEN', 'Chờ nhận', Icons.fiber_new_rounded),
                    ('IN_PROGRESS', 'Đang xử lý', Icons.build_circle_outlined),
                    ('RESOLVED', 'Hoàn tất', Icons.check_circle_outline),
                  ]) ...[
                    _buildScheduleChip(
                      label: option.$1 == 'ALL'
                          ? option.$2
                          : '${option.$2} '
                              '(${_reports.where((r) => r['status'] == option.$1).length})',
                      selected: _reportStatusFilter == option.$1,
                      icon: option.$3,
                      activeColor: switch (option.$1) {
                        'OPEN' => const Color(0xFFDC2626),
                        'IN_PROGRESS' => const Color(0xFFD97706),
                        'RESOLVED' => const Color(0xFF16A34A),
                        _ => opsPrimary,
                      },
                      onTap: () =>
                          setState(() => _reportStatusFilter = option.$1),
                    ),
                    const SizedBox(width: 8),
                  ],
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          if (!routedView) _boxAnomaliesSection(),
          if (routedView) ...[
            OpsBanner(
              tone: OpsBannerTone.info,
              icon: Icons.assignment_ind_outlined,
              text: _myLockers.isEmpty
                  ? 'Bạn chưa được giao phụ trách tủ nào — phiếu mới được báo tới mọi KTV tủ.'
                  : 'Bạn phụ trách ${_myLockers.length} tủ: '
                        '${_myLockers.map((l) => l['name'] ?? l['code'] ?? '#${l['id']}').join(', ')}. '
                        'Phiếu mới ở các tủ này được chuyển thẳng cho bạn.',
            ),
            const SizedBox(height: 10),
          ],
          if (faults.isNotEmpty) ...[
            const OpsSectionLabel('Ô đang lỗi vật lý tại trạm', icon: Icons.warning_amber_rounded),
            for (final f in faults)
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
                              '${f['lockerName'] ?? 'Chưa tra được tên tủ'} · Ô #${f['boxNumber']}',
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
                          // Ô còn phiếu mở ⇒ "Đã sửa" mở luồng nghiệm thu của phiếu.
                          TextButton(
                            onPressed: _asInt(f['boxId']) == null
                                ? null
                                : () => _markFaultFixed(
                                      _asInt(f['boxId'])!,
                                      openReportId: _asInt(f['openReportId']),
                                    ),
                            child: Text(
                              _asInt(f['openReportId']) != null
                                  ? 'Đã sửa · phiếu #${f['openReportId']}'
                                  : 'Đã sửa',
                              style: const TextStyle(color: Color(0xFF16A34A)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 8),
          ],

          // --- Phiếu OPEN định tuyến cho mình (tủ mình phụ trách) ---
          if (routedView) ...[
            if (_routedReports.isNotEmpty) ...[
              OpsSectionLabel(
                'Phiếu chờ bạn nhận (${_routedReports.length})',
                icon: Icons.assignment_late_outlined,
              ),
              for (final r in _routedReports) _reportCard(r, isQueueView: true),
            ] else if (faults.isEmpty)
              const OpsEmptyState(
                icon: Icons.check_circle_outline,
                title: 'Không có phiếu nào chờ bạn',
                subtitle: 'Các tủ bạn phụ trách chưa có sự cố mới.',
              ),
          ],

          // --- Banner tổng quan sự cố toàn hệ thống ---
          if (!routedView && _reports.isNotEmpty) ...[
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFF0F9FF), Color(0xFFE0F2FE)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFF0EA5E9), width: 1.2),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0EA5E9).withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.dashboard_outlined, color: Color(0xFF0284C7), size: 20),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'TOÀN HỆ THỐNG: ${_reports.length} PHIẾU SỰ CỐ KIOSK',
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0C4A6E),
                            letterSpacing: 0.2,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            if (openReports.isNotEmpty)
                              _QueueStatChip(
                                label: '${openReports.length} chờ nhận',
                                color: const Color(0xFFF59E0B),
                              ),
                            if (openReports.isNotEmpty && inProgressReports.isNotEmpty)
                              const SizedBox(width: 6),
                            if (inProgressReports.isNotEmpty)
                              _QueueStatChip(
                                label: '${inProgressReports.length} đang xử lý',
                                color: const Color(0xFF3B82F6),
                              ),
                            if (resolvedReports.isNotEmpty) ...[
                              const SizedBox(width: 6),
                              _QueueStatChip(
                                label: '${resolvedReports.length} hoàn tất',
                                color: const Color(0xFF16A34A),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],

          // --- Phiếu OPEN: chờ tiếp nhận ---
          if (!routedView && openReports.isNotEmpty) ...[
            if (openReports.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFBEB),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFF59E0B), width: 1.2),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.bolt, color: Color(0xFFD97706), size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${openReports.length} sự cố đang chờ KTV tiếp nhận xử lý',
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF92400E),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            const OpsSectionLabel('Sự cố chờ tiếp nhận', icon: Icons.fiber_new_rounded),
            for (final r in openReports) _reportCard(r, isQueueView: true),
            const SizedBox(height: 8),
          ],

          // --- Phiếu IN_PROGRESS: KTV khác đang xử lý (tham khảo) ---
          if (!routedView && inProgressReports.isNotEmpty) ...[
            const OpsSectionLabel('Đang được xử lý', icon: Icons.engineering_outlined),
            for (final r in inProgressReports) _reportCard(r, isQueueView: false),
            const SizedBox(height: 8),
          ],

          // --- Phiếu RESOLVED: đã hoàn tất (lịch sử hệ thống) ---
          if (!routedView && resolvedReports.isNotEmpty) ...[
            const OpsSectionLabel('Đã hoàn tất gần đây', icon: Icons.check_circle_outline),
            for (final r in resolvedReports) _reportCard(r, isQueueView: false),
            const SizedBox(height: 8),
          ],

          if (!routedView && _reports.isEmpty && _faults.isEmpty)
            const OpsEmptyState(
              icon: Icons.check_circle_outline,
              title: 'Không có sự cố nào',
              subtitle: 'Tất cả các trạm Kiosk hiện đang vận hành ổn định.',
            ),
        ],
      ),
    );
  }

  Widget _buildShiftSummary() {
    // Đồng bộ chuẩn xác 100% với Web Admin Portal (technician-detail.tsx):
    // Tính toán trực tiếp và nhất quán từ danh sách phiếu _myReports của KTV Kiosk
    final totalAssigned = _myReports.length;
    final inProgress = _myReports.where((r) => r['status'] == 'IN_PROGRESS').length;
    final resolved = _myReports.where((r) => r['status'] == 'RESOLVED').length;
    final overdue = _myReports
        .where((r) => r['status'] == 'IN_PROGRESS' && _isReportOverdue(r))
        .length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const OpsSectionLabel('Tổng quan ca trực', icon: Icons.dashboard_outlined),
        Row(
          children: [
            Expanded(
              child: _MetricCard(
                label: 'Tổng ca\nphụ trách',
                value: '$totalAssigned',
                icon: Icons.inventory_2_outlined,
                color: const Color(0xFF475569),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: _MetricCard(
                label: 'Đang\nxử lý',
                value: '$inProgress',
                icon: Icons.access_time_rounded,
                color: const Color(0xFF2563EB),
                highlight: inProgress > 0,
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: _MetricCard(
                label: 'Đã\nhoàn tất',
                value: '$resolved',
                icon: Icons.check_circle_outline,
                color: const Color(0xFF059669),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: _MetricCard(
                label: 'Trễ hạn\nSLA',
                value: '$overdue',
                icon: Icons.warning_amber_rounded,
                color: const Color(0xFFDC2626),
                highlight: overdue > 0,
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
        if (_myReports.isNotEmpty || _myPerformance != null) ...[
          const SizedBox(height: 10),
          _buildSlaPenaltyCard(),
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

  Widget _buildSlaPenaltyCard() {
    // Đồng bộ 100% với Web Admin Portal: tính toán chuẩn xác từ danh sách phiếu thực tế
    final overdue = _myReports
        .where((r) => r['status'] == 'IN_PROGRESS' && _isReportOverdue(r))
        .length;
    final inProgress = _myReports.where((r) => r['status'] == 'IN_PROGRESS').length;
    final resolved = _myReports.where((r) => r['status'] == 'RESOLVED').length;

    // Phân loại mức chế tài theo quy chuẩn Admin Portal:
    String penaltyLevel = 'NORMAL';
    if (overdue >= 5) {
      penaltyLevel = 'SUSPENDED';
    } else if (overdue >= 3) {
      penaltyLevel = 'RESTRICTED';
    } else if (overdue >= 1) {
      penaltyLevel = 'WARNING';
    } else {
      penaltyLevel = 'NORMAL';
    }

    String reason = '';
    if (overdue >= 5) {
      reason = 'Vi phạm nghiêm trọng: có từ $overdue phiếu trễ hạn SLA. Đề xuất đình chỉ công tác & khóa tài khoản.';
    } else if (overdue >= 3) {
      reason = 'Hạn chế nhận việc: có $overdue phiếu trễ hạn SLA. Tạm ngưng phân công mới.';
    } else if (overdue >= 1) {
      reason = 'Cảnh báo thời gian SLA (Mức 1): Đang có $overdue phiếu sự cố bị quá hạn thời gian xử lý quy định (> 4 giờ). Cần đẩy nhanh tiến độ.';
    } else {
      reason = 'Hiệu suất hoạt động tốt, các sự cố phụ trách đều trong hạn SLA (hoặc đã được phê duyệt gia hạn).';
    }

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
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          // 1. Toàn bộ tổng quan ca trực & thống kê KPI của KTV đưa về đây
          _buildShiftSummary(),
          const SizedBox(height: 14),

          if (active.isEmpty && done.isEmpty)
            const OpsEmptyState(
              icon: Icons.engineering_outlined,
              title: 'Bạn chưa nhận việc nào',
              subtitle: 'Chuyển sang tab "Sự cố" để duyệt và nhận việc mới.',
            ),

          // 2. Danh sách các phiếu sự cố KTV đang trực tiếp xử lý
          if (active.isNotEmpty) ...[
            OpsSectionLabel('Sự cố đang xử lý (${active.length})', icon: Icons.pending_actions_outlined),
            for (final r in active) _reportCard(r, isQueueView: false),
            const SizedBox(height: 12),
          ],

          // 3. Lịch sử các sự cố đã hoàn thành
          if (done.isNotEmpty) ...[
            OpsSectionLabel('Lịch sử đã hoàn thành (${done.length})', icon: Icons.check_circle_outline),
            for (final r in done) _reportCard(r, isQueueView: false),
          ],
        ],
      ),
    );
  }

  // ---- Tab 4: bảo trì định kỳ (preventive) — Dành riêng cho KTV Kiosk ----
  bool _isScheduleMine(Map<String, dynamic> s) {
    final me = _myUserId;
    return me != null &&
        me.isNotEmpty &&
        s['assignedTechnicianId']?.toString() == me;
  }

  Widget _buildSchedules() {
    // KTV Kiosk chỉ hiển thị các kế hoạch kiểm tra định kỳ của trạm Kiosk
    final allKioskList = _schedules.where((s) => !_isDroneSchedule(s)).toList();
    final myKioskList = allKioskList.where(_isScheduleMine).toList();
    final kioskList = _mySchedulesOnly ? myKioskList : allKioskList;
    final dueList = kioskList.where((s) => s['due'] == true).toList();
    final upcomingList = kioskList.where((s) => s['due'] != true).toList();

    List<Map<String, dynamic>> displayed;
    switch (_scheduleFilter) {
      case 'DUE':
        displayed = dueList;
        break;
      case 'UPCOMING':
        displayed = upcomingList;
        break;
      default:
        displayed = kioskList;
    }

    final due = displayed.where((s) => s['due'] == true).toList();
    final upcoming = displayed.where((s) => s['due'] != true).toList();

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          const OpsBanner(
            tone: OpsBannerTone.info,
            icon: Icons.event_repeat,
            text: 'Lịch kiểm tra định kỳ Kiosk do quản trị tạo và giao KTV phụ trách. '
                'Khi đến hạn, bấm "Kiểm tra" và đánh giá từng hạng mục: tất cả đạt ⇒ dời '
                'sang chu kỳ kế tiếp; có mục không đạt ⇒ hệ thống mở phiếu giao cho bạn, '
                'hạn chỉ dời khi phiếu được hoàn tất.',
          ),
          const SizedBox(height: 10),

          // Phạm vi: lịch giao cho mình / mọi lịch tủ
          Row(
            children: [
              _buildScheduleChip(
                label: 'Của tôi (${myKioskList.length})',
                selected: _mySchedulesOnly,
                icon: Icons.person_outline,
                onTap: () => setState(() => _mySchedulesOnly = true),
              ),
              const SizedBox(width: 8),
              _buildScheduleChip(
                label: 'Tất cả (${allKioskList.length})',
                selected: !_mySchedulesOnly,
                icon: Icons.groups_outlined,
                onTap: () => setState(() => _mySchedulesOnly = false),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Thanh lọc theo hạn: Mọi hạn, Đến hạn, Sắp tới
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildScheduleChip(
                  label: 'Mọi hạn (${kioskList.length})',
                  selected: _scheduleFilter == 'ALL',
                  onTap: () => setState(() => _scheduleFilter = 'ALL'),
                ),
                const SizedBox(width: 8),
                _buildScheduleChip(
                  label: 'Đến hạn (${dueList.length})',
                  selected: _scheduleFilter == 'DUE',
                  icon: Icons.warning_amber_rounded,
                  activeColor: const Color(0xFFDC2626),
                  onTap: () => setState(() => _scheduleFilter = 'DUE'),
                ),
                const SizedBox(width: 8),
                _buildScheduleChip(
                  label: 'Sắp tới (${upcomingList.length})',
                  selected: _scheduleFilter == 'UPCOMING',
                  icon: Icons.schedule_outlined,
                  activeColor: const Color(0xFF2563EB),
                  onTap: () => setState(() => _scheduleFilter = 'UPCOMING'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          if (displayed.isEmpty)
            OpsEmptyState(
              icon: Icons.event_available_outlined,
              title: _scheduleFilter == 'DUE'
                  ? 'Không có lịch kiểm tra Kiosk nào đến hạn'
                  : _scheduleFilter == 'UPCOMING'
                      ? 'Không có lịch kiểm tra Kiosk nào sắp tới'
                      : _mySchedulesOnly
                          ? 'Bạn chưa được giao lịch kiểm tra nào'
                          : 'Chưa có kế hoạch kiểm tra định kỳ Kiosk nào',
              subtitle: _mySchedulesOnly
                  ? 'Chọn "Tất cả" để xem lịch của các KTV khác.'
                  : 'Mọi thiết bị Kiosk đều đang trong chu kỳ bảo trì bình thường.',
            ),
          if (_scheduleFilter == 'ALL') ...[
            if (due.isNotEmpty) ...[
              OpsSectionLabel('Đến hạn (${due.length})', icon: Icons.warning_amber_rounded),
              for (final s in due) _scheduleCard(s, due: true),
              const SizedBox(height: 8),
            ],
            if (upcoming.isNotEmpty) ...[
              OpsSectionLabel('Sắp tới (${upcoming.length})', icon: Icons.schedule_outlined),
              for (final s in upcoming) _scheduleCard(s, due: false),
            ],
          ] else ...[
            for (final s in displayed) _scheduleCard(s, due: s['due'] == true),
          ],
        ],
      ),
    );
  }

  Widget _buildScheduleChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
    IconData? icon,
    Color activeColor = opsPrimary,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? activeColor.withValues(alpha: 0.12) : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? activeColor : const Color(0xFFE2E8F0),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 14, color: selected ? activeColor : opsMutedText),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: selected ? FontWeight.bold : FontWeight.w600,
                color: selected ? activeColor : opsDark,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Tính toán số ngày còn lại đến hạn hoặc quá hạn để KTV nắm bắt thời hạn
  (String, bool) _remainingDaysInfo(dynamic nextDueAtValue) {
    final nextDue = _parseDate(nextDueAtValue);
    if (nextDue == null) return ('', false);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final targetDate = DateTime(nextDue.year, nextDue.month, nextDue.day);
    final dayDiff = targetDate.difference(today).inDays;

    if (dayDiff < 0) {
      return ('Quá hạn ${-dayDiff} ngày', true);
    } else if (dayDiff == 0) {
      return ('Đến hạn hôm nay', true);
    } else if (dayDiff == 1) {
      return ('Còn 1 ngày nữa đến hạn', false);
    } else {
      return ('Còn $dayDiff ngày nữa đến hạn', false);
    }
  }

  Widget _scheduleCard(Map<String, dynamic> s, {required bool due}) {
    final lockerCode = s['lockerCode'];
    final lockerName = s['lockerName'];

    final targetLabel =
        '${lockerName ?? "Tủ Kiosk"}${lockerCode != null ? " ($lockerCode)" : ""}';
    final targetIcon = Icons.inventory_2_outlined;
    final nextDue = _fmtDateTime(s['nextDueAt']) ?? _fmtDate(s['nextDueAt']);
    final lastDone = _fmtDateTime(s['lastDoneAt']) ?? _fmtDate(s['lastDoneAt']);
    final id = _asInt(s['id']);
    final rem = _remainingDaysInfo(s['nextDueAt']);
    final pendingReportId = _asInt(s['pendingReportId']);
    final lastResult = s['lastResult']?.toString();
    final assignedId = s['assignedTechnicianId']?.toString();
    final assignedToMe = _isScheduleMine(s);
    // Server chặn: lịch đang chờ phiếu KHÔNG ĐẠT (409) hoặc giao cho KTV khác (403).
    final blockedReason = pendingReportId != null
        ? 'Lần trước không đạt — hoàn tất phiếu #$pendingReportId trước khi kiểm tra lại.'
        : assignedId != null && !assignedToMe
            ? 'Lịch do KTV khác phụ trách.'
            : null;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: OpsCard(
        border: due
            ? Border.all(color: const Color(0xFFFCA5A5), width: 1.2)
            : null,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${s['title'] ?? ''}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: opsDark,
              ),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                if (due)
                  const _MiniPill(
                    icon: Icons.warning_amber_rounded,
                    text: 'Đến hạn',
                    color: Color(0xFFDC2626),
                  ),
                if (due && rem.$1.isNotEmpty)
                  _MiniPill(
                    icon: Icons.timer_outlined,
                    text: rem.$1,
                    color: const Color(0xFFDC2626),
                  ),
                // Badge đếm ngược nổi bật ở góc trên bên phải cho những card sắp tới:
                if (!due && rem.$1.isNotEmpty)
                  _MiniPill(
                    icon: Icons.hourglass_top_rounded,
                    text: rem.$1,
                    color: const Color(0xFF2563EB),
                  ),
                const _MiniPill(
                  icon: Icons.inventory_2_outlined,
                  text: 'Trạm Kiosk',
                  color: Color(0xFFD97706),
                ),
                if (pendingReportId != null)
                  InkWell(
                    onTap: () => _openReportById(pendingReportId),
                    borderRadius: BorderRadius.circular(999),
                    child: _MiniPill(
                      icon: Icons.pending_actions,
                      text: 'Chờ phiếu #$pendingReportId',
                      color: const Color(0xFFEA580C),
                    ),
                  ),
                if (lastResult == 'PASSED')
                  const _MiniPill(
                    icon: Icons.verified_outlined,
                    text: 'Lần trước: ĐẠT',
                    color: Color(0xFF16A34A),
                  ),
                if (lastResult == 'FAILED')
                  const _MiniPill(
                    icon: Icons.report_gmailerrorred_outlined,
                    text: 'Lần trước: KHÔNG ĐẠT',
                    color: Color(0xFFDC2626),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                _MiniPill(
                  icon: targetIcon,
                  text: targetLabel,
                  color: const Color(0xFFB45309),
                ),
                _MiniPill(
                  icon: Icons.repeat,
                  text: 'Chu kỳ: Mỗi ${s['intervalDays']} ngày',
                ),
                if (nextDue != null)
                  _MiniPill(
                    icon: Icons.event,
                    text: 'Hạn tới: $nextDue',
                    color: due ? const Color(0xFFDC2626) : const Color(0xFF16A34A),
                  ),
                if (s['scheduledTimeSlot'] != null && (s['scheduledTimeSlot'] as String).isNotEmpty)
                  _MiniPill(
                    icon: Icons.access_time_filled,
                    text: 'Ca: ${s['scheduledTimeSlot']}',
                    color: const Color(0xFFD97706),
                  ),
                if (lastDone != null)
                  _MiniPill(
                    icon: Icons.history,
                    text: 'Lần trước: $lastDone',
                  ),
                _MiniPill(
                  icon: Icons.engineering_outlined,
                  text: assignedId == null
                      ? 'Chưa giao KTV'
                      : assignedToMe
                          ? 'KTV phụ trách: bạn'
                          : 'KTV phụ trách: ${s['assignedTechnicianName'] ?? '#$assignedId'}',
                  color: assignedToMe ? const Color(0xFF16A34A) : opsMutedText,
                ),
              ],
            ),
            if (s['address'] != null && (s['address'] as String).isNotEmpty) ...[
              const SizedBox(height: 6),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.place_outlined, size: 14, color: Color(0xFF16A34A)),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      '${s['address']}${s['locationNote'] != null && (s['locationNote'] as String).isNotEmpty ? " · Vị trí: ${s['locationNote']}" : ""}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: opsDark,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ] else if (s['locationNote'] != null && (s['locationNote'] as String).isNotEmpty) ...[
              const SizedBox(height: 6),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.push_pin_outlined, size: 14, color: Color(0xFF4F46E5)),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'Vị trí đặt tủ: ${s['locationNote']}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: opsDark,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 10),
            // Lịch bị chặn vì lần trước KHÔNG ĐẠT: trước đây chỉ có một dòng chữ
            // xám 11.5px cạnh nút đã mờ, nên KTV không biết phải làm gì để kiểm
            // tra tiếp. Nay nói rõ bước kế tiếp và cho bấm thẳng vào phiếu.
            if (blockedReason != null) ...[
              OpsBanner(
                tone: OpsBannerTone.warning,
                icon: Icons.report_gmailerrorred_outlined,
                text: pendingReportId != null
                    ? 'Lần kiểm tra trước KHÔNG ĐẠT nên hệ thống đã mở phiếu '
                          '#$pendingReportId. Xử lý xong và nghiệm thu phiếu đó '
                          'thì lịch này mở lại để kiểm tra tiếp.'
                    : blockedReason,
              ),
              const SizedBox(height: 8),
            ],
            Row(
              children: [
                const Spacer(),
                if (pendingReportId != null)
                  ElevatedButton.icon(
                    onPressed: () => _openReportById(pendingReportId),
                    icon: const Icon(Icons.assignment_turned_in_outlined,
                        size: 16),
                    label: Text('Xử lý phiếu #$pendingReportId'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFEA580C),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  )
                else
                  ElevatedButton.icon(
                    onPressed: id == null || blockedReason != null
                        ? null
                        : () => _showCompleteInspectionSheet(s),
                    icon: const Icon(Icons.fact_check_outlined, size: 16),
                    label: const Text('Kiểm tra'),
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

  /// Mở sheet đánh giá checklist; xong thì báo kết quả server suy ra (ĐẠT dời
  /// hạn / KHÔNG ĐẠT kèm phiếu vừa mở) rồi tải lại.
  Future<void> _showCompleteInspectionSheet(Map<String, dynamic> s) async {
    final id = _asInt(s['id']);
    if (id == null) return;
    // Trang đang mở đúng tủ của lịch ⇒ dùng luôn danh sách ô để chọn ô hỏng.
    final cells = _selectedLockerId != null &&
            _selectedLockerId == _asInt(s['lockerId'])
        ? (_layout?['cells'] as List?)?.cast<Map<String, dynamic>>()
        : null;
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => CompleteInspectionSheet(
        schedule: s,
        service: _service,
        lockerCells: cells,
      ),
    );
    if (result == null || !mounted) return;
    final pendingReportId = _asInt(result['pendingReportId']);
    final failed = result['lastResult'] == 'FAILED' || pendingReportId != null;
    final nextDue = _fmtDate(result['nextDueAt']);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor:
            failed ? const Color(0xFFDC2626) : const Color(0xFF16A34A),
        duration: Duration(seconds: pendingReportId != null ? 6 : 4),
        content: Text(
          pendingReportId != null
              ? 'Kiểm tra KHÔNG ĐẠT — đã mở phiếu #$pendingReportId giao cho bạn. '
                    'Hạn kế tiếp chỉ dời khi phiếu được hoàn tất.'
              : failed
                  ? 'Đã ghi nhận KHÔNG ĐẠT cho "${s['title'] ?? 'Tủ Kiosk'}".'
                  : 'Đã ghi nhận ĐẠT cho "${s['title'] ?? 'Tủ Kiosk'}"'
                        '${nextDue != null ? ' — hạn kế tiếp $nextDue' : ''}.',
        ),
        action: pendingReportId == null
            ? null
            : SnackBarAction(
                label: 'Xem việc',
                textColor: Colors.white,
                onPressed: () => _tabs.animateTo(2),
              ),
      ),
    );
    await _load();
  }

  String? _fmtDate(dynamic value) {
    final d = _parseDate(value);
    if (d == null) return null;
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(d.day)}/${two(d.month)}/${d.year}';
  }

  String? _fmtDateTime(dynamic value) {
    final d = _parseDate(value);
    if (d == null) return null;
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(d.hour)}:${two(d.minute)}:${two(d.second)} ${two(d.day)}/${two(d.month)}/${d.year}';
  }

  bool _isDroneSchedule(Map<String, dynamic> s) {
    if (s['droneUnitId'] != null || s['droneCode'] != null) return true;
    // Lịch gắn tủ (kể cả kiểm tra bãi đáp) là việc của KTV tủ.
    if (s['lockerId'] != null) return false;
    final t = (s['title'] ?? '').toString().toLowerCase();
    final lc = (s['lockerCode'] ?? '').toString().toLowerCase();
    final ln = (s['lockerName'] ?? '').toString().toLowerCase();
    final dc = (s['droneCode'] ?? '').toString().toLowerCase();
    if (dc.isNotEmpty) return true;
    return t.contains('drone') ||
        t.contains('cánh') ||
        t.contains('bãi đáp') ||
        t.contains('marker') ||
        t.contains('pin ') ||
        t.contains('pin drone') ||
        t.contains('hiệu chuẩn') ||
        t.contains('bay') ||
        lc.contains('drone') ||
        ln.contains('drone');
  }

  bool _isDroneReport(Map<String, dynamic> r) {
    if (r['droneUnitId'] != null) return true;
    // Server đã phân loại (BOX/DRONE/LANDING_PAD/LOCKER) ⇒ tin `category`;
    // phiếu bãi đáp là việc của KTV tủ. Đoán theo chữ chỉ cho response cũ.
    final category = r['category']?.toString();
    if (category != null && category.isNotEmpty) return category == 'DRONE';
    final t = (r['title'] ?? '').toString().toLowerCase();
    final d = (r['description'] ?? '').toString().toLowerCase();
    final ct = (r['cellType'] ?? '').toString().toUpperCase();
    final lc = (r['lockerCode'] ?? '').toString().toLowerCase();
    final ln = (r['lockerName'] ?? '').toString().toLowerCase();
    final boxNum = (r['boxNumber'] ?? '').toString().toLowerCase();

    if (ct == 'DRONE') return true;
    if (t.contains('drone') ||
        d.contains('drone') ||
        lc.contains('drone') ||
        ln.contains('drone') ||
        boxNum.contains('drone')) {
      return true;
    }
    if (t.contains('đội bay') ||
        d.contains('đội bay') ||
        t.contains('pin drone') ||
        d.contains('pin drone')) {
      return true;
    }
    if (t.contains('gãy càng') ||
        d.contains('gãy càng') ||
        t.contains('mất thăng bằng') ||
        d.contains('mất thăng bằng')) {
      return true;
    }
    if (t.contains('hạ cánh') ||
        d.contains('hạ cánh') ||
        t.contains('bãi đáp') ||
        d.contains('bãi đáp')) {
      return true;
    }
    return false;
  }

  bool _isDroneFault(Map<String, dynamic> f) {
    final ct = (f['cellType'] ?? '').toString().toUpperCase();
    final r = (f['faultReason'] ?? '').toString().toLowerCase();
    final ln = (f['lockerName'] ?? '').toString().toLowerCase();
    return ct == 'DRONE' ||
        r.contains('drone') ||
        r.contains('bãi đáp') ||
        ln.contains('drone');
  }

  bool _isDroneAnomaly(Map<String, dynamic> a) {
    final ct = (a['cellType'] ?? '').toString().toUpperCase();
    final ln = (a['lockerName'] ?? '').toString().toLowerCase();
    return ct == 'DRONE' || ln.contains('drone');
  }


  DateTime? _getEffectiveDueAt(Map<String, dynamic> r) {
    final reportId = _asInt(r['id']);
    // 1. Kiểm tra bộ nhớ cục bộ nếu KTV hoặc Admin vừa gia hạn trên máy
    if (reportId != null && _localSlaExtensions.containsKey(reportId)) {
      final ext = _localSlaExtensions[reportId]!;
      final extDue = _parseDate(ext['extendedDueAt']);
      if (extDue != null) return extDue;
    }

    final extHours = (_localSlaExtensions[reportId]?['extensionHours'] ??
            r['slaExtendedHours'] as num? ??
            0)
        .toInt();
    final slaHours = (r['slaHours'] as num? ?? 4).toInt();
    final dueAt = _parseDate(r['slaDueAt']);
    final created = _parseDate(r['createdAt']);
    final now = DateTime.now();

    // 2. Mốc gia hạn chuẩn xác từ Backend (Backend extendSla đã tính: now + extHours)
    if (dueAt != null) {
      return dueAt;
    }

    // 3. Nếu phiếu có số giờ gia hạn nhưng chưa có slaDueAt trong DB
    if (extHours > 0) {
      final reqAtStr = _localSlaExtensions[reportId]?['requestedAt'];
      final reqAt = _parseDate(reqAtStr);
      if (reqAt != null) {
        return reqAt.add(Duration(hours: extHours));
      }
      return now.add(Duration(hours: extHours));
    }

    // 4. Chưa gia hạn: trả về createdAt + slaHours
    if (created != null) {
      return created.add(Duration(hours: slaHours));
    }
    return null;
  }

  bool _isReportOverdue(Map<String, dynamic> r) {
    if (r['status'] == 'RESOLVED') return false;
    final now = DateTime.now();
    final effectiveDue = _getEffectiveDueAt(r);
    if (effectiveDue != null) {
      return now.isAfter(effectiveDue);
    }
    return r['overdue'] == true;
  }

  Future<void> _submitExtendSla(
      int reportId, int hours, String reason, DateTime newDue) async {
    try {
      await _service.extendReportSla(reportId,
          extensionHours: hours, reason: reason);
    } catch (e) {
      debugPrint('Cloud extendReportSla failed, applying local fallback: $e');
    }
    // Lưu vào bộ nhớ cục bộ để đồng bộ tức thời
    _localSlaExtensions[reportId] = {
      'reportId': reportId,
      'extendedDueAt': newDue.toIso8601String(),
      'extensionHours': hours,
      'reason': reason,
      'requestedAt': DateTime.now().toIso8601String(),
    };
    await _saveLocalSlaExtensions();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF059669),
          content: Text(
              'Đã gia hạn SLA thành công thêm +$hours giờ cho phiếu #$reportId'),
        ),
      );
    }
    await _load();
  }

  void _openExtendSlaSheet(Map<String, dynamic> r) {
    final reportId = _asInt(r['id']);
    if (reportId == null) return;
    int selectedHours = 4;
    final reasonController = TextEditingController();
    final now = DateTime.now();
    final currentDue = _getEffectiveDueAt(r) ?? now;
    final baseDue = currentDue.isAfter(now) ? currentDue : now;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            final newDue = baseDue.add(Duration(hours: selectedHours));
            return SafeArea(
              top: false,
              child: Padding(
                padding: EdgeInsets.only(
                  left: 20,
                  right: 20,
                  top: 16,
                  bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
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
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEF3C7),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.more_time_rounded,
                                color: Color(0xFFD97706), size: 22),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Gia hạn SLA phiếu #${r['id']}',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: opsDark,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${r['title'] ?? ''}',
                                  style: const TextStyle(
                                      fontSize: 12, color: opsMutedText),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFFBEB),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFFDE68A)),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Hạn hiện tại:',
                                    style: TextStyle(
                                        fontSize: 12.5,
                                        color: Color(0xFF92400E))),
                                Text(_formatFullDateTime(currentDue),
                                    style: const TextStyle(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF92400E))),
                              ],
                            ),
                            const Divider(height: 12, color: Color(0xFFFDE68A)),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Hạn mới sau gia hạn:',
                                    style: TextStyle(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFFB45309))),
                                Text(_formatFullDateTime(newDue),
                                    style: const TextStyle(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFFB45309))),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      const Text('Chọn thời gian gia hạn:',
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: opsDark)),
                      const SizedBox(height: 8),
                      Row(
                        children: [2, 4, 8, 24].map((hrs) {
                          final isSel = selectedHours == hrs;
                          return Expanded(
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 3),
                              child: InkWell(
                                onTap: () =>
                                    setModalState(() => selectedHours = hrs),
                                borderRadius: BorderRadius.circular(10),
                                child: Container(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 10),
                                  decoration: BoxDecoration(
                                    color: isSel
                                        ? const Color(0xFFD97706)
                                        : Colors.white,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: isSel
                                          ? const Color(0xFFD97706)
                                          : const Color(0xFFE2E8F0),
                                      width: isSel ? 1.5 : 1,
                                    ),
                                  ),
                                  child: Center(
                                    child: Text(
                                      '+$hrs h',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: isSel
                                            ? FontWeight.bold
                                            : FontWeight.w600,
                                        color: isSel ? Colors.white : opsDark,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 14),
                      const Text('Lý do gia hạn (bắt buộc):',
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: opsDark)),
                      const SizedBox(height: 6),
                      TextField(
                        controller: reasonController,
                        maxLines: 2,
                        style: const TextStyle(fontSize: 13),
                        decoration: InputDecoration(
                          hintText: 'Nhập lý do cần thêm thời gian xử lý...',
                          hintStyle: const TextStyle(
                              fontSize: 12.5, color: opsMutedText),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10)),
                          contentPadding: const EdgeInsets.all(10),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          'Chờ linh kiện thay thế',
                          'Cần kiểm tra sâu mạch điện',
                          'Tủ khó tiếp cận',
                          'Phối hợp bên vận hành tòa nhà',
                        ].map((preset) {
                          return InkWell(
                            onTap: () => setModalState(
                                () => reasonController.text = preset),
                            borderRadius: BorderRadius.circular(6),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(6),
                                border:
                                    Border.all(color: const Color(0xFFCBD5E1)),
                              ),
                              child: Text(preset,
                                  style: const TextStyle(
                                      fontSize: 11, color: Color(0xFF475569))),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 18),
                      SizedBox(
                        width: double.infinity,
                        height: 46,
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            final reason = reasonController.text.trim();
                            if (reason.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text(
                                        'Vui lòng nhập lý do gia hạn SLA')),
                              );
                              return;
                            }
                            Navigator.of(ctx).pop();
                            await _submitExtendSla(
                                reportId, selectedHours, reason, newDue);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFD97706),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          icon:
                              const Icon(Icons.check_circle_outline, size: 18),
                          label: const Text('Xác nhận gia hạn SLA',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 14)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
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

  /// Nhãn phụ của phiếu: loại tài sản, chặn cả tủ, sinh từ lịch định kỳ,
  /// định tuyến cho tủ mình phụ trách.
  List<Widget> _ticketBadges(Map<String, dynamic> r) {
    final category = r['category']?.toString();
    final scheduleId = _asInt(r['scheduleId']);
    final routedToMe = r['status'] == 'OPEN' &&
        _myUserId != null &&
        r['routedToUserId']?.toString() == _myUserId;
    return [
      if (category == 'LANDING_PAD')
        const _MiniPill(
          icon: Icons.flight_land,
          text: 'Bãi đáp',
          color: Color(0xFF7C3AED),
        ),
      if (category == 'LOCKER')
        const _MiniPill(
          icon: Icons.warehouse_outlined,
          text: 'Cấp tủ',
          color: Color(0xFF0369A1),
        ),
      if (r['blocksLocker'] == true)
        const _MiniPill(
          icon: Icons.block,
          text: 'Ngưng cả tủ',
          color: Color(0xFFDC2626),
        ),
      if (scheduleId != null)
        _MiniPill(
          icon: Icons.event_repeat,
          text: 'Từ kiểm tra định kỳ #$scheduleId',
          color: const Color(0xFF7C3AED),
        ),
      if (routedToMe)
        const _MiniPill(
          icon: Icons.assignment_ind_outlined,
          text: 'Tủ bạn phụ trách',
          color: Color(0xFFD97706),
        ),
    ];
  }

  Widget _reportCard(Map<String, dynamic> r, {bool isQueueView = false}) {
    final status = r['status'] as String? ?? '';
    // Kiểm tra phiếu có đang được assign cho chính KTV này không
    final isAssignedToMe = _isAssignedToMe(r);
    final lockerLabel = r['lockerName'] ?? 'Chưa tra được tên tủ';
    final boxLabel = r['boxNumber'] ?? r['boxId'];
    final createdAt = _parseDate(r['createdAt']);
    final (_, userPhotos) = _extractUserPhotosAndClean(
      r['description'],
      r['photoUrls'] ?? r['photos'],
    );
    final isNew = status == 'OPEN';
    final attachments = [
      ...userPhotos.map((u) => ReportAttachment(
            url: u,
            stage: ReportStage.report,
            createdAt: createdAt,
          )),
      ...ReportAttachment.listFrom(r['attachments']),
    ];
    final hasInspection =
        attachments.any((a) => a.stage == ReportStage.inspection);

    final extHours = (_localSlaExtensions[r['id']]?['extensionHours'] ?? r['slaExtendedHours'] as num? ?? 0).toInt();
    final isExtended = extHours > 0;
    final effectiveDue = _getEffectiveDueAt(r);
    final isOverdue = _isReportOverdue(r);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showReportDetailModal(r),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: isNew
                  ? const Color(0xFFFFFDF5)
                  : isOverdue
                      ? const Color(0xFFFFFBFB)
                      : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isNew
                    ? const Color(0xFFFDE68A)
                    : isOverdue
                        ? const Color(0xFFFECACA)
                        : const Color(0xFFE2E8F0),
                width: isOverdue || isNew ? 1.2 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // 1. Tiêu đề + SLA đếm ngược + Trạng thái
                Row(
                  children: [
                    if (isNew) ...[
                      Container(
                        margin: const EdgeInsets.only(right: 6),
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF59E0B),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'MỚI',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 9.5,
                          ),
                        ),
                      ),
                    ],
                    Expanded(
                      child: Text(
                        '#${r['id']} · ${r['title'] ?? ''}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14.5,
                          color: opsDark,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    _SlaCountdownBadge(
                      dueAt: effectiveDue,
                      createdAt: createdAt,
                      slaHours: (r['slaHours'] as num? ?? 4).toInt(),
                      status: status,
                      isExtended: isExtended,
                      extendedHours: extHours,
                    ),
                    const SizedBox(width: 6),
                    StatusChip(status),
                  ],
                ),
                const SizedBox(height: 8),

                // 2. Dòng thông tin cốt lõi (Vị trí tủ, thời gian, số ảnh, gia hạn)
                Wrap(
                  spacing: 8,
                  runSpacing: 5,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.inventory_2_outlined, size: 13.5, color: opsPrimary),
                        const SizedBox(width: 4),
                        Text(
                          '$lockerLabel${boxLabel != null ? ' · ô $boxLabel' : ''}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF334155),
                          ),
                        ),
                      ],
                    ),
                    if (createdAt != null) ...[
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.access_time, size: 13, color: Color(0xFF94A3B8)),
                          const SizedBox(width: 3),
                          Text(
                            _formatCompactDateTime(createdAt),
                            style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                          ),
                        ],
                      ),
                    ],
                    if (attachments.isNotEmpty) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.photo_library_outlined, size: 12, color: Color(0xFF64748B)),
                            const SizedBox(width: 3),
                            Text(
                              '${attachments.length} ảnh',
                              style: const TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF475569),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    if (isExtended) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF3C7),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: const Color(0xFFFDE68A)),
                        ),
                        child: Text(
                          '+$extHours h SLA',
                          style: const TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFFB45309),
                          ),
                        ),
                      ),
                    ],
                    ..._ticketBadges(r),
                  ],
                ),
                const SizedBox(height: 10),

                // 3. Thanh thao tác nhanh và nút bấm chính
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    // Nhóm công cụ: Chỉ đường, Nhật ký
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        InkWell(
                          onTap: () => _openDirections(r),
                          borderRadius: BorderRadius.circular(8),
                          child: const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 5, vertical: 4),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.near_me_outlined, size: 13.5, color: opsPrimary),
                                SizedBox(width: 3),
                                Text(
                                  'Chỉ đường',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: opsPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        InkWell(
                          onTap: () => _reportLogSheet(r),
                          borderRadius: BorderRadius.circular(8),
                          child: const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 5, vertical: 4),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.history_edu_outlined, size: 13.5, color: opsPrimary),
                                SizedBox(width: 3),
                                Text(
                                  'Nhật ký',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: opsPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),

                    // Nhóm hành động
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Nút nhận việc nếu OPEN
                        if ((isQueueView || status == 'OPEN') && status == 'OPEN')
                          ElevatedButton.icon(
                            onPressed: () async {
                              final success = await _run(
                                () => _service.claimReport(r['id'] as int),
                                'Đã nhận việc thành công',
                              );
                              if (success && mounted) {
                                _tabs.animateTo(2);
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFF59E0B),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              visualDensity: VisualDensity.compact,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            icon: const Icon(Icons.pan_tool_alt, size: 12.5),
                            label: const Text(
                              'Nhận việc',
                              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 11),
                            ),
                          ),
                        // Nút gia hạn, nghiệm thu & hoàn tất nếu IN_PROGRESS của KTV
                        if (!isQueueView && status == 'IN_PROGRESS' && isAssignedToMe) ...[
                          // Nút gia hạn SLA nhanh
                          InkWell(
                            onTap: () => _openExtendSlaSheet(r),
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFFBEB),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: const Color(0xFFFDE68A)),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.more_time,
                                    size: 13,
                                    color: Color(0xFFD97706),
                                  ),
                                  SizedBox(width: 3),
                                  Text(
                                    'Gia hạn',
                                    style: TextStyle(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFFD97706),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 5),
                          InkWell(
                            onTap: () => _inspectionFlow(r),
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFEF3C7),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: const Color(0xFFFDE68A)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    hasInspection ? Icons.fact_check : Icons.add_a_photo_outlined,
                                    size: 13,
                                    color: const Color(0xFFB45309),
                                  ),
                                  const SizedBox(width: 3),
                                  Text(
                                    hasInspection ? 'Ảnh (+)' : 'Nghiệm thu',
                                    style: const TextStyle(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFFB45309),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 5),
                          ElevatedButton.icon(
                            onPressed: () => _confirmResolveReport(r),
                            icon: const Icon(Icons.check, size: 13),
                            label: const Text(
                              'Hoàn tất',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF16A34A),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              visualDensity: VisualDensity.compact,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            ),
                          ),
                        ],
                        const SizedBox(width: 3),
                        const Icon(Icons.chevron_right, size: 16, color: Color(0xFF94A3B8)),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Modal BottomSheet hiển thị toàn bộ 100% thông tin chi tiết của phiếu sự cố
  void _showReportDetailModal(Map<String, dynamic> r) {
    final status = r['status'] as String? ?? '';
    final assignedToMe = _isAssignedToMe(r);
    final lockerLabel = r['lockerName'] ?? 'Chưa tra được tên tủ';
    final boxLabel = r['boxNumber'] ?? r['boxId'];
    final createdAt = _parseDate(r['createdAt']);
    final ageLabel = createdAt == null ? null : _ageLabel(createdAt);
    final (cleanedDesc, userPhotos) = _extractUserPhotosAndClean(
      r['description'],
      r['photoUrls'] ?? r['photos'],
    );
    final attachments = [
      ...userPhotos.map((u) => ReportAttachment(
            url: u,
            stage: ReportStage.report,
            createdAt: createdAt,
          )),
      ...ReportAttachment.listFrom(r['attachments']),
    ];
    final hasInspection =
        attachments.any((a) => a.stage == ReportStage.inspection);
    final reporterName = (r['reporterName'] ?? '').toString().trim();
    final reporterPhone = (r['reporterPhone'] ?? '').toString().trim();
    final lockerAddress = (r['lockerAddress'] ?? '').toString().trim();
    final overdue = _isReportOverdue(r);
    final extHours = (_localSlaExtensions[r['id']]?['extensionHours'] ?? r['slaExtendedHours'] as num? ?? 0).toInt();
    final isExtended = extHours > 0;
    final effectiveDue = _getEffectiveDueAt(r);

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          top: false,
          child: SizedBox(
            height: MediaQuery.of(ctx).size.height * 0.85,
            child: Column(
              children: [
                // Drag handle
                Center(
                  child: Container(
                    margin: const EdgeInsets.only(top: 12, bottom: 8),
                    width: 44,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                // Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '#${r['id']} · ${r['title'] ?? ''}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: opsDark,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Hồ sơ chi tiết phiếu sự cố kỹ thuật',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      _SlaCountdownBadge(
                        dueAt: effectiveDue,
                        createdAt: createdAt,
                        slaHours: (r['slaHours'] as num? ?? 4).toInt(),
                        status: status,
                        isExtended: isExtended,
                        extendedHours: extHours,
                      ),
                      const SizedBox(width: 6),
                      StatusChip(status),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                // Scrollable body
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Badges row
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          children: [
                            _SlaCountdownBadge(
                              dueAt: effectiveDue,
                              createdAt: createdAt,
                              slaHours: (r['slaHours'] as num? ?? 4).toInt(),
                              status: status,
                              isExtended: isExtended,
                              extendedHours: extHours,
                            ),
                            if (isExtended && !overdue)
                              _MiniPill(
                                icon: Icons.more_time,
                                text: 'Đã gia hạn SLA (+$extHours h)',
                                color: const Color(0xFFD97706),
                              ),
                            if (isExtended && overdue)
                              _MiniPill(
                                icon: Icons.warning_amber_rounded,
                                text: 'Quá hạn (sau gia hạn +$extHours h)',
                                color: const Color(0xFFDC2626),
                              ),
                            if (!isExtended && overdue)
                              const _MiniPill(
                                icon: Icons.warning_amber_rounded,
                                text: 'Quá hạn SLA',
                                color: Color(0xFFDC2626),
                              ),
                            if (ageLabel != null)
                              _MiniPill(
                                icon: Icons.schedule,
                                text: ageLabel,
                                color: overdue
                                    ? const Color(0xFFDC2626)
                                    : (createdAt != null ? _slaColor(createdAt) : opsPrimary),
                              ),
                            if (r['assignedToUserId'] != null)
                              _MiniPill(
                                icon: Icons.engineering_outlined,
                                text: 'KTV #${r['assignedToUserId']}${assignedToMe ? ' (bạn)' : ''}',
                              ),
                            if (createdAt != null)
                              _MiniPill(
                                icon: Icons.access_time,
                                text: 'Tạo lúc: ${_formatFullDateTime(createdAt)}',
                              ),
                            if (effectiveDue != null)
                              _MiniPill(
                                icon: Icons.timelapse,
                                text: 'Hạn SLA: ${_formatFullDateTime(effectiveDue)}',
                                color: overdue ? const Color(0xFFDC2626) : const Color(0xFF2563EB),
                              ),
                            if (isExtended && (r['slaExtensionReason'] != null || _localSlaExtensions[r['id']]?['reason'] != null))
                              _MiniPill(
                                icon: Icons.comment_outlined,
                                text: 'Lý do gia hạn: ${_localSlaExtensions[r['id']]?['reason'] ?? r['slaExtensionReason']}',
                                color: const Color(0xFF92400E),
                              ),
                            ..._ticketBadges(r),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Location & Locker card
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.inventory_2_outlined, size: 16, color: opsPrimary),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      '$lockerLabel${boxLabel != null ? ' · Ô #$boxLabel' : ''}',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: opsDark),
                                    ),
                                  ),
                                ],
                              ),
                            if (lockerAddress.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(Icons.location_on_outlined, size: 15, color: opsMutedText),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      lockerAddress,
                                      style: const TextStyle(fontSize: 12, color: opsMutedText),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                            const SizedBox(height: 10),
                            Align(
                              alignment: Alignment.centerRight,
                              child: OutlinedButton.icon(
                                onPressed: () {
                                  Navigator.pop(ctx);
                                  _openDirections(r);
                                },
                                icon: const Icon(Icons.near_me_outlined, size: 14, color: opsPrimary),
                                label: const Text(
                                  'Chỉ đường tới tủ',
                                  style: TextStyle(fontSize: 12, color: opsPrimary, fontWeight: FontWeight.w600),
                                ),
                                style: OutlinedButton.styleFrom(
                                  visualDensity: VisualDensity.compact,
                                  side: BorderSide(color: opsPrimary.withValues(alpha: 0.35)),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Reporter info card
                      if (reporterName.isNotEmpty || reporterPhone.isNotEmpty) ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 18,
                                backgroundColor: opsPrimary.withValues(alpha: 0.1),
                                child: const Icon(Icons.person, size: 20, color: opsPrimary),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      reporterName.isNotEmpty ? reporterName : 'Khách hàng',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: opsDark),
                                    ),
                                    if (reporterPhone.isNotEmpty)
                                      Text(
                                        reporterPhone,
                                        style: const TextStyle(fontSize: 12, color: opsMutedText, fontFamily: 'monospace'),
                                      ),
                                  ],
                                ),
                              ),
                              if (reporterPhone.isNotEmpty)
                                IconButton(
                                  icon: const Icon(Icons.copy, size: 18, color: opsPrimary),
                                  tooltip: 'Sao chép SĐT',
                                  onPressed: () {
                                    Clipboard.setData(ClipboardData(text: reporterPhone));
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Đã sao chép số điện thoại')),
                                    );
                                  },
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                      ],

                      // Description
                      if (cleanedDesc.isNotEmpty) ...[
                        const Text(
                          'Nội dung khách phản ánh:',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: opsDark),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            cleanedDesc,
                            style: const TextStyle(fontSize: 13, color: opsDark, height: 1.4),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Full stage attachments with timestamps
                      if (attachments.isNotEmpty) ...[
                        const Text(
                          'Hình ảnh minh chứng theo giai đoạn:',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: opsDark),
                        ),
                        const SizedBox(height: 8),
                        AttachmentStageGallery(
                          attachments: attachments,
                          labels: const {
                            ReportStage.report: 'Ảnh người báo',
                            ReportStage.inspection: 'Ảnh KTV xác nhận',
                            ReportStage.progress: 'Ảnh quá trình sửa',
                            ReportStage.resolution: 'Ảnh nghiệm thu',
                          },
                          accentColor: opsPrimary,
                          thumbSize: 76,
                        ),
                        const SizedBox(height: 16),
                      ],
                    ],
                  ),
                ),
              ),

              // Bottom action buttons in modal
              Container(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(top: BorderSide(color: Colors.grey.shade200)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 8,
                      offset: const Offset(0, -3),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Hàng 1: Nút hành động nghiệp vụ chính (Primary Workflow)
                    if (status == 'OPEN')
                      SizedBox(
                        width: double.infinity,
                        height: 46,
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            Navigator.pop(ctx);
                            await _run(
                              () => _service.claimReport(r['id'] as int),
                              'Đã nhận việc thành công',
                            );
                            if (mounted) {
                              _tabs.animateTo(2);
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFF59E0B),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          icon: const Icon(Icons.pan_tool_alt, size: 16),
                          label: const Text(
                            'Nhận việc ngay',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                        ),
                      ),
                    // Chỉ KTV đang được giao mới hoàn tất được (server trả 403 nếu không).
                    if (status == 'IN_PROGRESS' && assignedToMe)
                      Row(
                        children: [
                          Expanded(
                            child: SizedBox(
                              height: 46,
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  Navigator.pop(ctx);
                                  _inspectionFlow(r);
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFD97706),
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(horizontal: 6),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                icon: const Icon(Icons.add_a_photo_outlined, size: 16),
                                label: Text(
                                  hasInspection ? 'Bổ sung ảnh' : 'Xác nhận hiện trường',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: SizedBox(
                              height: 46,
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  Navigator.pop(ctx);
                                  _confirmResolveReport(r);
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF16A34A),
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(horizontal: 6),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                icon: const Icon(Icons.check_circle_outline, size: 16),
                                label: const Text(
                                  'Hoàn tất xử lý',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    if (status == 'IN_PROGRESS' && !assignedToMe)
                      OpsBanner(
                        tone: OpsBannerTone.info,
                        icon: Icons.engineering_outlined,
                        text: r['assignedToUserId'] != null
                            ? 'Phiếu đang do KTV #${r['assignedToUserId']} xử lý — chỉ người được giao mới hoàn tất được.'
                            : 'Phiếu đang được xử lý.',
                      ),
                    if (status == 'OPEN' || status == 'IN_PROGRESS')
                      const SizedBox(height: 10),

                    // Hàng 2: Nút tiện ích phụ (Chỉ đường + Nhật ký xử lý)
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 38,
                            child: OutlinedButton.icon(
                              onPressed: () {
                                Navigator.pop(ctx);
                                _openDirections(r);
                              },
                              icon: const Icon(Icons.map_outlined, size: 15),
                              label: const Text(
                                'Chỉ đường',
                                style: TextStyle(fontSize: 12.5),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: opsPrimary,
                                side: BorderSide(color: opsPrimary.withValues(alpha: 0.35)),
                                padding: const EdgeInsets.symmetric(horizontal: 6),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: SizedBox(
                            height: 38,
                            child: OutlinedButton.icon(
                              onPressed: () {
                                Navigator.pop(ctx);
                                _reportLogSheet(r);
                              },
                              icon: const Icon(Icons.history_edu_outlined, size: 15),
                              label: const Text(
                                'Nhật ký',
                                style: TextStyle(fontSize: 12),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: opsDark,
                                side: BorderSide(color: Colors.grey.shade300),
                                padding: const EdgeInsets.symmetric(horizontal: 4),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                          ),
                        ),
                        if (status == 'IN_PROGRESS') ...[
                          const SizedBox(width: 6),
                          Expanded(
                            child: SizedBox(
                              height: 38,
                              child: OutlinedButton.icon(
                                onPressed: () {
                                  Navigator.pop(ctx);
                                  _openExtendSlaSheet(r);
                                },
                                icon: const Icon(Icons.more_time, size: 15, color: Color(0xFFD97706)),
                                label: const Text(
                                  'Gia hạn SLA',
                                  style: TextStyle(fontSize: 12, color: Color(0xFFD97706), fontWeight: FontWeight.w700),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: const Color(0xFFD97706),
                                  side: const BorderSide(color: Color(0xFFFDE68A)),
                                  backgroundColor: const Color(0xFFFFFBEB),
                                  padding: const EdgeInsets.symmetric(horizontal: 4),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
  }

  /// KTV tới nơi: chụp ảnh INSPECTION xác nhận hiện trạng (+ ghi chú tuỳ chọn).
  Future<void> _inspectionFlow(Map<String, dynamic> report) async {
    final reportId = _asInt(report['id']);
    if (reportId == null) return;
    final done = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _InspectionSheet(
        reportId: reportId,
        title: '#${report['id']} · ${report['title'] ?? ''}',
        service: _service,
      ),
    );
    if (done == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã lưu ảnh xác nhận hiện trường')),
      );
      await _load();
    }
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
    return parseServerDateTime(value);
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

  String _formatCompactDateTime(DateTime dt) {
    final d = dt.day.toString().padLeft(2, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final hh = dt.hour.toString().padLeft(2, '0');
    final mm = dt.minute.toString().padLeft(2, '0');
    return '$hh:$mm $d/$m';
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
    final d = parseServerDateTime(value);
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

/// Số ảnh tối đa mỗi lần KTV gửi (INSPECTION/PROGRESS/RESOLUTION) — admin
/// cấu hình qua `app.maintenance.report-photos-per-request-staff`.
int get _staffPhotosPerRequest =>
    BusinessConfigService.instance.current.reportPhotosPerRequestStaff;

class _RepairLogSheetState extends State<_RepairLogSheet> {
  final _noteCtrl = TextEditingController();
  // Ảnh tiến độ (stage PROGRESS) gắn vào dòng nhật ký — tối đa theo cấu hình
  // app.maintenance.report-photos-per-request-staff.
  final _photos = PhotoPickerController(maxPhotos: _staffPhotosPerRequest);
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
    _photos.addListener(_onPhotosChanged);
    _load();
  }

  @override
  void dispose() {
    _photos
      ..removeListener(_onPhotosChanged)
      ..dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  void _onPhotosChanged() {
    if (mounted) setState(() {});
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

  void _showImagePickerOptions() => PhotoPickerField.pickWithSourceSheet(
    context,
    _photos,
    accentColor: opsPrimary,
  );

  /// Upload ảnh tiến độ lên Cloudinary rồi gửi kèm dòng nhật ký (stage
  /// PROGRESS). Upload lỗi giữa chừng: ảnh đã lên giữ lại, bấm gửi lại chỉ
  /// upload phần còn thiếu.
  Future<void> _add() async {
    final note = _noteCtrl.text.trim();
    if (note.isEmpty && _photos.isEmpty) return;
    setState(() => _sending = true);
    try {
      final attachments = await _photos.uploadAll();
      await widget.service.addReportLog(
        widget.reportId,
        note.isNotEmpty ? note : 'Cập nhật ảnh tiến độ sửa chữa',
        attachments: attachments,
      );
      _noteCtrl.clear();
      _photos.clear();
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
                        final logPhotos =
                            ReportAttachment.listFrom(log['attachments']);
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
                              if (logPhotos.isNotEmpty) ...[
                                const SizedBox(height: 6),
                                AttachmentStrip(
                                  attachments: logPhotos,
                                  size: 56,
                                  viewerTitle: 'Nhật ký · ${_fmt(log['createdAt'])}',
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
            if (_photos.isNotEmpty)
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
                          '${_photos.length} ảnh tiến độ đính kèm',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: opsPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    PhotoPickerField(
                      controller: _photos,
                      enabled: !_sending,
                      thumbSize: 68,
                      accentColor: opsPrimary,
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
  // "Trước khi sửa" = ảnh INSPECTION (bỏ qua nếu phiếu đã có),
  // "Sau khi xong" = ảnh RESOLUTION gửi cùng lệnh Hoàn tất.
  final _beforePhotos = PhotoPickerController(
    maxPhotos: _staffPhotosPerRequest,
  );
  final _afterPhotos = PhotoPickerController(
    maxPhotos: _staffPhotosPerRequest,
  );
  late final List<ReportAttachment> _attachments =
      ReportAttachment.listFrom(widget.report['attachments']);
  late final List<ReportAttachment> _existingInspection = _attachments
      .where((a) => a.stage == ReportStage.inspection)
      .toList(growable: false);
  late final List<ReportAttachment> _existingResolution = _attachments
      .where((a) => a.stage == ReportStage.resolution)
      .toList(growable: false);
  bool _submitting = false;
  // Ảnh INSPECTION đã gắn nhưng resolve lỗi ⇒ lần thử lại không gắn lần 2.
  bool _inspectionSaved = false;
  String? _error;

  final _quickNotes = const [
    'Đã thay thế linh kiện khóa điện tử',
    'Đã cân chỉnh then & bản lề cửa ô tủ',
    'Đã kiểm tra bo mạch điều khiển & nguồn',
    'Đã vệ sinh sạch sẽ, test đóng mở 3 lần',
  ];

  @override
  void initState() {
    super.initState();
    _beforePhotos.addListener(_onPhotosChanged);
    _afterPhotos.addListener(_onPhotosChanged);
  }

  @override
  void dispose() {
    _beforePhotos
      ..removeListener(_onPhotosChanged)
      ..dispose();
    _afterPhotos
      ..removeListener(_onPhotosChanged)
      ..dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  void _onPhotosChanged() {
    if (mounted) setState(() {});
  }

  bool get _hasAfterPhoto =>
      _afterPhotos.isNotEmpty || _existingResolution.isNotEmpty;

  Future<void> _submit() async {
    final reportId = _asInt(widget.report['id']);
    if (reportId == null) return;
    if (!_hasAfterPhoto) {
      setState(
        () => _error =
            'Vui lòng chụp ít nhất 1 ảnh sau khi sửa xong để nghiệm thu.',
      );
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      // Upload hết ảnh trước — lỗi mạng thì phiếu chưa bị thay đổi gì.
      final inspection = _existingInspection.isEmpty && !_inspectionSaved
          ? await _beforePhotos.uploadAll()
          : const <Map<String, dynamic>>[];
      final resolution = await _afterPhotos.uploadAll();

      if (inspection.isNotEmpty) {
        await widget.service.addReportAttachments(
          reportId,
          ReportStage.inspection,
          inspection,
        );
        _inspectionSaved = true;
      }

      // Ảnh RESOLUTION + ghi chú đi cùng lệnh Hoàn tất (1 request).
      final noteText = _noteCtrl.text.trim();
      await widget.service.resolveReport(
        reportId,
        note: noteText.isEmpty ? null : noteText,
        attachments: resolution,
      );

      if (mounted) {
        // Đóng phiếu ⇒ server trả tài sản của phiếu về hoạt động.
        final restored = switch (widget.report['category']) {
          'LANDING_PAD' => 'Bãi đáp đã hoạt động lại.',
          'LOCKER' => 'Tủ đã hoạt động lại.',
          _ => 'Ô tủ đã hoạt động lại.',
        };
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF16A34A),
            content: Text('Đã nghiệm thu và hoàn tất sự cố! $restored'),
          ),
        );
      }
      await widget.onResolved();
    } catch (e) {
      if (mounted) {
        setState(() => _error = LockerOpsService.errorMessage(e));
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Widget _buildPhotoSection({
    required String title,
    required String subtitle,
    required bool satisfied,
    required Widget child,
    bool required = false,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: opsSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: satisfied ? const Color(0xFF16A34A) : opsBorder,
          width: satisfied ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                satisfied ? Icons.check_circle : Icons.camera_alt_outlined,
                size: 16,
                color: satisfied ? const Color(0xFF16A34A) : opsMutedText,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.bold,
                    color: satisfied ? const Color(0xFF16A34A) : opsDark,
                  ),
                ),
              ),
              if (required && !satisfied)
                const Text(
                  'Bắt buộc',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFDC2626),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 11, color: opsMutedText),
          ),
          const SizedBox(height: 8),
          child,
        ],
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
    final uploading = _beforePhotos.isUploading || _afterPhotos.isUploading;
    final hasBefore = _existingInspection.isNotEmpty ||
        _beforePhotos.isNotEmpty ||
        _inspectionSaved;

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
                          '$lockerLabel${boxLabel != null ? ' · Ô $boxLabel' : ''} · #$reportTitle',
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
              _buildPhotoSection(
                title: 'Trước khi sửa',
                subtitle: _existingInspection.isNotEmpty
                    ? 'Đã xác nhận hiện trường (${_existingInspection.length} ảnh)'
                    : 'Tuỳ chọn · lưu thành ảnh xác nhận hiện trường',
                satisfied: hasBefore,
                child: _existingInspection.isNotEmpty
                    ? AttachmentStrip(
                        attachments: _existingInspection,
                        viewerTitle: ReportStage.label(ReportStage.inspection),
                      )
                    : PhotoPickerField(
                        controller: _beforePhotos,
                        enabled: !_submitting && !_inspectionSaved,
                        accentColor: opsPrimary,
                        addLabel: 'Chụp ảnh',
                      ),
              ),
              const SizedBox(height: 10),
              _buildPhotoSection(
                title: 'Sau khi xong',
                subtitle: 'Ảnh nghiệm thu — cần ít nhất 1 ảnh',
                satisfied: _hasAfterPhoto,
                required: true,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_existingResolution.isNotEmpty) ...[
                      AttachmentStrip(
                        attachments: _existingResolution,
                        viewerTitle: ReportStage.label(ReportStage.resolution),
                      ),
                      const SizedBox(height: 8),
                    ],
                    PhotoPickerField(
                      controller: _afterPhotos,
                      enabled: !_submitting,
                      accentColor: const Color(0xFF16A34A),
                      addLabel: 'Chụp ảnh',
                    ),
                  ],
                ),
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
              if (_error != null) ...[
                const SizedBox(height: 12),
                OpsBanner(
                  tone: OpsBannerTone.danger,
                  icon: Icons.error_outline,
                  text: _error!,
                ),
              ],
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
                        ? (uploading
                            ? 'Đang tải ảnh...'
                            : 'Đang lưu nghiệm thu...')
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

/// Sheet "Xác nhận hiện trường": KTV tới nơi chụp ảnh INSPECTION (+ ghi chú)
/// trước khi bắt tay vào sửa. Có ghi chú ⇒ backend tạo 1 dòng nhật ký gắn ảnh.
class _InspectionSheet extends StatefulWidget {
  const _InspectionSheet({
    required this.reportId,
    required this.title,
    required this.service,
  });

  final int reportId;
  final String title;
  final LockerOpsService service;

  @override
  State<_InspectionSheet> createState() => _InspectionSheetState();
}

class _InspectionSheetState extends State<_InspectionSheet> {
  static const _accent = Color(0xFFD97706);

  final _noteCtrl = TextEditingController();
  final _photos = PhotoPickerController(maxPhotos: _staffPhotosPerRequest);
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _photos.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_photos.isEmpty) {
      setState(() => _error = 'Vui lòng chụp ít nhất 1 ảnh hiện trường.');
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final attachments = await _photos.uploadAll();
      await widget.service.addReportAttachments(
        widget.reportId,
        ReportStage.inspection,
        attachments,
        note: _noteCtrl.text,
      );
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) setState(() => _error = LockerOpsService.errorMessage(e));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
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
                      color: _accent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.fact_check_outlined,
                        color: _accent, size: 22),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Xác nhận hiện trường',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        Text(
                          widget.title,
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
              const SizedBox(height: 12),
              const Text(
                'Chụp hiện trạng ô tủ ngay khi tới nơi (cửa, khoá, bo mạch...). '
                'Ảnh được lưu vào phiếu làm bằng chứng trước khi sửa.',
                style: TextStyle(fontSize: 12, color: opsMutedText),
              ),
              const SizedBox(height: 12),
              PhotoPickerField(
                controller: _photos,
                enabled: !_submitting,
                thumbSize: 80,
                accentColor: _accent,
                addLabel: 'Chụp ảnh',
                helperText: 'Tối đa ${_photos.maxPhotos} ảnh',
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _noteCtrl,
                enabled: !_submitting,
                minLines: 1,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Ghi chú hiện trạng (tuỳ chọn)...',
                  isDense: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: opsBorder),
                  ),
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                OpsBanner(
                  tone: OpsBannerTone.danger,
                  icon: Icons.error_outline,
                  text: _error!,
                ),
              ],
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _submitting ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _accent,
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
                      : const Icon(Icons.cloud_upload_outlined),
                  label: Text(
                    _submitting ? 'Đang tải ảnh...' : 'Lưu ảnh hiện trường',
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
  'DRONE' => 'Ô Kiosk',
  'XL' => 'XL',
  'STANDARD' => 'Chuẩn',
  null => 'Chuẩn',
  _ => type,
};

/// Pill nhỏ trong banner tổng quan sự cố của tab "Sự cố" (Queue).
class _QueueStatChip extends StatelessWidget {
  const _QueueStatChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
          color: color.withValues(alpha: 1.0),
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    required this.color,
    this.icon,
    this.highlight = false,
  });

  final String label;
  final String value;
  final Color color;
  final IconData? icon;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      decoration: BoxDecoration(
        color: highlight
            ? color.withValues(alpha: 0.15)
            : color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: highlight ? color : color.withValues(alpha: 0.2),
          width: highlight ? 1.6 : 1.0,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16, color: color),
            const SizedBox(height: 2),
          ],
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 10.5,
              color: highlight ? color : const Color(0xFF475569),
              fontWeight: FontWeight.w700,
              height: 1.15,
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

class _SlaCountdownBadge extends StatefulWidget {
  final DateTime? dueAt;
  final DateTime? createdAt;
  final int slaHours;
  final String status;
  final bool isExtended;
  final int? extendedHours;

  const _SlaCountdownBadge({
    required this.dueAt,
    this.createdAt,
    this.slaHours = 4,
    required this.status,
    this.isExtended = false,
    this.extendedHours,
  });

  @override
  State<_SlaCountdownBadge> createState() => _SlaCountdownBadgeState();
}

class _SlaCountdownBadgeState extends State<_SlaCountdownBadge> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    if (widget.status != 'RESOLVED') {
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) setState(() {});
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.status == 'RESOLVED') return const SizedBox.shrink();

    DateTime? targetTime = widget.dueAt;
    if (targetTime == null && widget.createdAt != null) {
      targetTime = widget.createdAt!.add(Duration(hours: widget.slaHours));
    }
    if (targetTime == null) return const SizedBox.shrink();

    final now = DateTime.now();
    final diff = targetTime.difference(now);

    String pad(int n) => n.toString().padLeft(2, '0');

    if (!diff.isNegative) {
      final h = diff.inHours;
      final m = diff.inMinutes.remainder(60);
      final s = diff.inSeconds.remainder(60);
      final isExt = widget.isExtended && (widget.extendedHours ?? 0) > 0;

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
        decoration: BoxDecoration(
          color: isExt ? const Color(0xFFFFFBEB) : const Color(0xFFECFDF5),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isExt ? const Color(0xFFFDE68A) : const Color(0xFFA7F3D0),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isExt ? Icons.update : Icons.timer_outlined,
              size: 12,
              color: isExt ? const Color(0xFFB45309) : const Color(0xFF059669),
            ),
            const SizedBox(width: 3.5),
            Text(
              isExt
                  ? 'Còn ${pad(h)}:${pad(m)}:${pad(s)} (+${widget.extendedHours}h)'
                  : 'Còn ${pad(h)}:${pad(m)}:${pad(s)}',
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: isExt ? const Color(0xFFB45309) : const Color(0xFF059669),
              ),
            ),
          ],
        ),
      );
    } else {
      final absDiff = diff.abs();
      final h = absDiff.inHours;
      final m = absDiff.inMinutes.remainder(60);
      final s = absDiff.inSeconds.remainder(60);
      final isExt = widget.isExtended && (widget.extendedHours ?? 0) > 0;

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
        decoration: BoxDecoration(
          color: const Color(0xFFFEF2F2),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: const Color(0xFFFCA5A5)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.warning_amber_rounded, size: 12, color: Color(0xFFDC2626)),
            const SizedBox(width: 3.5),
            Text(
              isExt
                  ? 'Quá hạn ${pad(h)}:${pad(m)}:${pad(s)} (Sau gia hạn)'
                  : 'Quá hạn ${pad(h)}:${pad(m)}:${pad(s)}',
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Color(0xFFDC2626),
              ),
            ),
          ],
        ),
      );
    }
  }
}
