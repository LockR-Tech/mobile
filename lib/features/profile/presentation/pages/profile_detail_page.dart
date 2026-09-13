import 'package:smart_laundry_locker/core/constants/app_colors.dart';
import 'package:smart_laundry_locker/core/network/api_client.dart';
import 'package:smart_laundry_locker/core/routing/app_router.dart';
import 'package:smart_laundry_locker/features/profile/presentation/providers/profile_injection.dart';
import 'package:smart_laundry_locker/features/profile/presentation/providers/profile_provider.dart';
import 'package:smart_laundry_locker/features/profile/presentation/widgets/profile_input_card.dart';
import 'package:smart_laundry_locker/features/profile/domain/entities/user_profile.dart';
import 'package:smart_laundry_locker/shared/widgets/app_cached_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

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
        appBar: AppBar(
          backgroundColor: const Color(0xFFFF9F43),
          elevation: 2,
          systemOverlayStyle: SystemUiOverlayStyle.light,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: const Text(
            'Thông tin cá nhân',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
          ),
          centerTitle: false,
          actions: [
            Consumer<ProfileProvider>(
              builder: (context, provider, child) {
                final enabled = !provider.isLoading && provider.profile != null;
                return IconButton(
                  onPressed: enabled
                      ? () async {
                          final updated = await context.push(
                            AppRouter.editProfile,
                            extra: provider.profile,
                          );
                          if (updated == true && mounted) {
                            await provider.loadProfile();
                          }
                        }
                      : null,
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Icon(
                      LucideIcons.pencil,
                      size: 20,
                      color: enabled
                          ? Colors.white
                          : Colors.white.withOpacity(0.5),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
        body: SafeArea(
          child: Consumer<ProfileProvider>(
            builder: (context, provider, child) {
              if (provider.isLoading && provider.profile == null) {
                return const Center(child: CircularProgressIndicator());
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
                        child: const Text('Thử lại'),
                      ),
                    ],
                  ),
                );
              }

              final profile = provider.profile;
              if (profile == null) {
                return const Center(child: Text('Không có dữ liệu'));
              }

              final String statusLabel = profile.status == UserStatus.ACTIVE
                  ? 'Trạng thái tài khoản: Đang hoạt động'
                  : 'Trạng thái tài khoản: Đang bị khóa';

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
                          children: const [
                            Icon(
                              Icons.warning_amber_rounded,
                              color: Colors.amber,
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Tài khoản của bạn hiện đang bị vô hiệu hóa kỹ thuật. Vui lòng liên hệ hỗ trợ.',
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
                            const SizedBox(height: 12),
                            Text(
                              profile.isVerified
                                  ? 'Tài khoản đã xác thực'
                                  : 'Tài khoản chưa xác thực',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: profile.isVerified
                                    ? Colors.green
                                    : AppColors.error,
                              ),
                            ),
                            const SizedBox(height: 8),
                            // Badge trạng thái mới
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: profile.status == UserStatus.ACTIVE
                                    ? Colors.green.shade50
                                    : AppColors.error.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (profile.status == UserStatus.ACTIVE) ...[
                                    Container(
                                      width: 6,
                                      height: 6,
                                      decoration: BoxDecoration(
                                        color: Colors.green.shade700,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                  ] else ...[
                                    Container(
                                      width: 6,
                                      height: 6,
                                      decoration: BoxDecoration(
                                        color: AppColors.error,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                  ],
                                  Text(
                                    statusLabel,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: profile.status == UserStatus.ACTIVE
                                          ? Colors.green.shade700
                                          : AppColors.error,
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
                      label: 'Email của bạn',
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
                      label: 'Số điện thoại',
                      value: profile.phoneNumber,
                      hintText: 'Chưa cập nhật',
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
                    ProfileInputCard(
                      label: 'Mật khẩu',
                      value: 'password',
                      hintText: '••••••••••••',
                      leadingIcon: Icons.lock_outline_rounded,
                      trailingIcon: Icons.lock_rounded,
                      isPassword: true,
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
      ),
    );
  }
}
