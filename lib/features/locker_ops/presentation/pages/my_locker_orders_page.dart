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
import 'package:smart_laundry_locker/core/l10n/l10n.dart';

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
  /// Mới nhất trước. Một đơn có thể dính nhiều phiếu: phiếu của ô cũ (KTV đã chuyển hàng
  /// sang ô khác, phiếu còn mở để sửa ô) và phiếu của ô đang giữ đồ.
  Map<int, List<Map<String, dynamic>>> _reportsByOrderId = {};
  Map<String, List<Map<String, dynamic>>> _reportsByOrderCode = {};
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
      final reportsByOrderId = <int, List<Map<String, dynamic>>>{};
      final reportsByOrderCode = <String, List<Map<String, dynamic>>>{};
      for (final r in reports) {
        final bId = _asInt(r['boxId']);
        if (bId != null) latestReportByBox[bId] ??= r;
        final oId = _asInt(r['orderId']);
        if (oId != null) (reportsByOrderId[oId] ??= []).add(r);
        final code = r['orderCode']?.toString().trim().toUpperCase();
        if (code != null && code.isNotEmpty) {
          (reportsByOrderCode[code] ??= []).add(r);
        }
      }

      setState(() {
        _activeReportsByBox = _activeReportsByBoxMap(reports);
        _latestReportByBox = latestReportByBox;
        _reportsByOrderId = reportsByOrderId;
        _reportsByOrderCode = reportsByOrderCode;
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
            ? context.l10n.ordIncomingNotSupported
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
    _snack(context.l10n.ordNotFoundInList);
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
          item.date == null ? context.l10n.commonUnknownDate : _dateGroupLabel(item.date!);
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
    'RECENT' => context.l10n.ordEmptyRecent,
    'ACTIVE' => context.l10n.ordEmptyActive,
    'COMPLETED' => context.l10n.ordEmptyCompleted,
    'RENTAL' => context.l10n.ordEmptyRental,
    'SEND' => context.l10n.ordEmptySend,
    'CANCELED' => context.l10n.ordEmptyCanceled,
    _ => context.l10n.ordEmptyHint,
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
    final isResolved = isReportClosed(reportStatus);

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
    final byId = orderId == null ? null : _reportsByOrderId[orderId];
    if (byId != null && byId.isNotEmpty) return _preferCurrentBoxReport(byId, order);
    final code = order['orderCode']?.toString().trim().toUpperCase();
    if (code != null && code.isNotEmpty) {
      final byCode = _reportsByOrderCode[code];
      if (byCode != null && byCode.isNotEmpty) {
        return _preferCurrentBoxReport(byCode, order);
      }
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
    return number == null ? L10n.current.boxThisLower : L10n.current.boxNumberLower(number);
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
    if (diff == 0) return L10n.current.commonToday;
    if (diff == 1) return L10n.current.commonYesterday;
    return L10n.current.dateDayMonthYear(d.day, d.month, d.year);
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
      final key = item.date == null ? context.l10n.commonUnknownDate : _dateGroupLabel(item.date!);
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
        title: Text(context.l10n.ordCancelQuestion),
        content: Text(
          '${context.l10n.ordCancelBody(code ?? '')}'
          '${isPaid ? context.l10n.ordCancelPaidNote : ''}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(context.l10n.ordKeepOrder),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(context.l10n.ordCancelOrderAlt),
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
          title: Text(context.l10n.ordExtendRental),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                context.l10n.ordAddHours(hours.round()),
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
                context.l10n.ordMaxHoursPerExtension(maxHours),
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12, color: opsMutedText),
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
              child: Text(context.l10n.ordExtend),
            ),
          ],
        ),
      ),
    );
    if (confirmed == true) {
      await _runAction(
        () => _service.extendRental(orderId, hours.round()),
        L10n.current.ordExtended(hours.round()),
      );
    }
  }

  Future<void> _reportDialog({
    required int orderId,

    /// Nhãn ô cho người đọc (`ô số 4`), đã tra sẵn từ sơ đồ tủ.
    String? boxLabel,
  }) async {
    boxLabel ??= context.l10n.boxThisLower;
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
            title: Text(context.l10n.ordReportFaultyBox),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: reasonCtrl,
                    maxLines: 3,
                    enabled: !uploading,
                    decoration: InputDecoration(
                      hintText: context.l10n.ordDescribeIssueHint,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    context.l10n.ordOnsitePhotosOptional(photos.maxPhotos),
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
                    helperText: context.l10n.ordPhotosHelp,
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
                child: Text(context.l10n.commonCancel),
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
                                context.l10n.ordDescribeOrAttach,
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
                child: Text(uploading ? context.l10n.ordUploadingPhotos : context.l10n.ordSendReport),
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
          reason.isNotEmpty ? reason : L10n.current.ordBoxFaultDefault,
          attachments: attachments,
        );
        await _load();
        if (!mounted) return;
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(
                context.l10n.ordReportSentFor(boxLabel),
              ),
              action: SnackBarAction(
                label: context.l10n.commonView,
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
            Text(
              context.l10n.ordPickupAtKiosk,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 18,
                color: opsDark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              context.l10n.ordPickupAtKioskBody,
              style: TextStyle(fontSize: 14, color: opsMutedText, height: 1.45),
            ),
            const SizedBox(height: 16),
            OpsSheetAction(
              label: context.l10n.ordOpenBoxOnPhone(boxLabel),
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
              label: context.l10n.ordPickedUpAndClosed,
              icon: LucideIcons.circleCheck,
              primary: false,
              onTap: () {
                Navigator.pop(ctx);
                _runAction(
                  () => _service.endRental(orderId),
                  context.l10n.ordRentalEnded,
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
      _snack(context.l10n.ordNoLockerInfo);
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
          _snack(L10n.current.ordLockerNoLocation);
        case DirectionsResult.launchFailed:
          _snack(L10n.current.ordCantOpenMapsApp);
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
        ? context.l10n.ordExtensionPaymentFor(orderId)
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
          title: context.l10n.paymentSuccessExclaim,
          amountText: '${total.toInt()} đ',
          message: context.l10n.ordPaidSuccessfully,
        );
      } else if (outcome == OrderPaymentOutcome.failed) {
        showPaymentResultDialog<void>(
          context,
          type: PaymentStatusType.failure,
          title: context.l10n.paymentFailed,
          amountText: '${total.toInt()} đ',
          message: context.l10n.ordPaymentNotCompleted,
        );
      } else {
        _snack(
          context.l10n.ordAwaitingPaymentPull,
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
          title: context.l10n.paymentFailed,
          amountText: fmtPrice(due),
          message: context.l10n.ordPaymentNotCompleted,
        );
        await _load();
        return;
      }
      if (outcome == OrderPaymentOutcome.pending) {
        // Chưa có xác nhận PAID thì chưa chốt đơn — server cũng sẽ từ chối.
        _snack(
          context.l10n.ordAwaitingPaymentConfirmPickup,
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
          title: Row(
            children: [
              Icon(LucideIcons.packageCheck, color: Color(0xFF16A34A)),
              SizedBox(width: 8),
              Text(
                context.l10n.ordConfirmPickup,
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17),
              ),
            ],
          ),
          content: Text(
            context.l10n.ordConfirmPickupBody,
            style: TextStyle(fontSize: 14, height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(context.l10n.commonCancel, style: TextStyle(color: opsMutedText)),
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
              child: Text(context.l10n.ordPickedUpComplete),
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
          title: context.l10n.ordCompletedTitle,
          amountText: fmtPrice(due),
          message: context.l10n.ordPaidAndPickedUp,
        );
      } else {
        _snack(context.l10n.ordReceivedComplete);
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
            title: Text(context.l10n.ordPaidNotCompletedTitle),
            content: Text(
              context.l10n.ordPaidNotCompletedBody(reason),
              style: const TextStyle(fontSize: 14, height: 1.4),
            ),
            actions: [
              FilledButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(context.l10n.commonGotIt),
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
      _snack(context.l10n.ordNoOvertimeFeeDue);
      return;
    }
    final lockerName = _lockerNameOf(order) ?? context.l10n.ordLockrLocker;
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
            : context.l10n.ordOverdue,
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
          description: context.l10n.ordOverdueFee,
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
          title: context.l10n.paymentFailed,
          amountText: fmtPrice(due),
          message: context.l10n.ordPaymentNotCompleted,
        );
        await _load();
        return;
      }
      if (outcome == OrderPaymentOutcome.pending) {
        _snack(
          context.l10n.ordAwaitingPaymentOpenBox,
        );
        await _load();
        return;
      }
      _snack(context.l10n.ordOvertimePaidOpening);
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
    _snack(context.l10n.ordSendingOpenCommand(boxLabel));
    try {
      final res = await _service.unlock(lockerId, boxId, pin);
      final accepted = res['accepted'] == true;
      final msg = res['message']?.toString();
      _snack(
        accepted
            ? L10n.current.ordBoxOpened(boxLabel)
            : L10n.current.ordBoxOpenFailed(
                boxLabel,
                msg != null && msg.isNotEmpty ? ': $msg' : '',
              ),
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
      _snack(context.l10n.ordNoBoxPinInfo);
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
    final lockerName = locker?['name']?.toString() ?? L10n.current.ordLockrLocker;
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
          ? context.l10n.ordOverdueRentalNotice
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
      context.l10n.ordDelegatedTo(
        phone == null || phone.isEmpty
            ? ''
            : context.l10n.ordDelegatedToPhone(phone),
      ),
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
        title: Text(context.l10n.ordChangePinQuestion),
        content: Text(
          isSend && status == 'STORING'
              ? context.l10n.ordChangePinReceiver
              : context.l10n.ordChangePinNow,
          style: const TextStyle(fontSize: 14, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(context.l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(context.l10n.ordChangeCode),
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
            ? L10n.current.ordPinChangedSeeDetail
            : L10n.current.ordPinChangedNew(pin),
      );
      await _load();
    } catch (e) {
      _snack(
        LockerOpsService.isEndpointUnavailable(e)
            ? L10n.current.ordPinChangeNotSupported
            : LockerOpsService.errorMessage(e),
      );
    }
  }

  /// "Gửi lại thông tin cho người nhận" của đơn gửi hàng: hiện email đang có (sửa được) rồi gửi lại thư —
  /// hàng đã vào tủ ⇒ kèm mã mở tủ; đã thanh toán, chưa bỏ hàng ⇒ thư báo có đơn; chưa thanh toán ⇒ chỉ lưu
  /// email (Lock.R báo người nhận khi đơn được thanh toán).
  Future<void> _receiverEmail(Map<String, dynamic> order) async {
    final orderId = _asInt(order['id']);
    if (orderId == null) return;
    final current = (order['receiverEmail'] as String? ?? '').trim();
    final email = await showDialog<String>(
      context: context,
      builder: (_) => _ReceiverEmailDialog(
        initial: current,
        mode: _receiverEmailMode(order),
      ),
    );
    if (email == null || !mounted) return;
    try {
      final res = await _service.sendReceiverEmail(
        orderId,
        email: email == current ? null : email,
      );
      final masked = res['maskedEmail']?.toString() ?? email;
      _snack(
        res['sentAt'] == null
            ? L10n.current.ordReceiverEmailSaved(masked)
            : res['includesPickupCode'] == true
            ? L10n.current.ordPickupCodeSentTo(masked)
            : L10n.current.ordOrderInfoResentTo(masked),
      );
      await _load();
    } catch (e) {
      _snack(
        LockerOpsService.isEndpointUnavailable(e)
            ? L10n.current.ordEmailCodeNotSupported
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
              context.l10n.ordNewOrderCreated,
            );
          },
          onConfirmDrop: (id) async {
            Navigator.pop(ctx);
            await _runAction(
              () => _service.confirmDrop(id),
              context.l10n.ordDropoffConfirmed,
            );
          },
          onComplete: (id) async {
            Navigator.pop(ctx);
            // Hoàn tất là không đảo ngược và nhả ô: hỏi lại để tránh bấm nhầm khi chưa lấy đồ
            // (test 2026-10-29 bấm một lần là đóng đơn).
            final ok = await showDialog<bool>(
              context: context,
              builder: (dialogCtx) => AlertDialog(
                title: Text(context.l10n.ordConfirmPickedUpQuestion),
                content: Text(
                  context.l10n.ordConfirmPickedUpBody,
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(dialogCtx).pop(false),
                    child: Text(context.l10n.commonNotYet),
                  ),
                  FilledButton(
                    onPressed: () => Navigator.of(dialogCtx).pop(true),
                    child: Text(context.l10n.ordPickedUp),
                  ),
                ],
              ),
            );
            if (ok != true || !mounted) return;
            await _runAction(
              () => _service.completePickup(id),
              context.l10n.ordReceivedComplete,
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
          // Báo lỗi / ủy quyền / đổi PIN làm ngay trên trang chi tiết (hộp thoại mở
          // chồng lên), trang chi tiết tự tải lại sau đó — không đóng về danh sách.
          onReport: (boxId) async {
            final orderId = _asInt(order['id']);
            if (orderId == null) return;
            final latest =
                _orders.where((o) => _asInt(o['id']) == orderId).firstOrNull ??
                    order;
            // Đồ đã trong ô và ô đang có phiếu mở ⇒ mở phiếu đó, không báo trùng.
            // Đơn chưa có đồ vẫn báo qua server: server tự huỷ đơn để khách đặt ô khác.
            final status = (latest['status'] as String? ?? '').toUpperCase();
            final itemsInside = status == 'STORING' || status == 'RETURNED';
            final open = itemsInside ? _incidentReportForOrder(latest) : null;
            if (open != null &&
                !_reportOnOtherBox(open, latest) &&
                !isReportClosed(open['status'] ?? 'OPEN')) {
              _snack(
                context.l10n.ordBoxHasTicket(open['id']),
              );
              UserReportDetailSheet.show(context, report: open);
              return;
            }
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
            await _runAction(() => _service.cancelOrder(id), L10n.current.ordCancelled);
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
            await _delegateOrder(id);
          },
          onResetPin: () async {
            await _resetPin(order);
          },
          onReceiverEmail: () async {
            await _receiverEmail(order);
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
            title: context.l10n.homeLockerOrders,
            subtitle: context.l10n.ordMyOrdersSubtitle,
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
                    label: context.l10n.commonAll,
                    count: _orders.length,
                    selected: _typeFilter == 'ALL',
                    onTap: () => _setFilter('ALL'),
                  ),
                  const SizedBox(width: 8),
                  _TypeChip(
                    label: context.l10n.ordTabRecent,
                    count: _countRecent,
                    selected: _typeFilter == 'RECENT',
                    onTap: () => _setFilter('RECENT'),
                  ),
                  const SizedBox(width: 8),
                  _TypeChip(
                    label: context.l10n.ordTabInUse,
                    count: _countActive,
                    selected: _typeFilter == 'ACTIVE',
                    onTap: () => _setFilter('ACTIVE'),
                  ),
                  const SizedBox(width: 8),
                  _TypeChip(
                    label: context.l10n.ordTabCompleted,
                    count: _countCompleted,
                    selected: _typeFilter == 'COMPLETED',
                    onTap: () => _setFilter('COMPLETED'),
                  ),
                  const SizedBox(width: 8),
                  _TypeChip(
                    label: context.l10n.homeRentLocker,
                    count: _countRental,
                    selected: _typeFilter == 'RENTAL',
                    onTap: () => _setFilter('RENTAL'),
                  ),
                  const SizedBox(width: 8),
                  _TypeChip(
                    label: context.l10n.lockerSendParcel,
                    count: _countSend,
                    selected: _typeFilter == 'SEND',
                    onTap: () => _setFilter('SEND'),
                  ),
                  if (_countCanceled > 0) ...[
                    const SizedBox(width: 8),
                    _TypeChip(
                      label: context.l10n.ordTabCancelled,
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
                    label: context.l10n.commonAll,
                    count: _incoming.length,
                    selected: _incomingFilter == 'ALL',
                    onTap: () => _setIncomingFilter('ALL'),
                  ),
                  const SizedBox(width: 8),
                  _TypeChip(
                    label: context.l10n.ordTabRecent,
                    count: _incomingCountRecent,
                    selected: _incomingFilter == 'RECENT',
                    onTap: () => _setIncomingFilter('RECENT'),
                  ),
                  const SizedBox(width: 8),
                  _TypeChip(
                    label: context.l10n.ordTabAwaitingPickup,
                    count: _incomingCountActive,
                    selected: _incomingFilter == 'ACTIVE',
                    onTap: () => _setIncomingFilter('ACTIVE'),
                  ),
                  const SizedBox(width: 8),
                  _TypeChip(
                    label: context.l10n.ordTabCompleted,
                    count: _incomingCountCompleted,
                    selected: _incomingFilter == 'COMPLETED',
                    onTap: () => _setIncomingFilter('COMPLETED'),
                  ),
                  if (_incomingCountDrone > 0) ...[
                    const SizedBox(width: 8),
                    _TypeChip(
                      label: context.l10n.ordFilterDrone,
                      count: _incomingCountDrone,
                      selected: _incomingFilter == 'DRONE',
                      onTap: () => _setIncomingFilter('DRONE'),
                    ),
                  ],
                  if (_incomingCountSend > 0) ...[
                    const SizedBox(width: 8),
                    _TypeChip(
                      label: context.l10n.lockerSendParcel,
                      count: _incomingCountSend,
                      selected: _incomingFilter == 'SEND',
                      onTap: () => _setIncomingFilter('SEND'),
                    ),
                  ],
                  if (_incomingCountCanceled > 0) ...[
                    const SizedBox(width: 8),
                    _TypeChip(
                      label: context.l10n.ordTabCancelled,
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
                ? Center(
                    child: AppLoadingIndicator(
                      message: context.l10n.ordListLoading,
                    ),
                  )
                : _visible.isEmpty
                ? OpsEmptyState(
                    icon: LucideIcons.packageOpen,
                    title: _typeFilter == 'ALL'
                        ? context.l10n.ordNoOrdersYet
                        : context.l10n.ordNoMatchingOrders,
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
      return Center(
        child: AppLoadingIndicator(message: context.l10n.ordIncomingLoading),
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
              TextButton(onPressed: onRefresh, child: Text(context.l10n.commonRetry)),
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
          children: [
            SizedBox(height: 40),
            OpsEmptyState(
              icon: LucideIcons.inbox,
              title: context.l10n.ordNoIncoming,
              subtitle:
                  context.l10n.ordNoIncomingHint,
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
            children: [
              SizedBox(height: 40),
              OpsEmptyState(
                icon: LucideIcons.packageOpen,
                title: context.l10n.ordNoMatchingOrders,
                subtitle:
                    context.l10n.ordNoIncomingMatch,
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
            tab(context.l10n.ordMyOrders, !showIncoming, () => onChanged(false)),
            tab(
              context.l10n.ordIncoming,
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
    // Đơn drone giao không thành công cũng đóng (CANCELED) nhưng không tô xanh "xong".
    final doneTone =
        isDone && status != 'FAILED' && status != 'DROP_REPORTED';
    // Ô hỏng đã xác nhận: không mời khách trả tiền / lấy đồ (server cũng chặn).
    // Ô mới chờ KTV kiểm tra: khách vẫn lấy đồ được, chỉ báo phí đang dừng.
    final boxIncident = orderBoxIncidentBlocksAccess(order);
    final feePaused = orderHasOpenBoxIncident(order);

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
                                  (doneTone
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
                                color: doneTone
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
                              context.l10n.ordPickupDeadlineValue(fmtDateTime(deadline)),
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
                              text: lockerName ?? context.l10n.ordLockerNameUnknown,
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
                                    ? context.l10n.ordPayAndPickup
                                    : context.l10n.ordConfirmPickup;
                                actionBgColor = const Color(
                                  0xFFDC2626,
                                ).withValues(alpha: 0.12);
                                actionTextColor = const Color(0xFFDC2626);
                                actionBorderSide = const BorderSide(
                                  color: Color(0xFFDC2626),
                                  width: 1.4,
                                );
                              } else if (boxIncident) {
                                actionLabel = context.l10n.ordAwaitingTechnician;
                                actionBgColor = const Color(
                                  0xFFF59E0B,
                                ).withValues(alpha: 0.12);
                                actionTextColor = const Color(0xFFB45309);
                                actionBorderSide = const BorderSide(
                                  color: Color(0xFFF59E0B),
                                  width: 1.2,
                                );
                              } else if (isDone) {
                                actionLabel = context.l10n.ordReview;
                                actionBgColor = null;
                                actionTextColor = context.textPrimary;
                                actionBorderSide = BorderSide(
                                  color: context.borderColor,
                                  width: 1.5,
                                );
                              } else if (rawStatus == 'INITIALIZED') {
                                actionLabel = context.l10n.ordDropIntoLocker;
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
                                    ? context.l10n.ordPayAndPickup
                                    : context.l10n.ordPickupNow;
                                actionBgColor = const Color(
                                  0xFFDC2626,
                                ).withValues(alpha: 0.12);
                                actionTextColor = const Color(0xFFDC2626);
                                actionBorderSide = const BorderSide(
                                  color: Color(0xFFDC2626),
                                  width: 1.4,
                                );
                              } else {
                                actionLabel = context.l10n.commonDetails;
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
            if (feePaused)
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
                            ? context.l10n.ordOvertimePausedNoTime
                            : context.l10n.ordOvertimePausedSince(fmtDateTime(order['boxIncidentOpenedAt'])),
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
                        context.l10n.ordStorageExpiredTapPay(BusinessConfigService.instance.current.overdueReleaseHoursLabel),
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
                  children: [
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
                        context.l10n.ordOverdueMayCharge,
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
                  accessBlocked: boxIncident,
                  movedToCurrentBox: _reportOnOtherBox(faultReport!, order),
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
    this.accessBlocked = true,
    this.movedToCurrentBox = false,
    this.logs = const [],
    this.onViewReport,
  });

  final Map<String, dynamic> report;

  /// Đồ đã nằm trong ô (đơn STORING/RETURNED): không huỷ được đơn, chỉ chờ KTV.
  final bool itemsInside;

  /// Phiếu báo cho ô cũ, đồ đã được chuyển sang ô hiện tại ([boxLabel]).
  final bool movedToCurrentBox;

  /// Sự cố đã được xác nhận (ô khoá chờ KTV). False: ô chờ KTV kiểm tra, khách
  /// vẫn mở ô bằng mã PIN được.
  final bool accessBlocked;
  final String boxLabel;
  final List<Map<String, dynamic>> logs;
  final VoidCallback? onViewReport;

  @override
  Widget build(BuildContext context) {
    final reason = (report['description'] as String?)?.trim();
    final status = (report['status'] as String? ?? 'OPEN').toUpperCase();
    final isResolved = isReportClosed(status);
    final isRejected = status == 'REJECTED';
    final reportId = report['id'];

    // Kiểm tra xem đơn hàng đã được KTV điều chuyển sang ô mới an toàn chưa
    bool isRelocated = movedToCurrentBox;
    String? newBoxNum = movedToCurrentBox
        ? RegExp(r'\d+').firstMatch(boxLabel)?.group(0)
        : null;
    String? oldBoxNum = report['boxNumber']?.toString();

    for (final log in movedToCurrentBox ? const <Map<String, dynamic>>[] : logs) {
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
      title = context.l10n.ordRelocatedTitle(newBoxNum ?? '');
      subtitle = context.l10n.ordRelocatedSubtitle(oldBoxNum ?? '');
    } else if (isRejected) {
      bg = const Color(0xFFF8FAFC);
      border = const Color(0xFFCBD5E1);
      fg = const Color(0xFF334155);
      icon = LucideIcons.shieldCheck;
      title = context.l10n.ordCheckedNoIssueTitle(boxLabel);
      subtitle = context.l10n.ordCheckedNoIssueSubtitle;
    } else if (isResolved) {
      bg = const Color(0xFFF0FDF4);
      border = const Color(0xFFBBF7D0);
      fg = const Color(0xFF15803D);
      icon = LucideIcons.shieldCheck;
      title = context.l10n.ordResolvedTitle(boxLabel);
      subtitle = context.l10n.ordResolvedSubtitle;
    } else {
      bg = const Color(0xFFFEF2F2);
      border = const Color(0xFFFCA5A5);
      fg = const Color(0xFFDC2626);
      icon = LucideIcons.triangleAlert;
      title = context.l10n.ordReportedTitle(boxLabel);
      // Đơn đã có đồ trong ô thì không huỷ được (và huỷ cũng không lấy lại được đồ).
      subtitle = !itemsInside
          ? context.l10n.ordReportedCancelHint
          : accessBlocked
              ? context.l10n.ordReportedBlocked
              : context.l10n.ordReportedCanOpen;
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
                            context.l10n.ordReasonValue(reason),
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
                              ? context.l10n.ordViewRelocation
                              : context.l10n.ordViewRecord,
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
                    Text(
                      context.l10n.ordPayOvertimeFee,
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
                _breakdownRow(context.l10n.ordOriginalDeadline, fmtDateTime(deadline)),
                _breakdownRow(
                  context.l10n.ordOverdueDuration,
                  overdueDurationText,
                  valueColor: const Color(0xFFDC2626),
                ),
                _breakdownRow(context.l10n.ordOvertimeRate, context.l10n.pricePerHour(fmtPrice(overtimeRate))),
                if (overtimeCapped &&
                    (config.pickupMaxOvertimePercent > 0 ||
                        config.pickupMaxOvertimeFee > 0))
                  _breakdownRow(
                    context.l10n.ordCapRule,
                    [
                      if (config.pickupMaxOvertimeFee > 0)
                        context.l10n.ordCapMax(fmtPrice(config.pickupMaxOvertimeFee)),
                      if (config.pickupMaxOvertimePercent > 0)
                        context.l10n.ordCapPercent(config.pickupMaxOvertimePercent),
                    ].join(' & '),
                  ),
                if (overtimeFee != null && overtimeFee > 0)
                  _breakdownRow(context.l10n.ordOvertimeFee, fmtPrice(overtimeFee)),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Divider(height: 1, color: opsBorder),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      context.l10n.ordAmountDue,
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
                  ? context.l10n.ordPayAmount(fmtPrice(amountDue))
                  : context.l10n.ordOpenBoxPickup,
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
            child: Text(context.l10n.commonLater),
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
    if (boxId == null || isReportClosed(status) || active.containsKey(boxId)) {
      continue;
    }
    active[boxId] = report;
  }
  return active;
}

/// Ô đang giữ đồ của đơn (lúc chờ lấy: ô nhận, trước đó: ô gửi) — cùng cách
/// `_activeReportForOrder` chọn ô.
int? _currentBoxIdOf(Map<String, dynamic> order) {
  final status = (order['status'] as String? ?? '').toUpperCase();
  final isPickup = status == 'STORING' || status == 'RETURNED';
  return isPickup
      ? _asInt(order['receiveBoxId'] ?? order['sendBoxId'] ?? order['reservedBoxId'])
      : _asInt(order['sendBoxId'] ?? order['receiveBoxId'] ?? order['reservedBoxId']);
}

/// Phiếu báo cho một ô mà đơn không còn nằm trong đó: KTV đã chuyển đồ sang ô khác,
/// phiếu vẫn mở để sửa ô cũ. Không phải sự cố của ô đang giữ đồ.
bool _reportOnOtherBox(Map<String, dynamic> report, Map<String, dynamic> order) {
  final reportBox = _asInt(report['boxId']);
  final current = _currentBoxIdOf(order);
  return reportBox != null && current != null && reportBox != current;
}

/// Trong các phiếu gắn với đơn (mới nhất trước), ưu tiên phiếu của ô đang giữ đồ —
/// phiếu ô cũ sau khi KTV chuyển ô chỉ còn là lịch sử.
Map<String, dynamic> _preferCurrentBoxReport(
  List<Map<String, dynamic>> linked,
  Map<String, dynamic> order,
) {
  for (final report in linked) {
    if (!_reportOnOtherBox(report, order)) return report;
  }
  return linked.first;
}

/// `4`, `4 → 7`, hoặc `Chưa gán ô` — cho dòng "Ô" ở bảng chi tiết.
String _boxRouteLabel(
  int? sendBoxNumber,
  int? receiveBoxNumber, [
  String? status,
]) {
  if (sendBoxNumber == null && receiveBoxNumber == null) {
    return (status ?? '').toUpperCase() == 'EXPIRED'
        ? L10n.current.ordBoxReleased
        : L10n.current.ordBoxNotAssigned;
  }
  // Đơn thuê không có ô nhận riêng — ô nhận rơi về cùng số ô, không hiện "3 → 3".
  if (sendBoxNumber != null &&
      receiveBoxNumber != null &&
      sendBoxNumber != receiveBoxNumber) {
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
  return label == null ? L10n.current.boxThis : L10n.current.boxNumberLabel(label);
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
      initialPin: L10n.current.ordPinCancelledSecurity,
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
    final tech = relocation.technician ?? context.l10n.ordTechInCharge;
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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.l10n.ordRelocationRecordUpper,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF15803D),
                        letterSpacing: 0.3,
                      ),
                    ),
                    Text(
                      context.l10n.ordRelocationRecordSubtitle,
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
                      Row(
                        children: [
                          Icon(LucideIcons.circleAlert, size: 12, color: Color(0xFFDC2626)),
                          SizedBox(width: 4),
                          Text(
                            context.l10n.ordOriginalBoxUpper,
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
                        context.l10n.ordBoxNumberHash(oldBox),
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
                            : context.l10n.ordTechnicalIssue,
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
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            context.l10n.ordNewBoxUpper,
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
                        context.l10n.ordBoxNumberHash(newBox),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF15803D),
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        context.l10n.ordHoldingSafely,
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
                    label: context.l10n.ordOldBoxCheckedAt,
                    value: oldTime,
                    valueColor: const Color(0xFFB45309),
                  ),
                  const Divider(height: 10, color: Color(0xFFF1F5F9)),
                ],
                if (newTime != null && newTime.isNotEmpty) ...[
                  _detailRow(
                    icon: LucideIcons.packageCheck,
                    label: context.l10n.ordMovedAt,
                    value: newTime,
                    valueColor: const Color(0xFF15803D),
                  ),
                  const Divider(height: 10, color: Color(0xFFF1F5F9)),
                ],
                _detailRow(
                  icon: LucideIcons.shieldAlert,
                  label: context.l10n.ordOriginalBoxPin,
                  value: context.l10n.ordPinDisabled,
                  valueColor: const Color(0xFF64748B),
                ),
                const Divider(height: 10, color: Color(0xFFF1F5F9)),
                _detailRow(
                  icon: LucideIcons.key,
                  label: context.l10n.ordNewBoxPin(newBox),
                  value: context.l10n.ordPinActive(relocation.currentPin ?? '••••••'),
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
                Expanded(
                  child: Text(
                    context.l10n.ordTechPhotos(photos.length),
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF15803D),
                    ),
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
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(LucideIcons.fileText, size: 14, color: Colors.white),
                    SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        context.l10n.ordViewFullRecord,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
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
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
              color: valueColor ?? const Color(0xFF1E293B),
            ),
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
    this.onReceiverEmail,
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
  final Future<void> Function(int boxId) onReport;
  final void Function(int orderId) onCancel;
  final VoidCallback onDirections;
  final void Function(int orderId) onPay;
  final void Function(int orderId, num fee) onPayOvertime;
  final VoidCallback onOpenLocker;
  final void Function(int orderId) onTrackDrone;
  final void Function(int orderId)? onPayAndComplete;
  final Future<void> Function(int orderId)? onDelegate;
  final Future<void> Function()? onResetPin;
  final Future<void> Function()? onReceiverEmail;
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
        : context.l10n.ordOrderDetailHash(_currentOrder['id'] ?? '');

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
            tooltip: context.l10n.commonReload,
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
              onReport: (boxId) async {
                await widget.onReport(boxId);
                if (mounted) await _refresh();
              },
              onCancel: widget.onCancel,
              onDirections: widget.onDirections,
              onPay: widget.onPay,
              onPayOvertime: widget.onPayOvertime,
              onPayAndComplete: widget.onPayAndComplete,
              onOpenLocker: widget.onOpenLocker,
              onTrackDrone: widget.onTrackDrone,
              onDelegate: widget.onDelegate == null
                  ? null
                  : (id) async {
                      await widget.onDelegate!(id);
                      if (mounted) await _refresh();
                    },
              onResetPin: widget.onResetPin == null
                  ? null
                  : () async {
                      await widget.onResetPin!();
                      if (mounted) await _refresh();
                    },
              onReceiverEmail: widget.onReceiverEmail == null
                  ? null
                  : () async {
                      await widget.onReceiverEmail!();
                      if (mounted) await _refresh();
                    },
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
    this.onReceiverEmail,
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

  /// "Gửi mã cho người nhận qua email" / thêm, đổi email người nhận (đơn gửi hàng).
  final VoidCallback? onReceiverEmail;

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
    // Ô hỏng đã xác nhận: server không thu tiền, không mở ô bằng mã. Ô mới chờ
    // KTV kiểm tra: vẫn lấy đồ được, chỉ chưa gia hạn (phí đang dừng).
    final boxIncident = orderBoxIncidentBlocksAccess(order);
    final feePaused = orderHasOpenBoxIncident(order);
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
                : context.l10n.ordServiceHash(line['serviceId'] ?? ''),
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
      // Đơn drone luôn mở được màn hành trình: đang giao thì theo dõi, đã xong/huỷ thì xem lại chuyến bay.
      if (isDroneDelivery)
        OpsSheetAction(
          label: droneFlightFinished(rawStatus)
              ? context.l10n.ordReviewDroneJourney
              : context.l10n.ordTrackDrone,
          icon: LucideIcons.navigation,
          primary: !droneFlightFinished(rawStatus),
          onTap: () => onTrackDrone(id),
        ),
      if (canPay &&
          rawStatus != 'EXPIRED' &&
          !(rawStatus == 'STORING' && needsPayOvertime) &&
          !(rawStatus == 'RETURNED' && needsPayOvertime))
        OpsSheetAction(
          label: context.l10n.ordPayAmount(fmtPrice(orderAmountDue(order))),
          icon: LucideIcons.creditCard,
          primary: true,
          onTap: () => onPay(id),
        ),
      if (rawStatus == 'EXPIRED') ...[
        if (canPay || orderAmountDue(order) > 0)
          OpsSheetAction(
            label:
                context.l10n.ordPayAndCompletePickup(fmtPrice(orderAmountDue(order) > 0 ? orderAmountDue(order) : totalNum)),
            icon: LucideIcons.circleCheck,
            primary: true,
            onTap: () => onPayAndComplete?.call(id),
          )
        else
          OpsSheetAction(
            label: context.l10n.ordIPickedUpCompleteOrder,
            icon: LucideIcons.circleCheck,
            primary: true,
            onTap: () => onPayAndComplete?.call(id),
          ),
        if (boxId != null)
          OpsSheetAction(
            label: context.l10n.ordOpenBoxToPickup(boxLabel),
            icon: LucideIcons.doorOpen,
            primary: false,
            onTap: onOpenLocker,
          ),
        if (!isDroneDelivery)
          OpsSheetAction(
            label: context.l10n.ordReorder,
            icon: LucideIcons.repeat,
            primary: false,
            onTap: () => onReorder(id),
          ),
      ],
      // Đặt lại chỉ áp cho đơn gửi hàng / thuê ô (server từ chối đơn drone) ⇒ không hiện nút cho đơn drone.
      if ((rawStatus == 'COMPLETED' || rawStatus == 'CANCELED') &&
          rawStatus != 'EXPIRED' &&
          !isDroneDelivery)
        OpsSheetAction(
          label: context.l10n.ordReorder,
          icon: LucideIcons.repeat,
          primary: true,
          onTap: () => onReorder(id),
        ),
      if (canDrop)
        OpsSheetAction(
          label: context.l10n.ordOpenBoxToDrop(boxLabel),
          icon: LucideIcons.doorOpen,
          primary: true,
          onTap: onOpenLocker,
        ),
      if (rawStatus == 'INITIALIZED')
        OpsSheetAction(
          label: context.l10n.ordIDroppedOff,
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
                context.l10n.ordPayAndCompletePickup(fmtPrice(orderAmountDue(order) > 0 ? orderAmountDue(order) : overtimeFee)),
            icon: LucideIcons.circleCheck,
            primary: true,
            onTap: () => onPayAndComplete?.call(id),
          ),
          OpsSheetAction(
            label: context.l10n.ordPayOvertimeAndOpen(fmtPrice(overtimeFee)),
            icon: LucideIcons.creditCard,
            primary: false,
            onTap: () => onPayOvertime(id, overtimeFee),
          ),
        ] else ...[
          OpsSheetAction(
            label: context.l10n.ordOpenBoxToPickup(boxLabel),
            icon: LucideIcons.doorOpen,
            primary: true,
            onTap: onOpenLocker,
          ),
          OpsSheetAction(
            label: context.l10n.ordIPickedUpComplete,
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
                context.l10n.ordPayAndCompletePickup(fmtPrice(orderAmountDue(order) > 0 ? orderAmountDue(order) : overtimeFee)),
            icon: LucideIcons.circleCheck,
            primary: true,
            onTap: () => onPayAndComplete?.call(id),
          ),
          OpsSheetAction(
            label: context.l10n.ordPayOvertimeAndOpen(fmtPrice(overtimeFee)),
            icon: LucideIcons.creditCard,
            primary: false,
            onTap: () => onPayOvertime(id, overtimeFee),
          ),
        ] else ...[
          OpsSheetAction(
            label: context.l10n.ordOpenBoxToReturn(boxLabel),
            icon: LucideIcons.doorOpen,
            primary: true,
            onTap: onOpenLocker,
          ),
        ],
        if (!feePaused)
          OpsSheetAction(
            label: context.l10n.ordExtendRental,
            icon: LucideIcons.timer,
            onTap: () => onExtend(id),
          ),
        OpsSheetAction(
          label: context.l10n.ordEndRentalPickup,
          icon: LucideIcons.logOut,
          onTap: () => onEndRental(id),
        ),
      ],
      // Ủy quyền lấy hộ: server chỉ nhận khi đồ đang nằm trong ô (STORING/RETURNED).
      if (onDelegate != null &&
          !isDroneDelivery &&
          (rawStatus == 'STORING' || rawStatus == 'RETURNED'))
        OpsSheetAction(
          label: context.l10n.ordDelegatePickup,
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
          label: context.l10n.ordChangePin,
          icon: LucideIcons.keyRound,
          onTap: onResetPin!,
        ),
      // Đơn gửi hàng: gửi lại mã cho người nhận qua email (hoặc thêm / đổi email khi chưa bỏ hàng).
      if (onReceiverEmail != null &&
          type == 'SEND' &&
          (order['delegatedAt'] == null && (order['delegatePhone'] ?? '').toString().isEmpty) &&
          (rawStatus == 'INITIALIZED' ||
              rawStatus == 'STORING' ||
              rawStatus == 'RETURNED'))
        OpsSheetAction(
          key: const ValueKey('send-receiver-email-action'),
          label: (order['receiverEmail'] ?? '').toString().trim().isEmpty
              ? context.l10n.ordAddReceiverEmail
              : (_receiverEmailMode(order) == _ReceiverEmailMode.saveOnly
                    ? context.l10n.ordChangeReceiverEmail
                    : context.l10n.ordResendToReceiver),
          icon: LucideIcons.mailCheck,
          onTap: onReceiverEmail!,
        ),
      // Đơn drone giữ sẵn ô nhận từ lúc đặt; chỉ báo ô lỗi được khi kiện đã nằm trong ô
      // (STORING) — trước đó khách chưa dùng ô nào.
      if (boxId != null &&
          (!isDroneDelivery || rawStatus == 'STORING') &&
          rawStatus != 'COMPLETED' &&
          rawStatus != 'CANCELED' &&
          rawStatus != 'EXPIRED')
        OpsSheetAction(
          label: context.l10n.ordReportFaultyBox,
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
          label: context.l10n.ordCancelOrder,
          icon: LucideIcons.circleX,
          danger: true,
          onTap: () => onCancel(id),
        ),
      OpsSheetAction(
        label: context.l10n.ordDirectionsToLocker,
        icon: LucideIcons.map,
        onTap: onDirections,
      ),
      // Backend chỉ nhận yêu cầu hoàn cho đơn có khoản đã thu (ORDER_NOT_PAID nếu
      // chưa trả); đơn đang chờ hoàn / đã hoàn xem ở Hồ sơ › Yêu cầu hoàn tiền.
      if (paymentStatus == 'PAID')
        OpsSheetAction(
          label: context.l10n.ordRequestRefund,
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
            accessBlocked: boxIncident,
            movedToCurrentBox: _reportOnOtherBox(faultReport!, order),
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
        if (feePaused)
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
                  ? context.l10n.ordStorageExpiredPay(config.overdueReleaseHoursLabel)
                  : context.l10n.ordStorageExpiredCheck(config.overdueReleaseHoursLabel),
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
                  ? context.l10n.ordOverduePaidOpen
                  : context.l10n.ordOverdueNeedPay(overtimePolicyText(config)),
            ),
          )
        else if (rawStatus == 'INITIALIZED' && canPay)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: OpsBanner(
              tone: OpsBannerTone.warning,
              icon: LucideIcons.circleAlert,
              text:
                  context.l10n.ordUnpaidHold(config.autoCancelUnpaidMinutes),
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
                label: context.l10n.commonLocker,
                value: lockerName ?? context.l10n.ordLockerNameUnknown,
              ),
              // Địa chỉ nơi đặt tủ — người nhận cần biết đi đâu, không chỉ tủ tên gì.
              if (lockerAddress != null)
                OpsInfoRow(
                  icon: LucideIcons.mapPin,
                  label: context.l10n.ordPlace,
                  value: lockerAddress,
                ),

              // Hiển thị chi tiết ô tủ theo nghiệp vụ chuyển ô hoặc bình thường
              if (relocation.isRelocated) ...[
                OpsInfoRow(
                  icon: LucideIcons.grid3x3,
                  label: context.l10n.ordNewBox,
                  value: context.l10n.ordNewBoxValue(relocation.newBoxNumber ?? sendBoxNumber ?? '—'),
                  valueColor: const Color(0xFF15803D),
                ),
                OpsInfoRow(
                  icon: LucideIcons.circleAlert,
                  label: context.l10n.ordOriginalBox,
                  value: context.l10n.ordOriginalBoxValue(relocation.oldBoxNumber ?? '—'),
                  valueColor: const Color(0xFFDC2626),
                ),
                if (relocation.oldBoxOpenedTime != null && relocation.oldBoxOpenedTime!.isNotEmpty)
                  OpsInfoRow(
                    icon: LucideIcons.doorOpen,
                    label: context.l10n.ordOldBoxOpenedAt,
                    value: relocation.oldBoxOpenedTime!,
                    valueColor: const Color(0xFFB45309),
                  ),
                if (relocation.relocatedTime != null && relocation.relocatedTime!.isNotEmpty)
                  OpsInfoRow(
                    icon: LucideIcons.checkCheck,
                    label: context.l10n.ordBoxMovedAt,
                    value: relocation.relocatedTime!,
                    valueColor: const Color(0xFF15803D),
                  ),
                OpsInfoRow(
                  icon: LucideIcons.keyRound,
                  label: context.l10n.ordOriginalPin,
                  value: context.l10n.ordPinDisabled,
                  valueColor: const Color(0xFF64748B),
                ),
              ] else ...[
                OpsInfoRow(
                  icon: LucideIcons.grid3x3,
                  label: context.l10n.commonBox,
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
                  label: context.l10n.ordOrderDate,
                  value: fmtDateTime(createdAt),
                ),
              if (isRental && rentalHours != null)
                OpsInfoRow(
                  icon: LucideIcons.timer,
                  label: context.l10n.ordRentalDuration,
                  value: context.l10n.hoursValue(rentalHours),
                ),
              if (deadline != null)
                OpsInfoRow(
                  icon: LucideIcons.clock,
                  label: context.l10n.ordOriginalDeadlineShort,
                  value: fmtDateTime(deadline),
                ),
              if (overdue) ...[
                OpsInfoRow(
                  icon: LucideIcons.clockAlert,
                  label: context.l10n.ordOverdueDuration,
                  value: overtimeDurationText.isNotEmpty
                      ? overtimeDurationText
                      : context.l10n.ordOverdue,
                  valueColor: const Color(0xFFDC2626),
                ),
                OpsInfoRow(
                  icon: LucideIcons.receiptText,
                  label: context.l10n.ordOvertimeRate,
                  value: context.l10n.pricePerHour(fmtPrice(overtimeRateOf(order, config))),
                ),
                if (overtimeCappedOf(order) &&
                    (config.pickupMaxOvertimePercent > 0 ||
                        config.pickupMaxOvertimeFee > 0))
                  OpsInfoRow(
                    icon: LucideIcons.shieldAlert,
                    label: context.l10n.ordCapRuleShort,
                    value: [
                      if (config.pickupMaxOvertimeFee > 0)
                        context.l10n.ordCapMax(fmtPrice(config.pickupMaxOvertimeFee)),
                      if (config.pickupMaxOvertimePercent > 0)
                        context.l10n.ordCapPercent(config.pickupMaxOvertimePercent),
                    ].join(' & '),
                  ),
                OpsInfoRow(
                  icon: LucideIcons.circleAlert,
                  label: context.l10n.ordOvertimeFeeEstimate,
                  value: fmtPrice(overtimeFee),
                  valueColor: const Color(0xFFEA580C),
                ),
                OpsInfoRow(
                  icon: LucideIcons.badgeAlert,
                  label: context.l10n.ordPenaltyStatus,
                  value: isOvertimePaid ? context.l10n.enumPaid : context.l10n.enumUnpaid,
                  valueColor: isOvertimePaid
                      ? const Color(0xFF15803D)
                      : const Color(0xFFDC2626),
                ),
                if (needsPayOvertime)
                  OpsInfoRow(
                    icon: LucideIcons.circleDollarSign,
                    label: context.l10n.ordDueToOpen,
                    value: fmtPrice(overtimeFee),
                    valueColor: const Color(0xFFDC2626),
                  ),
              ],
              if (receiverLabel.isNotEmpty)
                OpsInfoRow(
                  icon: LucideIcons.userCheck,
                  label: context.l10n.ordRecipient,
                  value: receiverLabel,
                ),
              if (receiverEmail != null)
                OrderContactRow(
                  icon: LucideIcons.mail,
                  label: context.l10n.ordRecipientEmail,
                  value: receiverEmail,
                ),
              if (delegatedAt != null) ...[
                OpsInfoRow(
                  icon: LucideIcons.userPlus,
                  label: context.l10n.ordDelegatedToLabel,
                  value: delegateLabel.isEmpty
                      ? context.l10n.ordDelegatee
                      : delegateLabel,
                  valueColor: const Color(0xFF7C3AED),
                ),
                if (delegateNote != null)
                  OpsInfoRow(
                    icon: LucideIcons.messageSquareText,
                    label: context.l10n.ordDelegationMessage,
                    value: delegateNote,
                  ),
                OpsInfoRow(
                  icon: LucideIcons.clock,
                  label: context.l10n.ordDelegatedAt,
                  value: fmtDateTime(delegatedAt),
                ),
              ],
              if (intendedReceiveAt != null)
                OpsInfoRow(
                  icon: LucideIcons.calendarClock,
                  label: context.l10n.ordExpectedPickup,
                  value: fmtDateTime(intendedReceiveAt),
                ),
              if (deliveryAddress != null && deliveryAddress.isNotEmpty)
                OpsInfoRow(
                  icon: LucideIcons.truck,
                  label: context.l10n.ordDeliveryAddress,
                  value: deliveryAddress,
                ),
              if (isDroneDelivery && sourceLockerName != null)
                OpsInfoRow(
                  icon: LucideIcons.planeTakeoff,
                  label: context.l10n.ordFromLocker,
                  value: sourceLockerName!,
                ),
              if (isDroneDelivery && routeDistance != null)
                OpsInfoRow(
                  icon: LucideIcons.route,
                  label: context.l10n.ordFlightDistance,
                  value: fmtDistanceMeters(routeDistance),
                ),
              for (final line in serviceLines)
                OpsInfoRow(
                  icon: LucideIcons.listChecks,
                  label: context.l10n.commonService,
                  value: line,
                ),
              if ((discountAmount > 0 || pointsUsed > 0) && originalPrice > 0)
                OpsInfoRow(
                  icon: LucideIcons.tag,
                  label: context.l10n.ordBasePrice,
                  value: fmtPrice(originalPrice),
                ),
              if (hasExtra)
                OpsInfoRow(
                  icon: LucideIcons.circlePlus,
                  label: context.l10n.ordExtraFees,
                  value: fmtPrice(extraFee),
                  valueColor: const Color(0xFFB45309),
                ),
              if (discountAmount > 0)
                OpsInfoRow(
                  icon: LucideIcons.badgePercent,
                  label: promotionCode != null && promotionCode.isNotEmpty
                      ? 'Voucher'
                      : context.l10n.commonDiscount,
                  value: promotionCode != null && promotionCode.isNotEmpty
                      ? '-${fmtPrice(discountAmount)} ($promotionCode)'
                      : '-${fmtPrice(discountAmount)}',
                  valueColor: const Color(0xFF15803D),
                ),
              if (pointsUsed > 0)
                OpsInfoRow(
                  icon: LucideIcons.sparkles,
                  label: context.l10n.ordPointsUsed,
                  value: loyaltyPointsDiscountText(pointsUsed, pointsDiscount),
                  valueColor: const Color(0xFF15803D),
                ),
              OpsInfoRow(
                icon: LucideIcons.wallet,
                label: context.l10n.ordTotal,
                value: fmtPrice(order['totalPrice']),
                valueColor: opsDark,
              ),
              if (service != null)
                OrderEarnedPointsRow(order: order, service: service!),
              // Gia hạn / phí quá hạn cộng vào tổng nhưng phần cũ đã trả rồi,
              // nên tách rõ đã trả bao nhiêu và còn thiếu bao nhiêu.
              if (rawStatus != 'COMPLETED' &&
                  orderAmountDue(order) > 0 &&
                  (_asDouble(order['paidAmount']) ?? 0) > 0) ...[
                OpsInfoRow(
                  icon: LucideIcons.receiptText,
                  label: context.l10n.enumPaid,
                  value: fmtPrice(order['paidAmount']),
                  valueColor: const Color(0xFF15803D),
                ),
                OpsInfoRow(
                  icon: LucideIcons.circleDollarSign,
                  label: context.l10n.ordRemaining,
                  value: fmtPrice(orderAmountDue(order)),
                  valueColor: const Color(0xFFB45309),
                ),
              ],
              OpsInfoRow(
                icon: LucideIcons.checkCheck,
                label: context.l10n.commonPayment,
                value: switch (paymentStatus) {
                  'PAID' => context.l10n.enumPaid,
                  'REFUND_PENDING' => context.l10n.enumAwaitingRefund,
                  'REFUNDED' => context.l10n.enumRefunded,
                  _ => context.l10n.enumUnpaid,
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
                  label: context.l10n.ordPaidAt,
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
                  label: context.l10n.commonNote,
                  value: customerNote,
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        OrderDetailSection(
          title: context.l10n.ordParcel,
          icon: LucideIcons.package,
          rows: orderParcelRows(parcel),
        ),
        OrderDetailSection(
          title: context.l10n.ordDeliveryIncident,
          icon: LucideIcons.triangleAlert,
          rows: [
            if (blockLabel != null)
              OpsInfoRow(
                icon: LucideIcons.circlePause,
                label: context.l10n.ordPaused,
                value: blockLabel,
                valueColor: const Color(0xFFEA580C),
              ),
            if (blockLabel != null && order['deliveryBlockedAt'] != null)
              OpsInfoRow(
                icon: LucideIcons.clock,
                label: context.l10n.ordPausedAt,
                value: fmtDateTime(order['deliveryBlockedAt']),
              ),
            if (failureLabel != null)
              OpsInfoRow(
                icon: LucideIcons.circleX,
                label: context.l10n.ordDeliveryIncomplete,
                value: failureLabel,
                valueColor: const Color(0xFFDC2626),
              ),
            if (failureLabel != null && order['failedAt'] != null)
              OpsInfoRow(
                icon: LucideIcons.clock,
                label: context.l10n.ordRecordedAt,
                value: fmtDateTime(order['failedAt']),
              ),
            if (order['parcelReturnedAt'] != null)
              OpsInfoRow(
                icon: LucideIcons.undo2,
                label: context.l10n.ordParcelReturned,
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
                      context.l10n.ordNewBoxPinUpper(relocation.newBoxNumber ?? '4'),
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
            Padding(
              padding: EdgeInsets.only(top: 6),
              child: Center(
                child: Text(
                  context.l10n.ordOldPinDisabledNote,
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
        // Đơn drone lấy hàng tận nhà: mã người gửi đọc cho KTV khi KTV tới (server chỉ trả khi KTV
        // chưa cầm kiện). Trước đây chỉ có ở màn theo dõi (test 2026-10-29).
        if (isDroneDelivery && text('dronePickupCode') != null) ...[
          const SizedBox(height: 14),
          Container(
            key: const ValueKey('order-drone-pickup-code'),
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
            decoration: BoxDecoration(
              color: const Color(0xFFEEF2FF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Text(
                  context.l10n.ordPickupCodeForTech,
                  style: TextStyle(fontSize: 12.5, color: Color(0xFF3730A3)),
                ),
                const SizedBox(height: 4),
                SelectableText(
                  text('dronePickupCode')!,
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 6,
                    color: Color(0xFF312E81),
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 16),
        ...actions,
        const SizedBox(height: 20),
        const Divider(height: 1, color: opsBorder),
        const SizedBox(height: 12),
        OrderDetailSection(
          title: context.l10n.ordTimeline,
          icon: LucideIcons.milestone,
          footer: milestones.isEmpty
              ? null
              : OrderMilestoneTimeline(milestones: milestones),
        ),
        OrderStatusTimeline(orderId: id, service: service, refreshToken: order),
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
    'WALLET' => L10n.current.payMethodWallet,
    'SEPAY' => L10n.current.payMethodSepay,
    'VNPAY' => 'VNPay',
    'MOMO' => 'MoMo',
    'CASH' => L10n.current.payMethodCash,
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
                label: context.l10n.ordPaymentMethod,
                value: _methodLabel(done[i]['method'] as String?),
              ),
              OpsInfoRow(
                icon: LucideIcons.hash,
                label: context.l10n.ordTransactionId,
                value: _transactionCode(done[i]),
              ),
              if (done[i]['amount'] != null)
                OpsInfoRow(
                  icon: LucideIcons.banknote,
                  label: context.l10n.commonAmount,
                  value: fmtPrice(done[i]['amount']),
                  valueColor: const Color(0xFF15803D),
                ),
              if (done[i]['createdAt'] != null)
                OpsInfoRow(
                  icon: LucideIcons.calendarCheck,
                  label: context.l10n.ordPaymentTime,
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
        ? context.l10n.ordTransferred
        : (isRejected ? context.l10n.ordRejected : context.l10n.ordAwaitingTransfer);
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
                        context.l10n.ordRefundHash(rf['id'] ?? ''),
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
                  label: context.l10n.ordRefundAmount,
                  value: fmtPrice(rf['amount']),
                  valueColor: isCompleted ? const Color(0xFF15803D) : const Color(0xFFD97706),
                ),

              // Tài khoản nhận
              if (bankDisplay.isNotEmpty)
                OpsInfoRow(
                  icon: LucideIcons.building2,
                  label: context.l10n.ordReceivingAccount,
                  value: bankDisplay,
                ),

              // Thời gian hoàn tất / yêu cầu
              if (timeDisplay != null)
                OpsInfoRow(
                  icon: LucideIcons.clock,
                  label: isCompleted ? context.l10n.ordCompletedAt : context.l10n.ordRequestedAt,
                  value: timeDisplay,
                ),

              const SizedBox(height: 8),
              const Divider(height: 1, color: Color(0xFFE2E8F0)),
              const SizedBox(height: 8),

              // Dòng chữ xem chi tiết ở mục hoàn tiền
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(LucideIcons.arrowUpRight, size: 13, color: Color(0xFF0284C7)),
                      SizedBox(width: 5),
                      Text(
                        context.l10n.ordSeeRefunds,
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
        description = L10n.current.ordExtensionPayment;
      } else {
        description = description.replaceAll(
          RegExp(r'thanh toán bổ sung', caseSensitive: false),
          L10n.current.ordExtensionPayment,
        );
      }
    }
    final order = L10n.current.ordAttemptN(index + 1);
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

  /// Tag cho ghi chú order-service viết khi KTV chuyển ô / xử lý xong sự cố (không có
  /// tag `[...]`); null nếu không phải ghi chú xử lý sự cố.
  static String? _untaggedIncidentTag(String note) {
    final lower = note.toLowerCase();
    if (lower.contains('đã xử lý sự cố ô')) return '[ĐÃ XỬ LÝ SỰ CỐ]';
    if (lower.startsWith('ktv điều chuyển hàng sang ô')) return '[ĐIỀU CHUYỂN Ô]';
    if (lower.contains('bàn giao hàng trực tiếp')) return '[BÀN GIAO TRỰC TIẾP]';
    if (lower.contains('niêm phong')) return '[NIÊM PHONG VỀ HUB]';
    return null;
  }

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
      // Lọc chỉ giữ incident notes: ghi chú có tag của KTV, hoặc ghi chú order-service
      // tự viết khi chuyển ô / xử lý xong sự cố (không có tag).
      final incidents = events.where((e) {
        final note = (e['note'] ?? e['description'] ?? '').toString().trim();
        final upperNote = note.toUpperCase();
        return _incidentTags.any((t) => upperNote.contains(t.toUpperCase())) ||
            _untaggedIncidentTag(note) != null;
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
        upperTag.contains('ĐÃ XỬ LÝ') ||
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
    // Chưa có bước xử lý nào thì không vẽ tiêu đề rỗng (phiếu mới báo, KTV chưa làm gì).
    if (_loading || _incidentEvents.isEmpty) {
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
            Expanded(
              child: Text(
                context.l10n.ordInterventionRecord,
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
              final untagged = match == null ? _untaggedIncidentTag(rawNote) : null;
              final tag = match?.group(1) ?? untagged ?? rawNote;
              final rest = match?.group(2) ?? (untagged != null ? rawNote : '');
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
                                  context.l10n.ordBoxIncidentTitle(widget.order?['orderCode'] ?? widget.orderId),
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
                                  context.l10n.photosMore(validPhotos.length - 3),
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
                                    context.l10n.ordBoxIncidentTitle(widget.order?['orderCode'] ?? widget.orderId),
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
                                  context.l10n.ordViewTechEvidence,
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
                          context.l10n.ordInfoRelocated,
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
                          context.l10n.ordInfoSealedHub,
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
                          context.l10n.ordInfoHandedOver,
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

/// Đơn drone đã kết thúc (hàng đã lấy, huỷ hoặc hết hạn): nút hành trình chuyển sang "xem lại".
@visibleForTesting
bool droneFlightFinished(String rawStatus) =>
    const {'COMPLETED', 'CANCELED', 'EXPIRED', 'DELIVERY_INCOMPLETE'}.contains(
      rawStatus.toUpperCase(),
    );

/// Thư server gửi khi người gửi bấm nút email người nhận (khớp `OrderService.sendReceiverEmail`).
enum _ReceiverEmailMode {
  /// Hàng đã vào tủ ⇒ thư kèm mã mở tủ.
  withCode,

  /// Đã thanh toán, chưa bỏ hàng ⇒ thư báo có đơn sắp tới (không mã).
  orderInfo,

  /// Chưa thanh toán ⇒ người nhận chưa được báo, chỉ lưu email.
  saveOnly,
}

_ReceiverEmailMode _receiverEmailMode(Map<String, dynamic> order) {
  final status = (order['status'] as String? ?? '').toUpperCase();
  if (status == 'STORING' || status == 'RETURNED') return _ReceiverEmailMode.withCode;
  final total = order['totalPrice'];
  final totalNum = total is num ? total : num.tryParse('$total') ?? 0;
  final paid = (order['paymentStatus'] as String? ?? '').toUpperCase() == 'PAID';
  return paid || totalNum <= 0 ? _ReceiverEmailMode.orderInfo : _ReceiverEmailMode.saveOnly;
}

/// Hộp nhập email người nhận của đơn gửi hàng. Trả email đã cắt khoảng trắng, hoặc null khi huỷ.
class _ReceiverEmailDialog extends StatefulWidget {
  const _ReceiverEmailDialog({required this.initial, required this.mode});

  final String initial;
  final _ReceiverEmailMode mode;

  @override
  State<_ReceiverEmailDialog> createState() => _ReceiverEmailDialogState();
}

class _ReceiverEmailDialogState extends State<_ReceiverEmailDialog> {
  static final RegExp _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]{2,}$');

  late final TextEditingController _controller = TextEditingController(text: widget.initial);
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    Navigator.of(context).pop(_controller.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      title: Text(
        widget.mode == _ReceiverEmailMode.saveOnly
            ? context.l10n.ordRecipientEmail
            : context.l10n.ordResendToReceiver,
      ),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              switch (widget.mode) {
                _ReceiverEmailMode.withCode =>
                  context.l10n.ordEmailWithCode,
                _ReceiverEmailMode.orderInfo =>
                  context.l10n.ordEmailOrderInfo,
                _ReceiverEmailMode.saveOnly =>
                  context.l10n.ordEmailSaveOnly,
              },
              style: const TextStyle(fontSize: 14, height: 1.4),
            ),
            const SizedBox(height: 14),
            TextFormField(
              key: const ValueKey('receiver-email-input'),
              controller: _controller,
              autofocus: widget.initial.isEmpty,
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.email],
              textInputAction: TextInputAction.done,
              decoration: InputDecoration(
                labelText: context.l10n.ordRecipientEmail,
                hintText: 'name@example.com',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                final email = value?.trim() ?? '';
                if (email.isEmpty) return context.l10n.ordEnterRecipientEmail;
                return _emailPattern.hasMatch(email) ? null : context.l10n.authInvalidEmail;
              },
              onFieldSubmitted: (_) => _submit(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(context.l10n.commonCancel)),
        FilledButton(
          key: const ValueKey('receiver-email-submit'),
          onPressed: _submit,
          child: Text(widget.mode == _ReceiverEmailMode.saveOnly ? context.l10n.ordSaveEmail : context.l10n.ordSendEmail),
        ),
      ],
    );
  }
}
