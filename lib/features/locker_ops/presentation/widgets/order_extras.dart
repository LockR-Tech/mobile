import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:smart_laundry_locker/core/config/business_config_provider.dart';
import 'package:smart_laundry_locker/features/locker_ops/data/locker_ops_service.dart';
import 'package:smart_laundry_locker/features/locker_ops/presentation/widgets/ops_widgets.dart';
import 'package:smart_laundry_locker/features/promotions/data/models/promotion_model.dart';
import 'package:smart_laundry_locker/features/promotions/presentation/widgets/promotion_scope_tag.dart';
import 'package:smart_laundry_locker/core/l10n/l10n.dart';

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
///
/// Mã theo tủ chỉ hợp lệ ở đúng [lockerId]; đổi tủ ⇒ kiểm lại mã. Đổi
/// [orderTotal] (vd. số giờ thuê, phí drone) ⇒ tính lại mức giảm theo mã đã áp.
class PromoCodeField extends StatefulWidget {
  const PromoCodeField({
    super.key,
    required this.orderTotal,
    required this.onChanged,
    this.lockerId,
    this.service,
  });

  /// Current order subtotal (VND), used to compute percentage discounts.
  final int orderTotal;

  /// Tủ đặt đơn (đơn drone: tủ gửi) — mã theo tủ chỉ dùng được ở đúng tủ này.
  final int? lockerId;

  final LockerOpsService? service;

  /// Called with the applied discount (VND) and the code (null when cleared).
  final void Function(int discount, String? code) onChanged;

  @override
  State<PromoCodeField> createState() => _PromoCodeFieldState();
}

class _PromoCodeFieldState extends State<PromoCodeField> {
  LockerOpsService? _ownService;
  bool _loading = false;
  String? _appliedCode;
  String? _error;

  /// Khuyến mãi của mã đang áp (để tính lại khi số tiền đơn đổi).
  Map<String, dynamic>? _promotion;

  /// Lần kiểm mã mới nhất — bỏ kết quả của lần cũ về muộn.
  int _request = 0;

  /// Dựng lười: màn mở độc lập (test, chưa init mạng) chỉ lỗi khi thật sự gọi.
  LockerOpsService get _service =>
      widget.service ?? (_ownService ??= LockerOpsService());

  @override
  void didUpdateWidget(covariant PromoCodeField oldWidget) {
    super.didUpdateWidget(oldWidget);
    final code = _appliedCode;
    if (code == null) return;
    if (oldWidget.lockerId != widget.lockerId) {
      // Mã theo tủ có thể không dùng được ở tủ mới ⇒ hỏi lại server.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _apply(code);
      });
      return;
    }
    if (oldWidget.orderTotal != widget.orderTotal) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _recompute();
      });
    }
  }

  /// Tính lại mức giảm của mã đang áp theo số tiền đơn mới.
  void _recompute() {
    final code = _appliedCode;
    if (code == null) return;
    final discount = computePromotionDiscount(_promotion, widget.orderTotal);
    if (discount <= 0) {
      _reject(context.l10n.extrasNotEligible);
      return;
    }
    widget.onChanged(discount, code);
  }

  void _reject(String message) {
    setState(() {
      _error = message;
      _appliedCode = null;
      _promotion = null;
    });
    widget.onChanged(0, null);
  }

  Future<void> _apply(String code) async {
    if (code.isEmpty) return;
    final request = ++_request;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await _service.validatePromotion(
        code,
        lockerId: widget.lockerId,
        orderTotal: widget.orderTotal,
      );
      if (!mounted || request != _request) return;
      final valid = res['valid'] == true;
      final rawPromotion = res['promotion'];
      final promotion = rawPromotion is Map
          ? Map<String, dynamic>.from(rawPromotion)
          : null;
      if (!valid || promotion == null) {
        _reject(
          (res['reason'] as String?) ?? context.l10n.extrasCodeInvalid,
        );
        return;
      }
      final discount = computePromotionDiscount(promotion, widget.orderTotal);
      if (discount <= 0) {
        _reject(context.l10n.extrasNotEligible);
        return;
      }
      setState(() {
        _appliedCode = code;
        _promotion = promotion;
      });
      widget.onChanged(discount, code);
    } catch (e) {
      if (!mounted || request != _request) return;
      _reject(LockerOpsService.errorMessage(e));
    } finally {
      if (mounted && request == _request) setState(() => _loading = false);
    }
  }

  void _clear() {
    _request++;
    setState(() {
      _appliedCode = null;
      _promotion = null;
      _error = null;
      _loading = false;
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
        lockerId: widget.lockerId,
        service: _service,
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
                context.l10n.extrasCodeApplied(_appliedCode!),
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF166534),
                ),
              ),
            ),
            TextButton(
              onPressed: _clear,
              child: Text(context.l10n.commonRemove),
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
                Expanded(
                  child: Text(
                    context.l10n.extrasChooseCode,
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

/// Voucher đã lưu còn dùng được (SAVED / UNUSED; bỏ USED, EXPIRED) từ
/// `GET /api/promotions/vouchers/my`, đổi sang [PromotionModel] để hiện chung với
/// khuyến mãi đang chạy.
List<PromotionModel> usableSavedVouchers(List<Map<String, dynamic>> raw) => raw
    .where((v) {
      final status = '${v['status'] ?? ''}'.toUpperCase();
      return (status == 'SAVED' || status == 'UNUSED') &&
          '${v['code'] ?? ''}'.trim().isNotEmpty;
    })
    .map(PromotionModel.fromJson)
    .toList(growable: false);

/// Gộp voucher đã lưu (lên trước) với khuyến mãi đang chạy, bỏ trùng theo mã.
List<PromotionModel> mergeVoucherOptions(
  List<PromotionModel> saved,
  List<PromotionModel> active,
) {
  final seen = <String>{};
  return [
    for (final p in [...saved, ...active])
      if (seen.add(p.code.toUpperCase())) p,
  ];
}

/// Chỉ giữ mã dùng được ở tủ [lockerId] (mã toàn hệ thống + mã của đúng tủ).
/// Server đã lọc theo `?lockerId=`; lọc lại ở app phòng server cũ trả hết.
List<PromotionModel> vouchersUsableAt(
  List<PromotionModel> options,
  int? lockerId,
) => options.where((p) => p.usableAt(lockerId)).toList(growable: false);

class _VoucherPickerSheet extends StatefulWidget {
  const _VoucherPickerSheet({
    required this.orderTotal,
    required this.service,
    this.currentCode,
    this.lockerId,
  });

  final int orderTotal;
  final String? currentCode;

  /// Tủ đặt đơn — chỉ hiện mã dùng được ở tủ này.
  final int? lockerId;
  final LockerOpsService service;

  @override
  State<_VoucherPickerSheet> createState() => _VoucherPickerSheetState();
}

class _VoucherPickerSheetState extends State<_VoucherPickerSheet> {
  List<PromotionModel>? _promotions;

  /// Mã voucher khách đã lưu — hiện nhãn "Đã lưu".
  Set<String> _savedCodes = const {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    // Hai nguồn độc lập: lỗi nguồn nào thì bỏ nguồn đó, vẫn hiện nguồn còn lại.
    final lockerId = widget.lockerId;
    var active = const <PromotionModel>[];
    var saved = const <PromotionModel>[];
    try {
      active = (await widget.service.activePromotions(lockerId: lockerId))
          .map(PromotionModel.fromJson)
          .toList(growable: false);
    } catch (_) {}
    try {
      saved = usableSavedVouchers(
        await widget.service.myVouchers(lockerId: lockerId),
      );
    } catch (_) {}
    if (!mounted) return;
    setState(() {
      _promotions = vouchersUsableAt(
        mergeVoucherOptions(saved, active),
        lockerId,
      );
      _savedCodes = {for (final v in saved) v.code.toUpperCase()};
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 4),
          child: Text(
            context.l10n.extrasChooseCode,
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
          Padding(
            padding: const EdgeInsets.all(32),
            child: Center(
              child: Text(
                widget.lockerId == null
                    ? context.l10n.extrasNoCodes
                    : context.l10n.extrasNoCodesHere,
                textAlign: TextAlign.center,
                style: const TextStyle(color: opsMutedText),
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
                                Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        p.code,
                                        style: const TextStyle(fontWeight: FontWeight.w800, color: opsDark, fontSize: 15),
                                      ),
                                    ),
                                    if (_savedCodes.contains(p.code.toUpperCase())) ...[
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF16A34A).withValues(alpha: 0.12),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          context.l10n.commonSaved,
                                          style: TextStyle(
                                            fontSize: 10.5,
                                            fontWeight: FontWeight.w700,
                                            color: Color(0xFF15803D),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  p.name,
                                  style: const TextStyle(fontSize: 13, color: opsMutedText),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                PromotionScopeTag(
                                  label: p.scopeLabel,
                                  lockerScoped: p.isLockerScoped,
                                  fontSize: 10.5,
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
    (points: config.tierSilverPoints, name: L10n.current.tierSilver),
    (points: config.tierGoldPoints, name: L10n.current.tierGold),
    (points: config.tierPlatinumPoints, name: L10n.current.tierPlatinum),
  ]..sort((a, b) => a.points.compareTo(b.points));
  for (final tier in tiers) {
    if (points < tier.points) {
      return L10n.current.tierNextPoints(tier.points - points, tier.name);
    }
  }
  return null;
}

/// Nhãn hạng thành viên: ưu tiên `tierLabel` server trả, không có thì đổi từ
/// mã hạng (`BRONZE`/`SILVER`/`GOLD`/`PLATINUM`).
String? loyaltyTierLabel({String? tierLabel, String? tier}) {
  final label = tierLabel?.trim();
  if (label != null && label.isNotEmpty) return label;
  return switch ((tier ?? '').trim().toUpperCase()) {
    'BRONZE' => L10n.current.tierBronze,
    'SILVER' => L10n.current.tierSilver,
    'GOLD' => L10n.current.tierGold,
    'PLATINUM' => L10n.current.tierPlatinum,
    '' => null,
    final other => other,
  };
}

/// "Bạn đang có 120 điểm · hạng Đồng · còn 380 điểm lên hạng Bạc"
/// (hạng cao nhất ⇒ "· hạng cao nhất"). Chỉ dùng số điểm thật của tài khoản.
/// Hạng tính theo tổng điểm đã tích ([lifetimePoints]; server cũ chưa trả thì
/// dùng [points]) — tiêu điểm không làm tụt hạng.
String loyaltyHintText(
  int points,
  String? tierLabel,
  BusinessConfig config, {
  int? lifetimePoints,
}) {
  final next = nextLoyaltyTierText(lifetimePoints ?? points, config);
  return [
    L10n.current.tierYouHavePoints(points),
    if (tierLabel != null && tierLabel.isNotEmpty)
      L10n.current.tierRank(tierLabel),
    next ?? L10n.current.tierHighest,
  ].join(' · ');
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
          label: context.l10n.payStatusPaid,
          icon: LucideIcons.circleCheck,
        );
      case 'PENDING':
      case 'PROCESSING':
        return (
          color: const Color(0xFFCA8A04),
          label: context.l10n.payStatusPending,
          icon: LucideIcons.clock,
        );
      case 'FAILED':
      case 'CANCELED':
        return (
          color: const Color(0xFFDC2626),
          label: context.l10n.payStatusFailed,
          icon: LucideIcons.circleX,
        );
      default:
        return (
          color: opsMutedText,
          label: context.l10n.payStatusNone,
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
