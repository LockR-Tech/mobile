import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:smart_laundry_locker/core/config/feature_flags.dart';
import 'package:smart_laundry_locker/core/constants/app_colors.dart';
import 'package:smart_laundry_locker/core/network/api_client.dart';
import 'package:smart_laundry_locker/core/routing/app_router.dart';
import 'package:smart_laundry_locker/core/routing/role_routes.dart';
import 'package:smart_laundry_locker/core/services/token_service.dart';
import 'package:smart_laundry_locker/features/auth/presentation/providers/auth_injection.dart';
import 'package:smart_laundry_locker/features/auth/presentation/providers/login_provider.dart';
import 'package:smart_laundry_locker/features/auth/presentation/providers/register_provider.dart';
import 'package:smart_laundry_locker/features/profile/presentation/post_login_prompts.dart';
import 'package:smart_laundry_locker/features/auth/presentation/widgets/phone_otp_dialog.dart';
import 'package:smart_laundry_locker/features/auth/presentation/widgets/social_login_options.dart';
import 'package:smart_laundry_locker/features/profile/presentation/providers/profile_provider.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';

import 'package:smart_laundry_locker/core/l10n/l10n.dart';
class AuthBottomSheet extends StatefulWidget {
  final bool initialIsLogin;

  const AuthBottomSheet({super.key, this.initialIsLogin = true});

  @override
  State<AuthBottomSheet> createState() => _AuthBottomSheetState();

  static Future<bool?> show(BuildContext context, {bool isLogin = true}) {
    return showModalBottomSheet<bool>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AuthBottomSheet(initialIsLogin: isLogin),
    );
  }
}

class _AuthBottomSheetState extends State<AuthBottomSheet> {
  late bool _isLoginTab;

  final _loginFormKey = GlobalKey<FormState>();
  final _loginEmailController = TextEditingController();
  final _loginPasswordController = TextEditingController();

  final _registerFormKey = GlobalKey<FormState>();
  final _registerFullNameController = TextEditingController();
  final _registerEmailController = TextEditingController();
  final _registerPhoneController = TextEditingController();
  final _registerPasswordController = TextEditingController();

  bool _obscureLoginPassword = true;
  bool _obscureRegisterPassword = true;
  bool _agreeToTerms = false;

  late LoginProvider _loginProvider;
  late RegisterProvider _registerProvider;

  late final TapGestureRecognizer _termsRecognizer = TapGestureRecognizer()
    ..onTap = () => context.push(
      AppRouter.policy,
      extra: {
        'title': context.l10n.commonTermsOfUse,
        'assetPath': 'assets/markdown/terms_of_service.md',
      },
    );

  @override
  void initState() {
    super.initState();
    _isLoginTab = widget.initialIsLogin;
    final apiClient = ApiClient();
    _loginProvider = AuthInjection.provideLoginProvider(apiClient);
    _registerProvider = AuthInjection.provideRegisterProvider(apiClient);

    _loginProvider.addListener(_onLoginStateChanged);
    _registerProvider.addListener(_onRegisterStateChanged);
  }

  bool _hasNavigated = false;

  void _onLoginStateChanged() {
    if (_loginProvider.isSuccess && !_hasNavigated) {
      _hasNavigated = true;
      _navigateAfterLogin();
    }
  }

  Future<void> _navigateAfterLogin() async {
    if (!mounted) return;
    // Lời nhắc sau đăng nhập (điều khoản, hoàn tất đăng ký, bổ sung thông tin)
    // chạy sau khi vào trang chủ. Lấy provider trước khi đóng sheet.
    final profileProvider = context.read<ProfileProvider>();
    // Đóng bottom sheet trước
    Navigator.of(context, rootNavigator: true).pop(true);
    // Lấy roles từ token và navigate đến trang phù hợp
    try {
      final roles = await TokenService.getCurrentRoles();
      // Sử dụng AppRouter.navigatorKey để navigate ngay cả khi sheet đã dispose
      final navContext = AppRouter.navigatorKey.currentContext;
      if (navContext != null && navContext.mounted) {
        navContext.go(homeForRoles(roles));
      }
    } catch (_) {
      // fallback: không navigate, ProfilePage sẽ tự reload
    }
    // Điều khoản dịch vụ (lần đầu) → "Hoàn tất đăng ký" (tên mặc định) → nhắc bổ sung email/SĐT.
    unawaited(PostLoginPrompts.run(profileProvider));
  }

  void _onRegisterStateChanged() {
    // Backend cấp token ngay khi đăng ký ⇒ vào app luôn.
    if (_registerProvider.isSuccess &&
        _registerProvider.signedIn &&
        !_hasNavigated) {
      _hasNavigated = true;
      SmartDialog.showToast(context.l10n.authRegisterSuccess);
      _registerProvider.reset();
      _navigateAfterLogin();
      return;
    }
    if (_registerProvider.isSuccess && !_hasNavigated) {
      // Backend issues the account immediately on register (no separate email
      // OTP gate in this environment). Instead of pushing the legacy OTP screen,
      // move the user to the Login tab with their email prefilled.
      if (mounted) {
        final email = _registerEmailController.text.trim();
        SmartDialog.showToast(context.l10n.authRegisterSuccessPleaseLogin);
        setState(() {
          _isLoginTab = true;
          _loginEmailController.text = email;
        });
        _registerProvider.reset();
      }
    }
  }

  @override
  void dispose() {
    _termsRecognizer.dispose();
    _loginProvider.removeListener(_onLoginStateChanged);
    _registerProvider.removeListener(_onRegisterStateChanged);
    _loginEmailController.dispose();
    _loginPasswordController.dispose();
    _registerFullNameController.dispose();
    _registerEmailController.dispose();
    _registerPhoneController.dispose();
    _registerPasswordController.dispose();
    _loginProvider.dispose();
    _registerProvider.dispose();
    super.dispose();
  }

  void _handleLogin() {
    if (!_loginFormKey.currentState!.validate()) return;
    _loginProvider.login(
      email: _loginEmailController.text.trim(),
      password: _loginPasswordController.text.trim(),
    );
  }

  void _handleRegister() {
    if (!_registerFormKey.currentState!.validate()) return;
    if (!_agreeToTerms) {
      SmartDialog.showToast(context.l10n.authPleaseAcceptTerms);
      return;
    }
    _registerProvider.register(
      phoneNumber: _registerPhoneController.text.trim(),
      fullName: _registerFullNameController.text.trim().isNotEmpty
          ? _registerFullNameController.text.trim()
          : null,
      email: _registerEmailController.text.trim().isNotEmpty
          ? _registerEmailController.text.trim()
          : null,
      password: _registerPasswordController.text.trim().isNotEmpty
          ? _registerPasswordController.text.trim()
          : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    final baseMaxHeight = _isLoginTab
        ? screenHeight * 0.74
        : screenHeight * 0.92;
    final maxHeight = (baseMaxHeight - keyboardHeight).clamp(
      screenHeight * 0.35,
      baseMaxHeight,
    );

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: _loginProvider),
          ChangeNotifierProvider.value(value: _registerProvider),
        ],
        child: Padding(
          padding: EdgeInsets.only(bottom: keyboardHeight),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.white, // White background
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(32),
                topRight: Radius.circular(32),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 20,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            constraints: BoxConstraints(maxHeight: maxHeight),
            child: SafeArea(
              bottom: true,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Drag Handle
                  Center(
                    child: Container(
                      margin: const EdgeInsets.only(top: 14, bottom: 18),
                      width: 45,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(2.5),
                      ),
                    ),
                  ),

                  // Tabs
                  _buildTabSwitch(),

                  // Scrolling Form Content
                  Flexible(
                    fit: FlexFit.loose,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24.0,
                          vertical: 16.0,
                        ),
                        child: _isLoginTab
                            ? _buildLoginForm()
                            : _buildRegisterForm(),
                      ),
                    ),
                  ),

                  // Bottom Action Button
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      24,
                      8,
                      24,
                      24,
                    ), // Added more bottom padding
                    child: _isLoginTab
                        ? _buildLoginButton()
                        : _buildRegisterButton(),
                  ),
                  const SizedBox(height: 12), // Extra space to clear navbar
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabSwitch() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24.0),
      decoration: BoxDecoration(
        color: AppColors.grey100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _isLoginTab = false),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: !_isLoginTab ? AppColors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: !_isLoginTab
                      ? [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Text(
                  context.l10n.authRegister,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: !_isLoginTab
                        ? FontWeight.w600
                        : FontWeight.normal,
                    color: !_isLoginTab
                        ? Colors.black
                        : Colors.black.withValues(alpha: 0.5),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _isLoginTab = true),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: _isLoginTab ? AppColors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: _isLoginTab
                      ? [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Text(
                  context.l10n.authLogin,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: _isLoginTab
                        ? FontWeight.w600
                        : FontWeight.normal,
                    color: _isLoginTab
                        ? Colors.black
                        : Colors.black.withValues(alpha: 0.5),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginForm() {
    return Form(
      key: _loginFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildTextField(
            controller: _loginEmailController,
            label: 'Email',
            hintText: 'name@example.com',
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value == null || value.trim().isEmpty)
                return context.l10n.authEnterEmail;
              return null;
            },
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _loginPasswordController,
            label: context.l10n.commonPassword,
            hintText: context.l10n.authPasswordHint,
            isPassword: true,
            obscureText: _obscureLoginPassword,
            onTogglePassword: () =>
                setState(() => _obscureLoginPassword = !_obscureLoginPassword),
            validator: (value) {
              if (value == null || value.trim().isEmpty)
                return context.l10n.authEnterPassword;
              return null;
            },
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => context.push(AppRouter.forgotPassword),
              child: Text(
                context.l10n.authForgotPasswordQuestion,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.success,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          // Đăng nhập khuôn mặt chỉ hiện khi backend có AI service.
          if (FeatureFlags.faceRecognitionEnabled) ...[
            const SizedBox(height: 8),
            _buildFaceIdButton(),
          ],
          const SizedBox(height: 16),
          _buildSocialLoginSection(),
          Consumer<LoginProvider>(
            builder: (context, provider, _) {
              if (provider.error != null) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    provider.error!,
                    style: const TextStyle(
                      color: AppColors.error,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFaceIdButton() {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () {
        Navigator.of(context).pop();
        context.push(AppRouter.faceVerify);
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.black),
        ),
        child: Text(
          context.l10n.authFaceLogin,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildRegisterForm() {
    return Form(
      key: _registerFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildTextField(
            controller: _registerFullNameController,
            label: context.l10n.commonFullName,
            hintText: context.l10n.commonFullNameHint,
            keyboardType: TextInputType.name,
            textCapitalization: TextCapitalization.words,
            validator: (value) {
              if (value == null || value.trim().isEmpty)
                return context.l10n.authEnterFullName;
              return null;
            },
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _registerEmailController,
            label: 'Email',
            hintText: 'name@example.com',
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value == null || value.trim().isEmpty)
                return context.l10n.authEnterEmail;
              return null;
            },
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _registerPhoneController,
            label: context.l10n.commonPhoneNumber,
            hintText: '0901234567',
            keyboardType: TextInputType.phone,
            validator: (value) {
              if (value == null || value.trim().isEmpty)
                return context.l10n.authEnterPhone;
              return null;
            },
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _registerPasswordController,
            label: context.l10n.commonPassword,
            hintText: context.l10n.authPasswordHint,
            isPassword: true,
            obscureText: _obscureRegisterPassword,
            onTogglePassword: () => setState(
              () => _obscureRegisterPassword = !_obscureRegisterPassword,
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty)
                return context.l10n.authEnterPassword;
              if (value.length < 6) return context.l10n.authPasswordMin6;
              return null;
            },
          ),
          const SizedBox(height: 16),
          _buildTermsCheckbox(),
          const SizedBox(height: 16),
          _buildSocialLoginSection(),
          Consumer<RegisterProvider>(
            builder: (context, provider, _) {
              if (provider.error != null) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    provider.error!,
                    style: const TextStyle(
                      color: AppColors.error,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hintText,
    TextInputType? keyboardType,
    TextCapitalization textCapitalization = TextCapitalization.none,
    bool isPassword = false,
    bool obscureText = false,
    VoidCallback? onTogglePassword,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label *',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black.withValues(alpha: 0.9),
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          textCapitalization: textCapitalization,
          obscureText: obscureText,
          validator: validator,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w400,
              color: Colors.black.withValues(alpha: 0.4),
            ),
            filled: true,
            fillColor: Colors.black.withValues(alpha: 0.05),
            suffixIcon: isPassword
                ? IconButton(
                    icon: Icon(
                      obscureText
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      color: AppColors.onSurfaceVariant,
                    ),
                    onPressed: onTogglePassword,
                  )
                : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.border, width: 1),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Colors.black.withValues(alpha: 0.1),
                width: 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.success, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.error, width: 1),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTermsCheckbox() {
    return Row(
      children: [
        Checkbox(
          value: _agreeToTerms,
          onChanged: (value) => setState(() => _agreeToTerms = value ?? false),
          activeColor: AppColors.success,
          side: const BorderSide(color: Colors.black, width: 1.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        ),
        Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _agreeToTerms = !_agreeToTerms),
            child: RichText(
              text: TextSpan(
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.black.withValues(alpha: 0.7),
                ),
                children: [
                  TextSpan(
                    text: context.l10n.authAgreePrefix,
                    style: TextStyle(
                      color: Colors.black.withValues(alpha: 0.7),
                    ),
                  ),
                  TextSpan(
                    text: context.l10n.commonTermsOfUse,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.success,
                      decoration: TextDecoration.underline,
                    ),
                    recognizer: _termsRecognizer,
                  ),
                  TextSpan(text: '.'),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoginButton() {
    return Consumer<LoginProvider>(
      builder: (context, provider, _) {
        return SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: !provider.isLoading ? _handleLogin : null,
            style: _buttonStyle(),
            child: provider.isLoading
                ? _buildLoadingState()
                : Text(
                    context.l10n.authLogin,
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
          ),
        );
      },
    );
  }

  Widget _buildRegisterButton() {
    return Consumer<RegisterProvider>(
      builder: (context, provider, _) {
        return SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _agreeToTerms && !provider.isLoading
                ? _handleRegister
                : null,
            style: _buttonStyle(),
            child: provider.isLoading
                ? _buildLoadingState()
                : Text(
                    context.l10n.authCreateAccount,
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
          ),
        );
      },
    );
  }

  ButtonStyle _buttonStyle() {
    return ElevatedButton.styleFrom(
      backgroundColor: AppColors.success,
      foregroundColor: Colors.white,
      disabledBackgroundColor: AppColors.grey300,
      disabledForegroundColor: AppColors.grey500,
      padding: const EdgeInsets.symmetric(vertical: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 0,
    );
  }

  Widget _buildLoadingState() {
    return const SizedBox(
      height: 20,
      width: 20,
      child: CircularProgressIndicator(
        strokeWidth: 2,
        valueColor: AlwaysStoppedAnimation<Color>(AppColors.white),
      ),
    );
  }

  Widget _buildSocialLoginSection() {
    // Web chưa cấu hình Firebase ⇒ không có nút nào (chỉ đăng nhập email);
    // Facebook ẩn theo FeatureFlags.facebookLoginEnabled.
    final options = SocialLoginOptions.current();
    if (!options.any) return const SizedBox.shrink();
    final buttons = <Widget>[
      if (options.google)
        _buildSocialButton(
          icon: Icons.g_mobiledata,
          label: 'Google',
          onTap: () => _loginProvider.loginWithGoogle(),
        ),
      if (options.facebook)
        _buildSocialButton(
          icon: Icons.facebook,
          iconColor: const Color(0xFF1877F2),
          label: 'Facebook',
          onTap: () => _loginProvider.loginWithFacebook(),
        ),
      if (options.phone)
        _buildSocialButton(
          icon: Icons.phone_android,
          label: context.l10n.commonPhoneShort,
          onTap: () => _showPhoneOtpDialog(),
        ),
    ];
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: Divider(color: Colors.black.withOpacity(0.1))),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                context.l10n.authOrContinueWith,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.black.withOpacity(0.5),
                ),
              ),
            ),
            Expanded(child: Divider(color: Colors.black.withOpacity(0.1))),
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

  Widget _buildSocialButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? iconColor,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.black.withOpacity(0.1)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 22, color: iconColor),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPhoneOtpDialog() =>
      PhoneOtpDialog.show(_loginProvider, accentColor: AppColors.success);
}
