import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:smart_laundry_locker/core/l10n/language_toggle.dart';
import 'package:smart_laundry_locker/core/network/api_client.dart';
import 'package:smart_laundry_locker/core/routing/app_router.dart';
import 'package:smart_laundry_locker/core/routing/role_routes.dart';
import 'package:smart_laundry_locker/core/services/firebase_messaging_service.dart';
import 'package:smart_laundry_locker/core/services/token_service.dart';
import 'package:smart_laundry_locker/features/auth/presentation/providers/auth_injection.dart';
import 'package:smart_laundry_locker/features/auth/presentation/providers/login_provider.dart';
import 'package:smart_laundry_locker/features/auth/presentation/providers/register_provider.dart';
import 'package:smart_laundry_locker/features/profile/presentation/post_login_prompts.dart';
import 'package:smart_laundry_locker/features/auth/presentation/widgets/phone_otp_dialog.dart';
import 'package:smart_laundry_locker/features/auth/presentation/widgets/social_login_options.dart';
import 'package:smart_laundry_locker/features/profile/presentation/providers/profile_provider.dart';
import 'package:smart_laundry_locker/shared/shared.dart';
import 'package:smart_laundry_locker/shared/widgets/app_lottie.dart';

import 'package:smart_laundry_locker/core/l10n/l10n.dart';
/// Brand palette shared by the login + register flows so both halves of the
/// auth screen feel like one product.
const Color _kNavyDark = Color(0xFF001F2D);
const Color _kNavy = Color(0xFF003D5B);
const Color _kBlue = Color(0xFF0077B6);
const Color _kCyan = Color(0xFF00B4D8);
const Color _kInk = Color(0xFF1E293B);
const Color _kMuted = Color(0xFF64748B);
const String _kFastDeliveryLottie = 'assets/animations/fast_shopping_delivery.json';

/// Single auth screen with a Login / Register toggle. Email-or-phone +
/// password sign-in, self-registration, and social sign-in (Google / phone OTP;
/// Facebook behind FeatureFlags) all live here so the two flows stay in sync.
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

  /// "Điều khoản sử dụng" mở trang điều khoản (trước đây chỉ là chữ tô màu).
  late final TapGestureRecognizer _termsRecognizer = TapGestureRecognizer()
    ..onTap = () => context.push(
      AppRouter.policy,
      extra: {
        'title': context.l10n.commonTermsOfUse,
        'assetPath': 'assets/markdown/terms_of_service.md',
      },
    );
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
    _termsRecognizer.dispose();
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

    // Backend cấp token ngay khi đăng ký ⇒ vào app luôn, không bắt đăng nhập lại.
    if (_registerProvider.isSuccess &&
        _registerProvider.signedIn &&
        !_hasNavigated) {
      _hasNavigated = true;
      SmartDialog.showToast(context.l10n.authRegisterSuccess);
      _registerProvider.reset();
      _navigateAfterLogin();
      return;
    }

    // Backend cũ không trả token ⇒ chuyển sang tab đăng nhập, điền sẵn định danh.
    if (_registerProvider.isSuccess) {
      final identifier = _emailController.text.trim().isNotEmpty
          ? _emailController.text.trim()
          : _phoneController.text.trim();
      SmartDialog.showToast(context.l10n.authRegisterSuccessPleaseLogin);
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
    // Lời nhắc sau đăng nhập (điều khoản, hoàn tất đăng ký, bổ sung thông tin)
    // tự tải hồ sơ của khách; KTV vẫn tải hồ sơ ở đây cho trang KTV.
    final profileProvider = context.read<ProfileProvider>();
    try {
      final roles = await TokenService.getCurrentRoles();
      if (primaryRole(roles) != AppRole.customer) profileProvider.loadProfile();
      unawaited(
        FirebaseMessagingService.instance.updateBackendDeviceToken(ApiClient()),
      );
      if (!mounted) return;
      context.go(homeForRoles(roles));
    } catch (_) {
      if (mounted) context.go(homeForRoles(const []));
    }
    // Điều khoản dịch vụ (lần đầu) → "Hoàn tất đăng ký" (tên mặc định) → nhắc bổ sung email/SĐT.
    unawaited(PostLoginPrompts.run(profileProvider));
  }

  void _handleLogin() {
    final identifier = _identifierController.text.trim();
    // Cắt khoảng trắng như form đăng ký/đổi mật khẩu để mật khẩu luôn khớp.
    final password = _loginPasswordController.text.trim();
    if (identifier.isEmpty || password.isEmpty) {
      setState(() => _loginError = context.l10n.authEnterIdentifierAndPassword);
      return;
    }
    setState(() => _loginError = null);
    _loginProvider.login(email: identifier, password: password);
  }

  void _handleRegister() {
    if (!(_registerFormKey.currentState?.validate() ?? false)) return;
    if (!_agreeToTerms) {
      SmartDialog.showToast(context.l10n.authPleaseAcceptTerms);
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
      padding: const EdgeInsets.fromLTRB(20, 52, 20, 18),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [_kNavyDark, _kNavy, Color(0xFF0F3661)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          Positioned(
            top: -50,
            right: -60,
            child: _circle(200, Colors.white.withValues(alpha: 0.04)),
          ),
          Positioned(
            bottom: -40,
            left: -50,
            child: _circle(160, _kCyan.withValues(alpha: 0.08)),
          ),
          const Positioned(top: -12, right: 0, child: LanguageToggle()),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 1. Logo ở TRÊN file JSON
              ScaleTransition(
                scale: _logoScale,
                child: FadeTransition(
                  opacity: _opacity,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.8),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF00B4D8).withValues(alpha: 0.35),
                              blurRadius: 18,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: Image.asset(
                            'assets/images/logo.png',
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Container(
                              color: const Color(0xFF0F172A),
                              child: const Icon(LucideIcons.box, color: Colors.white, size: 24),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'LOCK.R',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 2.2,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            context.l10n.authTagline,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Colors.white.withValues(alpha: 0.82),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 10),

              // 2. Lottie Animation Shopping Delivery ở DƯỚI Logo
              FadeTransition(
                opacity: _opacity,
                child: Container(
                  height: 130,
                  width: double.infinity,
                  alignment: Alignment.center,
                  child: const AppLottie(
                    _kFastDeliveryLottie,
                    animate: true,
                    repeat: true,
                    fit: BoxFit.contain,
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
          _tabButton(context.l10n.authLogin, _isLoginTab, () => _switchTab(true)),
          _tabButton(context.l10n.authRegister, !_isLoginTab, () => _switchTab(false)),
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
            gradient: active
                ? const LinearGradient(
                    colors: [_kNavy, _kBlue],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            color: active ? null : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: active
                ? [
                    BoxShadow(
                      color: _kBlue.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
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
        _fieldLabel(context.l10n.authEmailOrPhone),
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
        _fieldLabel(context.l10n.commonPassword),
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
              child: Text(
                context.l10n.authLoginWithOtp,
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
              child: Text(
                context.l10n.authForgotPasswordQuestion,
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
          _fieldLabel(context.l10n.commonFullName),
          const SizedBox(height: 8),
          TextFormField(
            controller: _fullNameController,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.next,
            decoration: _inputDecoration(
              context.l10n.commonFullNameHint,
              icon: LucideIcons.user,
            ),
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? context.l10n.authEnterFullName : null,
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
              if (v == null || v.trim().isEmpty) return context.l10n.authEnterEmail;
              if (!v.contains('@')) return context.l10n.authInvalidEmail;
              return null;
            },
          ),
          const SizedBox(height: 16),
          _fieldLabel(context.l10n.commonPhoneNumber),
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
                ? context.l10n.authEnterPhone
                : null,
          ),
          const SizedBox(height: 16),
          _fieldLabel(context.l10n.commonPassword),
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
              if (v == null || v.trim().isEmpty) return context.l10n.authEnterPassword;
              if (v.trim().length < 6) return context.l10n.authPasswordMin6;
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
            child: Text.rich(
              TextSpan(
                style: const TextStyle(fontSize: 13, color: _kMuted),
                children: [
                  TextSpan(text: context.l10n.authAgreePrefix),
                  TextSpan(
                    text: context.l10n.commonTermsOfUse,
                    style: const TextStyle(
                      color: _kBlue,
                      fontWeight: FontWeight.w600,
                      decoration: TextDecoration.underline,
                    ),
                    recognizer: _termsRecognizer,
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
    // Web chưa cấu hình Firebase ⇒ không có nút nào (chỉ đăng nhập email);
    // Facebook ẩn theo FeatureFlags.facebookLoginEnabled.
    final options = SocialLoginOptions.current();
    if (!options.any) return const SizedBox.shrink();
    final buttons = <Widget>[
      if (options.google)
        _socialButton(
          icon: Icons.g_mobiledata,
          iconColor: const Color(0xFFDB4437),
          label: 'Google',
          onTap: _busy ? null : _loginProvider.loginWithGoogle,
        ),
      if (options.facebook)
        _socialButton(
          icon: Icons.facebook,
          iconColor: const Color(0xFF1877F2),
          label: 'Facebook',
          onTap: _busy ? null : _loginProvider.loginWithFacebook,
        ),
      if (options.phone)
        _socialButton(
          icon: Icons.phone_android,
          iconColor: _kBlue,
          label: context.l10n.commonPhoneShort,
          onTap: _busy ? null : _showPhoneOtpDialog,
        ),
    ];
    return Column(
      children: [
        Row(
          children: [
            const Expanded(child: Divider()),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                context.l10n.authOrContinueWith,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ),
            const Expanded(child: Divider()),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            for (var i = 0; i < buttons.length; i++) ...[
              if (i > 0) const SizedBox(width: 12),
              Expanded(child: buttons[i]),
            ],
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
              _isLoginTab ? context.l10n.authLogin : context.l10n.authCreateAccount,
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
                    ? context.l10n.authNoAccount
                    : context.l10n.authHaveAccount,
              ),
              TextSpan(
                text: _isLoginTab ? context.l10n.authRegisterNow : context.l10n.authLogin,
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
  void _showPhoneOtpDialog() =>
      PhoneOtpDialog.show(_loginProvider, accentColor: _kBlue);

  // ---------------------------------------------------------------------------
  // Email OTP dialog
  // ---------------------------------------------------------------------------
  void _handleEmailOtpLogin() {
    final email = _identifierController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      setState(() => _loginError = context.l10n.authEnterValidEmailForOtp);
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
                    Text(
                      context.l10n.authEnterOtp,
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
                          ? context.l10n.authOtpSentTo(email)
                          : context.l10n.authOtpSendingTo(email),
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 14, color: _kMuted),
                    ),
                    if (isSent) ...[
                      const SizedBox(height: 16),
                      TextField(
                        controller: otpController,
                        keyboardType: TextInputType.number,
                        autofocus: true,
                        decoration: InputDecoration(
                          labelText: context.l10n.authOtp6Digits,
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
                              : Text(context.l10n.commonConfirm),
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
