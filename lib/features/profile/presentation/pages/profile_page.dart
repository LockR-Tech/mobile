import 'dart:io';

import 'package:smart_laundry_locker/core/config/feature_flags.dart';
import 'package:smart_laundry_locker/core/services/token_service.dart';
import 'package:smart_laundry_locker/features/notifications/presentation/providers/notification_provider.dart';
import 'package:smart_laundry_locker/core/network/api_client.dart';
import 'package:smart_laundry_locker/features/profile/presentation/providers/profile_provider.dart';
import 'package:smart_laundry_locker/features/delegations/presentation/providers/delegation_provider.dart';
import 'package:smart_laundry_locker/features/delegations/presentation/providers/delegation_injection.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:smart_laundry_locker/core/routing/app_router.dart';
import 'package:smart_laundry_locker/core/theme/shadcn_theme.dart';
import 'package:smart_laundry_locker/core/theme/theme_provider.dart';
import 'package:smart_laundry_locker/features/profile/presentation/mixins/profile_image_actions_mixin.dart';
import 'package:smart_laundry_locker/features/profile/presentation/widgets/profile_header.dart';
import 'package:smart_laundry_locker/features/profile/presentation/widgets/profile_menu_item.dart';
import 'package:smart_laundry_locker/shared/widgets/user_ui_kit.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage>
    with ProfileImageActionsMixin {
  @override
  File? localAvatarFile;

  @override
  File? localBannerFile;

  @override
  bool isAvatarSyncing = false;

  // User data
  Map<String, dynamic>? _userData;
  bool _isLoading = true;
  bool _isLoggedIn = false;
  late ProfileProvider _profileProvider;
  late DelegationProvider _delegationProvider;

  @override
  void initState() {
    super.initState();
    final apiClient = ApiClient();
    _profileProvider = context.read<ProfileProvider>();
    _delegationProvider = DelegationInjection.provideDelegationProvider(
      apiClient,
    );
    TokenService.authState.addListener(_onAuthStateChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadUserProfile();
    });
  }

  void _onAuthStateChanged() {
    if (TokenService.authState.value) {
      _loadUserProfile();
    } else {
      if (mounted) {
        setState(() {
          _isLoggedIn = false;
          _userData = null;
        });
      }
    }
  }

  @override
  void dispose() {
    TokenService.authState.removeListener(_onAuthStateChanged);
    _delegationProvider.dispose();
    super.dispose();
  }

  Future<void> _loadUserProfile({bool forceRefresh = false}) async {
    setState(() {
      _isLoading = true;
    });

    final hasToken = await TokenService.hasToken();
    if (!mounted) return;

    if (!hasToken) {
      setState(() {
        _isLoggedIn = false;
        _userData = null;
        _isLoading = false;
      });
      return;
    }

    await _profileProvider.loadProfile();
    if (!mounted) return;

    final isLoggedIn = _profileProvider.profile != null;

    if (isLoggedIn) {
      await _delegationProvider.fetchMyDelegations();
    }
    if (!mounted) return;

    List<String> roles = [];
    if (isLoggedIn) {
      roles = await TokenService.getCurrentRoles();
    }

    setState(() {
      _isLoggedIn = isLoggedIn;
      if (_profileProvider.profile != null) {
        final profile = _profileProvider.profile!;
        _userData = {
          'id': profile.id.toString(),
          'fullName': profile.fullName.toString(),
          'email': profile.email.toString(),
          'phoneNumber': profile.phoneNumber.toString(),
          'avatar': profile.avatarUrl,
          'isEmailVerified': profile.isVerified,
          'isPhoneVerified': profile.isVerified,
          'status': profile.status.name,
          'isActive': profile.isActive,
          'roles': roles,
        };
      } else {
        _userData = null;
      }
      _isLoading = false;
    });
  }

  @override
  String? get currentUserIdForAvatar => _userData?['id'] as String?;

  @override
  Widget build(BuildContext context) {
    // Show loading
    if (_isLoading) {
      return Scaffold(
        backgroundColor: context.pageBg,
        body: const Column(
          children: [
            BrandHeroHeader(
              title: 'Hồ sơ',
              subtitle: 'Quản lý tài khoản của bạn',
            ),
            Expanded(
              child: Center(child: CircularProgressIndicator()),
            ),
          ],
        ),
      );
    }

    // nếu chưa đăng nhập thì chuyển về màn hình đăng nhập
    if (!_isLoggedIn) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.go(AppRouter.onboarding);
      });
      return Scaffold(
        backgroundColor: context.pageBg,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: context.pageBg,
      body: MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: _delegationProvider),
        ],
        child: Column(
          children: [
            BrandHeroHeader(
              title: 'Hồ sơ',
              subtitle: 'Quản lý tài khoản của bạn',
              trailing: BrandCircleIconButton(
                icon: LucideIcons.pencil,
                onTap: _handleEditProfile,
                iconSize: 16,
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  await _loadUserProfile(forceRefresh: true);
                },
                color: AISLShadcnTheme.navyPrimary,
                backgroundColor: context.cardBg,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Column(
                    children: [
                      const SizedBox(height: 16),

                      if (_userData != null)
                        ProfileHeader(
                          user: _userData!,
                          avatarVersion: 0,
                          localAvatarFile: localAvatarFile,
                          isAvatarSyncing: isAvatarSyncing,
                          showSaveAvatarButton: localAvatarFile != null,
                          onEditAvatar: handleAvatarSelection,
                          onSaveAvatar: uploadAvatarImage,
                          onCancelAvatar: cancelAvatarSelection,
                        ),

                      const SizedBox(height: 24),

                      _buildMenuSection(),
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuSection() {
    return Column(
      children: [
          // Account section
          _buildMenuGroup(
            title: 'Tài khoản',
            items: [
              ProfileMenuItem(
                icon: LucideIcons.user,
                title: 'Thông tin cá nhân',
                onTap: _handleEditProfile,
              ),
              // Tạm ẩn: backend chưa có AI service (/api/auth/ai/* trả 500).
              if (FeatureFlags.faceRecognitionEnabled)
                ListenableBuilder(
                  listenable: _profileProvider,
                  builder: (context, _) {
                    final isRegistered = _profileProvider.isFaceRegistered;
                    return ProfileMenuItem(
                      icon: Icons.face_retouching_natural_outlined,
                      title: isRegistered
                          ? 'Đăng ký lại khuôn mặt'
                          : 'Đăng ký khuôn mặt',
                      onTap: _handleFaceRegistration,
                    );
                  },
                ),
              ProfileMenuItem(
                icon: LucideIcons.shield,
                title: 'Bảo mật',
                onTap: _handleSecurity,
              ),
              // Tạm ẩn: backend chưa có subscription service (/plans, /subscriptions 404).
              if (FeatureFlags.subscriptionEnabled)
                ProfileMenuItem(
                  icon: LucideIcons.badgePercent,
                  title: 'Gói dịch vụ',
                  onTap: _handlePlans,
                ),
              // Tạm ẩn: backend chưa có kho voucher (/promotions/vouchers/my 404).
              // (Trang "Ưu đãi" qua chip ở trang chủ vẫn hoạt động.)
              if (FeatureFlags.vouchersEnabled)
                ProfileMenuItem(
                  icon: LucideIcons.ticket,
                  title: 'Ưu đãi & Quà tặng',
                  onTap: _handleMyVouchers,
                ),
              Consumer<NotificationProvider>(
                builder: (context, provider, child) {
                  return ProfileMenuItem(
                    icon: LucideIcons.bell,
                    title: 'Thông báo',
                    onTap: () {
                      context.push(AppRouter.notifications);
                    },
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (provider.unreadCount > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              provider.unreadCount > 99
                                  ? '99+'
                                  : '${provider.unreadCount}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        const SizedBox(width: 8),
                        Icon(
                          LucideIcons.chevronRight,
                          size: 16,
                          color: context.textMuted,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Divider(height: 1, indent: 16, endIndent: 16),
          const SizedBox(height: 8),
          // Properties section
          _buildMenuGroup(
            title: 'Quản lý',
            items: [
              Consumer<DelegationProvider>(
                builder: (context, provider, child) {
                  final delegations = provider.myDelegations
                      .where((d) => d.isActive && d.usedAt == null)
                      .toList();

                  return ProfileMenuItem(
                    icon: LucideIcons.packageOpen,
                    title: 'Đơn ủy quyền',
                    onTap: () => context.push(AppRouter.myDelegations),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (delegations.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.blue,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              delegations.length > 99
                                  ? '99+'
                                  : '${delegations.length}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        const SizedBox(width: 8),
                        Icon(
                          LucideIcons.chevronRight,
                          size: 16,
                          color: context.textMuted,
                        ),
                      ],
                    ),
                  );
                },
              ),
              // Tạm ẩn: backend chưa có lịch sử giao dịch/ví (/payments/transactions 404).
              if (FeatureFlags.transactionsEnabled)
                ProfileMenuItem(
                  icon: LucideIcons.arrowLeftRight,
                  title: 'Giao dịch',
                  onTap: () => context.push(AppRouter.transactions),
                  trailing: Icon(
                    LucideIcons.chevronRight,
                    size: 16,
                    color: Colors.black54,
                  ),
                ),
              ProfileMenuItem(
                icon: LucideIcons.clipboardList,
                title: 'Báo cáo của tôi',
                onTap: () => context.pushNamed('my_reports'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Divider(height: 1, indent: 16, endIndent: 16),
          const SizedBox(height: 8),
          // Settings section
          _buildMenuGroup(
            title: 'Cài đặt',
            items: [
              ProfileMenuItem(
                icon: LucideIcons.globe,
                title: 'Ngôn ngữ',
                onTap: _handleLanguage,
                trailing: Icon(
                  LucideIcons.chevronRight,
                  size: 16,
                  color: ShadTheme.of(context).colorScheme.mutedForeground,
                ),
              ),
              ProfileMenuItem(
                icon: LucideIcons.palette,
                title: 'Giao diện',
                onTap: _handleTheme,
                trailing: Icon(
                  LucideIcons.chevronRight,
                  size: 16,
                  color: ShadTheme.of(context).colorScheme.mutedForeground,
                ),
              ),
              ProfileMenuItem(
                icon: LucideIcons.mapPin,
                title: 'Vị trí',
                onTap: _handleLocation,
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Divider(height: 1, indent: 16, endIndent: 16),
          const SizedBox(height: 8),
          // Support section
          _buildMenuGroup(
            title: 'Hỗ trợ',
            items: [
              ProfileMenuItem(
                icon: LucideIcons.handHelping,
                title: 'Trợ giúp',
                onTap: _handleHelp,
              ),
              ProfileMenuItem(
                icon: LucideIcons.messageCircle,
                title: 'Liên hệ',
                onTap: _handleContact,
              ),
              ProfileMenuItem(
                icon: LucideIcons.fileText,
                title: 'Điều khoản',
                onTap: _handleTerms,
              ),
              ProfileMenuItem(
                icon: LucideIcons.shieldCheck,
                title: 'Chính sách bảo mật',
                onTap: _handlePrivacy,
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Divider(height: 1, indent: 16, endIndent: 16),
          const SizedBox(height: 8),
          // Account actions
          _buildMenuGroup(
            items: [
              ProfileMenuItem(
                icon: LucideIcons.doorOpen,
                title: 'Đăng xuất',
                onTap: _handleLogout,
                textColor: ShadTheme.of(context).colorScheme.destructive,
                iconColor: ShadTheme.of(context).colorScheme.destructive,
              ),
            ],
          ),

          const SizedBox(height: 8),
        ],
    );
  }

  Widget _buildMenuGroup({required List<Widget> items, String? title}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title != null) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              title,
              style: TextStyle(
                fontFamily: 'Manrope',
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: ShadTheme.of(context).colorScheme.mutedForeground,
              ),
            ),
          ),
        ],
        ...items,
      ],
    );
  }

  void _handleEditProfile() {
    if (!mounted) return;
    context.pushNamed('profile_detail');
  }

  void _handleFaceRegistration() {
    if (!mounted) return;
    context.push(AppRouter.faceRegistration);
  }

  void _handleSecurity() {
    if (!mounted) return;
    context.push(AppRouter.security);
  }

  void _handlePlans() {
    if (!mounted) return;
    context.push(AppRouter.plans);
  }

  void _handleMyVouchers() {
    if (!mounted) return;
    context.push(AppRouter.myVouchers);
  }

  void _handleLanguage() {
    _showProfileSnackBar('Tính năng đang được phát triển');
  }

  void _handleTheme() {
    final themeProvider = context.read<ThemeProvider>();
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return _ThemePickerSheet(current: themeProvider.themeMode);
      },
    ).then((value) {
      // ignore
    });
  }

  void _handleLocation() {
    _showProfileSnackBar('Tính năng đang được phát triển');
  }

  void _handleHelp() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 4, 24, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Trợ giúp nhanh',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 14),
            _helpRow(
              LucideIcons.packagePlus,
              'Gửi hàng',
              'Chọn cửa hàng → chạm ô trống → Gửi hàng → thanh toán → dùng PIN/nút "Mở tủ" để bỏ hàng.',
            ),
            _helpRow(
              LucideIcons.lockKeyhole,
              'Thuê tủ giữ đồ',
              'Chọn ô trống → Thuê tủ → chọn số giờ → thanh toán → PIN dùng nhiều lần tới hết hạn.',
            ),
            _helpRow(
              LucideIcons.doorOpen,
              'Không mở được ô?',
              'Vào Đơn tủ → mở đơn → "Báo ô lỗi". Đội bảo trì sẽ xử lý và bạn nhận được thông báo.',
            ),
            _helpRow(
              LucideIcons.wallet,
              'Nạp ví / thanh toán',
              'Nạp qua VNPay ở Trang chủ; khi thanh toán đơn có thể chọn Ví, VNPay, MoMo hoặc Tiền mặt.',
            ),
          ],
        ),
      ),
    );
  }

  Widget _helpRow(IconData icon, String title, String body) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: AISLShadcnTheme.navyPrimary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  body,
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: Color(0xFF64748B),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _handleContact() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 4, 24, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Liên hệ hỗ trợ',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 14),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(
                LucideIcons.mail,
                color: AISLShadcnTheme.navyPrimary,
              ),
              title: const Text('Email hỗ trợ'),
              subtitle: const Text('huynqbse180211@fpt.edu.vn'),
              onTap: () => launchUrl(
                Uri.parse(
                  'mailto:huynqbse180211@fpt.edu.vn?subject=Lockerly%20-%20Ho%20tro',
                ),
              ),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(
                LucideIcons.globe,
                color: AISLShadcnTheme.navyPrimary,
              ),
              title: const Text('Website'),
              subtitle: const Text('locker-drone.tech'),
              onTap: () => launchUrl(
                Uri.parse('https://locker-drone.tech'),
                mode: LaunchMode.externalApplication,
              ),
            ),
            const ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                LucideIcons.clock,
                color: AISLShadcnTheme.navyPrimary,
              ),
              title: Text('Giờ hỗ trợ'),
              subtitle: Text('08:00 – 22:00 hằng ngày'),
            ),
          ],
        ),
      ),
    );
  }

  void _handleTerms() {
    if (!mounted) return;
    context.push(
      AppRouter.policy,
      extra: {
        'title': 'Điều khoản sử dụng',
        'assetPath': 'assets/markdown/terms_of_service.md',
      },
    );
  }

  void _handlePrivacy() {
    if (!mounted) return;
    context.push(
      AppRouter.policy,
      extra: {
        'title': 'Chính sách bảo mật',
        'assetPath': 'assets/markdown/privacy_policy.md',
      },
    );
  }

  /// Show snackbar with white background and dark text for profile page
  void _showProfileSnackBar(String message) {
    if (!mounted) return;
    SmartDialog.showToast(
      '',
      alignment: Alignment.center,
      builder: (context) => Container(
        margin: const EdgeInsets.symmetric(horizontal: 40),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          message,
          style: const TextStyle(
            color: Colors.black87,
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  void _handleLogout() {
    showCupertinoDialog<void>(
      context: context,
      builder: (dialogContext) => CupertinoAlertDialog(
        title: const Text('Đăng xuất'),
        content: const Text('Bạn có chắc chắn muốn đăng xuất khỏi tài khoản?'),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Hủy'),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              await TokenService.clearTokens();
              setState(() {
                _userData = null;
                _isLoggedIn = false;
              });
              _showProfileSnackBar('Đã đăng xuất');
            },
            child: const Text('Đăng xuất'),
          ),
        ],
      ),
    );
  }

}

// ── Theme picker bottom sheet ──────────────────────────────────────────────────

class _ThemePickerSheet extends StatelessWidget {
  final ThemeMode current;
  const _ThemePickerSheet({required this.current});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF0A2342) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final mutedColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: mutedColor.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Text(
            'Giao diện',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: textColor,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Chọn chủ đề hiển thị cho ứng dụng',
            style: TextStyle(fontSize: 13, color: mutedColor),
          ),
          const SizedBox(height: 20),
          _ThemeOption(
            icon: LucideIcons.sun,
            label: 'Sáng',
            description: 'Giao diện nền trắng',
            selected: current == ThemeMode.light,
            onTap: () {
              context.read<ThemeProvider>().setThemeMode(ThemeMode.light);
              Navigator.pop(context);
            },
          ),
          const SizedBox(height: 10),
          _ThemeOption(
            icon: LucideIcons.moon,
            label: 'Tối',
            description: 'Giao diện nền tối',
            selected: current == ThemeMode.dark,
            onTap: () {
              context.read<ThemeProvider>().setThemeMode(ThemeMode.dark);
              Navigator.pop(context);
            },
          ),
          const SizedBox(height: 10),
          _ThemeOption(
            icon: LucideIcons.monitorSmartphone,
            label: 'Theo hệ thống',
            description: 'Tự động theo cài đặt thiết bị',
            selected: current == ThemeMode.system,
            onTap: () {
              context.read<ThemeProvider>().setThemeMode(ThemeMode.system);
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }
}

class _ThemeOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final String description;
  final bool selected;
  final VoidCallback onTap;

  const _ThemeOption({
    required this.icon,
    required this.label,
    required this.description,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final navy = const Color(0xFF003D5B);
    final selectedBg = navy.withValues(alpha: isDark ? 0.35 : 0.08);
    final borderColor = selected
        ? navy.withValues(alpha: isDark ? 0.7 : 0.4)
        : (isDark ? const Color(0xFF1E4976) : const Color(0xFFE2E8F0));
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final mutedColor =
        isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: selected ? selectedBg : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor, width: selected ? 1.5 : 1),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: selected
                    ? navy.withValues(alpha: 0.12)
                    : (isDark
                        ? const Color(0xFF0D2B4A)
                        : const Color(0xFFF0F4F8)),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon,
                  size: 20, color: selected ? navy : mutedColor),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: textColor,
                    ),
                  ),
                  Text(
                    description,
                    style: TextStyle(fontSize: 12, color: mutedColor),
                  ),
                ],
              ),
            ),
            if (selected)
              Icon(LucideIcons.circleCheck, size: 20, color: navy),
          ],
        ),
      ),
    );
  }
}
