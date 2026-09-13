import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_laundry_locker/core/routing/app_router.dart';
import 'package:smart_laundry_locker/core/services/biometric_service.dart';
import 'package:smart_laundry_locker/core/services/token_service.dart';
import 'package:smart_laundry_locker/core/theme/shadcn_theme.dart';
import 'package:smart_laundry_locker/core/routing/role_routes.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  // Khóa sinh trắc: hiện nút thử lại khi xác thực thất bại/hủy.
  bool _bioBlocked = false;

  @override
  void initState() {
    super.initState();
    _checkAuthAndNavigate();
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
          reason: 'Xác thực để mở Lockerly',
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
      reason: 'Xác thực để mở Lockerly',
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
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(32),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0A2342).withValues(alpha: 0.2),
                    blurRadius: 24,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(32),
                child: Image.asset(
                  'assets/images/logo.png',
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.white,
                      child: const Icon(
                        LucideIcons.box,
                        size: 64,
                        color: AISLShadcnTheme.navyPrimary,
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'LOCKERLY',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
                color: Color(0xFF1E293B),
              ),
            ),
            if (_bioBlocked) ...[
              const SizedBox(height: 28),
              const Text(
                'Cần xác thực sinh trắc học để tiếp tục',
                style: TextStyle(fontSize: 14, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: _retryBiometric,
                icon: const Icon(LucideIcons.fingerprint, size: 18),
                label: const Text('Xác thực lại'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AISLShadcnTheme.navyPrimary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              TextButton(
                onPressed: _signOutInstead,
                child: const Text(
                  'Đăng xuất và dùng mật khẩu',
                  style: TextStyle(color: Color(0xFF64748B)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
