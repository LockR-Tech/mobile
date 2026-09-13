import 'package:smart_laundry_locker/features/auth/presentation/widgets/auth_bottom_sheet.dart';
import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

class UnauthenticatedPlaceholder extends StatelessWidget {
  final String message;
  final VoidCallback? onAuthSuccess;

  const UnauthenticatedPlaceholder({
    super.key,
    this.message = 'Bạn cần đăng nhập để sử dụng tính năng này',
    this.onAuthSuccess,
  });

  Future<void> _showAuthSheet(BuildContext context, bool isLogin) async {
    final result = await AuthBottomSheet.show(context, isLogin: isLogin);
    if (result == true) {
      onAuthSuccess?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.lock_outline,
                size: 64,
                color: theme.colorScheme.mutedForeground.withOpacity(0.5),
              ),
              const SizedBox(height: 24),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.foreground,
                ),
              ),
              const SizedBox(height: 32),
              // Login Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _showAuthSheet(context, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.primaryForeground,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Đăng Nhập',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Register Button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => _showAuthSheet(context, false),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: BorderSide(color: theme.colorScheme.border),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Đăng Ký',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
