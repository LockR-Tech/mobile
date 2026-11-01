import 'package:smart_laundry_locker/core/constants/app_colors.dart';
import 'package:smart_laundry_locker/core/network/api_client.dart';
import 'package:smart_laundry_locker/core/routing/app_router.dart';
import 'package:smart_laundry_locker/features/profile/presentation/providers/profile_injection.dart';
import 'package:smart_laundry_locker/features/profile/presentation/providers/profile_provider.dart';
import 'package:smart_laundry_locker/features/profile/presentation/widgets/profile_input_card.dart';
import 'package:smart_laundry_locker/features/profile/domain/entities/user_profile.dart';
import 'package:smart_laundry_locker/shared/widgets/app_cached_image.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_laundry_locker/shared/shared.dart';
import 'package:smart_laundry_locker/shared/widgets/user_ui_kit.dart';
import 'package:smart_laundry_locker/core/l10n/l10n.dart';

class ProfileDetailPage extends StatefulWidget {
  const ProfileDetailPage({super.key});

  @override
  State<ProfileDetailPage> createState() => _ProfileDetailPageState();
}

class _ProfileDetailPageState extends State<ProfileDetailPage> {
  late ProfileProvider _profileProvider;
  bool _showEmail = false;
  bool _showPhone = false;

  @override
  void initState() {
    super.initState();
    final apiClient = ApiClient();
    _profileProvider = ProfileInjection.provideProfileProvider(apiClient);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _profileProvider.loadProfile();
    });
  }

  @override
  void dispose() {
    _profileProvider.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _profileProvider,
      child: Scaffold(
        backgroundColor: AppColors.white,
        body: Column(
          children: [
            BrandHeroHeader(
              title: context.l10n.pdTitle,
              subtitle: context.l10n.pdSubtitle,
              onBack: () => Navigator.of(context).pop(),
              trailing: Consumer<ProfileProvider>(
                builder: (context, provider, child) {
                  final enabled = !provider.isLoading && provider.profile != null;
                  return BrandCircleIconButton(
                    icon: LucideIcons.pencil,
                    iconSize: 18,
                    onTap: () async {
                      if (!enabled) return;
                      final updated = await context.push(
                        AppRouter.editProfile,
                        extra: provider.profile,
                      );
                      if (updated == true && mounted) {
                        await provider.loadProfile();
                        // Đồng bộ ProfileProvider dùng chung (trang Hồ sơ,
                        // trang chủ) — `this.context` nằm ngoài provider cục bộ.
                        if (mounted) {
                          this.context.read<ProfileProvider>().loadProfile();
                        }
                      }
                    },
                  );
                },
              ),
            ),
            Expanded(
              child: Consumer<ProfileProvider>(
            builder: (context, provider, child) {
              if (provider.isLoading && provider.profile == null) {
                return Center(
                  child: AppLoadingIndicator(message: context.l10n.storeInfoLoading),
                );
              }

              // hiện error khi không có profile data
              if (provider.error != null && provider.profile == null) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        provider.error!,
                        style: const TextStyle(color: AppColors.error),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => provider.loadProfile(),
                        child: Text(context.l10n.commonRetry),
                      ),
                    ],
                  ),
                );
              }

              final profile = provider.profile;
              if (profile == null) {
                return Center(child: Text(context.l10n.pdNoData));
              }

              final String statusLabel;
              final Color statusColor;
              final Color statusBgColor;

              switch (profile.status) {
                case UserStatus.ACTIVE:
                  statusLabel = context.l10n.pdStatusActive;
                  statusColor = Colors.green.shade700;
                  statusBgColor = Colors.green.shade50;
                  break;
                case UserStatus.INACTIVE:
                  statusLabel = context.l10n.pdStatusInactive;
                  statusColor = Colors.orange.shade800;
                  statusBgColor = Colors.orange.shade50;
                  break;
                case UserStatus.BLOCKED:
                  statusLabel = context.l10n.pdStatusLocked;
                  statusColor = AppColors.error;
                  statusBgColor = AppColors.error.withOpacity(0.12);
                  break;
              }

              return SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (!profile.isActive) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade100,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.amber.shade400),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.warning_amber_rounded,
                              color: Colors.amber,
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                context.l10n.pdDisabled,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AppColors.onBackground,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 16),

                    // Avatar + tên + trạng thái (khối nền header)
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(top: 4),
                      padding: const EdgeInsets.symmetric(
                        vertical: 24,
                        horizontal: 16,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Center(
                        child: Column(
                          children: [
                            ProfileAvatar(
                              imageUrl: profile.avatarUrl,
                              userId: profile.id,
                              avatarVersion: 0,
                              size: 128,
                              fallbackText: profile.fullName,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              profile.fullName,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: AppColors.onBackground,
                              ),
                            ),
                            // Backend không có cờ "đã xác thực" cho hồ sơ nên
                            // không hiện dòng "Tài khoản chưa xác thực" giả.
                            const SizedBox(height: 12),
                            // Badge trạng thái mới
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: statusBgColor,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 6,
                                    height: 6,
                                    decoration: BoxDecoration(
                                      color: statusColor,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    statusLabel,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: statusColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Email
                    ProfileInputCard(
                      label: context.l10n.pdYourEmail,
                      value: profile.email,
                      hintText: 'name@example.com',
                      leadingIcon: Icons.email_rounded,
                      trailing: IconButton(
                        icon: Icon(
                          _showEmail ? LucideIcons.eye : LucideIcons.eyeOff,
                          size: 20,
                          color: _showEmail
                              ? AppColors.primary
                              : AppColors.onSurfaceVariant,
                        ),
                        onPressed: () {
                          setState(() {
                            _showEmail = !_showEmail;
                          });
                        },
                      ),
                      obscured: !_showEmail,
                    ),

                    const SizedBox(height: 22),

                    // Phone
                    ProfileInputCard(
                      label: context.l10n.commonPhoneNumber,
                      value: profile.phoneNumber,
                      hintText: context.l10n.pdNotUpdated,
                      leadingIcon: Icons.phone_rounded,
                      trailing: IconButton(
                        icon: Icon(
                          _showPhone ? LucideIcons.eye : LucideIcons.eyeOff,
                          size: 20,
                          color: _showPhone
                              ? AppColors.primary
                              : AppColors.onSurfaceVariant,
                        ),
                        onPressed: () {
                          setState(() {
                            _showPhone = !_showPhone;
                          });
                        },
                      ),
                      obscured: !_showPhone,
                    ),

                    const SizedBox(height: 22),

                    // Password
                    GestureDetector(
                      onTap: () => context.push(AppRouter.security),
                      child: ProfileInputCard(
                        label: profile.hasPassword
                            ? context.l10n.commonPassword
                    : context.l10n.pdPasswordNotSet,
                        value: profile.hasPassword ? 'password' : '',
                        hintText: profile.hasPassword ? '••••••••••••' : context.l10n.pdNotSet,
                        leadingIcon: Icons.lock_outline_rounded,
                        trailing: const Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 16,
                          color: AppColors.onSurfaceVariant,
                        ),
                        isPassword: true,
                      ),
                    ),

                    const SizedBox(height: 24),

                    if (provider.error != null) ...[
                      const SizedBox(height: 16),
                      Text(
                        provider.error!,
                        style: const TextStyle(
                          color: AppColors.error,
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],

                    const SizedBox(height: 30),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    ),
  ),
);
  }
}
