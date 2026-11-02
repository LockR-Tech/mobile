import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_laundry_locker/core/l10n/l10n.dart';
import 'package:smart_laundry_locker/core/services/session_service.dart';
import 'package:smart_laundry_locker/features/locker_ops/presentation/widgets/ops_widgets.dart';

/// ADMIN signs in on mobile → the admin console only exists on the web app,
/// so show a notice and offer sign-out. Mobile keeps 3 roles: customer,
/// DRONE_TECHNICIAN (drone fleet) and LOCKER_TECHNICIAN (locker maintenance
/// + IoT).
class AdminWebNoticePage extends StatelessWidget {
  const AdminWebNoticePage({super.key});

  Future<void> _logout(BuildContext context) async {
    await SessionService.logout();
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
                Text(
                  context.l10n.techUiAdminAccountTitle,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: opsDark,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  context.l10n.techUiAdminWebOnly,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 14, color: opsMutedText),
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _logout(context),
                    icon: const Icon(Icons.logout, size: 18),
                    label: Text(context.l10n.commonLogout),
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
