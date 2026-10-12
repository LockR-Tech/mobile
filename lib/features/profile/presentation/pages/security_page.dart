import 'package:smart_laundry_locker/core/constants/app_colors.dart';
import 'package:smart_laundry_locker/core/network/api_client.dart';
import 'package:smart_laundry_locker/core/services/biometric_service.dart';
import 'package:smart_laundry_locker/features/profile/domain/password_change.dart';
import 'package:smart_laundry_locker/features/profile/presentation/providers/profile_injection.dart';
import 'package:smart_laundry_locker/features/profile/presentation/providers/security_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:provider/provider.dart';
import 'package:smart_laundry_locker/shared/widgets/user_ui_kit.dart';

class SecurityPage extends StatefulWidget {
  const SecurityPage({super.key});

  @override
  State<SecurityPage> createState() => _SecurityPageState();
}

class _SecurityPageState extends State<SecurityPage> {
  final _currentController = TextEditingController();
  final _newController = TextEditingController();
  final _confirmController = TextEditingController();
  late final SecurityProvider _securityProvider;

  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  // Khóa ứng dụng bằng sinh trắc học thiết bị (vân tay/khuôn mặt OS).
  bool _bioSupported = false;
  bool _bioEnabled = false;

  @override
  void initState() {
    super.initState();
    _securityProvider = ProfileInjection.provideSecurityProvider(ApiClient());
    _securityProvider.loadPasswordState();
    _loadBiometricState();
  }

  @override
  void dispose() {
    _currentController.dispose();
    _newController.dispose();
    _confirmController.dispose();
    _securityProvider.dispose();
    super.dispose();
  }

  Future<void> _loadBiometricState() async {
    final supported = await BiometricService.isSupported();
    final enabled = await BiometricService.isEnabled();
    if (!mounted) return;
    setState(() {
      _bioSupported = supported;
      _bioEnabled = supported && enabled;
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

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    final wasSetMode = _securityProvider.mode == PasswordFormMode.set;
    final ok = await _securityProvider.submit(
      currentPassword: _currentController.text,
      newPassword: _newController.text,
      confirmPassword: _confirmController.text,
    );
    if (!mounted) return;
    if (ok) {
      _currentController.clear();
      _newController.clear();
      _confirmController.clear();
      SmartDialog.showToast(
        wasSetMode ? 'Đã đặt mật khẩu' : 'Đổi mật khẩu thành công',
      );
    }
  }

  void _onFieldChanged(String _) {
    _securityProvider.clearError();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _securityProvider,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Column(
          children: [
            BrandHeroHeader(
              title: 'Bảo mật',
              subtitle: 'Bảo vệ tài khoản và thiết bị của bạn',
              onBack: () => Navigator.of(context).pop(),
            ),
            Expanded(
              child: Consumer<SecurityProvider>(
                builder: (context, provider, _) {
                  return ListView(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
                    children: [
                      _buildBiometricCard(),
                      _buildPasswordCard(provider),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBiometricCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.success.withValues(alpha: 0.25)),
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
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        ),
        subtitle: Text(
          _bioSupported
              ? 'Yêu cầu vân tay/khuôn mặt mỗi khi mở app.'
              : 'Thiết bị chưa đăng ký sinh trắc học.',
          style: const TextStyle(fontSize: 12.5),
        ),
      ),
    );
  }

  Widget _buildPasswordCard(SecurityProvider provider) {
    final titleStyle = Theme.of(context).textTheme.titleLarge?.copyWith(
      fontSize: 20,
      fontWeight: FontWeight.w700,
      color: AppColors.onBackground,
    );

    Widget body;
    if (provider.isLoadingProfile) {
      body = const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: CircularProgressIndicator(strokeWidth: 2.5)),
      );
    } else if (provider.profileError != null) {
      body = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Mật khẩu', style: titleStyle),
          const SizedBox(height: 10),
          Text(
            'Không tải được thông tin tài khoản: ${provider.profileError}',
            style: const TextStyle(color: AppColors.error, fontSize: 13),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: provider.loadPasswordState,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Thử lại'),
          ),
        ],
      );
    } else {
      final isChange = provider.mode == PasswordFormMode.change;
      body = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(isChange ? 'Đổi mật khẩu' : 'Đặt mật khẩu', style: titleStyle),
          const SizedBox(height: 6),
          Text(
            isChange
                ? 'Nhập mật khẩu hiện tại và mật khẩu mới. Các thiết bị khác sẽ phải đăng nhập lại.'
                : 'Tài khoản của bạn đăng nhập bằng Google hoặc mã OTP nên chưa có mật khẩu. Đặt mật khẩu để có thể đăng nhập bằng email/số điện thoại và mật khẩu.',
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.onSurfaceVariant,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          if (isChange) ...[
            _PasswordField(
              controller: _currentController,
              label: 'Mật khẩu hiện tại',
              obscure: _obscureCurrent,
              onToggle: () => setState(() => _obscureCurrent = !_obscureCurrent),
              onChanged: _onFieldChanged,
            ),
            const SizedBox(height: 12),
          ],
          _PasswordField(
            controller: _newController,
            label: 'Mật khẩu mới',
            helper: 'Ít nhất $kMinPasswordLength ký tự',
            obscure: _obscureNew,
            onToggle: () => setState(() => _obscureNew = !_obscureNew),
            onChanged: _onFieldChanged,
          ),
          const SizedBox(height: 12),
          _PasswordField(
            controller: _confirmController,
            label: 'Xác nhận mật khẩu mới',
            obscure: _obscureConfirm,
            onToggle: () => setState(() => _obscureConfirm = !_obscureConfirm),
            onChanged: _onFieldChanged,
          ),
          if (provider.error != null) ...[
            const SizedBox(height: 12),
            Text(
              provider.error!,
              style: const TextStyle(
                color: AppColors.error,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
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
              onPressed: provider.isChangingPassword ? null : _submit,
              child: provider.isChangingPassword
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.4,
                        color: AppColors.white,
                      ),
                    )
                  : Text(
                      isChange ? 'Đổi mật khẩu' : 'Đặt mật khẩu',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
          ),
        ],
      );
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.success.withValues(alpha: 0.25)),
        boxShadow: [
          BoxShadow(
            color: AppColors.success.withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: body,
    );
  }
}

class _PasswordField extends StatelessWidget {
  const _PasswordField({
    required this.controller,
    required this.label,
    required this.obscure,
    required this.onToggle,
    required this.onChanged,
    this.helper,
  });

  final TextEditingController controller;
  final String label;
  final String? helper;
  final bool obscure;
  final VoidCallback onToggle;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      onChanged: onChanged,
      autocorrect: false,
      enableSuggestions: false,
      decoration: InputDecoration(
        labelText: label,
        helperText: helper,
        filled: true,
        fillColor: AppColors.grey100,
        suffixIcon: IconButton(
          icon: Icon(
            obscure ? Icons.visibility_off_rounded : Icons.visibility_rounded,
            color: AppColors.success,
          ),
          onPressed: onToggle,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
