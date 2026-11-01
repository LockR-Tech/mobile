import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:smart_laundry_locker/core/config/business_config_provider.dart';
import 'package:smart_laundry_locker/core/routing/app_router.dart';
import 'package:smart_laundry_locker/core/theme/shadcn_theme.dart';
import 'package:smart_laundry_locker/features/locker_ops/data/locker_ops_service.dart';
import 'package:smart_laundry_locker/features/locker_ops/domain/pickup_code_share.dart';
import 'package:smart_laundry_locker/features/locker_ops/presentation/utils/business_rules_text.dart';
import 'package:smart_laundry_locker/features/locker_ops/presentation/widgets/locker_picker.dart';
import 'package:smart_laundry_locker/features/locker_ops/presentation/widgets/loyalty_redeem_toggle.dart';
import 'package:smart_laundry_locker/features/locker_ops/presentation/widgets/ops_widgets.dart';
import 'package:smart_laundry_locker/features/locker_ops/presentation/widgets/order_extras.dart';
import 'package:smart_laundry_locker/features/locker_ops/presentation/widgets/pickup_code_share_actions.dart';
import 'package:smart_laundry_locker/features/locker_ops/presentation/widgets/sepay_payment.dart';
import 'package:smart_laundry_locker/features/locker/domain/utils/locker_layout_helper.dart';
import 'package:smart_laundry_locker/features/notifications/infrastructure/services/realtime_notification_service.dart';
import 'package:smart_laundry_locker/shared/shared.dart';
import 'package:smart_laundry_locker/shared/widgets/user_ui_kit.dart';
import 'package:smart_laundry_locker/core/services/app_event_bus.dart';
import 'package:smart_laundry_locker/features/profile/domain/constants/profile_constants.dart';
import 'package:smart_laundry_locker/core/l10n/l10n.dart';

/// SEND flow (gửi hàng C2C qua tủ).
/// Stage 1: tạo đơn + nhận PIN bỏ hàng. Stage 2: thanh toán → mở ô → bỏ hàng →
/// xác nhận; khi đó PIN nhận hàng được sinh mới và gửi cho người nhận (đúng luồng
/// PIN 2 giai đoạn của backend `order-service`). Server chỉ nhận xác nhận khi đơn
/// đã thanh toán và ô đã từng được mở bằng PIN gửi.
class SendParcelPage extends StatefulWidget {
  const SendParcelPage({
    super.key,
    this.initialLockerId,
    this.initialLockerName,
    this.locationName,
    this.service,
    this.initialBoxId,
    this.initialBoxNumber,
    this.initialBoxSize,
  });

  /// Ô khách đã chọn trên sơ đồ tủ (gửi kèm `boxId` khi tạo đơn).
  final int? initialBoxId;
  final int? initialBoxNumber;

  /// Cỡ ô đã chọn (`SMALL` / `MEDIUM` / `LARGE`). Đã chọn ô thì server bỏ qua
  /// `size`, nên màn này chỉ hiện cỡ ô thay vì cho chọn kích thước hàng.
  final String? initialBoxSize;

  final LockerOpsService? service;

  /// Pre-selected locker (cabinet) id — set when opened from the cell grid.
  /// When non-null the locker picker is hidden and the API load is skipped.
  final int? initialLockerId;

  /// Display name of the cabinet (e.g. "Tu demo capstone 3x3 + vali").
  /// Shown in the read-only locker card when [initialLockerId] is set.
  final String? initialLockerName;

  /// Display name of the store/location (shown as a location hint row).
  final String? locationName;

  @override
  State<SendParcelPage> createState() => _SendParcelPageState();
}

class _SendParcelPageState extends State<SendParcelPage>
    with BusinessConfigStateMixin, WidgetsBindingObserver {
  late final LockerOpsService _service = widget.service ?? LockerOpsService();
  final _formKey = GlobalKey<FormState>();
  final _phoneCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();

  /// Phí gửi hiển thị (admin cấu hình) — server tự tính tiền thật.
  int get _fee => businessConfig.sendBaseFee;

  static const _sizes = ['SMALL', 'MEDIUM', 'LARGE'];

  List<Map<String, dynamic>> _lockers = [];
  int? _lockerId;
  bool _loadingLockers = true;
  bool _loading = false;
  Map<String, dynamic>? _order;
  int _discount = 0;
  String? _promoCode;

  /// Điểm thưởng khách bật dùng (gửi `pointsToUse`) và số tiền giảm ước tính.
  int _pointsToUse = 0;
  int _pointsDiscount = 0;
  String _size = 'MEDIUM';

  /// Thanh toán SePay của đơn vừa tạo (mã VietQR hiện ngay trên màn).
  SepayPaymentController? _payment;

  /// Tên tủ hiển thị khi mở từ lưới ô mà nơi gọi chỉ truyền id.
  String? _lockerName;

  /// Địa chỉ tủ cho tin nhắn chia sẻ mã — tải một lần khi hàng đã vào ô mà
  /// danh sách tủ không có sẵn (mở từ lưới ô).
  String? _lockerAddress;
  bool _lockerInfoRequested = false;
  StreamSubscription<AppEvent>? _eventSub;
  StreamSubscription<int>? _availabilitySub;

  /// Số ô thường còn trống theo cỡ (`SMALL`/`MEDIUM`/`LARGE`) của tủ đang chọn —
  /// giống "Còn N ô trống" ở Thuê tủ. `null` khi chưa tải được sơ đồ.
  Map<String, int>? _availableBySize;

  /// Ô khách chọn trên sơ đồ vừa bị người khác đặt mất.
  bool _selectedBoxTaken = false;

  /// Phí sau mã giảm giá — số tiền dùng để hỏi được dùng bao nhiêu điểm.
  int get _feeAfterVoucher => (_fee - _discount).clamp(0, _fee);

  /// Tạm tính sau mã giảm giá và điểm thưởng.
  int get _netFee =>
      (_feeAfterVoucher - _pointsDiscount).clamp(0, _feeAfterVoucher);

  /// Giới hạn lời nhắn — đủ cho một câu dặn, vừa một dòng email.
  static const _noteMaxLength = 200;

  static bool _isBookableLocker(Map<String, dynamic> l) =>
      l['online'] != false &&
      '${l['status'] ?? 'ACTIVE'}'.trim().toUpperCase() == 'ACTIVE';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final presetSize = _normalizeSize(widget.initialBoxSize);
    if (presetSize != null) _size = presetSize;
    // Người khác đặt/trả ô, KTV khoá/mở ô ⇒ số ô trống đổi. Chỉ cập nhật khi chưa tạo đơn.
    _availabilitySub = RealtimeNotificationService.instance.lockerAvailability
        .listen((lockerId) {
      if (mounted && _order == null && lockerId == _lockerId) {
        _loadLayout(lockerId);
      }
    });
    if (widget.initialLockerId != null) {
      // Đến từ lưới ô — tủ đã xác định, bỏ qua gọi API load danh sách tủ.
      _lockerId = widget.initialLockerId;
      _loadingLockers = false;
      _lockerName = widget.initialLockerName;
      if (_lockerName == null || _lockerName!.trim().isEmpty) {
        _loadLockerName(widget.initialLockerId!);
      }
      _loadLayout(_lockerId!);
    } else {
      _loadLockers();
      // Admin sửa/tắt tủ khi khách đang chọn ⇒ cập nhật danh sách tủ (chưa tạo
      // đơn mới cập nhật, giữ tủ đang chọn nếu vẫn dùng được).
      _eventSub = AppEventBus.instance.events.listen((event) {
        if (mounted &&
            _order == null &&
            event is CatalogChangedEvent &&
            event.isLocker) {
          _loadLockers();
        }
      });
    }
  }

  Future<void> _loadLockerName(int lockerId) async {
    try {
      final locker = await _service.locker(lockerId);
      final name = locker['name']?.toString().trim();
      if (!mounted || name == null || name.isEmpty) return;
      setState(() => _lockerName = name);
    } catch (_) {
      // Không tra được thì giữ nhãn chung "Tủ đã chọn".
    }
  }

  /// Bản ghi tủ của đơn trong danh sách tủ đã tải (luồng chọn tủ).
  Map<String, dynamic>? _listedLocker(Map<String, dynamic> order) {
    final id = order['lockerId'] ?? _lockerId;
    for (final locker in _lockers) {
      if (locker['id'] == id) return locker;
    }
    return null;
  }

  /// Hàng đã vào ô ⇒ người gửi sắp chia sẻ mã: tra tên + địa chỉ tủ nếu danh
  /// sách tủ không có sẵn. Lỗi thì tin nhắn bỏ phần địa chỉ.
  Future<void> _loadLockerInfoForShare(Map<String, dynamic> order) async {
    if (_lockerInfoRequested ||
        (order['status'] as String?) != 'STORING' ||
        _listedLocker(order) != null) {
      return;
    }
    final lockerId = (order['lockerId'] as int?) ?? _lockerId;
    if (lockerId == null) return;
    _lockerInfoRequested = true;
    try {
      final locker = await _service.locker(lockerId);
      if (!mounted) return;
      final name = locker['name']?.toString().trim();
      final address = locker['address']?.toString().trim();
      setState(() {
        if ((_lockerName ?? '').trim().isEmpty &&
            name != null &&
            name.isNotEmpty) {
          _lockerName = name;
        }
        if (address != null && address.isNotEmpty) _lockerAddress = address;
      });
    } catch (_) {
      // Không tra được địa chỉ thì tin nhắn chỉ ghi tên tủ.
    }
  }

  /// Mã người nhận cần, khi người gửi nên tự chuyển (hàng đã vào ô).
  PickupCodeShare? _receiverShare(Map<String, dynamic> order) {
    final listed = _listedLocker(order);
    final listedName = listed?['name']?.toString().trim();
    final listedAddress = listed?['address']?.toString().trim();
    final rawBox = order['sendBoxNumber'];
    final boxNumber = rawBox is int
        ? rawBox
        : int.tryParse('${rawBox ?? ''}') ??
              (widget.initialBoxId != null &&
                      order['sendBoxId'] == widget.initialBoxId
                  ? widget.initialBoxNumber
                  : null);
    return pickupCodeShareForOrder(
      order,
      lockerName: (listedName == null || listedName.isEmpty)
          ? _lockerName
          : listedName,
      lockerAddress: (listedAddress == null || listedAddress.isEmpty)
          ? _lockerAddress ?? widget.locationName
          : listedAddress,
      boxNumber: boxNumber,
    );
  }

  // Người gửi có thể thanh toán qua cổng ngoài hoặc xác nhận bỏ hàng ngay tại
  // kiosk — quay lại app thì tải lại đơn để thấy trạng thái mới.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _order != null) {
      _refreshOrder();
    }
  }

  @override
  void dispose() {
    _eventSub?.cancel();
    _availabilitySub?.cancel();
    _disposePayment();
    WidgetsBinding.instance.removeObserver(this);
    _phoneCtrl.dispose();
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  /// Đơn có phí mà chưa thanh toán.
  bool _isUnpaid(Map<String, dynamic> order) {
    final total = order['totalPrice'];
    final hasFee = total is num ? total > 0 : _netFee > 0;
    return hasFee && (order['paymentStatus'] as String?) != 'PAID';
  }

  /// Chưa bỏ hàng mà chưa trả ⇒ hiện mã VietQR SePay ngay trên màn: tạo
  /// checkout MỘT lần cho đơn này, tự hỏi trạng thái ~3 s/lần và khi app quay
  /// lại. Đơn đã trả / đã bỏ hàng ⇒ dừng.
  void _syncPayment() {
    final order = _order;
    final id = order?['id'] as int?;
    final needsPayment = order != null &&
        id != null &&
        (order['status'] as String?) != 'STORING' &&
        _isUnpaid(order);
    if (!needsPayment) {
      _disposePayment();
      return;
    }
    if (_payment?.orderId == id) return;
    _disposePayment();
    final payment = SepayPaymentController(
      service: _service,
      orderId: id,
      orderCode: order['orderCode'] as String?,
      amount: orderAmountDue(order),
    )..addListener(_onPaymentChanged);
    _payment = payment;
    unawaited(payment.start());
  }

  void _disposePayment() {
    final payment = _payment;
    _payment = null;
    payment
      ?..removeListener(_onPaymentChanged)
      ..dispose();
  }

  void _onPaymentChanged() {
    final payment = _payment;
    if (payment == null || !payment.paid || !mounted) return;
    // Đang trong notifyListeners của controller ⇒ huỷ nó ở microtask sau.
    _payment = null;
    payment.removeListener(_onPaymentChanged);
    scheduleMicrotask(payment.dispose);
    setState(() => _order = {...?_order, 'paymentStatus': 'PAID'});
    _refreshOrder();
    _snack(context.l10n.commonPaySuccessPinReady);
  }

  Future<void> _loadLockers() async {
    try {
      final lockers = await _service.lockers();
      if (!mounted) return;
      setState(() {
        _lockers = lockers.where((l) => l['id'] is num).toList();
        final preset = widget.initialLockerId;
        // Tải lại (admin sửa tủ): giữ tủ khách đang chọn nếu vẫn dùng được.
        final current = _lockerId;
        final keepCurrent =
            current != null &&
            _lockers.any((l) => l['id'] == current && _isBookableLocker(l));
        if (keepCurrent) {
          _lockerId = current;
        } else if (preset != null &&
            _lockers.any((l) => l['id'] == preset && _isBookableLocker(l))) {
          _lockerId = preset;
        } else {
          final firstBookable = _lockers
              .where(_isBookableLocker)
              .firstOrNull;
          _lockerId = firstBookable?['id'] as int?;
        }
        _loadingLockers = false;
      });
      if (_lockerId != null) _loadLayout(_lockerId!);
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadingLockers = false);
      _snack(LockerOpsService.errorMessage(e));
    }
  }

  static String? _normalizeSize(Object? raw) =>
      switch ('${raw ?? ''}'.trim().toUpperCase()) {
        'SMALL' || 'S' => 'SMALL',
        'MEDIUM' || 'M' => 'MEDIUM',
        'LARGE' || 'L' => 'LARGE',
        _ => null,
      };

  /// Đếm ô thường còn trống theo cỡ. Gửi hàng chỉ dùng ô thường (server chọn ô
  /// `STANDARD`) nên bỏ ô vali XL và ô drone.
  Future<void> _loadLayout(int id) async {
    try {
      final res = await _service.layout(id);
      if (!mounted || id != _lockerId) return;
      final cells = res['cells'];
      if (cells is! List) return;
      final counts = {for (final s in _sizes) s: 0};
      var boxTaken = widget.initialBoxId != null;
      for (final raw in cells.whereType<Map>()) {
        final cell = Map<String, dynamic>.from(raw);
        final available =
            cell['status'] == 'AVAILABLE' && cell['active'] != false;
        if ((cell['id'] as num?)?.toInt() == widget.initialBoxId &&
            available) {
          boxTaken = false;
        }
        if (!available || LockerLayoutHelper.cellType(cell) != 'STANDARD') {
          continue;
        }
        final size = _normalizeSize(cell['size']);
        if (size != null) counts[size] = counts[size]! + 1;
      }
      setState(() {
        _availableBySize = counts;
        _selectedBoxTaken = boxTaken;
        // Cỡ đang chọn đã hết ⇒ tự chuyển sang cỡ còn ô (như Thuê tủ).
        if (widget.initialBoxId == null && counts[_size] == 0) {
          _size = _sizes.firstWhere((s) => counts[s]! > 0, orElse: () => _size);
        }
      });
    } catch (_) {
      // Không tải được sơ đồ thì không hiện số ô trống; server vẫn kiểm khi tạo đơn.
    }
  }

  /// Hết ô để tạo đơn: ô đã chọn bị đặt mất, hoặc cỡ đang chọn không còn ô.
  bool get _noCellAvailable => widget.initialBoxId != null
      ? _selectedBoxTaken
      : _availableBySize?[_size] == 0;

  Future<void> _create() async {
    if (!(_formKey.currentState?.validate() ?? false) || _lockerId == null) {
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() => _loading = true);
    try {
      final order = await _service.createSend(
        lockerId: _lockerId!,
        receiverPhone: _phoneCtrl.text.trim(),
        boxId: widget.initialBoxId,
        receiverName:
            _nameCtrl.text.trim().isEmpty ? null : _nameCtrl.text.trim(),
        receiverEmail: _emailCtrl.text.trim(),
        note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
        promotionCode: _promoCode,
        size: _size,
        pointsToUse: _pointsToUse > 0 ? _pointsToUse : null,
      );
      if (!mounted) return;
      setState(() => _order = order);
      // Chưa trả ⇒ hiện mã VietQR SePay ngay (một checkout cho đơn này).
      // Voucher + điểm trừ hết ⇒ server đã ghi PAID, đi thẳng bước bỏ hàng.
      _syncPayment();
      final notice = loyaltyRedeemSkippedNotice(_pointsToUse, order);
      if (notice != null) _snack(notice);
    } catch (e) {
      _snack(LockerOpsService.errorMessage(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _refreshOrder() async {
    final id = _order?['id'] as int?;
    if (id == null) return;
    try {
      final fresh = await _service.order(id);
      if (!mounted || fresh.isEmpty) return;
      setState(() {
        // Vừa thấy PAID qua /status mà bản đơn chưa kịp cập nhật ⇒ giữ PAID.
        final wasPaid = (_order?['paymentStatus'] as String?) == 'PAID';
        final freshPaid = (fresh['paymentStatus'] as String?) == 'PAID';
        _order = {
          ...fresh,
          if (wasPaid && !freshPaid) 'paymentStatus': 'PAID',
        };
      });
      _syncPayment();
      unawaited(_loadLockerInfoForShare(fresh));
    } catch (_) {
      // Giữ bản đang hiển thị; lần sau quay lại app sẽ thử tải lại.
    }
  }

  Future<void> _openBox() async {
    final order = _order;
    final lockerId = order?['lockerId'] as int?;
    final boxId = order?['sendBoxId'] as int?;
    final pin = order?['pinCode'] as String?;
    if (lockerId == null || boxId == null || pin == null || pin.isEmpty) {
      _snack(context.l10n.ordNoBoxPinInfo);
      return;
    }
    setState(() => _loading = true);
    try {
      final res = await _service.unlock(lockerId, boxId, pin);
      final message = res['message']?.toString();
      _snack(
        res['accepted'] == true
            ? L10n.current.sendBoxOpened
            : (message == null || message.isEmpty ? L10n.current.sendBoxOpenFailed : message),
      );
    } catch (e) {
      _snack(LockerOpsService.errorMessage(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _confirmDrop() async {
    final id = _order?['id'] as int?;
    if (id == null) return;
    setState(() => _loading = true);
    try {
      final updated = await _service.confirmDrop(id);
      if (!mounted) return;
      setState(() => _order = updated);
      _syncPayment();
      unawaited(_loadLockerInfoForShare(updated));
      _snack(context.l10n.sendDroppedShare);
    } catch (e) {
      _snack(LockerOpsService.errorMessage(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  /// Kiểm tra sơ bộ ở phía app để bắt lỗi gõ nhầm ngay; server vẫn kiểm lại
  /// (`@Email` trên `SendOrderRequest`) nên đây chỉ là lớp lọc cho dễ chịu.
  static bool _looksLikeEmail(String value) =>
      RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value);

  /// Email người nhận bắt buộc và đúng dạng (server kiểm lại, lỗi `RECEIVER_EMAIL_REQUIRED`):
  /// Lock.R báo người nhận lúc đơn được thanh toán và gửi mã khi bỏ hàng vào ô.
  static String? _validateReceiverEmail(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) return L10n.current.sendEnterRecipientEmail;
    return _looksLikeEmail(email) ? null : L10n.current.authInvalidEmail;
  }

  /// Số di động Việt Nam 10 số bắt đầu bằng 0 — SMS và tra tài khoản người
  /// nhận đều dựa vào số này, gõ thiếu là người nhận không nhận được mã.
  static String? _validateReceiverPhone(String? value) {
    final phone = value?.trim() ?? '';
    if (phone.isEmpty) return L10n.current.sendEnterRecipientPhone;
    if (!ProfileConstants.vnPhoneRegex.hasMatch(phone)) {
      return L10n.current.sendPhone10Digits;
    }
    return null;
  }

  String _sizeLabel(String size) => switch (size) {
        'SMALL' => L10n.current.sizeSmallShort,
        'LARGE' => L10n.current.sizeLargeShort,
        _ => L10n.current.sizeMediumShort,
      };

  /// `Ô vừa (M)` — cùng cách gọi với sơ đồ tủ và bảng chọn ô.
  String _sizeTitle(String size) => switch (size) {
        'SMALL' => L10n.current.groupSmall,
        'LARGE' => L10n.current.groupLarge,
        _ => L10n.current.groupMedium,
      };

  Future<void> _handleBack() async {
    final order = _order;
    if (order == null) {
      Navigator.of(context).pop();
      return;
    }

    final paymentStatus =
        (order['paymentStatus'] as String? ?? 'UNPAID').toUpperCase();
    final status = (order['status'] as String? ?? '').toUpperCase();
    final total = order['totalPrice'];
    final hasFee = total is num ? total > 0 : _netFee > 0;
    final isPaid = paymentStatus == 'PAID' || status == 'STORING' || !hasFee;

    if (isPaid) {
      Navigator.of(context).pop();
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Row(
          children: [
            Icon(LucideIcons.triangleAlert, color: Color(0xFFEA580C)),
            SizedBox(width: 8),
            Text(
              context.l10n.sendCancelCreateQuestion,
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17),
            ),
          ],
        ),
        content: Text(
          context.l10n.sendCancelCreateBody(businessConfig.autoCancelUnpaidMinutes),
          style: const TextStyle(fontSize: 14, color: opsDark, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(context.l10n.commonStayToPay),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(context.l10n.commonCancelAndExit),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    final orderId = order['id'] as int?;
    if (orderId != null) {
      try {
        await _service.cancelOrder(orderId);
        _snack(L10n.current.sendCancelledReleased);
        AppEventBus.instance.emit(LockerLayoutUpdatedEvent(
          lockerId: _lockerId?.toString(),
        ));
        AppEventBus.instance.emit(OrderChangedEvent(orderId: orderId.toString()));
      } catch (_) {}
    }
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _handleBack();
      },
      child: Scaffold(
        backgroundColor: AISLShadcnTheme.navySurface,
        body: Column(
          children: [
            BrandHeroHeader(
              eyebrow: _order == null ? null : context.l10n.commonPaymentEyebrow,
              title: _order == null
                  ? context.l10n.sendTitle
                  : context.l10n.commonOrderCode(_order!['orderCode'] ?? '#${_order!['id']}'),
              subtitle: _order == null ? context.l10n.sendSubtitle : null,
              trailing: _order == null
                  ? null
                  : StatusChip(_order!['status'] as String?),
              onBack: _handleBack,
            ),
            Expanded(
              child: _order == null ? _buildForm() : _buildResult(),
            ),
          ],
        ),
        bottomNavigationBar: _buildBottomBar(),
      ),
    );
  }

  Widget? _buildBottomBar() {
    if (_order == null) {
      return Container(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.of(context).padding.bottom + 16,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _priceCard(),
            const SizedBox(height: 16),
            OpsPrimaryButton(
              label: context.l10n.sendCreateAndGetPin,
              icon: LucideIcons.arrowRight,
              loading: _loading,
              onPressed: _noCellAvailable ? null : _create,
            ),
          ],
        ),
      );
    }

    final payment = _payment;
    final order = _order!;
    final isDropped = order['status'] == 'STORING';
    final total = order['totalPrice'];
    final hasFee = total is num ? total > 0 : _netFee > 0;
    final unpaid = (order['paymentStatus'] as String?) != 'PAID';
    final mustPayFirst = hasFee && unpaid && businessConfig.requirePaymentBeforeDrop;

    if (!isDropped && mustPayFirst && payment != null) {
      return SepayPaymentActions(
        controller: payment,
        isPinned: true,
      );
    }

    return null;
  }

  /// Hoá đơn tạm — cùng kiểu thẻ "Tạm tính" của Thuê tủ.
  Widget _priceCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [opsDark, AISLShadcnTheme.navySecondary],
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(LucideIcons.wallet, color: Colors.white70, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.l10n.commonSubtotal,
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                    Text(
                      widget.initialBoxId != null &&
                              _normalizeSize(widget.initialBoxSize) == null
                          ? typeLabel('SEND')
                          : '${typeLabel('SEND')} · ${_sizeTitle(_size)}',
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (_netFee != _fee)
                    Text(
                      fmtPrice(_fee),
                      style: const TextStyle(
                        color: Colors.white60,
                        fontSize: 13,
                        decoration: TextDecoration.lineThrough,
                      ),
                    ),
                  Text(
                    fmtPrice(_netFee),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 22,
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (_discount > 0)
            _adjustmentLine(
              label: context.l10n.commonDiscountCode,
              value: '-${fmtPrice(_discount)}',
              color: const Color(0xFF86EFAC),
            ),
          if (_pointsDiscount > 0)
            _adjustmentLine(
              label: context.l10n.commonRewardPoints,
              value: loyaltyPointsDiscountText(_pointsToUse, _pointsDiscount),
              color: const Color(0xFFFDE68A),
            ),
        ],
      ),
    );
  }

  /// Một dòng giảm trừ trong hoá đơn tạm (mã giảm giá / điểm thưởng).
  Widget _adjustmentLine({
    required String label,
    required String value,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.only(top: 6, left: 34),
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: Colors.white70),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---- Stage 1: form ----
  Widget _buildForm() {
    if (_loadingLockers) {
      return Center(
        child: AppLoadingIndicator(message: context.l10n.sendLoadingLockers),
      );
    }
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const _SendStepper(active: 0),
          const SizedBox(height: 16),
          OpsBanner(
            text: context.l10n.sendIntro,
            icon: LucideIcons.packagePlus,
          ),
          if (widget.locationName != null) ...[
            const SizedBox(height: 12),
            LocationHint(name: widget.locationName!),
          ],
          const SizedBox(height: 20),
          OpsSectionLabel(context.l10n.commonChooseLocker, icon: LucideIcons.warehouse),
          if (widget.initialLockerId != null)
            _lockedLockerCard()
          else
            LockerPickerField(
              lockers: _lockers,
              selectedId: _lockerId,
              onlyActive: true,
              onSelected: (l) {
                final newId = l['id'] as int?;
                setState(() {
                  _lockerId = newId;
                  _availableBySize = null;
                });
                if (newId != null) _loadLayout(newId);
              },
            ),
          const SizedBox(height: 20),
          OpsSectionLabel(context.l10n.commonBoxType, icon: LucideIcons.boxes),
          if (widget.initialBoxId != null)
            _lockedCellCard()
          else
            Row(
              children: [
                for (final s in _sizes) ...[
                  if (s != _sizes.first) const SizedBox(width: 10),
                  _sizeCard(s),
                ],
              ],
            ),
          const SizedBox(height: 6),
          Text(
            context.l10n.sendStandardOnly,
            style: TextStyle(fontSize: 12, color: opsMutedText, height: 1.4),
          ),
          const SizedBox(height: 20),
          OpsSectionLabel(context.l10n.ordRecipient, icon: LucideIcons.userRound),
          _field(
            controller: _phoneCtrl,
            hint: context.l10n.sendRecipientPhoneHint,
            icon: LucideIcons.phone,
            keyboardType: TextInputType.phone,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(ProfileConstants.vnPhoneLength),
            ],
            validator: _validateReceiverPhone,
          ),
          const SizedBox(height: 10),
          _field(
            controller: _nameCtrl,
            hint: context.l10n.sendRecipientNameHint,
            icon: LucideIcons.idCard,
          ),
          const SizedBox(height: 10),
          _field(
            key: const ValueKey('send-receiver-email'),
            controller: _emailCtrl,
            hint: context.l10n.sendRecipientEmailHint,
            icon: LucideIcons.mail,
            keyboardType: TextInputType.emailAddress,
            // Bắt buộc: Lock.R báo người nhận qua email này, và người gửi gửi lại được từ chi tiết đơn.
            validator: _validateReceiverEmail,
          ),
          const SizedBox(height: 8),
          // Nói rõ người nhận được báo lúc nào để người gửi khỏi nhắn trùng.
          OpsBanner(
            tone: OpsBannerTone.info,
            icon: LucideIcons.mailCheck,
            text: context.l10n.sendEmailInfo,
          ),
          const SizedBox(height: 20),
          OpsSectionLabel(
            context.l10n.sendRecipientMessage,
            icon: LucideIcons.messageSquareText,
          ),
          _field(
            controller: _noteCtrl,
            hint: context.l10n.sendMessageHint,
            icon: LucideIcons.pencil,
            maxLines: 2,
            maxLength: _noteMaxLength,
          ),
          const SizedBox(height: 12),
          OpsBanner(
            tone: OpsBannerTone.info,
            icon: LucideIcons.clock,
            text: sendPickupPolicyText(businessConfig),
          ),
          // Admin đặt 0 mã mỗi đơn ⇒ tắt nhập mã.
          if (businessConfig.maxVouchersPerOrder > 0) ...[
            const SizedBox(height: 20),
            OpsSectionLabel(context.l10n.commonDiscountCode, icon: LucideIcons.ticket),
            PromoCodeField(
              orderTotal: _fee,
              lockerId: _lockerId,
              service: _service,
              onChanged: (discount, code) => setState(() {
                _discount = discount;
                _promoCode = code;
              }),
            ),
          ],
          const SizedBox(height: 20),
          OpsSectionLabel(context.l10n.commonRewardPoints, icon: LucideIcons.sparkles),
          LoyaltyRedeemToggle(
            orderTotal: _feeAfterVoucher,
            service: _service,
            onChanged: (points, discount) => setState(() {
              _pointsToUse = points;
              _pointsDiscount = discount;
            }),
          ),
        ].animate(interval: 40.ms).fadeIn(duration: 250.ms).slideY(begin: 0.06),
      ),
    );
  }

  Widget _lockedLockerCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: opsBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: opsPrimary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(LucideIcons.warehouse, color: opsPrimary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _lockerName ?? widget.locationName ?? context.l10n.commonSelectedLocker,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14.5,
                    color: opsDark,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (widget.locationName != null)
                  Text(
                    widget.locationName!,
                    style: const TextStyle(fontSize: 12, color: opsMutedText),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          const Icon(LucideIcons.lockKeyhole, size: 18, color: opsMutedText),
        ],
      ),
    );
  }

  /// Nhãn còn/hết ô dưới thẻ loại ô — giống Thuê tủ. `null` khi chưa biết.
  Widget? _availabilityText(int? available) {
    if (available == null) return null;
    return available == 0
        ? Text(
            context.l10n.commonNoFreeBoxes,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Colors.redAccent,
            ),
          )
        : Text(
            context.l10n.commonFreeBoxes(available),
            style: const TextStyle(fontSize: 11, color: Colors.green),
          );
  }

  /// Một cỡ ô (nhỏ / vừa / lớn) khi khách chưa chọn ô cụ thể trên sơ đồ.
  Widget _sizeCard(String size) {
    final selected = _size == size;
    final available = _availableBySize?[size];
    final disabled = available == 0;
    final color = disabled
        ? Colors.grey.shade400
        : (selected ? opsPrimary : opsDark);
    return Expanded(
      child: GestureDetector(
        onTap: disabled ? null : () => setState(() => _size = size),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: selected
                ? opsPrimary.withValues(alpha: 0.06)
                : (disabled ? Colors.grey.shade100 : Colors.white),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected
                  ? opsPrimary
                  : (disabled ? Colors.grey.shade300 : opsBorder),
              width: selected ? 1.8 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    LucideIcons.box,
                    size: switch (size) {
                      'SMALL' => 16.0,
                      'LARGE' => 24.0,
                      _ => 20.0,
                    },
                    color: disabled
                        ? Colors.grey.shade400
                        : (selected ? opsPrimary : opsMutedText),
                  ),
                  const Spacer(),
                  if (selected)
                    const Icon(
                      LucideIcons.circleCheck,
                      color: opsPrimary,
                      size: 16,
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                context.l10n.sendBoxSize(_sizeLabel(size).toLowerCase()),
                style: TextStyle(fontWeight: FontWeight.w800, color: color),
              ),
              const SizedBox(height: 4),
              _availabilityText(available) ??
                  Text(
                    _sizeTitle(size).split(' ').last,
                    style: const TextStyle(fontSize: 11, color: opsMutedText),
                  ),
            ],
          ),
        ),
      ),
    );
  }

  /// Ô đã chọn trên sơ đồ tủ (khoá, không đổi được) — như thẻ loại ô của Thuê tủ.
  Widget _lockedCellCard() {
    // Sơ đồ không ghi cỡ ô ⇒ không đoán cỡ, cũng không đếm ô cùng cỡ.
    final knownSize = _normalizeSize(widget.initialBoxSize) != null;
    final available = knownSize ? (_availableBySize?[_size]) : null;
    final title = [
      if (widget.initialBoxNumber != null) context.l10n.boxNumberLabel(widget.initialBoxNumber!),
      knownSize ? _sizeTitle(_size) : context.l10n.sendSelectedBox,
    ].join(' · ');
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _selectedBoxTaken
            ? Colors.grey.shade100
            : opsPrimary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _selectedBoxTaken ? opsBorder : opsPrimary,
          width: 1.8,
        ),
      ),
      child: Row(
        children: [
          Icon(
            LucideIcons.box,
            color: _selectedBoxTaken ? opsMutedText : opsPrimary,
            size: 22,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: _selectedBoxTaken ? opsMutedText : opsDark,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        context.l10n.sendFeePerParcel(fmtPrice(_fee)),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: opsDark,
                        ),
                      ),
                    ),
                    if (_selectedBoxTaken) ...[
                      const SizedBox(width: 8),
                      Text(
                        context.l10n.sendBoxTaken,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.redAccent,
                        ),
                      ),
                    ] else if (available != null) ...[
                      const SizedBox(width: 8),
                      _availabilityText(available)!,
                    ],
                  ],
                ),
              ],
            ),
          ),
          const Icon(LucideIcons.lockKeyhole, size: 16, color: opsMutedText),
        ],
      ),
    );
  }

  // ---- Stage 2: result ----
  Widget _buildResult() {
    final order = _order!;
    final status = order['status'] as String?;
    final isDropped = status == 'STORING';
    final hasReceiverAccount = order['receiverId'] != null;
    final total = order['totalPrice'];
    final hasFee = total is num ? total > 0 : _netFee > 0;
    final unpaid = (order['paymentStatus'] as String?) != 'PAID';
    final config = businessConfig;
    final mustPayFirst = hasFee && unpaid && config.requirePaymentBeforeDrop;
    final payment = _payment;

    // Phải trả trước khi lấy mã mở ô ⇒ hiển thị trực tiếp khung VietQR gọn gàng
    if (!isDropped && mustPayFirst && payment != null) {
      return ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        children: [
          if (orderHasDiscounts(order)) ...[
            OpsCard(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: OrderDiscountRows(order: order),
            ),
            const SizedBox(height: 12),
          ],
          SepayQrSection(controller: payment),
          const SizedBox(height: 12),
          OpsBanner(
            tone: OpsBannerTone.info,
            icon: LucideIcons.badgeAlert,
            text:
                context.l10n.commonScanQrPayHold(config.autoCancelUnpaidMinutes),
          ),
        ],
      );
    }

    final receiverShare = isDropped ? _receiverShare(order) : null;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _SendStepper(active: isDropped ? 2 : 1),
        const SizedBox(height: 16),
        OpsCard(
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      context.l10n.commonOrderCode(order['orderCode'] ?? '#${order['id']}'),
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        color: opsDark,
                      ),
                    ),
                  ),
                  StatusChip(status),
                ],
              ),
              const Divider(height: 24, color: opsBorder),
              if (order['id'] is int && !(mustPayFirst && !isDropped)) ...[
                Align(
                  alignment: Alignment.centerLeft,
                  child: PaymentStatusChip(
                    orderId: order['id'] as int,
                    service: _service,
                  ),
                ),
                const SizedBox(height: 14),
              ],
              // Tiền thật server tính (mã giảm giá + điểm thưởng).
              if (orderHasDiscounts(order)) ...[
                OrderDiscountRows(order: order),
                const SizedBox(height: 14),
              ],
              if (!isDropped && mustPayFirst) ...[
                // Mã VietQR SePay thế chỗ mã bỏ hàng cho tới khi đơn PAID.
                if (payment != null) SepayQrSection(controller: payment),
              ] else ...[
                if (!isDropped) ...[
                  _ResultHeadline(
                    icon: LucideIcons.packageOpen,
                    title: context.l10n.sendStep1Title,
                    subtitle:
                        context.l10n.sendStep1Body(
                          order['sendBoxNumber'] == null
                              ? context.l10n.boxOfOrder
                              : context.l10n.boxNumberLower(order['sendBoxNumber']),
                        ),
                  ),
                ] else ...[
                  _ResultHeadline(
                    icon: LucideIcons.packageCheck,
                    title: context.l10n.sendStep2Title,
                    subtitle: hasReceiverAccount
                        ? context.l10n.sendPinSentToRecipient
                        : context.l10n.sendSharePinWithRecipient,
                  ),
                ],
                const SizedBox(height: 16),
                AccessCredentials(
                  pin: order['pinCode'] as String?,
                  qrToken: order['qrToken'] as String?,
                  caption: isDropped
                      ? context.l10n.sendRecipientEntersPin
                      : context.l10n.sendEnterPinToDrop,
                ),
                // Chỉ PIN nhận hàng (sau khi bỏ hàng) mới chia sẻ; PIN bỏ hàng
                // là của người gửi.
                if (receiverShare != null) ...[
                  const SizedBox(height: 14),
                  PickupCodeShareActions(share: receiverShare),
                ],
              ],
              // Người nhận vừa nhập ở bước trước nhưng màn kết quả không hiện
              // lại, nên không kiểm tra được mình gõ đúng số chưa.
              ...[
                const SizedBox(height: 16),
                OpsSectionLabel(
                  context.l10n.ordRecipient,
                  icon: LucideIcons.userRound,
                ),
                OpsInfoRow(
                  icon: LucideIcons.user,
                  label: context.l10n.commonFullNameShort,
                  value: _textOrDash(order['receiverName']),
                ),
                OpsInfoRow(
                  icon: LucideIcons.phone,
                  label: context.l10n.commonPhoneNumber,
                  value: _textOrDash(order['receiverPhone']),
                ),
                if (_hasText(order['receiverEmail']))
                  OpsInfoRow(
                    icon: LucideIcons.mail,
                    label: 'Email',
                    value: '${order['receiverEmail']}',
                  ),
                OpsInfoRow(
                  icon: LucideIcons.userCheck,
                  label: context.l10n.sendLockrAccount,
                  value: hasReceiverAccount
                      ? context.l10n.sendHasAccount
                      : context.l10n.sendNoAccount,
                ),
                if (_hasText(order['customerNote']))
                  OpsInfoRow(
                    icon: LucideIcons.stickyNote,
                    label: context.l10n.commonNote,
                    value: '${order['customerNote']}',
                  ),
              ],
              if (isDropped && order['pickupDeadline'] != null) ...[
                const SizedBox(height: 16),
                OpsBanner(
                  tone: OpsBannerTone.warning,
                  icon: LucideIcons.clock,
                  text: context.l10n.sendPickupBefore(
                    fmtDateTime(order['pickupDeadline']),
                    fmtRemaining(order['pickupDeadline']),
                    overtimePolicyText(config),
                  ),
                ),
              ],
            ],
          ),
        ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.05),
        const SizedBox(height: 16),
        if (!isDropped && mustPayFirst) ...[
          OpsBanner(
            tone: OpsBannerTone.info,
            icon: LucideIcons.badgeAlert,
            text:
                context.l10n.commonScanQrPayHold(config.autoCancelUnpaidMinutes),
          ),
          const SizedBox(height: 12),
          if (payment != null) SepayPaymentActions(controller: payment),
        ] else if (!isDropped) ...[
          if (hasFee && unpaid && payment != null) ...[
            // Admin cho bỏ hàng trước khi trả, nhưng xác nhận bỏ hàng vẫn cần
            // đơn đã thanh toán.
            SepayQrSection(controller: payment),
            const SizedBox(height: 12),
            SepayPaymentActions(controller: payment),
            const SizedBox(height: 12),
          ],
          OpsBanner(
            tone: OpsBannerTone.info,
            icon: LucideIcons.lockKeyholeOpen,
            text: context.l10n.sendDropInstructions,
          ),
          const SizedBox(height: 12),
          OpsPrimaryButton(
            label: context.l10n.sendOpenToDrop,
            icon: LucideIcons.lockKeyholeOpen,
            color: opsPrimary,
            loading: _loading,
            onPressed: _openBox,
          ),
          const SizedBox(height: 12),
          OpsPrimaryButton(
            label: context.l10n.sendIDropped,
            icon: LucideIcons.check,
            loading: _loading,
            onPressed: _confirmDrop,
          ),
        ] else
          OpsPrimaryButton(
            label: context.l10n.commonDone,
            icon: LucideIcons.house,
            onPressed: () {
              final router = GoRouter.of(context);
              Navigator.of(context, rootNavigator: true).popUntil((route) => route.isFirst);
              Future.microtask(() {
                router.go(AppRouter.orders);
              });
            },
          ),
      ],
    );
  }

  Widget _field({
    Key? key,
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
    int maxLines = 1,
    int? maxLength,
  }) {
    return TextFormField(
      key: key,
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: validator,
      maxLines: maxLines,
      maxLength: maxLength,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, size: 18, color: opsMutedText),
        filled: true,
        fillColor: Colors.white,
        border: _border(opsBorder),
        enabledBorder: _border(opsBorder),
        focusedBorder: _border(opsPrimary, width: 1.6),
        errorBorder: _border(const Color(0xFFEF4444)),
        focusedErrorBorder: _border(const Color(0xFFEF4444), width: 1.6),
      ),
    );
  }

  OutlineInputBorder _border(Color color, {double width = 1}) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: color, width: width),
      );
}

/// Two-step progress header for the SEND flow.
class _SendStepper extends StatelessWidget {
  const _SendStepper({required this.active});

  /// 0 = form, 1 = drop pending, 2 = handed to receiver.
  final int active;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _step(1, context.l10n.sendStepDrop, done: active >= 2, current: active <= 1),
        _connector(active >= 2),
        _step(2, context.l10n.sendStepRecipientPicks, done: false, current: active >= 2),
      ],
    );
  }

  Widget _step(int n, String label, {required bool done, required bool current}) {
    final color = done || current ? opsPrimary : const Color(0xFFCBD5E1);
    return Expanded(
      child: Column(
        children: [
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: current ? opsPrimary : color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
              border: Border.all(color: color, width: 1.6),
            ),
            child: done
                ? const Icon(LucideIcons.check, size: 16, color: Colors.white)
                : Text(
                    '$n',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: current ? Colors.white : color,
                    ),
                  ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: done || current ? opsDark : const Color(0xFF94A3B8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _connector(bool active) => Container(
        width: 28,
        height: 2,
        margin: const EdgeInsets.only(bottom: 22),
        color: active ? opsPrimary : const Color(0xFFE2E8F0),
      );
}

class _ResultHeadline extends StatelessWidget {
  const _ResultHeadline({
    required this.icon,
    required this.title,
    required this.subtitle,
  });
  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 30, color: opsPrimary),
        const SizedBox(height: 8),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 16,
            color: opsDark,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 13, color: opsMutedText, height: 1.4),
        ),
      ],
    );
  }
}

bool _hasText(dynamic value) => value != null && '$value'.trim().isNotEmpty;

String _textOrDash(dynamic value) => _hasText(value) ? '$value'.trim() : '—';
