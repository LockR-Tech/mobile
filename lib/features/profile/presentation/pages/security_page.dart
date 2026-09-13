import 'dart:async';

import 'package:smart_laundry_locker/core/constants/app_colors.dart';
import 'package:smart_laundry_locker/core/network/api_client.dart';
import 'package:smart_laundry_locker/core/services/biometric_service.dart';
import 'package:smart_laundry_locker/features/profile/presentation/providers/profile_injection.dart';
import 'package:smart_laundry_locker/features/profile/presentation/providers/security_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:provider/provider.dart';

class SecurityPage extends StatefulWidget {
  const SecurityPage({super.key});

  @override
  State<SecurityPage> createState() => _SecurityPageState();
}

class _SecurityPageState extends State<SecurityPage> {
  final TextEditingController _passwordController = TextEditingController();
  late final SecurityProvider _securityProvider;
  Timer? _verifyDebounce;

  String? _email;
  bool _obscurePassword = true;
  bool _isLoadingProfile = true;

  // Khóa ứng dụng bằng sinh trắc học thiết bị (vân tay/khuôn mặt OS).
  bool _bioSupported = false;
  bool _bioEnabled = false;

  @override
  void initState() {
    super.initState();
    _securityProvider = ProfileInjection.provideSecurityProvider(ApiClient());
    _loadCurrentUserEmail();
    _loadBiometricState();
  }

  Future<void> _loadBiometricState() async {
    final supported = await BiometricService.isSupported();
    final enabled = await BiometricService.isEnabled();
    if (!mounted) return;
    setState(() {
      _bioSupported = supported;
      _bioEnabled = enabled;
    });
  }

  Future<void> _toggleBiometric(bool value) async {
    if (!_bioSupported) {
      SmartDialog.showToast(
        'Thiết bị chưa đăng ký vân tay/khuôn mặt trong cài đặt hệ thống.',
      );
      return;
    }
    if (value) {
      // Bắt xác thực thành công một lần trước khi bật để tránh tự khóa nhầm.
      final ok = await BiometricService.authenticate(
        reason: 'Xác thực để bật khóa ứng dụng',
      );
      if (!ok) {
        SmartDialog.showToast('Xác thực không thành công');
        return;
      }
    }
    await BiometricService.setEnabled(value);
    if (!mounted) return;
    setState(() => _bioEnabled = value);
    SmartDialog.showToast(
      value
          ? 'Đã bật khóa ứng dụng bằng sinh trắc học'
          : 'Đã tắt khóa ứng dụng bằng sinh trắc học',
    );
  }

  Future<void> _loadCurrentUserEmail() async {
    final repository = ProfileInjection.provideProfileRepository(ApiClient());
    final profileResult = await repository.getProfile();
    if (!mounted) return;
    profileResult.fold(
      (_) => _email = null,
      (profile) => _email = profile.email,
    );
    setState(() {
      _isLoadingProfile = false;
    });
  }

  void _onCurrentPasswordChanged(String value) {
    _verifyDebounce?.cancel();
    _securityProvider.resetValidation();

    if (value.trim().length < 6 || (_email?.isNotEmpty != true)) {
      return;
    }

    _verifyDebounce = Timer(const Duration(milliseconds: 450), () {
      _securityProvider.verifyCurrentPassword(
        email: _email!,
        currentPassword: value.trim(),
      );
    });
  }

  Future<void> _showChangePasswordDialog(BuildContext parentContext) async {
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    final currentPassword = _passwordController.text.trim();
    bool obscureNew = true;
    bool obscureConfirm = true;
    String? mismatchError;
    String? strengthError;
    String? duplicateOldError;

    await showDialog<void>(
      context: parentContext,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setLocalState) {
            void validateMatch() {
              final newPass = newPasswordController.text.trim();
              final confirm = confirmPasswordController.text.trim();
              strengthError = newPass.length < 6
                  ? 'Mật khẩu mới phải có ít nhất 6 ký tự'
                  : null;
              duplicateOldError =
                  newPass.isNotEmpty && newPass == currentPassword
                  ? 'Mật khẩu mới không được trùng mật khẩu hiện tại'
                  : null;
              mismatchError = confirm.isNotEmpty && newPass != confirm
                  ? 'Mật khẩu xác nhận chưa khớp'
                  : null;
            }

            return Dialog(
              insetPadding: const EdgeInsets.symmetric(horizontal: 20),
              backgroundColor: Colors.transparent,
              child: Container(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: AppColors.success.withValues(alpha: 0.18),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.12),
                      blurRadius: 24,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Đổi mật khẩu',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 18),
                    TextField(
                      controller: newPasswordController,
                      obscureText: obscureNew,
                      onChanged: (_) => setLocalState(validateMatch),
                      decoration: InputDecoration(
                        labelText: 'Mật khẩu mới',
                        errorText: duplicateOldError ?? strengthError,
                        filled: true,
                        fillColor: AppColors.grey100,
                        suffixIcon: IconButton(
                          icon: Icon(
                            obscureNew
                                ? Icons.visibility_off_rounded
                                : Icons.visibility_rounded,
                            color: AppColors.success,
                          ),
                          onPressed: () {
                            setLocalState(() {
                              obscureNew = !obscureNew;
                            });
                          },
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: confirmPasswordController,
                      obscureText: obscureConfirm,
                      onChanged: (_) => setLocalState(validateMatch),
                      decoration: InputDecoration(
                        labelText: 'Xác nhận mật khẩu mới',
                        errorText: mismatchError,
                        filled: true,
                        fillColor: AppColors.grey100,
                        suffixIcon: IconButton(
                          icon: Icon(
                            obscureConfirm
                                ? Icons.visibility_off_rounded
                                : Icons.visibility_rounded,
                            color: AppColors.success,
                          ),
                          onPressed: () {
                            setLocalState(() {
                              obscureConfirm = !obscureConfirm;
                            });
                          },
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.of(context).pop(),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.grey700,
                              side: BorderSide(
                                color: AppColors.success.withValues(
                                  alpha: 0.35,
                                ),
                              ),
                              minimumSize: const Size.fromHeight(48),
                            ),
                            child: const Text('Hủy'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ListenableBuilder(
                            listenable: _securityProvider,
                            builder: (context, _) {
                              final canConfirm =
                                  !_securityProvider.isChangingPassword &&
                                  (strengthError == null) &&
                                  (duplicateOldError == null) &&
                                  (mismatchError == null) &&
                                  newPasswordController.text
                                      .trim()
                                      .isNotEmpty &&
                                  confirmPasswordController.text
                                      .trim()
                                      .isNotEmpty;

                              return ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.success,
                                  foregroundColor: AppColors.white,
                                  minimumSize: const Size.fromHeight(48),
                                ),
                                onPressed: !canConfirm
                                    ? null
                                    : () async {
                                        final email = _email;
                                        if (email == null || email.isEmpty) {
                                          SmartDialog.showToast(
                                            'Không lấy được email tài khoản.',
                                          );
                                          return;
                                        }

                                        SmartDialog.showLoading(
                                          msg: 'Đang đổi mật khẩu...',
                                        );
                                        final ok = await _securityProvider
                                            .changePassword(
                                              email: email,
                                              newPassword: newPasswordController
                                                  .text
                                                  .trim(),
                                            );
                                        SmartDialog.dismiss();
                                        if (!mounted) return;

                                        if (ok) {
                                          Navigator.of(context).pop();
                                          _passwordController.clear();
                                          _securityProvider.resetValidation();
                                          SmartDialog.showToast(
                                            'Đổi mật khẩu thành công',
                                          );
                                        } else {
                                          SmartDialog.showToast(
                                            _securityProvider.error ??
                                                'Đổi mật khẩu thất bại',
                                          );
                                        }
                                      },
                                child: const Text('Xác nhận'),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    newPasswordController.dispose();
    confirmPasswordController.dispose();
  }

  @override
  void dispose() {
    _verifyDebounce?.cancel();
    _passwordController.dispose();
    _securityProvider.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final titleStyle = Theme.of(context).textTheme.titleLarge?.copyWith(
      fontSize: 22,
      fontWeight: FontWeight.w700,
      color: AppColors.onBackground,
    );

    return ChangeNotifierProvider.value(
      value: _securityProvider,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('Bảo mật'),
          backgroundColor: AppColors.background,
          foregroundColor: AppColors.onBackground,
          elevation: 0,
        ),
        body: SafeArea(
          child: Consumer<SecurityProvider>(
            builder: (context, provider, _) {
              return Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 8),
                    // ── Khóa ứng dụng bằng sinh trắc học ──────────────────
                    Container(
                      margin: const EdgeInsets.only(bottom: 14),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppColors.success.withValues(alpha: 0.25),
                        ),
                      ),
                      child: SwitchListTile(
                        value: _bioEnabled,
                        onChanged: _toggleBiometric,
                        activeColor: AppColors.success,
                        secondary: const Icon(
                          Icons.fingerprint,
                          color: AppColors.success,
                          size: 28,
                        ),
                        title: const Text(
                          'Khóa ứng dụng bằng sinh trắc học',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        subtitle: Text(
                          _bioSupported
                              ? 'Yêu cầu vân tay/khuôn mặt mỗi khi mở app.'
                              : 'Thiết bị chưa đăng ký sinh trắc học.',
                          style: const TextStyle(fontSize: 12.5),
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppColors.success.withValues(alpha: 0.25),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.success.withValues(alpha: 0.08),
                            blurRadius: 18,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Mật khẩu hiện tại', style: titleStyle),
                          const SizedBox(height: 14),
                          TextField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            obscuringCharacter: '*',
                            onChanged: _onCurrentPasswordChanged,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.2,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Nhập mật khẩu hiện tại',
                              hintStyle: const TextStyle(
                                fontSize: 16,
                                color: AppColors.grey500,
                              ),
                              filled: true,
                              fillColor: AppColors.grey100,
                              suffixIcon: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (provider.isVerifying)
                                    const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    ),
                                  IconButton(
                                    icon: Icon(
                                      _obscurePassword
                                          ? Icons.visibility_off_rounded
                                          : Icons.visibility_rounded,
                                      color: AppColors.success,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _obscurePassword = !_obscurePassword;
                                      });
                                    },
                                  ),
                                ],
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 18,
                                vertical: 16,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(
                                  color: AppColors.success.withValues(
                                    alpha: 0.25,
                                  ),
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: const BorderSide(
                                  color: AppColors.success,
                                  width: 1.8,
                                ),
                              ),
                            ),
                          ),
                          if (_passwordController.text.isNotEmpty &&
                              provider.error != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 10),
                              child: Text(
                                provider.error!,
                                style: const TextStyle(
                                  color: AppColors.error,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          if (provider.isCurrentPasswordValid)
                            const Padding(
                              padding: EdgeInsets.only(top: 10),
                              child: Text(
                                'Mật khẩu hiện tại hợp lệ',
                                style: TextStyle(
                                  color: Colors.green,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppColors.success.withValues(alpha: 0.2),
                        ),
                      ),
                      child: SizedBox(
                        height: 50,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.success,
                            foregroundColor: AppColors.white,
                            elevation: 0,
                            disabledBackgroundColor: AppColors.grey300,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed:
                              (_isLoadingProfile ||
                                  !provider.isCurrentPasswordValid)
                              ? null
                              : () => _showChangePasswordDialog(context),
                          child: const Text(
                            'Đổi mật khẩu',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ),
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
