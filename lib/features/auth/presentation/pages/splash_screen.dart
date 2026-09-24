import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:smart_laundry_locker/core/routing/app_router.dart';
import 'package:smart_laundry_locker/core/routing/role_routes.dart';
import 'package:smart_laundry_locker/core/services/biometric_service.dart';
import 'package:smart_laundry_locker/core/services/token_service.dart';
import 'package:smart_laundry_locker/shared/shared.dart';
import 'package:smart_laundry_locker/shared/widgets/app_lottie.dart';

const String _kFastDeliveryLottie = 'assets/animations/fast_shopping_delivery.json';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  // Khóa sinh trắc: hiện nút thử lại khi xác thực thất bại/hủy.
  bool _bioBlocked = false;

  late final AnimationController _animCtrl;
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animCtrl,
      curve: Curves.easeOut,
    );
    _scaleAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(
        parent: _animCtrl,
        curve: Curves.easeOutBack,
      ),
    );
    _animCtrl.forward();

    _checkAuthAndNavigate();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  Future<void> _checkAuthAndNavigate() async {
    // Thời gian hiển thị splash screen tầm 4s theo yêu cầu
    await Future<void>.delayed(const Duration(seconds: 4));
    if (!mounted) return;

    final hasToken = await TokenService.hasToken();
    if (!mounted) return;
    if (hasToken) {
      // App-lock sinh trắc học (bật trong Hồ sơ → Bảo mật).
      if (await BiometricService.isEnabled() &&
          await BiometricService.isSupported()) {
        final ok = await BiometricService.authenticate(
          reason: 'Xác thực để mở Lock.R',
        );
        if (!mounted) return;
        if (!ok) {
          setState(() => _bioBlocked = true);
          return;
        }
      }
      if (!mounted) return;
      final roles = await TokenService.getCurrentRoles();
      if (!mounted) return;
      context.go(homeForRoles(roles));
    } else {
      context.go(AppRouter.onboarding);
    }
  }

  Future<void> _retryBiometric() async {
    setState(() => _bioBlocked = false);
    final ok = await BiometricService.authenticate(
      reason: 'Xác thực để mở Lock.R',
    );
    if (!mounted) return;
    if (ok) {
      final roles = await TokenService.getCurrentRoles();
      if (!mounted) return;
      context.go(homeForRoles(roles));
    } else {
      setState(() => _bioBlocked = true);
    }
  }

  Future<void> _signOutInstead() async {
    await TokenService.clearTokens();
    if (!mounted) return;
    context.go(AppRouter.onboarding);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          color: Colors.white,
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: Stack(
                children: [
                  // Ambient soft decorative circles for subtle depth on white
                  Positioned(
                    top: -50,
                    right: -40,
                    child: Container(
                      width: 220,
                      height: 220,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFFE0F2FE).withValues(alpha: 0.5),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: -60,
                    left: -50,
                    child: Container(
                      width: 240,
                      height: 240,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFFF0FDF4).withValues(alpha: 0.6),
                      ),
                    ),
                  ),

                  // Main Content
                  Center(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(height: 10),

                          // ── 1. LOGO Ở TRÊN ──────────────────────────────────────
                          Container(
                            width: 86,
                            height: 86,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF0F172A).withValues(alpha: 0.08),
                                  blurRadius: 20,
                                  spreadRadius: 2,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(24),
                              child: Image.asset(
                                'assets/images/logo.png',
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    color: const Color(0xFF0F172A),
                                    child: const Icon(
                                      LucideIcons.box,
                                      size: 40,
                                      color: Colors.white,
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),

                          // App Name & Tagline
                          const Text(
                            'LOCK.R',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 3.5,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: const Color(0xFFE2E8F0),
                              ),
                            ),
                            child: const Text(
                              'Hệ thống tủ khóa thông minh 24/7',
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.3,
                                color: Color(0xFF475569),
                              ),
                            ),
                          ),

                          const SizedBox(height: 20),

                          // ── 2. LOTTIE ANIMATION PHÓNG TO Ở DƯỚI LOGO ────────────
                          Container(
                            width: 320,
                            height: 320,
                            alignment: Alignment.center,
                            child: const AppLottie(
                              _kFastDeliveryLottie,
                              animate: true,
                              repeat: true,
                              fit: BoxFit.contain,
                            ),
                          ),

                          const SizedBox(height: 20),

                          // ── 3. LOADING INDICATOR HOẶC BIOMETRIC PROMPT ──────────
                          if (!_bioBlocked) ...[
                            SizedBox(
                              width: 140,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: const LinearProgressIndicator(
                                  minHeight: 4,
                                  backgroundColor: Color(0xFFE2E8F0),
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Color(0xFF0077B6),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            const Text(
                              'Đang tải...',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF94A3B8),
                              ),
                            ),
                          ] else ...[
                            // Biometric prompt card
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(
                                  color: const Color(0xFFE2E8F0),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.05),
                                    blurRadius: 16,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Column(
                                children: [
                                  const Text(
                                    'Cần xác thực sinh trắc học để tiếp tục',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: Color(0xFF475569),
                                    ),
                                  ),
                                  const SizedBox(height: 14),
                                  ElevatedButton.icon(
                                    onPressed: _retryBiometric,
                                    icon: const Icon(LucideIcons.fingerprint, size: 20),
                                    label: const Text(
                                      'Xác thực vân tay / Face ID',
                                      style: TextStyle(fontWeight: FontWeight.w700),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF003D5B),
                                      foregroundColor: Colors.white,
                                      elevation: 0,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 24,
                                        vertical: 14,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  TextButton(
                                    onPressed: _signOutInstead,
                                    child: const Text(
                                      'Đăng xuất và dùng mật khẩu',
                                      style: TextStyle(
                                        color: Color(0xFF64748B),
                                        fontSize: 13.5,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
