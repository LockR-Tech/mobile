import 'package:flutter/services.dart';
import 'package:smart_laundry_locker/core/config/feature_flags.dart';
import 'package:smart_laundry_locker/features/promotions/data/models/promotion_model.dart';
import 'package:smart_laundry_locker/features/promotions/presentation/pages/promotion_detail_page.dart';
import 'package:smart_laundry_locker/features/promotions/presentation/providers/promotion_provider.dart';
import 'package:flutter/material.dart';
import 'package:smart_laundry_locker/core/utils/currency_formatter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:smart_laundry_locker/features/notifications/presentation/providers/notification_provider.dart';
import 'package:smart_laundry_locker/core/routing/app_router.dart';
import 'package:smart_laundry_locker/features/wallet/presentation/providers/wallet_provider.dart';
import 'package:smart_laundry_locker/features/profile/presentation/providers/profile_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' hide Consumer;
import 'package:smart_laundry_locker/features/locker/domain/entities/locker_location.dart';
import 'package:smart_laundry_locker/features/locker/presentation/providers/locker_provider.dart';
import 'package:smart_laundry_locker/features/locker/presentation/providers/locker_providers.dart';
import 'package:smart_laundry_locker/features/stores/domain/entities/store.dart';
import 'package:smart_laundry_locker/features/stores/presentation/pages/store_lockers_page.dart';
import 'package:smart_laundry_locker/shared/widgets/user_ui_kit.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage>
    with SingleTickerProviderStateMixin {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final profile = context.read<ProfileProvider>();
      if (profile.profile == null && !profile.isLoading) {
        profile.loadProfile();
      }
      ref.read(lockerNotifierProvider).getLocations();
      ref.read(promotionNotifierProvider).load();
    });
  }

  Future<void> _onRefresh() async {
    final profile = context.read<ProfileProvider>();
    context.read<NotificationProvider>().loadUnreadCount();
    await Future.wait<void>([
      profile.loadProfile(),
      ref.read(lockerNotifierProvider).getLocations(refresh: true),
      ref.read(promotionNotifierProvider).load(),
    ]);
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.pageBg,
      body: _buildCustomerBody(context),
    );
  }

  // ---------------------------------------------------------------------------
  // Customer home (RN-style)
  // ---------------------------------------------------------------------------

  Widget _buildCustomerBody(BuildContext context) {
    return RefreshIndicator(
      color: AislBrand.navy,
      onRefresh: _onRefresh,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            const SizedBox(height: 20),
            _buildChips(context),
            const SizedBox(height: 24),
            _buildPopularLockersSection(context),
            const SizedBox(height: 24),
            _buildFlashSaleSection(context),
            const SizedBox(height: 28),
          ],
        ),
      ),
    );
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return '☀️ Chào buổi sáng';
    if (hour < 14) return '🌤️ Chào buổi trưa';
    if (hour < 18) return '🌅 Chào buổi chiều';
    return '🌙 Chào buổi tối';
  }

  Widget _buildHeader(BuildContext context) {
    final profile = context.watch<ProfileProvider>().profile;
    final name = (profile?.fullName.trim().isNotEmpty ?? false)
        ? profile!.fullName
        : 'Người dùng';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Theme-adaptive colours
    final bgGradient = isDark
        ? const [Color(0xFF061A30), Color(0xFF0A2845), Color(0xFF0D3055)]
        : const [Color(0xFFFFFFFF), Color(0xFFEBF5FF), Color(0xFFCBE8F5)];
    final textColor = isDark ? const Color(0xFFF1F5F9) : AislBrand.navy;
    final subColor = isDark
        ? const Color(0xFF94A3B8)
        : AislBrand.navy.withValues(alpha: 0.65);
    final circleA = isDark
        ? Colors.white.withValues(alpha: 0.04)
        : AislBrand.cyan.withValues(alpha: 0.18);
    final circleB = isDark
        ? Colors.white.withValues(alpha: 0.03)
        : AislBrand.navy.withValues(alpha: 0.06);
    final accentDot = isDark ? const Color(0xFF38BDF8) : AislBrand.cyan;
    final cardBg = isDark
        ? Colors.white.withValues(alpha: 0.07)
        : AislBrand.navy.withValues(alpha: 0.06);
    final cardBorder = isDark
        ? Colors.white.withValues(alpha: 0.12)
        : AislBrand.navy.withValues(alpha: 0.10);
    final walletIconBg = isDark
        ? const Color(0xFF38BDF8).withValues(alpha: 0.15)
        : AislBrand.cyan.withValues(alpha: 0.20);
    final walletIconColor = isDark ? const Color(0xFF38BDF8) : AislBrand.navy;
    final walletLabelColor = isDark
        ? const Color(0xFF94A3B8)
        : AislBrand.navy.withValues(alpha: 0.60);
    final btnBg = isDark ? const Color(0xFF38BDF8) : AislBrand.navy;
    final btnText = isDark ? const Color(0xFF061A30) : Colors.white;
    final shadowColor =
        isDark ? Colors.black.withValues(alpha: 0.4) : const Color(0x1A000000);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: bgGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(30)),
        boxShadow: [
          BoxShadow(color: shadowColor, blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(30)),
        child: Stack(
          children: [
            // ── Decorative circles (background) ──────────────────────────
            Positioned(
              top: -40,
              right: -40,
              child: Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(color: circleA, shape: BoxShape.circle),
              ),
            ),
            Positioned(
              top: 20,
              right: 60,
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(color: circleB, shape: BoxShape.circle),
              ),
            ),
            Positioned(
              bottom: -30,
              left: -20,
              child: Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(color: circleB, shape: BoxShape.circle),
              ),
            ),
            // ── Content ───────────────────────────────────────────────────
            SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 22),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Row 1: Avatar / greeting / bell
                    Row(
                      children: [
                        BrandAvatar(
                          imageUrl: profile?.avatarUrl,
                          name: name,
                          size: 48,
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Hi $name!',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  color: textColor,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Row(
                                children: [
                                  Container(
                                    width: 6,
                                    height: 6,
                                    decoration: BoxDecoration(
                                      color: accentDot,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    _greeting(),
                                    style: TextStyle(fontSize: 13, color: subColor),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        _buildBell(context, isDark: isDark),
                      ],
                    ),

                    // Row 2: Wallet card
                    if (FeatureFlags.walletEnabled) ...[
                      const SizedBox(height: 16),
                      Consumer<WalletProvider>(
                        builder: (context, wallet, _) => GestureDetector(
                          onTap: () async {
                            await context.push(AppRouter.topUp);
                            if (context.mounted) wallet.getWalletBalance();
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: cardBg,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: cardBorder),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: walletIconBg,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    LucideIcons.wallet,
                                    color: walletIconColor,
                                    size: 18,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'Số dư ví',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: walletLabelColor,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    Text(
                                      CurrencyFormatter.formatVnd(wallet.balance),
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w800,
                                        color: textColor,
                                      ),
                                    ),
                                  ],
                                ),
                                const Spacer(),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: btnBg,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    'Nạp tiền',
                                    style: TextStyle(
                                      color: btnText,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildBell(BuildContext context, {bool isDark = false}) {
    final bellBg = isDark
        ? Colors.white.withValues(alpha: 0.10)
        : Colors.white.withValues(alpha: 0.75);
    final bellBorder = isDark
        ? Colors.white.withValues(alpha: 0.15)
        : AislBrand.navy.withValues(alpha: 0.10);
    final bellIcon = isDark ? const Color(0xFFF1F5F9) : AislBrand.navy;

    return Consumer<NotificationProvider>(
      builder: (context, provider, _) {
        final count = provider.unreadCount;
        return GestureDetector(
          onTap: () => context.push(AppRouter.notifications),
          behavior: HitTestBehavior.opaque,
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: bellBg,
              shape: BoxShape.circle,
              border: Border.all(color: bellBorder),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(LucideIcons.bell, color: bellIcon, size: 24),
                if (count > 0)
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      constraints: const BoxConstraints(
                        minWidth: 18,
                        minHeight: 18,
                      ),
                      decoration: BoxDecoration(
                        color: AislBrand.badgeRed,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                      child: Center(
                        child: Text(
                          count > 99 ? '99+' : '$count',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildChips(BuildContext context) {
    final chips = <Widget>[
      BrandFilterChip(
        icon: LucideIcons.packageCheck,
        label: 'Đơn hàng',
        onTap: () => context.go(AppRouter.orders),
      ),
      BrandFilterChip(
        icon: LucideIcons.box,
        label: 'Tủ',
        onTap: () => context.go(AppRouter.lockers),
      ),
      BrandFilterChip(
        icon: LucideIcons.store,
        label: 'Cửa hàng',
        onTap: () => context.push(AppRouter.stores),
      ),
      BrandFilterChip(
        icon: LucideIcons.bell,
        label: 'Thông báo',
        onTap: () => context.push(AppRouter.notifications),
      ),
      BrandFilterChip(
        icon: LucideIcons.gift,
        label: 'Ưu đãi',
        onTap: () => context.push(AppRouter.promotions),
      ),
    ];

    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: chips.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (_, index) => chips[index],
      ),
    );
  }

  // ── "Popular Workouts" style: horizontal locker cards ──────────────────────

  Widget _buildPopularLockersSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: BrandSectionHeader(
            icon: LucideIcons.store,
            title: 'Các nơi đặt locker',
            onSeeAll: () => context.go(AppRouter.lockers),
            highlightColor: const Color(0xFF766807),
            highlightRollColor: const Color(0xFF58500D),
          ),
        ),
        const SizedBox(height: 14),
        _buildLockerHorizontalList(context),
      ],
    );
  }

  Widget _buildLockerHorizontalList(BuildContext context) {
    final LockerProvider lockerProvider = ref.watch(lockerNotifierProvider);
    final LockerState state = lockerProvider.state;

    if (state.isLoading && state.locations.isEmpty) {
      return SizedBox(
        height: 158,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          itemCount: 3,
          separatorBuilder: (_, __) => const SizedBox(width: 14),
          itemBuilder: (_, __) => Container(
            width: 250,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        ),
      );
    }
    if (state.error != null && state.locations.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: _storeMessage(LucideIcons.triangleAlert, state.error!, const Color(0xFFE53E3E)),
      );
    }
    if (state.locations.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: _storeMessage(LucideIcons.store, 'Chưa có nơi đặt locker nào', const Color(0xFFA0AEC0)),
      );
    }
    return SizedBox(
      height: 158,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: state.locations.length,
        separatorBuilder: (_, __) => const SizedBox(width: 14),
        itemBuilder: (_, index) => _buildLockerHorizontalCard(context, state.locations[index]),
      ),
    );
  }

  Widget _buildLockerHorizontalCard(BuildContext context, LockerLocation location) {
    final colors = _gradientForLocation(location.id);
    final initials = _initialsForName(location.name);
    return GestureDetector(
      onTap: () => Navigator.of(context, rootNavigator: true).push<void>(
        MaterialPageRoute(
          builder: (_) => StoreLockerGridPage(
            store: Store(
              id: int.tryParse(location.id) ?? 0,
              name: location.name,
              address: location.address,
              latitude: location.latitude,
              longitude: location.longitude,
              active: location.isActive,
            ),
          ),
        ),
      ),
      child: Container(
        width: 250,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Background image or gradient
              (location.imageUrl != null && location.imageUrl!.isNotEmpty)
                  ? CachedNetworkImage(
                      imageUrl: location.imageUrl!,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => _lockerCardGradient(colors, initials),
                      errorWidget: (_, __, ___) => _lockerCardGradient(colors, initials),
                    )
                  : _lockerCardGradient(colors, initials),
              // Dark bottom overlay
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.transparent, Colors.black.withValues(alpha: 0.60)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      stops: const [0.4, 1.0],
                    ),
                  ),
                ),
              ),
              // Status badge top-left
              Positioned(
                top: 12,
                left: 12,
                child: BrandStatusBadge(
                  label: location.isActive ? 'Hoạt động' : 'Đóng cửa',
                  dotColor: location.isActive ? AislBrand.statusGreen : Colors.grey,
                  textColor: location.isActive ? AislBrand.statusGreenText : Colors.grey.shade700,
                ),
              ),
              // Name + address bottom
              Positioned(
                bottom: 14,
                left: 14,
                right: 14,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      location.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(LucideIcons.mapPin, color: Colors.white60, size: 11),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            location.address.isNotEmpty ? location.address : 'Chưa có địa chỉ',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: Colors.white60, fontSize: 11),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _lockerCardGradient(List<Color> colors, String initials) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: colors, begin: Alignment.topLeft, end: Alignment.bottomRight),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              initials,
              style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w800, letterSpacing: 2),
            ),
            const SizedBox(height: 4),
            const Icon(LucideIcons.lockKeyhole, color: Colors.white38, size: 22),
          ],
        ),
      ),
    );
  }

  // ── Flash Sale section ─────────────────────────────────────────────────────

  Widget _buildFlashSaleSection(BuildContext context) {
    final PromotionProvider promoProvider = ref.watch(promotionNotifierProvider);
    final promos = promoProvider.promotions;
    final isLoading = promoProvider.isLoading;

    if (!isLoading && promos.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: BrandSectionHeader(
            icon: LucideIcons.zap,
            title: 'Flash Sale',
            onSeeAll: () => context.push(AppRouter.promotions),
            highlightColor: const Color(0xFF766807),
            highlightRollColor: const Color(0xFF58500D),
          ),
        ),
        const SizedBox(height: 14),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: isLoading && promos.isEmpty
              ? _buildFlashSaleSkeleton()
              : Column(
                  children: [
                    for (int i = 0; i < promos.take(10).length; i++) ...[
                      if (i > 0)
                        Divider(height: 1, color: context.dividerColor),
                      RepaintBoundary(
                        child: _FlashSaleCard(
                          promo: promos[i],
                          colors: _gradients[i % _gradients.length],
                        ),
                      ),
                    ],
                  ],
                ),
        ),
      ],
    );
  }

  Widget _buildFlashSaleSkeleton() {
    return Column(
      children: List.generate(
        2,
        (_) => Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Container(
              height: 200,
              color: const Color(0xFFE2E8F0),
            ),
          ),
        ),
      ),
    );
  }

  Widget _storeMessage(IconData icon, String message, Color color) {
    return Padding(
      padding: const EdgeInsets.all(36),
      child: Column(
        children: [
          Icon(icon, size: 44, color: color),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(color: color, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  static const _gradients = [
    [Color(0xFF003D5B), Color(0xFF0077B6)],
    [Color(0xFF0077B6), Color(0xFF00B4D8)],
    [Color(0xFF059669), Color(0xFF10B981)],
    [Color(0xFF7C3AED), Color(0xFF8B5CF6)],
    [Color(0xFFD97706), Color(0xFFF59E0B)],
    [Color(0xFF0F172A), Color(0xFF334155)],
  ];

  List<Color> _gradientForLocation(String id) {
    final hash = id.codeUnits.fold(0, (a, b) => a + b);
    return _gradients[hash % _gradients.length];
  }

  String _initialsForName(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return (parts[0][0] + parts[1][0]).toUpperCase();
    }
    final n = parts.first;
    return n.length >= 2 ? n.substring(0, 2).toUpperCase() : n.toUpperCase();
  }

}

// ── Flash Sale card — extracted for RepaintBoundary isolation ────────────────

class _FlashSaleCard extends StatelessWidget {
  final PromotionModel promo;
  final List<Color> colors;

  const _FlashSaleCard({required this.promo, required this.colors});

  @override
  Widget build(BuildContext context) {
    final String? sub =
        (promo.description != null && promo.description!.isNotEmpty)
            ? promo.description
            : null;

    return GestureDetector(
      onTap: () => Navigator.of(context, rootNavigator: true).push<void>(
        MaterialPageRoute(
          builder: (_) => PromotionDetailPage(promo: promo),
        ),
      ),
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Left: image 110×110 ──────────────────────────────────
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                width: 110,
                height: 110,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CachedNetworkImage(
                      imageUrl: promo.effectiveImageUrl,
                      fit: BoxFit.cover,
                      memCacheWidth: 220,
                      memCacheHeight: 220,
                      placeholder: (_, __) => _gradientBg(),
                      errorWidget: (_, __, ___) => _gradientBg(),
                    ),
                    Positioned(
                      bottom: 7,
                      left: 7,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE53E3E),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          promo.discountLabel,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 14),
            // ── Right: content ───────────────────────────────────────
            Expanded(
              child: SizedBox(
                height: 110,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Flash Sale chip
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF97316).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(LucideIcons.zap,
                              size: 10, color: Color(0xFFF97316)),
                          SizedBox(width: 4),
                          Text(
                            'Flash Sale',
                            style: TextStyle(
                              color: Color(0xFFF97316),
                              fontWeight: FontWeight.w800,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Title — 2 lines
                    Text(
                      promo.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: context.textPrimary,
                        height: 1.3,
                      ),
                    ),
                    // Subtitle
                    if (sub != null)
                      Text(
                        sub,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF94A3B8),
                        ),
                      )
                    else
                      const SizedBox.shrink(),
                    // Bottom: expiry + code chip
                    Row(
                      children: [
                        Icon(
                          LucideIcons.clock,
                          size: 12,
                          color: promo.isExpiringSoon
                              ? const Color(0xFFE53E3E)
                              : const Color(0xFF94A3B8),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            promo.expiryLabel,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              color: promo.isExpiringSoon
                                  ? const Color(0xFFE53E3E)
                                  : const Color(0xFF94A3B8),
                              fontWeight: promo.isExpiringSoon
                                  ? FontWeight.w700
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () => _copyCode(context),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 9, vertical: 4),
                            decoration: BoxDecoration(
                              color: AislBrand.navy.withValues(alpha: 0.06),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                  color: AislBrand.navy.withValues(alpha: 0.18)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  promo.code,
                                  style: const TextStyle(
                                    fontFamily: 'monospace',
                                    fontWeight: FontWeight.w800,
                                    fontSize: 12,
                                    color: AislBrand.navy,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const SizedBox(width: 5),
                                const Icon(LucideIcons.copy,
                                    size: 12, color: AislBrand.navy),
                              ],
                            ),
                          ),
                        ),
                      ],
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

  void _copyCode(BuildContext context) {
    Clipboard.setData(ClipboardData(text: promo.code));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Đã sao chép: ${promo.code}'),
        backgroundColor: AislBrand.navy,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Widget _gradientBg() => DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: colors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: const Center(
          child: Icon(LucideIcons.ticket, size: 32, color: Colors.white24),
        ),
      );
}
