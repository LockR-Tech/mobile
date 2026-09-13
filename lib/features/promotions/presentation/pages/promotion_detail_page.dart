import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:smart_laundry_locker/features/promotions/data/models/promotion_model.dart';
import 'package:smart_laundry_locker/shared/widgets/user_ui_kit.dart';

class PromotionDetailPage extends StatelessWidget {
  const PromotionDetailPage({super.key, required this.promo});

  final PromotionModel promo;

  static const _gradients = [
    [Color(0xFF003D5B), Color(0xFF0077B6)],
    [Color(0xFF7C3AED), Color(0xFF8B5CF6)],
    [Color(0xFF059669), Color(0xFF10B981)],
    [Color(0xFFD97706), Color(0xFFF59E0B)],
    [Color(0xFFE53E3E), Color(0xFFFC8181)],
    [Color(0xFF0F172A), Color(0xFF334155)],
  ];

  List<Color> get _colors => _gradients[promo.id % _gradients.length];

  String get _rewardText {
    final fmt = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
    return promo.discountType == 'PERCENTAGE'
        ? 'Giảm ${promo.discountValue.toInt()}%'
        : 'Giảm ${fmt.format(promo.discountValue)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Column(
        children: [
          BrandHeroHeader(
            title: 'Chi tiết ưu đãi',
            subtitle: promo.name,
            onBack: () => Navigator.of(context).pop(),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _ImageBanner(promo: promo, colors: _colors),
                  const SizedBox(height: 20),
                  _TicketBanner(promo: promo, rewardText: _rewardText),
                  const SizedBox(height: 20),
                  _CodeSection(code: promo.code),
                  const SizedBox(height: 20),
                  _InfoSection(promo: promo, rewardText: _rewardText),
                  if (promo.description != null &&
                      promo.description!.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _DescCard(text: promo.description!),
                  ],
                  const SizedBox(height: 20),
                  _HowToUse(isExpired: promo.isExpired),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Image banner ──────────────────────────────────────────────────────────────

class _ImageBanner extends StatelessWidget {
  const _ImageBanner({required this.promo, required this.colors});
  final PromotionModel promo;
  final List<Color> colors;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: SizedBox(
        height: 180,
        child: Stack(
          fit: StackFit.expand,
          children: [
            CachedNetworkImage(
              imageUrl: promo.effectiveImageUrl,
              fit: BoxFit.cover,
              placeholder: (_, __) => DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: colors,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
              errorWidget: (_, __, ___) => DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: colors,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: const Center(
                  child: Icon(LucideIcons.ticket, size: 52, color: Colors.white30),
                ),
              ),
            ),
            // Dark overlay for legibility
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black.withValues(alpha: 0.55)],
                ),
              ),
            ),
            // Flash Sale chip
            Positioned(
              top: 12,
              left: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFFF97316),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(LucideIcons.zap, size: 12, color: Colors.white),
                    SizedBox(width: 4),
                    Text(
                      'Flash Sale',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Discount badge
            Positioned(
              bottom: 12,
              left: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFE53E3E),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  promo.discountLabel,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
            // Title bottom-right area
            Positioned(
              bottom: 12,
              right: 12,
              left: 100,
              child: Text(
                promo.name,
                textAlign: TextAlign.right,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                  shadows: [Shadow(blurRadius: 8, color: Colors.black54)],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Reward ticket banner ──────────────────────────────────────────────────────

class _TicketBanner extends StatelessWidget {
  const _TicketBanner({required this.promo, required this.rewardText});
  final PromotionModel promo;
  final String rewardText;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: promo.isExpired
              ? [Colors.grey.shade400, Colors.grey.shade300]
              : AislBrand.brandGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: (promo.isExpired ? Colors.grey : AislBrand.navy)
                .withValues(alpha: 0.25),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(LucideIcons.ticketPercent,
                color: Colors.white, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  rewardText,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  promo.isExpired
                      ? 'Ưu đãi đã hết hạn'
                      : promo.expiryLabel == 'Không giới hạn'
                          ? 'Không giới hạn thời gian'
                          : promo.expiryLabel,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withValues(alpha: 0.85),
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

// ── Code section ──────────────────────────────────────────────────────────────

class _CodeSection extends StatelessWidget {
  const _CodeSection({required this.code});
  final String code;

  void _copy(BuildContext context) {
    Clipboard.setData(ClipboardData(text: code));
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(LucideIcons.check, color: Colors.white, size: 16),
              const SizedBox(width: 8),
              Text('Đã sao chép: $code'),
            ],
          ),
          backgroundColor: AislBrand.navy,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          duration: const Duration(seconds: 2),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Mã khuyến mãi',
            style: TextStyle(
              fontSize: 12,
              color: AislBrand.textMuted,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: AislBrand.navy.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: AislBrand.navy.withValues(alpha: 0.2)),
                  ),
                  child: Text(
                    code,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 2,
                      color: AislBrand.navy,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: () => _copy(context),
                child: Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: AislBrand.navy,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(LucideIcons.copy,
                      color: Colors.white, size: 20),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: () => _copy(context),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(LucideIcons.copy, size: 13, color: AislBrand.blue),
                const SizedBox(width: 4),
                Text(
                  'Chạm để sao chép mã',
                  style: TextStyle(
                    fontSize: 12,
                    color: AislBrand.blue,
                    fontWeight: FontWeight.w600,
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

// ── Info section ──────────────────────────────────────────────────────────────

class _InfoSection extends StatelessWidget {
  const _InfoSection({required this.promo, required this.rewardText});
  final PromotionModel promo;
  final String rewardText;

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          _Row(
            icon: LucideIcons.gift,
            label: 'Mức giảm',
            value: rewardText,
            valueColor: AislBrand.navy,
          ),
          if (promo.maxDiscountAmount != null &&
              promo.maxDiscountAmount! > 0) ...[
            const _Div(),
            _Row(
              icon: LucideIcons.arrowDownToLine,
              label: 'Giảm tối đa',
              value: fmt.format(promo.maxDiscountAmount),
            ),
          ],
          if (promo.minOrderAmount != null &&
              promo.minOrderAmount! > 0) ...[
            const _Div(),
            _Row(
              icon: LucideIcons.shoppingCart,
              label: 'Đơn tối thiểu',
              value: fmt.format(promo.minOrderAmount),
            ),
          ],
          if (promo.startAt != null) ...[
            const _Div(),
            _Row(
              icon: LucideIcons.calendarCheck,
              label: 'Bắt đầu',
              value: DateFormat('dd/MM/yyyy HH:mm').format(promo.startAt!),
            ),
          ],
          if (promo.endAt != null) ...[
            const _Div(),
            _Row(
              icon: LucideIcons.calendarX,
              label: 'Kết thúc',
              value: DateFormat('dd/MM/yyyy HH:mm').format(promo.endAt!),
              valueColor: promo.isExpired ? const Color(0xFF991B1B) : null,
            ),
          ],
          const _Div(),
          _Row(
            icon: LucideIcons.checkCircle,
            label: 'Trạng thái',
            valueWidget: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: promo.isExpired
                    ? const Color(0xFFFEE2E2)
                    : const Color(0xFFDCFCE7),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                promo.isExpired ? 'Hết hạn' : 'Đang hiệu lực',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: promo.isExpired
                      ? const Color(0xFF991B1B)
                      : const Color(0xFF166534),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.icon,
    required this.label,
    this.value,
    this.valueColor,
    this.valueWidget,
  });
  final IconData icon;
  final String label;
  final String? value;
  final Color? valueColor;
  final Widget? valueWidget;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AislBrand.textMuted),
          const SizedBox(width: 10),
          Text(label,
              style: const TextStyle(fontSize: 13, color: AislBrand.textMuted)),
          const Spacer(),
          if (valueWidget != null)
            valueWidget!
          else
            Flexible(
              child: Text(
                value ?? '',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: valueColor ?? AislBrand.textTitle,
                ),
                textAlign: TextAlign.right,
              ),
            ),
        ],
      ),
    );
  }
}

class _Div extends StatelessWidget {
  const _Div();
  @override
  Widget build(BuildContext context) =>
      const Divider(height: 1, color: Color(0xFFF1F5F9));
}

// ── Description card ──────────────────────────────────────────────────────────

class _DescCard extends StatelessWidget {
  const _DescCard({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AislBrand.navy.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AislBrand.navy.withValues(alpha: 0.12)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(LucideIcons.info, size: 16, color: AislBrand.navy),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                  fontSize: 13, color: AislBrand.navy, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}

// ── How to use ────────────────────────────────────────────────────────────────

class _HowToUse extends StatelessWidget {
  const _HowToUse({required this.isExpired});
  final bool isExpired;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(LucideIcons.bookOpen, size: 16, color: AislBrand.navy),
              SizedBox(width: 8),
              Text(
                'Cách sử dụng',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: AislBrand.textTitle,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (isExpired)
            Text(
              'Ưu đãi này đã hết hạn và không thể sử dụng.',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
            )
          else ...[
            _step('1', 'Sao chép mã khuyến mãi ở trên'),
            const SizedBox(height: 8),
            _step('2', 'Vào trang đặt dịch vụ (Thuê tủ / Gửi hàng)'),
            const SizedBox(height: 8),
            _step('3', 'Nhập mã vào ô "Mã giảm giá" và nhấn Áp dụng'),
            const SizedBox(height: 8),
            _step('4', 'Mức giảm sẽ được trừ vào tổng tiền thanh toán'),
          ],
        ],
      ),
    );
  }

  Widget _step(String n, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 22,
          height: 22,
          decoration: const BoxDecoration(
              color: AislBrand.navy, shape: BoxShape.circle),
          alignment: Alignment.center,
          child: Text(n,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w800)),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(text,
              style: const TextStyle(
                  fontSize: 13, color: AislBrand.textBody, height: 1.4)),
        ),
      ],
    );
  }
}
