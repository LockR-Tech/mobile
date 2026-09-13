import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:smart_laundry_locker/core/routing/app_router.dart';
import 'package:smart_laundry_locker/core/theme/shadcn_theme.dart';
import 'package:smart_laundry_locker/features/locker_ops/data/locker_ops_service.dart';
import 'package:smart_laundry_locker/features/locker_ops/presentation/widgets/locker_picker.dart';
import 'package:smart_laundry_locker/features/locker_ops/presentation/widgets/ops_widgets.dart';
import 'package:smart_laundry_locker/features/locker_ops/presentation/widgets/order_extras.dart';

/// SEND flow (gửi hàng C2C qua tủ).
/// Stage 1: tạo đơn + nhận PIN bỏ hàng. Stage 2: xác nhận đã bỏ hàng → PIN
/// nhận hàng được sinh mới và gửi cho người nhận (đúng luồng PIN 2 giai đoạn
/// của backend `order-service`).
class SendParcelPage extends StatefulWidget {
  const SendParcelPage({
    super.key,
    this.initialLockerId,
    this.initialLockerName,
    this.locationName,
  });

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

class _SendParcelPageState extends State<SendParcelPage> {
  final _service = LockerOpsService();
  final _formKey = GlobalKey<FormState>();
  final _phoneCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();

  static const _fee = 15000;

  static const _sizes = ['SMALL', 'MEDIUM', 'LARGE'];

  List<Map<String, dynamic>> _lockers = [];
  int? _lockerId;
  bool _loadingLockers = true;
  bool _loading = false;
  Map<String, dynamic>? _order;
  int _discount = 0;
  String? _promoCode;
  String _size = 'MEDIUM';

  int get _netFee => (_fee - _discount).clamp(0, _fee);

  @override
  void initState() {
    super.initState();
    if (widget.initialLockerId != null) {
      // Đến từ lưới ô — tủ đã xác định, bỏ qua gọi API load danh sách tủ.
      _lockerId = widget.initialLockerId;
      _loadingLockers = false;
    } else {
      _loadLockers();
    }
  }

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _nameCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
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
        receiverName:
            _nameCtrl.text.trim().isEmpty ? null : _nameCtrl.text.trim(),
        note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
        promotionCode: _promoCode,
        size: _size,
      );
      if (!mounted) return;
      setState(() => _order = order);
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
      _snack('Đã gửi PIN nhận hàng tới người nhận');
    } catch (e) {
      _snack(LockerOpsService.errorMessage(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _sizeLabel(String size) => switch (size) {
        'SMALL' => 'Nhỏ',
        'LARGE' => 'Lớn',
        _ => 'Vừa',
      };

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AISLShadcnTheme.navySurface,
      appBar: AppBar(
        title: const Text('Gửi hàng qua tủ'),
        backgroundColor: AISLShadcnTheme.navyPrimary,
        foregroundColor: Colors.white,
      ),
      bottomNavigationBar: _order == null ? Container(
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
      ) : null,
      body: _order == null ? _buildForm() : _buildResult(),
    );
  }

  // ---- Stage 1: form ----
  Widget _buildForm() {
    if (_loadingLockers) {
      return const Center(child: CircularProgressIndicator());
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
          const SizedBox(height: 20),
          const OpsSectionLabel('Ghi chú', icon: LucideIcons.stickyNote),
          _field(
            controller: _noteCtrl,
            hint: 'VD: Hàng dễ vỡ, gọi trước khi lấy...',
            icon: LucideIcons.pencil,
            maxLines: 2,
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
                  widget.initialLockerName ?? widget.locationName ?? 'Tủ đã chọn',
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

  Future<void> _mockPayment() async {
    final id = _order?['id'] as int?;
    if (id == null) return;
    setState(() => _loading = true);
    try {
      // Dùng CASH thay cho WALLET để mock thành công mà không cần số dư trong DB thật
      final order = await _service.checkout(id, 'CASH');
      if (!mounted) return;
      setState(() => _order = order);
      _snack('Đã mock thanh toán (CASH) thành công');
      // Tự động gọi confirmDrop sau khi thanh toán thành công
      await _confirmDrop();
    } catch (e) {
      _snack(LockerOpsService.errorMessage(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ---- Stage 2: result ----
  Widget _buildResult() {
    final order = _order!;
    final status = order['status'] as String?;
    final isDropped = status == 'STORING';
    final hasReceiverAccount = order['receiverId'] != null;

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
                      'Đơn ${order['orderCode'] ?? ''}',
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
              if (order['id'] is int) ...[
                Align(
                  alignment: Alignment.centerLeft,
                  child: PaymentStatusChip(orderId: order['id'] as int),
                ),
                const SizedBox(height: 14),
              ],
              if (!isDropped) ...[
                _ResultHeadline(
                  icon: LucideIcons.packageOpen,
                  title: 'Bước 1 — Bỏ hàng vào ô',
                  subtitle:
                      'Đến tủ, nhập PIN bên dưới để mở ô số ${order['sendBoxId'] ?? '-'}, '
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
                    ? 'Người nhận nhập PIN / quét QR tại tủ để lấy hàng'
                    : 'Nhập PIN hoặc quét QR tại tủ để mở ô và bỏ hàng',
              ),
              if (isDropped && order['pickupDeadline'] != null) ...[
                const SizedBox(height: 16),
                OpsBanner(
                  tone: OpsBannerTone.warning,
                  icon: LucideIcons.clock,
                  text: 'Người nhận cần lấy hàng trước '
                      '${fmtDateTime(order['pickupDeadline'])} '
                      '(${fmtRemaining(order['pickupDeadline'])}).',
                ),
              ],
            ],
          ),
        ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.05),
        const SizedBox(height: 16),
        if (!isDropped) ...[
          OpsPrimaryButton(
            label: 'Đã thanh toán (Mock Ví)',
            icon: LucideIcons.wallet,
            loading: _loading,
            onPressed: _mockPayment,
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
