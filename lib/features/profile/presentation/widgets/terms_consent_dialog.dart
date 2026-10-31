import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_laundry_locker/core/routing/app_router.dart';
import 'package:smart_laundry_locker/features/profile/domain/account_reminders.dart';
import 'package:smart_laundry_locker/features/profile/presentation/providers/profile_provider.dart';

/// Hộp thoại bắt buộc lần đầu đăng nhập: khách phải tích "Tôi đã đọc và đồng ý" rồi bấm "Đồng ý và tiếp tục"
/// mới dùng app; lựa chọn khác duy nhất là đăng xuất. Đồng ý ⇒ `POST /api/user/terms` (DB lưu `true`).
class TermsConsentDialog extends StatefulWidget {
  const TermsConsentDialog({super.key, required this.profileProvider, required this.onSignOut});

  final ProfileProvider profileProvider;
  final Future<void> Function() onSignOut;

  /// `true` khi đã đồng ý và lưu được; `false` khi người dùng chọn đăng xuất.
  static Future<bool> show(
    BuildContext context, {
    required ProfileProvider profileProvider,
    required Future<void> Function() onSignOut,
  }) async {
    final accepted = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => TermsConsentDialog(profileProvider: profileProvider, onSignOut: onSignOut),
    );
    return accepted ?? false;
  }

  @override
  State<TermsConsentDialog> createState() => _TermsConsentDialogState();
}

class _TermsConsentDialogState extends State<TermsConsentDialog> {
  bool _checked = false;
  bool _saving = false;
  String? _error;

  Future<void> _accept() async {
    setState(() {
      _saving = true;
      _error = null;
    });
    final error = await widget.profileProvider.acceptTerms(currentTermsVersion);
    if (!mounted) return;
    if (error == null) {
      Navigator.of(context).pop(true);
      return;
    }
    setState(() {
      _saving = false;
      _error = error;
    });
  }

  Future<void> _signOut() async {
    setState(() => _saving = true);
    Navigator.of(context).pop(false);
    await widget.onSignOut();
  }

  void _openTerms(String title, String asset) => context.push(
    AppRouter.policy,
    extra: {'title': title, 'assetPath': asset},
  );

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    return PopScope(
      canPop: false,
      child: AlertDialog(
        key: const ValueKey('terms-consent-dialog'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Điều khoản dịch vụ'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Trước khi dùng Lock.R, vui lòng đọc và đồng ý với Điều khoản dịch vụ và Chính sách bảo mật. '
                'Điều khoản quy định việc thuê tủ, gửi và nhận hàng, giao hàng bằng drone, phí, hoàn tiền và '
                'bồi thường khi có sự cố.',
                style: TextStyle(fontSize: 14, height: 1.45, color: muted),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 4,
                children: [
                  TextButton(
                    onPressed: _saving
                        ? null
                        : () => _openTerms('Điều khoản sử dụng', 'assets/markdown/terms_of_service.md'),
                    child: const Text('Đọc Điều khoản dịch vụ'),
                  ),
                  TextButton(
                    onPressed: _saving
                        ? null
                        : () => _openTerms('Chính sách bảo mật', 'assets/markdown/privacy_policy.md'),
                    child: const Text('Đọc Chính sách bảo mật'),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              CheckboxListTile(
                key: const ValueKey('terms-consent-check'),
                value: _checked,
                onChanged: _saving ? null : (v) => setState(() => _checked = v ?? false),
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                title: const Text(
                  'Tôi đã đọc và đồng ý với Điều khoản dịch vụ và Chính sách bảo mật của Lock.R.',
                  style: TextStyle(fontSize: 14),
                ),
              ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 13)),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: _saving ? null : _signOut,
            child: const Text('Đăng xuất'),
          ),
          ElevatedButton(
            key: const ValueKey('terms-consent-accept'),
            onPressed: _saving || !_checked ? null : _accept,
            child: _saving
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Đồng ý và tiếp tục'),
          ),
        ],
      ),
    );
  }
}
