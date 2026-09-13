import 'dart:io';

import 'package:smart_laundry_locker/core/constants/app_colors.dart';
import 'package:smart_laundry_locker/core/network/api_client.dart';
import 'package:smart_laundry_locker/features/profile/domain/entities/user_profile.dart';
import 'package:smart_laundry_locker/features/profile/infrastructure/data_sources/profile_remote_data_source_impl.dart';
import 'package:smart_laundry_locker/features/profile/infrastructure/repositories/profile_repository_impl.dart';
import 'package:smart_laundry_locker/features/profile/presentation/providers/profile_injection.dart';
import 'package:smart_laundry_locker/features/profile/presentation/providers/profile_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

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
      _fullNameController.text = widget.profile!.fullName;
      _phoneController.text = widget.profile!.phoneNumber;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _profileProvider.loadProfile();
    });
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _profileProvider.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    await _profileProvider.updateProfile(
      fullName: _fullNameController.text.trim(),
      phoneNumber: _phoneController.text.trim(),
    );

    if (!mounted) return;

    if (_profileProvider.isSuccess) {
      SmartDialog.showToast('Cập nhật thành công!');
      Navigator.of(context).pop(true);
    } else if (_profileProvider.error != null) {
      SmartDialog.showToast(_profileProvider.error!);
    }
  }

  Future<void> _handlePickAvatar() async {
    if (_isUploadingAvatar) return;

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
                title: const Text('Chụp ảnh'),
                onTap: () => Navigator.of(context).pop(ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Chọn từ thư viện'),
                onTap: () => Navigator.of(context).pop(ImageSource.gallery),
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
      SmartDialog.showToast('Không xác định được tài khoản để cập nhật ảnh');
      return;
    }

    setState(() {
      _isUploadingAvatar = true;
    });
    SmartDialog.showLoading(msg: 'Đang cập nhật ảnh đại diện...');

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
        SmartDialog.showToast('Cập nhật ảnh đại diện thành công');
      },
    );

    if (!mounted) return;
    setState(() {
      _isUploadingAvatar = false;
      _localAvatarFile = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _profileProvider,
      child: Scaffold(
        backgroundColor: AppColors.white,
        appBar: AppBar(
          backgroundColor: AppColors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.onBackground),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: const Text(
            'Chỉnh sửa hồ sơ',
            style: TextStyle(
              color: AppColors.onBackground,
              fontWeight: FontWeight.w600,
            ),
          ),
          centerTitle: false,
          actions: [
            Consumer<ProfileProvider>(
              builder: (context, provider, child) {
                return TextButton(
                  onPressed: provider.isLoading ? null : _handleSave,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                  child: Text(
                    'Lưu',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: provider.isLoading
                          ? AppColors.grey400
                          : AppColors.primary,
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
              final effectiveProfile = provider.profile ?? widget.profile;

              if (widget.profile == null && provider.profile != null) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (_fullNameController.text.isEmpty) {
                    _fullNameController.text = provider.profile!.fullName;
                  }
                  if (_phoneController.text.isEmpty) {
                    _phoneController.text = provider.profile!.phoneNumber;
                  }
                });
              }

              if (widget.profile == null &&
                  provider.isLoading &&
                  provider.profile == null) {
                return const Center(child: CircularProgressIndicator());
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
                        child: const Text('Thử lại'),
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
                      const Text(
                        'Họ và tên',
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
                          hintText: 'Nhập họ và tên',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Vui lòng nhập họ và tên';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 20),

                      // Số điện thoại
                      const Text(
                        'Số điện thoại',
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
                          hintText: 'Nhập số điện thoại',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Vui lòng nhập số điện thoại';
                          }
                          if (value.trim().length < 9) {
                            return 'Số điện thoại không hợp lệ';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
