import 'dart:io';

import 'package:smart_laundry_locker/core/constants/app_colors.dart';
import 'package:smart_laundry_locker/core/network/api_client.dart';
import 'package:smart_laundry_locker/features/profile/domain/entities/user_profile.dart';
import 'package:smart_laundry_locker/features/profile/domain/utils/person_name.dart';
import 'package:smart_laundry_locker/features/profile/infrastructure/data_sources/profile_remote_data_source_impl.dart';
import 'package:smart_laundry_locker/features/profile/infrastructure/repositories/profile_repository_impl.dart';
import 'package:smart_laundry_locker/features/profile/presentation/providers/profile_injection.dart';
import 'package:smart_laundry_locker/features/profile/presentation/providers/profile_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:smart_laundry_locker/shared/shared.dart';
import 'package:smart_laundry_locker/shared/widgets/user_ui_kit.dart';
import 'package:smart_laundry_locker/core/l10n/l10n.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key, this.profile});

  final UserProfile? profile;

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();

  late ProfileProvider _profileProvider;
  File? _localAvatarFile;
  bool _isUploadingAvatar = false;

  @override
  void initState() {
    super.initState();

    final apiClient = ApiClient();
    _profileProvider = ProfileInjection.provideProfileProvider(apiClient);

    if (widget.profile != null) {
      _fillForm(widget.profile!);
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _profileProvider.loadProfile();
    });
  }

  /// Tên mặc định ("Customer" của tài khoản OTP mới) không điền sẵn để người
  /// dùng nhập tên thật thay vì lưu lại tên giả.
  void _fillForm(UserProfile profile) {
    _fullNameController.text =
        isPlaceholderName(profile.fullName) ? '' : profile.fullName;
    _phoneController.text = profile.phoneNumber;
    _emailController.text = profile.email;
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _profileProvider.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final current = _profileProvider.profile ?? widget.profile;
    final phone = _phoneController.text.trim();
    final email = _emailController.text.trim();
    await _profileProvider.updateProfile(
      fullName: _fullNameController.text.trim(),
      // Chỉ gửi định danh khi đổi — backend kiểm trùng rồi đồng bộ sang tài
      // khoản đăng nhập, không cần làm việc đó khi giữ nguyên.
      phoneNumber: phone != (current?.phoneNumber ?? '') ? phone : null,
      email: email.isNotEmpty && email != (current?.email ?? '') ? email : null,
    );

    if (!mounted) return;

    if (_profileProvider.isSuccess) {
      SmartDialog.showToast(context.l10n.epUpdated);
      Navigator.of(context).pop(true);
    } else if (_profileProvider.error != null) {
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(context.l10n.epSaveFailed),
          content: Text(_profileProvider.error!),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(context.l10n.commonClose),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _handlePickAvatar() async {
    if (_isUploadingAvatar) return;

    final currentAvatar =
        (_profileProvider.profile ?? widget.profile)?.avatarUrl ?? '';
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_camera_outlined),
                title: Text(context.l10n.epTakePhoto),
                onTap: () => Navigator.of(context).pop(ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: Text(context.l10n.epFromGallery),
                onTap: () => Navigator.of(context).pop(ImageSource.gallery),
              ),
              if (currentAvatar.isNotEmpty)
                ListTile(
                  leading: const Icon(
                    Icons.delete_outline,
                    color: AppColors.error,
                  ),
                  title: Text(
                    context.l10n.epRemoveAvatar,
                    style: TextStyle(color: AppColors.error),
                  ),
                  onTap: () {
                    Navigator.of(context).pop();
                    _handleDeleteAvatar();
                  },
                ),
            ],
          ),
        );
      },
    );

    if (source == null) return;

    final picked = await _imagePicker.pickImage(
      source: source,
      imageQuality: 85,
      maxWidth: 1200,
      maxHeight: 1200,
    );
    if (picked == null || !mounted) return;

    setState(() {
      _localAvatarFile = File(picked.path);
    });

    final userId = _profileProvider.profile?.id ?? widget.profile?.id;
    if (userId == null || userId.isEmpty) {
      SmartDialog.showToast(context.l10n.epNoAccountPhoto);
      return;
    }

    setState(() {
      _isUploadingAvatar = true;
    });
    SmartDialog.showLoading(msg: context.l10n.epUpdatingAvatar);

    final repository = ProfileRepositoryImpl(
      remoteDataSource: ProfileRemoteDataSourceImpl(ApiClient()),
    );
    final result = await repository.uploadAvatar(
      userId: userId,
      filePath: picked.path,
    );

    if (!mounted) return;
    SmartDialog.dismiss();

    result.fold(
      (failure) {
        SmartDialog.showToast(failure.message);
      },
      (_) async {
        await _profileProvider.loadProfile();
        SmartDialog.showToast(L10n.current.epAvatarUpdated);
      },
    );

    if (!mounted) return;
    setState(() {
      _isUploadingAvatar = false;
      _localAvatarFile = null;
    });
  }

  Future<void> _handleDeleteAvatar() async {
    if (_isUploadingAvatar) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.l10n.epRemoveQuestion),
        content: Text(context.l10n.epRemoveBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(context.l10n.commonCancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(context.l10n.commonDelete, style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _isUploadingAvatar = true);
    SmartDialog.showLoading(msg: context.l10n.epRemoving);
    final repository = ProfileRepositoryImpl(
      remoteDataSource: ProfileRemoteDataSourceImpl(ApiClient()),
    );
    final result = await repository.deleteAvatar();
    SmartDialog.dismiss();
    if (!mounted) return;

    await result.fold(
      (failure) async => SmartDialog.showToast(failure.message),
      (_) async {
        await _profileProvider.loadProfile();
        SmartDialog.showToast(L10n.current.epRemoved);
      },
    );
    if (!mounted) return;
    setState(() => _isUploadingAvatar = false);
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
              title: context.l10n.epTitle,
              subtitle: context.l10n.epSubtitle,
              onBack: () => Navigator.of(context).pop(),
              trailing: Consumer<ProfileProvider>(
                builder: (context, provider, child) {
                  return GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: provider.isLoading ? null : _handleSave,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: provider.isLoading
                            ? Colors.white.withValues(alpha: 0.1)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        context.l10n.commonSave,
                        style: TextStyle(
                          color: provider.isLoading
                              ? Colors.white54
                              : const Color(0xFF14171F),
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            Expanded(
              child: Consumer<ProfileProvider>(
            builder: (context, provider, child) {
              final effectiveProfile = provider.profile ?? widget.profile;

              if (widget.profile == null && provider.profile != null) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (_fullNameController.text.isEmpty &&
                      _phoneController.text.isEmpty &&
                      _emailController.text.isEmpty) {
                    _fillForm(provider.profile!);
                  }
                });
              }

              if (widget.profile == null &&
                  provider.isLoading &&
                  provider.profile == null) {
                return Center(
                  child: AppLoadingIndicator(message: context.l10n.storeInfoLoading),
                );
              }

              if (widget.profile == null &&
                  provider.error != null &&
                  provider.profile == null) {
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

              return SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 8),

                      // Avatar + nút đổi ảnh
                      Center(
                        child: Stack(
                          children: [
                            CircleAvatar(
                              radius: 56,
                              backgroundColor: AppColors.grey200,
                              backgroundImage: _localAvatarFile != null
                                  ? FileImage(_localAvatarFile!)
                                  : (effectiveProfile?.avatarUrl != null &&
                                        effectiveProfile!.avatarUrl!.isNotEmpty)
                                  ? NetworkImage(effectiveProfile.avatarUrl!)
                                  : null,
                              child:
                                  _localAvatarFile == null &&
                                      (effectiveProfile?.avatarUrl == null ||
                                          effectiveProfile!.avatarUrl!.isEmpty)
                                  ? Text(
                                      (effectiveProfile?.fullName ?? 'N')
                                          .trim()
                                          .substring(0, 1)
                                          .toUpperCase(),
                                      style: const TextStyle(
                                        fontSize: 32,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.onBackground,
                                      ),
                                    )
                                  : null,
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                decoration: const BoxDecoration(
                                  color: AppColors.primary,
                                  shape: BoxShape.circle,
                                ),
                                child: IconButton(
                                  icon: const Icon(
                                    Icons.camera_alt_rounded,
                                    size: 18,
                                    color: AppColors.white,
                                  ),
                                  padding: const EdgeInsets.all(4),
                                  constraints: const BoxConstraints(
                                    minWidth: 32,
                                    minHeight: 32,
                                  ),
                                  onPressed: _isUploadingAvatar
                                      ? null
                                      : _handlePickAvatar,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Họ và tên
                      Text(
                        context.l10n.commonFullName,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _fullNameController,
                        decoration: InputDecoration(
                          prefixIcon: const Icon(
                            Icons.person_outline_rounded,
                            color: AppColors.onSurfaceVariant,
                          ),
                          filled: true,
                          fillColor: AppColors.grey100,
                          hintText: context.l10n.epNameHint,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return context.l10n.authEnterFullName;
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 20),

                      // Số điện thoại
                      Text(
                        context.l10n.commonPhoneNumber,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: InputDecoration(
                          prefixIcon: const Icon(
                            Icons.phone_rounded,
                            color: AppColors.onSurfaceVariant,
                          ),
                          filled: true,
                          fillColor: AppColors.grey100,
                          hintText: context.l10n.epPhoneHint,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            // Tài khoản Google chưa có SĐT vẫn lưu được tên;
                            // đã có SĐT thì không xoá được (backend giữ nguyên).
                            final hadPhone = (effectiveProfile?.phoneNumber ?? '')
                                .trim()
                                .isNotEmpty;
                            return hadPhone ? context.l10n.authEnterPhone : null;
                          }
                          if (!RegExp(r'^\+?[0-9]{9,12}$')
                              .hasMatch(value.trim())) {
                            return context.l10n.epInvalidPhone;
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 20),

                      // Email
                      const Text(
                        'Email',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        autocorrect: false,
                        decoration: InputDecoration(
                          prefixIcon: const Icon(
                            Icons.email_outlined,
                            color: AppColors.onSurfaceVariant,
                          ),
                          filled: true,
                          fillColor: AppColors.grey100,
                          hintText: context.l10n.epEmailHint,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        validator: (value) {
                          final email = (value ?? '').trim();
                          if (email.isEmpty) return null;
                          if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
                              .hasMatch(email)) {
                            return context.l10n.authInvalidEmail;
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 10),
                      Text(
                        context.l10n.epLoginInfoNote,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),

                      const SizedBox(height: 32),
                    ],
                  ),
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
