import 'dart:ui';
import 'package:flutter/services.dart';
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
import 'package:smart_laundry_locker/features/profile/domain/entities/user_profile.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' hide Consumer;
import 'package:smart_laundry_locker/features/locker/domain/entities/locker_location.dart';
import 'package:smart_laundry_locker/features/locker/presentation/providers/locker_provider.dart';
import 'package:smart_laundry_locker/features/locker/presentation/providers/locker_providers.dart';
import 'package:smart_laundry_locker/features/stores/domain/entities/store.dart';
import 'package:smart_laundry_locker/features/stores/presentation/pages/store_lockers_page.dart';
import 'package:smart_laundry_locker/features/locker_ops/data/locker_ops_service.dart';
import 'package:smart_laundry_locker/features/locker_ops/presentation/widgets/ops_widgets.dart'
    show statusLabel, typeLabel, statusColor, fmtDateTime;
import 'package:smart_laundry_locker/shared/widgets/app_lottie.dart';
import 'package:smart_laundry_locker/shared/widgets/user_ui_kit.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage>
    with SingleTickerProviderStateMixin {
  final LockerOpsService _opsService = LockerOpsService();
  Map<String, dynamic>? _activeOrder;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final profile = context.read<ProfileProvider>();
      if (!profile.isLoading) {
        profile.loadProfile();
      }
      ref.read(lockerNotifierProvider).getLocations();
      ref.read(promotionNotifierProvider).load();
      _loadActiveOrder();
    });
  }

  Future<void> _loadActiveOrder() async {
    try {
      final orders = await _opsService.myOrders();
      if (orders.isNotEmpty && mounted) {
        final active = orders.firstWhere(
          (o) {
            final s = (o['status'] as String? ?? '').toUpperCase();
            return s != 'COMPLETED' && s != 'CANCELED';
          },
          orElse: () => orders.first,
        );

        final lockerId = int.tryParse(
          '${active['lockerId'] ?? active['destinationLockerId'] ?? ''}',
        );
        String? lockerName = active['lockerName']?.toString();
        int? boxNumber = int.tryParse('${active['boxNumber'] ?? ''}');

        if (lockerId != null) {
          if (lockerName == null || lockerName.isEmpty) {
            final locations = ref.read(lockerNotifierProvider).state.locations;
            final matched =
                locations.where((loc) => loc.id == '$lockerId').firstOrNull;
            if (matched != null) {
              lockerName = matched.name;
            } else {
              try {
                final info = await _opsService.locker(lockerId);
                lockerName = info['name']?.toString();
              } catch (_) {}
            }
          }

          if (boxNumber == null) {
            final boxId = int.tryParse(
              '${active['sendBoxId'] ?? active['receiveBoxId'] ?? active['boxId'] ?? ''}',
            );
            if (boxId != null) {
              try {
                final layout = await _opsService.layout(lockerId);
                final cells = layout['cells'] as List?;
                if (cells != null) {
                  for (final c in cells) {
                    if (int.tryParse('${c['id'] ?? ''}') == boxId) {
                      boxNumber = int.tryParse('${c['boxNumber'] ?? ''}');
                      break;
                    }
                  }
                }
              } catch (_) {}
            }
          }
        }

        final resolved = Map<String, dynamic>.from(active);
        if (lockerName != null && lockerName.isNotEmpty) {
          resolved['lockerName'] = lockerName;
        }
        if (boxNumber != null) {
          resolved['boxNumber'] = boxNumber;
        }

        if (mounted) {
          setState(() => _activeOrder = resolved);
        }
      }
    } catch (_) {
      // Keep sample card if network or not logged in
    }
  }

  Future<void> _onRefresh() async {
    final profile = context.read<ProfileProvider>();
    context.read<NotificationProvider>().loadUnreadCount();
    await Future.wait<void>([
      profile.loadProfile(),
      ref.read(lockerNotifierProvider).getLocations(refresh: true),
      ref.read(promotionNotifierProvider).load(),
      _loadActiveOrder(),
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
      color: const Color(0xFF0F172A),
      onRefresh: _onRefresh,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTopAppBar(context),
            const SizedBox(height: 12),
            _buildHeroCard(context),
            const SizedBox(height: 20),
            _buildQuickActionBadges(context),
            const SizedBox(height: 20),
            _buildActiveShipmentSection(context),
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

  Widget _buildTopAppBar(BuildContext context) {
    final profile = context.watch<ProfileProvider>().profile;
    final name = _resolveDisplayName(profile);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);

    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 6),
        child: Row(
          children: [
            // Lock.R Brand Logo & Name
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.08),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.asset(
                  'assets/images/logo.png',
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F172A).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Center(
                      child: Icon(
                        LucideIcons.box,
                        color: Color(0xFF0F172A),
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'Lock.R',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
                color: textColor,
              ),
            ),
            const Spacer(),
            // Bell Notification with Dot
            Consumer<NotificationProvider>(
              builder: (context, provider, _) {
                final count = provider.unreadCount;
                return GestureDetector(
                  onTap: () => context.push(AppRouter.notifications),
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.08)
                          : const Color(0xFFF1F5F9),
                      shape: BoxShape.circle,
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Icon(
                          LucideIcons.bell,
                          size: 21,
                          color: textColor,
                        ),
                        if (count > 0)
                          Positioned(
                            top: 9,
                            right: 10,
                            child: Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Color(0xFFEF4444),
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(width: 12),
            // Profile Circular Avatar
            GestureDetector(
              onTap: () => context.push(AppRouter.profile),
              behavior: HitTestBehavior.opaque,
              child: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.15)
                        : const Color(0xFFE2E8F0),
                    width: 1.5,
                  ),
                ),
                child: ClipOval(
                  child: (profile?.avatarUrl != null &&
                          profile!.avatarUrl!.isNotEmpty)
                      ? CachedNetworkImage(
                          imageUrl: profile.avatarUrl!,
                          fit: BoxFit.cover,
                          errorWidget: (_, __, ___) => _avatarFallback(name),
                        )
                      : _avatarFallback(name),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _avatarFallback(String name) {
    return Container(
      color: const Color(0xFFE2E8F0),
      child: Center(
        child: Text(
          AislBrand.initials(name),
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Color(0xFF334155),
          ),
        ),
      ),
    );
  }

  String _resolveDisplayName(UserProfile? profile) {
    if (profile == null) return 'Bạn';
    final name = profile.fullName.trim();
    if (name.isNotEmpty && name.toLowerCase() != 'người dùng') {
      return _capitalizeWords(name);
    }
    final email = profile.email.trim();
    if (email.isNotEmpty) {
      return _capitalizeWords(email.split('@').first);
    }
    final phone = profile.phoneNumber.trim();
    if (phone.isNotEmpty) {
      return phone;
    }
    return 'Bạn';
  }

  String _resolveHeroDisplayName(UserProfile? profile) {
    if (profile == null) return 'Bạn';
    final name = profile.fullName.trim();
    if (name.isNotEmpty && name.toLowerCase() != 'người dùng') {
      final parts =
          name.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
      if (parts.isNotEmpty) {
        return _capitalizeWords(parts.last);
      }
    }
    final email = profile.email.trim();
    if (email.isNotEmpty) {
      final prefix = email.split('@').first;
      final emailParts = prefix
          .split(RegExp(r'[._\s-]+'))
          .where((w) => w.isNotEmpty)
          .toList();
      if (emailParts.isNotEmpty) {
        return _capitalizeWords(emailParts.last);
      }
    }
    final phone = profile.phoneNumber.trim();
    if (phone.isNotEmpty) {
      return phone;
    }
    return 'Bạn';
  }

  String _capitalizeWords(String input) {
    return input
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .map((w) => w[0].toUpperCase() + (w.length > 1 ? w.substring(1) : ''))
        .join(' ');
  }

  Widget _buildHeroCard(BuildContext context) {
    final profile = context.watch<ProfileProvider>().profile;
    final displayName = _resolveHeroDisplayName(profile);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: const Color(0xFF14171F),
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(26),
        child: Stack(
          children: [
            // Top Section: Info text and spacing for wallet pill
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'HỆ THỐNG TỦ THÔNG MINH',
                              style: TextStyle(
                                color: Color(0xFF94A3B8),
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.1,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Flexible(
                                  child: Text(
                                    'Hello, $displayName!',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 22,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: -0.3,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                const Text(
                                  '👋',
                                  style: TextStyle(fontSize: 20),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Gửi đồ, thuê tủ và nhận hàng,\ntất cả trong một ứng dụng.',
                              style: TextStyle(
                                color: Color(0xFF94A3B8),
                                fontSize: 12.5,
                                height: 1.35,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 120),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Reserve space for the wallet pill to sit comfortably
                  const SizedBox(height: 60),
                ],
              ),
            ),
            // Big 3D Box Illustration (Layer 2)
            Positioned(
              top: 10,
              right: 10,
              child: IgnorePointer(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          LucideIcons.mapPin,
                          color: Color(0xFFF59E0B),
                          size: 15,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Điểm tủ 24/7',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: 10.5,
                            fontStyle: FontStyle.italic,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    const SizedBox(
                      width: 200,
                      height: 180,
                      child: AppLottie(AppLottieAssets.box),
                    ),
                  ],
                ),
              ),
            ),
            // Bottom Wallet Pill (Layer 3 - exactly overlaps the bottom of the 3D box)
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: _buildWalletPill(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWalletPill(BuildContext context) {
    return Consumer<WalletProvider>(
      builder: (context, wallet, _) => GestureDetector(
        onTap: () async {
          await context.push(AppRouter.topUp);
          if (context.mounted) wallet.getWalletBalance();
        },
        behavior: HitTestBehavior.opaque,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.15),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  const AppLottie(
                    AppLottieAssets.napVi,
                    width: 40,
                    height: 40,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Số dư ví khả dụng',
                          style: TextStyle(
                            fontSize: 11,
                            color: Color(0xFF94A3B8),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            CurrencyFormatter.formatVnd(wallet.balance),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                            maxLines: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD97706),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFD97706).withValues(alpha: 0.35),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Text(
                      'Nạp tiền',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActionBadges(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildQuickBadgeItem(
            context: context,
            icon: LucideIcons.store,
            lottieAsset: AppLottieAssets.cuaHang,
            label: 'Cửa hàng',
            isPrimary: false,
            textColor: textColor,
            onTap: () => context.push(AppRouter.stores),
          ),
          _buildQuickBadgeItem(
            context: context,
            icon: LucideIcons.box,
            lottieAsset: AppLottieAssets.thueTu,
            label: 'Thuê tủ',
            isPrimary: false,
            textColor: textColor,
            onTap: () => context.go(AppRouter.lockers),
          ),
          _buildQuickBadgeItem(
            context: context,
            icon: LucideIcons.calendarClock,
            lottieAsset: AppLottieAssets.donTu,
            label: 'Đơn tủ',
            isPrimary: false,
            textColor: textColor,
            onTap: () => context.go(AppRouter.orders),
          ),
          _buildQuickBadgeItem(
            context: context,
            icon: LucideIcons.ellipsis,
            label: 'Tiện ích',
            isPrimary: false,
            textColor: textColor,
            onTap: () => _showMoreUtilitiesSheet(context),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickBadgeItem({
    required BuildContext context,
    required IconData icon,
    required String label,
    required bool isPrimary,
    required Color textColor,
    required VoidCallback onTap,
    String? lottieAsset,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isPrimary
        ? const Color(0xFF0F172A)
        : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9));
    final iconColor = isPrimary
        ? Colors.white
        : (isDark ? Colors.white : const Color(0xFF0F172A));

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(22),
              boxShadow: isPrimary
                  ? [
                      BoxShadow(
                        color: const Color(0xFF0F172A).withValues(alpha: 0.35),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : null,
            ),
            child: Center(
              child: lottieAsset != null
                  ? AppLottie(
                      lottieAsset,
                      width: 46,
                      height: 46,
                      fallback: (context) => Icon(
                        icon,
                        color: iconColor,
                        size: 26,
                      ),
                    )
                  : Icon(
                      icon,
                      color: iconColor,
                      size: 26,
                    ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: isPrimary ? FontWeight.w800 : FontWeight.w600,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveShipmentSection(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final cardBorder =
        isDark ? Colors.white.withValues(alpha: 0.1) : const Color(0xFFF1F5F9);
    final titleColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final subColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    final order = _activeOrder;
    final orderCode = order != null &&
            order['orderCode'] != null &&
            order['orderCode'].toString().isNotEmpty
        ? '#${order['orderCode']}'
        : '#ORD-20260920-7D7BP5';
    final rawType = order != null ? (order['type'] as String? ?? '') : '';
    final boxNum = order != null ? order['boxNumber'] : null;
    final typeName = typeLabel(rawType.isNotEmpty ? rawType : 'RENTAL');
    final subtitle = order != null
        ? (boxNum != null ? '$typeName • Ô số $boxNum' : typeName)
        : 'Thuê tủ • Ô số 5';
    final routeText = order != null
        ? (order['lockerName'] as String? ?? 'Tủ demo capstone 3x3')
        : 'Tủ demo capstone 3x3';
    final rawStatus =
        order != null ? (order['status'] as String? ?? 'STORING') : 'STORING';
    final displayStatus = statusLabel(rawStatus);
    final sColor = statusColor(rawStatus);
    final deadline = order != null ? order['pickupDeadline'] : null;
    final deadlineStr = deadline != null ? fmtDateTime(deadline) : null;
    final isDelivered = rawStatus.toUpperCase() == 'COMPLETED';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Header: Active shipment + See all >
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Active shipment',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: titleColor,
                  letterSpacing: -0.3,
                ),
              ),
              GestureDetector(
                onTap: () => context.go(AppRouter.orders),
                behavior: HitTestBehavior.opaque,
                child: Row(
                  children: [
                    Text(
                      'See all',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: subColor,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      LucideIcons.chevronRight,
                      size: 14,
                      color: subColor,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Shipment Card
          GestureDetector(
            onTap: () => context.go(AppRouter.orders),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: cardBorder),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Top Row: 3D Box Thumb, Title/Info, Status Badge & ETA
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 3D Box Thumb container
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.08)
                              : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.12)
                                : const Color(0xFFE2E8F0),
                          ),
                        ),
                        padding: const EdgeInsets.all(5),
                        child: AppLottie(
                          (rawType.toUpperCase().contains('SEND') ||
                                  rawType.toUpperCase().contains('DRONE') ||
                                  rawType.toUpperCase().contains('DELIVERY') ||
                                  rawType.toUpperCase().contains('PARCEL'))
                              ? AppLottieAssets.airplaneBox
                              : AppLottieAssets.box,
                          fallback: (context) => Icon(
                            (rawType.toUpperCase().contains('SEND') ||
                                    rawType.toUpperCase().contains('DRONE') ||
                                    rawType.toUpperCase().contains('DELIVERY') ||
                                    rawType.toUpperCase().contains('PARCEL'))
                                ? LucideIcons.plane
                                : LucideIcons.box,
                            size: 26,
                            color: isDark
                                ? Colors.white70
                                : const Color(0xFF1E293B),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Middle: Order Code, Subtitle, Route
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              orderCode,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: titleColor,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              subtitle,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: subColor,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              routeText,
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w400,
                                color: subColor.withValues(alpha: 0.8),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Right: Status badge & ETA
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: sColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: sColor,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  displayStatus,
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w700,
                                    color: sColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            deadlineStr != null
                                ? 'Hạn lấy đồ'
                                : (isDelivered ? 'Trạng thái' : 'Dự kiến'),
                            style: TextStyle(
                              fontSize: 10.5,
                              color: subColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 1),
                          Text(
                            deadlineStr ??
                                (isDelivered ? 'Đã hoàn tất' : '2:30 PM'),
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w800,
                              color: titleColor,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  // Bottom Stepper (4 steps dynamic matching actual order status)
                  _buildShipmentStepper(context, order: order),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShipmentStepper(
    BuildContext context, {
    Map<String, dynamic>? order,
  }) {
    final activeColor = const Color(0xFF10B981);
    final inactiveColor = const Color(0xFFCBD5E1);
    final lineColor = const Color(0xFFE2E8F0);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final mutedText = const Color(0xFF94A3B8);

    final rawStatus = (order?['status'] as String? ?? '').toUpperCase();
    final rawType = (order?['type'] as String? ?? '').toUpperCase();
    final isRental = rawType.contains('RENT') || rawType.contains('STORAGE');

    final List<String> titles;
    final List<String?> times;
    final int activeStepCount;

    final createdStr = order?['createdAt'] != null
        ? fmtDateTime(order!['createdAt'])
        : '12 Sep, 10:24';

    if (order == null) {
      titles = const ['Picked up', 'In transit', 'Out for delivery', 'Delivered'];
      times = const ['12 Sep, 10:24', '13 Sep, 08:40', null, null];
      activeStepCount = 2;
    } else if (isRental) {
      titles = const ['Tạo đơn', 'Bỏ vào tủ', 'Đang lưu tủ', 'Hoàn tất'];
      times = [createdStr, null, null, null];
      if (rawStatus == 'INITIALIZED') {
        activeStepCount = 1;
      } else if (rawStatus == 'STORING') {
        activeStepCount = 3;
      } else if (rawStatus == 'COMPLETED') {
        activeStepCount = 4;
      } else {
        activeStepCount = 2;
      }
    } else {
      titles = const ['Tạo đơn', 'Đã vào tủ', 'Vận chuyển', 'Đã nhận'];
      times = [createdStr, null, null, null];
      if (rawStatus == 'INITIALIZED') {
        activeStepCount = 1;
      } else if (rawStatus == 'STORING') {
        activeStepCount = 2;
      } else if (rawStatus == 'COLLECTED' ||
          rawStatus == 'PROCESSING' ||
          rawStatus == 'RETURNED' ||
          rawStatus == 'READY_FOR_PICKUP') {
        activeStepCount = 3;
      } else if (rawStatus == 'COMPLETED') {
        activeStepCount = 4;
      } else {
        activeStepCount = 2;
      }
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final totalWidth = constraints.maxWidth;
        final stepWidth = totalWidth / 4;

        return Column(
          children: [
            // Row of Circles connected by Lines
            SizedBox(
              height: 24,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Connecting Lines
                  Positioned(
                    left: stepWidth / 2,
                    right: stepWidth / 2,
                    child: Row(
                      children: [
                        // Line 1-2
                        Expanded(
                          child: Container(
                            height: 2.5,
                            color:
                                activeStepCount >= 2 ? activeColor : lineColor,
                          ),
                        ),
                        // Line 2-3
                        Expanded(
                          child: Container(
                            height: 2.5,
                            color:
                                activeStepCount >= 3 ? activeColor : lineColor,
                          ),
                        ),
                        // Line 3-4
                        Expanded(
                          child: Container(
                            height: 2.5,
                            color:
                                activeStepCount >= 4 ? activeColor : lineColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // The 4 Step Circles
                  Row(
                    children: [
                      Expanded(
                        child: Center(
                          child: _buildStepCircle(
                            isActive: activeStepCount >= 1,
                            activeColor: activeColor,
                            inactiveColor: inactiveColor,
                            circleBg: isDark ? const Color(0xFF1E293B) : Colors.white,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Center(
                          child: _buildStepCircle(
                            isActive: activeStepCount >= 2,
                            activeColor: activeColor,
                            inactiveColor: inactiveColor,
                            circleBg: isDark ? const Color(0xFF1E293B) : Colors.white,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Center(
                          child: _buildStepCircle(
                            isActive: activeStepCount >= 3,
                            activeColor: activeColor,
                            inactiveColor: inactiveColor,
                            circleBg: isDark ? const Color(0xFF1E293B) : Colors.white,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Center(
                          child: _buildStepCircle(
                            isActive: activeStepCount >= 4,
                            activeColor: activeColor,
                            inactiveColor: inactiveColor,
                            circleBg: isDark ? const Color(0xFF1E293B) : Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            // The Labels and Timestamps
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStepLabel(
                  title: titles[0],
                  time: times[0],
                  isActive: activeStepCount >= 1,
                  textColor: textColor,
                  mutedColor: mutedText,
                ),
                _buildStepLabel(
                  title: titles[1],
                  time: times[1],
                  isActive: activeStepCount >= 2,
                  textColor: textColor,
                  mutedColor: mutedText,
                ),
                _buildStepLabel(
                  title: titles[2],
                  time: times[2],
                  isActive: activeStepCount >= 3,
                  textColor: textColor,
                  mutedColor: mutedText,
                ),
                _buildStepLabel(
                  title: titles[3],
                  time: times[3],
                  isActive: activeStepCount >= 4,
                  textColor: textColor,
                  mutedColor: mutedText,
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildStepCircle({
    required bool isActive,
    required Color activeColor,
    required Color inactiveColor,
    Color circleBg = Colors.white,
  }) {
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        color: isActive ? activeColor : circleBg,
        shape: BoxShape.circle,
        border: Border.all(
          color: isActive ? activeColor : inactiveColor,
          width: 2,
        ),
      ),
      child: Center(
        child: isActive
            ? const Icon(
                LucideIcons.check,
                color: Colors.white,
                size: 13,
              )
            : null,
      ),
    );
  }

  Widget _buildStepLabel({
    required String title,
    required String? time,
    required bool isActive,
    required Color textColor,
    required Color mutedColor,
  }) {
    return Expanded(
      child: Column(
        children: [
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
              color: isActive ? textColor : mutedColor,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (time != null) ...[
            const SizedBox(height: 2),
            Text(
              time,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 9.5,
                color: mutedColor,
                fontWeight: FontWeight.w400,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }

  void _showMoreUtilitiesSheet(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sheetBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final titleColor = isDark ? Colors.white : const Color(0xFF0F172A);

    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      backgroundColor: sheetBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Tiện ích & Dịch vụ',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: titleColor,
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    _buildUtilityItem(
                      ctx,
                      icon: LucideIcons.gift,
                      lottieAsset: AppLottieAssets.uuDai,
                      label: 'Ưu đãi',
                      color: const Color(0xFFEC4899),
                      onTap: () {
                        Navigator.pop(ctx);
                        context.push(AppRouter.promotions);
                      },
                    ),
                    _buildUtilityItem(
                      ctx,
                      icon: LucideIcons.triangleAlert,
                      lottieAsset: AppLottieAssets.baoSuCo,
                      label: 'Báo sự cố',
                      color: const Color(0xFFF59E0B),
                      onTap: () {
                        Navigator.pop(ctx);
                        context.push(AppRouter.createReport);
                      },
                    ),
                    _buildUtilityItem(
                      ctx,
                      icon: LucideIcons.clipboardList,
                      lottieAsset: AppLottieAssets.baoCao,
                      label: 'Báo cáo',
                      color: const Color(0xFF3B82F6),
                      onTap: () {
                        Navigator.pop(ctx);
                        context.push(AppRouter.myLockerReports);
                      },
                    ),
                    _buildUtilityItem(
                      ctx,
                      icon: LucideIcons.wallet,
                      lottieAsset: AppLottieAssets.napVi,
                      label: 'Nạp ví',
                      color: const Color(0xFF10B981),
                      onTap: () {
                        Navigator.pop(ctx);
                        context.push(AppRouter.topUp);
                      },
                    ),
                    _buildUtilityItem(
                      ctx,
                      icon: LucideIcons.arrowUpRight,
                      label: 'Rút tiền',
                      color: const Color(0xFFF97316),
                      onTap: () {
                        Navigator.pop(ctx);
                        context.push(AppRouter.withdraw);
                      },
                    ),
                    _buildUtilityItem(
                      ctx,
                      icon: LucideIcons.store,
                      label: 'Điểm gửi',
                      color: const Color(0xFF8B5CF6),
                      onTap: () {
                        Navigator.pop(ctx);
                        context.push(AppRouter.stores);
                      },
                    ),
                    _buildUtilityItem(
                      ctx,
                      icon: LucideIcons.bell,
                      label: 'Thông báo',
                      color: const Color(0xFF06B6D4),
                      onTap: () {
                        Navigator.pop(ctx);
                        context.push(AppRouter.notifications);
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildUtilityItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
    String? lottieAsset,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        width: 72,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: lottieAsset != null
                    ? AppLottie(
                        lottieAsset,
                        width: 36,
                        height: 36,
                        fallback: (context) =>
                            Icon(icon, color: color, size: 24),
                      )
                    : Icon(icon, color: color, size: 24),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
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
            title: 'Các nơi đặt kiosk',
            onSeeAll: () => context.go(AppRouter.lockers),
            highlightColor: const Color(0xFF0F172A),
            highlightRollColor: const Color(0xFF020617),
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
              color: Colors.grey.shade800,
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
            highlightColor: const Color(0xFFE11D48),
            highlightRollColor: const Color(0xFF9F1239),
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

