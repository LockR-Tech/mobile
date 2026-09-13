import 'package:flutter/material.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:smart_laundry_locker/core/network/api_client.dart';
import 'package:smart_laundry_locker/core/routing/app_router.dart';
import 'package:smart_laundry_locker/core/routing/role_routes.dart';
import 'package:smart_laundry_locker/core/services/token_service.dart';
import 'package:smart_laundry_locker/features/auth/presentation/providers/auth_injection.dart';
import 'package:smart_laundry_locker/features/auth/presentation/providers/login_provider.dart';
import 'package:smart_laundry_locker/features/auth/presentation/providers/register_provider.dart';

/// Brand palette shared by the login + register flows so both halves of the
/// auth screen feel like one product.
const Color _kNavyDark = Color(0xFF001F2D);
const Color _kNavy = Color(0xFF003D5B);
const Color _kBlue = Color(0xFF0077B6);
const Color _kCyan = Color(0xFF00B4D8);
const Color _kInk = Color(0xFF1E293B);
const Color _kMuted = Color(0xFF64748B);

/// Single auth screen with a Login / Register toggle. Email-or-phone +
/// password sign-in, self-registration, and social sign-in (Google / Facebook
/// / phone OTP) all live here so the two flows stay visually in sync.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  bool _isLoginTab = true;

  // Login fields (identifier accepts email OR phone).
  final _identifierController = TextEditingController();
  final _loginPasswordController = TextEditingController();

  // Register fields.
  final _registerFormKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _registerPasswordController = TextEditingController();

  bool _obscureLoginPassword = true;
  bool _obscureRegisterPassword = true;
  bool _agreeToTerms = false;
  String? _loginError;

  late final LoginProvider _loginProvider;
  late final RegisterProvider _registerProvider;
  bool _hasNavigated = false;

  late final AnimationController _animationController;
  late final Animation<double> _logoScale;
  late final Animation<double> _opacity;
  late final Animation<Offset> _formSlide;

  @override
  void initState() {
    super.initState();
    final apiClient = ApiClient();
    _loginProvider = AuthInjection.provideLoginProvider(apiClient);
    _registerProvider = AuthInjection.provideRegisterProvider(apiClient);
    _loginProvider.addListener(_onAuthChanged);
    _registerProvider.addListener(_onAuthChanged);

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _logoScale = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.elasticOut),
      ),
    );
    _opacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.2, 0.8, curve: Curves.easeIn),
      ),
    );
    _formSlide = Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _animationController,
            curve: const Interval(0.4, 1.0, curve: Curves.easeOutCubic),
          ),
        );
    _animationController.forward();
  }

  @override
  void dispose() {
    _loginProvider.removeListener(_onAuthChanged);
    _registerProvider.removeListener(_onAuthChanged);
    _animationController.dispose();
    _identifierController.dispose();
    _loginPasswordController.dispose();
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _registerPasswordController.dispose();
    _loginProvider.dispose();
    _registerProvider.dispose();
    super.dispose();
  }

  void _onAuthChanged() {
    if (!mounted) return;

    if (_loginProvider.isSuccess && !_hasNavigated) {
      _hasNavigated = true;
      _navigateAfterLogin();
      return;
    }

    // Backend issues the account immediately on register (no separate email
    // OTP gate). Move the user to the Login tab with their identifier prefilled.
    if (_registerProvider.isSuccess) {
      final identifier = _emailController.text.trim().isNotEmpty
          ? _emailController.text.trim()
          : _phoneController.text.trim();
      SmartDialog.showToast('Đăng ký thành công! Vui lòng đăng nhập.');
      _registerProvider.reset();
      setState(() {
        _isLoginTab = true;
        _identifierController.text = identifier;
        _loginError = null;
      });
      return;
    }

    setState(() {}); // reflect loading / error changes
  }

  Future<void> _navigateAfterLogin() async {
    if (!mounted) return;
    try {
      final roles = await TokenService.getCurrentRoles();
      if (!mounted) return;
      context.go(homeForRoles(roles));
    } catch (_) {
      if (mounted) context.go(homeForRoles(const []));
    }
  }

  void _handleLogin() {
    final identifier = _identifierController.text.trim();
    final password = _loginPasswordController.text;
    if (identifier.isEmpty || password.isEmpty) {
      setState(() => _loginError = 'Nhập email/SĐT và mật khẩu');
      return;
    }
    setState(() => _loginError = null);
    _loginProvider.login(email: identifier, password: password);
  }

  void _handleRegister() {
    if (!(_registerFormKey.currentState?.validate() ?? false)) return;
    if (!_agreeToTerms) {
      SmartDialog.showToast('Vui lòng đồng ý với Điều khoản sử dụng');
      return;
    }
    _registerProvider.register(
      phoneNumber: _phoneController.text.trim(),
      fullName: _fullNameController.text.trim().isNotEmpty
          ? _fullNameController.text.trim()
          : null,
      email: _emailController.text.trim().isNotEmpty
          ? _emailController.text.trim()
          : null,
      password: _registerPasswordController.text.trim().isNotEmpty
          ? _registerPasswordController.text.trim()
          : null,
    );
  }

  void _switchTab(bool toLogin) {
    if (_isLoginTab == toLogin) return;
    FocusScope.of(context).unfocus();
    _loginProvider.clearError();
    _registerProvider.clearError();
    setState(() {
      _isLoginTab = toLogin;
      _loginError = null;
    });
  }

  bool get _busy => _loginProvider.isLoading || _registerProvider.isLoading;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kNavy,
      resizeToAvoidBottomInset: true,
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SlideTransition(
                position: _formSlide,
                child: FadeTransition(
                  opacity: _opacity,
                  child: Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(30),
                        topRight: Radius.circular(30),
                      ),
                    ),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildTabSwitch(),
                          const SizedBox(height: 24),
                          AnimatedSize(
                            duration: const Duration(milliseconds: 200),
                            curve: Curves.easeOut,
                            alignment: Alignment.topCenter,
                            child: _isLoginTab
                                ? _buildLoginForm()
                                : _buildRegisterForm(),
                          ),
                          const SizedBox(height: 20),
                          _buildSocialSection(),
                          const SizedBox(height: 20),
                          _buildPrimaryButton(),
                          const SizedBox(height: 16),
                          _buildSwitchPrompt(),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(top: 64, bottom: 28),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [_kNavyDark, _kNavy, _kBlue],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          Positioned(
            top: -40,
            right: -50,
            child: _circle(180, Colors.white.withValues(alpha: 0.04)),
          ),
          Positioned(
            bottom: -30,
            left: -40,
            child: _circle(140, _kCyan.withValues(alpha: 0.08)),
          ),
          Column(
            children: [
              ScaleTransition(
                scale: _logoScale,
                child: FadeTransition(
                  opacity: _opacity,
                  child: Container(
                    width: 88,
                    height: 88,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.15),
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.1),
                      ),
                      child: const Icon(
                        LucideIcons.box,
                        size: 34,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              FadeTransition(
                opacity: _opacity,
                child: const Text(
                  'Lock.R Locker',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              FadeTransition(
                opacity: _opacity,
                child: Text(
                  'Locker thông minh, tiện lợi',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _circle(double size, Color color) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(shape: BoxShape.circle, color: color),
  );

  Widget _buildTabSwitch() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          _tabButton('Đăng nhập', _isLoginTab, () => _switchTab(true)),
          _tabButton('Đăng ký', !_isLoginTab, () => _switchTab(false)),
        ],
      ),
    );
  }

  Widget _tabButton(String label, bool active, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: active ? _kBlue : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: active ? Colors.white : _kMuted,
            ),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Login form
  // ---------------------------------------------------------------------------
  Widget _buildLoginForm() {
    return Column(
      key: const ValueKey('login'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _fieldLabel('Email / Số điện thoại'),
        const SizedBox(height: 8),
        TextField(
          controller: _identifierController,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          decoration: _inputDecoration(
            'email@example.com',
            icon: LucideIcons.user,
          ),
        ),
        const SizedBox(height: 16),
        _fieldLabel('Mật khẩu'),
        const SizedBox(height: 8),
        TextField(
          controller: _loginPasswordController,
          obscureText: _obscureLoginPassword,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _handleLogin(),
          decoration: _inputDecoration('••••••••', icon: LucideIcons.lock)
              .copyWith(
                suffixIcon: _obscureToggle(
                  _obscureLoginPassword,
                  () => setState(
                    () => _obscureLoginPassword = !_obscureLoginPassword,
                  ),
                ),
              ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TextButton(
              onPressed: _handleEmailOtpLogin,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 8),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text(
                'Đăng nhập bằng OTP',
                style: TextStyle(
                  fontSize: 13,
                  color: _kBlue,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            TextButton(
              onPressed: () => context.push(AppRouter.forgotPassword),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 8),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text(
                'Quên mật khẩu?',
                style: TextStyle(
                  fontSize: 13,
                  color: _kBlue,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        _buildError(_loginError ?? _loginProvider.error),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Register form
  // ---------------------------------------------------------------------------
  Widget _buildRegisterForm() {
    return Form(
      key: _registerFormKey,
      child: Column(
        key: const ValueKey('register'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _fieldLabel('Họ và tên'),
          const SizedBox(height: 8),
          TextFormField(
            controller: _fullNameController,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.next,
            decoration: _inputDecoration(
              'Nguyễn Văn A',
              icon: LucideIcons.user,
            ),
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Vui lòng nhập họ và tên' : null,
          ),
          const SizedBox(height: 16),
          _fieldLabel('Email'),
          const SizedBox(height: 8),
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            decoration: _inputDecoration(
              'name@example.com',
              icon: LucideIcons.mail,
            ),
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Vui lòng nhập email';
              if (!v.contains('@')) return 'Email không hợp lệ';
              return null;
            },
          ),
          const SizedBox(height: 16),
          _fieldLabel('Số điện thoại'),
          const SizedBox(height: 8),
          TextFormField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.next,
            decoration: _inputDecoration(
              '0901234567',
              icon: LucideIcons.smartphone,
            ),
            validator: (v) => (v == null || v.trim().isEmpty)
                ? 'Vui lòng nhập số điện thoại'
                : null,
          ),
          const SizedBox(height: 16),
          _fieldLabel('Mật khẩu'),
          const SizedBox(height: 8),
          TextFormField(
            controller: _registerPasswordController,
            obscureText: _obscureRegisterPassword,
            textInputAction: TextInputAction.done,
            decoration: _inputDecoration('••••••••', icon: LucideIcons.lock)
                .copyWith(
                  suffixIcon: _obscureToggle(
                    _obscureRegisterPassword,
                    () => setState(
                      () => _obscureRegisterPassword = !_obscureRegisterPassword,
                    ),
                  ),
                ),
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Vui lòng nhập mật khẩu';
              if (v.trim().length < 6) return 'Mật khẩu phải có ít nhất 6 ký tự';
              return null;
            },
          ),
          const SizedBox(height: 12),
          _buildTermsCheckbox(),
          _buildError(_registerProvider.error),
        ],
      ),
    );
  }

  Widget _buildTermsCheckbox() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 24,
          height: 24,
          child: Checkbox(
            value: _agreeToTerms,
            onChanged: (v) => setState(() => _agreeToTerms = v ?? false),
            activeColor: _kBlue,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _agreeToTerms = !_agreeToTerms),
            child: const Text.rich(
              TextSpan(
                style: TextStyle(fontSize: 13, color: _kMuted),
                children: [
                  TextSpan(text: 'Tôi đồng ý với '),
                  TextSpan(
                    text: 'Điều khoản sử dụng',
                    style: TextStyle(
                      color: _kBlue,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Shared widgets
  // ---------------------------------------------------------------------------
  Widget _buildSocialSection() {
    return Column(
      children: [
        Row(
          children: [
            const Expanded(child: Divider()),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                'Hoặc tiếp tục với',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ),
            const Expanded(child: Divider()),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _socialButton(
                icon: Icons.g_mobiledata,
                iconColor: const Color(0xFFDB4437),
                label: 'Google',
                onTap: _busy ? null : _loginProvider.loginWithGoogle,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _socialButton(
                icon: Icons.facebook,
                iconColor: const Color(0xFF1877F2),
                label: 'Facebook',
                onTap: _busy ? null : _loginProvider.loginWithFacebook,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _socialButton(
                icon: Icons.phone_android,
                iconColor: _kBlue,
                label: 'SĐT',
                onTap: _busy ? null : _showPhoneOtpDialog,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _socialButton({
    required IconData icon,
    required Color iconColor,
    required String label,
    required VoidCallback? onTap,
    double iconSize = 24,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFE2E8F0)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: iconSize, color: iconColor),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: _kInk,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrimaryButton() {
    return ElevatedButton(
      onPressed: _busy ? null : (_isLoginTab ? _handleLogin : _handleRegister),
      style: ElevatedButton.styleFrom(
        backgroundColor: _kBlue,
        disabledBackgroundColor: const Color(0xFF94A3B8),
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 0,
      ),
      child: _busy
          ? const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              ),
            )
          : Text(
              _isLoginTab ? 'Đăng nhập' : 'Tạo tài khoản',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
    );
  }

  Widget _buildSwitchPrompt() {
    return Center(
      child: GestureDetector(
        onTap: () => _switchTab(!_isLoginTab),
        child: Text.rich(
          TextSpan(
            style: const TextStyle(fontSize: 14, color: _kMuted),
            children: [
              TextSpan(
                text: _isLoginTab
                    ? 'Chưa có tài khoản? '
                    : 'Đã có tài khoản? ',
              ),
              TextSpan(
                text: _isLoginTab ? 'Đăng ký ngay' : 'Đăng nhập',
                style: const TextStyle(
                  color: _kBlue,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _fieldLabel(String text) => Text(
    text,
    style: const TextStyle(
      fontWeight: FontWeight.bold,
      fontSize: 14,
      color: _kInk,
    ),
  );

  Widget _obscureToggle(bool obscured, VoidCallback onTap) => IconButton(
    icon: Icon(
      obscured ? LucideIcons.eye : LucideIcons.eyeOff,
      size: 18,
      color: Colors.grey,
    ),
    onPressed: onTap,
  );

  Widget _buildError(String? message) {
    if (message == null || message.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: const Color(0xFFFEF2F2),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFFECACA)),
        ),
        child: Row(
          children: [
            const Icon(
              LucideIcons.circleAlert,
              size: 16,
              color: Color(0xFFB91C1C),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Color(0xFFB91C1C),
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint, {required IconData icon}) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, size: 18, color: Colors.grey),
      filled: true,
      fillColor: const Color(0xFFF8F9FA),
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _kBlue, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFFECACA)),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFB91C1C)),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Phone OTP (Firebase) dialog
  // ---------------------------------------------------------------------------
  void _showPhoneOtpDialog() {
    final phoneController = TextEditingController();
    final otpController = TextEditingController();
    // Always start fresh so the dialog opens on the "enter phone" step.
    _loginProvider.clearPhoneVerification();

    SmartDialog.show(
      builder: (_) {
        return ChangeNotifierProvider.value(
          value: _loginProvider,
          child: Consumer<LoginProvider>(
            builder: (context, provider, _) {
              // Driving the step off the provider (not a local bool) is what
              // makes the OTP field appear: Firebase's codeSent callback fires
              // asynchronously and sets verificationId, triggering this rebuild.
              final codeSent = provider.verificationId != null;

              // Instant verification or a confirmed OTP -> close the dialog;
              // the screen listener handles navigation.
              if (provider.isSuccess) {
                WidgetsBinding.instance.addPostFrameCallback(
                  (_) => SmartDialog.dismiss(),
                );
              }

              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 24),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      codeSent ? 'Nhập mã OTP' : 'Đăng nhập bằng số điện thoại',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: _kInk,
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (!codeSent) ...[
                      TextField(
                        controller: phoneController,
                        keyboardType: TextInputType.phone,
                        autofocus: true,
                        decoration: const InputDecoration(
                          labelText: 'Số điện thoại',
                          hintText: '0911649183',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.only(top: 6),
                        child: Text(
                          'Nhập số nội địa (0xxx) hoặc quốc tế (+84xxx) đều được.',
                          style: TextStyle(fontSize: 12, color: _kMuted),
                        ),
                      ),
                    ] else
                      TextField(
                        controller: otpController,
                        keyboardType: TextInputType.number,
                        autofocus: true,
                        decoration: const InputDecoration(
                          labelText: 'Mã OTP (6 số)',
                          hintText: '------',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: provider.isLoading
                            ? null
                            : () async {
                                FocusScope.of(context).unfocus();
                                if (!codeSent) {
                                  final phone = phoneController.text.trim();
                                  if (phone.isEmpty) return;
                                  await provider.sendPhoneOtp(phone);
                                } else {
                                  final code = otpController.text.trim();
                                  if (code.isEmpty) return;
                                  await provider.confirmPhoneOtp(code);
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _kBlue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: provider.isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(codeSent ? 'Xác nhận' : 'Gửi mã OTP'),
                      ),
                    ),
                    if (codeSent)
                      TextButton(
                        onPressed: provider.isLoading
                            ? null
                            : () {
                                otpController.clear();
                                provider.clearPhoneVerification();
                              },
                        child: const Text(
                          'Đổi số điện thoại',
                          style: TextStyle(color: _kBlue),
                        ),
                      ),
                    if (provider.error != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          provider.error!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
  // ---------------------------------------------------------------------------
  // Email OTP dialog
  // ---------------------------------------------------------------------------
  void _handleEmailOtpLogin() {
    final email = _identifierController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      setState(() => _loginError = 'Vui lòng nhập Email hợp lệ để nhận OTP');
      return;
    }
    setState(() => _loginError = null);
    _loginProvider.sendEmailOtp(email);
    _showEmailOtpDialog(email);
  }

  void _showEmailOtpDialog(String email) {
    final otpController = TextEditingController();

    SmartDialog.show(
      builder: (_) {
        return ChangeNotifierProvider.value(
          value: _loginProvider,
          child: Consumer<LoginProvider>(
            builder: (context, provider, _) {
              final isSent = provider.isEmailOtpSent;

              if (provider.isSuccess) {
                WidgetsBinding.instance.addPostFrameCallback(
                  (_) => SmartDialog.dismiss(),
                );
              }

              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 24),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Nhập mã OTP',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: _kInk,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      isSent
                          ? 'Mã OTP đã được gửi đến $email'
                          : 'Đang gửi mã OTP đến $email...',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 14, color: _kMuted),
                    ),
                    if (isSent) ...[
                      const SizedBox(height: 16),
                      TextField(
                        controller: otpController,
                        keyboardType: TextInputType.number,
                        autofocus: true,
                        decoration: const InputDecoration(
                          labelText: 'Mã OTP (6 số)',
                          hintText: '------',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                    if (isSent)
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: provider.isLoading
                              ? null
                              : () async {
                                  FocusScope.of(context).unfocus();
                                  final code = otpController.text.trim();
                                  if (code.isEmpty) return;
                                  await provider.confirmEmailOtp(
                                    email: email,
                                    otp: code,
                                  );
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _kBlue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: provider.isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text('Xác nhận'),
                        ),
                      ),
                    if (provider.error != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          provider.error!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}
