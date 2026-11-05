import 'dart:async';
import 'dart:convert';

import 'package:smart_laundry_locker/core/utils/app_date_time.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_laundry_locker/core/config/business_config_service.dart';
import 'package:smart_laundry_locker/core/routing/app_router.dart';
import 'package:smart_laundry_locker/core/services/session_service.dart';
import 'package:smart_laundry_locker/core/services/token_service.dart';
import 'package:smart_laundry_locker/core/services/app_event_bus.dart';
import 'package:smart_laundry_locker/features/assistant/presentation/widgets/assistant_entry.dart';
import 'package:smart_laundry_locker/features/drone_delivery/domain/entities/drone_delivery_stage.dart';
import 'package:smart_laundry_locker/features/drone_delivery/domain/entities/drone_delivery_status.dart';
import 'package:smart_laundry_locker/features/drone_delivery/domain/entities/drone_booking.dart';
import 'package:smart_laundry_locker/features/drone_delivery/presentation/widgets/drone_weather_panel.dart';
import 'package:smart_laundry_locker/features/drone_delivery/domain/entities/drone_labels.dart';
import 'package:smart_laundry_locker/features/drone_delivery/presentation/widgets/drone_pickup_queue.dart';
import 'package:smart_laundry_locker/features/drone_delivery/domain/entities/drone_parcel.dart';
import 'package:smart_laundry_locker/features/drone_delivery/infrastructure/models/drone_delivery_response.dart';
import 'package:smart_laundry_locker/features/drone_delivery/presentation/widgets/drone_delivery_detail.dart';
import 'package:smart_laundry_locker/features/locker_ops/data/drone_technician_errors.dart';
import 'package:smart_laundry_locker/features/locker_ops/data/locker_ops_service.dart';
import 'package:smart_laundry_locker/features/locker_ops/presentation/utils/technician_session.dart';
import 'package:smart_laundry_locker/features/locker_ops/presentation/widgets/ops_widgets.dart';
import 'package:smart_laundry_locker/features/locker_ops/presentation/widgets/complete_inspection_sheet.dart';
import 'package:smart_laundry_locker/features/locker_ops/presentation/widgets/schedule_detail_modal_sheet.dart';
import 'package:smart_laundry_locker/features/locker_ops/presentation/pages/technician_profile_page.dart';
import 'package:smart_laundry_locker/features/locker_ops/presentation/widgets/technician_shift_card.dart';
import 'package:smart_laundry_locker/features/locker_ops/presentation/widgets/technician_location_permission_sheet.dart';
import 'package:smart_laundry_locker/features/maintenance/presentation/widgets/drone_report_detail_sheet.dart';
import 'package:smart_laundry_locker/features/maintenance/presentation/widgets/drone_journey_camera_panel.dart';
import 'package:smart_laundry_locker/features/maintenance/presentation/widgets/drone_parcel_incident_card.dart';
import 'package:smart_laundry_locker/features/profile/presentation/providers/profile_provider.dart';
import 'package:provider/provider.dart';
import 'package:smart_laundry_locker/shared/widgets/controller_disposer.dart';
import 'package:smart_laundry_locker/shared/widgets/user_ui_kit.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:smart_laundry_locker/core/l10n/l10n.dart';

/// Hai danh sách đơn drone (JSON từ server) có giống hệt nhau không — poll dùng để bỏ qua
/// lượt không đổi. Trước đây chỉ so `id` (server trả `orderId`, nên luôn null), chặng,
/// trạng thái và `updatedAt` của đơn; xác nhận nạp hàng chỉ đổi `missionStatus`
/// (AWAITING_LOADING → READY_TO_LAUNCH) nên poll coi như "không đổi" và thẻ kẹt ở nút
/// "Xác nhận nạp" tới khi tải lại cả trang (test 2026-11-05).
@visibleForTesting
bool droneDeliveriesEqual(
  List<Map<String, dynamic>> a,
  List<Map<String, dynamic>> b,
) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;
  try {
    return jsonEncode(a) == jsonEncode(b);
  } catch (_) {
    return false;
  }
}

/// Home for the DRONE_TECHNICIAN role (kỹ thuật viên drone): drone fleet only
/// (delivery dispatch queue from the backend, fleet status/battery, mission
/// planner, flight data, drone maintenance schedules). Physical locker
/// maintenance lives with the LOCKER_TECHNICIAN role.
class MaintenanceHomePage extends StatefulWidget {
  const MaintenanceHomePage({
    super.key,
    this.service,
    this.initialTab = 0,
    this.reportId,
    this.scheduleId,
    this.orderId,
  });

  final LockerOpsService? service;

  /// Deep link (thông báo/push): tab mở sẵn — thứ tự `maintenanceTabs` trong
  /// role_routes — và phiếu / lịch / đơn cần mở chi tiết sau khi tải xong.
  final int initialTab;
  final int? reportId;
  final int? scheduleId;
  final int? orderId;

  @override
  State<MaintenanceHomePage> createState() => _MaintenanceHomePageState();
}

class _MaintenanceHomePageState extends State<MaintenanceHomePage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(
    length: 6,
    vsync: this,
    initialIndex: widget.initialTab.clamp(0, 5),
  );
  late final LockerOpsService _service = widget.service ?? LockerOpsService();

  List<Map<String, dynamic>> _drones = [];
  // Hàng đợi order-based cho đội bay theo Phase 2.
  List<Map<String, dynamic>> _deliveries = [];
  // lockerId → lý do trạm đang không bay được (thời tiết / admin tạm dừng), từ
  // danh sách thời tiết các tủ. Dùng để khoá trước nút Tiếp nhận / Phóng; server
  // vẫn kiểm tra lại tuyến bay lúc bấm.
  Map<int, String> _groundedStations = const {};
  int _loadGeneration = 0;
  DateTime _stationWeatherAt = DateTime.now();
  // Chỉ chứa phiếu category=DRONE, lấy qua API riêng cho DRONE_TECHNICIAN.
  List<Map<String, dynamic>> _droneReports = [];
  List<Map<String, dynamic>> _myDroneReports = [];
  List<Map<String, dynamic>> _routedDroneReports = [];
  String? _droneReportLoadError;
  String? _dronesLoadError;
  String? _deliveriesLoadError;
  // Sự cố rơi kiện (`/api/drone-technician/drone-incidents`). Máy chủ chưa có
  // endpoint ⇒ hiện đơn ở chặng DROP_REPORTED thay thế.
  List<Map<String, dynamic>> _incidents = [];
  List<Map<String, dynamic>> _dropReportedOrders = [];
  String? _incidentsLoadError;
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
  String _scheduleDueFilter = 'ALL';
  String _schedulePriorityFilter = 'ALL';
  String _scheduleSort = 'DUE';
  final _scheduleSearchController = TextEditingController();

  /// Lần tải đầu (chưa có dữ liệu nào) mới che cả màn bằng vòng quay; các lần
  /// tải lại giữ nguyên giao diện 6 tab và chỉ hiện thanh tiến trình mảnh.
  bool _loading = true;
  bool _refreshing = false;
  Future<void>? _loadInFlight;

  /// Trạng thái "Vào ca" (online làm việc) từ thẻ ca; null = chưa tải xong. Khác công tắc
  /// nhận việc lấy hàng trong [DronePickupQueue].
  bool? _shiftOnDuty;
  String? _myUserId;
  String? _myUserName;
  String? _myUserEmail;
  Map<String, dynamic>? _ratingAverage;
  // `my-performance` của KTV drone: totalAssigned, inProgress, resolved,
  // overdue, penaltyLevel, penaltyReason, averageRating, ratingCount.
  Map<String, dynamic>? _performance;
  String? _performanceLoadError;
  bool _loggingOut = false;
  String _dispatchFilter = 'ALL';
  Timer? _deliveryRefreshTimer;
  StreamSubscription<AppEvent>? _eventSubscription;
  // Mỗi (thao tác, đơn) giữ một Idempotency-Key tới khi server xác nhận thành
  // công — bấm lại sau lỗi mạng không tạo thao tác trùng.
  final Map<String, String> _idempotencyKeys = {};
  // Đơn đang có thao tác gửi lên server: khoá các nút của đơn đó.
  final Set<int> _busyOrders = {};
  bool _deepLinkHandled = false;

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

  /// Drone mà KTV này trực tiếp phụ trách.
  List<Map<String, dynamic>> get _myDrones => _drones
      .where(
        (drone) =>
            _myUserId != null &&
            _myUserId!.isNotEmpty &&
            drone['assignedTechnicianId'] != null &&
            '${drone['assignedTechnicianId']}' == _myUserId,
      )
      .toList(growable: false);

  /// Drone đang hoạt động chưa có KTV nào phụ trách — KTV mở để "Nhận xử lý".
  List<Map<String, dynamic>> get _unassignedDrones => _drones
      .where(
        (drone) =>
            drone['assignedTechnicianId'] == null && drone['active'] != false,
      )
      .toList(growable: false);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      TechnicianLocationPermissionSheet.checkAndPrompt(context);
      try {
        final profileProvider = context.read<ProfileProvider>();
        if (profileProvider.profile == null) profileProvider.loadProfile();
      } catch (_) {}
    });
    _load();
    // Watchdog định kỳ 20 giây (thay vì 3s làm nháy màn hình), kèm EventBus tức thời
    _deliveryRefreshTimer = Timer.periodic(
      const Duration(seconds: 20),
      (_) => _refreshDeliveries(),
    );
    _eventSubscription = AppEventBus.instance.events.listen((event) {
      if (!mounted) return;
      if (event is OrderChangedEvent) _refreshDeliveries();
      if (event is ReportUpdatedEvent) _load();
      if (event is MaintenanceChangedEvent) _onMaintenanceChanged(event);
    });
  }

  /// Việc của đội bay đổi do KTV khác, admin, khách hay hệ thống: chỉ tải lại
  /// đúng mục bị ảnh hưởng. Gom các tin dồn dập (chặng giao DEMO đổi mỗi vài
  /// giây) rồi mới tải.
  final Set<String> _pendingSections = {};
  Timer? _sectionDebounce;

  void _onMaintenanceChanged(MaintenanceChangedEvent event) {
    if (event.isDroneOrder) _pendingSections.add('deliveries');
    if (event.isDrone) _pendingSections.add('drones');
    if (event.isReport) _pendingSections.add('reports');
    if (event.isSchedule) _pendingSections.add('schedules');
    if (event.isDroneIncident) _pendingSections.add('incidents');
    if (_pendingSections.isEmpty) return;
    _sectionDebounce?.cancel();
    _sectionDebounce = Timer(const Duration(milliseconds: 1200), () {
      if (!mounted) return;
      final sections = Set<String>.of(_pendingSections);
      _pendingSections.clear();
      if (sections.contains('deliveries')) _refreshDeliveries();
      if (sections.contains('drones')) _loadDrones();
      if (sections.contains('reports')) {
        _loadDroneReports();
        _loadPerformance();
      }
      if (sections.contains('schedules')) _loadSchedules();
      if (sections.contains('incidents')) _loadIncidents();
    });
  }

  @override
  void didUpdateWidget(covariant MaintenanceHomePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Bấm thông báo khi trang đang mở: cùng route, tham số mới.
    final changed =
        oldWidget.initialTab != widget.initialTab ||
        oldWidget.reportId != widget.reportId ||
        oldWidget.scheduleId != widget.scheduleId ||
        oldWidget.orderId != widget.orderId;
    if (!changed) return;
    _tabs.animateTo(widget.initialTab.clamp(0, 5));
    _deepLinkHandled = false;
    unawaited(_load());
  }

  @override
  void dispose() {
    _tabs.dispose();
    _deliveryRefreshTimer?.cancel();
    _sectionDebounce?.cancel();
    _eventSubscription?.cancel();
    _droneReportSearchController.dispose();
    _myWorkSearchController.dispose();
    _scheduleSearchController.dispose();
    super.dispose();
  }

  /// Số thứ tự lượt đọc danh sách đơn: lượt đọc cũ về sau lượt mới (poll chạy song song với
  /// tải lại sau thao tác) thì bỏ, không ghi đè dữ liệu mới bằng dữ liệu trước thao tác.
  int _deliveriesFetchSeq = 0;
  int _deliveriesAppliedSeq = 0;

  bool _acceptDeliveriesFetch(int seq) {
    if (seq < _deliveriesAppliedSeq) return false;
    _deliveriesAppliedSeq = seq;
    return true;
  }

  /// Ghép kết quả thao tác (vd. DroneMissionResponse của xác nhận nạp) vào đơn đang hiện
  /// để nút đổi ngay, không chờ lượt tải lại.
  void _mergeDeliveryResult(int orderId, Map<String, dynamic> result) {
    const keys = {
      'missionStatus',
      'deliveryStage',
      'paymentStatus',
      'weightSurcharge',
      'sealCode',
      'payloadWeightGrams',
      'loadedAt',
      'readyToLaunchAt',
    };
    final patch = {
      for (final key in keys)
        if (result[key] != null) key: result[key],
    };
    if (patch.isEmpty || !mounted) return;
    setState(() {
      _deliveries = [
        for (final order in _deliveries)
          _asInt(order['orderId']) == orderId ? {...order, ...patch} : order,
      ];
    });
  }

  Future<void> _refreshDeliveries() async {
    final seq = ++_deliveriesFetchSeq;
    try {
      final deliveries = await _service.droneOrderQueue();
      if (!mounted || !_acceptDeliveriesFetch(seq)) return;
      // Thời tiết / lệnh dừng trạm đổi chậm: làm mới mỗi phút, không theo từng nhịp poll.
      if (DateTime.now().difference(_stationWeatherAt) >=
          const Duration(minutes: 1)) {
        _stationWeatherAt = DateTime.now();
        setState(() => _loadGeneration++);
      }
      // Chỉ cập nhật state khi danh sách đơn thực sự thay đổi để tránh nháy màn hình
      if (!droneDeliveriesEqual(_deliveries, deliveries)) {
        setState(() {
          _deliveries = deliveries;
          _deliveriesLoadError = null;
        });
        // Đơn đổi chặng thì drone cũng đổi trạng thái (giữ chỗ → đang bay → sẵn sàng);
        // không tải lại thì tab Đội bay còn "Đang bay" khi kiện đã vào tủ (test 2026-11-02).
        unawaited(_loadDrones());
      }
    } catch (_) {
      // Giữ dữ liệu cuối cùng khi mất mạng; lần poll sau sẽ thử lại.
    }
  }

  Future<void>? _loadQueued;

  /// Tải lại toàn bộ. Gọi khi đang có lượt tải thì xếp MỘT lượt nữa chạy sau lượt đó (các
  /// lời gọi chồng nhau dùng chung lượt xếp hàng): lượt đang chạy có thể đã đọc dữ liệu từ
  /// trước thao tác vừa xong (vd. xác nhận nạp), dùng lại nó thì màn hình hiện trạng thái cũ.
  Future<void> _load() {
    final running = _loadInFlight;
    if (running == null) {
      return _loadInFlight = _loadAll().whenComplete(
        () => _loadInFlight = null,
      );
    }
    return _loadQueued ??= running.catchError((_) {}).then((_) {
      _loadQueued = null;
      return _load();
    });
  }

  Future<void> _loadAll() async {
    if (mounted) {
      setState(() {
        _refreshing = true;
        _loadGeneration++;
      });
      _stationWeatherAt = DateTime.now();
    }
    try {
      _myUserId = await TokenService.getUserId();
      _myUserName = await TokenService.getUserName();
      _myUserEmail = await TokenService.getUserEmail();
      // Mỗi phần tự bắt lỗi của mình để một API lỗi không xoá các phần khác.
      await Future.wait<void>([
        _loadDrones(),
        _loadDeliveries(),
        _loadSchedules(),
        _loadDroneReports(),
        _loadIncidents(),
        _loadPerformance(),
      ]);
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
          _refreshing = false;
        });
        _applyDeepLinkOnce();
      }
    }
  }

  Future<void> _loadDrones() async {
    try {
      final drones = await _service.droneUnits();
      if (!mounted) return;
      setState(() {
        _drones = drones;
        _dronesLoadError = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(
        () => _dronesLoadError =
            context.l10n.dtLoadDronesFailed(droneTechnicianErrorMessage(e)),
      );
    }
  }

  Future<void> _loadDeliveries() async {
    final seq = ++_deliveriesFetchSeq;
    try {
      final deliveries = await _service.droneOrderQueue();
      if (!mounted || !_acceptDeliveriesFetch(seq)) return;
      setState(() {
        _deliveries = deliveries;
        _deliveriesLoadError = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(
        () => _deliveriesLoadError =
            context.l10n.dtLoadDeliveriesFailed(droneTechnicianErrorMessage(e)),
      );
    }
  }

  Future<void> _loadSchedules() async {
    try {
      final schedules = await _service.maintenanceSchedules(
        mine: true,
        target: 'DRONE',
      );
      if (!mounted) return;
      setState(() {
        _schedules = schedules
            .where((s) => s['droneUnitId'] != null && _isScheduleMine(s))
            .toList(growable: false);
        _scheduleLoadError = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(
        () => _scheduleLoadError =
            context.l10n.dtLoadSchedulesFailed(LockerOpsService.errorMessage(e)),
      );
    }
  }

  Future<void> _loadIncidents() async {
    Object failure;
    try {
      final incidents = await _service.droneIncidents();
      if (!mounted) return;
      setState(() {
        _incidents = incidents;
        _dropReportedOrders = const [];
        _incidentsLoadError = null;
      });
      return;
    } catch (e) {
      failure = e;
    }
    if (isEndpointMissing(failure)) {
      // Máy chủ chưa có danh sách sự cố cho KTV drone: đơn đã báo rơi kiện vẫn
      // lọc được theo chặng DROP_REPORTED.
      try {
        final orders = await _service.droneOrderQueue(
          deliveryStage: _dropReportedStage,
        );
        if (!mounted) return;
        setState(() {
          _incidents = const [];
          _dropReportedOrders = orders;
          _incidentsLoadError = null;
        });
        return;
      } catch (e) {
        failure = e;
      }
    }
    if (!mounted) return;
    setState(
      () => _incidentsLoadError =
          context.l10n.dtLoadIncidentsFailed(droneTechnicianErrorMessage(failure)),
    );
  }

  Future<void> _loadPerformance() async {
    Map<String, dynamic>? performance;
    String? error;
    try {
      performance = await _service.droneMyPerformance();
    } catch (e) {
      error = droneTechnicianErrorMessage(
        e,
        unsupported: L10n.current.dtPerformanceUnsupported,
      );
    }
    Map<String, dynamic>? rating;
    try {
      rating = await _service.droneMyRatingAverage();
    } catch (_) {
      // Không có điểm đánh giá ⇒ hiện "chưa tải được", không bịa điểm.
    }
    if (!mounted) return;
    setState(() {
      if (performance != null) _performance = performance;
      _performanceLoadError = error;
      if (rating != null) _ratingAverage = rating;
    });
  }

  /// ID của KTV phụ trách drone liên quan đến phiếu sự cố hoặc sự cố rơi kiện.
  /// Ưu tiên `routedToUserId` trên phiếu, nếu không có thì tra từ danh sách drone `_drones` theo ID hoặc mã drone.
  String? _droneAssignedTechnicianId(Map<String, dynamic> item) {
    final routed = item['routedToUserId']?.toString().trim();
    if (routed != null && routed.isNotEmpty && routed != 'null') {
      return routed;
    }
    final droneId = _asInt(item['droneUnitId']);
    final droneCode = item['droneCode']?.toString().trim();
    for (final d in _drones) {
      final matchesId = droneId != null && _asInt(d['id']) == droneId;
      final matchesCode = droneCode != null &&
          droneCode.isNotEmpty &&
          d['code']?.toString().trim() == droneCode;
      if (matchesId || matchesCode) {
        final techId = d['assignedTechnicianId']?.toString().trim();
        if (techId != null && techId.isNotEmpty && techId != 'null') {
          return techId;
        }
        break;
      }
    }
    return null;
  }

  /// Logic kiểm tra hiển thị sự cố cho KTV Drone:
  /// - Tab sự cố chỉ hiện sự cố mà mình được phân công (được ai nhận rồi thì chỉ hiển thị cho người đó).
  /// - Khi có sự cố mới:
  ///   + Drone đã có KTV phụ trách: CHỈ hiển thị cho KTV phụ trách drone đó xem và nhận việc.
  ///   + Drone chưa có KTV phụ trách: hiển thị cho tất cả KTV drone xem trong danh sách chờ nhận.
  bool _isDroneReportVisibleToMe(Map<String, dynamic> report) {
    final currentUserId = _myUserId;
    if (currentUserId == null || currentUserId.isEmpty) return false;

    final assignedTo = report['assignedToUserId']?.toString().trim();
    if (assignedTo != null && assignedTo.isNotEmpty && assignedTo != 'null') {
      return assignedTo == currentUserId;
    }

    // Sự cố mới (chưa có người nhận)
    final droneTech = _droneAssignedTechnicianId(report);
    if (droneTech != null) {
      return droneTech == currentUserId;
    }

    return true;
  }

  /// Logic kiểm tra hiển thị sự cố rơi kiện theo đúng phân công và phụ trách.
  bool _isIncidentVisibleToMe(Map<String, dynamic> incident) {
    final currentUserId = _myUserId;
    if (currentUserId == null || currentUserId.isEmpty) return false;

    // Đã có người nhận
    final assignedTo = (incident['recoveryAssignedToUserId'] ??
            incident['assignedToUserId'])
        ?.toString()
        .trim();
    if (assignedTo != null && assignedTo.isNotEmpty && assignedTo != 'null') {
      return assignedTo == currentUserId;
    }

    // Sự cố mới: chỉ hiện cho KTV phụ trách drone, hoặc mọi KTV nếu drone chưa có phụ trách
    final droneTech = _droneAssignedTechnicianId(incident);
    if (droneTech != null) {
      return droneTech == currentUserId;
    }

    return true;
  }

  bool _isDropReportedOrderVisibleToMe(Map<String, dynamic> order) {
    final currentUserId = _myUserId;
    if (currentUserId == null || currentUserId.isEmpty) return false;

    final assignedTo = (order['recoveryAssignedToUserId'] ??
            order['assignedByUserId'] ??
            order['assignedTechnicianId'])
        ?.toString()
        .trim();
    if (assignedTo != null && assignedTo.isNotEmpty && assignedTo != 'null') {
      return assignedTo == currentUserId;
    }

    final droneTech = _droneAssignedTechnicianId(order);
    if (droneTech != null) {
      return droneTech == currentUserId;
    }

    return true;
  }

  bool _incidentMatchesStatusFilter(Map<String, dynamic> incident) {
    final status = '${incident['status'] ?? ''}'.toUpperCase();
    final isResolved = status == 'RESOLVED' || status == 'CLOSED';
    final isOpen = status == 'REPORTED' ||
        status == 'EVIDENCE_PENDING' ||
        status == 'OPEN';
    return switch (_droneReportStatusFilter) {
      'OPEN' => isOpen,
      'IN_PROGRESS' => !isResolved && !isOpen,
      'RESOLVED' => isResolved,
      _ => !isResolved,
    };
  }

  bool _incidentMatchesSearch(Map<String, dynamic> incident, String query) {
    if (query.isEmpty) return true;
    final searchable = [
      incident['id'],
      incident['incidentCode'],
      incident['orderId'],
      incident['orderCode'],
      incident['droneCode'],
      incident['reason'],
      incident['description'],
      incident['status'],
    ].where((value) => value != null).join(' ').toLowerCase();
    return searchable.contains(query);
  }

  Future<void> _loadDroneReports() async {
    try {
      final reports = await _service.droneReports(all: true);
      final currentUserId = _myUserId;
      final visibleReports = reports
          .where(_isDroneReportVisibleToMe)
          .toList(growable: false);
      final mine = visibleReports
          .where(
            (report) =>
                currentUserId != null &&
                '${report['assignedToUserId']}' == currentUserId,
          )
          .toList(growable: false);
      // Chỉ phiếu sự cố mới trên drone mà mình phụ trách
      final routed = visibleReports
          .where(
            (report) =>
                report['status'] == 'OPEN' &&
                currentUserId != null &&
                _droneAssignedTechnicianId(report) == currentUserId,
          )
          .toList(growable: false);
      if (!mounted) return;
      setState(() {
        _droneReports = visibleReports;
        _myDroneReports = mine;
        _routedDroneReports = routed;
        _droneReportLoadError = null;
      });
    } catch (_) {
      // Nếu API tổng gặp lỗi riêng, vẫn thử API cá nhân để công việc đã được
      // phân công không biến mất hoàn toàn khỏi mobile.
      try {
        final mine = await _service.droneReports(mine: true);
        final visibleMine =
            mine.where(_isDroneReportVisibleToMe).toList(growable: false);
        if (!mounted) return;
        setState(() {
          _myDroneReports = visibleMine;
          _droneReports = visibleMine;
          _routedDroneReports = const [];
          _droneReportLoadError =
              context.l10n.dtSharedQueueFailedShowingMine;
        });
      } catch (_) {
        if (!mounted) return;
        setState(() {
          _droneReportLoadError =
              context.l10n.dtLoadReportsFailedPull;
        });
      }
    }
  }

  /// Mở chi tiết theo deep link một lần sau lần tải đầu (hoặc sau khi tham số
  /// deep link đổi).
  void _applyDeepLinkOnce() {
    if (_deepLinkHandled) return;
    _deepLinkHandled = true;
    final reportId = widget.reportId;
    final scheduleId = widget.scheduleId;
    final orderId = widget.orderId;
    if (reportId == null && scheduleId == null && orderId == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (reportId != null) {
        _openDroneReportById(reportId);
      } else if (scheduleId != null) {
        _openScheduleById(scheduleId);
      } else if (orderId != null) {
        _showDeliveryDetail(orderId);
      }
    });
  }

  void _openScheduleById(int scheduleId) {
    for (final schedule in _schedules) {
      if (_asInt(schedule['id']) == scheduleId) {
        _showDroneScheduleDetail(schedule);
        return;
      }
    }
    _showSnack(
      context.l10n.dtScheduleNotFound(scheduleId),
    );
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _logout() async {
    if (_loggingOut) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.logout_rounded, color: Color(0xFFDC2626)),
            SizedBox(width: 10),
            Text(context.l10n.dtLogoutShiftTitle),
          ],
        ),
        content: Text(context.l10n.dtLogoutShiftConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(context.l10n.commonCancel, style: const TextStyle(color: Colors.grey)),
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
            child: Text(context.l10n.commonLogout),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    ProfileProvider? profile;
    try {
      profile = context.read<ProfileProvider>();
    } catch (_) {}
    setState(() => _loggingOut = true);
    _deliveryRefreshTimer?.cancel();
    // Tắt ca (hộp xác nhận nói "kết thúc ca trực"), gỡ token push + thu hồi refresh token ở server rồi
    // mới xoá token trên máy.
    await endTechnicianShiftQuietly(service: _service, drone: true);
    await SessionService.logout();
    profile?.reset();
    if (mounted) context.go(AppRouter.onboarding);
  }

  /// Chạy 1 thao tác + báo kết quả + reload danh sách (giữ tên cũ để không
  /// đổi các flow drone gọi tới).
  Future<void> _runCellAction(
    Future<dynamic> Function() action,
    String successMsg,
  ) async {
    try {
      await action();
      _showSnack(successMsg);
      await _load();
    } catch (e) {
      _showSnack(droneTechnicianErrorMessage(e));
      // Trạng thái server có thể đã khác bản đang hiện (vd. drone vừa có phiếu).
      unawaited(_load());
    }
  }

  /// Thao tác trên một đơn drone: khoá các nút của đơn trong lúc gửi, giữ
  /// Idempotency-Key của (thao tác, đơn) tới khi thành công.
  Future<void> _runOrderAction(
    int orderId,
    String action,
    Future<Object?> Function() fn, {
    required String success,
    bool reloadOnError = false,
  }) async {
    if (_busyOrders.contains(orderId)) return;
    setState(() => _busyOrders.add(orderId));
    try {
      await fn();
      _idempotencyKeys.remove('$action-$orderId');
      _showSnack(success);
      await _load();
    } catch (e) {
      _showSnack(droneTechnicianErrorMessage(e));
      if (reloadOnError) await _load();
    } finally {
      if (mounted) {
        setState(() => _busyOrders.remove(orderId));
      } else {
        _busyOrders.remove(orderId);
      }
    }
  }

  /// Idempotency-Key ổn định cho (thao tác, đơn) — tạo một lần, xoá khi thành công.
  String _idempotencyKey(String action, int orderId) =>
      _idempotencyKeys.putIfAbsent(
        '$action-$orderId',
        () => '$action-$orderId-${DateTime.now().microsecondsSinceEpoch}',
      );

  bool _orderBusy(int? orderId) =>
      orderId != null && _busyOrders.contains(orderId);

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return context.l10n.dtGreetingMorning;
    if (hour < 14) return context.l10n.dtGreetingNoon;
    if (hour < 18) return context.l10n.dtGreetingAfternoon;
    return context.l10n.dtGreetingEvening;
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
    return context.l10n.dtDefaultName;
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
        resolvedName ?? profileName ?? _myUserName ?? context.l10n.dtDefaultName;
    // Chỉ hiện email thật của tài khoản; không có thì ẩn dòng email.
    final techEmail = profileEmail ?? _myUserEmail;
    final techPhone = profilePhone ?? context.l10n.techHomePhoneNotSet;
    // Số liệu lấy từ `my-performance` của KTV drone; chưa tải được thì hiện "—".
    final performance = _performance;
    String stat(String key) {
      final value = performance?[key];
      return value is num ? '${value.toInt()}' : '—';
    }

    final penalty = _penaltyInfo(performance?['penaltyLevel']);
    final penaltyReason = '${performance?['penaltyReason'] ?? ''}'.trim();

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
                    ],
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          techName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: opsDark,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          context.l10n.dtRoleFlightTeam,
                          style: TextStyle(
                            fontSize: 12.5,
                            color: opsMutedText,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (techEmail != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            techEmail,
                            style: const TextStyle(
                              fontSize: 12,
                              color: opsMutedText,
                            ),
                          ),
                        ],
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
                      context.l10n.dtStatReceived,
                      stat('totalAssigned'),
                      const Color(0xFF4F46E5),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _profileStatTile(
                      context.l10n.dtStatInProgress,
                      stat('inProgress'),
                      const Color(0xFF2563EB),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _profileStatTile(
                      context.l10n.dtStatDone,
                      stat('resolved'),
                      const Color(0xFF16A34A),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _profileStatTile(
                      context.l10n.dtStatOverdue,
                      stat('overdue'),
                      const Color(0xFFDC2626),
                    ),
                  ),
                ],
              ),
              if (performance == null && _performanceLoadError != null) ...[
                const SizedBox(height: 8),
                Text(
                  _performanceLoadError!,
                  style: const TextStyle(fontSize: 11.5, color: opsMutedText),
                ),
              ],
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
                        Text(
                          context.l10n.dtQualityRatingLabel,
                          style: TextStyle(fontSize: 13, color: opsDark),
                        ),
                        Flexible(
                          child: Text(
                            _ratingText(),
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: opsDark,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.verified_user_outlined,
                          color: penalty?.$2 ?? opsMutedText,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          context.l10n.dtSlaPolicyLabel,
                          style: TextStyle(fontSize: 13, color: opsDark),
                        ),
                        if (penalty != null)
                          _PenaltyBadge(label: penalty.$1, color: penalty.$2)
                        else
                          Text(
                            context.l10n.dtNoData,
                            style: TextStyle(fontSize: 12, color: opsMutedText),
                          ),
                      ],
                    ),
                    if (penaltyReason.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          penaltyReason,
                          style: const TextStyle(
                            fontSize: 11.5,
                            color: opsMutedText,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(
                          Icons.phone_outlined,
                          color: opsMutedText,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          context.l10n.dtTechPhoneLabel,
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
                      label: Text(
                        context.l10n.dtViewEditProfile,
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
                    label: Text(
                      context.l10n.commonLogout,
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

  /// "4.5/5 (12 lượt)" | "Chưa có đánh giá" | "Chưa tải được đánh giá".
  String _ratingText() {
    final source = _ratingAverage ?? _performance;
    if (source == null) return context.l10n.dtRatingLoadFailed;
    final count = _asInt(source['count'] ?? source['ratingCount']) ?? 0;
    if (count <= 0) return context.l10n.dtNoRatingYet;
    final average = source['average'] ?? source['averageRating'];
    final value = average is num ? average.toStringAsFixed(1) : '$average';
    return context.l10n.dtRatingValue(value, count);
  }

  /// Bậc chế tài SLA do server tính (`penaltyLevel` của my-performance).
  (String, Color)? _penaltyInfo(dynamic level) =>
      switch ('${level ?? ''}'.toUpperCase()) {
        'NORMAL' => (context.l10n.dtSlaNormal, const Color(0xFF16A34A)),
        'WARNING' => (context.l10n.dtSlaWarning, const Color(0xFFD97706)),
        'RESTRICTED' => (context.l10n.dtSlaRestricted, const Color(0xFFDC2626)),
        'SUSPENDED' => (context.l10n.dtSlaSuspended, const Color(0xFF991B1B)),
        _ => null,
      };

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
    final openIncidentsCount = _incidents
            .where(_isIncidentVisibleToMe)
            .where((i) {
              final s = '${i['status'] ?? ''}'.toUpperCase();
              return s == 'REPORTED' || s == 'EVIDENCE_PENDING' || s == 'OPEN';
            })
            .length +
        _dropReportedOrders.where(_isDropReportedOrderVisibleToMe).length;
    final waiting =
        _droneReports.where((r) => r['status'] == 'OPEN').length +
        openIncidentsCount;
    final working = _myDroneReports
        .where((r) => r['status'] == 'IN_PROGRESS')
        .length;
    final inFlight = _inFlightDeliveries.length;
    final displayName = _resolvedTechnicianName(context);
    // Bậc SLA do server tính (my-performance); chưa có thì không ghi "Bình thường".
    final headerPenalty = _penaltyInfo(_performance?['penaltyLevel']);
    final slaTextColor = switch ('${_performance?['penaltyLevel'] ?? ''}'
        .toUpperCase()) {
      'NORMAL' => const Color(0xFFA7F3D0),
      'WARNING' => const Color(0xFFFDE68A),
      'RESTRICTED' || 'SUSPENDED' => const Color(0xFFFCA5A5),
      _ => const Color(0xFFCBD5E1),
    };
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
                            Icon(
                              headerPenalty == null
                                  ? Icons.engineering_outlined
                                  : Icons.verified_rounded,
                              size: 14,
                              color: slaTextColor,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                [
                                  if (headerPenalty != null)
                                    context.l10n.dtHeaderSla(headerPenalty.$1),
                                  working > 0
                                      ? context.l10n.dtHeaderWorking(working)
                                      : context.l10n.dtHeaderNoWorking,
                                ].join(' · '),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: slaTextColor,
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
                  // Chỉ khi chính trang này được mở chồng lên trang khác. context.canPop()
                  // tính cả sheet / hộp thoại đang mở (vd. sheet quyền vị trí lúc mở app)
                  // nên từng hiện "Quay lại" bấm không tác dụng và mất nút Đăng xuất.
                  if (ModalRoute.of(context)?.impliesAppBarDismissal ?? false)
                    _droneHeaderAction(
                      Icons.arrow_back_rounded,
                      context.l10n.commonBack,
                      () => Navigator.of(context).maybePop(),
                    )
                  else ...[
                    AssistantEntryGate(
                      builder: (context) => Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: _droneHeaderAction(
                          Icons.support_agent_rounded,
                          context.l10n.dtAssistant,
                          () => context.push(AppRouter.assistant),
                        ),
                      ),
                    ),
                    _droneHeaderAction(
                      Icons.person_outline_rounded,
                      context.l10n.dtProfileAndEdit,
                      () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const TechnicianProfilePage(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    _droneHeaderAction(
                      Icons.logout_rounded,
                      context.l10n.commonLogout,
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
                      context.l10n.dtHudWaiting,
                      const Color(0xFFEF4444),
                      waiting > 0,
                      () => _selectDroneReportFilter('OPEN'),
                    ),
                    const SizedBox(width: 4),
                    _droneHudChip(
                      Icons.handyman_outlined,
                      '$working',
                      context.l10n.dtHudWorking,
                      const Color(0xFF38BDF8),
                      false,
                      () => _tabs.animateTo(3),
                    ),
                    const SizedBox(width: 4),
                    _droneHudChip(
                      Icons.event_repeat_outlined,
                      '${_schedules.length}',
                      context.l10n.dtHudRoutine,
                      const Color(0xFFA78BFA),
                      false,
                      () => _tabs.animateTo(4),
                    ),
                    const SizedBox(width: 4),
                    _droneHudChip(
                      Icons.flight_outlined,
                      '${_myDrones.length}',
                      context.l10n.dtHudFleet,
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
                    context.l10n.dtDronesInFlight(inFlight),
                    style: const TextStyle(
                      color: Color(0xFFBAE6FD),
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 10),
              TechnicianShiftCard(
                service: _service,
                isDrone: true,
                margin: EdgeInsets.zero,
                onPresenceChanged: (presence) {
                  final onDuty = presence['onDuty'] == true;
                  if (mounted && onDuty != _shiftOnDuty) {
                    setState(() => _shiftOnDuty = onDuty);
                  }
                  _refreshDeliveries();
                },
              ),
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
                Tab(text: context.l10n.dtTabDispatch(_dispatchCount)),
                Tab(text: context.l10n.dtTabFleet(_myDrones.length)),
                Tab(text: context.l10n.dtTabIncidents(_activeDroneReportCount)),
                Tab(text: context.l10n.dtTabMyWork(_activeMyWorkCount)),
                Tab(text: context.l10n.dtTabRoutine(_schedules.length)),
                Tab(text: context.l10n.dtTabFlightTools),
              ],
            ),
          ),
          // Tải lại không xoá giao diện: chỉ hiện thanh tiến trình mảnh.
          if (_refreshing && !_loading)
            const LinearProgressIndicator(
              minHeight: 2,
              color: Color(0xFF0077B6),
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
        .where(_shownInDispatch)
        .where(_matchesDispatchFilter)
        .toList();
    // Đơn lấy hàng tận nhà đi qua lời mời của hệ thống (DronePickupQueue bên dưới);
    // hàng chờ tiếp nhận chung chỉ còn dành cho đơn cũ khách tự mang kiện ra tủ.
    final awaiting = visibleDeliveries
        .where(
          (d) =>
              d['deliveryStage'] == 'AWAITING_DISPATCH' && d['pickup'] is! Map,
        )
        .toList(growable: false);
    final hasPickupWork = visibleDeliveries.any(
      (d) =>
          d['pickup'] is Map &&
          const {
            'OFFERED',
            'ACCEPTED',
            'PICKED_UP',
          }.contains('${(d['pickup'] as Map)['status']}'.toUpperCase()) &&
          const {
            'AWAITING_DISPATCH',
            'PICKUP_ASSIGNED',
            'PICKED_UP',
          }.contains('${d['deliveryStage']}'.toUpperCase()),
    );
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
    final canceled = visibleDeliveries
        .where(
          (delivery) =>
              delivery['parcelReturnPending'] != true &&
              _isCanceledDelivery(delivery),
        )
        .toList(growable: false);
    final otherAssignedWork = visibleDeliveries
        .where(
          (d) =>
              !_hasActivePickup(d) &&
              d['parcelReturnPending'] != true &&
              !_isCanceledDelivery(d) &&
              !_isKnownDispatchGroup(d),
        )
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
          DroneLockerWeatherList(
            load: _service.droneLockerWeather,
            onLoaded: _onStationWeather,
            refreshKey: _loadGeneration,
          ),
          DronePickupQueue(
            service: _service,
            deliveries: visibleDeliveries,
            shiftOnDuty: _shiftOnDuty,
            onChanged: _load,
            onOpenDetail: _showDeliveryDetail,
            onAssignDrone: _acceptFlow,
          ),
          _buildDispatchFilters(),
          const SizedBox(height: 8),
          if (_deliveriesLoadError != null) ...[
            OpsBanner(
              tone: OpsBannerTone.danger,
              icon: Icons.cloud_off_outlined,
              text: _deliveriesLoadError!,
            ),
            _retryButton(),
            const SizedBox(height: 8),
          ],
          // ── Đơn hàng drone order-based cho đội bay ───────────────────────
          if (parcelReturns.isNotEmpty) ...[
            OpsSectionLabel(
              context.l10n.dtSecParcelReturns(parcelReturns.length),
              icon: Icons.assignment_return_outlined,
            ),
            const SizedBox(height: 8),
            for (final order in parcelReturns) _parcelReturnCard(order),
            const SizedBox(height: 8),
          ],
          if (awaiting.isNotEmpty) ...[
            OpsSectionLabel(
              context.l10n.dtSecAwaitingDispatch(awaiting.length),
              icon: Icons.inbox_rounded,
            ),
            const SizedBox(height: 8),
            for (final order in awaiting)
              _deliveryCard(order, action: _DeliveryAction.accept),
            const SizedBox(height: 8),
          ],
          if (awaitingLoading.isNotEmpty) ...[
            OpsSectionLabel(
              context.l10n.dtSecAwaitingLoading(awaitingLoading.length),
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
              context.l10n.dtSecReadyToLaunch(readyToLaunch.length),
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
              context.l10n.dtSecLaunching(launching.length),
              icon: Icons.flight_takeoff,
            ),
            const SizedBox(height: 8),
            for (final order in launching)
              _deliveryCard(order, action: _DeliveryAction.launching),
            const SizedBox(height: 8),
          ],
          if (inFlight.isNotEmpty) ...[
            OpsSectionLabel(
              context.l10n.dtSecInFlight(inFlight.length),
              icon: Icons.flight,
            ),
            const SizedBox(height: 8),
            for (final order in inFlight)
              _deliveryCard(order, action: _DeliveryAction.track),
            const SizedBox(height: 8),
          ],
          if (delivered.isNotEmpty) ...[
            OpsSectionLabel(
              context.l10n.dtSecDelivered(delivered.length),
              icon: Icons.inventory_outlined,
            ),
            const SizedBox(height: 8),
            for (final order in delivered)
              _deliveryCard(order, action: _DeliveryAction.track),
            const SizedBox(height: 8),
          ],
          if (otherAssignedWork.isNotEmpty) ...[
            OpsSectionLabel(
              context.l10n.dtSecOtherAssigned(otherAssignedWork.length),
              icon: Icons.assignment_ind_outlined,
            ),
            const SizedBox(height: 8),
            for (final order in otherAssignedWork)
              _deliveryCard(order, action: _DeliveryAction.track),
            const SizedBox(height: 8),
          ],
          if (canceled.isNotEmpty) ...[
            OpsSectionLabel(
              context.l10n.dtSecCanceled(canceled.length),
              icon: Icons.cancel_outlined,
            ),
            const SizedBox(height: 8),
            for (final order in canceled)
              _deliveryCard(order, action: _DeliveryAction.track),
            const SizedBox(height: 8),
          ],
          if (awaiting.isNotEmpty ||
              parcelReturns.isNotEmpty ||
              awaitingLoading.isNotEmpty ||
              readyToLaunch.isNotEmpty ||
              launching.isNotEmpty ||
              inFlight.isNotEmpty ||
              delivered.isNotEmpty ||
              otherAssignedWork.isNotEmpty ||
              canceled.isNotEmpty) ...[
            const Divider(),
            const SizedBox(height: 8),
          ],

          if (awaiting.isEmpty &&
              !hasPickupWork &&
              parcelReturns.isEmpty &&
              _deliveriesLoadError == null &&
              awaitingLoading.isEmpty &&
              readyToLaunch.isEmpty &&
              launching.isEmpty &&
              inFlight.isEmpty &&
              delivered.isEmpty &&
              otherAssignedWork.isEmpty &&
              canceled.isEmpty)
            OpsEmptyState(
              icon: Icons.inbox_outlined,
              title: context.l10n.dtDispatchEmptyTitle,
              subtitle: context.l10n.dtDispatchEmptySubtitle,
            ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> get _activeIncidents =>
      _incidents
          .where(_isIncidentVisibleToMe)
          .where(droneIncidentActive)
          .toList(growable: false);

  String _pickupStatus(Map<String, dynamic> delivery) {
    final pickup = delivery['pickup'];
    return pickup is Map ? '${pickup['status']}'.toUpperCase() : '';
  }

  bool _hasActivePickup(Map<String, dynamic> delivery) => const {
    'OFFERED',
    'ACCEPTED',
    'PICKED_UP',
  }.contains(_pickupStatus(delivery));

  bool _isCanceledDelivery(Map<String, dynamic> delivery) {
    final status = '${delivery['status']}'.toUpperCase();
    final stage = '${delivery['deliveryStage']}'.toUpperCase();
    final mission = '${delivery['missionStatus']}'.toUpperCase();
    return status == 'CANCELED' ||
        stage == 'CANCELED' ||
        stage == 'FAILED' ||
        mission == 'CANCELED' ||
        mission == 'FAILED';
  }

  bool _isKnownDispatchGroup(Map<String, dynamic> delivery) {
    final stage = '${delivery['deliveryStage']}'.toUpperCase();
    final mission = '${delivery['missionStatus']}'.toUpperCase();
    if (stage == 'AWAITING_DISPATCH' && delivery['pickup'] is! Map) {
      return true;
    }
    if (stage == 'ACCEPTED' &&
        const {'AWAITING_LOADING', 'READY_TO_LAUNCH'}.contains(mission)) {
      return true;
    }
    return stage == 'LAUNCHING' ||
        stage == 'READY_FOR_PICKUP' ||
        _flightFailureStages.contains(stage);
  }

  /// Đơn có hiện trong một nhóm của tab Điều phối (bỏ qua bộ lọc chặng).
  bool _shownInDispatch(Map<String, dynamic> delivery) {
    if (delivery['parcelReturnPending'] == true) return true;
    if (_hasActivePickup(delivery) || _isCanceledDelivery(delivery)) {
      return true;
    }
    final stage = '${delivery['deliveryStage']}'.toUpperCase();
    final mission = '${delivery['missionStatus']}'.toUpperCase();
    if (stage == 'ACCEPTED') {
      return const {'AWAITING_LOADING', 'READY_TO_LAUNCH'}.contains(mission);
    }
    return stage == 'AWAITING_DISPATCH' ||
        stage == 'PICKUP_ASSIGNED' ||
        stage == 'PICKED_UP' ||
        stage == 'READY_FOR_PICKUP' ||
        _flightFailureStages.contains(stage);
  }

  /// Số mục tab Điều phối thật sự hiện: chỉ tính đơn hàng.
  int get _dispatchCount => _deliveries.where(_shownInDispatch).length;

  /// Phiếu sự cố chưa hoàn tất (gồm phiếu kỹ thuật drone và sự cố rơi kiện).
  int get _activeDroneReportCount =>
      _droneReports.where((r) => r['status'] != 'RESOLVED').length +
      _activeIncidents.length +
      _dropReportedOrders
          .where(_isDropReportedOrderVisibleToMe)
          .length;

  /// Việc của tôi còn phải làm: phiếu chưa hoàn tất + lịch chưa xong.
  int get _activeMyWorkCount =>
      _myDroneReports.where((r) => r['status'] != 'RESOLVED').length +
      _schedules
          .where(_isScheduleMine)
          .where((s) => !_myTaskIsDone((type: 'MAINTENANCE', data: s)))
          .length;

  bool _matchesDispatchFilter(Map<String, dynamic> delivery, [String? filter]) {
    switch (filter ?? _dispatchFilter) {
      case 'WAITING':
        return delivery['deliveryStage'] == 'AWAITING_DISPATCH' &&
            _pickupStatus(delivery) != 'ACCEPTED';
      case 'WORKING':
        return const {
              'ACCEPTED',
              'PICKED_UP',
            }.contains(_pickupStatus(delivery)) ||
            const {
              'PICKUP_ASSIGNED',
              'PICKED_UP',
              'ACCEPTED',
              'LAUNCHING',
            }.contains('${delivery['deliveryStage']}'.toUpperCase());
      case 'FLYING':
        return const {
          'DEPARTED',
          'EN_ROUTE',
          'APPROACHING',
          'ARRIVED',
        }.contains(delivery['deliveryStage']);
      case 'DONE':
        return delivery['deliveryStage'] == 'READY_FOR_PICKUP';
      case 'CANCELED':
        return _isCanceledDelivery(delivery);
      default:
        return true;
    }
  }

  Widget _buildDispatchFilters() {
    int count(String filter) {
      return _deliveries
          .where(_shownInDispatch)
          .where((delivery) => _matchesDispatchFilter(delivery, filter))
          .length;
    }

    final options = [
      ('ALL', context.l10n.dtFilterAllStatuses, Icons.filter_list_rounded, opsPrimary),
      ('WAITING', context.l10n.dtFilterWaiting, Icons.fiber_new_rounded, const Color(0xFFDC2626)),
      (
        'WORKING',
        context.l10n.dtFilterWorking,
        Icons.build_circle_outlined,
        const Color(0xFFD97706),
      ),
      ('FLYING', context.l10n.dtFilterFlying, Icons.flight_outlined, const Color(0xFF2563EB)),
      ('DONE', context.l10n.dtFilterDelivered, Icons.check_circle_outline, const Color(0xFF16A34A)),
      ('CANCELED', context.l10n.dtFilterCanceled, Icons.cancel_outlined, const Color(0xFF64748B)),
    ];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final option in options) ...[
            _droneFilterChip(
              label: context.l10n.dtFilterWithCount(option.$2, count(option.$1)),
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
    // Phiếu được định tuyến đích danh cho mình hiện thành nhóm riêng ở đầu
    // (chỉ khi không lọc trạng thái), không lặp lại trong hàng đợi chung.
    final showRouted =
        _routedDroneReports.isNotEmpty &&
        (_droneReportStatusFilter == 'ALL' || _droneReportStatusFilter == 'OPEN');
    final routedIds = showRouted
        ? _routedDroneReports.map((r) => '${r['id']}').toSet()
        : const <String>{};
    final reports = _droneReports.where((report) {
      if (routedIds.contains('${report['id']}')) return false;
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

    final visibleIncidents = _incidents
        .where(_isIncidentVisibleToMe)
        .where(_incidentMatchesStatusFilter)
        .where((i) => _incidentMatchesSearch(i, query))
        .where((i) {
          if (_droneReportDroneFilter == 'ALL') return true;
          final code = '${i['droneCode'] ?? i['droneUnitId'] ?? ''}';
          return code == _droneReportDroneFilter;
        })
        .where((i) {
          final assignedTo =
              (i['recoveryAssignedToUserId'] ?? i['assignedToUserId'])
                  ?.toString()
                  .trim();
          return switch (_droneReportAssignmentFilter) {
            'MINE' => assignedTo == _myUserId,
            'UNASSIGNED' => assignedTo == null ||
                assignedTo.isEmpty ||
                assignedTo == 'null',
            _ => true,
          };
        })
        .toList(growable: false);

    final visibleDropOrders = _dropReportedOrders
        .where(_isDropReportedOrderVisibleToMe)
        .where((o) =>
            _droneReportStatusFilter == 'ALL' ||
            _droneReportStatusFilter == 'OPEN')
        .where((o) => _incidentMatchesSearch(o, query))
        .where((o) {
          if (_droneReportDroneFilter == 'ALL') return true;
          final code = '${o['droneCode'] ?? o['droneUnitId'] ?? ''}';
          return code == _droneReportDroneFilter;
        })
        .where((o) {
          final assignedTo =
              (o['assignedByUserId'] ?? o['assignedTechnicianId'])
                  ?.toString()
                  .trim();
          return switch (_droneReportAssignmentFilter) {
            'MINE' => assignedTo == _myUserId,
            'UNASSIGNED' => assignedTo == null ||
                assignedTo.isEmpty ||
                assignedTo == 'null',
            _ => true,
          };
        })
        .toList(growable: false);

    final openIncidentCount = _incidents
            .where(_isIncidentVisibleToMe)
            .where((i) {
              final s = '${i['status'] ?? ''}'.toUpperCase();
              return s == 'REPORTED' || s == 'EVIDENCE_PENDING' || s == 'OPEN';
            })
            .length +
        _dropReportedOrders.where(_isDropReportedOrderVisibleToMe).length;
    final inProgressIncidentCount = _incidents
        .where(_isIncidentVisibleToMe)
        .where((i) {
          final s = '${i['status'] ?? ''}'.toUpperCase();
          return s != 'RESOLVED' &&
              s != 'CLOSED' &&
              s != 'REPORTED' &&
              s != 'EVIDENCE_PENDING' &&
              s != 'OPEN';
        })
        .length;
    final resolvedIncidentCount = _incidents
        .where(_isIncidentVisibleToMe)
        .where((i) {
          final s = '${i['status'] ?? ''}'.toUpperCase();
          return s == 'RESOLVED' || s == 'CLOSED';
        })
        .length;

    final openCount =
        _droneReports.where((r) => r['status'] == 'OPEN').length +
        openIncidentCount;
    final inProgressCount =
        _droneReports.where((r) => r['status'] == 'IN_PROGRESS').length +
        inProgressIncidentCount;
    final resolvedCount =
        _droneReports.where((r) => r['status'] == 'RESOLVED').length +
        resolvedIncidentCount;
    final totalCount = _droneReports.length +
        _incidents.where(_isIncidentVisibleToMe).length +
        _dropReportedOrders.where(_isDropReportedOrderVisibleToMe).length;

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
          ] else if (_incidentsLoadError != null) ...[
            OpsBanner(
              tone: OpsBannerTone.warning,
              icon: Icons.cloud_off_outlined,
              text: _incidentsLoadError!,
            ),
            _retryButton(),
          ] else
            OpsBanner(
              tone: openCount > 0 ? OpsBannerTone.warning : OpsBannerTone.info,
              icon: openCount > 0
                  ? Icons.warning_amber_rounded
                  : Icons.flight_outlined,
              text: openCount > 0
                  ? context.l10n.dtIncidentsWaitingBanner(openCount)
                  : context.l10n.dtIncidentsQueueBanner,
            ),
          const SizedBox(height: 10),
          _buildSearchField(
            controller: _droneReportSearchController,
            hint: context.l10n.dtReportSearchHint,
            onChanged: (_) => setState(() => _droneReportVisibleCount = 20),
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final option in [
                  ('ALL', context.l10n.commonAll, totalCount, Icons.filter_list),
                  ('OPEN', context.l10n.dtFilterWaiting, openCount, Icons.fiber_new_rounded),
                  (
                    'IN_PROGRESS',
                    context.l10n.dtFilterWorking,
                    inProgressCount,
                    Icons.build_circle_outlined,
                  ),
                  (
                    'RESOLVED',
                    context.l10n.dtFilterResolved,
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
                    label: Text(context.l10n.dtFilterWithCount(option.$2, option.$3)),
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
          if (visibleIncidents.any(droneIncidentNeedsManualReturn)) ...[
            const DroneManualReturnBanner(),
            const SizedBox(height: 8),
          ],
          if (visibleIncidents.isNotEmpty) ...[
            OpsSectionLabel(
              context.l10n.dtSecParcelDrop(visibleIncidents.length),
              icon: Icons.report_gmailerrorred_outlined,
            ),
            const SizedBox(height: 8),
            for (final incident in visibleIncidents)
              DroneParcelIncidentCard(
                incident: incident,
                onTap: () => DroneParcelIncidentSheet.show(
                  context,
                  incident: incident,
                  service: _service,
                ),
              ),
            const SizedBox(height: 12),
          ],
          if (visibleDropOrders.isNotEmpty) ...[
            OpsSectionLabel(
              context.l10n.dtSecParcelDrop(visibleDropOrders.length),
              icon: Icons.report_gmailerrorred_outlined,
            ),
            const SizedBox(height: 8),
            for (final order in visibleDropOrders)
              _deliveryCard(order, action: _DeliveryAction.track),
            const SizedBox(height: 12),
          ],
          if (showRouted) ...[
            OpsSectionLabel(
              context.l10n.dtSecRoutedToYou(_routedDroneReports.length),
              icon: Icons.assignment_ind_outlined,
            ),
            const SizedBox(height: 8),
            for (final report in _routedDroneReports) _droneReportCard(report),
            const SizedBox(height: 4),
            OpsSectionLabel(context.l10n.dtSecSharedQueue, icon: Icons.inbox_outlined),
            const SizedBox(height: 8),
          ] else if (visibleIncidents.isNotEmpty || visibleDropOrders.isNotEmpty) ...[
            if (reports.isNotEmpty) ...[
              OpsSectionLabel(
                context.l10n.dtSecDroneTechnical(reports.length),
                icon: Icons.build_circle_outlined,
              ),
              const SizedBox(height: 8),
            ],
          ],
          if (reports.isEmpty &&
              _droneReportLoadError == null &&
              !showRouted &&
              visibleIncidents.isEmpty &&
              visibleDropOrders.isEmpty)
            OpsEmptyState(
              icon: Icons.check_circle_outline,
              title: context.l10n.dtReportsEmptyTitle,
              subtitle: context.l10n.dtReportsEmptySubtitle,
            )
          else if (showRouted && reports.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                context.l10n.dtNoOtherInSharedQueue,
                style: const TextStyle(fontSize: 12, color: opsMutedText),
              ),
            )
          else
            for (final report in visibleReports) _droneReportCard(report),
          if (reports.length > visibleReports.length)
            Center(
              child: OutlinedButton.icon(
                onPressed: () => setState(() => _droneReportVisibleCount += 20),
                icon: const Icon(Icons.expand_more_rounded),
                label: Text(
                  context.l10n.dtSeeMore(reports.length - visibleReports.length),
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
                  context.l10n.dtMyWorkBanner,
            ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _workMetric(
                  context.l10n.dtMetricPending,
                  pendingCount,
                  const Color(0xFFEA580C),
                ),
              ),
              const SizedBox(width: 7),
              Expanded(
                child: _workMetric(
                  context.l10n.dtMetricWorking,
                  progressCount,
                  const Color(0xFF0284C7),
                ),
              ),
              const SizedBox(width: 7),
              Expanded(
                child: _workMetric(
                  context.l10n.dtMetricDone,
                  completedCount,
                  const Color(0xFF16A34A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _buildSearchField(
            controller: _myWorkSearchController,
            hint: context.l10n.dtMyWorkSearchHint,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final option in [
                  ('ALL', context.l10n.dtTypeAll),
                  ('INCIDENT', context.l10n.dtTypeIncident),
                  ('MAINTENANCE', context.l10n.dtTypeMaintenance),
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
                for (final option in [
                  ('ACTIVE', context.l10n.dtStatusActive),
                  ('DONE', context.l10n.dtStatusDone),
                  ('ALL', context.l10n.commonAll),
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
                  values: {'DUE': context.l10n.dtSortDue, 'NEWEST': context.l10n.dtSortNewest},
                  onSelected: (value) => setState(() => _myWorkSort = value),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          if (filtered.isEmpty)
            OpsEmptyState(
              icon: Icons.engineering_outlined,
              title: context.l10n.dtMyWorkEmptyTitle,
              subtitle: context.l10n.dtTryOtherFilters,
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
              tooltip: context.l10n.dtClearSearch,
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
          items: {
            'ALL': context.l10n.dtAssignAll,
            'MINE': context.l10n.dtAssignMine,
            'UNASSIGNED': context.l10n.dtAssignNone,
          },
          onChanged: (value) =>
              setState(() => _droneReportAssignmentFilter = value),
        ),
        _compactDropdown(
          value: _droneReportDroneFilter,
          items: {'ALL': context.l10n.dtAllDrones, for (final drone in drones) drone: drone},
          onChanged: (value) => setState(() => _droneReportDroneFilter = value),
        ),
        _compactDropdown(
          value: _droneReportTimeFilter,
          items: {
            'ALL': context.l10n.dtTimeAll,
            'TODAY': context.l10n.commonToday,
            '7D': context.l10n.dtTime7d,
            '30D': context.l10n.dtTime30d,
          },
          onChanged: (value) => setState(() => _droneReportTimeFilter = value),
        ),
        _sortMenu(
          value: _droneReportSort,
          values: {
            'NEWEST': context.l10n.dtSortNewest,
            'OLDEST': context.l10n.dtSortOldest,
            'SLA': context.l10n.dtSortSla,
          },
          onSelected: (value) => setState(() => _droneReportSort = value),
        ),
        if (active)
          TextButton.icon(
            onPressed: _resetDroneReportFilters,
            icon: const Icon(Icons.restart_alt_rounded, size: 17),
            label: Text(context.l10n.dtReset),
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
      label: Text(values[value] ?? context.l10n.dtSort),
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
                    '${report['title'] ?? context.l10n.dtDroneIncidentFallback}',
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
                  _MiniPill(
                    icon: Icons.timer_off_outlined,
                    text: context.l10n.dtSlaOverdue,
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
                        label: Text(context.l10n.dtClaim),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0284C7),
                          foregroundColor: Colors.white,
                        ),
                      )
                    : TextButton.icon(
                        onPressed: () => _showDroneReportDetail(report),
                        icon: const Icon(Icons.build_outlined, size: 17),
                        label: Text(context.l10n.dtUpdateProgress),
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
    final assignedTo = report['assignedToUserId']?.toString().trim();
    if (assignedTo != null && assignedTo.isNotEmpty && assignedTo != 'null') {
      return false;
    }
    final droneTech = _droneAssignedTechnicianId(report);
    return droneTech == null || droneTech == _myUserId;
  }

  Future<void> _confirmClaimDroneReport(Map<String, dynamic> report) async {
    final reportId = _asInt(report['id']);
    if (reportId == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(context.l10n.dtClaimReportTitle),
        content: Text(
          context.l10n.dtClaimReportBody(
            reportId,
            '${report['droneCode'] ?? report['droneUnitId'] ?? '—'}',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(context.l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(context.l10n.dtConfirmClaim),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await _runCellAction(
      () => _service.claimDroneReport(reportId),
      context.l10n.dtClaimedReport(reportId),
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
          OpsBanner(
            tone: OpsBannerTone.info,
            icon: Icons.flight_outlined,
            text: context.l10n.dtFleetBanner,
          ),
          if (_dronesLoadError != null) ...[
            const SizedBox(height: 8),
            OpsBanner(
              tone: OpsBannerTone.danger,
              icon: Icons.cloud_off_outlined,
              text: _dronesLoadError!,
            ),
            _retryButton(),
          ],
          const SizedBox(height: 12),
          if (_myDrones.isEmpty && _dronesLoadError == null)
            OpsEmptyState(
              icon: Icons.flight_outlined,
              title: context.l10n.dtFleetEmptyTitle,
              subtitle: _unassignedDrones.isEmpty
                  ? context.l10n.dtFleetEmptyAssigned
                  : context.l10n.dtFleetEmptyPickBelow,
            )
          else
            for (final d in _myDrones) _droneCard(d),
          // Trước đây tab chỉ liệt kê drone của mình nên nút "Nhận xử lý" (chỉ hiện với
          // drone chưa thuộc mình) không bao giờ mở được (test 2026-11-02).
          if (_unassignedDrones.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              context.l10n.dtUnassignedDrones(_unassignedDrones.length),
              key: const ValueKey('drone-unassigned-title'),
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 14,
                color: opsDark,
              ),
            ),
            const SizedBox(height: 8),
            for (final d in _unassignedDrones) _droneCard(d),
          ],
        ],
      ),
    );
  }

  // ---- Tab lịch bảo trì ----
  Widget _buildMaintenanceSchedules() {
    final query = _scheduleSearchController.text.trim().toLowerCase();
    final dueCount = _schedules.where((s) => s['due'] == true).length;
    final upcomingCount = _schedules.length - dueCount;
    final schedules = _schedules.where((schedule) {
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
          OpsBanner(
            tone: OpsBannerTone.info,
            icon: Icons.event_repeat,
            text: context.l10n.dtScheduleBanner,
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
            hint: context.l10n.dtScheduleSearchHint,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final option in [
                  (
                    'ALL',
                    context.l10n.dtAllWithCount(_schedules.length),
                    Icons.event_note_outlined,
                  ),
                  ('DUE', context.l10n.dtDueWithCount(dueCount), Icons.warning_amber_rounded),
                  (
                    'UPCOMING',
                    context.l10n.dtUpcomingWithCount(upcomingCount),
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
                items: {
                  'ALL': context.l10n.dtPriorityAll,
                  'URGENT': context.l10n.dtPriorityUrgent,
                  'HIGH': context.l10n.dtPriorityHighShort,
                  'NORMAL': context.l10n.dtPriorityNormal,
                  'LOW': context.l10n.dtPriorityLowShort,
                },
                onChanged: (value) =>
                    setState(() => _schedulePriorityFilter = value),
              ),
              _sortMenu(
                value: _scheduleSort,
                values: {
                  'DUE': context.l10n.dtSortDue,
                  'PRIORITY': context.l10n.dtSortPriority,
                  'NEWEST': context.l10n.dtSortNewlyCreated,
                },
                onSelected: (value) => setState(() => _scheduleSort = value),
              ),
              if (_scheduleSearchController.text.isNotEmpty ||
                  _schedulePriorityFilter != 'ALL' ||
                  _scheduleDueFilter != 'ALL')
                TextButton.icon(
                  onPressed: _resetScheduleFilters,
                  icon: const Icon(Icons.restart_alt_rounded, size: 17),
                  label: Text(context.l10n.dtReset),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (schedules.isEmpty && _scheduleLoadError == null)
            OpsEmptyState(
              icon: Icons.event_available_outlined,
              title: _schedules.isEmpty
                  ? context.l10n.dtSchedulesEmptyTitle
                  : context.l10n.dtSchedulesNoMatch,
              subtitle: _schedules.isEmpty
                  ? context.l10n.dtSchedulesEmptySubtitle
                  : context.l10n.dtTryOtherFilters,
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
            title: context.l10n.dtToolMissionTitle,
            subtitle: context.l10n.dtToolMissionSubtitle,
            onTap: () => context.push(AppRouter.droneMissionPlanner),
          ),
          const SizedBox(height: 10),
          _droneToolCard(
            icon: Icons.flight_takeoff,
            title: context.l10n.dtToolFlightTitle,
            subtitle: context.l10n.dtToolFlightSubtitle,
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
                  _MiniPill(
                    icon: Icons.warning_amber_rounded,
                    text: context.l10n.dtDueBadge,
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
                  text: context.l10n.dtEveryDays('${s['intervalDays']}'),
                ),
                if (nextDue != null)
                  _MiniPill(icon: Icons.event, text: context.l10n.dtDueAt(nextDue)),
                if (lastDone != null)
                  _MiniPill(icon: Icons.history, text: context.l10n.dtLastDone(lastDone)),
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
                text: context.l10n.dtFinishTicketBeforeNext(pendingReportId),
              ),
            ],
            const SizedBox(height: 10),
            // Wrap: máy hẹp / cỡ chữ lớn thì nút xuống dòng thay vì tràn phải.
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: () => _showDroneScheduleDetail(s),
                  icon: const Icon(Icons.info_outline, size: 16),
                  label: Text(context.l10n.commonDetails),
                ),
                ElevatedButton.icon(
                  onPressed: id == null || blocked
                      ? null
                      : () => _showDroneInspectionSheet(s),
                  icon: const Icon(Icons.fact_check_outlined, size: 16),
                  label: Text(due ? context.l10n.dtInspectNow : context.l10n.dtInspect),
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
      label: Text(context.l10n.commonRetry),
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
    'URGENT' => (context.l10n.dtPriorityUrgent, const Color(0xFFDC2626)),
    'HIGH' => (context.l10n.dtPriorityHigh, const Color(0xFFEA580C)),
    'LOW' => (context.l10n.dtPriorityLow, const Color(0xFF64748B)),
    _ => (context.l10n.dtPriorityNormal, const Color(0xFF0284C7)),
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
              ? context.l10n.dtInspectionFailedSnack
              : context.l10n.dtInspectionPassedSnack,
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
          SnackBar(content: Text(context.l10n.dtScheduleNoAddress)),
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
        SnackBar(content: Text(context.l10n.dtCannotOpenMaps)),
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
                          '${_lockerPointName(order['sourceLocker'], order['sourceLockerId'], context.l10n.dtSourceLocker)} '
                          '→ ${_lockerPointName(order['destinationLocker'], lockerId, context.l10n.dtDestinationLocker)}',
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
                              context.l10n.dtReceiveBoxNumber(boxNumber)
                            else if (reservedBoxId != null)
                              context.l10n.dtReceiveBoxHeld,
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
                  if (_orderBusy(orderId))
                    const Padding(
                      padding: EdgeInsets.only(left: 8),
                      child: SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
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
                          _DeliveryAction.accept => context.l10n.dtActionAccept,
                          _DeliveryAction.load => context.l10n.dtActionLoad,
                          _DeliveryAction.launch => context.l10n.dtActionLaunch,
                          _DeliveryAction.launching => context.l10n.dtActionLaunching,
                          _DeliveryAction.track => context.l10n.dtActionTrack,
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
                        label: Text(
                          context.l10n.dtActionLoad,
                          style: const TextStyle(
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
                        label: Text(
                          context.l10n.dtActionLaunch,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    OutlinedButton.icon(
                      onPressed: _ownsMission(order) && !_orderBusy(orderId)
                          ? onCancel
                          : null,
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
                      label: Text(
                        context.l10n.dtCancelBeforeFlight,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              if ((action == _DeliveryAction.accept ||
                      action == _DeliveryAction.launch) &&
                  _routeGrounded(order) != null) ...[
                const SizedBox(height: 8),
                Row(
                  key: ValueKey('drone-route-grounded-$orderId'),
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.thunderstorm_outlined,
                      size: 16,
                      color: Color(0xFFB91C1C),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        action == _DeliveryAction.accept ? context.l10n.dtRouteGroundedCantAccept('${_routeGrounded(order)}') : context.l10n.dtRouteGroundedCantLaunch('${_routeGrounded(order)}'),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFB91C1C),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              if (description != null && description.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  context.l10n.dtGoods(description),
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                ),
              ],
              if (_parcelSummary(order) != null) ...[
                const SizedBox(height: 4),
                Text(
                  context.l10n.dtParcel('${_parcelSummary(order)}'),
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
              // Drone đang gửi telemetry thì chặng tự cập nhật: không cho xác
              // nhận tay để tránh nhảy thêm một chặng.
              if (_advanceLabel(order) != null &&
                  order['liveTracking'] == true) ...[
                const SizedBox(height: 8),
                _MiniPill(
                  icon: Icons.sensors,
                  text: context.l10n.dtLiveTrackingPill,
                  color: Color(0xFF0F766E),
                ),
              ] else if (_advanceLabel(order) != null) ...[
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _orderBusy(orderId)
                        ? null
                        : () => _advanceFlow(order),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF0F766E),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    icon: const Icon(Icons.check_circle_outline, size: 16),
                    label: Text(
                      context.l10n.dtConfirmStage('${_advanceLabel(order)}'),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
              if (order['block'] is Map) ...[
                const SizedBox(height: 8),
                _MiniPill(
                  icon: Icons.warning_amber_rounded,
                  text:
                      context.l10n.dtBlockedBy(
                        '${(order['block'] as Map)['reasonLabel'] ?? droneFailureReasonLabel('${(order['block'] as Map)['reason']}')}',
                      ) +
                      ((order['block'] as Map)['ticketId'] == null
                          ? ''
                          : context.l10n.dtBlockedTicket(
                              '${(order['block'] as Map)['ticketId']}',
                            )),
                  color: const Color(0xFFB45309),
                ),
              ],
              if (_canChangeDrone(order)) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    OutlinedButton.icon(
                      key: const ValueKey('drone-change-drone'),
                      onPressed: () => _changeDroneFlow(order),
                      icon: const Icon(Icons.swap_horiz, size: 16),
                      label: Text(context.l10n.dtChangeDrone),
                    ),
                    OutlinedButton.icon(
                      key: const ValueKey('drone-fail-blocked'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFDC2626),
                        side: const BorderSide(color: Color(0xFFDC2626)),
                      ),
                      onPressed: () => _failDeliveryFlow(order),
                      icon: const Icon(Icons.report_problem_outlined, size: 16),
                      label: Text(context.l10n.dtFailDelivery),
                    ),
                  ],
                ),
              ],
              if (_canReportFailure(order)) ...[
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    key: const ValueKey('drone-report-flight-failure'),
                    onPressed: _orderBusy(orderId)
                        ? null
                        : () => _cancelDeliveryFlow(order, inFlight: true),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFDC2626),
                      side: const BorderSide(color: Color(0xFFDC2626)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    icon: const Icon(Icons.report_problem_outlined, size: 16),
                    label: Text(
                      context.l10n.dtReportFlightFailure,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
              if (action == _DeliveryAction.accept && !_isPaid(order)) ...[
                const SizedBox(height: 8),
                _MiniPill(
                  icon: Icons.payments_outlined,
                  text: context.l10n.dtUnpaidCantAccept,
                  color: Color(0xFFB45309),
                ),
              ],
              if (action == _DeliveryAction.accept &&
                  _isPaid(order) &&
                  !_parcelDropped(order)) ...[
                const SizedBox(height: 8),
                _MiniPill(
                  icon: Icons.inventory_2_outlined,
                  text: context.l10n.dtNotDroppedCantAccept,
                  color: Color(0xFFB45309),
                ),
              ],
              if (action == _DeliveryAction.launch && !_isPaid(order)) ...[
                const SizedBox(height: 8),
                _MiniPill(
                  icon: Icons.scale_outlined,
                  text: context.l10n.dtOverweightAwaitingPayment,
                  color: Color(0xFFB45309),
                ),
              ],
              const SizedBox(height: 8),
              Text(
                [
                  context.l10n.dtStageLine(_stageTitle(order['deliveryStage'], stage, missionStatus)),
                  // Đã nạp xong thì chặng nói luôn "Sẵn sàng phóng"; không ghép thêm
                  // nhãn nhiệm vụ trùng / mâu thuẫn (test 2026-10-29).
                  if (missionStatus != null &&
                      missionStatus.isNotEmpty &&
                      missionStatus.toUpperCase() != 'READY_TO_LAUNCH')
                    context.l10n.dtMissionLine(droneMissionStatusLabel(missionStatus)),
                ].join(' · '),
                style: const TextStyle(fontSize: 12, color: Colors.black54),
              ),
              if (updatedAt != null) ...[
                const SizedBox(height: 4),
                Text(
                  context.l10n.dtUpdatedTapDetail(formatDateTimeVn(updatedAt)),
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
          onChanged: _load,
        ),
      ),
    );
  }

  void _onStationWeather(List<Map<String, dynamic>> lockers) {
    final grounded = <int, String>{};
    for (final locker in lockers) {
      final id = _asInt(locker['lockerId']);
      if (id == null) continue;
      final weather = DroneWeather.fromJson(locker['weather']);
      if (locker['suspension'] case final Map stop) {
        grounded[id] = context.l10n.dtGroundedPaused(
          '${stop['reasonLabel'] ?? stop['reason'] ?? context.l10n.dtGroundedPausedByAdmin}',
        );
      } else if (weather != null && !weather.canFly) {
        grounded[id] = weather.unavailable
            ? context.l10n.dtGroundedNoForecast
            : context.l10n.dtGroundedWeather;
      }
    }
    if (mounted) setState(() => _groundedStations = grounded);
  }

  /// Lý do tuyến của đơn đang không bay được, null nếu cả hai trạm đều bay được.
  String? _routeGrounded(Map<String, dynamic> order) {
    final source = _asInt(order['sourceLockerId']);
    final destination = _asInt(order['destinationLockerId']);
    if (source != null && _groundedStations[source] != null) {
      return context.l10n.dtGroundedTakeoffStation('${_groundedStations[source]}');
    }
    if (destination != null && _groundedStations[destination] != null) {
      return context.l10n.dtGroundedReceivingLocker('${_groundedStations[destination]}');
    }
    return null;
  }

  bool _actionEnabled(
    _DeliveryAction action,
    int? orderId,
    Map<String, dynamic> order,
  ) {
    if (orderId == null) return false;
    if (_orderBusy(orderId)) return false;
    if (action == _DeliveryAction.launching) return false;
    if (action == _DeliveryAction.track) return true;
    // Trạm cất cánh / tủ nhận đang không bay được: server sẽ từ chối, khoá sẵn.
    if ((action == _DeliveryAction.accept ||
            action == _DeliveryAction.launch) &&
        _routeGrounded(order) != null) {
      return false;
    }
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

  String? _nextStageLabel(String stage) => switch (stage) {
    'LAUNCHING' => context.l10n.dtNextStageLaunching,
    'DEPARTED' => context.l10n.dtNextStageDeparted,
    'EN_ROUTE' => context.l10n.dtNextStageEnRoute,
    'APPROACHING' => context.l10n.dtNextStageApproaching,
    'ARRIVED' => context.l10n.dtNextStageArrived,
    _ => null,
  };

  /// Nhãn chặng kế tiếp nếu điều phối viên này được xác nhận tay; null nếu không.
  /// Chỉ đơn drone thật: đơn DEMO do bộ giả lập tự đẩy chặng.
  String? _advanceLabel(Map<String, dynamic> order) {
    if ('${order['fulfillmentMode']}'.toUpperCase() == 'DEMO') return null;
    if ('${order['deliveryStage']}'.toUpperCase() == _dropReportedStage) {
      return null;
    }
    if (order['assignedByUserId'] == null || !_ownsMission(order)) return null;
    return _nextStageLabel('${order['deliveryStage']}');
  }

  /// Chuyến bay đã phóng (kể cả đơn DEMO) mà không giao được: chỉ điều phối viên
  /// đã nhận nhiệm vụ được báo — khớp `reportFlightFailure` ở backend.
  bool _canReportFailure(Map<String, dynamic> order) =>
      order['assignedByUserId'] != null &&
      _ownsMission(order) &&
      _flightFailureStages.contains('${order['deliveryStage']}');

  static const _flightFailureStages = {
    'LAUNCHING',
    'DEPARTED',
    'EN_ROUTE',
    'APPROACHING',
    'ARRIVED',
  };

  /// Tiêu đề chặng cho thẻ đơn; DROP_REPORTED (đã báo rơi kiện) chưa có trong
  /// [DroneDeliveryStage] nên đặt nhãn riêng.
  /// Chặng ACCEPTED kéo dài từ lúc gán drone tới lúc phóng; nhiệm vụ READY_TO_LAUNCH nghĩa là
  /// đã nạp xong — tiêu đề "Đang nạp hàng lên drone" khi đó là sai.
  String _stageTitle(
    dynamic raw,
    DroneDeliveryStage stage, [
    String? missionStatus,
  ]) {
    if ('${raw ?? ''}'.toUpperCase() == _dropReportedStage) {
      return context.l10n.dtStageDropReported;
    }
    if ((missionStatus ?? '').toUpperCase() == 'READY_TO_LAUNCH') {
      return context.l10n.dtStageReadyToLaunch;
    }
    return stage.title;
  }

  /// Đơn đã gán drone (chưa phóng) đang gặp sự cố: KTV phụ trách đổi drone khác ở tủ gửi
  /// hoặc xác nhận giao không hoàn tất.
  bool _canChangeDrone(Map<String, dynamic> order) =>
      order['block'] is Map &&
      order['assignedByUserId'] != null &&
      _ownsMission(order) &&
      '${order['deliveryStage']}' == 'ACCEPTED';

  Future<void> _changeDroneFlow(Map<String, dynamic> order) async {
    final id = _asInt(order['orderId']);
    if (id == null) return;
    final candidates = _drones
        .where(
          (d) =>
              d['status'] == 'IDLE' &&
              _asInt(d['id']) != _asInt(order['droneUnitId']) &&
              _asInt(d['lockerId']) == _asInt(order['sourceLockerId']),
        )
        .toList(growable: false);
    if (candidates.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.dtNoOtherIdleDrone)),
        );
      }
      return;
    }
    int? selected = _asInt(candidates.first['id']);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(context.l10n.dtChangeDrone),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(context.l10n.dtChangeDroneHint),
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
                      selected: selected == _asInt(d['id']),
                      onSelected: (_) =>
                          setLocal(() => selected = _asInt(d['id'])),
                    ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(context.l10n.commonCancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(context.l10n.dtChangeDrone),
            ),
          ],
        ),
      ),
    );
    if (ok != true || selected == null) return;
    await _runOrderAction(
      id,
      'change-drone',
      () => _service.changeDroneOfOrder(id, droneUnitId: selected!),
      success: L10n.current.dtChangedDrone,
    );
  }

  /// KTV phụ trách xác nhận đơn giao không hoàn tất (đơn đang bị sự cố chặn).
  Future<void> _failDeliveryFlow(Map<String, dynamic> order) async {
    final id = _asInt(order['orderId']);
    if (id == null) return;
    final block = order['block'];
    final result = await showDroneReasonDialog(
      context,
      title: context.l10n.dtFailDelivery,
      intro: context.l10n.dtFailDeliveryIntro,
      reasons: droneDeliveryFailureReasons,
      confirmLabel: context.l10n.commonConfirm,
      initialReason: block is Map ? '${block['reason']}' : null,
    );
    if (result == null) return;
    await _runOrderAction(
      id,
      'fail-delivery',
      () => _service.failDroneOrder(id, reason: result.$1, note: result.$2),
      success: L10n.current.dtFailedDeliveryDone,
    );
  }

  Future<void> _advanceFlow(Map<String, dynamic> order) async {
    final orderId = _asInt(order['orderId']);
    final label = _advanceLabel(order);
    if (orderId == null || label == null) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(context.l10n.dtConfirmStageTitle),
        content: Text(context.l10n.dtConfirmStageBody(label)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(context.l10n.commonNotYet),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(context.l10n.commonConfirm),
          ),
        ],
      ),
    );
    if (ok != true) return;
    // Gửi chặng đang hiển thị: drone/người khác đã đẩy chặng đi trước thì server
    // trả DRONE_STAGE_CHANGED và danh sách được tải lại.
    final expectedStage = order['deliveryStage']?.toString();
    await _runOrderAction(
      orderId,
      'advance',
      () => _service.advanceDroneOrder(orderId, expectedStage: expectedStage),
      success: L10n.current.dtConfirmedStage(label),
      reloadOnError: true,
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
        context.l10n.dtDeclaredValue(fmtPrice(order['declaredValue'])),
      if (order['fragile'] == true) context.l10n.dtFragileUpper,
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
                '${order['orderCode'] ?? context.l10n.dtOrderNumber('$orderId')} · '
                '${DroneDeliveryStage.fromRaw(order['deliveryStage']?.toString()) == DroneDeliveryStage.failed ? (order['launchingAt'] != null ? context.l10n.dtFlightFailedLower : context.l10n.dtDeliveryNotCompletedLower) : context.l10n.dtCanceledLower}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: opsDark,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                inSourceBox
                    ? (sourceBox == null
                          ? context.l10n.dtParcelInSourceBox(
                              _lockerPointName(order['sourceLocker'], order['sourceLockerId'], context.l10n.dtSendingLocker),
                            )
                          : context.l10n.dtParcelInSourceBoxNumber(
                              sourceBox,
                              _lockerPointName(order['sourceLocker'], order['sourceLockerId'], context.l10n.dtSendingLocker),
                            ))
                    : context.l10n.dtParcelHeldByTeam,
                style: const TextStyle(fontSize: 12, color: Colors.black54),
              ),
              if (sender.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  context.l10n.dtSender(sender),
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                ),
              ],
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  key: ValueKey('drone-parcel-return-$orderId'),
                  onPressed:
                      orderId != null &&
                          _ownsMission(order) &&
                          !_orderBusy(orderId)
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
                  label: Text(
                    context.l10n.dtConfirmParcelReturned,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
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
        title: Text(context.l10n.dtConfirmParcelReturned),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.l10n.dtParcelReturnHint,
              style: const TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: noteCtrl,
              minLines: 1,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: context.l10n.dtNoteOptional,
                isDense: true,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(context.l10n.commonNotYet),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(context.l10n.dtParcelReturned),
          ),
        ],
      ),
    );
    final note = noteCtrl.text;
    WidgetsBinding.instance.addPostFrameCallback((_) => noteCtrl.dispose());
    if (ok != true) return;
    await _runOrderAction(
      orderId,
      'parcel-return',
      () => _service.confirmDroneParcelReturn(orderId, note: note),
      success: L10n.current.dtParcelReturnRecorded,
    );
  }

  bool _isPaid(Map<String, dynamic> order) =>
      '${order['paymentStatus']}'.toUpperCase() == 'PAID';

  String _routeLabel(Map<String, dynamic> order) =>
      '${_lockerPointName(order['sourceLocker'], order['sourceLockerId'], context.l10n.dtSendingLocker)} '
      '→ ${_lockerPointName(order['destinationLocker'], order['destinationLockerId'], context.l10n.dtReceivingLocker)}';

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
        await _runOrderAction(
          orderId,
          'launch',
          () => _service.launchDroneOrder(
            orderId,
            idempotencyKey: _idempotencyKey('launch', orderId),
          ),
          success: context.l10n.dtLaunchCommandSent,
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
    // Ô cân để trống: đội viên phải nhập số đọc trên cân, không lấy sẵn số khai báo.
    final weightCtrl = TextEditingController();
    final config = BusinessConfigService.instance.current;
    final declaredGrams =
        _asInt(order['parcelWeightGrams']) ??
        _asInt(order['expectedWeightGrams']);
    final totalRaw = order['totalPrice'];
    final currentTotal = totalRaw is num ? totalRaw : num.tryParse('$totalRaw');
    final chargedRaw = order['weightSurcharge'];
    final alreadyCharged = chargedRaw is num
        ? chargedRaw
        : num.tryParse('${chargedRaw ?? ''}') ?? 0;
    // Phần thu thêm ước tính theo bảng giá; server tính lại khi xác nhận.
    int surchargeFor(String text) {
      final actual = int.tryParse(text.trim());
      if (actual == null || declaredGrams == null) {
        return 0;
      }
      return config.droneWeightSurcharge(
        declaredGrams: declaredGrams,
        actualGrams: actual,
        alreadyCharged: alreadyCharged,
      );
    }

    final noteCtrl = TextEditingController();
    var parcelMatched = false;
    var payloadSecured = false;
    var compartmentLocked = false;
    var weightInvalid = false;
    var checklistIncomplete = false;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(context.l10n.dtConfirmLoadingTitle),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(context.l10n.dtConfirmLoadingIntro),
                const SizedBox(height: 12),
                TextField(
                  key: const ValueKey('drone-loading-weight'),
                  controller: weightCtrl,
                  keyboardType: TextInputType.number,
                  onChanged: (_) => setLocal(() => weightInvalid = false),
                  decoration: InputDecoration(
                    labelText: context.l10n.dtActualWeightLabel,
                    hintText: context.l10n.dtActualWeightHint,
                    errorText: weightInvalid
                        ? context.l10n.dtActualWeightInvalid
                        : null,
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  declaredGrams == null
                      ? context.l10n.dtNoDeclaredWeight
                      : currentTotal == null
                      ? context.l10n.dtDeclaredWeight(droneWeightLabel(declaredGrams))
                      : context.l10n.dtDeclaredWeightWithFee(
                          droneWeightLabel(declaredGrams),
                          fmtPrice(currentTotal),
                        ),
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                ),
                if (surchargeFor(weightCtrl.text) > 0) ...[
                  const SizedBox(height: 6),
                  Text(
                    context.l10n.dtOverweightSurcharge(
                      fmtPrice(surchargeFor(weightCtrl.text)),
                    ),
                    key: const ValueKey('drone-loading-surcharge'),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFB45309),
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                // Mã niêm phong do server sinh khi xác nhận nạp; app chỉ hiện
                // mã server trả về.
                InputDecorator(
                  key: const ValueKey('drone-loading-seal'),
                  decoration: InputDecoration(
                    labelText: context.l10n.dtSealCode,
                    isDense: true,
                  ),
                  child: Text(
                    context.l10n.dtSealCodeHint,
                    style: const TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                ),
                const SizedBox(height: 8),
                CheckboxListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  value: parcelMatched,
                  onChanged: (value) => setLocal(() {
                    parcelMatched = value ?? false;
                    checklistIncomplete = false;
                  }),
                  title: Text(context.l10n.dtCheckParcelMatched),
                ),
                CheckboxListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  value: payloadSecured,
                  onChanged: (value) => setLocal(() {
                    payloadSecured = value ?? false;
                    checklistIncomplete = false;
                  }),
                  title: Text(context.l10n.dtCheckPayloadSecured),
                ),
                CheckboxListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  value: compartmentLocked,
                  onChanged: (value) => setLocal(() {
                    compartmentLocked = value ?? false;
                    checklistIncomplete = false;
                  }),
                  title: Text(context.l10n.dtCheckCompartmentLocked),
                ),
                if (checklistIncomplete)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      context.l10n.dtChecklistIncomplete,
                      key: const ValueKey('drone-loading-checklist-error'),
                      style: const TextStyle(
                        color: Colors.red,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                TextField(
                  controller: noteCtrl,
                  minLines: 1,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: context.l10n.dtNoteOptional,
                    isDense: true,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(context.l10n.commonClose),
            ),
            FilledButton(
              onPressed: () {
                final weight = int.tryParse(weightCtrl.text.trim());
                final invalidWeight = weight == null || weight <= 0;
                final incompleteChecklist =
                    !parcelMatched || !payloadSecured || !compartmentLocked;
                if (invalidWeight || incompleteChecklist) {
                  setLocal(() {
                    weightInvalid = invalidWeight;
                    checklistIncomplete = incompleteChecklist;
                  });
                  return;
                }
                Navigator.pop(ctx, true);
              },
              child: Text(context.l10n.dtConfirmLoaded),
            ),
          ],
        ),
      ),
    );

    if (confirmed == true) {
      await _confirmLoading(
        orderId,
        payloadWeightGrams: int.parse(weightCtrl.text.trim()),
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
    required bool parcelMatched,
    required bool payloadSecured,
    required bool compartmentLocked,
    required String note,
  }) async {
    if (_busyOrders.contains(orderId)) return;
    setState(() => _busyOrders.add(orderId));
    String message;
    try {
      final result = await _service.confirmDroneLoading(
        orderId,
        payloadWeightGrams: payloadWeightGrams,
        parcelMatched: parcelMatched,
        payloadSecured: payloadSecured,
        compartmentLocked: compartmentLocked,
        note: note,
        idempotencyKey: _idempotencyKey('load', orderId),
      );
      _idempotencyKeys.remove('load-$orderId');
      // Đổi thẻ sang "Phóng" ngay theo phản hồi server, không chờ lượt tải lại.
      _mergeDeliveryResult(orderId, result);
      final surchargeRaw = result['weightSurcharge'];
      final surcharge = surchargeRaw is num
          ? surchargeRaw
          : num.tryParse('$surchargeRaw') ?? 0;
      // Mã niêm phong do server cấp; không có thì không bịa mã.
      final seal = '${result['sealCode'] ?? ''}'.trim();
      final sealText = seal.isEmpty ? '' : L10n.current.dtSealSuffix(seal);
      message = surcharge > 0
          ? L10n.current.dtLoadedOverweight(sealText, fmtPrice(surcharge))
          : L10n.current.dtLoadedReady(sealText);
    } catch (e) {
      message = droneTechnicianErrorMessage(e);
    } finally {
      if (mounted) {
        setState(() => _busyOrders.remove(orderId));
      } else {
        _busyOrders.remove(orderId);
      }
    }
    _showSnack(message);
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
    // Không chọn sẵn: KTV phải tự chọn lý do (lý do vào lịch sử đơn và báo cáo chặn bay).
    _DroneCancelReason? selectedReason;
    String? reasonProblem;
    String? noteProblem;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            inFlight ? context.l10n.dtReportFlightFailure : context.l10n.dtCancelMissionBeforeFlight,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                inFlight
                    ? context.l10n.dtFlightFailureIntro
                    : context.l10n.dtCancelMissionIntro,
                style: const TextStyle(fontSize: 13, color: Colors.black87),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final reason in _cancelReasons)
                    ChoiceChip(
                      label: Text(reason.label),
                      selected: selectedReason?.code == reason.code,
                      onSelected: (_) => setLocal(() {
                        selectedReason = reason;
                        reasonProblem = null;
                      }),
                    ),
                ],
              ),
              if (reasonProblem != null) ...[
                const SizedBox(height: 6),
                Text(
                  reasonProblem!,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFFB91C1C),
                  ),
                ),
              ],
              const SizedBox(height: 12),
              TextField(
                controller: noteCtrl,
                minLines: 2,
                maxLines: 4,
                decoration: InputDecoration(
                  labelText: selectedReason?.requiresNote == true
                      ? context.l10n.dtNoteRequired
                      : context.l10n.dtNoteOptional,
                  errorText: noteProblem,
                  isDense: true,
                ),
              ),
            ],
          ),
          actions: [
            // "Quay lại" chứ không "Hủy": đặt cạnh "Xác nhận hủy" dễ bấm nhầm.
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(context.l10n.commonBack),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFDC2626),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {
                // Báo lỗi ngay trong hộp thoại: SnackBar nằm sau lớp phủ, KTV không thấy.
                if (selectedReason == null) {
                  setLocal(() => reasonProblem = context.l10n.dtPickReason);
                  return;
                }
                if (selectedReason!.requiresNote &&
                    noteCtrl.text.trim().isEmpty) {
                  setLocal(() => noteProblem = context.l10n.dtNoteRequiredForOther);
                  return;
                }
                Navigator.pop(ctx, true);
              },
              child: Text(inFlight ? context.l10n.dtConfirmFailure : context.l10n.dtConfirmCancel),
            ),
          ],
        ),
      ),
    );

    final reason = selectedReason;
    if (confirmed != true || reason == null) {
      return;
    }

    final note = noteCtrl.text.trim().isEmpty ? null : noteCtrl.text.trim();
    WidgetsBinding.instance.addPostFrameCallback((_) => noteCtrl.dispose());
    await _runOrderAction(
      orderId,
      inFlight ? 'fail' : 'cancel',
      () => inFlight
          ? _service.failDroneOrder(
              orderId,
              // Sự cố khi drone đã phóng: mã số của hộp chọn → mã lý do của backend.
              reason: const {
                1: 'WEATHER_UNSAFE',
                // KTV chọn "Drone lỗi" ⇒ lưu đúng là drone lỗi, không gộp vào "sự cố trong lúc bay".
                2: 'DRONE_FAULT',
                3: 'LANDING_PAD_FAULT',
                4: 'OPERATIONAL',
                5: 'OTHER',
              }[reason.code],
              note: note,
            )
          : _service.cancelDroneOrder(
              orderId,
              reasonCode: reason.code,
              note: note,
            ),
      success: inFlight
          ? L10n.current.dtFlightFailureReported
          : L10n.current.dtMissionCanceled,
      reloadOnError: true,
    );
  }

  /// Lý do drone không nhận được đơn — cùng điều kiện server kiểm khi tiếp nhận
  /// (drone còn hoạt động, đang Sẵn sàng, biết mức pin, pin trên ngưỡng);
  /// `null` = đủ điều kiện. Server vẫn kiểm lại.
  String? _droneIneligibleReason(Map<String, dynamic> drone) {
    if (drone['active'] == false) return context.l10n.dtIneligibleInactive;
    final status = '${drone['status'] ?? ''}';
    if (status != 'IDLE') return _droneStatusLabel(status).toLowerCase();
    final battery = _asInt(drone['batteryPercent']);
    if (battery == null) return context.l10n.dtIneligibleUnknownBattery;
    if (battery <= _minPreflightBatteryPercent) {
      return context.l10n.dtIneligibleLowBattery(battery, _minPreflightBatteryPercent);
    }
    return null;
  }

  /// Chọn drone đủ điều kiện rồi tiếp nhận nhiệm vụ theo `orderId`.
  Future<void> _acceptFlow(Map<String, dynamic> order) async {
    final id = _asInt(order['orderId']);
    if (id == null) return;
    final sourceLockerId = _asInt(order['sourceLockerId']);
    final atSource = _drones
        .where(
          (d) =>
              sourceLockerId == null || _asInt(d['lockerId']) == sourceLockerId,
        )
        .toList(growable: false);
    final candidates = atSource
        .where((d) => _droneIneligibleReason(d) == null)
        .toList(growable: false);
    if (candidates.isEmpty) {
      _showSnack(
        atSource.isEmpty
            ? context.l10n.dtNoDroneAtSource
            : context.l10n.dtNoEligibleDroneAtSource(
                atSource
                    .map((d) => '${d['code']} (${_droneIneligibleReason(d)})')
                    .join(', '),
              ),
      );
      return;
    }
    final hasIneligible = candidates.length < atSource.length;
    int? selectedDroneId = _asInt(candidates.first['id']);

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Icon(Icons.flight, color: Color(0xFF6366F1)),
              SizedBox(width: 8),
              Text(context.l10n.dtAssignDroneTitle),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${order['reservedBoxNumber'] != null ? context.l10n.dtAssignDroneRouteBox(_routeLabel(order), '${order['reservedBoxNumber']}') : context.l10n.dtAssignDroneRoute(_routeLabel(order))}\n'
                '${context.l10n.dtAssignDronePick}',
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final d in atSource)
                    ChoiceChip(
                      label: Text(
                        _droneIneligibleReason(d) == null
                            ? '${d['code']} · ${d['batteryPercent']}%'
                            : '${d['code']} · ${_droneIneligibleReason(d)}',
                      ),
                      selected: selectedDroneId == _asInt(d['id']),
                      onSelected: _droneIneligibleReason(d) == null
                          ? (_) => setLocal(
                              () => selectedDroneId = _asInt(d['id']),
                            )
                          : null,
                    ),
                ],
              ),
              if (hasIneligible) ...[
                const SizedBox(height: 8),
                Text(
                  context.l10n.dtIneligibleDronesHint(_minPreflightBatteryPercent),
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(context.l10n.commonCancel),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(context.l10n.dtAssignDrone),
            ),
          ],
        ),
      ),
    );
    if (ok != true) return;
    final droneId = selectedDroneId;
    if (droneId == null) return;
    await _runOrderAction(
      id,
      'accept',
      () => _service.acceptDroneOrder(
        id,
        droneUnitId: droneId,
        idempotencyKey: _idempotencyKey('accept', id),
      ),
      success: L10n.current.dtAcceptedAndAssigned,
      reloadOnError: true,
    );
  }

  Widget _droneCard(Map<String, dynamic> drone) {
    final status = drone['status'] as String? ?? 'IDLE';
    final battery = _asInt(drone['batteryPercent']);
    final lockerLabel = drone['lockerName'] ?? context.l10n.dtLockerNumber('${drone['lockerId']}');
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
                  icon: battery == null
                      ? Icons.battery_unknown
                      : _droneBatteryIcon(battery),
                  text: battery == null ? context.l10n.dtNoBatteryData : context.l10n.dtBatteryPercentPin(battery),
                  color: battery == null
                      ? opsMutedText
                      : _droneBatteryColor(battery),
                ),
                _MiniPill(
                  icon: Icons.person_outline,
                  text: technicianName?.isNotEmpty == true
                      ? technicianName!
                      : context.l10n.dtNotClaimed,
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
    final battery = _asInt(drone['batteryPercent']);
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
                  '${battery == null ? context.l10n.dtNoBatteryData : context.l10n.dtBatteryPercent(battery)}'
                  '${assignedToMe ? context.l10n.dtYouAreInCharge : ''}',
                  style: const TextStyle(fontSize: 12, color: opsMutedText),
                ),
                const SizedBox(height: 16),
                if (!assignedToMe)
                  tile(
                    Icons.assignment_ind_outlined,
                    context.l10n.dtClaimDrone,
                    opsPrimary,
                    () => _runCellAction(
                      () => _service.claimDrone(droneId),
                      context.l10n.dtClaimedDrone,
                    ),
                  ),
                if (assignedToMe)
                  tile(
                    Icons.assignment_return_outlined,
                    context.l10n.dtReleaseDrone,
                    const Color(0xFF6B7280),
                    () => _runCellAction(
                      () => _service.releaseDrone(droneId),
                      context.l10n.dtReleasedDrone,
                    ),
                  ),
                if (assignedToMe) ...[
                  tile(
                    Icons.sync_alt,
                    context.l10n.dtChangeStatus,
                    const Color(0xFF7C3AED),
                    // Drone đang bay: không đổi trạng thái tay, dẫn sang báo
                    // chuyến bay thất bại (server trả DRONE_IN_FLIGHT_USE_FAIL).
                    () => status == 'IN_FLIGHT'
                        ? _inFlightStatusGuide(drone)
                        : _changeDroneStatusFlow(drone),
                  ),
                  tile(
                    Icons.battery_charging_full,
                    context.l10n.dtUpdateBattery,
                    const Color(0xFF0891B2),
                    () => _updateDroneBatteryFlow(drone),
                  ),
                ],
                tile(
                  Icons.history_edu_outlined,
                  context.l10n.dtMaintenanceLog,
                  opsMutedText,
                  () => _droneLogSheet(drone, canWrite: assignedToMe),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Phiếu sự cố chưa hoàn tất của một drone — còn phiếu thì server không cho
  /// đưa drone về Sẵn sàng/Đang sạc (`DRONE_HAS_OPEN_REPORT`).
  List<Map<String, dynamic>> _openReportsForDrone(int droneId) => _droneReports
      .where(
        (r) =>
            _asInt(r['droneUnitId']) == droneId &&
            (r['status'] == 'OPEN' || r['status'] == 'IN_PROGRESS'),
      )
      .toList(growable: false);

  /// Nhiệm vụ đang bay của drone (theo id hoặc mã drone) trong hàng đợi.
  Map<String, dynamic>? _inFlightOrderFor(Map<String, dynamic> drone) {
    final id = _asInt(drone['id']);
    final code = '${drone['code'] ?? ''}';
    for (final order in _deliveries) {
      if (!_flightFailureStages.contains('${order['deliveryStage']}')) continue;
      final sameId = id != null && _asInt(order['droneUnitId']) == id;
      final sameCode = code.isNotEmpty && '${order['droneCode']}' == code;
      if (sameId || sameCode) return order;
    }
    return null;
  }

  Future<void> _inFlightStatusGuide(Map<String, dynamic> drone) async {
    final order = _inFlightOrderFor(drone);
    final canFail = order != null && _canReportFailure(order);
    final proceed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(context.l10n.dtDroneInFlightTitle),
        content: Text(context.l10n.dtDroneInFlightBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(context.l10n.commonClose),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              canFail ? context.l10n.dtReportFlightFailure : context.l10n.dtViewInFlightMission,
            ),
          ),
        ],
      ),
    );
    if (proceed != true || !mounted) return;
    if (canFail) {
      await _cancelDeliveryFlow(order, inFlight: true);
    } else {
      setState(() => _dispatchFilter = 'FLYING');
      _tabs.animateTo(0);
    }
  }

  /// Dialog chọn trạng thái mới cho drone; bắt nhập lý do khi chọn FAULT.
  Future<void> _changeDroneStatusFlow(Map<String, dynamic> drone) async {
    final droneId = _asInt(drone['id']);
    if (droneId == null) return;
    final reasonCtrl = TextEditingController();
    final currentStatus = drone['status'] as String? ?? 'IDLE';
    String selected = currentStatus;
    final openReports = _openReportsForDrone(droneId);

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
            title: Text(context.l10n.dtChangeDroneStatusTitle),
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
                        onSelected:
                            openReports.isNotEmpty &&
                                _operationalDroneStatuses.contains(s) &&
                                s != currentStatus
                            ? null
                            : (_) => setLocal(() => selected = s),
                      ),
                  ],
                ),
                if (openReports.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(
                    context.l10n.dtDroneHasOpenReports(
                      openReports.map((r) => 'RPT-${r['id']}').join(', '),
                    ),
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFFB45309),
                    ),
                  ),
                ],
                if (selected == 'FAULT') ...[
                  const SizedBox(height: 12),
                  TextField(
                    controller: reasonCtrl,
                    decoration: InputDecoration(
                      labelText: context.l10n.dtReasonRequired,
                      isDense: true,
                    ),
                  ),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(context.l10n.commonCancel),
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
                child: Text(context.l10n.commonConfirm),
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
          SnackBar(content: Text(context.l10n.dtStatusUnchanged)),
        );
      }
      return;
    }
    if (isFault && reason.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.dtFaultReasonRequired)),
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
      L10n.current.dtStatusChanged,
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
          title: Text(context.l10n.dtUpdateBattery),
          content: TextField(
            controller: ctrl,
            autofocus: true,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(labelText: context.l10n.dtBatteryRemaining),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(context.l10n.commonCancel),
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
              child: Text(context.l10n.commonSave),
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
          SnackBar(content: Text(context.l10n.dtBatteryRange)),
        );
      }
      return;
    }
    await _runCellAction(
      () => _service.updateDroneBattery(droneId, percent),
      L10n.current.dtBatteryUpdated,
    );
  }

  /// Mở nhật ký bảo trì của 1 drone để xem (+ thêm ghi chú khi đang phụ trách).
  Future<void> _droneLogSheet(
    Map<String, dynamic> drone, {
    required bool canWrite,
  }) async {
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
        canWrite: canWrite,
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
    required this.canWrite,
  });

  final int droneId;
  final LockerOpsService service;
  final String title;

  /// Chỉ KTV đang phụ trách drone mới ghi được nhật ký.
  final bool canWrite;

  @override
  State<_DroneLogSheet> createState() => _DroneLogSheetState();
}

class _DroneLogSheetState extends State<_DroneLogSheet> {
  final _noteCtrl = TextEditingController();
  List<Map<String, dynamic>> _logs = const [];
  bool _loading = true;
  bool _sending = false;
  String? _loadError;
  StreamSubscription<AppEvent>? _eventSub;

  @override
  void initState() {
    super.initState();
    _load();
    // KTV khác ghi nhật ký / admin đổi trạng thái drone này ⇒ tải ngầm.
    _eventSub = AppEventBus.instance.events.listen((event) {
      if (mounted &&
          !_sending &&
          event is MaintenanceChangedEvent &&
          event.isDrone &&
          event.id == '${widget.droneId}') {
        _load(silent: true);
      }
    });
  }

  @override
  void dispose() {
    _eventSub?.cancel();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _load({bool silent = false}) async {
    if (mounted && !silent) {
      setState(() {
        _loading = true;
        _loadError = null;
      });
    }
    try {
      final logs = await widget.service.droneLogs(widget.droneId);
      if (!mounted) return;
      setState(() {
        _logs = logs;
        _loading = false;
      });
    } catch (e) {
      if (!mounted || silent) return;
      setState(() {
        _loading = false;
        _loadError = droneTechnicianErrorMessage(e);
      });
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

  String _actorLabel(Map<String, dynamic> log) {
    final name = '${log['actorName'] ?? ''}'.trim();
    if (name.isNotEmpty) return ' · $name';
    return log['actorUserId'] != null ? context.l10n.dtTechnicianNumber('${log['actorUserId']}') : '';
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
                      context.l10n.dtMaintenanceLogTitle(widget.title),
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
                  : _loadError != null
                  ? Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            context.l10n.dtLogLoadFailed('$_loadError'),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 12.5,
                              color: Color(0xFFDC2626),
                            ),
                          ),
                          TextButton.icon(
                            onPressed: _load,
                            icon: const Icon(Icons.refresh_rounded, size: 18),
                            label: Text(context.l10n.commonRetry),
                          ),
                        ],
                      ),
                    )
                  : _logs.isEmpty
                  ? OpsEmptyState(
                      icon: Icons.history_edu_outlined,
                      title: context.l10n.dtLogEmptyTitle,
                      subtitle: widget.canWrite
                          ? context.l10n.dtLogEmptyCanWrite
                          : context.l10n.dtLogEmptyReadOnly,
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
                                '${_actorLabel(log)}',
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
            if (!widget.canWrite)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 14),
                child: Text(
                  context.l10n.dtLogReadOnlyHint,
                  style: const TextStyle(fontSize: 12, color: opsMutedText),
                ),
              )
            else
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
                          hintText: context.l10n.dtLogInputHint,
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
    required this.onChanged,
  });

  final int orderId;
  final LockerOpsService service;
  final ScrollController scrollController;

  /// Tải lại trang chủ sau thao tác trong sheet (vd. báo rơi kiện).
  final Future<void> Function() onChanged;

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
    // Chặng giao/nhiệm vụ/lượt lấy hàng của đơn này đổi ⇒ server đẩy tin
    // (`DRONE_ORDER`) và sheet tải ngay; vòng 15 giây chỉ phòng mất kết nối.
    _timer = Timer.periodic(const Duration(seconds: 15), (_) => _refresh());
    _events = AppEventBus.instance.events.listen((event) {
      if (event is OrderChangedEvent) _refresh();
      if (event is MaintenanceChangedEvent &&
          event.isDroneOrder &&
          event.id == '${widget.orderId}') {
        _refresh();
      }
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
        Text(
          context.l10n.dtMissionDetailTitle,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 4),
        Text(
          context.l10n.dtRealtimeUpdates,
          style: const TextStyle(fontSize: 12, color: opsMutedText),
        ),
        const SizedBox(height: 14),
        if (status != null) ...[
          if (status.status.toUpperCase() == _dropReportedStage) ...[
            OpsBanner(
              tone: OpsBannerTone.danger,
              icon: Icons.report_gmailerrorred_outlined,
              text: context.l10n.dtDropReportedBanner,
            ),
            const SizedBox(height: 14),
          ],
          if (status.stage.isInFlight) ...[
            DroneJourneyCameraPanel(
              orderId: widget.orderId,
              service: widget.service,
              onIncidentReported: () async {
                await _refresh();
                await widget.onChanged();
              },
            ),
            const SizedBox(height: 14),
          ],
          if (status.stage.needsRouteWeather) ...[
            DroneRouteWeatherCard(
              orderId: widget.orderId,
              asTechnician: true,
              load: (id) =>
                  widget.service.droneRouteWeather(id, asTechnician: true),
              refreshKey: status.status,
            ),
            const SizedBox(height: 14),
          ],
          DroneDeliveryDetail(status: status, forOperator: true),
        ] else if (_error != null)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 32),
            child: Column(
              children: [
                Text(_error!, textAlign: TextAlign.center),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: _refresh,
                  child: Text(context.l10n.commonRetry),
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

List<_DroneCancelReason> get _cancelReasons => [
  _DroneCancelReason(1, L10n.current.dtCancelReasonWeather),
  _DroneCancelReason(2, L10n.current.dtCancelReasonDroneFault),
  _DroneCancelReason(3, L10n.current.dtCancelReasonLandingPad),
  _DroneCancelReason(4, L10n.current.dtCancelReasonOperational),
  _DroneCancelReason(5, L10n.current.dtCancelReasonOther, requiresNote: true),
];

/// Trạng thái của 1 con drone vật lý (drone_units.status) — khác trạng thái
/// ô tủ cellType=DRONE ở trên.
const _droneStatuses = ['IDLE', 'CHARGING', 'MAINTENANCE', 'FAULT'];

/// Trạng thái vận hành: server chặn chuyển về đây khi drone còn phiếu mở.
const _operationalDroneStatuses = {'IDLE', 'CHARGING'};

/// Chặng của đơn đã báo rơi kiện (chưa có trong [DroneDeliveryStage]).
const _dropReportedStage = 'DROP_REPORTED';

/// Pin tối thiểu để nhận đơn — đọc từ cấu hình admin (`app.locker.drone-low-battery-percent`);
/// server vẫn kiểm lại và trả `DRONE_BATTERY_TOO_LOW`.
int get _minPreflightBatteryPercent =>
    BusinessConfigService.instance.current.droneLowBatteryPercent;

List<String> _manualDroneStatuses(String current) {
  // Drone đang có nhiệm vụ chỉ được báo lỗi; drone đang bay đi luồng báo
  // chuyến bay thất bại (xem _inFlightStatusGuide).
  if (current == 'RESERVED') return [current, 'FAULT'];
  if (current == 'IN_FLIGHT') return [current];
  return _droneStatuses;
}

String _droneStatusLabel(String? status) => switch (status) {
  'IDLE' => L10n.current.dtDroneStatusIdle,
  'RESERVED' => L10n.current.dtDroneStatusReserved,
  'CHARGING' => L10n.current.dtDroneStatusCharging,
  'IN_FLIGHT' => L10n.current.dtDroneStatusInFlight,
  'MAINTENANCE' => L10n.current.dtDroneStatusMaintenance,
  'FAULT' => L10n.current.dtDroneStatusFault,
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

class _PenaltyBadge extends StatelessWidget {
  const _PenaltyBadge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
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
          // Câu dài trên máy hẹp xuống dòng thay vì tràn phải. Không dùng Flexible:
          // pill có khi nằm trong Row (bề ngang không giới hạn).
          ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.sizeOf(context).width - 96,
            ),
            child: Text(
              text,
              style: TextStyle(
                fontSize: 11,
                color: color,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
