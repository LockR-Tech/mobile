import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:smart_laundry_locker/features/locker_ops/data/locker_ops_service.dart';
import 'package:smart_laundry_locker/features/locker_ops/presentation/widgets/ops_widgets.dart';

/// Kết quả `GET /api/loyalty/redeem-preview?orderTotal=` — server tính theo
/// cấu hình admin (`app.loyalty.redeem-*`):
/// `maxPoints = min(balance, floor(orderTotal × maxPercent / 100 / vndPerPoint))`,
/// dưới `minPoints` hoặc đang tắt ⇒ 0.
class LoyaltyRedeemPreview {
  const LoyaltyRedeemPreview({
    required this.enabled,
    required this.balance,
    required this.vndPerPoint,
    required this.maxPercent,
    required this.minPoints,
    required this.maxPoints,
    required this.maxDiscount,
    required this.orderTotal,
  });

  final bool enabled;

  /// Số điểm hiện có.
  final int balance;

  /// Giá trị 1 điểm khi dùng (VND).
  final int vndPerPoint;

  /// % tối đa số tiền đơn được trả bằng điểm.
  final int maxPercent;

  /// Số điểm tối thiểu mỗi lần dùng.
  final int minPoints;

  /// Số điểm dùng được cho đơn này (0 = không dùng được).
  final int maxPoints;

  /// Số tiền giảm khi dùng [maxPoints] điểm (VND).
  final int maxDiscount;

  /// Số tiền đơn (sau voucher) đã hỏi.
  final int orderTotal;

  factory LoyaltyRedeemPreview.fromJson(
    Map<String, dynamic> json, {
    required int orderTotal,
  }) {
    final enabled = json['enabled'];
    return LoyaltyRedeemPreview(
      enabled: enabled is bool ? enabled : '$enabled'.toLowerCase() == 'true',
      balance: _int(json['balance']),
      vndPerPoint: _int(json['vndPerPoint']),
      maxPercent: _int(json['maxPercent']),
      minPoints: _int(json['minPoints']),
      maxPoints: _int(json['maxPoints']),
      maxDiscount: _int(json['maxDiscount']),
      orderTotal: orderTotal,
    );
  }

  /// Dùng được điểm cho đơn này.
  bool get usable => enabled && maxPoints > 0 && maxDiscount > 0;

  /// Ước tính lại cho số tiền đơn [total] theo đúng công thức server — để giá
  /// tạm tính đổi ngay khi khách đổi giờ thuê / mã giảm giá, trong lúc chờ
  /// hỏi lại server.
  LoyaltyRedeemPreview estimateFor(int total) {
    var points = 0;
    if (enabled && total > 0 && vndPerPoint > 0 && maxPercent > 0) {
      final cap = (total * maxPercent) ~/ (100 * vndPerPoint);
      points = cap < balance ? cap : balance;
      if (points < minPoints || points < 0) points = 0;
    }
    var discount = points * vndPerPoint;
    if (discount > total) discount = total < 0 ? 0 : total;
    return LoyaltyRedeemPreview(
      enabled: enabled,
      balance: balance,
      vndPerPoint: vndPerPoint,
      maxPercent: maxPercent,
      minPoints: minPoints,
      maxPoints: points,
      maxDiscount: discount,
      orderTotal: total,
    );
  }

  /// Vì sao chưa dùng được điểm cho đơn này; `null` khi dùng được.
  String? get unavailableReason {
    if (!enabled) return 'Hiện chưa áp dụng dùng điểm để thanh toán';
    if (orderTotal <= 0) return 'Đơn đã được giảm hết, không cần dùng điểm';
    if (balance <= 0) {
      return 'Bạn chưa có điểm — điểm được cộng khi đơn hoàn tất';
    }
    if (balance < minPoints) {
      return 'Bạn có $balance điểm, cần tối thiểu $minPoints điểm mỗi lần dùng';
    }
    if (!usable) {
      return 'Đơn chưa đủ giá trị để dùng tối thiểu $minPoints điểm';
    }
    return null;
  }

  /// `Dùng 120 điểm · giảm 12.000đ`.
  String get offerText =>
      'Dùng $maxPoints điểm · giảm ${fmtPrice(maxDiscount)}';

  /// `Bạn có 350 điểm · 1 điểm = 100đ, tối đa 50% giá trị đơn`.
  String get ruleText => [
    'Bạn có $balance điểm',
    if (enabled && vndPerPoint > 0)
      '1 điểm = ${fmtPrice(vndPerPoint)}, tối đa $maxPercent% giá trị đơn',
  ].join(' · ');

  static int _int(dynamic raw) {
    if (raw is num) return raw.floor();
    return num.tryParse('${raw ?? ''}')?.floor() ?? 0;
  }
}

/// `-12.000đ (120 điểm)` — dòng "Điểm thưởng" ở hoá đơn tạm và chi tiết đơn.
String loyaltyPointsDiscountText(int points, num discount) =>
    '-${fmtPrice(discount)} ($points điểm)';

int _orderInt(dynamic raw) {
  if (raw is num) return raw.round();
  return num.tryParse('${raw ?? ''}')?.round() ?? 0;
}

/// Số điểm server đã thật sự trừ cho đơn (`pointsUsed`).
int orderPointsUsed(Map<String, dynamic> order) =>
    _orderInt(order['pointsUsed']);

/// Số tiền server đã giảm nhờ điểm (`pointsDiscount`).
int orderPointsDiscount(Map<String, dynamic> order) =>
    _orderInt(order['pointsDiscount']);

/// Khách bật dùng điểm nhưng server không trừ điểm nào (loyalty lỗi/không phản
/// hồi ⇒ server vẫn tạo đơn, tính đủ giá). Server cũ chưa trả `pointsUsed` thì
/// không kết luận gì.
String? loyaltyRedeemSkippedNotice(
  int requestedPoints,
  Map<String, dynamic> order,
) {
  if (requestedPoints <= 0 || !order.containsKey('pointsUsed')) return null;
  if (orderPointsUsed(order) > 0) return null;
  return 'Chưa dùng được điểm thưởng lúc này — đơn được tính đủ giá.';
}

/// Đơn được giảm hết (voucher + điểm) ⇒ server coi như đã thanh toán ngay,
/// không cần mở SePay.
bool orderFullyCovered(Map<String, dynamic> order) {
  final status = '${order['paymentStatus'] ?? ''}'.toUpperCase();
  if (status == 'PAID') return true;
  final total = order['totalPrice'];
  final totalNum = total is num ? total : num.tryParse('${total ?? ''}');
  if (totalNum == null || totalNum > 0) return false;
  final due = order['amountDue'];
  final dueNum = due is num ? due : num.tryParse('${due ?? ''}');
  return dueNum == null || dueNum <= 0;
}

int _orderDiscount(Map<String, dynamic> order) => _orderInt(order['discount']);

/// Đơn server trả có giảm giá (mã hoặc điểm) cần hiện bảng giá chi tiết.
bool orderHasDiscounts(Map<String, dynamic> order) =>
    _orderDiscount(order) > 0 || orderPointsUsed(order) > 0;

/// Bảng giá đơn VỪA TẠO theo số liệu server (giá gốc, mã giảm giá, điểm
/// thưởng, tổng tiền) — app không tự tính lại. Rỗng khi đơn không được giảm.
class OrderDiscountRows extends StatelessWidget {
  const OrderDiscountRows({super.key, required this.order});

  final Map<String, dynamic> order;

  @override
  Widget build(BuildContext context) {
    if (!orderHasDiscounts(order)) return const SizedBox.shrink();
    final original = _orderInt(order['originalPrice']);
    final discount = _orderDiscount(order);
    final code = order['promotionCode']?.toString().trim();
    final points = orderPointsUsed(order);
    return Column(
      children: [
        if (original > 0)
          OpsInfoRow(
            icon: LucideIcons.tag,
            label: 'Giá gốc',
            value: fmtPrice(original),
          ),
        if (discount > 0)
          OpsInfoRow(
            icon: LucideIcons.badgePercent,
            label: 'Giảm giá',
            value: code == null || code.isEmpty
                ? '-${fmtPrice(discount)}'
                : '-${fmtPrice(discount)} ($code)',
            valueColor: const Color(0xFF15803D),
          ),
        if (points > 0)
          OpsInfoRow(
            icon: LucideIcons.sparkles,
            label: 'Điểm thưởng',
            value: loyaltyPointsDiscountText(
              points,
              orderPointsDiscount(order),
            ),
            valueColor: const Color(0xFF15803D),
          ),
        OpsInfoRow(
          icon: LucideIcons.wallet,
          label: 'Tổng tiền',
          value: fmtPrice(order['totalPrice']),
          valueColor: opsDark,
        ),
      ],
    );
  }
}

/// Công tắc "Dùng điểm thưởng" ở trang thanh toán (gửi hàng, thuê ô, drone).
///
/// Hỏi `redeem-preview` theo [orderTotal] (số tiền SAU voucher; hỏi lại sau
/// [debounce] mỗi khi số tiền đổi) và báo cho trang cha số điểm sẽ gửi
/// (`pointsToUse`) cùng số tiền giảm ước tính. Server vẫn là nơi quyết định:
/// sau khi tạo đơn, trang cha hiện `totalPrice`/`amountDue` server trả.
/// Không tải được điểm (máy chủ cũ, mất mạng) ⇒ ẩn, đơn tính đủ giá.
class LoyaltyRedeemToggle extends StatefulWidget {
  const LoyaltyRedeemToggle({
    super.key,
    required this.orderTotal,
    required this.onChanged,
    this.service,
    this.debounce = const Duration(milliseconds: 400),
  });

  /// Số tiền đơn sau voucher (VND).
  final int orderTotal;

  /// Gọi với (số điểm dùng, số tiền giảm); (0, 0) khi tắt / không dùng được.
  final void Function(int points, int discount) onChanged;

  final LockerOpsService? service;
  final Duration debounce;

  @override
  State<LoyaltyRedeemToggle> createState() => _LoyaltyRedeemToggleState();
}

class _LoyaltyRedeemToggleState extends State<LoyaltyRedeemToggle> {
  LockerOpsService? _ownService;
  LoyaltyRedeemPreview? _preview;
  bool _loading = true;
  bool _on = false;
  Timer? _debounce;
  int _request = 0;
  int _reportedPoints = 0;
  int _reportedDiscount = 0;

  @override
  void initState() {
    super.initState();
    _load(widget.orderTotal);
  }

  @override
  void didUpdateWidget(covariant LoyaltyRedeemToggle oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.orderTotal == widget.orderTotal) return;
    final total = widget.orderTotal;
    // Giá tạm tính đổi ngay theo công thức server, rồi mới hỏi lại server.
    final preview = _preview;
    if (preview != null) {
      _preview = preview.estimateFor(total);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _report();
      });
    }
    _debounce?.cancel();
    _debounce = Timer(widget.debounce, () => _load(total));
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _load(int total) async {
    final request = ++_request;
    if (!_loading && mounted) setState(() => _loading = true);
    try {
      // Dựng service trong try: màn mở độc lập (test, web chưa init mạng) thì
      // chỉ ẩn công tắc.
      final service = widget.service ?? (_ownService ??= LockerOpsService());
      final json = await service.loyaltyRedeemPreview(total);
      if (!mounted || request != _request) return;
      if (json.isEmpty) throw const FormatException('empty redeem preview');
      setState(() {
        _preview = LoyaltyRedeemPreview.fromJson(json, orderTotal: total);
        _loading = false;
      });
    } catch (_) {
      if (!mounted || request != _request) return;
      // Giữ ước tính cũ nếu đã có; chưa có thì ẩn công tắc.
      setState(() => _loading = false);
    }
    _report();
  }

  void _report() {
    final preview = _preview;
    final use = _on && preview != null && preview.usable;
    final points = use ? preview.maxPoints : 0;
    final discount = use ? preview.maxDiscount : 0;
    if (points == _reportedPoints && discount == _reportedDiscount) return;
    _reportedPoints = points;
    _reportedDiscount = discount;
    widget.onChanged(points, discount);
  }

  void _toggle(bool value) {
    setState(() => _on = value);
    _report();
  }

  @override
  Widget build(BuildContext context) {
    final preview = _preview;
    if (preview == null) {
      // Chưa có số liệu (đang tải lần đầu hoặc máy chủ chưa hỗ trợ): không
      // đoán số điểm — chỉ ghi chú tĩnh, không vòng quay.
      return Text(
        _loading
            ? 'Đang kiểm tra điểm thưởng...'
            : 'Chưa tải được điểm thưởng — đơn được tính đủ giá.',
        style: const TextStyle(fontSize: 12.5, color: opsMutedText),
      );
    }
    final usable = preview.usable;
    final active = _on && usable;
    final reason = preview.unavailableReason;
    return Container(
      key: const ValueKey('loyalty-redeem'),
      padding: const EdgeInsets.fromLTRB(14, 10, 6, 10),
      decoration: BoxDecoration(
        color: active
            ? const Color(0xFFFACC15).withValues(alpha: 0.10)
            : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: active
              ? const Color(0xFFCA8A04).withValues(alpha: 0.5)
              : opsBorder,
        ),
      ),
      child: Row(
        children: [
          Icon(
            LucideIcons.sparkles,
            size: 18,
            color: usable ? const Color(0xFFCA8A04) : opsMutedText,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Dùng điểm thưởng',
                  style: TextStyle(
                    color: opsDark,
                    fontWeight: FontWeight.w700,
                    fontSize: 14.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  reason ?? preview.offerText,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: reason == null
                        ? const Color(0xFF15803D)
                        : opsMutedText,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  preview.ruleText,
                  style: const TextStyle(fontSize: 11.5, color: opsMutedText),
                ),
              ],
            ),
          ),
          if (_loading)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 6),
              child: SizedBox(
                width: 12,
                height: 12,
                child: CircularProgressIndicator(
                  strokeWidth: 1.6,
                  color: opsPrimary,
                ),
              ),
            ),
          Switch(
            key: const ValueKey('loyalty-redeem-switch'),
            value: active,
            activeTrackColor: opsPrimary,
            onChanged: usable ? _toggle : null,
          ),
        ],
      ),
    );
  }
}
