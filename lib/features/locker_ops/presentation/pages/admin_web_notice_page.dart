import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_laundry_locker/core/services/token_service.dart';
import 'package:smart_laundry_locker/features/locker_ops/presentation/widgets/ops_widgets.dart';

/// ADMIN signs in on mobile → the admin console only exists on the web app,
/// so show a notice and offer sign-out. Mobile keeps 3 roles: customer,
/// MAINTENANCE (drone fleet) and TECHNICIAN (locker maintenance + IoT).
class AdminWebNoticePage extends StatelessWidget {
  const AdminWebNoticePage({super.key});

  Future<void> _logout(BuildContext context) async {
    await TokenService.clearTokens();
    if (context.mounted) context.go('/onboarding');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FA),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    color: opsPrimary.withValues(alpha: 0.10),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.desktop_windows_outlined,
                    size: 44,
                    color: opsPrimary,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Tài khoản quản trị',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: opsDark,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Trang quản trị (dashboard, thống kê, quản lý người dùng, '
                  'đơn hàng, khuyến mãi...) chỉ có trên bản web.\n'
                  'Vui lòng đăng nhập bằng trình duyệt để tiếp tục.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: opsMutedText),
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _logout(context),
                    icon: const Icon(Icons.logout, size: 18),
                    label: const Text('Đăng xuất'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: opsPrimary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
