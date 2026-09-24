import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:smart_laundry_locker/core/routing/app_router.dart';
import 'package:smart_laundry_locker/core/routing/role_routes.dart';
import 'package:smart_laundry_locker/core/services/biometric_service.dart';
import 'package:smart_laundry_locker/core/services/token_service.dart';
import 'package:smart_laundry_locker/shared/shared.dart';

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
    await Future<void>.delayed(const Duration(seconds: 2));
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
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF061426),
              Color(0xFF0A2240),
              Color(0xFF0F325E),
            ],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: Stack(
                children: [
                  // Ambient glowing circles for depth & glass aesthetic
                  Positioned(
                    top: -60,
                    right: -50,
                    child: Container(
                      width: 240,
                      height: 240,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF00B4D8).withValues(alpha: 0.12),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: -80,
                    left: -60,
                    child: Container(
                      width: 260,
                      height: 260,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF0077B6).withValues(alpha: 0.15),
                      ),
                    ),
                  ),

                  // Main Content
                  Center(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(height: 10),

                          // ── 1. LOGO Ở TRÊN ──────────────────────────────────────
                          Container(
                            width: 88,
                            height: 88,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(26),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.8),
                                width: 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF00B4D8).withValues(alpha: 0.35),
                                  blurRadius: 28,
                                  spreadRadius: 2,
                                  offset: const Offset(0, 8),
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
                                      size: 42,
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
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.15),
                              ),
                            ),
                            child: const Text(
                              'Hệ thống tủ khóa thông minh 24/7',
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w500,
                                letterSpacing: 0.4,
                                color: Color(0xFFE2E8F0),
                              ),
                            ),
                          ),

                          const SizedBox(height: 24),

                          // ── 2. LOTTIE ANIMATION Ở DƯỚI LOGO ─────────────────────
                          Container(
                            width: 250,
                            height: 250,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF0077B6).withValues(alpha: 0.18),
                                  blurRadius: 40,
                                  spreadRadius: 10,
                                ),
                              ],
                            ),
                            child: const AppLottie(
                              AppLottieAssets.fastDelivery,
                              animate: true,
                              repeat: true,
                              fit: BoxFit.contain,
                            ),
                          ),

                          const SizedBox(height: 28),

                          // ── 3. LOADING INDICATOR HOẶC BIOMETRIC PROMPT ──────────
                          if (!_bioBlocked) ...[
                            SizedBox(
                              width: 140,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: const LinearProgressIndicator(
                                  minHeight: 4,
                                  backgroundColor: Color(0x33FFFFFF),
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Color(0xFF00B4D8),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Đang tải...',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: Colors.white.withValues(alpha: 0.65),
                              ),
                            ),
                          ] else ...[
                            // Biometric prompt card
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.18),
                                ),
                              ),
                              child: Column(
                                children: [
                                  const Text(
                                    'Cần xác thực sinh trắc học để tiếp tục',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: Color(0xFFE2E8F0),
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
                                      backgroundColor: const Color(0xFF00B4D8),
                                      foregroundColor: const Color(0xFF001F2D),
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
                                    child: Text(
                                      'Đăng xuất và dùng mật khẩu',
                                      style: TextStyle(
                                        color: Colors.white.withValues(alpha: 0.7),
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
