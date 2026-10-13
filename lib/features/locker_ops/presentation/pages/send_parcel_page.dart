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
import 'package:smart_laundry_locker/features/locker_ops/presentation/widgets/ops_widgets.dart';
import 'package:smart_laundry_locker/features/locker_ops/presentation/widgets/order_extras.dart';
import 'package:smart_laundry_locker/features/locker_ops/presentation/widgets/pickup_code_share_actions.dart';
import 'package:smart_laundry_locker/features/locker_ops/presentation/widgets/sepay_payment.dart';
import 'package:smart_laundry_locker/shared/shared.dart';
import 'package:smart_laundry_locker/shared/widgets/user_ui_kit.dart';
import 'package:smart_laundry_locker/core/services/app_event_bus.dart';

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
  });

  /// Ô khách đã chọn trên sơ đồ tủ (gửi kèm `boxId` khi tạo đơn).
  final int? initialBoxId;
  final int? initialBoxNumber;

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
  String _size = 'MEDIUM';

  /// Thanh toán SePay của đơn vừa tạo (mã VietQR hiện ngay trên màn).
  SepayPaymentController? _payment;

  /// Tên tủ hiển thị khi mở từ lưới ô mà nơi gọi chỉ truyền id.
  String? _lockerName;

  /// Địa chỉ tủ cho tin nhắn chia sẻ mã — tải một lần khi hàng đã vào ô mà
  /// danh sách tủ không có sẵn (mở từ lưới ô).
  String? _lockerAddress;
  bool _lockerInfoRequested = false;

  int get _netFee => (_fee - _discount).clamp(0, _fee);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (widget.initialLockerId != null) {
      // Đến từ lưới ô — tủ đã xác định, bỏ qua gọi API load danh sách tủ.
      _lockerId = widget.initialLockerId;
      _loadingLockers = false;
      _lockerName = widget.initialLockerName;
      if (_lockerName == null || _lockerName!.trim().isEmpty) {
        _loadLockerName(widget.initialLockerId!);
      }
    } else {
      _loadLockers();
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
    _snack('Thanh toán thành công! Mã PIN mở ô tủ đã sẵn sàng.');
  }

  Future<void> _loadLockers() async {
    try {
      final lockers = await _service.lockers();
      if (!mounted) return;
      setState(() {
        _lockers = lockers.where((l) => l['status'] == 'ACTIVE').toList();
        final preset = widget.initialLockerId;
        if (preset != null && _lockers.any((l) => l['id'] == preset)) {
          _lockerId = preset;
        } else if (_lockers.isNotEmpty) {
          _lockerId = _lockers.first['id'] as int?;
        }
        _loadingLockers = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadingLockers = false);
      _snack(LockerOpsService.errorMessage(e));
    }
  }

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
        receiverEmail:
            _emailCtrl.text.trim().isEmpty ? null : _emailCtrl.text.trim(),
        note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
        promotionCode: _promoCode,
        size: _size,
      );
      if (!mounted) return;
      setState(() => _order = order);
      // Chưa trả ⇒ hiện mã VietQR SePay ngay (một checkout cho đơn này).
      _syncPayment();
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
      _snack('Đơn chưa có thông tin ô/PIN để mở tủ.');
      return;
    }
    setState(() => _loading = true);
    try {
      final res = await _service.unlock(lockerId, boxId, pin);
      final message = res['message']?.toString();
      _snack(
        res['accepted'] == true
            ? 'Ô đã mở — đặt hàng vào, đóng cửa rồi bấm xác nhận.'
            : (message == null || message.isEmpty ? 'Không mở được ô' : message),
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
      _snack('Đã bỏ hàng. Gửi mã lấy hàng cho người nhận bằng nút Chia sẻ bên dưới.');
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

  String _sizeLabel(String size) => switch (size) {
        'SMALL' => 'Nhỏ',
        'LARGE' => 'Lớn',
        _ => 'Vừa',
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
        title: const Row(
          children: [
            Icon(LucideIcons.triangleAlert, color: Color(0xFFEA580C)),
            SizedBox(width: 8),
            Text(
              'Hủy tạo đơn hàng?',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17),
            ),
          ],
        ),
        content: Text(
          'Đơn hàng chưa được thanh toán. Nếu bạn thoát bây giờ hoặc không hoàn tất thanh toán trong vòng ${businessConfig.autoCancelUnpaidMinutes} phút, đơn hàng sẽ bị hủy và ô tủ sẽ được giải phóng.',
          style: const TextStyle(fontSize: 14, color: opsDark, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Ở lại thanh toán'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hủy đơn & Thoát'),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    final orderId = order['id'] as int?;
    if (orderId != null) {
      try {
        await _service.cancelOrder(orderId);
        _snack('Đã hủy đơn hàng và giải phóng ô tủ.');
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
              eyebrow: _order == null ? null : 'LOCK.R • THANH TOÁN',
              title: _order == null
                  ? 'Gửi hàng qua tủ'
                  : 'Đơn ${_order!['orderCode'] ?? '#${_order!['id']}'}',
              subtitle: _order == null ? 'Gửi đồ nhanh chóng & tiện lợi' : null,
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
            Row(
              children: [
                const Icon(LucideIcons.receiptText, size: 16, color: opsMutedText),
                const SizedBox(width: 6),
                const Text('Phí gửi', style: TextStyle(color: opsMutedText)),
                const Spacer(),
                if (_discount > 0) ...[
                  Text(
                    fmtPrice(_fee),
                    style: const TextStyle(
                      fontSize: 13,
                      color: opsMutedText,
                      decoration: TextDecoration.lineThrough,
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                Text(
                  fmtPrice(_netFee),
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    color: opsDark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            OpsPrimaryButton(
              label: 'Tạo đơn & lấy PIN bỏ hàng',
              icon: LucideIcons.arrowRight,
              loading: _loading,
              onPressed: _create,
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

  // ---- Stage 1: form ----
  Widget _buildForm() {
    if (_loadingLockers) {
      return const Center(
        child: AppLoadingIndicator(message: 'Đang tải danh sách tủ...'),
      );
    }
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const _SendStepper(active: 0),
          const SizedBox(height: 16),
          const OpsBanner(
            text: 'Gửi hàng cho người khác qua tủ: bạn bỏ hàng vào ô bằng PIN, '
                'hệ thống sinh PIN mới gửi người nhận để họ tới lấy.',
            icon: LucideIcons.packagePlus,
          ),
          if (widget.locationName != null) ...[
            const SizedBox(height: 12),
            LocationHint(name: widget.locationName!),
          ],
          const SizedBox(height: 20),
          const OpsSectionLabel('Chọn tủ', icon: LucideIcons.warehouse),
          if (widget.initialLockerId != null)
            _lockedLockerCard()
          else
            LockerPickerField(
              lockers: _lockers,
              selectedId: _lockerId,
              onSelected: (l) => setState(() => _lockerId = l['id'] as int?),
            ),
          const SizedBox(height: 20),
          const OpsSectionLabel('Kích thước hàng', icon: LucideIcons.packageSearch),
          Wrap(
            spacing: 8,
            children: _sizes.map((s) {
              final selected = _size == s;
              return ChoiceChip(
                label: Text(_sizeLabel(s)),
                selected: selected,
                onSelected: (_) => setState(() => _size = s),
                selectedColor: opsPrimary,
                labelStyle: TextStyle(
                  color: selected ? Colors.white : opsDark,
                  fontWeight: FontWeight.w600,
                ),
                backgroundColor: Colors.white,
                side: BorderSide(color: selected ? opsPrimary : opsBorder),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          const OpsSectionLabel('Người nhận', icon: LucideIcons.userRound),
          _field(
            controller: _phoneCtrl,
            hint: 'Số điện thoại người nhận',
            icon: LucideIcons.phone,
            keyboardType: TextInputType.phone,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            validator: (v) => (v == null || v.trim().length < 9)
                ? 'Nhập số điện thoại hợp lệ'
                : null,
          ),
          const SizedBox(height: 10),
          _field(
            controller: _nameCtrl,
            hint: 'Tên người nhận (tùy chọn)',
            icon: LucideIcons.idCard,
          ),
          const SizedBox(height: 10),
          _field(
            controller: _emailCtrl,
            hint: 'Email người nhận (tùy chọn)',
            icon: LucideIcons.mail,
            keyboardType: TextInputType.emailAddress,
            validator: (v) {
              final email = v?.trim() ?? '';
              if (email.isEmpty) return null;
              return _looksLikeEmail(email) ? null : 'Email không hợp lệ';
            },
          ),
          const SizedBox(height: 8),
          // Nói thẳng người nhận có tự nhận được mã không: nếu không, người gửi
          // phải chủ động chuyển mã, và họ chỉ làm vậy khi biết.
          const OpsBanner(
            tone: OpsBannerTone.info,
            icon: LucideIcons.send,
            text:
                'Bỏ hàng xong, bấm "Chia sẻ mã cho người nhận" để gửi mã lấy hàng '
                'qua Zalo, Messenger hoặc SMS. Người nhận đã có tài khoản Lock.R '
                'trùng số điện thoại còn thấy đơn và nhận thông báo trong app.',
          ),
          const SizedBox(height: 20),
          const OpsSectionLabel('Ghi chú', icon: LucideIcons.stickyNote),
          _field(
            controller: _noteCtrl,
            hint: 'VD: Hàng dễ vỡ, gọi trước khi lấy...',
            icon: LucideIcons.pencil,
            maxLines: 2,
          ),
          const SizedBox(height: 12),
          OpsBanner(
            tone: OpsBannerTone.info,
            icon: LucideIcons.clock,
            text: sendPickupPolicyText(businessConfig),
          ),
          const SizedBox(height: 20),
          const OpsSectionLabel('Mã giảm giá', icon: LucideIcons.ticket),
          PromoCodeField(
            orderTotal: _fee,
            lockerId: _lockerId,
            onChanged: (discount, code) => setState(() {
              _discount = discount;
              _promoCode = code;
            }),
          ),
          const SizedBox(height: 10),
          const LoyaltyPointsHint(),
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
                  _lockerName ?? widget.locationName ?? 'Tủ đã chọn',
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
                if (widget.initialBoxNumber != null)
                  Text(
                    'Ô số ${widget.initialBoxNumber}',
                    style: const TextStyle(fontSize: 12, color: opsMutedText),
                  ),
              ],
            ),
          ),
          const Icon(LucideIcons.lockKeyhole, size: 18, color: opsMutedText),
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
          SepayQrSection(controller: payment),
          const SizedBox(height: 12),
          OpsBanner(
            tone: OpsBannerTone.info,
            icon: LucideIcons.badgeAlert,
            text:
                'Quét mã QR trên và chuyển khoản trong ${config.autoCancelUnpaidMinutes} phút để giữ ô — mã bỏ hàng sẽ tự hiện sau khi thanh toán.',
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
                      'Đơn ${order['orderCode'] ?? '#${order['id']}'}',
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
                  child: PaymentStatusChip(orderId: order['id'] as int),
                ),
                const SizedBox(height: 14),
              ],
              if (!isDropped && mustPayFirst) ...[
                // Mã VietQR SePay thế chỗ mã bỏ hàng cho tới khi đơn PAID.
                if (payment != null) SepayQrSection(controller: payment),
              ] else ...[
                if (!isDropped) ...[
                  _ResultHeadline(
                    icon: LucideIcons.packageOpen,
                    title: 'Bước 1 — Bỏ hàng vào ô',
                    subtitle:
                        'Đến tủ, nhập PIN bên dưới để mở ${order['sendBoxNumber'] == null ? 'ô của đơn' : 'ô số ${order['sendBoxNumber']}'}, '
                        'đặt hàng vào rồi đóng cửa.',
                  ),
                ] else ...[
                  _ResultHeadline(
                    icon: LucideIcons.packageCheck,
                    title: 'Bước 2 — Đã bỏ hàng xong',
                    subtitle: hasReceiverAccount
                        ? 'PIN nhận hàng đã được gửi tới tài khoản người nhận.'
                        : 'Hãy chuyển mã PIN nhận hàng bên dưới cho người nhận.',
                  ),
                ],
                const SizedBox(height: 16),
                AccessCredentials(
                  pin: order['pinCode'] as String?,
                  qrToken: order['qrToken'] as String?,
                  caption: isDropped
                      ? 'Người nhận nhập PIN tại tủ để lấy hàng'
                      : 'Nhập PIN tại tủ để mở ô và bỏ hàng',
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
                const OpsSectionLabel(
                  'Người nhận',
                  icon: LucideIcons.userRound,
                ),
                OpsInfoRow(
                  icon: LucideIcons.user,
                  label: 'Họ tên',
                  value: _textOrDash(order['receiverName']),
                ),
                OpsInfoRow(
                  icon: LucideIcons.phone,
                  label: 'Số điện thoại',
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
                  label: 'Tài khoản Lock.R',
                  value: hasReceiverAccount
                      ? 'Đã có — PIN gửi thẳng vào app'
                      : 'Chưa có — bạn cần chuyển PIN cho người nhận',
                ),
                if (_hasText(order['customerNote']))
                  OpsInfoRow(
                    icon: LucideIcons.stickyNote,
                    label: 'Ghi chú',
                    value: '${order['customerNote']}',
                  ),
              ],
              if (isDropped && order['pickupDeadline'] != null) ...[
                const SizedBox(height: 16),
                OpsBanner(
                  tone: OpsBannerTone.warning,
                  icon: LucideIcons.clock,
                  text: 'Người nhận cần lấy hàng trước '
                      '${fmtDateTime(order['pickupDeadline'])} '
                      '(${fmtRemaining(order['pickupDeadline'])}). '
                      '${overtimePolicyText(config)}',
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
                'Quét mã QR trên và chuyển khoản trong ${config.autoCancelUnpaidMinutes} phút để giữ ô — mã bỏ hàng sẽ tự hiện sau khi thanh toán.',
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
          const OpsBanner(
            tone: OpsBannerTone.info,
            icon: LucideIcons.lockKeyholeOpen,
            text: 'Mở ô bằng nút bên dưới hoặc nhập PIN tại tủ, đặt hàng vào, '
                'đóng cửa rồi xác nhận. Xác nhận ngay trên màn hình tủ cũng được.',
          ),
          const SizedBox(height: 12),
          OpsPrimaryButton(
            label: 'Mở ô để bỏ hàng',
            icon: LucideIcons.lockKeyholeOpen,
            color: opsPrimary,
            loading: _loading,
            onPressed: _openBox,
          ),
          const SizedBox(height: 12),
          OpsPrimaryButton(
            label: 'Tôi đã bỏ hàng vào ô',
            icon: LucideIcons.check,
            loading: _loading,
            onPressed: _confirmDrop,
          ),
        ] else
          OpsPrimaryButton(
            label: 'Hoàn tất',
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
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: validator,
      maxLines: maxLines,
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
        _step(1, 'Bỏ hàng', done: active >= 2, current: active <= 1),
        _connector(active >= 2),
        _step(2, 'Người nhận lấy', done: false, current: active >= 2),
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
