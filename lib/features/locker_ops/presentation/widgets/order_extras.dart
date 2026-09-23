import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:smart_laundry_locker/core/config/business_config_provider.dart';
import 'package:smart_laundry_locker/features/locker_ops/data/locker_ops_service.dart';
import 'package:smart_laundry_locker/features/locker_ops/presentation/widgets/ops_widgets.dart';
import 'package:smart_laundry_locker/features/promotions/data/models/promotion_model.dart';
import 'package:smart_laundry_locker/features/promotions/data/repositories/promotion_repository.dart';
import 'package:smart_laundry_locker/core/network/api_client.dart';

/// Compute the discount (in VND) a validated [promotion] grants on [total].
/// Mirrors the order-service Promotion model (discountType / discountValue /
/// maxDiscountAmount / minOrderAmount).
int computePromotionDiscount(Map<String, dynamic>? promotion, int total) {
  if (promotion == null) return 0;
  final type = (promotion['discountType'] as String?) ?? 'FIXED_AMOUNT';
  final value = (promotion['discountValue'] as num?)?.toDouble() ?? 0;
  final maxDiscount = (promotion['maxDiscountAmount'] as num?)?.toDouble();
  final minOrder = (promotion['minOrderAmount'] as num?)?.toDouble() ?? 0;
  if (total < minOrder) return 0;
  double discount;
  if (type == 'PERCENT' || type == 'PERCENTAGE') {
    discount = total * value / 100;
    if (maxDiscount != null && discount > maxDiscount) discount = maxDiscount;
  } else {
    discount = value;
  }
  if (discount > total) discount = total.toDouble();
  if (discount < 0) discount = 0;
  return discount.round();
}

/// A promo-code input that validates against `/api/promotions/validate/{code}`
/// and reports the applied discount + code back to the parent.
class PromoCodeField extends StatefulWidget {
  const PromoCodeField({
    super.key,
    required this.orderTotal,
    required this.onChanged,
    this.lockerId,
  });

  /// Current order subtotal (VND), used to compute percentage discounts.
  final int orderTotal;

  /// Tủ đang đặt — backend dùng để check mã có scope theo tủ/kiosk.
  final int? lockerId;

  /// Called with the applied discount (VND) and the code (null when cleared).
  final void Function(int discount, String? code) onChanged;

  @override
  State<PromoCodeField> createState() => _PromoCodeFieldState();
}

class _PromoCodeFieldState extends State<PromoCodeField> {
  final _service = LockerOpsService();
  bool _loading = false;
  String? _appliedCode;
  String? _error;

  Future<void> _apply(String code) async {
    if (code.isEmpty) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res =
          await _service.validatePromotion(code, lockerId: widget.lockerId);
      final valid = res['valid'] == true;
      final promotion = res['promotion'] as Map<String, dynamic>?;
      if (!valid || promotion == null) {
        setState(() {
          _error =
              (res['reason'] as String?) ?? 'Mã không hợp lệ hoặc đã hết hạn';
          _appliedCode = null;
        });
        widget.onChanged(0, null);
        return;
      }
      final discount = computePromotionDiscount(promotion, widget.orderTotal);
      if (discount <= 0) {
        setState(() {
          _error = 'Đơn chưa đủ điều kiện áp mã này';
          _appliedCode = null;
        });
        widget.onChanged(0, null);
        return;
      }
      setState(() => _appliedCode = code);
      widget.onChanged(discount, code);
    } catch (e) {
      setState(() => _error = LockerOpsService.errorMessage(e));
      widget.onChanged(0, null);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _clear() {
    setState(() {
      _appliedCode = null;
      _error = null;
    });
    widget.onChanged(0, null);
  }

  Future<void> _showVoucherPicker() async {
    final code = await showModalBottomSheet<String>(
      context: context,
      useRootNavigator: true,
      backgroundColor: Colors.white,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (ctx) => _VoucherPickerSheet(
        orderTotal: widget.orderTotal,
        currentCode: _appliedCode,
      ),
    );
    if (code != null) {
      _apply(code);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_appliedCode != null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF16A34A).withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFF16A34A).withValues(alpha: 0.4)),
        ),
        child: Row(
          children: [
            const Icon(LucideIcons.badgeCheck, color: Color(0xFF16A34A), size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Đã áp mã "$_appliedCode"',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF166534),
                ),
              ),
            ),
            TextButton(
              onPressed: _clear,
              child: const Text('Bỏ'),
            ),
          ],
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: _loading ? null : _showVoucherPicker,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: opsBorder),
            ),
            child: Row(
              children: [
                const Icon(LucideIcons.ticket, size: 18, color: opsMutedText),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Chọn mã giảm giá',
                    style: TextStyle(
                      color: opsDark,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                ),
                if (_loading)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: opsPrimary),
                  )
                else
                  const Icon(LucideIcons.chevronRight, size: 18, color: opsMutedText),
              ],
            ),
          ),
        ),
        if (_error != null) ...[
          const SizedBox(height: 6),
          Text(
            _error!,
            style: const TextStyle(color: Color(0xFFDC2626), fontSize: 12.5),
          ),
        ],
      ],
    );
  }
}

class _VoucherPickerSheet extends StatefulWidget {
  const _VoucherPickerSheet({
    required this.orderTotal,
    this.currentCode,
  });

  final int orderTotal;
  final String? currentCode;

  @override
  State<_VoucherPickerSheet> createState() => _VoucherPickerSheetState();
}

class _VoucherPickerSheetState extends State<_VoucherPickerSheet> {
  final _repo = PromotionRepository(ApiClient());
  List<PromotionModel>? _promotions;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final res = await _repo.getActivePromotions();
      if (!mounted) return;
      setState(() {
        _promotions = res;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 4),
          child: Text(
            'Chọn mã giảm giá',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 18,
              color: opsDark,
            ),
          ),
        ),
        const SizedBox(height: 12),
        if (_loading)
          const Padding(
            padding: EdgeInsets.all(32),
            child: Center(child: CircularProgressIndicator(color: opsPrimary)),
          )
        else if (_promotions == null || _promotions!.isEmpty)
          const Padding(
            padding: EdgeInsets.all(32),
            child: Center(
              child: Text(
                'Chưa có mã giảm giá nào.',
                style: TextStyle(color: opsMutedText),
              ),
            ),
          )
        else
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              itemCount: _promotions!.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (ctx, i) {
                final p = _promotions![i];
                final meetsMin = p.minOrderAmount == null || widget.orderTotal >= p.minOrderAmount!;
                final isSelected = p.code == widget.currentCode;

                return Opacity(
                  opacity: meetsMin ? 1.0 : 0.5,
                  child: GestureDetector(
                    onTap: meetsMin ? () => Navigator.pop(context, p.code) : null,
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isSelected ? opsPrimary.withValues(alpha: 0.05) : opsSurface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: isSelected ? opsPrimary : opsBorder, width: isSelected ? 1.5 : 1),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: const Color(0xFFFACC15).withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(LucideIcons.ticket, color: Color(0xFFCA8A04)),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  p.code,
                                  style: const TextStyle(fontWeight: FontWeight.w800, color: opsDark, fontSize: 15),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  p.name,
                                  style: const TextStyle(fontSize: 13, color: opsMutedText),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (p.minOrderLabel != null) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    p.minOrderLabel!,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: meetsMin ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
                                    ),
                                  ),
                                ]
                              ],
                            ),
                          ),
                          if (isSelected)
                            const Icon(LucideIcons.circleCheck, color: opsPrimary, size: 22)
                          else if (meetsMin)
                            const Icon(LucideIcons.chevronRight, color: opsMutedText, size: 20),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}

/// Số điểm cần để lên hạng kế tiếp theo ngưỡng admin cấu hình
/// (`app.loyalty.tier-*-points`). `null` khi đã ở hạng cao nhất.
String? nextLoyaltyTierText(int points, BusinessConfig config) {
  final tiers = [
    (points: config.tierSilverPoints, name: 'Bạc'),
    (points: config.tierGoldPoints, name: 'Vàng'),
    (points: config.tierPlatinumPoints, name: 'Bạch kim'),
  ]..sort((a, b) => a.points.compareTo(b.points));
  for (final tier in tiers) {
    if (points < tier.points) {
      return 'còn ${tier.points - points} điểm lên hạng ${tier.name}';
    }
  }
  return null;
}

/// Small informational chip showing the user's loyalty points balance.
class LoyaltyPointsHint extends StatefulWidget {
  const LoyaltyPointsHint({super.key, this.service});

  final LockerOpsService? service;

  @override
  State<LoyaltyPointsHint> createState() => _LoyaltyPointsHintState();
}

class _LoyaltyPointsHintState extends State<LoyaltyPointsHint>
    with BusinessConfigStateMixin {
  late final LockerOpsService _service = widget.service ?? LockerOpsService();
  int? _points;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final res = await _service.loyaltyPoints();
      if (!mounted) return;
      setState(() => _points = (res['points'] as num?)?.toInt());
    } catch (_) {
      // Loyalty is optional — stay silent if unavailable.
    }
  }

  @override
  Widget build(BuildContext context) {
    final points = _points;
    if (points == null) return const SizedBox.shrink();
    final nextTier = nextLoyaltyTierText(points, businessConfig);
    return Row(
      children: [
        const Icon(LucideIcons.sparkles, size: 15, color: Color(0xFFCA8A04)),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            nextTier == null
                ? 'Bạn đang có $points điểm tích lũy'
                : 'Bạn đang có $points điểm tích lũy · $nextTier',
            style: const TextStyle(
              fontSize: 12.5,
              color: opsMutedText,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

/// Fetches the order's payments and renders the latest payment status.
class PaymentStatusChip extends StatefulWidget {
  const PaymentStatusChip({super.key, required this.orderId, this.service});

  final int orderId;
  final LockerOpsService? service;

  @override
  State<PaymentStatusChip> createState() => _PaymentStatusChipState();
}

class _PaymentStatusChipState extends State<PaymentStatusChip> {
  late final LockerOpsService _service;
  bool _loading = true;
  String? _status;

  @override
  void initState() {
    super.initState();
    _service = widget.service ?? LockerOpsService();
    _load();
  }

  Future<void> _load() async {
    try {
      final payments = await _service.paymentsByOrder(widget.orderId);
      String? foundStatus;
      if (payments.any((p) =>
          p['status'] == 'COMPLETED' ||
          p['status'] == 'PAID' ||
          p['status'] == 'SUCCESS')) {
        foundStatus = 'COMPLETED';
      } else if (payments.isNotEmpty) {
        foundStatus = payments.last['status'] as String?;
      } else {
        final ord = await _service.order(widget.orderId);
        if (ord['paymentStatus'] == 'PAID') {
          foundStatus = 'COMPLETED';
        }
      }
      if (!mounted) return;
      setState(() {
        _status = foundStatus;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  ({Color color, String label, IconData icon}) _style(String? status) {
    switch (status) {
      case 'PAID':
      case 'SUCCESS':
      case 'COMPLETED':
        return (
          color: const Color(0xFF16A34A),
          label: 'Đã thanh toán',
          icon: LucideIcons.circleCheck,
        );
      case 'PENDING':
      case 'PROCESSING':
        return (
          color: const Color(0xFFCA8A04),
          label: 'Chờ thanh toán',
          icon: LucideIcons.clock,
        );
      case 'FAILED':
      case 'CANCELED':
        return (
          color: const Color(0xFFDC2626),
          label: 'Thanh toán lỗi',
          icon: LucideIcons.circleX,
        );
      default:
        return (
          color: opsMutedText,
          label: 'Chưa có thanh toán',
          icon: LucideIcons.wallet,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const SizedBox(
        width: 16,
        height: 16,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }
    final s = _style(_status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: s.color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(s.icon, size: 14, color: s.color),
          const SizedBox(width: 6),
          Text(
            s.label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: s.color,
            ),
          ),
        ],
      ),
    );
  }
}

/// Hiển thị mã VietQR SePay trực tiếp trên trang để user quét và chuyển khoản.
/// Không cần bấm nút — chỉ cần quét và chuyển đúng nội dung là xong.
class InlineVietQrCard extends StatelessWidget {
  const InlineVietQrCard({
    super.key,
    required this.orderId,
    required this.amount,
  });

  final int orderId;
  final double amount;

  String _qrUrl() {
    final info = Uri.encodeComponent('PAY-$orderId');
    return 'https://img.vietqr.io/image/970422-0000234917957-compact2.jpg'
        '?amount=${amount.toInt()}&addInfo=$info&accountName=TRUONG%20NGUYEN%20THAI%20BINH';
  }

  @override
  Widget build(BuildContext context) {
    final transferNote = 'PAY-$orderId';
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF1E40AF), Color(0xFF3B82F6)],
              ),
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              children: const [
                Icon(LucideIcons.qrCode, color: Colors.white, size: 20),
                SizedBox(width: 10),
                Text(
                  'Quét mã VietQR để thanh toán',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
          // QR image
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                _qrUrl(),
                width: double.infinity,
                fit: BoxFit.fitWidth,
                loadingBuilder: (_, child, progress) => progress == null
                    ? child
                    : const SizedBox(
                        height: 200,
                        child: Center(child: CircularProgressIndicator()),
                      ),
                errorBuilder: (_, __, ___) => const SizedBox(
                  height: 160,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(LucideIcons.imageOff, size: 36, color: opsMutedText),
                        SizedBox(height: 8),
                        Text('Không tải được mã QR', style: TextStyle(color: opsMutedText)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Amount row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Số tiền cần chuyển:',
                    style: TextStyle(color: opsMutedText, fontSize: 13)),
                Text(
                  '${amount.toInt().toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]}.')} đ',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    color: opsDark,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, indent: 20, endIndent: 20),
          // Transfer note row with copy button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Nội dung chuyển khoản:',
                          style: TextStyle(color: opsMutedText, fontSize: 12)),
                      const SizedBox(height: 2),
                      Text(
                        transferNote,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                          color: opsDark,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton.icon(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: transferNote));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Đã sao chép nội dung chuyển khoản'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                  icon: const Icon(LucideIcons.copy, size: 14),
                  label: const Text('Sao chép'),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF3B82F6),
                    textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
          // Loading hint
          Container(
            margin: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
            decoration: BoxDecoration(
              color: const Color(0xFFF0FDF4),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFBBF7D0)),
            ),
            child: Row(
              children: const [
                SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Color(0xFF16A34A),
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Đang chờ xác nhận thanh toán… mã mở ô sẽ tự hiện.',
                    style: TextStyle(
                      color: Color(0xFF16A34A),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
