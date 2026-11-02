import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:smart_laundry_locker/shared/widgets/app_lottie.dart';
import 'package:smart_laundry_locker/core/l10n/l10n.dart';

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

/// Nút tròn một icon. Đặt trong [BrandHeroHeader] thì tự lấy màu của header
/// (nền trắng, icon navy — hoặc tông tối khi bật dark mode); nơi khác giữ kiểu
/// kính tối của thẻ hero trang chủ.
class BrandCircleIconButton extends StatelessWidget {
  const BrandCircleIconButton({
    super.key,
    this.icon,
    this.child,
    required this.onTap,
    this.iconColor,
    this.background,
    this.size = 40,
    this.iconSize = 20,
  }) : assert(icon != null || child != null);

  final IconData? icon;
  final Widget? child;
  final VoidCallback onTap;
  final Color? iconColor;
  final Color? background;
  final double size;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final hero = BrandHeroColors.maybeOf(context);
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: background ?? hero?.buttonBg ?? Colors.white.withValues(alpha: 0.12),
          shape: BoxShape.circle,
          border: Border.all(
            color: hero?.buttonBorder ?? Colors.white.withValues(alpha: 0.18),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: hero?.buttonShadow ?? Colors.black.withValues(alpha: 0.15),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: child ??
              Icon(icon!, size: iconSize, color: iconColor ?? hero?.buttonFg ?? Colors.white),
        ),
      ),
    );
  }
}

/// Hình minh hoạ góc phải header — mỗi loại trang một hình.
enum HeroArt {
  none,
  locker,
  order,
  parcel,
  report,
  ticket,
  gift,
  wallet,
  bell,
  store,
  favorite,
  profile,
  security,
  delegation,
  location,
  chat,
}

/// Màu của [BrandHeroHeader] theo sáng/tối. Widget đặt ở `trailing` đọc qua
/// [BrandHeroColors.maybeOf] để không bị chìm trên nền header.
class BrandHeroColors extends InheritedWidget {
  const BrandHeroColors._({
    required this.background,
    required this.title,
    required this.subtitle,
    required this.buttonBg,
    required this.buttonFg,
    required this.buttonBorder,
    required this.buttonShadow,
    required this.artCard,
    required this.artCell,
    required this.artAccent,
    required super.child,
  });

  factory BrandHeroColors.forBrightness(bool dark, {required Widget child}) => dark
      ? BrandHeroColors._(
          background: const Color(0xFF0D2B4A),
          title: const Color(0xFFF1F5F9),
          subtitle: const Color(0xFFA9BBD0),
          buttonBg: const Color(0xFF1E3A5F),
          buttonFg: Colors.white,
          buttonBorder: const Color(0xFF2A4C74),
          buttonShadow: Colors.black.withValues(alpha: 0.25),
          artCard: const Color(0xFF163A5E),
          artCell: const Color(0xFF214A73),
          artAccent: const Color(0xFF4A90C8),
          child: child,
        )
      : BrandHeroColors._(
          background: const Color(0xFFDCE8F4),
          title: const Color(0xFF0A2342),
          subtitle: const Color(0xFF2E4560),
          buttonBg: Colors.white,
          buttonFg: const Color(0xFF0A2342),
          buttonBorder: Colors.white,
          buttonShadow: const Color(0xFF0A2342).withValues(alpha: 0.08),
          artCard: const Color(0xFFC5D7EA),
          artCell: const Color(0xFFE9F0F8),
          artAccent: const Color(0xFF1E5A8A),
          child: child,
        );

  final Color background;
  final Color title;
  final Color subtitle;
  final Color buttonBg;
  final Color buttonFg;
  final Color buttonBorder;
  final Color buttonShadow;
  final Color artCard;
  final Color artCell;
  final Color artAccent;

  static BrandHeroColors? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<BrandHeroColors>();

  @override
  bool updateShouldNotify(BrandHeroColors oldWidget) => background != oldWidget.background;
}

/// Header các trang khách: nền xanh nhạt bo góc dưới, tiêu đề lớn tự xuống
/// dòng (không bị cắt "…"), hình minh hoạ [art] nghiêng ở góc phải theo loại
/// trang. Khi cuộn ([collapseProgress] → 1) mô tả và hình mờ dần, tiêu đề nhỏ lại.
class BrandHeroHeader extends StatelessWidget {
  const BrandHeroHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.eyebrow,
    this.onBack,
    this.trailing,
    this.showBackButton,
    this.titleColor,
    this.subtitleColor,
    this.backgroundColor,
    this.art = HeroArt.none,
    this.collapseProgress = 0,
  });

  /// 0 = header đầy đủ, 1 = đã co thành thanh gọn.
  ///
  /// Header nằm trên một `Expanded` nên luôn cố định. [BrandHeroScaffold]
  /// truyền giá trị này theo vị trí cuộn để phần mô tả và hình xẹp dần, chỉ giữ
  /// lại tiêu đề và nút quay lại.
  final double collapseProgress;

  final String title;
  final String? subtitle;

  /// Kiểu header cũ hiện dòng "LOCK.R • …" trên tiêu đề; kiểu mới bỏ dòng này
  /// (hình minh hoạ đã cho biết loại trang). Giữ tham số để các trang không phải sửa.
  final String? eyebrow;
  final VoidCallback? onBack;
  final Widget? trailing;
  final bool? showBackButton;
  final Color? titleColor;
  final Color? subtitleColor;
  final Color? backgroundColor;
  final HeroArt art;

  /// Phần hình minh hoạ lộ ra trong header (~130 px): chữ chừa chỗ để không đè lên.
  static const double _artGap = 124;

  @override
  Widget build(BuildContext context) {
    final t = collapseProgress.clamp(0.0, 1.0);
    final canPop = Navigator.of(context).canPop();
    final shouldShowBack = showBackButton ?? (onBack != null || canPop);
    final effectiveOnBack = shouldShowBack
        ? (onBack ?? (canPop ? () => Navigator.of(context).maybePop() : null))
        : null;

    return BrandHeroColors.forBrightness(
      context.isDark,
      child: Builder(builder: (context) {
        final colors = BrandHeroColors.maybeOf(context)!;
        final hasArt = art != HeroArt.none;
        return Container(
          decoration: BoxDecoration(
            color: backgroundColor ?? colors.background,
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
          ),
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
            child: Stack(
              children: [
                if (hasArt && t < 1)
                  Positioned(
                    right: -18,
                    bottom: -22 - 30 * t,
                    child: IgnorePointer(
                      child: Opacity(
                        opacity: 1 - t,
                        child: _HeroArtwork(art: art, colors: colors),
                      ),
                    ),
                  ),
                SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(20, 10 - 4 * t, 20, 24 - 14 * t),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (effectiveOnBack != null || trailing != null)
                          Row(
                            children: [
                              if (effectiveOnBack != null)
                                Semantics(
                                  button: true,
                                  label: MaterialLocalizations.of(context).backButtonTooltip,
                                  child: BrandCircleIconButton(
                                    icon: Icons.arrow_back,
                                    onTap: effectiveOnBack,
                                    size: 44,
                                    iconSize: 20,
                                  ),
                                ),
                              const Spacer(),
                              if (trailing != null) trailing!,
                            ],
                          ),
                        SizedBox(height: 14 - 6 * t),
                        Padding(
                          // Chừa chỗ cho hình minh hoạ để chữ không đè lên.
                          padding: EdgeInsets.only(right: hasArt ? _artGap * (1 - t) : 0),
                          child: Text(
                            title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 26 - 7 * t,
                              height: 1.15,
                              fontWeight: FontWeight.w800,
                              color: titleColor ?? colors.title,
                              letterSpacing: -0.4,
                            ),
                          ),
                        ),
                        if (subtitle != null)
                          _Collapsible(
                            progress: t,
                            child: Padding(
                              padding: EdgeInsets.only(top: 6, right: hasArt ? _artGap : 0),
                              child: Text(
                                subtitle!,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 14,
                                  height: 1.4,
                                  color: subtitleColor ?? colors.subtitle,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }
}

/// Thẻ minh hoạ nghiêng ở góc header: tủ = lưới ô, còn lại = ô icon + vài vạch
/// chữ giả, cùng một tông màu để các trang trông đồng bộ.
class _HeroArtwork extends StatelessWidget {
  const _HeroArtwork({required this.art, required this.colors});

  final HeroArt art;
  final BrandHeroColors colors;

  static IconData _icon(HeroArt art) => switch (art) {
        HeroArt.order => LucideIcons.receipt,
        HeroArt.parcel => LucideIcons.package,
        HeroArt.report => LucideIcons.clipboardList,
        HeroArt.ticket => LucideIcons.ticket,
        HeroArt.gift => LucideIcons.gift,
        HeroArt.wallet => LucideIcons.wallet,
        HeroArt.bell => LucideIcons.bell,
        HeroArt.store => LucideIcons.store,
        HeroArt.favorite => LucideIcons.heart,
        HeroArt.profile => LucideIcons.user,
        HeroArt.security => LucideIcons.shieldCheck,
        HeroArt.delegation => LucideIcons.keyRound,
        HeroArt.location => LucideIcons.mapPin,
        HeroArt.chat => LucideIcons.messageCircle,
        HeroArt.locker || HeroArt.none => LucideIcons.box,
      };

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: -0.14,
      child: Container(
        width: 150,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: colors.artCard,
          borderRadius: BorderRadius.circular(18),
        ),
        child: art == HeroArt.locker ? _lockerGrid() : _iconCard(),
      ),
    );
  }

  Widget _cell({double height = 30, Color? color, double? width}) => Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: color ?? colors.artCell,
          borderRadius: BorderRadius.circular(6),
        ),
      );

  Widget _lockerGrid() {
    Widget row(List<bool> accents) => Row(
          children: [
            for (var i = 0; i < accents.length; i++) ...[
              if (i > 0) const SizedBox(width: 6),
              Expanded(child: _cell(color: accents[i] ? colors.artAccent : null)),
            ],
          ],
        );
    return Column(
      children: [
        row(const [false, false, true]),
        const SizedBox(height: 6),
        row(const [false, false, false]),
        const SizedBox(height: 6),
        row(const [false, false, false]),
      ],
    );
  }

  Widget _iconCard() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: colors.artAccent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(_icon(art), size: 22, color: Colors.white),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _cell(height: 10, width: 56),
                  const SizedBox(height: 6),
                  _cell(height: 10, width: 36),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        _cell(height: 12),
        const SizedBox(height: 6),
        _cell(height: 12, width: 92),
        const SizedBox(height: 6),
        _cell(height: 12),
      ],
    );
  }
}

/// Xẹp dần theo [progress] (0 = hiện đủ, 1 = cao 0) và mờ đi cùng lúc.
class _Collapsible extends StatelessWidget {
  const _Collapsible({required this.progress, required this.child});

  final double progress;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final factor = (1 - progress).clamp(0.0, 1.0);
    if (factor == 0) return const SizedBox.shrink();
    return ClipRect(
      child: Align(
        alignment: Alignment.topLeft,
        heightFactor: factor,
        child: Opacity(opacity: factor, child: child),
      ),
    );
  }
}

/// Bọc một trang "header + nội dung cuộn" để header co lại khi cuộn xuống.
///
/// Trước đây mọi trang dựng `Column(children: [BrandHeroHeader(...), Expanded(...)])`
/// nên header đứng yên và ăn ~140px chiều cao suốt lúc đọc nội dung.
class BrandHeroScaffold extends StatefulWidget {
  const BrandHeroScaffold({
    super.key,
    required this.header,
    required this.child,
    this.collapseDistance = 88,
  });

  /// Dựng header với mức co hiện tại (0..1).
  final Widget Function(double collapseProgress) header;

  /// Phần nội dung cuộn được (ListView, RefreshIndicator bọc ListView...).
  final Widget child;

  /// Cuộn bao nhiêu pixel thì header co hết cỡ.
  final double collapseDistance;

  @override
  State<BrandHeroScaffold> createState() => _BrandHeroScaffoldState();
}

class _BrandHeroScaffoldState extends State<BrandHeroScaffold> {
  final ValueNotifier<double> _progress = ValueNotifier<double>(0);

  @override
  void dispose() {
    _progress.dispose();
    super.dispose();
  }

  bool _onScroll(ScrollNotification notification) {
    // Chỉ nghe trục dọc của danh sách chính; bỏ qua list ngang lồng bên trong.
    if (notification.metrics.axis != Axis.vertical) return false;
    if (notification.depth > 0) return false;
    final offset = notification.metrics.pixels;
    _progress.value = (offset / widget.collapseDistance).clamp(0.0, 1.0);
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ValueListenableBuilder<double>(
          valueListenable: _progress,
          builder: (context, value, _) => widget.header(value),
        ),
        Expanded(
          child: NotificationListener<ScrollNotification>(
            onNotification: _onScroll,
            child: widget.child,
          ),
        ),
      ],
    );
  }
}

/// Section header: rounded icon tile + title + optional "see all" link.
class BrandSectionHeader extends StatelessWidget {
  const BrandSectionHeader({
    super.key,
    required this.icon,
    required this.title,
    this.lottieAsset,
    this.onSeeAll,
    this.seeAllLabel,
    this.highlightColor,
    this.highlightRollColor,
  });

  final IconData icon;
  final String title;
  final String? lottieAsset;
  final VoidCallback? onSeeAll;
  final String? seeAllLabel;

  /// Màu thân banner (bật chế độ highlight giống "Đang thịnh hành" Threads)
  final Color? highlightColor;

  /// Màu phần cuộn 3D bên phải (mặc định tự tối hơn highlightColor nếu null)
  final Color? highlightRollColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AislBrand.textTitle,
                    ),
                  ),
                ),
                if (lottieAsset != null) ...[
                  const SizedBox(width: 6),
                  AppLottie(lottieAsset!, width: 22, height: 22),
                ],
              ],
            ),
          ),
        ] else ...[
          // Co lại khi tiêu đề + "Xem tất cả" rộng hơn màn hình (máy hẹp,
          // cỡ chữ hệ thống lớn, tiêu đề tiếng Anh).
          Flexible(
            child: _HighlightBanner(
              color: highlightColor!,
              rollColor:
                  highlightRollColor ??
                  Color.lerp(highlightColor!, Colors.black, 0.30)!,
              title: title,
              lottieAsset: lottieAsset,
            ),
          ),
          if (onSeeAll != null) const SizedBox(width: 8),
        ],
        if (onSeeAll != null)
          GestureDetector(
            onTap: onSeeAll,
            behavior: HitTestBehavior.opaque,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  seeAllLabel ?? context.l10n.commonSeeAll,
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
    this.backgroundColor,
  });

  final String label;
  final Color dotColor;
  final Color textColor;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: backgroundColor ?? (context.isDark ? const Color(0xFF1E293B).withValues(alpha: 0.88) : Colors.white.withValues(alpha: 0.85)),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.40),
          width: 0.8,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
              ),
              const SizedBox(width: 5),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11.5,
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

class _HighlightBanner extends StatefulWidget {
  final Color color;
  final Color rollColor;
  final String title;
  final String? lottieAsset;

  const _HighlightBanner({
    required this.color,
    required this.rollColor,
    required this.title,
    this.lottieAsset,
  });

  @override
  State<_HighlightBanner> createState() => _HighlightBannerState();
}

class _HighlightBannerState extends State<_HighlightBanner> {
  static String? _rawSvg;

  @override
  void initState() {
    super.initState();
    if (_rawSvg == null) {
      rootBundle.loadString('assets/images/banner_highlight.svg').then((val) {
        if (mounted) {
          setState(() {
            _rawSvg = val;
          });
        } else {
          _rawSvg = val;
        }
      });
    }
  }

  static String _toHex(Color c) {
    final r = ((c.r * 255).round() & 0xFF).toRadixString(16).padLeft(2, '0');
    final g = ((c.g * 255).round() & 0xFF).toRadixString(16).padLeft(2, '0');
    final b = ((c.b * 255).round() & 0xFF).toRadixString(16).padLeft(2, '0');
    return '#$r$g$b';
  }

  static const _textStyle = TextStyle(
    fontSize: 14.5,
    fontWeight: FontWeight.w800,
    color: Colors.white,
    letterSpacing: 0.3,
  );

  // SVG roll element occupies the rightmost ~7% of banner width.
  // bannerWidth = (leftPad + contentWidth) / 0.93  → roll fills remainder automatically.
  static const double _leftPad = 14.0;
  static const double _rollFraction = 0.07;
  static const double _lottieSize = 20.0;
  static const double _lottieSpacing = 6.0;

  @override
  Widget build(BuildContext context) {
    final textScaler = MediaQuery.textScalerOf(context);
    final tp = TextPainter(
      text: TextSpan(text: widget.title, style: _textStyle),
      textDirection: TextDirection.ltr,
      textScaler: textScaler,
      maxLines: 1,
    )..layout();

    final lottieWidth =
        widget.lottieAsset != null ? (_lottieSize + _lottieSpacing) : 0.0;
    final contentWidth = tp.width + lottieWidth;
    final bannerWidth = (_leftPad + contentWidth) / (1 - _rollFraction);
    final rightPad = bannerWidth - _leftPad - contentWidth;

    Widget background;
    if (_rawSvg != null) {
      final bodyHex = _toHex(widget.color);
      final rollHex = _toHex(widget.rollColor);
      int matchCount = 0;
      final coloredSvg = _rawSvg!.replaceAllMapped(
        RegExp(r'fill="#[0-9A-Fa-f]{6}"'),
        (match) {
          matchCount++;
          return matchCount == 1 ? 'fill="$bodyHex"' : 'fill="$rollHex"';
        },
      );
      background = SvgPicture.string(
        coloredSvg,
        fit: BoxFit.fill,
      );
    } else {
      background = Container(
        decoration: BoxDecoration(
          color: widget.color,
          borderRadius: BorderRadius.circular(8),
        ),
      );
    }

    return Container(
      width: bannerWidth,
      height: 30,
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: widget.color.withValues(alpha: 0.22),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          background,
          Padding(
            padding: EdgeInsets.fromLTRB(_leftPad, 0, rightPad, 0),
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Flexible(
                    child: Text(
                      widget.title,
                      softWrap: false,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: _textStyle,
                    ),
                  ),
                  if (widget.lottieAsset != null) ...[
                    const SizedBox(width: _lottieSpacing),
                    AppLottie(
                      widget.lottieAsset!,
                      width: _lottieSize,
                      height: _lottieSize,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
