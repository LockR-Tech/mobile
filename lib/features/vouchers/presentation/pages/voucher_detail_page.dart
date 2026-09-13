import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:smart_laundry_locker/shared/widgets/user_ui_kit.dart';
import '../../data/models/voucher_model.dart';

class VoucherDetailPage extends StatelessWidget {
  const VoucherDetailPage({super.key, required this.voucher});

  final VoucherModel voucher;

  bool get _isActive => voucher.status == 'UNUSED';
  bool get _isExpired => voucher.status == 'EXPIRED';

  Color get _accentColor => _isActive ? AislBrand.navy : Colors.grey.shade500;

  String get _rewardText {
    final fmt = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
    return switch (voucher.rewardType) {
      'DISCOUNT_FIXED' => 'Giảm ${fmt.format(voucher.rewardValue)}',
      'DISCOUNT_PERCENT' => 'Giảm ${voucher.rewardValue.toInt()}%',
      _ => 'Quà tặng',
    };
  }

  String get _statusLabel => switch (voucher.status) {
    'UNUSED' => 'Khả dụng',
    'USED' => 'Đã sử dụng',
    'EXPIRED' => 'Hết hạn',
    _ => voucher.status,
  };

  Color get _statusBg => switch (voucher.status) {
    'UNUSED' => const Color(0xFFDCFCE7),
    'USED' => const Color(0xFFF1F5F9),
    'EXPIRED' => const Color(0xFFFEE2E2),
    _ => const Color(0xFFF1F5F9),
  };

  Color get _statusFg => switch (voucher.status) {
    'UNUSED' => const Color(0xFF166534),
    'USED' => Colors.grey,
    'EXPIRED' => const Color(0xFF991B1B),
    _ => Colors.grey,
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Column(
        children: [
          BrandHeroHeader(
            title: 'Chi tiết ưu đãi',
            subtitle: voucher.campaignTitle,
            onBack: () => context.pop(),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _TicketCard(voucher: voucher, accentColor: _accentColor),
                  const SizedBox(height: 20),
                  _CodeSection(
                    code: voucher.code,
                    isActive: _isActive,
                    accentColor: _accentColor,
                  ),
                  const SizedBox(height: 20),
                  _InfoSection(
                    rewardText: _rewardText,
                    statusLabel: _statusLabel,
                    statusBg: _statusBg,
                    statusFg: _statusFg,
                    voucher: voucher,
                    accentColor: _accentColor,
                  ),
                  if (voucher.giftDescription.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _DescriptionCard(description: voucher.giftDescription),
                  ],
                  const SizedBox(height: 20),
                  _HowToUseCard(isActive: _isActive, isExpired: _isExpired),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Ticket visual card ──────────────────────────────────────────────────────

class _TicketCard extends StatelessWidget {
  const _TicketCard({required this.voucher, required this.accentColor});
  final VoucherModel voucher;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    final isGift = voucher.rewardType == 'GIFT';
    final isPercent = voucher.rewardType == 'DISCOUNT_PERCENT';
    final fmt = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

    return Container(
      height: 140,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: 0.18),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Row(
          children: [
            // Left color stub
            Container(
              width: 110,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: voucher.status == 'UNUSED'
                      ? AislBrand.brandGradient
                      : [Colors.grey.shade400, Colors.grey.shade300],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isGift ? LucideIcons.gift : LucideIcons.ticketPercent,
                    color: Colors.white,
                    size: 36,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isGift ? 'QUÀ TẶNG' : 'GIẢM GIÁ',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ),
            // Notch separator
            _NotchDivider(color: accentColor),
            // Right content
            Expanded(
              child: Container(
                color: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      voucher.campaignTitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      isGift
                          ? 'Quà tặng'
                          : isPercent
                              ? 'Giảm ${voucher.rewardValue.toInt()}%'
                              : 'Giảm ${fmt.format(voucher.rewardValue)}',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        color: voucher.status == 'UNUSED'
                            ? AislBrand.navy
                            : Colors.grey.shade400,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (voucher.expiresAt != null)
                      Row(
                        children: [
                          Icon(LucideIcons.clock, size: 12, color: Colors.grey.shade400),
                          const SizedBox(width: 4),
                          Text(
                            'HSD: ${DateFormat('dd/MM/yyyy').format(voucher.expiresAt!)}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      )
                    else
                      Text(
                        'Không giới hạn thời gian',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotchDivider extends StatelessWidget {
  const _NotchDivider({required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 20,
      child: CustomPaint(
        painter: _NotchPainter(),
      ),
    );
  }
}

class _NotchPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0xFFF8FAFC);
    // Top semicircle notch
    canvas.drawCircle(
      Offset(size.width / 2, 0),
      size.width * 0.6,
      paint,
    );
    // Bottom semicircle notch
    canvas.drawCircle(
      Offset(size.width / 2, size.height),
      size.width * 0.6,
      paint,
    );
    // Dashed center line
    final linePaint = Paint()
      ..color = const Color(0xFFE2E8F0)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    const dashHeight = 6.0;
    const dashSpace = 4.0;
    double startY = size.width * 0.6;
    while (startY < size.height - size.width * 0.6) {
      canvas.drawLine(
        Offset(size.width / 2, startY),
        Offset(size.width / 2, startY + dashHeight),
        linePaint,
      );
      startY += dashHeight + dashSpace;
    }
    // White fill for full area
    final bgPaint = Paint()..color = Colors.white;
    final rect = Rect.fromLTWH(0, size.width * 0.6, size.width,
        size.height - size.width * 1.2);
    canvas.drawRect(rect, bgPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ── Code section ────────────────────────────────────────────────────────────

class _CodeSection extends StatelessWidget {
  const _CodeSection({
    required this.code,
    required this.isActive,
    required this.accentColor,
  });
  final String code;
  final bool isActive;
  final Color accentColor;

  void _copy(BuildContext context) {
    Clipboard.setData(ClipboardData(text: code));
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text('Đã sao chép mã voucher'),
          duration: Duration(seconds: 2),
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
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Mã voucher',
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
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: isActive
                        ? AislBrand.navy.withValues(alpha: 0.05)
                        : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isActive
                          ? AislBrand.navy.withValues(alpha: 0.2)
                          : const Color(0xFFE2E8F0),
                    ),
                  ),
                  child: Text(
                    code,
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 2,
                      color: isActive ? AislBrand.navy : Colors.grey,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              if (isActive) ...[
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
                    child: const Icon(
                      LucideIcons.copy,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ],
          ),
          if (isActive) ...[
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
        ],
      ),
    );
  }
}

// ── Info section ────────────────────────────────────────────────────────────

class _InfoSection extends StatelessWidget {
  const _InfoSection({
    required this.rewardText,
    required this.statusLabel,
    required this.statusBg,
    required this.statusFg,
    required this.voucher,
    required this.accentColor,
  });
  final String rewardText;
  final String statusLabel;
  final Color statusBg;
  final Color statusFg;
  final VoucherModel voucher;
  final Color accentColor;

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
        children: [
          _InfoRow(
            icon: LucideIcons.gift,
            label: 'Ưu đãi',
            value: rewardText,
            valueColor: accentColor,
          ),
          const _Divider(),
          _InfoRow(
            icon: LucideIcons.tag,
            label: 'Chiến dịch',
            value: voucher.campaignTitle,
          ),
          const _Divider(),
          _InfoRow(
            icon: LucideIcons.checkCircle,
            label: 'Trạng thái',
            valueWidget: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: statusBg,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                statusLabel,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: statusFg,
                ),
              ),
            ),
          ),
          if (voucher.expiresAt != null) ...[
            const _Divider(),
            _InfoRow(
              icon: LucideIcons.calendarX,
              label: 'Hạn sử dụng',
              value: DateFormat('HH:mm dd/MM/yyyy').format(voucher.expiresAt!),
              valueColor: voucher.status == 'EXPIRED'
                  ? const Color(0xFF991B1B)
                  : Colors.black87,
            ),
          ],
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
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
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: AislBrand.textMuted,
            ),
          ),
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
                maxLines: 2,
              ),
            ),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return const Divider(height: 1, color: Color(0xFFF1F5F9));
  }
}

// ── Description card ─────────────────────────────────────────────────────────

class _DescriptionCard extends StatelessWidget {
  const _DescriptionCard({required this.description});
  final String description;

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
          Icon(LucideIcons.info, size: 16, color: AislBrand.navy),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              description,
              style: const TextStyle(
                fontSize: 13,
                color: AislBrand.navy,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── How-to-use card ──────────────────────────────────────────────────────────

class _HowToUseCard extends StatelessWidget {
  const _HowToUseCard({required this.isActive, required this.isExpired});
  final bool isActive;
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
          Row(
            children: [
              Icon(LucideIcons.bookOpen, size: 16, color: AislBrand.navy),
              const SizedBox(width: 8),
              const Text(
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
          if (!isActive)
            Text(
              isExpired
                  ? 'Voucher này đã hết hạn và không thể sử dụng.'
                  : 'Voucher này đã được sử dụng.',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
            )
          else ...[
            _Step(
              step: '1',
              text: 'Sao chép mã voucher ở trên',
            ),
            const SizedBox(height: 8),
            _Step(
              step: '2',
              text: 'Vào trang đặt dịch vụ (Thuê tủ / Gửi hàng)',
            ),
            const SizedBox(height: 8),
            _Step(
              step: '3',
              text: 'Nhập mã vào ô "Mã giảm giá" và nhấn Áp dụng',
            ),
            const SizedBox(height: 8),
            _Step(
              step: '4',
              text: 'Mức giảm sẽ được trừ vào tổng tiền thanh toán',
            ),
          ],
        ],
      ),
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({required this.step, required this.text});
  final String step;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 22,
          height: 22,
          decoration: const BoxDecoration(
            color: AislBrand.navy,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(
            step,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 13,
              color: AislBrand.textBody,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}
