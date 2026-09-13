import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Convenience extension so widgets can do `context.isDark`, `context.cardBg` etc.
extension AislTheme on BuildContext {
  bool get isDark => Theme.of(this).brightness == Brightness.dark;

  Color get pageBg =>
      isDark ? const Color(0xFF061A30) : const Color(0xFFF8FAFC);
  Color get cardBg => isDark ? const Color(0xFF0A2342) : Colors.white;
  Color get surfaceBg =>
      isDark ? const Color(0xFF0D2B4A) : const Color(0xFFF0F4F8);
  Color get textPrimary =>
      isDark ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A);
  Color get textMuted =>
      isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
  Color get dividerColor =>
      isDark ? const Color(0xFF1E3A5F) : const Color(0xFFF1F5F9);
  Color get borderColor =>
      isDark ? const Color(0xFF1E4976) : const Color(0xFFE2E8F0);
}

/// Brand palette + shared building blocks ported from the legacy React Native
/// customer app (`laundry-locker-frontend/mobile`) so the Flutter user screens
/// share its polished navy / soft-gradient look.
///
/// This intentionally lives next to the existing `AISLShadcnTheme`: the shadcn
/// theme drives the global Material/shadcn widgets, while [AislBrand] captures
/// the legacy customer-app visual language (gradients, chips, cards, badges).
class AislBrand {
  AislBrand._();

  // Core brand colours (legacy RN app).
  static const Color navy = Color(0xFF003D5B);
  static const Color blue = Color(0xFF0077B6);
  static const Color cyan = Color(0xFF00B4D8);

  /// Avatar border / prominent accents gradient.
  static const List<Color> brandGradient = <Color>[navy, blue, cyan];

  /// Soft header / welcome-card gradient (white -> light blue).
  static const List<Color> softHeaderGradient = <Color>[
    Color(0xFFFFFFFF),
    Color(0xFFF0F8FF),
    Color(0xFFD6E9F5),
  ];

  // Text + surface tokens.
  static const Color textTitle = Color(0xFF1A202C);
  static const Color textBody = Color(0xFF4A5568);
  static const Color textMuted = Color(0xFF718096);
  static const Color cardBorder = Color(0xFFF0F4F8);
  static const Color chipBorder = Color(0xFFE2E8F0);
  static const Color surface = Color(0xFFF0F4F8);
  static const Color pageBackground = Color(0xFFFFFFFF);

  // Status / accent tokens.
  static const Color badgeRed = Color(0xFFFF3B30);
  static const Color statusGreen = Color(0xFF48BB78);
  static const Color statusGreenText = Color(0xFF2F855A);

  // Floating bottom navigation bar.
  static const Color navBar = navy;
  static const Color navInactive = Color(0xFFB0C4DE);
  static const Color navIndicator = Color(0xFF90D4EA);

  /// Up-to-two-letter initials used as an avatar fallback.
  static String initials(String? name) {
    final parts = (name ?? '')
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.isEmpty) return 'U';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    final a = parts[parts.length - 2].substring(0, 1);
    final b = parts.last.substring(0, 1);
    return (a + b).toUpperCase();
  }
}

/// Circular avatar with the brand gradient ring (falls back to initials).
class BrandAvatar extends StatelessWidget {
  const BrandAvatar({
    super.key,
    this.imageUrl,
    this.name,
    this.size = 52,
    this.borderWidth = 3,
  });

  final String? imageUrl;
  final String? name;
  final double size;
  final double borderWidth;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size + borderWidth * 2 + 4,
      height: size + borderWidth * 2 + 4,
      padding: EdgeInsets.all(borderWidth),
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: AislBrand.brandGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(2),
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
        ),
        child: ClipOval(
          child: (imageUrl != null && imageUrl!.isNotEmpty)
              ? CachedNetworkImage(
                  imageUrl: imageUrl!,
                  width: size,
                  height: size,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => _fallback(),
                  errorWidget: (_, __, ___) => _fallback(),
                )
              : _fallback(),
        ),
      ),
    );
  }

  Widget _fallback() {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      color: AislBrand.navy.withValues(alpha: 0.10),
      child: Text(
        AislBrand.initials(name),
        style: TextStyle(
          color: AislBrand.navy,
          fontWeight: FontWeight.w800,
          fontSize: size * 0.36,
        ),
      ),
    );
  }
}

/// Circular icon button (white by default) used in hero headers and as
/// floating actions over images (back button, favourite heart, etc.).
class BrandCircleIconButton extends StatelessWidget {
  const BrandCircleIconButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.iconColor = AislBrand.navy,
    this.background = Colors.white,
    this.size = 40,
    this.iconSize = 22,
  });

  final IconData icon;
  final VoidCallback onTap;
  final Color iconColor;
  final Color background;
  final double size;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: background,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.10),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(icon, size: iconSize, color: iconColor),
      ),
    );
  }
}

/// Soft-gradient hero header with rounded bottom corners, an optional back
/// button and an optional trailing action. Used at the top of the user
/// screens in place of a plain [AppBar].
class BrandHeroHeader extends StatelessWidget {
  const BrandHeroHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.onBack,
    this.trailing,
  });

  final String title;
  final String? subtitle;
  final VoidCallback? onBack;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final gradientColors = isDark
        ? const <Color>[Color(0xFF061A30), Color(0xFF0A2342), Color(0xFF0D2B4A)]
        : AislBrand.softHeaderGradient;
    final titleColor = isDark ? const Color(0xFFF1F5F9) : AislBrand.navy;
    final subtitleColor = isDark
        ? const Color(0xFF94A3B8)
        : AislBrand.navy.withValues(alpha: 0.8);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(30)),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? const Color(0xFF000000).withValues(alpha: 0.4)
                : const Color(0x1A000000),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 22),
          child: Row(
            children: [
              if (onBack != null) ...[
                BrandCircleIconButton(
                  icon: Icons.arrow_back,
                  onTap: onBack!,
                  size: 40,
                ),
                const SizedBox(width: 14),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: titleColor,
                        letterSpacing: -0.5,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: subtitleColor,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
        ),
      ),
    );
  }
}

/// Section header: rounded icon tile + title + optional "see all" link.
class BrandSectionHeader extends StatelessWidget {
  const BrandSectionHeader({
    super.key,
    required this.icon,
    required this.title,
    this.onSeeAll,
    this.seeAllLabel = 'XEM TẤT CẢ',
    this.highlightColor,
    this.highlightRollColor,
  });

  final IconData icon;
  final String title;
  final VoidCallback? onSeeAll;
  final String seeAllLabel;

  /// Màu thân banner (bật chế độ highlight giống "Đang thịnh hành" Threads)
  final Color? highlightColor;

  /// Màu phần cuộn 3D bên phải (mặc định tự tối hơn highlightColor nếu null)
  final Color? highlightRollColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (highlightColor == null) ...[
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AislBrand.surface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 18, color: AislBrand.navy),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AislBrand.textTitle,
              ),
            ),
          ),
        ] else ...[
          _HighlightBanner(
            color: highlightColor!,
            rollColor:
                highlightRollColor ??
                Color.lerp(highlightColor!, Colors.black, 0.30)!,
            title: title,
          ),
          const Spacer(),
        ],
        if (onSeeAll != null)
          GestureDetector(
            onTap: onSeeAll,
            behavior: HitTestBehavior.opaque,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  seeAllLabel,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AislBrand.navy,
                  ),
                ),
                const Icon(
                  Icons.chevron_right,
                  size: 16,
                  color: AislBrand.navy,
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// White pill quick-filter chip with leading icon.
class BrandFilterChip extends StatelessWidget {
  const BrandFilterChip({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: context.cardBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: context.borderColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: AislBrand.navy),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: context.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Small rounded status pill (e.g. "Hoạt động" with a colored dot).
class BrandStatusBadge extends StatelessWidget {
  const BrandStatusBadge({
    super.key,
    required this.label,
    this.dotColor = AislBrand.statusGreen,
    this.textColor = AislBrand.statusGreenText,
  });

  final String label;
  final Color dotColor;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Highlight banner widget (Threads "Đang thịnh hành" style) ───────────────

class _HighlightBanner extends StatelessWidget {
  // color/rollColor kept for API compatibility but SVG asset is used for visuals
  final Color color;
  final Color rollColor;
  final String title;

  const _HighlightBanner({
    required this.color,
    required this.rollColor,
    required this.title,
  });

  static const _textStyle = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w800,
    color: Color.fromARGB(255, 229, 255, 133),
    letterSpacing: 0.3,
  );

  // SVG roll element occupies the rightmost ~7% of banner width.
  // bannerWidth = (leftPad + textWidth) / 0.93  → roll fills remainder automatically.
  static const double _leftPad = 14.0;
  static const double _rollFraction = 0.07;

  @override
  Widget build(BuildContext context) {
    final textScaler = MediaQuery.textScalerOf(context);
    final tp = TextPainter(
      text: TextSpan(text: title, style: _textStyle),
      textDirection: TextDirection.ltr,
      textScaler: textScaler,
      maxLines: 1,
    )..layout();

    final bannerWidth = (_leftPad + tp.width) / (1 - _rollFraction);
    final rightPad = bannerWidth - _leftPad - tp.width;

    return SizedBox(
      width: bannerWidth,
      height: 30,
      child: Stack(
        fit: StackFit.expand,
        children: [
          SvgPicture.asset(
            'assets/images/banner_highlight.svg',
            fit: BoxFit.fill,
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(_leftPad, 0, rightPad, 0),
            child: Center(
              child: Text(title, softWrap: false, style: _textStyle),
            ),
          ),
        ],
      ),
    );
  }
}
