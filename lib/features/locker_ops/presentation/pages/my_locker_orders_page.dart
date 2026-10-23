import 'dart:async';
import 'package:smart_laundry_locker/core/services/app_event_bus.dart';
import 'package:smart_laundry_locker/core/utils/app_date_time.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:smart_laundry_locker/core/config/business_config_provider.dart';
import 'package:smart_laundry_locker/core/media/media.dart';
import 'package:smart_laundry_locker/core/routing/app_router.dart';
import 'package:smart_laundry_locker/features/drone_delivery/presentation/widgets/drone_order_cancel.dart';
import 'package:smart_laundry_locker/features/locker_ops/data/locker_ops_service.dart';
import 'package:smart_laundry_locker/features/locker_ops/data/order_milestone.dart';
import 'package:smart_laundry_locker/features/locker_ops/data/receiver_order.dart';
import 'package:smart_laundry_locker/features/locker_ops/domain/pickup_code_share.dart';
import 'package:smart_laundry_locker/features/locker_ops/presentation/pages/receiver_order_detail_page.dart';
import 'package:smart_laundry_locker/features/locker_ops/presentation/utils/business_rules_text.dart';
import 'package:smart_laundry_locker/features/locker_ops/presentation/utils/locker_maps.dart';
import 'package:smart_laundry_locker/features/locker_ops/presentation/widgets/delegate_order_dialog.dart';
import 'package:smart_laundry_locker/features/locker_ops/presentation/widgets/locker_unlock_modal.dart';
import 'package:smart_laundry_locker/features/locker_ops/presentation/widgets/loyalty_redeem_toggle.dart';
import 'package:smart_laundry_locker/features/locker_ops/presentation/widgets/ops_widgets.dart';
import 'package:smart_laundry_locker/features/locker_ops/presentation/widgets/order_detail_widgets.dart';
import 'package:smart_laundry_locker/features/locker_ops/presentation/widgets/order_feedback_section.dart';
import 'package:smart_laundry_locker/features/locker_ops/presentation/widgets/order_payment_sheet.dart';
import 'package:smart_laundry_locker/features/locker_ops/presentation/widgets/order_status_timeline.dart';
import 'package:smart_laundry_locker/features/locker_ops/presentation/widgets/pickup_code_share_actions.dart';
import 'package:smart_laundry_locker/features/locker_ops/presentation/widgets/receiver_order_card.dart';
import 'package:smart_laundry_locker/features/locker_ops/presentation/widgets/user_report_detail_sheet.dart';
import 'package:smart_laundry_locker/shared/widgets/user_ui_kit.dart';
import 'package:smart_laundry_locker/shared/shared.dart';

/// All locker orders of the signed-in customer, with the full action set gated
/// to the backend state machine: confirm drop, pickup/complete, delegate,
/// extend/end rental, report fault, cancel — plus "Hàng chờ nhận" (orders sent
/// to me, `GET /api/orders/incoming`).
class MyLockerOrdersPage extends StatefulWidget {
  const MyLockerOrdersPage({
    super.key,
    this.service,
    this.initialOrderId,
    this.initialTab,
    this.openToken,
    this.initialOrder,
  });

  final LockerOpsService? service;

  /// Deep link `/locker/my-orders?orderId=<id>`: mở chi tiết đơn này sau khi tải.
  final int? initialOrderId;

  /// `incoming` ⇒ mở thẳng mục "Hàng chờ nhận".
  final String? initialTab;

  /// Dấu hiệu mở lại chi tiết đơn khi ấn vào card đơn đang xử lý nhiều lần.
  final String? openToken;

  /// Dữ liệu đơn đã nạp sẵn (ví dụ truyền từ trang chủ) để mở ngay lập tức.
  final Map<String, dynamic>? initialOrder;

  @override
  State<MyLockerOrdersPage> createState() => _MyLockerOrdersPageState();
}

class _MyLockerOrdersPageState extends State<MyLockerOrdersPage>
    with BusinessConfigStateMixin {
  late final LockerOpsService _service = widget.service ?? LockerOpsService();
  List<Map<String, dynamic>> _orders = [];

  /// Sơ đồ ô (`boxId` → số ô in trên tủ) và bản ghi tủ theo `lockerId`. Giữ qua
  /// các lần tải lại: tủ không đổi theo từng đơn, chỉ tải lại khi có sự kiện cập
  /// nhật sơ đồ tủ hoặc khách bấm làm mới.
  final Map<int, Map<int, int>> _lockerBoxesMap = {};

  /// Bản ghi tủ đầy đủ theo `lockerId` (tên, địa chỉ, toạ độ) để bảng chi tiết hiện
  /// được địa điểm đặt tủ mà không phải gọi mạng thêm lần nữa.
  final Map<int, Map<String, dynamic>> _lockersMap = {};
  Map<int, Map<String, dynamic>> _activeReportsByBox = {};
  Map<int, Map<String, dynamic>> _latestReportByBox = {};

  /// Phiếu sự cố gắn với đơn theo trường có cấu trúc `orderId` / `orderCode` của
  /// `GET /api/lockers/my-reports` (không dò mã đơn trong ghi chú).
  Map<int, Map<String, dynamic>> _reportByOrderId = {};
  Map<String, Map<String, dynamic>> _reportByOrderCode = {};
  bool _loading = true;
  String _typeFilter = 'ALL';

  /// "Hàng chờ nhận" (đơn người khác gửi tới mình) tách khỏi "Đơn của tôi" —
  /// không phải đơn của mình nên không trộn vào các bộ lọc trạng thái/loại đơn.
  late bool _showIncoming = widget.initialTab == 'incoming';
  StreamSubscription<AppEvent>? _eventSub;

  List<ReceiverOrder> _incoming = const [];
  bool _incomingLoading = true;
  String? _incomingError;
  String _incomingFilter = 'ALL';
  bool _openedInitialOrder = false;
  String? _lastOpenedToken;
  int? _lastOpenedId;

  @override
  void initState() {
    super.initState();
    if (widget.initialOrderId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _openInitialOrderOnce();
      });
    }
    _load();
    _eventSub = AppEventBus.instance.events.listen((event) {
      if (!mounted) return;
      if (event is LockerLayoutUpdatedEvent) {
        _load(refreshLockers: true);
      } else if (event is OrderChangedEvent ||
          event is PaymentCompletedEvent ||
          event is PaymentFailedEvent) {
        _load();
      }
    });
  }

  @override
  void didUpdateWidget(covariant MyLockerOrdersPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    final hasNewToken =
        widget.openToken != null && widget.openToken != oldWidget.openToken;
    final hasNewId =
        widget.initialOrderId != null &&
        widget.initialOrderId != oldWidget.initialOrderId;
    if (hasNewToken || hasNewId) {
      _openedInitialOrder = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _openInitialOrderOnce();
      });
    }
  }

  @override
  void dispose() {
    _eventSub?.cancel();
    super.dispose();
  }

  Future<void> _refresh() => _load(refreshLockers: true);

  Future<void> _load({bool refreshLockers = false}) async {
    setState(() => _loading = true);
    final incomingDone = _loadIncoming();
    try {
      final orders = await _service.myOrders();
      // Phiếu sự cố chỉ để gắn cảnh báo lên đơn — lỗi tải phiếu không được làm
      // mất cả danh sách đơn.
      var reports = const <Map<String, dynamic>>[];
      try {
        reports = await _service.myReports();
      } catch (_) {}

      final lockerIds = <int>{};
      for (final o in orders) {
        final origin = _asInt(o['lockerId']);
        if (origin != null) lockerIds.add(origin);
        final dest = _asInt(o['destinationLockerId']);
        if (dest != null) lockerIds.add(dest);
        // Tủ gửi của đơn drone — chi tiết đơn hiện "Gửi từ tủ".
        final source = _asInt(o['sourceLockerId']);
        if (source != null) lockerIds.add(source);
      }
      if (refreshLockers) {
        _lockersMap.clear();
        _lockerBoxesMap.clear();
      }
      // Tải song song, mỗi tủ một lần; tủ đã có trong bộ nhớ thì bỏ qua.
      await Future.wait(
        lockerIds
            .where((id) => !_lockerBoxesMap.containsKey(id))
            .map(_loadLocker),
      );
      if (!mounted) return;

      final latestReportByBox = <int, Map<String, dynamic>>{};
      final reportByOrderId = <int, Map<String, dynamic>>{};
      final reportByOrderCode = <String, Map<String, dynamic>>{};
      for (final r in reports) {
        final bId = _asInt(r['boxId']);
        if (bId != null) latestReportByBox[bId] ??= r;
        final oId = _asInt(r['orderId']);
        if (oId != null) reportByOrderId[oId] ??= r;
        final code = r['orderCode']?.toString().trim().toUpperCase();
        if (code != null && code.isNotEmpty) reportByOrderCode[code] ??= r;
      }

      setState(() {
        _activeReportsByBox = _activeReportsByBoxMap(reports);
        _latestReportByBox = latestReportByBox;
        _reportByOrderId = reportByOrderId;
        _reportByOrderCode = reportByOrderCode;
        _orders = orders;
      });
    } catch (e) {
      _snack(LockerOpsService.errorMessage(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
    await incomingDone;
    _openInitialOrderOnce();
  }

  Future<void> _loadLocker(int lockerId) async {
    final results = await Future.wait([
      _service.locker(lockerId).then<Map<String, dynamic>?>((v) => v).catchError(
        (Object _) => null,
      ),
      _service.layout(lockerId).then<Map<String, dynamic>?>((v) => v).catchError(
        (Object _) => null,
      ),
    ]);
    final info = results[0];
    if (info != null) _lockersMap[lockerId] = info;
    final layout = results[1];
    if (layout == null) return;
    final map = <int, int>{};
    final cells = layout['cells'];
    if (cells is List) {
      for (final c in cells.whereType<Map>()) {
        final cId = _asInt(c['id']);
        final bNum = _asInt(c['boxNumber']);
        if (cId != null && bNum != null) map[cId] = bNum;
      }
    }
    _lockerBoxesMap[lockerId] = map;
  }

  /// "Hàng chờ nhận": lỗi chỉ hiện trong mục này, không ảnh hưởng đơn của mình.
  Future<void> _loadIncoming() async {
    if (mounted) setState(() => _incomingLoading = true);
    try {
      final raw = await _service.incomingOrders();
      if (!mounted) return;
      setState(() {
        _incoming = ReceiverOrder.listFrom(raw);
        _incomingError = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(
        () => _incomingError = LockerOpsService.isEndpointUnavailable(e)
            ? 'Máy chủ chưa hỗ trợ mục Hàng chờ nhận. Vui lòng thử lại sau.'
            : LockerOpsService.errorMessage(e),
      );
    } finally {
      if (mounted) setState(() => _incomingLoading = false);
    }
  }

  Future<void> _openInitialOrderOnce({bool canRetry = true}) async {
    final id = widget.initialOrderId;
    if (id == null || !mounted) return;
    if (_openedInitialOrder &&
        widget.openToken == _lastOpenedToken &&
        id == _lastOpenedId) {
      return;
    }

    final order = _orders.where((o) => _asInt(o['id']) == id).firstOrNull ??
        (widget.initialOrder != null && _asInt(widget.initialOrder!['id']) == id
            ? widget.initialOrder
            : null);
    if (order != null) {
      _openedInitialOrder = true;
      _lastOpenedToken = widget.openToken;
      _lastOpenedId = id;
      _openDetail(order);
      return;
    }
    // Đơn mình là người nhận (thông báo hàng tới) ⇒ mở mục Hàng chờ nhận và
    // chi tiết đơn đó.
    final incoming = _incoming.where((o) => o.id == id).firstOrNull;
    if (incoming != null) {
      _openedInitialOrder = true;
      _lastOpenedToken = widget.openToken;
      _lastOpenedId = id;
      setState(() => _showIncoming = true);
      _openIncomingDetail(incoming);
      return;
    }

    if (canRetry) {
      await _load();
      if (!mounted) return;
      return _openInitialOrderOnce(canRetry: false);
    }
    _openedInitialOrder = true;
    _lastOpenedToken = widget.openToken;
    _lastOpenedId = id;
    _snack('Không tìm thấy đơn trong danh sách của bạn.');
  }

  Future<void> _openIncomingDetail(ReceiverOrder order) async {
    await ReceiverOrderDetailPage.open(
      context,
      order: order,
      service: _service,
    );
    // Có thể đã mở ô lấy hàng trong màn chi tiết.
    if (mounted) await _loadIncoming();
  }

  int get _incomingReadyCount => _incoming.where((o) => o.isActive).length;

  bool _isIncomingRecent(ReceiverOrder o) {
    final d = _parseIncomingDate(o);
    if (d == null) return true;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(d.year, d.month, d.day);
    final diff = today.difference(day).inDays.abs();
    return diff <= 7;
  }

  int get _incomingCountRecent => _incoming.where(_isIncomingRecent).length;
  int get _incomingCountActive => _incoming.where((o) => o.isActive).length;
  int get _incomingCountCompleted =>
      _incoming.where((o) => o.status == 'COMPLETED').length;
  int get _incomingCountDrone => _incoming
      .where((o) => (o.type ?? '').toUpperCase() == 'DRONE_DELIVERY')
      .length;
  int get _incomingCountSend =>
      _incoming.where((o) => (o.type ?? '').toUpperCase() == 'SEND').length;
  int get _incomingCountCanceled => _incoming
      .where((o) => o.status == 'CANCELED' || o.status == 'CANCELLED')
      .length;

  void _setIncomingFilter(String key) {
    setState(() {
      _incomingFilter = (_incomingFilter == key && key != 'ALL') ? 'ALL' : key;
    });
  }

  List<ReceiverOrder> get _visibleIncoming {
    return _incoming.where((o) {
      return switch (_incomingFilter) {
        'ACTIVE' => o.isActive,
        'RECENT' => _isIncomingRecent(o),
        'COMPLETED' => o.status == 'COMPLETED',
        'DRONE' => (o.type ?? '').toUpperCase() == 'DRONE_DELIVERY',
        'SEND' => (o.type ?? '').toUpperCase() == 'SEND',
        'CANCELED' => o.status == 'CANCELED' || o.status == 'CANCELLED',
        'ALL' => true,
        _ => true,
      };
    }).toList();
  }

  static DateTime? _parseIncomingDate(ReceiverOrder o) {
    return o.createdAt ?? o.pickupDeadline ?? o.completedAt;
  }

  List<MapEntry<String, List<ReceiverOrder>>> get _groupedIncomingOrders {
    final visible = _visibleIncoming;
    if (visible.isEmpty) return const [];

    final withDates = visible
        .map((o) => (order: o, date: _parseIncomingDate(o)))
        .toList()
      ..sort((a, b) {
        if (a.date == null && b.date == null) return 0;
        if (a.date == null) return 1;
        if (b.date == null) return -1;
        return b.date!.compareTo(a.date!);
      });

    final map = <String, List<ReceiverOrder>>{};
    for (final item in withDates) {
      final key =
          item.date == null ? 'Không rõ ngày' : _dateGroupLabel(item.date!);
      (map[key] ??= []).add(item.order);
    }
    return map.entries.toList();
  }
  bool _isRecent(Map<String, dynamic> o) {
    final d = _parseOrderDate(o);
    if (d == null) return true;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(d.year, d.month, d.day);
    final diff = today.difference(day).inDays.abs();
    return diff <= 7;
  }

  bool _isActive(Map<String, dynamic> o) {
    final rawStatus = (o['status'] as String? ?? '').toUpperCase();
    return rawStatus.isNotEmpty &&
        rawStatus != 'COMPLETED' &&
        rawStatus != 'CANCELED';
  }

  bool _isCompleted(Map<String, dynamic> o) {
    final rawStatus = (o['status'] as String? ?? '').toUpperCase();
    return rawStatus == 'COMPLETED';
  }

  bool _isRental(Map<String, dynamic> o) {
    final type = (o['type'] as String? ?? '').toUpperCase();
    return type.contains('RENT');
  }

  bool _isSend(Map<String, dynamic> o) {
    final type = o['type'] as String?;
    return _isDeliveryOrder(type);
  }

  bool _isCanceled(Map<String, dynamic> o) {
    final rawStatus = (o['status'] as String? ?? '').toUpperCase();
    return rawStatus == 'CANCELED';
  }

  int get _countRecent => _orders.where(_isRecent).length;
  int get _countActive => _orders.where(_isActive).length;
  int get _countCompleted => _orders.where(_isCompleted).length;
  int get _countRental => _orders.where(_isRental).length;
  int get _countSend => _orders.where(_isSend).length;
  int get _countCanceled => _orders.where(_isCanceled).length;

  void _setFilter(String key) {
    setState(() {
      _typeFilter = (_typeFilter == key && key != 'ALL') ? 'ALL' : key;
    });
  }

  String get _emptySubtitle => switch (_typeFilter) {
    'RECENT' => 'Không có đơn hàng nào trong 7 ngày gần đây.',
    'ACTIVE' => 'Hiện không có đơn hàng nào đang trong quá trình sử dụng.',
    'COMPLETED' => 'Chưa có đơn hàng nào đã hoàn tất.',
    'RENTAL' => 'Chưa có đơn thuê tủ nào.',
    'SEND' => 'Chưa có đơn gửi hàng nào.',
    'CANCELED' => 'Không có đơn nào đã hủy.',
    _ => 'Tạo đơn Gửi hàng hoặc Thuê tủ từ màn hình chính.',
  };

  List<Map<String, dynamic>> get _visible {
    return _orders.where((o) {
      return switch (_typeFilter) {
        'RECENT' => _isRecent(o),
        'ACTIVE' => _isActive(o),
        'COMPLETED' => _isCompleted(o),
        'RENTAL' => _isRental(o),
        'SEND' => _isSend(o),
        'CANCELED' => _isCanceled(o),
        'ALL' => true,
        _ => true,
      };
    }).toList();
  }

  Map<String, dynamic>? _activeReportForOrder(Map<String, dynamic> order) {
    final rawStatus = (order['status'] as String? ?? '').toUpperCase();
    // Đơn đã hủy hoặc đã hoàn tất trong quá khứ KHÔNG BAO GIỜ nhận sự cố đang mở của ô tủ!
    if (rawStatus == 'CANCELED' || rawStatus == 'COMPLETED') return null;

    final isPickup = rawStatus == 'STORING' || rawStatus == 'RETURNED';
    final boxId = isPickup
        ? _asInt(order['receiveBoxId'] ?? order['sendBoxId'])
        : _asInt(order['sendBoxId'] ?? order['receiveBoxId']);
    if (boxId == null) return null;
    final rep = _activeReportsByBox[boxId];
    if (rep == null) return null;
    if (_isReportApplicableToOrder(rep, order)) {
      return rep;
    }
    return null;
  }

  /// Kiểm tra xem phiếu sự cố có thực sự liên quan đến đơn hàng này hay không.
  /// 1. Nếu phiếu có orderCode hoặc orderId cụ thể, bắt buộc phải trùng khớp với đơn hàng.
  /// 2. Nếu phiếu đã RESOLVED/CLOSED, đơn hàng bắt buộc phải được tạo TRƯỚC thời điểm
  ///    sự cố được xử lý xong. Đơn tạo mới sau khi sự cố đã xong sẽ bị bỏ qua.
  bool _isReportApplicableToOrder(
    Map<String, dynamic> report,
    Map<String, dynamic> order,
  ) {
    // Nếu phiếu có gắn mã đơn cụ thể từ backend
    final reportOrderCode = report['orderCode']?.toString().trim();
    final currentOrderCode = order['orderCode']?.toString().trim();
    if (reportOrderCode != null &&
        reportOrderCode.isNotEmpty &&
        currentOrderCode != null &&
        currentOrderCode.isNotEmpty) {
      if (reportOrderCode.toUpperCase() != currentOrderCode.toUpperCase()) {
        return false;
      }
    }

    final reportOrderId = _asInt(report['orderId']);
    final currentOrderId = _asInt(order['id']);
    if (reportOrderId != null && currentOrderId != null) {
      if (reportOrderId != currentOrderId) {
        return false;
      }
    }

    final reportStatus = (report['status'] as String? ?? 'OPEN').toUpperCase();
    final isResolved = reportStatus == 'RESOLVED' || reportStatus == 'CLOSED';

    // Nếu sự cố đang mở (OPEN/IN_PROGRESS), đơn hàng đang nằm ở ô đó đều bị ảnh hưởng
    if (!isResolved) return true;

    final orderDate = _parseOrderDate(order);
    final resolvedAt = parseServerDateTime(report['resolvedAt']) ??
        parseServerDateTime(report['updatedAt']) ??
        parseServerDateTime(report['createdAt']);

    if (orderDate != null && resolvedAt != null) {
      // Đơn hàng được tạo SAU KHI sự cố đã được xử lý xong -> không liên quan
      if (orderDate.isAfter(resolvedAt)) {
        return false;
      }
    }

    return true;
  }

  /// Tra cứu phiếu sự cố gắn liền với đơn hàng (ưu tiên phiếu theo mã đơn,
  /// sau đó phiếu đang mở, nếu không có thì lấy phiếu sự cố đã xử lý mới nhất của ô tủ).
  Map<String, dynamic>? _incidentReportForOrder(Map<String, dynamic> order) {
    final orderId = _asInt(order['id']);
    final byId = orderId == null ? null : _reportByOrderId[orderId];
    if (byId != null) return byId;
    final code = order['orderCode']?.toString().trim().toUpperCase();
    if (code != null && code.isNotEmpty) {
      final byCode = _reportByOrderCode[code];
      if (byCode != null) return byCode;
    }

    final rawStatus = (order['status'] as String? ?? '').toUpperCase();
    // Đơn đã hủy hoặc đã hoàn tất trong quá khứ KHÔNG NHẬN sự cố của ô tủ
    if (rawStatus == 'CANCELED' || rawStatus == 'COMPLETED') {
      return null;
    }

    final active = _activeReportForOrder(order);
    if (active != null) return active;

    final isPickup = rawStatus == 'STORING' || rawStatus == 'RETURNED';
    final boxId = isPickup
        ? _asInt(order['receiveBoxId'] ?? order['sendBoxId'])
        : _asInt(order['sendBoxId'] ?? order['receiveBoxId']);
    if (boxId != null && _latestReportByBox.containsKey(boxId)) {
      final rep = _latestReportByBox[boxId]!;
      if (_isReportApplicableToOrder(rep, order)) {
        return rep;
      }
    }
    final otherBoxId = isPickup
        ? _asInt(order['sendBoxId'])
        : _asInt(order['receiveBoxId']);
    if (otherBoxId != null && _latestReportByBox.containsKey(otherBoxId)) {
      final rep = _latestReportByBox[otherBoxId]!;
      if (_isReportApplicableToOrder(rep, order)) {
        return rep;
      }
    }
    return null;
  }

  /// Số ô in trên tủ, tra từ sơ đồ tủ đã tải. Dùng cho MỌI câu thông báo cho người
  /// dùng: `boxId` là mã nội bộ, nói "ô 701" thì người ta ra tủ không tìm thấy ô nào.
  String _boxLabelFor(Map<String, dynamic> order, int? boxId) {
    final rawStatus = (order['status'] as String? ?? '').toUpperCase();
    final isPickup = rawStatus == 'STORING' || rawStatus == 'RETURNED';
    final lockerId = isPickup
        ? _asInt(order['destinationLockerId'] ?? order['lockerId'])
        : _asInt(order['lockerId'] ?? order['destinationLockerId']);
    final number = (lockerId == null || boxId == null)
        ? null
        : _lockerBoxesMap[lockerId]?[boxId];
    return number == null ? 'ô này' : 'ô số $number';
  }

  static DateTime? _parseOrderDate(Map<String, dynamic> o) {
    final raw = o['createdAt'] ?? o['updatedAt'] ?? o['pickupDeadline'];
    if (raw == null) return null;
    return parseServerDateTime(raw);
  }

  static String _dateGroupLabel(DateTime d) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(d.year, d.month, d.day);
    final diff = today.difference(day).inDays;
    if (diff == 0) return 'Hôm nay';
    if (diff == 1) return 'Hôm qua';
    return '${d.day} tháng ${d.month}, ${d.year}';
  }

  /// Orders grouped by date label, sorted newest-first within each group.
  List<MapEntry<String, List<Map<String, dynamic>>>> get _groupedOrders {
    final visible = _visible;
    if (visible.isEmpty) return const [];

    final withDates = visible
        .map((o) => (order: o, date: _parseOrderDate(o)))
        .toList()
      ..sort((a, b) {
        if (a.date == null && b.date == null) return 0;
        if (a.date == null) return 1;
        if (b.date == null) return -1;
        return b.date!.compareTo(a.date!);
      });

    final map = <String, List<Map<String, dynamic>>>{};
    for (final item in withDates) {
      final key = item.date == null ? 'Không rõ ngày' : _dateGroupLabel(item.date!);
      (map[key] ??= []).add(item.order);
    }
    return map.entries.toList();
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _runAction(
    Future<Map<String, dynamic>> Function() fn,
    String ok,
  ) async {
    try {
      await fn();
      _snack(ok);
      await _load();
    } catch (e) {
      _snack(LockerOpsService.errorMessage(e));
    }
  }

  /// Đơn drone: hỏi xác nhận và báo rõ việc hoàn tiền, giống màn theo dõi drone.
  Future<void> _cancelDroneOrder(Map<String, dynamic> order, int orderId) async {
    final message = await confirmAndCancelDroneOrder(
      context,
      orderId: orderId,
      orderCode: order['orderCode']?.toString(),
      isPaid: '${order['paymentStatus']}'.toUpperCase() == 'PAID',
      totalPrice: _asDouble(order['totalPrice']),
      cancelOrder: _service.cancelOrder,
    );
    if (message == null || !mounted) return;
    _snack(message);
    await _load();
  }

  /// Đơn gửi hàng / thuê tủ: hỏi xác nhận trước khi huỷ như đơn drone. Huỷ ở đây
  /// không tự hoàn tiền, nên đơn đã trả được nhắc gửi yêu cầu hoàn tiền sau đó.
  Future<bool> _confirmCancelOrder(Map<String, dynamic> order) async {
    final code = order['orderCode']?.toString();
    final isPaid = '${order['paymentStatus']}'.toUpperCase() == 'PAID';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Huỷ đơn?'),
        content: Text(
          'Đơn ${code ?? ''} sẽ bị huỷ, mã mở ô hết hiệu lực và ô đang giữ được nhả.'
          '${isPaid ? ' Tiền đã thanh toán không tự hoàn — sau khi huỷ, mở lại đơn và chọn "Yêu cầu hoàn tiền".' : ''}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Giữ đơn'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Huỷ đơn'),
          ),
        ],
      ),
    );
    return confirmed == true && mounted;
  }

  Future<void> _extendDialog(int orderId) async {
    // Giới hạn gia hạn do admin cấu hình; làm mới nền để lần sau dùng giá trị
    // mới nhất mà không bắt người dùng chờ mạng.
    businessConfigService.refresh();
    final config = businessConfig;
    final maxHours = config.extendMaxHours;
    var hours = config.extendDefaultHours.clamp(1, maxHours).toDouble();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text('Gia hạn thuê'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Thêm ${hours.round()} giờ',
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                  color: opsDark,
                ),
              ),
              if (maxHours > 1)
                Slider(
                  value: hours,
                  min: 1,
                  max: maxHours.toDouble(),
                  divisions: maxHours - 1,
                  activeColor: opsPrimary,
                  label: '${hours.round()}h',
                  onChanged: (v) => setSheet(() => hours = v),
                ),
              Text(
                'Tối đa $maxHours giờ mỗi lần gia hạn',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12, color: opsMutedText),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Hủy'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Gia hạn'),
            ),
          ],
        ),
      ),
    );
    if (confirmed == true) {
      await _runAction(
        () => _service.extendRental(orderId, hours.round()),
        'Đã gia hạn ${hours.round()} giờ',
      );
    }
  }

  Future<void> _reportDialog({
    required int orderId,

    /// Nhãn ô cho người đọc (`ô số 4`), đã tra sẵn từ sơ đồ tủ.
    String boxLabel = 'ô này',
  }) async {
    final reasonCtrl = TextEditingController();
    // Ảnh hiện trường stage REPORT — tối đa theo cấu hình admin.
    final photos = PhotoPickerController(
      maxPhotos: businessConfig.reportPhotosPerRequestReporter,
    );
    // Trạng thái dialog giữ ngoài builder để không bị reset khi dialog rebuild
    // (vd. bàn phím bật lên).
    var uploading = false;
    String? dialogError;
    List<Map<String, dynamic>> attachments = const [];
    final confirmed = await showDialog<bool>(
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
            title: const Text('Báo ô lỗi'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: reasonCtrl,
                    maxLines: 3,
                    enabled: !uploading,
                    decoration: const InputDecoration(
                      hintText: 'Mô tả sự cố (ô không mở, kẹt cửa...)',
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Ảnh hiện trường (không bắt buộc, tối đa '
                    '${photos.maxPhotos})',
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: opsDark,
                    ),
                  ),
                  const SizedBox(height: 8),
                  PhotoPickerField(
                    controller: photos,
                    enabled: !uploading,
                    thumbSize: 64,
                    accentColor: AislBrand.navy,
                    helperText: 'Ảnh giúp đội bảo trì xử lý nhanh hơn.',
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
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFDC2626),
                ),
                onPressed: uploading
                    ? null
                    : () async {
                        if (reasonCtrl.text.trim().isEmpty && photos.isEmpty) {
                          setLocal(
                            () => dialogError =
                                'Vui lòng mô tả sự cố hoặc đính kèm ảnh.',
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
                child: Text(uploading ? 'Đang tải ảnh...' : 'Gửi báo lỗi'),
              ),
            ],
          ),
        ),
      ),
    );
    final reason = reasonCtrl.text.trim();
    if (confirmed == true && (reason.isNotEmpty || attachments.isNotEmpty)) {
      try {
        await _service.reportOrderFault(
          orderId,
          reason.isNotEmpty ? reason : 'Ô tủ gặp sự cố (xem ảnh đính kèm)',
          attachments: attachments,
        );
        await _load();
        if (!mounted) return;
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(
                'Đã gửi báo lỗi cho $boxLabel — đội bảo trì sẽ xử lý',
              ),
              action: SnackBarAction(
                label: 'Xem',
                onPressed: () => context.push(AppRouter.myLockerReports),
              ),
            ),
          );
      } catch (e) {
        _snack(LockerOpsService.errorMessage(e));
      }
    }
  }

  Future<void> _showRentalCompletionGuide(Map<String, dynamic> order) async {
    final orderId = _asInt(order['id']);
    final pin = order['pinCode'] as String?;
    final qrToken = order['qrToken'] as String?;
    if (orderId == null) return;

    final boxId = _asInt(order['sendBoxId'] ?? order['receiveBoxId']);
    final boxLabel = _boxLabelFor(order, boxId);

    await showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (ctx) => SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Lấy đồ tại kiosk',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 18,
                color: opsDark,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Dùng mã này tại kiosk để mở ô, lấy đồ ra, rồi đóng cửa tủ lại trước khi xác nhận kết thúc thuê. Bạn cũng có thể bấm mở trực tiếp trên app nếu đang ở gần tủ.',
              style: TextStyle(fontSize: 14, color: opsMutedText, height: 1.45),
            ),
            const SizedBox(height: 16),
            OpsSheetAction(
              label: 'Mở $boxLabel trên điện thoại (GPS/QR)',
              icon: LucideIcons.doorOpen,
              primary: true,
              onTap: () {
                Navigator.pop(ctx);
                _openLockerFlow(order, isRentalReturning: true);
              },
            ),
            if ((pin != null && pin.isNotEmpty) ||
                (qrToken != null && qrToken.isNotEmpty)) ...[
              const SizedBox(height: 16),
              Center(
                child: AccessCredentials(pin: pin, qrToken: qrToken),
              ),
            ],
            const SizedBox(height: 16),
            OpsSheetAction(
              label: 'Đã lấy đồ và đóng tủ',
              icon: LucideIcons.circleCheck,
              primary: false,
              onTap: () {
                Navigator.pop(ctx);
                _runAction(
                  () => _service.endRental(orderId),
                  'Đã kết thúc kỳ thuê',
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Bản ghi tủ của đơn, `null` khi chưa tải được.
  Map<String, dynamic>? _lockerOf(Map<String, dynamic> order) {
    final rawStatus = (order['status'] as String? ?? '').toUpperCase();
    final isPickup = rawStatus == 'STORING' || rawStatus == 'RETURNED';
    final lockerId = isPickup
        ? _asInt(order['destinationLockerId'] ?? order['lockerId'])
        : _asInt(order['lockerId'] ?? order['destinationLockerId']);
    return _lockersMap[lockerId] ?? (order['locker'] as Map<String, dynamic>?);
  }

  String? _lockerNameOf(Map<String, dynamic> order) =>
      _lockerOf(order)?['name']?.toString() ??
      order['lockerName']?.toString();

  Future<void> _openLockerDirections(Map<String, dynamic> order) async {
    final rawStatus = (order['status'] as String? ?? '').toUpperCase();
    final isPickup = rawStatus == 'STORING' || rawStatus == 'RETURNED';
    final lockerId = isPickup
        ? _asInt(order['destinationLockerId'] ?? order['lockerId'])
        : _asInt(order['lockerId'] ?? order['destinationLockerId']);
    if (lockerId == null) {
      _snack('Đơn chưa có thông tin tủ.');
      return;
    }
    try {
      // Dùng bản ghi đã tải nếu có; chỉ gọi mạng khi cache chưa có tủ này.
      final locker = _lockersMap[lockerId] ?? await _service.locker(lockerId);
      final result = await openLockerDirectionsResult(
        latitude: _asDouble(locker['latitude']),
        longitude: _asDouble(locker['longitude']),
        address: locker['address']?.toString(),
      );
      switch (result) {
        case DirectionsResult.opened:
          break;
        case DirectionsResult.noLocation:
          _snack('Tủ chưa có vị trí để chỉ đường.');
        case DirectionsResult.launchFailed:
          _snack('Không mở được ứng dụng bản đồ trên máy này.');
      }
    } catch (e) {
      _snack(LockerOpsService.errorMessage(e));
    }
  }

  /// Chọn phương thức rồi thanh toán; chỉ báo thành công khi server đã ghi
  /// nhận đơn PAID (bước bỏ hàng phụ thuộc vào trạng thái đó).
  Future<void> _payDialog(Map<String, dynamic> order) async {
    final orderId = _asInt(order['id']);
    if (orderId == null) return;
    // Thu phần còn thiếu, không thu lại phần khách đã trả (gia hạn/phí quá hạn).
    final total = orderAmountDue(order);

    // Làm mới nền danh sách phương thức admin bật (trong TTL thì không gọi mạng).
    businessConfigService.refresh();

    final isRental = ('${order['type']}'.toUpperCase() == 'RENTAL');
    final paidAmount = _asDouble(order['paidAmount']) ?? 0;
    final isRentalExtension = isRental && paidAmount > 0;
    final description = isRentalExtension
        ? 'Thanh toán gia hạn thời gian đơn #$orderId'
        : null;

    try {
      final outcome = await payOrderAndAwaitPaid(
        context,
        service: _service,
        orderId: orderId,
        total: total,
        description: description,
      );
      if (!mounted || outcome == OrderPaymentOutcome.cancelled) return;
      if (outcome == OrderPaymentOutcome.paid) {
        showPaymentResultDialog<void>(
          context,
          type: PaymentStatusType.success,
          title: 'Thanh toán thành công!',
          amountText: '${total.toInt()} đ',
          message: 'Đơn hàng của bạn đã được thanh toán thành công.',
        );
      } else if (outcome == OrderPaymentOutcome.failed) {
        showPaymentResultDialog<void>(
          context,
          type: PaymentStatusType.failure,
          title: 'Thanh toán thất bại',
          amountText: '${total.toInt()} đ',
          message: 'Giao dịch chưa hoàn tất hoặc đã bị hủy. Vui lòng thử lại.',
        );
      } else {
        _snack(
          'Đang chờ xác nhận thanh toán — kéo xuống để làm mới sau ít phút.',
        );
      }
      await _load();
    } catch (e) {
      _snack(LockerOpsService.errorMessage(e));
    }
  }

  /// Thanh toán phần còn nợ (nếu có) rồi chốt đơn đã lấy đồ (đơn quá hạn/hết hạn).
  /// Chỉ chốt đơn khi server đã ghi nhận PAID; mọi lỗi hiện đúng câu server trả.
  Future<void> _payAndCompleteFlow(Map<String, dynamic> order) async {
    final orderId = _asInt(order['id']);
    if (orderId == null) return;

    // Cập nhật phí quá hạn trước khi tính tiền; lỗi thì dùng số liệu đang có.
    try {
      final assessed = await _service.assessOvertime(orderId);
      if (assessed.isNotEmpty) {
        order = assessed;
      }
    } catch (_) {}

    if (!mounted) return;

    final due = orderAmountDue(order);
    final paymentStatus =
        (order['paymentStatus'] as String? ?? 'UNPAID').toUpperCase();
    final needsPayment = paymentStatus != 'PAID' && due > 0;

    if (needsPayment) {
      businessConfigService.refresh();
      final OrderPaymentOutcome outcome;
      try {
        outcome = await payOrderAndAwaitPaid(
          context,
          service: _service,
          orderId: orderId,
          total: due,
        );
      } catch (e) {
        _snack(LockerOpsService.errorMessage(e));
        return;
      }
      if (!mounted || outcome == OrderPaymentOutcome.cancelled) return;
      if (outcome == OrderPaymentOutcome.failed) {
        showPaymentResultDialog<void>(
          context,
          type: PaymentStatusType.failure,
          title: 'Thanh toán thất bại',
          amountText: fmtPrice(due),
          message: 'Giao dịch chưa hoàn tất hoặc đã bị hủy. Vui lòng thử lại.',
        );
        await _load();
        return;
      }
      if (outcome == OrderPaymentOutcome.pending) {
        // Chưa có xác nhận PAID thì chưa chốt đơn — server cũng sẽ từ chối.
        _snack(
          'Đang chờ xác nhận thanh toán — bấm lại "Xác nhận lấy đồ" sau khi '
          'đơn hiện Đã thanh toán.',
        );
        await _load();
        return;
      }
    } else {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: const Row(
            children: [
              Icon(LucideIcons.packageCheck, color: Color(0xFF16A34A)),
              SizedBox(width: 8),
              Text(
                'Xác nhận lấy đồ',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17),
              ),
            ],
          ),
          content: const Text(
            'Bạn xác nhận đã nhận lại đầy đủ đồ đạc của đơn hàng này? Thao tác này sẽ đóng và hoàn tất đơn hàng.',
            style: TextStyle(fontSize: 14, height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Hủy', style: TextStyle(color: opsMutedText)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF16A34A),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Đã lấy đồ — Hoàn tất'),
            ),
          ],
        ),
      );
      if (confirm != true || !mounted) return;
    }

    try {
      await _completeOrder(order, orderId);
      if (!mounted) return;
      if (needsPayment) {
        showPaymentResultDialog<void>(
          context,
          type: PaymentStatusType.success,
          title: 'Hoàn tất đơn hàng!',
          amountText: fmtPrice(due),
          message: 'Bạn đã thanh toán và lấy đồ thành công. Đơn hàng đã hoàn tất.',
        );
      } else {
        _snack('Đã nhận đồ — đơn hoàn tất');
      }
    } catch (e) {
      if (!mounted) return;
      final reason = LockerOpsService.errorMessage(e);
      if (needsPayment) {
        // Tiền đã nhận nhưng chốt đơn lỗi: nói đúng hai việc, không hứa thay ai.
        await showDialog<void>(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            title: const Text('Đã thanh toán — chưa hoàn tất đơn'),
            content: Text(
              'Hệ thống đã ghi nhận thanh toán nhưng chưa hoàn tất được đơn: '
              '$reason\nBạn có thể thử lại "Xác nhận lấy đồ" hoặc gửi khiếu nại '
              'trong chi tiết đơn.',
              style: const TextStyle(fontSize: 14, height: 1.4),
            ),
            actions: [
              FilledButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Đã hiểu'),
              ),
            ],
          ),
        );
      } else {
        _snack(reason);
      }
    }
    await _load();
  }

  /// Chốt đơn đã lấy đồ: đơn thuê kết thúc kỳ thuê, đơn khác hoàn tất.
  Future<void> _completeOrder(Map<String, dynamic> order, int orderId) async {
    final isRental =
        (order['type'] as String? ?? '').toUpperCase() == 'RENTAL';
    if (!isRental) {
      await _service.completePickup(orderId);
      return;
    }
    try {
      await _service.endRental(orderId);
    } catch (_) {
      // Đơn thuê đã hết hạn lưu tủ có thể không còn ở bước "kết thúc thuê":
      // thử hoàn tất thường; vẫn lỗi thì lỗi đó được báo cho khách.
      await _service.completePickup(orderId);
    }
  }

  /// Thanh toán phí quá giờ để mở ô (Pay-to-Unlock): xem bảng kê, chọn phương
  /// thức admin đang bật, chỉ mở ô khi server đã ghi nhận PAID.
  Future<void> _payOvertimeFlow(Map<String, dynamic> order, num fee) async {
    final orderId = _asInt(order['id']);
    if (orderId == null) return;

    var assessedOk = false;
    try {
      final assessed = await _service.assessOvertime(orderId);
      if (assessed.isNotEmpty) {
        order = assessed;
        assessedOk = true;
      }
    } catch (_) {}

    if (!mounted) return;

    // Số tiền thu = phần còn nợ server tính sau khi áp phí quá hạn. Không gọi
    // được assess thì dùng phí tạm tính để hiện; server vẫn tự tính tiền thật.
    final due = assessedOk ? orderAmountDue(order) : fee.toDouble();
    if (due <= 0) {
      _snack('Đơn hàng không có phí quá giờ cần thanh toán');
      return;
    }
    final lockerName = _lockerNameOf(order) ?? 'Tủ Lock.R';
    final boxId = _asInt(order['receiveBoxId'] ?? order['sendBoxId']);
    final boxLabel = _boxLabelFor(order, boxId);
    final deadline = order['pickupDeadline'];
    final durationText = fmtOverdueDuration(deadline);
    final config = businessConfig;

    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (ctx) => _PayOvertimeConfirmationSheet(
        order: order,
        amountDue: due,
        lockerName: lockerName,
        boxLabel: boxLabel,
        overdueDurationText: durationText.isNotEmpty
            ? durationText
            : 'Đã quá hạn',
        overtimeRate: overtimeRateOf(order, config),
        overtimeCapped: overtimeCappedOf(order),
      ),
    );
    if (confirmed != true || !mounted) return;

    if (due > 0 &&
        (order['paymentStatus'] as String? ?? '').toUpperCase() != 'PAID') {
      businessConfigService.refresh();
      final OrderPaymentOutcome outcome;
      try {
        outcome = await payOrderAndAwaitPaid(
          context,
          service: _service,
          orderId: orderId,
          total: due,
          description: 'Phí quá hạn',
        );
      } catch (e) {
        _snack(LockerOpsService.errorMessage(e));
        return;
      }
      if (!mounted || outcome == OrderPaymentOutcome.cancelled) return;
      if (outcome == OrderPaymentOutcome.failed) {
        showPaymentResultDialog<void>(
          context,
          type: PaymentStatusType.failure,
          title: 'Thanh toán thất bại',
          amountText: fmtPrice(due),
          message: 'Giao dịch chưa hoàn tất hoặc đã bị hủy. Vui lòng thử lại.',
        );
        await _load();
        return;
      }
      if (outcome == OrderPaymentOutcome.pending) {
        _snack(
          'Đang chờ xác nhận thanh toán — mở ô sau khi đơn hiện Đã thanh toán.',
        );
        await _load();
        return;
      }
      _snack('Đã thanh toán phí quá giờ — chuẩn bị mở ô');
    }

    await _load();
    if (!mounted) return;
    final updated = _orders.firstWhere(
      (o) => _asInt(o['id']) == orderId,
      orElse: () => order,
    );
    _openLockerFlow(updated);
  }

  /// Thực hiện mở khóa vật lý qua backend IoT
  Future<void> _doPhysicalUnlock(
    int lockerId,
    int boxId,
    String pin,
    String boxLabel,
    Map<String, dynamic> order,
  ) async {
    _snack('Đang gửi lệnh mở $boxLabel tới tủ...');
    try {
      final res = await _service.unlock(lockerId, boxId, pin);
      final accepted = res['accepted'] == true;
      final msg = res['message']?.toString();
      _snack(
        accepted
            ? 'Tủ đã mở $boxLabel — mời bạn thao tác rồi đóng cửa.'
            : 'Không mở được $boxLabel${msg != null && msg.isNotEmpty ? ': $msg' : ''}',
      );
      if (accepted) {
        await _load();
      }
    } catch (e) {
      _snack(LockerOpsService.errorMessage(e));
    }
  }

  /// Gửi lệnh mở ô của đơn xuống cabinet qua mô hình Hybrid (GPS Geofencing + Quét QR).
  Future<void> _openLockerFlow(
    Map<String, dynamic> order, {
    bool isRentalReturning = false,
  }) async {
    final rawStatus = (order['status'] as String? ?? '').toUpperCase();
    final type = (order['type'] as String? ?? '').toUpperCase();
    final isRental = type == 'RENTAL';
    final isPickupPhase = rawStatus == 'STORING' || rawStatus == 'RETURNED';

    final lockerId = isPickupPhase
        ? _asInt(order['destinationLockerId'] ?? order['lockerId'])
        : _asInt(order['lockerId'] ?? order['destinationLockerId']);

    final boxId = isPickupPhase
        ? _asInt(order['receiveBoxId'] ?? order['sendBoxId'])
        : _asInt(order['sendBoxId'] ?? order['receiveBoxId']);

    final pin = order['pinCode'] as String?;
    if (lockerId == null || boxId == null || pin == null || pin.isEmpty) {
      _snack('Đơn chưa có thông tin ô/PIN để mở tủ.');
      return;
    }
    final boxLabel = _boxLabelFor(order, boxId);

    // Lấy thông tin tủ đầy đủ (mã tủ, tên)
    Map<String, dynamic>? locker = _lockersMap[lockerId];
    if (locker == null) {
      try {
        locker = await _service.locker(lockerId);
      } catch (_) {}
    }
    final lockerName = locker?['name']?.toString() ?? 'Tủ Lock.R';
    final lockerCode = locker?['code']?.toString() ?? '';

    if (!mounted) return;

    final deadline = order['pickupDeadline'];
    final overdue =
        isOverdue(deadline) &&
        rawStatus != 'COMPLETED' &&
        rawStatus != 'CANCELED';

    // Hiển thị Modal 3 phương thức mở tủ:
    // 1. Bluetooth BLE (Proximity 1-chạm kèm chế độ Mô phỏng RPi)
    // 2. Quét tem mã QR trên thân tủ
    // 3. Xem mã PIN / OTP nhập trực tiếp tại màn hình Kiosk
    final action = await LockerUnlockModal.show(
      context,
      lockerName: lockerName,
      lockerCode: lockerCode,
      lockerId: lockerId,
      boxId: boxId,
      boxLabel: boxLabel,
      pinCode: pin,
      isRentalReturning: isRentalReturning && isRental && rawStatus == 'STORING',
      isOverdue: overdue,
      overdueNotice: overdue
          ? 'Đơn thuê đã quá hạn. Đã ghi nhận xử lý phí quá giờ — mời bạn mở ô lấy đồ và đóng tủ để hoàn tất.'
          : null,
    );

    if (action == null || !mounted) return;

    if (action.type == LockerUnlockActionType.openViaBle ||
        action.type == LockerUnlockActionType.openViaQr) {
      await _doPhysicalUnlock(lockerId, boxId, pin, boxLabel, order);
    }
  }

  /// "Ủy quyền lấy hộ": server đổi PIN và người được ủy quyền thấy đơn ở mục
  /// "Đơn ủy quyền" của họ.
  Future<void> _delegateOrder(int orderId) async {
    final res = await showDelegateOrderDialog(
      context,
      service: _service,
      orderId: orderId,
    );
    if (res == null || !mounted) return;
    final phone = res['receiverPhone']?.toString();
    _snack(
      'Đã ủy quyền lấy hộ${phone == null || phone.isEmpty ? '' : ' cho $phone'}. '
      'Mã PIN cũ đã hết hiệu lực.',
    );
    await _load();
  }

  /// "Đổi mã PIN": cấp PIN mới, PIN cũ hết hiệu lực.
  Future<void> _resetPin(Map<String, dynamic> order) async {
    final orderId = _asInt(order['id']);
    if (orderId == null) return;
    final isSend = _isSend(order);
    final status = (order['status'] as String? ?? '').toUpperCase();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Đổi mã PIN?'),
        content: Text(
          isSend && status == 'STORING'
              ? 'Mã PIN hiện tại sẽ hết hiệu lực. Người nhận cần mã mới để lấy hàng '
                    '— hãy gửi lại mã mới cho họ.'
              : 'Mã PIN hiện tại sẽ hết hiệu lực ngay và được thay bằng mã mới.',
          style: const TextStyle(fontSize: 14, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Đổi mã'),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    try {
      final res = await _service.resetPin(orderId);
      final pin = res['pinCode']?.toString();
      _snack(
        pin == null || pin.isEmpty
            ? 'Đã đổi mã PIN — xem mã mới trong chi tiết đơn.'
            : 'Đã đổi mã PIN mới: $pin',
      );
      await _load();
    } catch (e) {
      _snack(
        LockerOpsService.isEndpointUnavailable(e)
            ? 'Máy chủ chưa hỗ trợ đổi mã PIN.'
            : LockerOpsService.errorMessage(e),
      );
    }
  }

  Future<void> _openDetail(Map<String, dynamic> order) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (ctx) => _MyLockerOrderDetailPage(
          order: order,
          service: _service,
          onRefreshOrder: () async {
            await _load();
            final id = _asInt(order['id']);
            return _orders.where((o) => _asInt(o['id']) == id).firstOrNull;
          },
          incidentReportForOrder: _incidentReportForOrder,
          lockerNameOf: _lockerNameOf,
          lockerOf: _lockerOf,
          sourceLockerName:
              _lockersMap[_asInt(order['sourceLockerId'])]?['name']
                  ?.toString() ??
              order['sourceLockerName']?.toString(),
          sendBoxNumber:
              _lockerBoxesMap[_asInt(order['lockerId'])]?[_asInt(
                order['sendBoxId'],
              )] ??
              _asInt(order['sendBoxNumber'] ?? order['boxNumber']),
          receiveBoxNumber:
              _lockerBoxesMap[_asInt(
                order['destinationLockerId'] ?? order['lockerId'],
              )]?[_asInt(order['receiveBoxId'])] ??
              _asInt(order['receiveBoxNumber'] ?? order['boxNumber']),
          onReorder: (id) async {
            Navigator.pop(ctx);
            await _runAction(
              () => _service.reorder(id),
              'Đã tạo đơn mới — xem trong danh sách',
            );
          },
          onConfirmDrop: (id) async {
            Navigator.pop(ctx);
            await _runAction(
              () => _service.confirmDrop(id),
              'Đã xác nhận bỏ đồ',
            );
          },
          onComplete: (id) async {
            Navigator.pop(ctx);
            await _runAction(
              () => _service.completePickup(id),
              'Đã nhận đồ — đơn hoàn tất',
            );
          },
          onEndRental: (id) async {
            Navigator.pop(ctx);
            await _showRentalCompletionGuide(order);
          },
          onExtend: (id) async {
            Navigator.pop(ctx);
            await _extendDialog(id);
          },
          onReport: (boxId) async {
            Navigator.pop(ctx);
            final orderId = _asInt(order['id']);
            if (orderId == null) return;
            await _reportDialog(
              orderId: orderId,
              boxLabel: _boxLabelFor(order, boxId),
            );
          },
          onCancel: (id) async {
            Navigator.pop(ctx);
            if ('${order['type']}'.toUpperCase() == 'DRONE_DELIVERY') {
              await _cancelDroneOrder(order, id);
              return;
            }
            if (!await _confirmCancelOrder(order)) return;
            await _runAction(() => _service.cancelOrder(id), 'Đã hủy đơn');
            final lockerId = order['lockerId'] ?? order['locker']?['id'];
            AppEventBus.instance.emit(LockerLayoutUpdatedEvent(
              lockerId: lockerId?.toString(),
            ));
            AppEventBus.instance.emit(OrderChangedEvent(orderId: id.toString()));
          },
          onDirections: () => _openLockerDirections(order),
          onPay: (_) async {
            Navigator.pop(ctx);
            await _payDialog(order);
          },
          onPayOvertime: (id, fee) async {
            Navigator.pop(ctx);
            await _payOvertimeFlow(order, fee);
          },
          onPayAndComplete: (id) async {
            Navigator.pop(ctx);
            await _payAndCompleteFlow(order);
          },
          onOpenLocker: () {
            Navigator.pop(ctx);
            _openLockerFlow(order);
          },
          onTrackDrone: (id) {
            Navigator.pop(ctx);
            context.go(AppRouter.droneDeliveryTracking, extra: '$id');
          },
          onDelegate: (id) async {
            Navigator.pop(ctx);
            await _delegateOrder(id);
          },
          onResetPin: () async {
            Navigator.pop(ctx);
            await _resetPin(order);
          },
          onChanged: _load,
        ),
      ),
    );
    if (mounted) await _load();
  }

  @override
  Widget build(BuildContext context) {
    final groups = _groupedOrders;
    final showIncoming = _showIncoming;

    // Flatten groups into a mixed list of date-headers + order items
    final items = <_ListItem>[];
    for (final entry in groups) {
      items.add(_ListItem.header(entry.key));
      for (var i = 0; i < entry.value.length; i++) {
        items.add(_ListItem.order(entry.value[i]));
      }
    }

    return Scaffold(
      backgroundColor: context.pageBg,
      body: Column(
        children: [
          BrandHeroHeader(
            title: 'Đơn tủ',
            subtitle: 'Quản lý các đơn hàng của bạn',
            trailing: BrandCircleIconButton(
              icon: LucideIcons.refreshCw,
              onTap: _refresh,
              iconSize: 18,
            ),
          ),

          _ScopeTabs(
            showIncoming: showIncoming,
            incomingReadyCount: _incomingReadyCount,
            onChanged: (incoming) => setState(() => _showIncoming = incoming),
          ),

          // ── Service type & status filter chips ────────────────────────────
          if (!showIncoming)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
              child: Row(
                children: [
                  _TypeChip(
                    label: 'Tất cả',
                    count: _orders.length,
                    selected: _typeFilter == 'ALL',
                    onTap: () => _setFilter('ALL'),
                  ),
                  const SizedBox(width: 8),
                  _TypeChip(
                    label: 'Gần đây',
                    count: _countRecent,
                    selected: _typeFilter == 'RECENT',
                    onTap: () => _setFilter('RECENT'),
                  ),
                  const SizedBox(width: 8),
                  _TypeChip(
                    label: 'Đang dùng',
                    count: _countActive,
                    selected: _typeFilter == 'ACTIVE',
                    onTap: () => _setFilter('ACTIVE'),
                  ),
                  const SizedBox(width: 8),
                  _TypeChip(
                    label: 'Hoàn thành',
                    count: _countCompleted,
                    selected: _typeFilter == 'COMPLETED',
                    onTap: () => _setFilter('COMPLETED'),
                  ),
                  const SizedBox(width: 8),
                  _TypeChip(
                    label: 'Thuê tủ',
                    count: _countRental,
                    selected: _typeFilter == 'RENTAL',
                    onTap: () => _setFilter('RENTAL'),
                  ),
                  const SizedBox(width: 8),
                  _TypeChip(
                    label: 'Gửi hàng',
                    count: _countSend,
                    selected: _typeFilter == 'SEND',
                    onTap: () => _setFilter('SEND'),
                  ),
                  if (_countCanceled > 0) ...[
                    const SizedBox(width: 8),
                    _TypeChip(
                      label: 'Đã hủy',
                      count: _countCanceled,
                      selected: _typeFilter == 'CANCELED',
                      onTap: () => _setFilter('CANCELED'),
                    ),
                  ],
                ],
              ),
            )
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
              child: Row(
                children: [
                  _TypeChip(
                    label: 'Tất cả',
                    count: _incoming.length,
                    selected: _incomingFilter == 'ALL',
                    onTap: () => _setIncomingFilter('ALL'),
                  ),
                  const SizedBox(width: 8),
                  _TypeChip(
                    label: 'Gần đây',
                    count: _incomingCountRecent,
                    selected: _incomingFilter == 'RECENT',
                    onTap: () => _setIncomingFilter('RECENT'),
                  ),
                  const SizedBox(width: 8),
                  _TypeChip(
                    label: 'Chờ lấy',
                    count: _incomingCountActive,
                    selected: _incomingFilter == 'ACTIVE',
                    onTap: () => _setIncomingFilter('ACTIVE'),
                  ),
                  const SizedBox(width: 8),
                  _TypeChip(
                    label: 'Hoàn thành',
                    count: _incomingCountCompleted,
                    selected: _incomingFilter == 'COMPLETED',
                    onTap: () => _setIncomingFilter('COMPLETED'),
                  ),
                  if (_incomingCountDrone > 0) ...[
                    const SizedBox(width: 8),
                    _TypeChip(
                      label: 'Giao drone',
                      count: _incomingCountDrone,
                      selected: _incomingFilter == 'DRONE',
                      onTap: () => _setIncomingFilter('DRONE'),
                    ),
                  ],
                  if (_incomingCountSend > 0) ...[
                    const SizedBox(width: 8),
                    _TypeChip(
                      label: 'Gửi hàng',
                      count: _incomingCountSend,
                      selected: _incomingFilter == 'SEND',
                      onTap: () => _setIncomingFilter('SEND'),
                    ),
                  ],
                  if (_incomingCountCanceled > 0) ...[
                    const SizedBox(width: 8),
                    _TypeChip(
                      label: 'Đã hủy',
                      count: _incomingCountCanceled,
                      selected: _incomingFilter == 'CANCELED',
                      onTap: () => _setIncomingFilter('CANCELED'),
                    ),
                  ],
                ],
              ),
            ),

          const SizedBox(height: 8),

          // ── Grouped list ─────────────────────────────────────────────────
          Expanded(
            child: showIncoming
                ? _IncomingOrdersView(
                    orders: _incoming,
                    groups: _groupedIncomingOrders,
                    filter: _incomingFilter,
                    loading: _incomingLoading,
                    error: _incomingError,
                    onRefresh: _loadIncoming,
                    onUnlock: (o) async {
                      final opened = await openReceiverOrderBox(
                        context,
                        service: _service,
                        order: o,
                      );
                      if (opened) await _loadIncoming();
                    },
                    onDirections: (o) => openReceiverOrderDirections(context, o),
                    onOpen: _openIncomingDetail,
                  )
                : _loading
                ? const Center(
                    child: AppLoadingIndicator(
                      message: 'Đang tải danh sách đơn...',
                    ),
                  )
                : _visible.isEmpty
                ? OpsEmptyState(
                    icon: LucideIcons.packageOpen,
                    title: _typeFilter == 'ALL'
                        ? 'Chưa có đơn nào'
                        : 'Không có đơn phù hợp',
                    subtitle: _emptySubtitle,
                  )
                : RefreshIndicator(
                    color: AislBrand.navy,
                    onRefresh: _refresh,
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(0, 0, 0, 120),
                      itemCount: items.length,
                      itemBuilder: (ctx, i) {
                        final item = items[i];
                        if (item.isHeader) {
                          return Padding(
                            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                            child: Text(
                              item.header!,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: ctx.textMuted,
                                letterSpacing: 0.3,
                              ),
                            ),
                          );
                        }
                        final o = item.order!;
                        return Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                          child: RepaintBoundary(
                            child: _OrderCard(
                              order: o,
                              faultReport: _incidentReportForOrder(o),
                              lockerName: _lockerNameOf(o),
                              sendBoxNumber:
                                  _lockerBoxesMap[_asInt(
                                    o['lockerId'],
                                  )]?[_asInt(o['sendBoxId'])],
                              receiveBoxNumber:
                                  _lockerBoxesMap[_asInt(
                                    o['destinationLockerId'] ??
                                        o['lockerId'],
                                  )]?[_asInt(o['receiveBoxId'])],
                              onTap: () => _openDetail(o),
                              onPayAndComplete: () =>
                                  _payAndCompleteFlow(o),
                              onViewReport: () {
                                final r = _incidentReportForOrder(o);
                                if (r != null) {
                                  UserReportDetailSheet.show(context, report: r);
                                }
                              },
                            ),
                          ),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

/// Tải nhật ký KTV của phiếu gắn với đơn khi mở chi tiết, rồi dựng lại bảng chi
/// tiết với nhật ký đó (dùng cho hồ sơ điều chuyển ô). Lỗi / chưa có ⇒ rỗng.
class _ReportLogsLoader extends StatefulWidget {
  const _ReportLogsLoader({
    required this.report,
    required this.service,
    required this.builder,
  });

  final Map<String, dynamic>? report;
  final LockerOpsService service;
  final Widget Function(List<Map<String, dynamic>> logs) builder;

  @override
  State<_ReportLogsLoader> createState() => _ReportLogsLoaderState();
}

class _ReportLogsLoaderState extends State<_ReportLogsLoader> {
  List<Map<String, dynamic>> _logs = const [];

  @override
  void initState() {
    super.initState();
    final reportId = _asInt(widget.report?['id']);
    if (reportId != null) _loadLogs(reportId);
  }

  Future<void> _loadLogs(int reportId) async {
    try {
      final logs = await widget.service.userReportLogs(reportId);
      if (mounted && logs.isNotEmpty) setState(() => _logs = logs);
    } catch (_) {
      // Không có nhật ký thì chi tiết đơn vẫn hiện bình thường.
    }
  }

  @override
  Widget build(BuildContext context) => widget.builder(_logs);
}

/// Mục "Hàng chờ nhận": đơn người khác gửi tới mình, kèm mã lấy hàng khi sẵn sàng.
class _IncomingOrdersView extends StatelessWidget {
  const _IncomingOrdersView({
    required this.orders,
    this.groups,
    this.filter,
    required this.loading,
    required this.error,
    required this.onRefresh,
    required this.onUnlock,
    required this.onDirections,
    this.onOpen,
  });

  final List<ReceiverOrder> orders;
  final List<MapEntry<String, List<ReceiverOrder>>>? groups;
  final String? filter;
  final bool loading;
  final String? error;
  final Future<void> Function() onRefresh;
  final void Function(ReceiverOrder order) onUnlock;
  final void Function(ReceiverOrder order) onDirections;

  /// Chạm thẻ ⇒ mở chi tiết đơn.
  final void Function(ReceiverOrder order)? onOpen;

  @override
  Widget build(BuildContext context) {
    if (loading && orders.isEmpty) {
      return const Center(
        child: AppLoadingIndicator(message: 'Đang tải hàng chờ nhận...'),
      );
    }
    if (error != null && orders.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(LucideIcons.cloudOff, size: 36, color: opsMutedText),
              const SizedBox(height: 10),
              Text(
                error!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13.5, color: opsDark),
              ),
              const SizedBox(height: 8),
              TextButton(onPressed: onRefresh, child: const Text('Thử lại')),
            ],
          ),
        ),
      );
    }
    if (orders.isEmpty) {
      return RefreshIndicator(
        color: AislBrand.navy,
        onRefresh: onRefresh,
        child: ListView(
          children: const [
            SizedBox(height: 40),
            OpsEmptyState(
              icon: LucideIcons.inbox,
              title: 'Chưa có hàng chờ nhận',
              subtitle:
                  'Khi có người gửi hàng tới số điện thoại của bạn, đơn sẽ hiện ở đây.',
            ),
          ],
        ),
      );
    }

    if (groups != null) {
      if (groups!.isEmpty) {
        return RefreshIndicator(
          color: AislBrand.navy,
          onRefresh: onRefresh,
          child: ListView(
            children: const [
              SizedBox(height: 40),
              OpsEmptyState(
                icon: LucideIcons.packageOpen,
                title: 'Không có đơn phù hợp',
                subtitle:
                    'Không tìm thấy đơn hàng chờ nhận nào theo bộ lọc đã chọn.',
              ),
            ],
          ),
        );
      }

      // Flatten groups into a mixed list of date-headers + order items
      final items = <_IncomingListItem>[];
      for (final entry in groups!) {
        items.add(_IncomingListItem.header(entry.key));
        for (final o in entry.value) {
          items.add(_IncomingListItem.order(o));
        }
      }

      return RefreshIndicator(
        color: AislBrand.navy,
        onRefresh: onRefresh,
        child: ListView.builder(
          padding: const EdgeInsets.fromLTRB(0, 0, 0, 120),
          itemCount: items.length,
          itemBuilder: (ctx, i) {
            final item = items[i];
            if (item.isHeader) {
              return Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Text(
                  item.header!,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: ctx.textMuted,
                    letterSpacing: 0.3,
                  ),
                ),
              );
            }
            final o = item.order!;
            return Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
              child: RepaintBoundary(
                child: ReceiverOrderCard(
                  order: o,
                  onUnlock: () => onUnlock(o),
                  onDirections: () => onDirections(o),
                  onTap: onOpen == null ? null : () => onOpen!(o),
                ),
              ),
            );
          },
        ),
      );
    }

    // Đơn đang chờ lấy lên trước, sau đó tới các đơn đã xong.
    final sorted = [...orders]
      ..sort((a, b) {
        if (a.isActive != b.isActive) return a.isActive ? -1 : 1;
        final da = a.createdAt;
        final db = b.createdAt;
        if (da == null || db == null) return 0;
        return db.compareTo(da);
      });
    return RefreshIndicator(
      color: AislBrand.navy,
      onRefresh: onRefresh,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
        itemCount: sorted.length,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (ctx, i) => ReceiverOrderCard(
          order: sorted[i],
          onUnlock: () => onUnlock(sorted[i]),
          onDirections: () => onDirections(sorted[i]),
          onTap: onOpen == null ? null : () => onOpen!(sorted[i]),
        ),
      ),
    );
  }
}

class _IncomingListItem {
  const _IncomingListItem.header(this.header) : order = null;
  const _IncomingListItem.order(this.order) : header = null;

  final String? header;
  final ReceiverOrder? order;

  bool get isHeader => header != null;
}

/// "Đơn của tôi" | "Hàng chờ nhận" (kèm số đơn đang chờ lấy).
class _ScopeTabs extends StatelessWidget {
  const _ScopeTabs({
    required this.showIncoming,
    required this.incomingReadyCount,
    required this.onChanged,
  });

  final bool showIncoming;
  final int incomingReadyCount;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    Widget tab(String label, bool selected, VoidCallback onTap, {int? badge}) {
      return Expanded(
        child: Material(
          color: selected ? context.cardBg : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 9),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                        color: selected ? context.textPrimary : context.textMuted,
                      ),
                    ),
                  ),
                  if (badge != null && badge > 0) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 1.5,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDC2626),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '$badge',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
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

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: context.isDark
              ? Colors.white.withValues(alpha: 0.06)
              : const Color(0xFFE2E8F0),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            tab('Đơn của tôi', !showIncoming, () => onChanged(false)),
            tab(
              'Hàng chờ nhận',
              showIncoming,
              () => onChanged(true),
              badge: incomingReadyCount,
            ),
          ],
        ),
      ),
    );
  }
}

// ── List item discriminated union ─────────────────────────────────────────────

class _ListItem {
  const _ListItem._({this.header, this.order});
  factory _ListItem.header(String h) => _ListItem._(header: h);
  factory _ListItem.order(Map<String, dynamic> o) => _ListItem._(order: o);

  final String? header;
  final Map<String, dynamic>? order;
  bool get isHeader => header != null;
}

// ── Service type & status chip ───────────────────────────────────────────

class _TypeChip extends StatelessWidget {
  const _TypeChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.count,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final int? count;

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final activeBg = isDark ? Colors.white : const Color(0xFF0F172A);
    final activeFg = isDark ? const Color(0xFF0F172A) : Colors.white;
    final inactiveBg = isDark
        ? Colors.white.withValues(alpha: 0.06)
        : const Color(0xFFF1F5F9);
    final inactiveBorder = isDark
        ? Colors.white.withValues(alpha: 0.12)
        : const Color(0xFFE2E8F0);
    final inactiveFg = context.textPrimary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        splashColor: isDark
            ? Colors.white.withValues(alpha: 0.1)
            : const Color(0xFF0F172A).withValues(alpha: 0.08),
        highlightColor: Colors.transparent,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7.5),
          decoration: BoxDecoration(
            color: selected ? activeBg : inactiveBg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected ? activeBg : inactiveBorder,
              width: 1.5,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                  color: selected ? activeFg : inactiveFg,
                ),
              ),
              if (count != null) ...[
                const SizedBox(width: 5),
                Text(
                  '($count)',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    color: selected
                        ? activeFg.withValues(alpha: 0.75)
                        : context.textMuted,
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

// ── Order card (Grab style) ───────────────────────────────────────────────────

bool _isDeliveryOrder(String? type) {
  final upper = (type ?? '').toUpperCase();
  return upper.contains('SEND') ||
      upper.contains('DRONE') ||
      upper.contains('DELIVERY') ||
      upper.contains('PARCEL');
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({
    required this.order,
    this.faultReport,
    this.lockerName,
    this.sendBoxNumber,
    this.receiveBoxNumber,
    required this.onTap,
    this.onPayAndComplete,
    this.onViewReport,
  });

  final Map<String, dynamic> order;
  final Map<String, dynamic>? faultReport;
  final String? lockerName;
  final int? sendBoxNumber;
  final int? receiveBoxNumber;
  final VoidCallback onTap;
  final VoidCallback? onPayAndComplete;
  final VoidCallback? onViewReport;

  @override
  Widget build(BuildContext context) {
    final type = order['type'] as String?;
    final rawStatus = order['status'] as String?;
    final status = _displayStatus(order, rawStatus);
    final deadline = order['pickupDeadline'];
    final overdue =
        isOverdue(deadline) &&
        rawStatus != 'COMPLETED' &&
        rawStatus != 'CANCELED';
    final sColor = statusColor(status);
    final isDone = rawStatus == 'COMPLETED' || rawStatus == 'CANCELED';
    // Ô đang chờ KTV: không mời khách trả tiền / lấy đồ (server cũng chặn).
    final boxIncident = orderHasOpenBoxIncident(order);

    return Material(
      color: context.cardBg,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              clipBehavior: Clip.antiAlias,
              children: [
                // 3D asset nestled in bottom-right corner (compact, elegant, non-obtrusive)
                Positioned(
                  bottom: -2,
                  right: -2,
                  child: IgnorePointer(
                    child: SizedBox(
                      width: _isDeliveryOrder(type) ? 122 : 112,
                      height: _isDeliveryOrder(type) ? 112 : 104,
                      child: AppLottie(
                        _isDeliveryOrder(type)
                            ? AppLottieAssets.airplaneBox
                            : AppLottieAssets.box,
                        alignment: Alignment.bottomRight,
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Order Code + Status Badge Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Text(
                              order['orderCode'] != null &&
                                      order['orderCode'].toString().isNotEmpty
                                  ? '#${order['orderCode']}'
                                  : '#ORD-${order['id'] ?? ''}',
                              style: TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w800,
                                color: context.textPrimary,
                                letterSpacing: -0.2,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 9,
                              vertical: 3.5,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  (isDone
                                          ? const Color(0xFF16A34A)
                                          : overdue
                                          ? const Color(0xFFDC2626)
                                          : sColor)
                                      .withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              statusLabel(status),
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                color: isDone
                                    ? const Color(0xFF16A34A)
                                    : overdue
                                    ? const Color(0xFFDC2626)
                                    : sColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      // Service type + deadline
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            typeLabel(type),
                            style: TextStyle(
                              fontSize: 12.5,
                              color: context.textMuted,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (deadline != null) ...[
                            Text(
                              '•',
                              style: TextStyle(
                                fontSize: 12,
                                color: context.textMuted,
                              ),
                            ),
                            Text(
                              'Hạn lấy: ${fmtDateTime(deadline)}',
                              style: TextStyle(
                                fontSize: 12,
                                color: overdue
                                    ? const Color(0xFFDC2626)
                                    : context.textMuted,
                                fontWeight: overdue
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Route: Tủ and Ô
                      Padding(
                        padding: const EdgeInsets.only(right: 120),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _RouteRow(
                              isOrigin: true,
                              text: lockerName ?? 'Chưa tra được tên tủ',
                            ),
                            Padding(
                              padding: const EdgeInsets.only(
                                left: 7.25,
                                top: 2,
                                bottom: 2,
                              ),
                              child: Container(
                                width: 1.5,
                                height: 10,
                                color: const Color(0xFFCBD5E1),
                              ),
                            ),
                            _RouteRow(
                              isOrigin: false,
                              text: _orderBoxLabel(
                                sendBoxNumber: sendBoxNumber,
                                receiveBoxNumber: receiveBoxNumber,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      // Price + action
                      // Wrap chứ không dùng Row: nhãn nút đổi theo trạng thái (vd. "Thanh toán
                      // & lấy đồ") có thể dài hơn chỗ trống trên màn hẹp / chữ phóng to — khi
                      // không đủ chỗ thì nút xuống dòng thay vì tràn vạch vàng-đen.
                      Wrap(
                        spacing: 12,
                        runSpacing: 8,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            fmtPrice(order['totalPrice']),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: context.textPrimary,
                            ),
                          ),
                          Builder(
                            builder: (ctx) {
                              final due = orderAmountDue(order);
                              final paymentStatus = (order['paymentStatus']
                                          as String? ??
                                      'UNPAID')
                                  .toUpperCase();
                              final needsPay =
                                  due > 0 || paymentStatus != 'PAID';

                              final String actionLabel;
                              final Color? actionBgColor;
                              final Color actionTextColor;
                              final BorderSide actionBorderSide;

                              if (rawStatus == 'EXPIRED') {
                                actionLabel = needsPay
                                    ? 'Thanh toán & lấy đồ'
                                    : 'Xác nhận lấy đồ';
                                actionBgColor = const Color(
                                  0xFFDC2626,
                                ).withValues(alpha: 0.12);
                                actionTextColor = const Color(0xFFDC2626);
                                actionBorderSide = const BorderSide(
                                  color: Color(0xFFDC2626),
                                  width: 1.4,
                                );
                              } else if (boxIncident) {
                                actionLabel = 'Chờ KTV xử lý';
                                actionBgColor = const Color(
                                  0xFFF59E0B,
                                ).withValues(alpha: 0.12);
                                actionTextColor = const Color(0xFFB45309);
                                actionBorderSide = const BorderSide(
                                  color: Color(0xFFF59E0B),
                                  width: 1.2,
                                );
                              } else if (isDone) {
                                actionLabel = 'Xem lại';
                                actionBgColor = null;
                                actionTextColor = context.textPrimary;
                                actionBorderSide = BorderSide(
                                  color: context.borderColor,
                                  width: 1.5,
                                );
                              } else if (rawStatus == 'INITIALIZED') {
                                actionLabel = 'Bỏ đồ vào tủ';
                                actionBgColor = AislBrand.navy.withValues(
                                  alpha: 0.10,
                                );
                                actionTextColor = AislBrand.navy;
                                actionBorderSide = const BorderSide(
                                  color: AislBrand.navy,
                                  width: 1.2,
                                );
                              } else if (overdue) {
                                actionLabel = needsPay
                                    ? 'Thanh toán & lấy đồ'
                                    : 'Lấy đồ ngay';
                                actionBgColor = const Color(
                                  0xFFDC2626,
                                ).withValues(alpha: 0.12);
                                actionTextColor = const Color(0xFFDC2626);
                                actionBorderSide = const BorderSide(
                                  color: Color(0xFFDC2626),
                                  width: 1.4,
                                );
                              } else {
                                actionLabel = 'Chi tiết';
                                actionBgColor = null;
                                actionTextColor = context.textPrimary;
                                actionBorderSide = BorderSide(
                                  color: context.borderColor,
                                  width: 1.5,
                                );
                              }

                              return GestureDetector(
                                onTap: () {
                                  if (!boxIncident &&
                                      (rawStatus == 'EXPIRED' || overdue) &&
                                      onPayAndComplete != null) {
                                    onPayAndComplete!();
                                  } else {
                                    onTap();
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: actionBgColor,
                                    border: Border.fromBorderSide(
                                      actionBorderSide,
                                    ),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    actionLabel,
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w700,
                                      color: actionTextColor,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            // Overdue or Expired banner
            if (boxIncident)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                color: const Color(0xFFFFFBEB),
                child: Row(
                  children: [
                    const Icon(
                      LucideIcons.circlePause,
                      size: 13,
                      color: Color(0xFFB45309),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        order['boxIncidentOpenedAt'] == null
                            ? 'Phí quá giờ tạm dừng — chờ KTV xử lý ô, chưa cần thanh toán'
                            : 'Phí quá giờ tạm dừng từ ${fmtDateTime(order['boxIncidentOpenedAt'])} — chưa cần thanh toán',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFB45309),
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else if (rawStatus == 'EXPIRED')
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                color: const Color(0xFFFEF2F2),
                child: Row(
                  children: [
                    const Icon(
                      LucideIcons.triangleAlert,
                      size: 13,
                      color: Color(0xFFDC2626),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Đơn đã hết hạn lưu tủ ${BusinessConfigService.instance.current.overdueReleaseHoursLabel} — Bấm để thanh toán & lấy đồ',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFDC2626),
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else if (overdue)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                color: const Color(0xFFFEF2F2),
                child: Row(
                  children: const [
                    Icon(
                      LucideIcons.triangleAlert,
                      size: 13,
                      color: Color(0xFFDC2626),
                    ),
                    SizedBox(width: 6),
                    // Expanded chứ không để Text tự do: trong Row, Text lấy chiều rộng
                    // tự nhiên nên câu này tràn khỏi màn hình 390px và hiện vạch vàng-đen.
                    Expanded(
                      child: Text(
                        'Đơn đã quá hạn — có thể phát sinh phí',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFDC2626),
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else
              const SizedBox(height: 0),
            if (faultReport != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                child: _FaultOrderBanner(
                  report: faultReport!,
                  itemsInside: rawStatus == 'STORING' || rawStatus == 'RETURNED',
                  boxLabel: _orderBoxLabel(
                    sendBoxNumber: sendBoxNumber,
                    receiveBoxNumber: receiveBoxNumber,
                  ),
                  onViewReport: onViewReport ??
                      () {
                        UserReportDetailSheet.show(context, report: faultReport!);
                      },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _RouteRow extends StatelessWidget {
  const _RouteRow({required this.isOrigin, required this.text});
  final bool isOrigin;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: SizedBox(
            width: 16,
            child: Center(
              child: isOrigin
                  ? Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFF9CA3AF),
                          width: 2,
                        ),
                      ),
                    )
                  : Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: const Color(0xFF374151),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1F2937),
              height: 1.25,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _FaultOrderBanner extends StatelessWidget {
  const _FaultOrderBanner({
    required this.report,
    required this.boxLabel,
    this.itemsInside = false,
    this.logs = const [],
    this.onViewReport,
  });

  final Map<String, dynamic> report;

  /// Đồ đã nằm trong ô (đơn STORING/RETURNED): không huỷ được đơn, chỉ chờ KTV.
  final bool itemsInside;
  final String boxLabel;
  final List<Map<String, dynamic>> logs;
  final VoidCallback? onViewReport;

  @override
  Widget build(BuildContext context) {
    final reason = (report['description'] as String?)?.trim();
    final status = (report['status'] as String? ?? 'OPEN').toUpperCase();
    final isResolved = status == 'RESOLVED' || status == 'CLOSED';
    final reportId = report['id'];

    // Kiểm tra xem đơn hàng đã được KTV điều chuyển sang ô mới an toàn chưa
    bool isRelocated = false;
    String? newBoxNum;
    String? oldBoxNum = report['boxNumber']?.toString();

    for (final log in logs) {
      final note = (log['note'] ?? '').toString();
      final upper = note.toUpperCase();
      if (upper.contains('ĐIỀU CHUYỂN') || upper.contains('RELOCATE')) {
        isRelocated = true;
        final mNew = RegExp(r'sang ô #?(\d+)', caseSensitive: false).firstMatch(note);
        if (mNew != null) newBoxNum = mNew.group(1);
        final mOld = RegExp(r'khóa bảo trì ô #?(\d+)', caseSensitive: false).firstMatch(note) ??
            RegExp(r'ô #?(\d+)', caseSensitive: false).firstMatch(note);
        if (mOld != null && (oldBoxNum == null || oldBoxNum.isEmpty)) {
          oldBoxNum = mOld.group(1);
        }
        break;
      }
    }

    final Color bg;
    final Color border;
    final Color fg;
    final String title;
    final String subtitle;
    final IconData icon;

    if (isRelocated) {
      bg = const Color(0xFFF0FDF4);
      border = const Color(0xFFBBF7D0);
      fg = const Color(0xFF15803D);
      icon = LucideIcons.arrowRightLeft;
      title = 'Đã điều chuyển sang Ô số ${newBoxNum ?? ''} an toàn';
      subtitle = 'KTV đã chuyển đồ từ ô cũ (#${oldBoxNum ?? ''}) sang ô mới do sự cố. Mã PIN mới đã sẵn sàng.';
    } else if (isResolved) {
      bg = const Color(0xFFF0FDF4);
      border = const Color(0xFFBBF7D0);
      fg = const Color(0xFF15803D);
      icon = LucideIcons.shieldCheck;
      title = '$boxLabel đã được KTV kiểm tra & xử lý xong';
      subtitle = 'Tài sản trong ô được bảo vệ an toàn.';
    } else {
      bg = const Color(0xFFFEF2F2);
      border = const Color(0xFFFCA5A5);
      fg = const Color(0xFFDC2626);
      icon = LucideIcons.triangleAlert;
      title = '$boxLabel đã được báo sự cố';
      // Đơn đã có đồ trong ô thì không huỷ được (và huỷ cũng không lấy lại được đồ).
      subtitle = itemsInside
          ? 'Đồ của bạn vẫn được giữ an toàn trong ô. KTV đang xử lý — phí quá giờ '
              'tạm dừng, bạn chưa cần thanh toán.'
          : 'Hãy hủy đơn này và đặt ô khác (hoặc liên hệ KTV).';
    }

    void onTapBanner() {
      if (onViewReport != null) {
        onViewReport!();
      } else {
        UserReportDetailSheet.show(context, report: report);
      }
    }

    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTapBanner,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    icon,
                    size: 16,
                    color: fg,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                title,
                                style: TextStyle(
                                  fontSize: 12.5,
                                  height: 1.35,
                                  color: fg,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            if (reportId != null) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: fg.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  'RPT-$reportId',
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.bold,
                                    color: fg,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: 12,
                            height: 1.35,
                            color: fg.withValues(alpha: 0.9),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (reason != null && reason.isNotEmpty && !isRelocated) ...[
                          const SizedBox(height: 2),
                          Text(
                            'Lý do: $reason',
                            style: TextStyle(
                              fontSize: 11.5,
                              height: 1.35,
                              color: fg.withValues(alpha: 0.8),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: fg.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: fg.withValues(alpha: 0.25)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(isRelocated ? LucideIcons.arrowRightLeft : LucideIcons.fileText, size: 12, color: fg),
                      const SizedBox(width: 5),
                      // Flexible: banner nằm trong thẻ đơn / sheet chi tiết nên trên màn hẹp
                      // hoặc chữ phóng to nhãn này dài hơn bề ngang — cho xuống dòng thay vì tràn.
                      Flexible(
                        child: Text(
                          isRelocated
                              ? 'Xem chi tiết điều chuyển & ảnh KTV'
                              : 'Xem biên bản & ảnh minh chứng',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                            color: fg,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(LucideIcons.chevronRight, size: 13, color: fg),
                    ],
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

int? _asInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse('$value');
}

/// Đơn giá mỗi giờ quá hạn server áp cho đơn (`overtimeRatePerHour`: đơn thuê
/// = giá thuê loại ô × tỉ lệ admin đặt). Server cũ chưa trả thì dùng phí quá hạn
/// mỗi giờ trong cấu hình.
num overtimeRateOf(Map<String, dynamic> order, BusinessConfig config) =>
    _asDouble(order['overtimeRatePerHour']) ?? config.pickupOvertimeFeePerHour;

/// Có áp trần phí quá hạn không — đơn thuê ô thì không (server trả
/// `overtimeCapped = false`).
bool overtimeCappedOf(Map<String, dynamic> order) =>
    order['overtimeCapped'] != false;

double? _asDouble(dynamic value) {
  if (value is double) return value;
  if (value is num) return value.toDouble();
  return double.tryParse('$value');
}

String _displayStatus(Map<String, dynamic> order, String? fallback) {
  final type = (order['type'] as String? ?? '').toUpperCase();
  if (type == 'DRONE_DELIVERY') {
    final deliveryStage = order['deliveryStage'] as String?;
    if (deliveryStage != null && deliveryStage.isNotEmpty) {
      return deliveryStage;
    }
  }
  return fallback ?? '';
}

/// Bảng kê phí quá giờ trước khi trả để mở ô (Pay-to-Unlock). Đóng với `true`
/// khi khách bấm thanh toán — phương thức chọn ở bước sau theo cấu hình admin.
class _PayOvertimeConfirmationSheet extends StatelessWidget {
  const _PayOvertimeConfirmationSheet({
    required this.order,
    required this.amountDue,
    required this.lockerName,
    required this.boxLabel,
    required this.overdueDurationText,
    required this.overtimeRate,
    required this.overtimeCapped,
  });

  final Map<String, dynamic> order;

  /// Số tiền còn phải trả sau khi server áp phí quá hạn (`amountDue`).
  final double amountDue;
  final String lockerName;
  final String boxLabel;
  final String overdueDurationText;
  final num overtimeRate;

  /// Đơn thuê ô không áp trần phí quá hạn (ở quá giờ tính như thuê thêm).
  final bool overtimeCapped;

  @override
  Widget build(BuildContext context) {
    final deadline = order['pickupDeadline'];
    final config = BusinessConfigService.instance.current;
    final overtimeFee = _asDouble(order['pickupOvertimeFee']);

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        left: 20,
        right: 20,
        top: 10,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFF97316).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  LucideIcons.circleAlert,
                  color: Color(0xFFEA580C),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Thanh toán phí quá giờ',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                        color: opsDark,
                      ),
                    ),
                    Text(
                      '$lockerName · $boxLabel',
                      style: const TextStyle(fontSize: 13, color: opsMutedText),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Bảng kê chi phí
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: opsSurface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: opsBorder),
            ),
            child: Column(
              children: [
                _breakdownRow('Hạn trả ban đầu', fmtDateTime(deadline)),
                _breakdownRow(
                  'Thời gian quá hạn',
                  overdueDurationText,
                  valueColor: const Color(0xFFDC2626),
                ),
                _breakdownRow('Đơn giá quá giờ', '${fmtPrice(overtimeRate)}/giờ'),
                if (overtimeCapped &&
                    (config.pickupMaxOvertimePercent > 0 ||
                        config.pickupMaxOvertimeFee > 0))
                  _breakdownRow(
                    'Quy định mức trần',
                    [
                      if (config.pickupMaxOvertimeFee > 0)
                        'Tối đa ${fmtPrice(config.pickupMaxOvertimeFee)}',
                      if (config.pickupMaxOvertimePercent > 0)
                        '${config.pickupMaxOvertimePercent}% đơn',
                    ].join(' & '),
                  ),
                if (overtimeFee != null && overtimeFee > 0)
                  _breakdownRow('Phí quá giờ', fmtPrice(overtimeFee)),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Divider(height: 1, color: opsBorder),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Cần thanh toán:',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                        color: opsDark,
                      ),
                    ),
                    Text(
                      fmtPrice(amountDue),
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 20,
                        color: Color(0xFFEA580C),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: () => Navigator.pop(context, true),
            icon: const Icon(LucideIcons.creditCard, size: 19),
            label: Text(
              amountDue > 0
                  ? 'Thanh toán ${fmtPrice(amountDue)}'
                  : 'Mở ô lấy đồ',
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 14.5,
              ),
            ),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF0F172A),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: 0,
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Để sau'),
          ),
        ],
      ),
    );
  }

  Widget _breakdownRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3.5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 12.5, color: opsMutedText),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: valueColor ?? opsDark,
            ),
          ),
        ],
      ),
    );
  }
}

Map<int, Map<String, dynamic>> _activeReportsByBoxMap(
  List<Map<String, dynamic>> reports,
) {
  final active = <int, Map<String, dynamic>>{};
  for (final report in reports) {
    final boxId = _asInt(report['boxId']);
    final status = (report['status'] as String? ?? '').toUpperCase();
    if (boxId == null || status == 'RESOLVED' || active.containsKey(boxId)) {
      continue;
    }
    active[boxId] = report;
  }
  return active;
}

/// `4`, `4 → 7`, hoặc `Chưa gán ô` — cho dòng "Ô" ở bảng chi tiết.
String _boxRouteLabel(
  int? sendBoxNumber,
  int? receiveBoxNumber, [
  String? status,
]) {
  if (sendBoxNumber == null && receiveBoxNumber == null) {
    return (status ?? '').toUpperCase() == 'EXPIRED'
        ? 'Đã giải phóng ô'
        : 'Chưa gán ô';
  }
  if (sendBoxNumber != null && receiveBoxNumber != null) {
    return '$sendBoxNumber → $receiveBoxNumber';
  }
  return '${sendBoxNumber ?? receiveBoxNumber}';
}

/// `Ô số 4`, hoặc `Ô này` khi chưa gán ô.
///
/// CHỈ dùng số ô in trên tủ. Trước đây thiếu số ô thì rơi về `boxId` — mã nội bộ của
/// bản ghi — nên màn hình hiện "Ô số 701" trong khi trên tủ không có ô nào số 701;
/// người dùng đi tìm sẽ không thấy. Nói chung chung còn hơn nói một con số sai.
String _orderBoxLabel({
  int? sendBoxNumber,
  int? receiveBoxNumber,
  bool isPickupPhase = false,
}) {
  final label = isPickupPhase
      ? (receiveBoxNumber ?? sendBoxNumber)
      : (sendBoxNumber ?? receiveBoxNumber);
  return label == null ? 'Ô này' : 'Ô số $label';
}

/// Bóc tách và chuẩn hóa thông tin điều chuyển ô do sự cố kỹ thuật của đơn hàng
class _IncidentRelocationInfo {
  final bool isRelocated;
  final String? oldBoxNumber;
  final String? newBoxNumber;
  final String? oldBoxOpenedTime;
  final String? relocatedTime;
  final String? technician;
  final String? initialPin;
  final String? currentPin;
  final String? faultReason;
  final List<String> photoUrls;
  final int? reportId;

  const _IncidentRelocationInfo({
    required this.isRelocated,
    this.oldBoxNumber,
    this.newBoxNumber,
    this.oldBoxOpenedTime,
    this.relocatedTime,
    this.technician,
    this.initialPin,
    this.currentPin,
    this.faultReason,
    this.photoUrls = const [],
    this.reportId,
  });

  static String _fmtSec(dynamic value) {
    if (value == null) return '';
    try {
      final d = DateTime.parse(value.toString()).toLocal();
      String tw(int n) => n.toString().padLeft(2, '0');
      return '${tw(d.hour)}:${tw(d.minute)}:${tw(d.second)} ${tw(d.day)}/${tw(d.month)}/${d.year}';
    } catch (_) {
      return '';
    }
  }

  static _IncidentRelocationInfo extract({
    required Map<String, dynamic> order,
    Map<String, dynamic>? report,
    List<Map<String, dynamic>> logs = const [],
  }) {
    bool isRelocated = false;
    String? oldBox;
    String? newBox;
    String? oldOpenedTime;
    String? relTime;
    String? tech;
    final photoUrls = <String>{};

    final repId = _asInt(report?['id']);
    final faultReason = (report?['description'] ?? report?['reason'])?.toString().trim();
    if (report?['boxNumber'] != null) {
      oldBox = report!['boxNumber'].toString();
    }

    // Quét qua logs để bóc tách thông tin KTV và các mốc can thiệp
    for (final l in logs) {
      final note = (l['note'] ?? l['description'] ?? '').toString();
      final upper = note.toUpperCase();
      final dt = l['createdAt'] ?? l['created_at'] ?? l['timestamp'] ?? l['changedAt'];
      final dtStr = _fmtSec(dt);

      final actorId = l['actorUserId'] ?? l['userId'] ?? l['technicianId'];
      if (actorId != null && tech == null) {
        tech = 'KTV #$actorId';
      }

      // Trích xuất ảnh trong log
      final atts = l['attachments'];
      if (atts is List) {
        for (final a in atts) {
          if (a is Map) {
            final u = (a['secureUrl'] ?? a['url'] ?? a['thumbnailUrl'])?.toString().trim();
            if (u != null && (u.startsWith('http://') || u.startsWith('https://'))) {
              photoUrls.add(u);
            }
          }
        }
      }

      if (upper.contains('ĐIỀU CHUYỂN') || upper.contains('RELOCATE')) {
        isRelocated = true;
        if (relTime == null && dtStr.isNotEmpty) {
          relTime = dtStr;
        }
        final mNew = RegExp(r'sang ô #?(\d+)', caseSensitive: false).firstMatch(note);
        if (mNew != null) newBox = mNew.group(1);
        final mOld = RegExp(r'khóa bảo trì ô #?(\d+)', caseSensitive: false).firstMatch(note) ??
            RegExp(r'ô #?(\d+)', caseSensitive: false).firstMatch(note);
        if (mOld != null && (oldBox == null || oldBox.isEmpty)) {
          oldBox = mOld.group(1);
        }
      } else {
        // Ghi chú hiện trường / kiểm tra mở ô cũ
        if (oldOpenedTime == null && dtStr.isNotEmpty) {
          oldOpenedTime = dtStr;
        }
        if (oldBox == null || oldBox.isEmpty) {
          final mOld = RegExp(r'ô #?(\d+)', caseSensitive: false).firstMatch(note);
          if (mOld != null) oldBox = mOld.group(1);
        }
      }
    }

    if (newBox == null && order['sendBoxNumber'] != null) {
      newBox = order['sendBoxNumber'].toString();
    }
    if (newBox == null && order['receiveBoxNumber'] != null) {
      newBox = order['receiveBoxNumber'].toString();
    }

    return _IncidentRelocationInfo(
      isRelocated: isRelocated,
      oldBoxNumber: oldBox,
      newBoxNumber: newBox,
      oldBoxOpenedTime: oldOpenedTime,
      relocatedTime: relTime,
      technician: tech ??
          (report?['assignedToTechnicianName'] ??
              (report?['assignedToUserId'] != null
                  ? 'KTV #${report!['assignedToUserId']}'
                  : null)),
      initialPin: '•••••• (Đã hủy để bảo mật)',
      currentPin: order['pinCode']?.toString(),
      faultReason: faultReason,
      photoUrls: photoUrls.toList(),
      reportId: repId,
    );
  }
}

/// Card chi tiết hồ sơ điều chuyển ô hiển thị trong modal chi tiết đơn hàng
class _OrderRelocationCard extends StatelessWidget {
  const _OrderRelocationCard({
    required this.relocation,
    this.onViewReport,
  });

  final _IncidentRelocationInfo relocation;
  final VoidCallback? onViewReport;

  @override
  Widget build(BuildContext context) {
    final oldBox = relocation.oldBoxNumber ?? '—';
    final newBox = relocation.newBoxNumber ?? '—';
    final tech = relocation.technician ?? 'KTV phụ trách';
    final oldTime = relocation.oldBoxOpenedTime;
    final newTime = relocation.relocatedTime;
    final photos = relocation.photoUrls;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF86EFAC), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF15803D).withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tiêu đề card
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  LucideIcons.arrowRightLeft,
                  size: 16,
                  color: Color(0xFF15803D),
                ),
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'HỒ SƠ ĐIỀU CHUYỂN Ô AN TOÀN',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF15803D),
                        letterSpacing: 0.3,
                      ),
                    ),
                    Text(
                      'Hàng đã được chuyển sang ô mới do ô cũ gặp sự cố kỹ thuật',
                      style: TextStyle(
                        fontSize: 11,
                        color: Color(0xFF166534),
                      ),
                    ),
                  ],
                ),
              ),
              if (relocation.reportId != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF15803D).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'RPT-${relocation.reportId}',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF15803D),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),

          // Sơ đồ chuyển đổi ô: Ô CŨ -> Ô MỚI
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFDCFCE7)),
            ),
            child: Row(
              children: [
                // Ô cũ
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(LucideIcons.circleAlert, size: 12, color: Color(0xFFDC2626)),
                          SizedBox(width: 4),
                          Text(
                            'Ô BAN ĐẦU',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFFDC2626),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Ô số #$oldBox',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF991B1B),
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        relocation.faultReason != null && relocation.faultReason!.isNotEmpty
                            ? relocation.faultReason!
                            : 'Gặp sự cố kỹ thuật',
                        style: const TextStyle(fontSize: 10.5, color: Color(0xFFB91C1C)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                // Icon mũi tên chuyển tiếp
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          color: Color(0xFFE0F2FE),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          LucideIcons.arrowRight,
                          size: 14,
                          color: Color(0xFF0284C7),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        tech,
                        style: const TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF0369A1),
                        ),
                      ),
                    ],
                  ),
                ),
                // Ô mới
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            'Ô TIẾP NHẬN MỚI',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF15803D),
                            ),
                          ),
                          SizedBox(width: 4),
                          Icon(LucideIcons.circleCheck, size: 12, color: Color(0xFF15803D)),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Ô số #$newBox',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF15803D),
                        ),
                      ),
                      const SizedBox(height: 1),
                      const Text(
                        'Đang chứa hàng an toàn',
                        style: TextStyle(fontSize: 10.5, color: Color(0xFF166534)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Chi tiết các mốc thời gian & mã PIN
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              children: [
                if (oldTime != null && oldTime.isNotEmpty) ...[
                  _detailRow(
                    icon: LucideIcons.doorOpen,
                    label: 'Thời gian mở ô cũ kiểm tra',
                    value: oldTime,
                    valueColor: const Color(0xFFB45309),
                  ),
                  const Divider(height: 10, color: Color(0xFFF1F5F9)),
                ],
                if (newTime != null && newTime.isNotEmpty) ...[
                  _detailRow(
                    icon: LucideIcons.packageCheck,
                    label: 'Thời gian chuyển qua ô mới',
                    value: newTime,
                    valueColor: const Color(0xFF15803D),
                  ),
                  const Divider(height: 10, color: Color(0xFFF1F5F9)),
                ],
                _detailRow(
                  icon: LucideIcons.shieldAlert,
                  label: 'Mã PIN ô ban đầu',
                  value: 'Đã vô hiệu hoá (Mã cũ hết hạn)',
                  valueColor: const Color(0xFF64748B),
                ),
                const Divider(height: 10, color: Color(0xFFF1F5F9)),
                _detailRow(
                  icon: LucideIcons.key,
                  label: 'Mã PIN mở ô mới (#$newBox)',
                  value: '${relocation.currentPin ?? '••••••'} (Đang kích hoạt)',
                  valueColor: const Color(0xFF15803D),
                  isBold: true,
                ),
              ],
            ),
          ),

          // Ảnh minh chứng KTV
          if (photos.isNotEmpty) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(LucideIcons.camera, size: 13, color: Color(0xFF15803D)),
                const SizedBox(width: 5),
                Text(
                  'Ảnh KTV chụp quá trình kiểm tra & chuyển ô (${photos.length} ảnh):',
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF15803D),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final url in photos)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      width: 58,
                      height: 58,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        border: Border.all(color: const Color(0xFF86EFAC)),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Image.network(
                        url,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.broken_image,
                          size: 20,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],

          const SizedBox(height: 10),
          // Nút bấm mở chi tiết báo cáo sự cố
          Material(
            color: const Color(0xFF15803D),
            borderRadius: BorderRadius.circular(10),
            child: InkWell(
              onTap: onViewReport,
              borderRadius: BorderRadius.circular(10),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 12),
                alignment: Alignment.center,
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(LucideIcons.fileText, size: 14, color: Colors.white),
                    SizedBox(width: 6),
                    Text(
                      'Xem toàn bộ biên bản sự cố KTV & nhật ký ➔',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Widget _detailRow({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
    bool isBold = false,
  }) {
    return Row(
      children: [
        Icon(icon, size: 12.5, color: valueColor ?? const Color(0xFF475569)),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
        ),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
            color: valueColor ?? const Color(0xFF1E293B),
          ),
        ),
      ],
    );
  }
}

class _MyLockerOrderDetailPage extends StatefulWidget {
  const _MyLockerOrderDetailPage({
    required this.order,
    required this.service,
    required this.onRefreshOrder,
    required this.incidentReportForOrder,
    required this.lockerNameOf,
    required this.lockerOf,
    this.sourceLockerName,
    this.sendBoxNumber,
    this.receiveBoxNumber,
    required this.onReorder,
    required this.onConfirmDrop,
    required this.onComplete,
    required this.onEndRental,
    required this.onExtend,
    required this.onReport,
    required this.onCancel,
    required this.onDirections,
    required this.onPay,
    required this.onPayOvertime,
    required this.onOpenLocker,
    required this.onTrackDrone,
    this.onPayAndComplete,
    this.onDelegate,
    this.onResetPin,
    this.onChanged,
  });

  final Map<String, dynamic> order;
  final LockerOpsService service;
  final Future<Map<String, dynamic>?> Function() onRefreshOrder;
  final Map<String, dynamic>? Function(Map<String, dynamic> order) incidentReportForOrder;
  final String? Function(Map<String, dynamic> order) lockerNameOf;
  final Map<String, dynamic>? Function(Map<String, dynamic> order) lockerOf;
  final String? sourceLockerName;
  final int? sendBoxNumber;
  final int? receiveBoxNumber;
  final void Function(int orderId) onReorder;
  final void Function(int orderId) onConfirmDrop;
  final void Function(int orderId) onComplete;
  final void Function(int orderId) onEndRental;
  final void Function(int orderId) onExtend;
  final void Function(int boxId) onReport;
  final void Function(int orderId) onCancel;
  final VoidCallback onDirections;
  final void Function(int orderId) onPay;
  final void Function(int orderId, num fee) onPayOvertime;
  final VoidCallback onOpenLocker;
  final void Function(int orderId) onTrackDrone;
  final void Function(int orderId)? onPayAndComplete;
  final void Function(int orderId)? onDelegate;
  final VoidCallback? onResetPin;
  final Future<void> Function()? onChanged;

  @override
  State<_MyLockerOrderDetailPage> createState() =>
      _MyLockerOrderDetailPageState();
}

class _MyLockerOrderDetailPageState extends State<_MyLockerOrderDetailPage> {
  late Map<String, dynamic> _currentOrder = widget.order;
  bool _refreshing = false;

  Future<void> _refresh() async {
    if (_refreshing) return;
    setState(() => _refreshing = true);
    try {
      final updated = await widget.onRefreshOrder();
      if (mounted && updated != null) {
        setState(() => _currentOrder = updated);
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _refreshing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final faultReport = widget.incidentReportForOrder(_currentOrder);
    final orderCode = _currentOrder['orderCode']?.toString();
    final displayTitle = (orderCode != null && orderCode.isNotEmpty)
        ? '#$orderCode'
        : 'Chi tiết đơn #${_currentOrder['id'] ?? ''}';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: opsDark,
        surfaceTintColor: Colors.white,
        elevation: 0,
        title: Text(
          displayTitle,
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
        ),
        actions: [
          IconButton(
            onPressed: _refreshing ? null : _refresh,
            icon: const Icon(LucideIcons.refreshCw, size: 18),
            tooltip: 'Tải lại',
          ),
        ],
        bottom: _refreshing
            ? const PreferredSize(
                preferredSize: Size.fromHeight(2),
                child: LinearProgressIndicator(minHeight: 2),
              )
            : null,
      ),
      body: RefreshIndicator(
        color: opsDark,
        onRefresh: _refresh,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
          child: _ReportLogsLoader(
            report: faultReport,
            service: widget.service,
            builder: (logs) => _DetailSheet(
              order: _currentOrder,
              service: widget.service,
              faultReport: faultReport,
              faultLogs: logs,
              lockerName: widget.lockerNameOf(_currentOrder),
              locker: widget.lockerOf(_currentOrder),
              sourceLockerName: widget.sourceLockerName,
              sendBoxNumber: widget.sendBoxNumber,
              receiveBoxNumber: widget.receiveBoxNumber,
              onReorder: widget.onReorder,
              onConfirmDrop: widget.onConfirmDrop,
              onComplete: widget.onComplete,
              onEndRental: widget.onEndRental,
              onExtend: widget.onExtend,
              onReport: widget.onReport,
              onCancel: widget.onCancel,
              onDirections: widget.onDirections,
              onPay: widget.onPay,
              onPayOvertime: widget.onPayOvertime,
              onPayAndComplete: widget.onPayAndComplete,
              onOpenLocker: widget.onOpenLocker,
              onTrackDrone: widget.onTrackDrone,
              onDelegate: widget.onDelegate,
              onResetPin: widget.onResetPin,
              onChanged: _refresh,
            ),
          ),
        ),
      ),
    );
  }
}

class _DetailSheet extends StatelessWidget {
  const _DetailSheet({
    required this.order,
    this.service,
    this.faultReport,
    this.faultLogs = const [],
    this.lockerName,
    this.locker,
    this.sourceLockerName,
    this.sendBoxNumber,
    this.receiveBoxNumber,
    required this.onReorder,
    required this.onConfirmDrop,
    required this.onComplete,
    required this.onEndRental,
    required this.onExtend,
    required this.onReport,
    required this.onCancel,
    required this.onDirections,
    required this.onPay,
    required this.onPayOvertime,
    required this.onOpenLocker,
    required this.onTrackDrone,
    this.onPayAndComplete,
    this.onDelegate,
    this.onResetPin,
    this.onChanged,
  });

  final Map<String, dynamic> order;
  final LockerOpsService? service;
  final Map<String, dynamic>? faultReport;
  final List<Map<String, dynamic>> faultLogs;
  final String? lockerName;

  /// Bản ghi tủ đầy đủ để hiện địa điểm; `null` khi chưa tải được.
  final Map<String, dynamic>? locker;

  /// Tên tủ gửi của đơn drone (đã tải trong danh sách); `null` khi không có.
  final String? sourceLockerName;
  final int? sendBoxNumber;
  final int? receiveBoxNumber;
  final void Function(int orderId) onReorder;
  final void Function(int orderId) onConfirmDrop;
  final void Function(int orderId) onComplete;
  final void Function(int orderId) onEndRental;
  final void Function(int orderId) onExtend;
  final void Function(int boxId) onReport;
  final void Function(int orderId) onCancel;
  final VoidCallback onDirections;
  final void Function(int orderId) onPay;
  final void Function(int orderId, num fee) onPayOvertime;
  final VoidCallback onOpenLocker;
  final void Function(int orderId) onTrackDrone;
  final void Function(int orderId)? onPayAndComplete;

  /// "Ủy quyền lấy hộ" (đơn STORING/RETURNED).
  final void Function(int orderId)? onDelegate;

  /// "Đổi mã PIN".
  final VoidCallback? onResetPin;

  /// Tải lại danh sách sau thao tác trong các mục con (hoàn tiền…).
  final Future<void> Function()? onChanged;

  @override
  Widget build(BuildContext context) {
    final id = _asInt(order['id']) ?? 0;
    final rawStatus = order['status'] as String? ?? '';
    final status = _displayStatus(order, rawStatus);
    final type = (order['type'] as String? ?? '').toUpperCase();
    final isDroneDelivery = type == 'DRONE_DELIVERY';
    final isRental = type == 'RENTAL';
    final isPickupPhase = rawStatus == 'STORING' || rawStatus == 'RETURNED';
    final boxId = isPickupPhase
        ? _asInt(order['receiveBoxId'] ?? order['sendBoxId'])
        : _asInt(order['sendBoxId'] ?? order['receiveBoxId']);
    final deadline = order['pickupDeadline'];
    final overdue =
        isOverdue(deadline) && status != 'COMPLETED' && status != 'CANCELED';
    final extraFee = order['extraFee'];
    final hasExtra =
        extraFee != null &&
        (extraFee is num ? extraFee > 0 : num.tryParse('$extraFee') != null);
    final extraFeeNum = extraFee is num
        ? extraFee
        : num.tryParse('$extraFee') ?? 0;

    final paymentStatus = (order['paymentStatus'] as String? ?? 'UNPAID')
        .toUpperCase();
    final totalRaw = order['totalPrice'];
    final totalNum = totalRaw is num
        ? totalRaw
        : num.tryParse('$totalRaw') ?? 0;
    // Ô đang chờ KTV: server dừng phí, không thu tiền, không mở ô bằng mã.
    final boxIncident = orderHasOpenBoxIncident(order);
    final canPay =
        !boxIncident &&
        paymentStatus != 'PAID' &&
        totalNum > 0 &&
        rawStatus != 'CANCELED' &&
        rawStatus != 'COMPLETED';
    final canUsePickupActions =
        !boxIncident && (!isDroneDelivery || paymentStatus == 'PAID');
    final boxLabel = _orderBoxLabel(
      sendBoxNumber: sendBoxNumber,
      receiveBoxNumber: receiveBoxNumber,
      isPickupPhase: isPickupPhase,
    );
    final rawAddress = locker?['address']?.toString().trim();
    final lockerAddress = (rawAddress == null || rawAddress.isEmpty)
        ? null
        : rawAddress;

    // Trích xuất toàn bộ hồ sơ điều chuyển ô kỹ thuật (nếu có)
    final relocation = _IncidentRelocationInfo.extract(
      order: order,
      report: faultReport,
      logs: faultLogs,
    );

    // Mã người nhận cần để mở ô (đơn gửi hàng / giao drone đã vào ô). "Đơn của
    // tôi" chỉ gồm đơn mình đặt nên người xem ở đây luôn là người gửi; người
    // nhận xem mã ở "Hàng chờ nhận", không có nút chia sẻ.
    final receiverShare = canUsePickupActions
        ? pickupCodeShareForOrder(
            order,
            lockerName: lockerName,
            lockerAddress: lockerAddress,
            boxNumber: receiveBoxNumber ?? sendBoxNumber,
          )
        : null;

    void handleViewReport() {
      if (faultReport != null) {
        UserReportDetailSheet.show(context, report: faultReport!);
      }
    }

    // Backend order-service trả thêm 5 trường này từ bản vá OrderResponse (trước đây có
    // trên entity nhưng không trả về khách hàng) — receiverName/receiverPhone (SEND / uỷ
    // quyền lấy hộ), customerNote (ghi chú lúc tạo đơn), deliveryAddress (SEND giao tận
    // nơi), rentalDurationHours (RENTAL). Tất cả optional nên chỉ hiện dòng khi có giá trị.
    final receiverName = (order['receiverName'] as String?)?.trim();
    final receiverPhone = (order['receiverPhone'] as String?)?.trim();
    final receiverLabel = [
      if (receiverName != null && receiverName.isNotEmpty) receiverName,
      if (receiverPhone != null && receiverPhone.isNotEmpty) receiverPhone,
    ].join(' · ');
    final customerNote = (order['customerNote'] as String?)?.trim();
    // Phần chi tiết bổ sung của OrderResponse (cùng nguồn với chi tiết đơn phía
    // người nhận): kiện hàng, mốc thời gian, ủy quyền, liên hệ, đơn drone.
    String? text(String key) {
      final v = order[key]?.toString().trim();
      return v == null || v.isEmpty ? null : v;
    }

    final receiverEmail = text('receiverEmail');
    final delegateNote = text('delegateNote');
    final delegateLabel = [
      text('delegateName'),
      text('delegatePhone'),
    ].whereType<String>().join(' · ');
    final delegatedAt = order['delegatedAt'];
    final intendedReceiveAt = order['intendedReceiveAt'];
    final paidAt = order['paidAt'];
    final routeDistance = _asInt(order['routeDistanceMeters']);
    final originalPrice = _asDouble(order['originalPrice']) ?? 0;
    final parcel = OrderParcel.tryParse(order['parcel']);
    final milestones = OrderMilestone.listFrom(order['milestones']);
    final blockLabel = text('deliveryBlockReasonLabel');
    final failureLabel = text('failureReasonLabel');
    final rawLines = order['orderDetails'];
    final serviceLines = <String>[
      if (rawLines is List)
        for (final line in rawLines.whereType<Map>())
          [
            (line['description']?.toString().trim() ?? '').isNotEmpty
                ? line['description'].toString().trim()
                : 'Dịch vụ #${line['serviceId'] ?? ''}',
            if (_asInt(line['quantity']) != null)
              '× ${_asInt(line['quantity'])}',
            if (line['price'] != null) '— ${fmtPrice(line['price'])}',
          ].join(' '),
    ];
    final deliveryAddress = (order['deliveryAddress'] as String?)?.trim();
    final rentalHours = _asInt(order['rentalDurationHours']);
    final discountAmount = _asDouble(order['discount']) ?? 0;
    final promotionCode = (order['promotionCode'] as String?)?.trim();
    // Điểm thưởng server đã trừ khi tạo đơn (`pointsUsed` điểm = `pointsDiscount` đ).
    final pointsUsed = orderPointsUsed(order);
    final pointsDiscount = orderPointsDiscount(order);
    final createdAt = order['createdAt'];

    final config = BusinessConfigService.instance.current;
    final overtimeDurationText = fmtOverdueDuration(deadline);

    num calcOvertime() {
      final backendFee = _asDouble(order['pickupOvertimeFee']);
      if (backendFee != null) return backendFee > 0 ? backendFee : 0;
      if (!overdue) return 0;
      final parsedD = parseDate(deadline);
      if (parsedD == null) return 0;
      if (!overtimeCappedOf(order)) {
        // Đơn thuê: mỗi giờ đã bắt đầu tính trọn giờ theo đơn giá server trả.
        final minutes = DateTime.now().difference(parsedD).inMinutes;
        final hours = (minutes + 59) ~/ 60;
        return hours > 0 ? hours * overtimeRateOf(order, config) : 0;
      }
      final diffHours = DateTime.now().difference(parsedD).inHours;
      final raw = diffHours * config.pickupOvertimeFeePerHour;
      final maxPercent = config.pickupMaxOvertimePercent;
      final percentCap = maxPercent > 0 && totalNum > 0
          ? (totalNum * maxPercent / 100).round()
          : (config.pickupMaxOvertimeFee > 0
                ? config.pickupMaxOvertimeFee
                : raw);
      var fee = raw;
      if (config.pickupMaxOvertimeFee > 0 &&
          fee > config.pickupMaxOvertimeFee) {
        fee = config.pickupMaxOvertimeFee;
      }
      if (percentCap > 0 && fee > percentCap) {
        fee = percentCap;
      }
      return fee > 0 ? fee : 0;
    }

    final overtimeFee = calcOvertime();
    final isOvertimePaid =
        hasExtra &&
        paymentStatus == 'PAID' &&
        extraFeeNum >= overtimeFee &&
        overtimeFee > 0;
    final needsPayOvertime = overdue && !isOvertimePaid && overtimeFee > 0;

    final canDrop =
        rawStatus == 'INITIALIZED' &&
        (paymentStatus == 'PAID' ||
            totalNum <= 0 ||
            order['paymentRequired'] == false) &&
        boxId != null;

    final actions = <Widget>[
      if (isDroneDelivery &&
          rawStatus != 'COMPLETED' &&
          rawStatus != 'CANCELED')
        OpsSheetAction(
          label: 'Theo dõi giao drone',
          icon: LucideIcons.navigation,
          primary: true,
          onTap: () => onTrackDrone(id),
        ),
      if (canPay &&
          rawStatus != 'EXPIRED' &&
          !(rawStatus == 'STORING' && needsPayOvertime) &&
          !(rawStatus == 'RETURNED' && needsPayOvertime))
        OpsSheetAction(
          label: 'Thanh toán ${fmtPrice(orderAmountDue(order))}',
          icon: LucideIcons.creditCard,
          primary: true,
          onTap: () => onPay(id),
        ),
      if (rawStatus == 'EXPIRED') ...[
        if (canPay || orderAmountDue(order) > 0)
          OpsSheetAction(
            label:
                'Thanh toán (${fmtPrice(orderAmountDue(order) > 0 ? orderAmountDue(order) : totalNum)}) & Lấy đồ hoàn tất',
            icon: LucideIcons.circleCheck,
            primary: true,
            onTap: () => onPayAndComplete?.call(id),
          )
        else
          OpsSheetAction(
            label: 'Tôi đã lấy đồ — Hoàn tất đơn',
            icon: LucideIcons.circleCheck,
            primary: true,
            onTap: () => onPayAndComplete?.call(id),
          ),
        if (boxId != null)
          OpsSheetAction(
            label: 'Mở $boxLabel để lấy đồ',
            icon: LucideIcons.doorOpen,
            primary: false,
            onTap: onOpenLocker,
          ),
        OpsSheetAction(
          label: 'Đặt lại đơn',
          icon: LucideIcons.repeat,
          primary: false,
          onTap: () => onReorder(id),
        ),
      ],
      if ((rawStatus == 'COMPLETED' || rawStatus == 'CANCELED') &&
          rawStatus != 'EXPIRED')
        OpsSheetAction(
          label: 'Đặt lại đơn',
          icon: LucideIcons.repeat,
          primary: true,
          onTap: () => onReorder(id),
        ),
      if (canDrop)
        OpsSheetAction(
          label: 'Mở $boxLabel để bỏ đồ',
          icon: LucideIcons.doorOpen,
          primary: true,
          onTap: onOpenLocker,
        ),
      if (rawStatus == 'INITIALIZED')
        OpsSheetAction(
          label: 'Tôi đã bỏ đồ vào ô',
          icon: LucideIcons.packageCheck,
          primary: !canDrop,
          onTap: () => onConfirmDrop(id),
        ),
      if (canUsePickupActions &&
          (rawStatus == 'RETURNED' ||
              (rawStatus == 'STORING' && !isRental))) ...[
        if (needsPayOvertime) ...[
          OpsSheetAction(
            label:
                'Thanh toán (${fmtPrice(orderAmountDue(order) > 0 ? orderAmountDue(order) : overtimeFee)}) & Lấy đồ hoàn tất',
            icon: LucideIcons.circleCheck,
            primary: true,
            onTap: () => onPayAndComplete?.call(id),
          ),
          OpsSheetAction(
            label: 'Thanh toán phí quá giờ (${fmtPrice(overtimeFee)}) & Mở ô',
            icon: LucideIcons.creditCard,
            primary: false,
            onTap: () => onPayOvertime(id, overtimeFee),
          ),
        ] else ...[
          OpsSheetAction(
            label: 'Mở $boxLabel để lấy đồ',
            icon: LucideIcons.doorOpen,
            primary: true,
            onTap: onOpenLocker,
          ),
          OpsSheetAction(
            label: 'Tôi đã lấy đồ — hoàn tất',
            icon: LucideIcons.circleCheck,
            primary: false,
            onTap: () => onComplete(id),
          ),
        ],
      ],
      if (isRental && rawStatus == 'STORING' && !boxIncident) ...[
        if (needsPayOvertime) ...[
          OpsSheetAction(
            label:
                'Thanh toán (${fmtPrice(orderAmountDue(order) > 0 ? orderAmountDue(order) : overtimeFee)}) & Lấy đồ hoàn tất',
            icon: LucideIcons.circleCheck,
            primary: true,
            onTap: () => onPayAndComplete?.call(id),
          ),
          OpsSheetAction(
            label: 'Thanh toán phí quá giờ (${fmtPrice(overtimeFee)}) & Mở ô',
            icon: LucideIcons.creditCard,
            primary: false,
            onTap: () => onPayOvertime(id, overtimeFee),
          ),
        ] else ...[
          OpsSheetAction(
            label: 'Mở $boxLabel để trả tủ & lấy đồ',
            icon: LucideIcons.doorOpen,
            primary: true,
            onTap: onOpenLocker,
          ),
        ],
        OpsSheetAction(
          label: 'Gia hạn thuê',
          icon: LucideIcons.timer,
          onTap: () => onExtend(id),
        ),
        OpsSheetAction(
          label: 'Kết thúc thuê & lấy đồ',
          icon: LucideIcons.logOut,
          onTap: () => onEndRental(id),
        ),
      ],
      // Ủy quyền lấy hộ: server chỉ nhận khi đồ đang nằm trong ô (STORING/RETURNED).
      if (onDelegate != null &&
          !isDroneDelivery &&
          (rawStatus == 'STORING' || rawStatus == 'RETURNED'))
        OpsSheetAction(
          label: 'Ủy quyền lấy hộ',
          icon: LucideIcons.userPlus,
          onTap: () => onDelegate!(id),
        ),
      if (onResetPin != null &&
          !isDroneDelivery &&
          '${order['pinCode'] ?? ''}'.isNotEmpty &&
          (rawStatus == 'INITIALIZED' ||
              rawStatus == 'STORING' ||
              rawStatus == 'RETURNED'))
        OpsSheetAction(
          label: 'Đổi mã PIN',
          icon: LucideIcons.keyRound,
          onTap: onResetPin!,
        ),
      if (boxId != null &&
          rawStatus != 'COMPLETED' &&
          rawStatus != 'CANCELED' &&
          rawStatus != 'EXPIRED')
        OpsSheetAction(
          label: 'Báo ô lỗi',
          leading: const AppLottie(
            AppLottieAssets.baoSuCo,
            width: 22,
            height: 22,
          ),
          onTap: () => onReport(boxId),
        ),
      // Đơn drone huỷ được tới khi kỹ thuật viên đã cầm kiện: còn chờ điều phối
      // (AWAITING_DISPATCH) hoặc kỹ thuật viên đang tới lấy (PICKUP_ASSIGNED).
      if (rawStatus == 'INITIALIZED' ||
          (isDroneDelivery &&
              const {
                'AWAITING_DISPATCH',
                'PICKUP_ASSIGNED',
              }.contains(status.toUpperCase())))
        OpsSheetAction(
          label: 'Hủy đơn',
          icon: LucideIcons.circleX,
          danger: true,
          onTap: () => onCancel(id),
        ),
      OpsSheetAction(
        label: 'Chỉ đường tới tủ',
        icon: LucideIcons.map,
        onTap: onDirections,
      ),
      // Backend chỉ nhận yêu cầu hoàn cho đơn có khoản đã thu (ORDER_NOT_PAID nếu
      // chưa trả); đơn đang chờ hoàn / đã hoàn xem ở Hồ sơ › Yêu cầu hoàn tiền.
      if (paymentStatus == 'PAID')
        OpsSheetAction(
          label: 'Yêu cầu hoàn tiền',
          icon: LucideIcons.rotateCcw,
          onTap: () {
            Navigator.pop(context);
            context.push(
              AppRouter.refundRequests,
              extra: {
                'orderId': id,
                'order': order,
              },
            );
          },
        ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (faultReport != null) ...[
          _FaultOrderBanner(
            report: faultReport!,
            boxLabel: boxLabel,
            itemsInside: isPickupPhase,
            logs: faultLogs,
            onViewReport: handleViewReport,
          ),
          const SizedBox(height: 12),
        ],
        Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: statusColor(status).withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: statusColor(status).withValues(alpha: 0.18),
                  width: 1,
                ),
              ),
              padding: const EdgeInsets.all(4),
              child: AppLottie(
                _isDeliveryOrder(order['type'] as String?)
                    ? AppLottieAssets.airplaneBox
                    : AppLottieAssets.box,
                fallback: (context) => Icon(
                  typeIcon(order['type'] as String?),
                  color: statusColor(status),
                  size: 24,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    typeLabel(order['type'] as String?),
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                      color: opsDark,
                    ),
                  ),
                  Text(
                    '${order['orderCode'] ?? ''}',
                    style: const TextStyle(fontSize: 12, color: opsMutedText),
                  ),
                ],
              ),
            ),
            StatusChip(status),
          ],
        ),
        const SizedBox(height: 16),
        if (boxIncident)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: OpsBanner(
              tone: OpsBannerTone.warning,
              icon: LucideIcons.circlePause,
              text: boxIncidentPausedText(order),
            ),
          )
        else if (rawStatus == 'EXPIRED')
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: OpsBanner(
              tone: OpsBannerTone.danger,
              icon: LucideIcons.triangleAlert,
              text: (canPay || orderAmountDue(order) > 0)
                  ? 'Đơn đã quá hạn lưu tủ ${config.overdueReleaseHoursLabel}. Ô tủ đã được giải phóng và đồ đã chuyển về bảo quản an toàn. Quý khách vui lòng thanh toán phí còn lại và bấm "Thanh toán & lấy đồ" để hoàn tất.'
                  : 'Đơn đã quá hạn lưu tủ ${config.overdueReleaseHoursLabel}. Ô tủ đã được giải phóng và đồ đã chuyển về bảo quản an toàn. Quý khách vui lòng kiểm tra nhận đồ và bấm "Tôi đã lấy đồ — Hoàn tất đơn" để hoàn tất.',
            ),
          )
        else if (overdue)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: OpsBanner(
              tone: isOvertimePaid ? OpsBannerTone.info : OpsBannerTone.danger,
              icon: isOvertimePaid
                  ? LucideIcons.circleCheck
                  : LucideIcons.triangleAlert,
              text: isOvertimePaid
                  ? 'Đơn quá hạn đã thanh toán phí quá giờ. Mời bạn mở ô để lấy đồ và hoàn tất trả tủ.'
                  : 'Đơn đã quá hạn lấy — cần thanh toán phí quá giờ để mở tủ. '
                        '${overtimePolicyText(config)}',
            ),
          )
        else if (rawStatus == 'INITIALIZED' && canPay)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: OpsBanner(
              tone: OpsBannerTone.warning,
              icon: LucideIcons.circleAlert,
              text:
                  'Đơn hàng chưa thanh toán. Vui lòng thanh toán trong vòng ${config.autoCancelUnpaidMinutes} phút để giữ chỗ tủ, hoặc bấm "Hủy đơn" bên dưới để giải phóng ô tủ ngay.',
            ),
          ),

        // Khối Card Hồ Sơ Điều Chuyển Ô Kỹ Thuật (nếu có)
        if (relocation.isRelocated) ...[
          _OrderRelocationCard(
            relocation: relocation,
            onViewReport: handleViewReport,
          ),
          const SizedBox(height: 14),
        ],

        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: opsSurface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: opsBorder),
          ),
          child: Column(
            children: [
              OpsInfoRow(
                icon: LucideIcons.warehouse,
                label: 'Tủ',
                value: lockerName ?? 'Chưa tra được tên tủ',
              ),
              // Địa chỉ nơi đặt tủ — người nhận cần biết đi đâu, không chỉ tủ tên gì.
              if (lockerAddress != null)
                OpsInfoRow(
                  icon: LucideIcons.mapPin,
                  label: 'Địa điểm',
                  value: lockerAddress,
                ),

              // Hiển thị chi tiết ô tủ theo nghiệp vụ chuyển ô hoặc bình thường
              if (relocation.isRelocated) ...[
                OpsInfoRow(
                  icon: LucideIcons.grid3x3,
                  label: 'Ô mới tiếp nhận',
                  value: 'Ô số ${relocation.newBoxNumber ?? sendBoxNumber ?? '—'} (Đang an toàn)',
                  valueColor: const Color(0xFF15803D),
                ),
                OpsInfoRow(
                  icon: LucideIcons.circleAlert,
                  label: 'Ô ban đầu',
                  value: 'Ô số ${relocation.oldBoxNumber ?? '—'} (Gặp sự cố)',
                  valueColor: const Color(0xFFDC2626),
                ),
                if (relocation.oldBoxOpenedTime != null && relocation.oldBoxOpenedTime!.isNotEmpty)
                  OpsInfoRow(
                    icon: LucideIcons.doorOpen,
                    label: 'Thời gian mở ô cũ',
                    value: relocation.oldBoxOpenedTime!,
                    valueColor: const Color(0xFFB45309),
                  ),
                if (relocation.relocatedTime != null && relocation.relocatedTime!.isNotEmpty)
                  OpsInfoRow(
                    icon: LucideIcons.checkCheck,
                    label: 'Thời gian chuyển ô',
                    value: relocation.relocatedTime!,
                    valueColor: const Color(0xFF15803D),
                  ),
                OpsInfoRow(
                  icon: LucideIcons.keyRound,
                  label: 'Mã PIN ban đầu',
                  value: 'Đã vô hiệu hoá (Mã cũ hết hạn)',
                  valueColor: const Color(0xFF64748B),
                ),
              ] else ...[
                OpsInfoRow(
                  icon: LucideIcons.grid3x3,
                  label: 'Ô',
                  value: _boxRouteLabel(
                    sendBoxNumber,
                    receiveBoxNumber,
                    rawStatus,
                  ),
                ),
              ],
              if (createdAt != null)
                OpsInfoRow(
                  icon: LucideIcons.calendar,
                  label: 'Ngày đặt',
                  value: fmtDateTime(createdAt),
                ),
              if (isRental && rentalHours != null)
                OpsInfoRow(
                  icon: LucideIcons.timer,
                  label: 'Thời gian thuê',
                  value: '$rentalHours giờ',
                ),
              if (deadline != null)
                OpsInfoRow(
                  icon: LucideIcons.clock,
                  label: 'Hạn ban đầu',
                  value: fmtDateTime(deadline),
                ),
              if (overdue) ...[
                OpsInfoRow(
                  icon: LucideIcons.clockAlert,
                  label: 'Thời gian quá hạn',
                  value: overtimeDurationText.isNotEmpty
                      ? overtimeDurationText
                      : 'Đã quá hạn',
                  valueColor: const Color(0xFFDC2626),
                ),
                OpsInfoRow(
                  icon: LucideIcons.receiptText,
                  label: 'Đơn giá quá giờ',
                  value: '${fmtPrice(overtimeRateOf(order, config))}/giờ',
                ),
                if (overtimeCappedOf(order) &&
                    (config.pickupMaxOvertimePercent > 0 ||
                        config.pickupMaxOvertimeFee > 0))
                  OpsInfoRow(
                    icon: LucideIcons.shieldAlert,
                    label: 'Quy định trần',
                    value: [
                      if (config.pickupMaxOvertimeFee > 0)
                        'Tối đa ${fmtPrice(config.pickupMaxOvertimeFee)}',
                      if (config.pickupMaxOvertimePercent > 0)
                        '${config.pickupMaxOvertimePercent}% đơn',
                    ].join(' & '),
                  ),
                OpsInfoRow(
                  icon: LucideIcons.circleAlert,
                  label: 'Phí quá giờ tạm tính',
                  value: fmtPrice(overtimeFee),
                  valueColor: const Color(0xFFEA580C),
                ),
                OpsInfoRow(
                  icon: LucideIcons.badgeAlert,
                  label: 'Trạng thái phạt',
                  value: isOvertimePaid ? 'Đã thanh toán' : 'Chưa thanh toán',
                  valueColor: isOvertimePaid
                      ? const Color(0xFF15803D)
                      : const Color(0xFFDC2626),
                ),
                if (needsPayOvertime)
                  OpsInfoRow(
                    icon: LucideIcons.circleDollarSign,
                    label: 'Cần nộp để mở ô',
                    value: fmtPrice(overtimeFee),
                    valueColor: const Color(0xFFDC2626),
                  ),
              ],
              if (receiverLabel.isNotEmpty)
                OpsInfoRow(
                  icon: LucideIcons.userCheck,
                  label: 'Người nhận',
                  value: receiverLabel,
                ),
              if (receiverEmail != null)
                OrderContactRow(
                  icon: LucideIcons.mail,
                  label: 'Email người nhận',
                  value: receiverEmail,
                ),
              if (delegatedAt != null) ...[
                OpsInfoRow(
                  icon: LucideIcons.userPlus,
                  label: 'Ủy quyền lấy hộ cho',
                  value: delegateLabel.isEmpty
                      ? 'Người được ủy quyền'
                      : delegateLabel,
                  valueColor: const Color(0xFF7C3AED),
                ),
                if (delegateNote != null)
                  OpsInfoRow(
                    icon: LucideIcons.messageSquareText,
                    label: 'Lời nhắn ủy quyền',
                    value: delegateNote,
                  ),
                OpsInfoRow(
                  icon: LucideIcons.clock,
                  label: 'Ủy quyền lúc',
                  value: fmtDateTime(delegatedAt),
                ),
              ],
              if (intendedReceiveAt != null)
                OpsInfoRow(
                  icon: LucideIcons.calendarClock,
                  label: 'Dự kiến người nhận lấy',
                  value: fmtDateTime(intendedReceiveAt),
                ),
              if (deliveryAddress != null && deliveryAddress.isNotEmpty)
                OpsInfoRow(
                  icon: LucideIcons.truck,
                  label: 'Địa chỉ giao',
                  value: deliveryAddress,
                ),
              if (isDroneDelivery && sourceLockerName != null)
                OpsInfoRow(
                  icon: LucideIcons.planeTakeoff,
                  label: 'Gửi từ tủ',
                  value: sourceLockerName!,
                ),
              if (isDroneDelivery && routeDistance != null)
                OpsInfoRow(
                  icon: LucideIcons.route,
                  label: 'Quãng đường bay',
                  value: fmtDistanceMeters(routeDistance),
                ),
              for (final line in serviceLines)
                OpsInfoRow(
                  icon: LucideIcons.listChecks,
                  label: 'Dịch vụ',
                  value: line,
                ),
              if ((discountAmount > 0 || pointsUsed > 0) && originalPrice > 0)
                OpsInfoRow(
                  icon: LucideIcons.tag,
                  label: 'Giá gốc',
                  value: fmtPrice(originalPrice),
                ),
              if (hasExtra)
                OpsInfoRow(
                  icon: LucideIcons.circlePlus,
                  label: 'Phí phát sinh',
                  value: fmtPrice(extraFee),
                  valueColor: const Color(0xFFB45309),
                ),
              if (discountAmount > 0)
                OpsInfoRow(
                  icon: LucideIcons.badgePercent,
                  label: 'Giảm giá',
                  value: promotionCode != null && promotionCode.isNotEmpty
                      ? '-${fmtPrice(discountAmount)} ($promotionCode)'
                      : '-${fmtPrice(discountAmount)}',
                  valueColor: const Color(0xFF15803D),
                ),
              if (pointsUsed > 0)
                OpsInfoRow(
                  icon: LucideIcons.sparkles,
                  label: 'Điểm thưởng',
                  value: loyaltyPointsDiscountText(pointsUsed, pointsDiscount),
                  valueColor: const Color(0xFF15803D),
                ),
              OpsInfoRow(
                icon: LucideIcons.wallet,
                label: 'Tổng tiền',
                value: fmtPrice(order['totalPrice']),
                valueColor: opsDark,
              ),
              // Gia hạn / phí quá hạn cộng vào tổng nhưng phần cũ đã trả rồi,
              // nên tách rõ đã trả bao nhiêu và còn thiếu bao nhiêu.
              if (rawStatus != 'COMPLETED' &&
                  orderAmountDue(order) > 0 &&
                  (_asDouble(order['paidAmount']) ?? 0) > 0) ...[
                OpsInfoRow(
                  icon: LucideIcons.receiptText,
                  label: 'Đã thanh toán',
                  value: fmtPrice(order['paidAmount']),
                  valueColor: const Color(0xFF15803D),
                ),
                OpsInfoRow(
                  icon: LucideIcons.circleDollarSign,
                  label: 'Còn phải trả',
                  value: fmtPrice(orderAmountDue(order)),
                  valueColor: const Color(0xFFB45309),
                ),
              ],
              OpsInfoRow(
                icon: LucideIcons.checkCheck,
                label: 'Thanh toán',
                value: switch (paymentStatus) {
                  'PAID' => 'Đã thanh toán',
                  'REFUND_PENDING' => 'Chờ hoàn tiền',
                  'REFUNDED' => 'Đã hoàn tiền',
                  _ => 'Chưa thanh toán',
                },
                valueColor: paymentStatus == 'PAID'
                    ? const Color(0xFF15803D)
                    : (paymentStatus == 'REFUNDED'
                          ? const Color(0xFF64748B)
                          : (paymentStatus == 'REFUND_PENDING'
                              ? const Color(0xFFD97706)
                              : const Color(0xFFB45309))),
              ),
              if (paidAt != null && paymentStatus != 'UNPAID')
                OpsInfoRow(
                  icon: LucideIcons.receiptText,
                  label: 'Thanh toán lúc',
                  value: fmtDateTime(paidAt),
                ),
              // Hình thức thanh toán + mã giao dịch lấy từ payment-service.
              _PaymentTraceRows(
                orderId: _asInt(order['id']),
                order: order,
                service: service,
              ),
              if (customerNote != null && customerNote.isNotEmpty)
                OpsInfoRow(
                  icon: LucideIcons.stickyNote,
                  label: 'Ghi chú',
                  value: customerNote,
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        OrderDetailSection(
          title: 'Kiện hàng',
          icon: LucideIcons.package,
          rows: orderParcelRows(parcel),
        ),
        OrderDetailSection(
          title: 'Sự cố giao hàng',
          icon: LucideIcons.triangleAlert,
          rows: [
            if (blockLabel != null)
              OpsInfoRow(
                icon: LucideIcons.circlePause,
                label: 'Đang tạm dừng',
                value: blockLabel,
                valueColor: const Color(0xFFEA580C),
              ),
            if (blockLabel != null && order['deliveryBlockedAt'] != null)
              OpsInfoRow(
                icon: LucideIcons.clock,
                label: 'Tạm dừng lúc',
                value: fmtDateTime(order['deliveryBlockedAt']),
              ),
            if (failureLabel != null)
              OpsInfoRow(
                icon: LucideIcons.circleX,
                label: 'Giao không hoàn tất',
                value: failureLabel,
                valueColor: const Color(0xFFDC2626),
              ),
            if (failureLabel != null && order['failedAt'] != null)
              OpsInfoRow(
                icon: LucideIcons.clock,
                label: 'Ghi nhận lúc',
                value: fmtDateTime(order['failedAt']),
              ),
            if (order['parcelReturnedAt'] != null)
              OpsInfoRow(
                icon: LucideIcons.undo2,
                label: 'Đã trả kiện cho bạn',
                value: fmtDateTime(order['parcelReturnedAt']),
              ),
          ],
        ),
        if (order['pinCode'] != null && canUsePickupActions) ...[
          if (relocation.isRelocated)
            Center(
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF86EFAC)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(LucideIcons.keyRound, size: 14, color: Color(0xFF15803D)),
                    const SizedBox(width: 6),
                    Text(
                      'Mã PIN mở Ô MỚI (#${relocation.newBoxNumber ?? '4'}):',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF15803D),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          Center(
            child: AccessCredentials(
              pin: order['pinCode'] as String?,
              qrToken: order['qrToken'] as String?,
            ),
          ),
          if (relocation.isRelocated)
            const Padding(
              padding: EdgeInsets.only(top: 6),
              child: Center(
                child: Text(
                  '🔒 Mã PIN ô cũ đã bị vô hiệu hoá. Chỉ sử dụng mã trên để mở ô mới an toàn.',
                  style: TextStyle(
                    fontSize: 11,
                    color: Color(0xFF64748B),
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ),
          if (receiverShare != null) ...[
            const SizedBox(height: 14),
            PickupCodeShareActions(share: receiverShare),
          ],
        ],
        const SizedBox(height: 16),
        ...actions,
        const SizedBox(height: 20),
        const Divider(height: 1, color: opsBorder),
        const SizedBox(height: 12),
        OrderDetailSection(
          title: 'Mốc thời gian',
          icon: LucideIcons.milestone,
          footer: milestones.isEmpty
              ? null
              : OrderMilestoneTimeline(milestones: milestones),
        ),
        OrderStatusTimeline(orderId: id, service: service),
        const SizedBox(height: 12),
        _OrderIncidentResolutionSection(
          orderId: id,
          order: order,
          report: faultReport,
          logs: faultLogs,
          service: service,
        ),
        if (OrderFeedbackSection.appliesTo(rawStatus)) ...[
          const SizedBox(height: 8),
          OrderFeedbackSection(orderId: id, status: rawStatus, service: service),
        ],
        const SizedBox(height: 8),
      ],
    );
  }
}

/// Hình thức thanh toán + mã giao dịch của đơn.
///
/// `OrderResponse` không mang thông tin này (nằm ở payment-service), nên chi
/// tiết đơn của khách trước đây chỉ có "Đã/Chưa thanh toán" mà không biết trả
/// bằng gì và mã giao dịch nào để đối soát.
class _PaymentTraceRows extends StatefulWidget {
  const _PaymentTraceRows({
    required this.orderId,
    this.order,
    this.service,
  });

  final int? orderId;
  final Map<String, dynamic>? order;
  final LockerOpsService? service;

  @override
  State<_PaymentTraceRows> createState() => _PaymentTraceRowsState();
}

class _PaymentTraceData {
  const _PaymentTraceData({
    required this.payments,
    required this.timeline,
    required this.refunds,
  });

  final List<Map<String, dynamic>> payments;
  final List<Map<String, dynamic>> timeline;
  final List<Map<String, dynamic>> refunds;
}

class _PaymentTraceRowsState extends State<_PaymentTraceRows> {
  late Future<dynamic> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  @override
  void reassemble() {
    super.reassemble();
    _future = _load();
  }

  Future<_PaymentTraceData> _load() async {
    final id = widget.orderId;
    if (id == null) {
      return const _PaymentTraceData(payments: [], timeline: [], refunds: []);
    }
    final svc = widget.service ?? LockerOpsService();
    try {
      final results = await Future.wait([
        svc.paymentsByOrder(id).catchError((_) => <Map<String, dynamic>>[]),
        svc.orderTimeline(id).catchError((_) => <Map<String, dynamic>>[]),
        svc.refundsByOrder(id).catchError((_) => <Map<String, dynamic>>[]),
      ]);
      return _PaymentTraceData(
        payments: results[0],
        timeline: results[1],
        refunds: results[2],
      );
    } catch (_) {
      // Chi tiết đơn vẫn phải mở được khi payment-service lỗi.
      return const _PaymentTraceData(payments: [], timeline: [], refunds: []);
    }
  }

  static String _methodLabel(String? method) => switch (method?.toUpperCase()) {
    'WALLET' => 'Ví Lock.R',
    'SEPAY' => 'Chuyển khoản (SePay)',
    'VNPAY' => 'VNPay',
    'MOMO' => 'MoMo',
    'CASH' => 'Tiền mặt',
    null => '—',
    final other => other,
  };

  /// Kiểm tra xem giao dịch thanh toán này có phải phát sinh do gia hạn thuê tủ hay không.
  static bool _isRentalExtensionPayment({
    required Map<String, dynamic> payment,
    required Map<String, dynamic>? order,
    required List<Map<String, dynamic>> timeline,
    required int index,
  }) {
    final orderType =
        ('${order?['type'] ?? order?['serviceCategory'] ?? ''}').toUpperCase();
    if (orderType != 'RENTAL') return false;
    if (index == 0) return false;

    final desc = '${payment['description'] ?? ''}'.toLowerCase();
    if (desc.contains('quá hạn') ||
        desc.contains('quá giờ') ||
        desc.contains('overtime')) {
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<dynamic>(
      future: _future,
      builder: (context, snapshot) {
        final raw = snapshot.data;
        final List<Map<String, dynamic>> payments;
        final List<Map<String, dynamic>> timeline;
        final List<Map<String, dynamic>> refunds;
        if (raw is _PaymentTraceData) {
          payments = raw.payments;
          timeline = raw.timeline;
          refunds = raw.refunds;
        } else if (raw is List) {
          payments = raw.cast<Map<String, dynamic>>();
          timeline = const [];
          refunds = const [];
        } else {
          payments = const [];
          timeline = const [];
          refunds = const [];
        }

        final done = payments
            .where((p) => '${p['status']}'.toUpperCase() == 'COMPLETED')
            .toList();
        if (done.isEmpty && refunds.isEmpty) return const SizedBox.shrink();

        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < done.length; i++) ...[
              if (done.length > 1) ...[
                if (i > 0) const SizedBox(height: 14),
                OpsSectionLabel(
                  _sectionLabel(
                    done[i],
                    i,
                    isRentalExtension: _isRentalExtensionPayment(
                      payment: done[i],
                      order: widget.order,
                      timeline: timeline,
                      index: i,
                    ),
                  ),
                  icon: LucideIcons.receiptText,
                ),
              ],
              OpsInfoRow(
                icon: LucideIcons.creditCard,
                label: 'Hình thức thanh toán',
                value: _methodLabel(done[i]['method'] as String?),
              ),
              OpsInfoRow(
                icon: LucideIcons.hash,
                label: 'Mã giao dịch',
                value: _transactionCode(done[i]),
              ),
              if (done[i]['amount'] != null)
                OpsInfoRow(
                  icon: LucideIcons.banknote,
                  label: 'Số tiền',
                  value: fmtPrice(done[i]['amount']),
                  valueColor: const Color(0xFF15803D),
                ),
              if (done[i]['createdAt'] != null)
                OpsInfoRow(
                  icon: LucideIcons.calendarCheck,
                  label: 'Thời gian thanh toán',
                  value: fmtDateTime(done[i]['createdAt']),
                ),
            ],

            // Khối chi tiết hoàn tiền (bao gồm ảnh minh chứng, thời gian, text)
            if (refunds.isNotEmpty) ...[
              for (final rf in refunds) ...[
                const SizedBox(height: 14),
                _buildRefundCard(context, rf),
              ],
            ],
          ],
        );
      },
    );
  }

  Widget _buildRefundCard(BuildContext context, Map<String, dynamic> rf) {
    final status = '${rf['status'] ?? 'PENDING'}'.toUpperCase();
    final isCompleted = status == 'COMPLETED';
    final isRejected = status == 'REJECTED';

    final statusText = isCompleted
        ? 'Đã chuyển tiền'
        : (isRejected ? 'Bị từ chối' : 'Chờ chuyển khoản');
    final statusColor = isCompleted
        ? const Color(0xFF15803D)
        : (isRejected ? const Color(0xFFE11D48) : const Color(0xFFD97706));
    final statusBg = isCompleted
        ? const Color(0xFFDCFCE7)
        : (isRejected ? const Color(0xFFFFE4E6) : const Color(0xFFFEF3C7));

    final bankDisplay = [
      if (rf['bankName'] != null || rf['bankCode'] != null)
        '${rf['bankName'] ?? rf['bankCode']}',
      if (rf['accountNumber'] != null && '${rf['accountNumber']}'.isNotEmpty)
        '${rf['accountNumber']}',
    ].join(' - ');

    final timeDisplay = rf['processedAt'] != null
        ? fmtDateTime(rf['processedAt'])
        : (rf['requestedAt'] != null ? fmtDateTime(rf['requestedAt']) : null);

    void onNavigateRefunds() {
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }
      context.push(
        AppRouter.refundRequests,
        extra: {
          'orderId': widget.orderId ?? widget.order?['id'] ?? rf['orderId'],
          'order': widget.order,
        },
      );
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onNavigateRefunds,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(LucideIcons.rotateCcw, size: 15, color: statusColor),
                      const SizedBox(width: 6),
                      Text(
                        'Hoàn tiền #${rf['id'] ?? ''}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: statusBg,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      statusText,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: statusColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Số tiền hoàn
              if (rf['amount'] != null)
                OpsInfoRow(
                  icon: LucideIcons.banknote,
                  label: 'Số tiền hoàn',
                  value: fmtPrice(rf['amount']),
                  valueColor: isCompleted ? const Color(0xFF15803D) : const Color(0xFFD97706),
                ),

              // Tài khoản nhận
              if (bankDisplay.isNotEmpty)
                OpsInfoRow(
                  icon: LucideIcons.building2,
                  label: 'Tài khoản nhận',
                  value: bankDisplay,
                ),

              // Thời gian hoàn tất / yêu cầu
              if (timeDisplay != null)
                OpsInfoRow(
                  icon: LucideIcons.clock,
                  label: isCompleted ? 'Thời gian hoàn tất' : 'Thời gian yêu cầu',
                  value: timeDisplay,
                ),

              const SizedBox(height: 8),
              const Divider(height: 1, color: Color(0xFFE2E8F0)),
              const SizedBox(height: 8),

              // Dòng chữ xem chi tiết ở mục hoàn tiền
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(LucideIcons.arrowUpRight, size: 13, color: Color(0xFF0284C7)),
                      SizedBox(width: 5),
                      Text(
                        'Xem chi tiết ở mục Hoàn tiền',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF0284C7),
                        ),
                      ),
                    ],
                  ),
                  Icon(LucideIcons.chevronRight, size: 13, color: Color(0xFF0284C7)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _sectionLabel(
    Map<String, dynamic> payment,
    int index, {
    bool isRentalExtension = false,
  }) {
    var description = '${payment['description'] ?? ''}'.trim();
    if (isRentalExtension) {
      if (description.isEmpty) {
        description = 'Thanh toán gia hạn thời gian';
      } else {
        description = description.replaceAll(
          RegExp(r'thanh toán bổ sung', caseSensitive: false),
          'Thanh toán gia hạn thời gian',
        );
      }
    }
    final order = 'Lần ${index + 1}';
    return description.isEmpty ? order : '$order · $description';
  }

  static String _transactionCode(Map<String, dynamic> payment) {
    for (final key in ['referenceTransactionId', 'referenceId', 'id']) {
      final value = payment[key];
      if (value != null && '$value'.trim().isNotEmpty) return '$value';
    }
    return '—';
  }
}

// ───────────────────────────────────────────────────────────────────────────────
// Phương án xử lý ô tủ từ Incident Notes trong Order Timeline
// ───────────────────────────────────────────────────────────────────────────────

/// Hiển thị chi tiết phương án xử lý ô tủ khi có sự cố — lấy từ incident notes
/// trong order timeline ("[THàNH CÔNG]", "[ĐIỀU CHUYỂN Ô]", v.v.).
/// Chỉ hiển khi timeline có ít nhất 1 note dạng incident resolution tag.
class _OrderIncidentResolutionSection extends StatefulWidget {
  const _OrderIncidentResolutionSection({
    required this.orderId,
    this.order,
    this.report,
    this.logs = const [],
    this.service,
  });

  final int orderId;
  final Map<String, dynamic>? order;
  final Map<String, dynamic>? report;
  final List<Map<String, dynamic>> logs;
  final LockerOpsService? service;

  @override
  State<_OrderIncidentResolutionSection> createState() =>
      _OrderIncidentResolutionSectionState();
}

class _OrderIncidentResolutionSectionState
    extends State<_OrderIncidentResolutionSection> {
  LockerOpsService? get _svc {
    if (widget.service != null) return widget.service;
    try {
      return LockerOpsService();
    } catch (_) {
      return null;
    }
  }
  List<Map<String, dynamic>> _incidentEvents = const [];
  // Danh sách thường (không const): còn thêm ảnh từ nhật ký vào sau.
  List<Map<String, dynamic>> _attachments = [];
  Map<String, dynamic>? _resolvedReport;
  bool _loading = true;

  // Danh sách tag prefix của incident notes
  static const _incidentTags = [
    '[THÀNH CÔNG]',
    '[ĐIỀU CHUYỂN Ô]',
    '[NIÊM PHONG VỀ HUB]',
    '[BÀN GIAO TRỰC TIẾP]',
    '[XÁC NHẬN & KHÓA Ô]',
    '[XỬ LÝ TẠI CHỖ]',
    '[NGHIỆM THU]',
    '[KHÓA BẢO TRÌ]',
  ];

  static final _tagRegex = RegExp(r'^(\[[^\]]+\])\s*(.*)', dotAll: true);

  @override
  void initState() {
    super.initState();
    _resolvedReport = widget.report;
    _load();
  }

  Future<void> _load() async {
    final svc = _svc;
    if (svc == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    try {
      final events = await svc.orderTimeline(widget.orderId);
      if (!mounted) return;
      // Lọc chỉ giữ incident notes dựa trên tag
      final incidents = events.where((e) {
        final note = (e['note'] ?? e['description'] ?? '').toString().trim();
        final upperNote = note.toUpperCase();
        return _incidentTags.any((t) => upperNote.contains(t.toUpperCase()));
      }).toList();

      // Nếu timeline chưa có incident events nhưng widget.logs có ghi nhận từ KTV
      if (incidents.isEmpty && widget.logs.isNotEmpty) {
        for (final l in widget.logs) {
          final note = (l['note'] ?? l['description'] ?? '').toString().trim();
          final upperNote = note.toUpperCase();
          if (_incidentTags.any((t) => upperNote.contains(t.toUpperCase())) ||
              upperNote.contains('ĐIỀU CHUYỂN') ||
              upperNote.contains('SỰ CỐ') ||
              upperNote.contains('BẢO TRÌ') ||
              upperNote.contains('HIỆN TRƯỜNG')) {
            incidents.add({
              'note': note,
              'changedAt': l['createdAt'] ?? l['created_at'] ?? l['timestamp'] ?? l['changedAt'],
              'actorUserId': l['actorUserId'] ?? l['userId'],
            });
          }
        }
      }

      // Chưa có phiếu truyền vào mà timeline có ghi chú sự cố ⇒ hỏi phiếu gắn với
      // đơn theo `orderId` (trường có cấu trúc, không dò mã trong ghi chú).
      if (_resolvedReport == null && incidents.isNotEmpty) {
        try {
          final linked = await svc.myReportsForOrder(widget.orderId);
          if (linked.isNotEmpty) _resolvedReport = linked.first;
        } catch (_) {}
      }

      // Bổ sung ảnh từ widget.logs nếu có
      for (final l in widget.logs) {
        final atts = l['attachments'];
        if (atts is List) {
          for (final a in atts) {
            if (a is Map<String, dynamic>) {
              _attachments.add(a);
            }
          }
        }
      }

      // Tải danh sách ảnh minh chứng đính kèm nếu có reportId
      final repId = _asInt(_resolvedReport?['id']);
      if (repId != null) {
        try {
          final atts = await svc.myReportAttachments(repId);
          if (atts.isNotEmpty && mounted) {
            _attachments = [..._attachments, ...atts];
          }
        } catch (_) {}
      }

      if (!mounted) return;
      setState(() {
        _incidentEvents = incidents;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  static String _fmtDt(dynamic value) {
    if (value == null) return '';
    try {
      final d = DateTime.parse(value.toString()).toLocal();
      String tw(int n) => n.toString().padLeft(2, '0');
      return '${tw(d.hour)}:${tw(d.minute)} ${tw(d.day)}/${tw(d.month)}/${d.year}';
    } catch (_) {
      return '';
    }
  }

  ({Color bg, Color fg, IconData icon}) _tagStyle(String upperTag) {
    if (upperTag.contains('THÀNH CÔNG') ||
        upperTag.contains('NGHIỆM THU') ||
        upperTag.contains('XỬ LÝ TẠI CHỖ')) {
      return (
        bg: const Color(0xFFDCFCE7),
        fg: const Color(0xFF15803D),
        icon: LucideIcons.circleCheck,
      );
    } else if (upperTag.contains('ĐIỀU CHUYỂN')) {
      return (
        bg: const Color(0xFFE0F2FE),
        fg: const Color(0xFF0369A1),
        icon: LucideIcons.arrowRightLeft,
      );
    } else if (upperTag.contains('NIÊM PHONG') || upperTag.contains('HUB')) {
      return (
        bg: const Color(0xFFFEF3C7),
        fg: const Color(0xFFB45309),
        icon: LucideIcons.packageCheck,
      );
    } else if (upperTag.contains('BÀN GIAO')) {
      return (
        bg: const Color(0xFFF3E8FF),
        fg: const Color(0xFF7E22CE),
        icon: LucideIcons.handshake,
      );
    } else if (upperTag.contains('KHÓA BẢO TRÌ') ||
        upperTag.contains('XÁC NHẬN')) {
      return (
        bg: const Color(0xFFFEF2F2),
        fg: const Color(0xFFDC2626),
        icon: LucideIcons.lockKeyhole,
      );
    }
    return (
      bg: const Color(0xFFF1F5F9),
      fg: const Color(0xFF334155),
      icon: LucideIcons.info,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading || (_incidentEvents.isEmpty && _resolvedReport == null)) {
      return const SizedBox.shrink();
    }

    final repId = _asInt(_resolvedReport?['id']);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(height: 1, color: opsBorder),
        const SizedBox(height: 12),
        Row(
          children: [
            const Icon(LucideIcons.shieldCheck, size: 16, color: opsPrimary),
            const SizedBox(width: 6),
            const Expanded(
              child: Text(
                'Biên bản can thiệp & bảo vệ tài sản:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: opsDark,
                ),
              ),
            ),
            if (repId != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: opsPrimary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'RPT-$repId',
                  style: const TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.bold,
                    color: opsPrimary,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        for (final event in _incidentEvents) ...[
          Builder(
            builder: (context) {
              final rawNote =
                  (event['note'] ?? event['description'] ?? '').toString().trim();
              final match = _tagRegex.firstMatch(rawNote);
              final tag = match?.group(1) ?? rawNote;
              final rest = match?.group(2) ?? '';
              final style = _tagStyle(tag.toUpperCase());
              final ts = _fmtDt(
                event['changedAt'] ?? event['createdAt'] ?? event['timestamp'],
              );
              // Danh sách thumbnail ảnh KTV chụp minh chứng (nếu có)
              final validPhotos = _attachments.where((a) {
                final u = (a['thumbnailUrl'] ??
                        a['secureUrl'] ??
                        a['url'] ??
                        '')
                    .toString()
                    .trim();
                return u.startsWith('http://') || u.startsWith('https://');
              }).toList();

              return Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: style.bg.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: style.bg),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(style.icon, size: 14, color: style.fg),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            tag,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: style.fg,
                            ),
                          ),
                        ),
                        if (ts.isNotEmpty)
                          Text(
                            ts,
                            style: const TextStyle(
                              fontSize: 11,
                              color: opsMutedText,
                            ),
                          ),
                      ],
                    ),
                    if (rest.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        rest,
                        style: TextStyle(
                          fontSize: 12.5,
                          color: style.fg.withValues(alpha: 0.9),
                          height: 1.4,
                        ),
                      ),
                    ],

                    if (validPhotos.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: () {
                          UserReportDetailSheet.show(
                            context,
                            report: _resolvedReport ?? {
                              'id': repId ?? 0,
                              'title':
                                  'Sự cố ô tủ - Đơn hàng #${widget.order?['orderCode'] ?? widget.orderId}',
                              'description': rest,
                              'status': 'RESOLVED',
                            },
                          );
                        },
                        child: Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            ...validPhotos.take(3).map((a) {
                              final url = (a['thumbnailUrl'] ??
                                      a['secureUrl'] ??
                                      a['url'] ??
                                      '')
                                  .toString()
                                  .trim();
                              return ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  width: 42,
                                  height: 42,
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade200,
                                    border: Border.all(
                                      color: style.fg.withValues(alpha: 0.25),
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Image.network(
                                    url,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Icon(
                                      Icons.broken_image,
                                      size: 16,
                                      color: Colors.grey.shade400,
                                    ),
                                  ),
                                ),
                              );
                            }),
                            if (validPhotos.length > 3)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: style.fg.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  '+${validPhotos.length - 3} ảnh',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: style.fg,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                    // Nút bấm chuyển sang xem toàn bộ báo cáo & ảnh minh chứng KTV
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            UserReportDetailSheet.show(
                              context,
                              report: _resolvedReport ?? {
                                'id': repId ?? 0,
                                'title':
                                    'Sự cố ô tủ - Đơn hàng #${widget.order?['orderCode'] ?? widget.orderId}',
                                'description': rest,
                                'status': 'RESOLVED',
                              },
                            );
                          },
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 7,
                            ),
                            decoration: BoxDecoration(
                              color: style.fg.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: style.fg.withValues(alpha: 0.25),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  LucideIcons.fileCheck,
                                  size: 13,
                                  color: style.fg,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Xem chi tiết & ảnh minh chứng KTV',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: style.fg,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Icon(
                                  LucideIcons.chevronRight,
                                  size: 13,
                                  color: style.fg,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    // Thông báo người dùng nếu có nội dung actionable
                    if (tag.toUpperCase().contains('ĐIỀU CHUYỂN'))
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          'ℹ️ Hàng của bạn đã được chuyển sang ô mới. Vui lòng kiểm tra mã mở ô mới trong app.',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: style.fg,
                            height: 1.35,
                          ),
                        ),
                      )
                    else if (tag.toUpperCase().contains('NIÊM PHONG') ||
                        tag.toUpperCase().contains('HUB'))
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          'ℹ️ Hàng được niêm phong an toàn và đưa về Hub. Nhân viên sẽ liên hệ bạn để thu xếp lại.',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: style.fg,
                            height: 1.35,
                          ),
                        ),
                      )
                    else if (tag.toUpperCase().contains('BÀN GIAO'))
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          'ℹ️ Hàng đã được bàn giao trực tiếp. Nếu có thắc mắc vui lòng liên hệ bộ phận CSKH.',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: style.fg,
                            height: 1.35,
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ],
      ],
    );
  }
}
