import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:smart_laundry_locker/core/network/api_client.dart';
import 'package:smart_laundry_locker/features/auth/presentation/providers/auth_injection.dart';
import 'package:smart_laundry_locker/features/auth/presentation/providers/forgot_password_provider.dart';

// Palette đồng bộ với LoginScreen để hai màn auth nhìn như một sản phẩm.
const Color _kNavyDark = Color(0xFF001F2D);
const Color _kNavy = Color(0xFF003D5B);
const Color _kBlue = Color(0xFF0077B6);
const Color _kInk = Color(0xFF1E293B);
const Color _kMuted = Color(0xFF64748B);

/// Quên mật khẩu: bước 1 nhập email nhận OTP, bước 2 nhập OTP + mật khẩu mới.
/// Backend: POST /api/auth/forgot-password → POST /api/auth/reset-password.
class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _emailController = TextEditingController();
  final _otpController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  String? _localError;

  late final ForgotPasswordProvider _provider;

  @override
  void initState() {
    super.initState();
    _provider = AuthInjection.provideForgotPasswordProvider(ApiClient());
    _provider.addListener(_onChanged);
  }

  @override
  void dispose() {
    _provider.removeListener(_onChanged);
    _provider.dispose();
    _emailController.dispose();
    _otpController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _onChanged() {
    if (!mounted) return;
    if (_provider.resetDone) {
      SmartDialog.showToast(
        'Đặt lại mật khẩu thành công. Vui lòng đăng nhập bằng mật khẩu mới.',
      );
      context.pop();
      return;
    }
    setState(() {});
  }

  void _sendOtp() {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      setState(() => _localError = 'Vui lòng nhập email hợp lệ.');
      return;
    }
    setState(() => _localError = null);
    _provider.sendOtp(email);
  }

  void _resetPassword() {
    final otp = _otpController.text.trim();
    final password = _passwordController.text;
    final confirm = _confirmController.text;
    if (otp.length != 6) {
      setState(() => _localError = 'Mã OTP gồm 6 chữ số.');
      return;
    }
    if (password.length < 6) {
      setState(() => _localError = 'Mật khẩu mới phải có ít nhất 6 ký tự.');
      return;
    }
    if (password != confirm) {
      setState(() => _localError = 'Mật khẩu nhập lại không khớp.');
      return;
    }
    setState(() => _localError = null);
    _provider.resetPassword(
      email: _emailController.text,
      otp: otp,
      newPassword: password,
      confirmPassword: confirm,
    );
  }

  @override
  Widget build(BuildContext context) {
    final otpStep = _provider.otpSent;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: _kInk),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Quên mật khẩu',
          style: TextStyle(
            color: _kInk,
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 8),
              Container(
                width: 72,
                height: 72,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [_kNavy, _kNavyDark],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(
                  otpStep ? LucideIcons.shieldCheck : LucideIcons.keyRound,
                  color: Colors.white,
                  size: 32,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                otpStep ? 'Nhập mã OTP & mật khẩu mới' : 'Đặt lại mật khẩu',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: _kInk,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                otpStep
                    ? 'Mã OTP gồm 6 chữ số đã được gửi tới\n${_emailController.text.trim()} (hết hạn sau 5 phút).'
                    : 'Nhập email đã đăng ký tài khoản.\nChúng tôi sẽ gửi mã OTP để đặt lại mật khẩu.',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13.5, color: _kMuted, height: 1.5),
              ),
              const SizedBox(height: 28),
              if (!otpStep) ..._buildEmailStep() else ..._buildResetStep(),
              const SizedBox(height: 12),
              if ((_localError ?? _provider.error) != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFFECACA)),
                  ),
                  child: Text(
                    _localError ?? _provider.error!,
                    style: const TextStyle(
                      color: Color(0xFFB91C1C),
                      fontSize: 13,
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: _provider.isLoading
                      ? null
                      : (otpStep ? _resetPassword : _sendOtp),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _kNavy,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: const Color(0xFFCBD5E1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: _provider.isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor: AlwaysStoppedAnimation(Colors.white),
                          ),
                        )
                      : Text(
                          otpStep ? 'Đặt lại mật khẩu' : 'Gửi mã OTP',
                          style: const TextStyle(
                            fontSize: 15.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ),
              if (otpStep)
                TextButton(
                  onPressed: _provider.isLoading ? null : _sendOtp,
                  child: const Text(
                    'Gửi lại mã OTP',
                    style: TextStyle(
                      color: _kBlue,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildEmailStep() {
    return [
      _fieldLabel('Email'),
      const SizedBox(height: 8),
      TextField(
        controller: _emailController,
        keyboardType: TextInputType.emailAddress,
        textInputAction: TextInputAction.done,
        onSubmitted: (_) => _sendOtp(),
        decoration: _inputDecoration('email@example.com', LucideIcons.mail),
      ),
    ];
  }

  List<Widget> _buildResetStep() {
    return [
      _fieldLabel('Mã OTP'),
      const SizedBox(height: 8),
      TextField(
        controller: _otpController,
        keyboardType: TextInputType.number,
        maxLength: 6,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: 8,
        ),
        decoration: _inputDecoration(
          '••••••',
          LucideIcons.shield,
        ).copyWith(counterText: ''),
      ),
      const SizedBox(height: 16),
      _fieldLabel('Mật khẩu mới'),
      const SizedBox(height: 8),
      TextField(
        controller: _passwordController,
        obscureText: _obscurePassword,
        decoration: _inputDecoration('••••••••', LucideIcons.lock).copyWith(
          suffixIcon: IconButton(
            icon: Icon(
              _obscurePassword ? LucideIcons.eyeOff : LucideIcons.eye,
              size: 18,
              color: _kMuted,
            ),
            onPressed: () =>
                setState(() => _obscurePassword = !_obscurePassword),
          ),
        ),
      ),
      const SizedBox(height: 16),
      _fieldLabel('Nhập lại mật khẩu mới'),
      const SizedBox(height: 8),
      TextField(
        controller: _confirmController,
        obscureText: _obscureConfirm,
        textInputAction: TextInputAction.done,
        onSubmitted: (_) => _resetPassword(),
        decoration: _inputDecoration('••••••••', LucideIcons.lock).copyWith(
          suffixIcon: IconButton(
            icon: Icon(
              _obscureConfirm ? LucideIcons.eyeOff : LucideIcons.eye,
              size: 18,
              color: _kMuted,
            ),
            onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
          ),
        ),
      ),
    ];
  }

  Widget _fieldLabel(String text) => Text(
    text,
    style: const TextStyle(
      fontSize: 13.5,
      fontWeight: FontWeight.w600,
      color: _kInk,
    ),
  );

  InputDecoration _inputDecoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
      prefixIcon: Icon(icon, size: 18, color: _kMuted),
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _kBlue, width: 1.5),
      ),
    );
  }
}
