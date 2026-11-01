import 'dart:io';

import 'package:smart_laundry_locker/core/config/feature_flags.dart';
import 'package:smart_laundry_locker/core/services/session_service.dart';
import 'package:smart_laundry_locker/core/services/token_service.dart';
import 'package:smart_laundry_locker/features/notifications/presentation/providers/notification_provider.dart';
import 'package:smart_laundry_locker/core/network/api_client.dart';
import 'package:smart_laundry_locker/features/profile/presentation/providers/profile_provider.dart';
import 'package:smart_laundry_locker/features/delegations/presentation/providers/delegation_provider.dart';
import 'package:smart_laundry_locker/features/delegations/presentation/providers/delegation_injection.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_laundry_locker/core/routing/app_router.dart';
import 'package:smart_laundry_locker/features/locker_ops/data/locker_ops_service.dart';
import 'package:smart_laundry_locker/core/theme/shadcn_theme.dart';
import 'package:smart_laundry_locker/core/theme/theme_provider.dart';
import 'package:smart_laundry_locker/core/l10n/locale_provider.dart';
import 'package:smart_laundry_locker/core/services/app_restart_service.dart';
import 'package:smart_laundry_locker/features/assistant/presentation/providers/assistant_availability.dart';
import 'package:smart_laundry_locker/features/profile/presentation/mixins/profile_image_actions_mixin.dart';
import 'package:smart_laundry_locker/features/profile/presentation/pages/location_permission_page.dart';
import 'package:smart_laundry_locker/features/profile/presentation/pages/loyalty_page.dart';
import 'package:smart_laundry_locker/features/profile/presentation/widgets/profile_header.dart';
import 'package:smart_laundry_locker/features/profile/presentation/widgets/profile_menu_item.dart';
import 'package:smart_laundry_locker/shared/shared.dart';
import 'package:smart_laundry_locker/shared/widgets/user_ui_kit.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:smart_laundry_locker/core/l10n/l10n.dart';

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
  bool isAvatarSyncing = false;

  // User data
  Map<String, dynamic>? _userData;
  bool _isLoading = true;
  bool _isLoggedIn = false;

  /// Admin đã cho tài khoản thử mở ô qua Bluetooth ở ít nhất một tủ (F3-G11).
  bool _bleTestAllowed = false;

  /// Có token nhưng `GET /api/user/profile` lỗi (mạng, 5xx, 404…). Hiện lỗi +
  /// "Thử lại" thay vì coi như chưa đăng nhập rồi đá ra màn đăng nhập. Phiên
  /// hết hạn thật (401 không làm mới được) thì AuthInterceptor tự đăng xuất.
  String? _loadError;
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
          _loadError = null;
          _bleTestAllowed = false;
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
      _loadError = null;
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

    if (!_profileProvider.hasServerProfile) {
      // Hết phiên (AuthInterceptor đã xoá token) ⇒ coi như đã đăng xuất.
      final stillHasToken = await TokenService.hasToken();
      if (!mounted) return;
      setState(() {
        _loadError = stillHasToken
            ? (_profileProvider.error ?? context.l10n.profileLoadFailedDot)
            : null;
        _isLoggedIn = stillHasToken && _isLoggedIn;
        _isLoading = false;
      });
      return;
    }
    if (forceRefresh && _profileProvider.error != null) {
      // Đã có hồ sơ cũ nhưng làm mới lỗi: vẫn hiện dữ liệu cũ, báo lỗi.
      _showProfileSnackBar(
        context.l10n.profileRefreshFailed('${_profileProvider.error}'),
      );
    }

    final isLoggedIn = _profileProvider.profile != null;

    if (isLoggedIn) {
      // Nạp trước trạng thái trợ lý cho mục "Trợ giúp" (không chờ).
      AssistantAvailability.instance.refresh();
      _loadBleTestAccess();
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

  /// Không chờ, lỗi thì coi như chưa được cấp (ẩn nút).
  Future<void> _loadBleTestAccess() async {
    var allowed = false;
    try {
      allowed = (await LockerOpsService().bleTestLockers()).isNotEmpty;
    } catch (_) {}
    if (mounted && allowed != _bleTestAllowed) {
      setState(() => _bleTestAllowed = allowed);
    }
  }

  @override
  String? get currentUserIdForAvatar => _userData?['id'] as String?;

  @override
  Widget build(BuildContext context) {
    // Show loading
    if (_isLoading) {
      return Scaffold(
        backgroundColor: context.pageBg,
        body: Column(
          children: [
            BrandHeroHeader(
              title: context.l10n.profileTitle,
              subtitle: context.l10n.profileSubtitle,
            ),
            Expanded(
              child: Center(
                child: AppLoadingIndicator(
                  message: context.l10n.profileLoading,
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (_loadError != null) {
      return Scaffold(
        backgroundColor: context.pageBg,
        body: Column(
          children: [
            BrandHeroHeader(
              title: context.l10n.profileTitle,
              subtitle: context.l10n.profileSubtitle,
            ),
            Expanded(child: _buildLoadErrorState(_loadError!)),
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
        body: const Center(child: AppLoadingIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: context.pageBg,
      body: MultiProvider(
        providers: [ChangeNotifierProvider.value(value: _delegationProvider)],
        child: Column(
          children: [
            BrandHeroHeader(
              title: context.l10n.profileTitle,
              subtitle: context.l10n.profileSubtitle,
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
                color: const Color.fromARGB(255, 191, 199, 209),
                backgroundColor: const Color.fromARGB(255, 220, 228, 238),
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Column(
                    children: [
                      const SizedBox(height: 12),

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
                          onEditProfile: _handleEditProfile,
                        ),

                      const SizedBox(height: 16),

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

  Widget _buildLoadErrorState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(LucideIcons.cloudOff, size: 56, color: context.textMuted),
            const SizedBox(height: 16),
            Text(
              context.l10n.profileLoadFailed,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13.5, color: context.textMuted),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: () => _loadUserProfile(forceRefresh: true),
              style: FilledButton.styleFrom(
                backgroundColor: AISLShadcnTheme.navyPrimary,
              ),
              icon: const Icon(LucideIcons.refreshCw, size: 16),
              label: Text(context.l10n.commonRetry),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: _handleLogout,
              child: Text(
                context.l10n.commonLogout,
                style: TextStyle(
                  color: ShadTheme.of(context).colorScheme.destructive,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuSection() {
    final l10n = context.l10n;
    return Column(
      children: [
        // Account section
        _buildMenuGroup(
          title: l10n.profileSectionAccount,
          items: [
            ProfileMenuItem(
              icon: LucideIcons.user,
              title: l10n.profilePersonalInfo,
              onTap: _handleEditProfile,
            ),
            ProfileMenuItem(
              icon: LucideIcons.landmark,
              title: l10n.profileRefundAccount,
              onTap: () => context.push(AppRouter.refundBankAccount),
            ),
            ProfileMenuItem(
              icon: LucideIcons.sparkles,
              title: l10n.profileLoyalty,
              subtitle: l10n.profileLoyaltySubtitle,
              onTap: _handleLoyalty,
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
                        ? l10n.profileFaceReRegister
                        : l10n.profileFaceRegister,
                    onTap: _handleFaceRegistration,
                  );
                },
              ),
            ProfileMenuItem(
              icon: LucideIcons.shield,
              title: l10n.profileSecurity,
              onTap: _handleSecurity,
            ),
            // Kho voucher: `GET /api/promotions/vouchers/my` (mã đã lưu từ
            // trang "Ưu đãi").
            if (FeatureFlags.vouchersEnabled)
              ProfileMenuItem(
                icon: LucideIcons.ticket,
                title: l10n.profileVouchers,
                onTap: _handleMyVouchers,
              ),
            Consumer<NotificationProvider>(
              builder: (context, provider, child) {
                return ProfileMenuItem(
                  icon: LucideIcons.bell,
                  title: l10n.commonNotifications,
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
          title: l10n.profileSectionManage,
          items: [
            Consumer<DelegationProvider>(
              builder: (context, provider, child) {
                final delegations = provider.myDelegations
                    .where((d) => d.isActive)
                    .toList();

                return ProfileMenuItem(
                  icon: LucideIcons.packageOpen,
                  title: l10n.profileDelegations,
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
            ProfileMenuItem(
              icon: LucideIcons.rotateCcw,
              title: l10n.profileRefunds,
              onTap: () => context.push(AppRouter.refundRequests),
            ),
            // Lịch sử thanh toán (`GET /api/wallet/transactions` gồm cả khoản SePay của đơn).
            if (FeatureFlags.transactionsEnabled)
              ProfileMenuItem(
                leadingWidget: const SizedBox(
                  width: 26,
                  height: 26,
                  child: AppLottie(
                    AppLottieAssets.napVi,
                    fit: BoxFit.contain,
                  ),
                ),
                title: l10n.commonTransactions,
                onTap: () => context.push(AppRouter.transactions),
                trailing: const Icon(
                  LucideIcons.chevronRight,
                  size: 16,
                  color: Colors.black54,
                ),
              ),
            ProfileMenuItem(
              leadingWidget: const SizedBox(
                width: 26,
                height: 26,
                child: AppLottie(
                  AppLottieAssets.baoCao,
                  fit: BoxFit.contain,
                ),
              ),
              title: l10n.profileMyReports,
              onTap: () => context.push(AppRouter.myReports),
            ),
            if (_bleTestAllowed)
              ProfileMenuItem(
                icon: LucideIcons.bluetooth,
                title: l10n.profileBleTest,
                onTap: () => context.push(AppRouter.bleTest),
              ),
          ],
        ),
        const SizedBox(height: 8),
        const Divider(height: 1, indent: 16, endIndent: 16),
        const SizedBox(height: 8),
        // Settings section
        _buildMenuGroup(
          title: l10n.profileSectionSettings,
          items: [
            ProfileMenuItem(
              icon: LucideIcons.languages,
              title: l10n.profileLanguage,
              subtitle: LocaleProvider.instance.isEnglish
                  ? l10n.languageEnglish
                  : l10n.languageVietnamese,
              onTap: _handleLanguage,
              trailing: Icon(
                LucideIcons.chevronRight,
                size: 16,
                color: ShadTheme.of(context).colorScheme.mutedForeground,
              ),
            ),
            ProfileMenuItem(
              icon: LucideIcons.palette,
              title: l10n.profileTheme,
              onTap: _handleTheme,
              trailing: Icon(
                LucideIcons.chevronRight,
                size: 16,
                color: ShadTheme.of(context).colorScheme.mutedForeground,
              ),
            ),
            ProfileMenuItem(
              icon: LucideIcons.mapPin,
              title: l10n.profileLocation,
              subtitle: l10n.profileLocationSubtitle,
              onTap: _handleLocation,
            ),
          ],
        ),
        const SizedBox(height: 8),
        const Divider(height: 1, indent: 16, endIndent: 16),
        const SizedBox(height: 8),
        // Support section
        _buildMenuGroup(
          title: l10n.profileSectionSupport,
          items: [
            ProfileMenuItem(
              leadingWidget: Container(
                width: 38,
                height: 38,
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: const Color(0xFF2563EB).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const AppLottie(
                  AppLottieAssets.chatbox,
                  fit: BoxFit.contain,
                ),
              ),
              title: l10n.profileAssistant,
              subtitle: l10n.profileAssistantSubtitle,
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF2563EB), Color(0xFF7C3AED)],
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(LucideIcons.sparkles, size: 11, color: Colors.white),
                        SizedBox(width: 3),
                        Text(
                          'AI',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(
                    LucideIcons.chevronRight,
                    size: 18,
                    color: context.textMuted,
                  ),
                ],
              ),
              onTap: () => context.push(AppRouter.assistant),
            ),
            ProfileMenuItem(
              icon: LucideIcons.helpCircle,
              title: l10n.profileQuickHelp,
              subtitle: l10n.profileQuickHelpSubtitle,
              onTap: _showQuickHelp,
            ),
            ProfileMenuItem(
              icon: LucideIcons.messageCircle,
              title: l10n.profileContact,
              onTap: _handleContact,
            ),
            ProfileMenuItem(
              icon: LucideIcons.fileText,
              title: l10n.profileTerms,
              onTap: _handleTerms,
            ),
            ProfileMenuItem(
              icon: LucideIcons.shieldCheck,
              title: l10n.commonPrivacyPolicy,
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
              title: l10n.commonLogout,
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
                fontFamily: 'Roboto',
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

  Future<void> _handleEditProfile() async {
    if (!mounted) return;
    await context.pushNamed('profile_detail');
    // Tên/SĐT/email có thể vừa đổi ⇒ dựng lại thẻ hồ sơ.
    if (mounted) await _loadUserProfile();
  }

  void _handleFaceRegistration() {
    if (!mounted) return;
    context.push(AppRouter.faceRegistration);
  }

  void _handleSecurity() {
    if (!mounted) return;
    context.push(AppRouter.security);
  }

  void _handleMyVouchers() {
    if (!mounted) return;
    context.push(AppRouter.myVouchers);
  }

  void _handleLoyalty() {
    if (!mounted) return;
    Navigator.of(context).push<void>(
      MaterialPageRoute(builder: (_) => const LoyaltyPage()),
    );
  }

  void _handleTheme() {
    final themeProvider = context.read<ThemeProvider>();
    showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return _ThemePickerSheet(current: themeProvider.themeMode);
      },
    ).then((value) {
      // ignore
    });
  }

  /// Đổi ngôn ngữ rồi dựng lại app để mọi màn (kể cả nhãn dựng ngoài widget)
  /// đọc lại bản dịch mới.
  Future<void> _handleLanguage() async {
    final selected = await showModalBottomSheet<Locale>(
      context: context,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _LanguagePickerSheet(current: LocaleProvider.instance.locale),
    );
    if (selected == null || !mounted) return;
    if (selected.languageCode == LocaleProvider.instance.locale.languageCode) {
      return;
    }
    await LocaleProvider.instance.setLocale(selected);
    if (mounted) RestartableApp.restartApp(context);
  }

  void _handleLocation() {
    if (!mounted) return;
    Navigator.of(context).push<void>(
      MaterialPageRoute(builder: (_) => const LocationPermissionPage()),
    );
  }

  void _showQuickHelp() {
    final l10n = context.l10n;
    showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
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
            Text(
              l10n.profileQuickHelp,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 14),
            _helpRow(
              LucideIcons.packagePlus,
              l10n.profileHelpSendTitle,
              l10n.profileHelpSendBody,
            ),
            _helpRow(
              LucideIcons.lockKeyhole,
              l10n.profileHelpRentTitle,
              l10n.profileHelpRentBody,
            ),
            _helpRow(
              LucideIcons.doorOpen,
              l10n.profileHelpCantOpenTitle,
              l10n.profileHelpCantOpenBody,
            ),
            _helpRow(
              LucideIcons.wallet,
              l10n.commonPayment,
              l10n.profileHelpPaymentBody,
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
    final l10n = context.l10n;
    showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
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
            Text(
              l10n.profileContactTitle,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 14),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(
                LucideIcons.mail,
                color: AISLShadcnTheme.navyPrimary,
              ),
              title: Text(l10n.profileContactEmail),
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
              title: Text(l10n.commonWebsite),
              subtitle: const Text('locker-drone.tech'),
              onTap: () => launchUrl(
                Uri.parse('https://locker-drone.tech'),
                mode: LaunchMode.externalApplication,
              ),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(
                LucideIcons.clock,
                color: AISLShadcnTheme.navyPrimary,
              ),
              title: Text(l10n.profileContactHours),
              subtitle: Text(l10n.profileContactHoursValue),
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
        'title': context.l10n.commonTermsOfUse,
        'assetPath': 'assets/markdown/terms_of_service.md',
      },
    );
  }

  void _handlePrivacy() {
    if (!mounted) return;
    context.push(
      AppRouter.policy,
      extra: {
        'title': context.l10n.commonPrivacyPolicy,
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
              color: Colors.black.withValues(alpha: 0.1),
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
    final l10n = context.l10n;
    showCupertinoDialog<void>(
      context: context,
      builder: (dialogContext) => CupertinoAlertDialog(
        title: Text(l10n.commonLogout),
        content: Text(l10n.commonLogoutConfirm),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(l10n.commonCancel),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              // Gỡ thiết bị khỏi push + thu hồi refresh token ở server rồi mới
              // xoá token trên máy (dùng chung mọi vai trò).
              SmartDialog.showLoading(msg: l10n.commonLoggingOut);
              await SessionService.logout();
              SmartDialog.dismiss();
              _profileProvider.reset();
              if (!mounted) return;
              setState(() {
                _userData = null;
                _isLoggedIn = false;
                _loadError = null;
              });
              _showProfileSnackBar(l10n.commonLoggedOut);
            },
            child: Text(l10n.commonLogout),
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
    final mutedColor = isDark
        ? const Color(0xFF94A3B8)
        : const Color(0xFF64748B);

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
            context.l10n.profileTheme,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: textColor,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            context.l10n.profileThemeSheetSubtitle,
            style: TextStyle(fontSize: 13, color: mutedColor),
          ),
          const SizedBox(height: 20),
          _ThemeOption(
            icon: LucideIcons.sun,
            label: context.l10n.profileThemeLight,
            description: context.l10n.profileThemeLightDescription,
            selected: current == ThemeMode.light,
            onTap: () {
              context.read<ThemeProvider>().setThemeMode(ThemeMode.light);
              Navigator.pop(context);
            },
          ),
          const SizedBox(height: 10),
          _ThemeOption(
            icon: LucideIcons.moon,
            label: context.l10n.profileThemeDark,
            description: context.l10n.profileThemeDarkDescription,
            selected: current == ThemeMode.dark,
            onTap: () {
              context.read<ThemeProvider>().setThemeMode(ThemeMode.dark);
              Navigator.pop(context);
            },
          ),
          const SizedBox(height: 10),
          _ThemeOption(
            icon: LucideIcons.monitorSmartphone,
            label: context.l10n.profileThemeSystem,
            description: context.l10n.profileThemeSystemDescription,
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

// ── Language picker bottom sheet ───────────────────────────────────────────────

class _LanguagePickerSheet extends StatelessWidget {
  final Locale current;
  const _LanguagePickerSheet({required this.current});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF0A2342) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final mutedColor = isDark
        ? const Color(0xFF94A3B8)
        : const Color(0xFF64748B);

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
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
            context.l10n.profileLanguage,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: textColor,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            context.l10n.profileLanguageSheetSubtitle,
            style: TextStyle(fontSize: 13, color: mutedColor),
          ),
          const SizedBox(height: 20),
          _ThemeOption(
            icon: LucideIcons.languages,
            label: context.l10n.languageVietnamese,
            description: context.l10n.profileLanguageViDescription,
            selected: current.languageCode == L10n.vi.languageCode,
            onTap: () => Navigator.pop(context, L10n.vi),
          ),
          const SizedBox(height: 10),
          _ThemeOption(
            icon: LucideIcons.globe,
            label: context.l10n.languageEnglish,
            description: context.l10n.profileLanguageEnDescription,
            selected: current.languageCode == L10n.en.languageCode,
            onTap: () => Navigator.pop(context, L10n.en),
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
    final mutedColor = isDark
        ? const Color(0xFF94A3B8)
        : const Color(0xFF64748B);

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
              child: Icon(icon, size: 20, color: selected ? navy : mutedColor),
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
            if (selected) Icon(LucideIcons.circleCheck, size: 20, color: navy),
          ],
        ),
      ),
    );
  }
}
