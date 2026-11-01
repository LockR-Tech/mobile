import 'package:flutter/material.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:smart_laundry_locker/core/routing/app_router.dart';
import 'package:smart_laundry_locker/features/profile/domain/profile_completion.dart';
import 'package:smart_laundry_locker/features/profile/presentation/providers/profile_provider.dart';

import 'package:smart_laundry_locker/core/l10n/l10n.dart';
/// "Hoàn tất đăng ký" sau khi đăng nhập bằng SĐT: tài khoản backend tự tạo chỉ
/// có tên "User" ⇒ hỏi họ tên (email tuỳ chọn) và lưu qua
/// `PUT /api/user/profile`. "Để sau" đóng hộp thoại; lần đăng nhập SĐT sau vẫn
/// hỏi lại cho tới khi hồ sơ có tên thật.
class CompleteProfileDialog extends StatefulWidget {
  const CompleteProfileDialog({
    super.key,
    required this.profileProvider,
    required this.askEmail,
  });

  final ProfileProvider profileProvider;

  /// Hồ sơ chưa có email ⇒ cho nhập thêm (không bắt buộc).
  final bool askEmail;

  /// Tải hồ sơ rồi hỏi nếu còn tên mặc định. Gọi SAU khi đã điều hướng khỏi
  /// màn đăng nhập: hộp thoại mở trên navigator gốc.
  static Future<void> maybeShow(ProfileProvider profileProvider) async {
    await profileProvider.loadProfile();
    // Chờ trang chủ dựng xong để hộp thoại không bám vào route đăng nhập cũ.
    await WidgetsBinding.instance.endOfFrame;
    final profile = profileProvider.profile;
    if (!profileProvider.hasServerProfile || !needsProfileCompletion(profile)) {
      return;
    }
    final context = AppRouter.navigatorKey.currentContext;
    if (context == null || !context.mounted) return;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => CompleteProfileDialog(
        profileProvider: profileProvider,
        askEmail: (profile?.email ?? '').trim().isEmpty,
      ),
    );
  }

  @override
  State<CompleteProfileDialog> createState() => _CompleteProfileDialogState();
}

class _CompleteProfileDialogState extends State<CompleteProfileDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _saving = true;
      _error = null;
    });
    final email = _emailController.text.trim();
    // Họ tên được tách như lúc đăng ký: từ cuối = lastName, phần còn lại =
    // firstName (buildProfileUpdateBody).
    await widget.profileProvider.updateProfile(
      fullName: _nameController.text.trim().replaceAll(RegExp(r'\s+'), ' '),
      email: widget.askEmail && email.isNotEmpty ? email : null,
    );
    if (!mounted) return;
    if (widget.profileProvider.isSuccess) {
      Navigator.of(context).pop();
      SmartDialog.showToast(context.l10n.authProfileSaved);
      return;
    }
    setState(() {
      _saving = false;
      _error =
          widget.profileProvider.error ??
          context.l10n.authProfileSaveFailed;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(context.l10n.authCompleteRegistration),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                context.l10n.authCompleteRegistrationBody,
                style: TextStyle(fontSize: 14, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                autofocus: true,
                enabled: !_saving,
                keyboardType: TextInputType.name,
                textCapitalization: TextCapitalization.words,
                autofillHints: const [AutofillHints.name],
                textInputAction: widget.askEmail
                    ? TextInputAction.next
                    : TextInputAction.done,
                decoration: InputDecoration(
                  labelText: context.l10n.commonFullName,
                  hintText: context.l10n.commonFullNameHint,
                  border: OutlineInputBorder(),
                ),
                validator: validateCompletionFullName,
                onFieldSubmitted: (_) {
                  if (!widget.askEmail) _save();
                },
              ),
              if (widget.askEmail) ...[
                const SizedBox(height: 12),
                TextFormField(
                  controller: _emailController,
                  enabled: !_saving,
                  keyboardType: TextInputType.emailAddress,
                  autofillHints: const [AutofillHints.email],
                  textInputAction: TextInputAction.done,
                  decoration: InputDecoration(
                    labelText: context.l10n.authEmailOptional,
                    hintText: 'name@example.com',
                    border: OutlineInputBorder(),
                  ),
                  validator: validateOptionalEmail,
                  onFieldSubmitted: (_) => _save(),
                ),
              ],
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    _error!,
                    style: const TextStyle(color: Colors.red, fontSize: 13),
                  ),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
          child: Text(context.l10n.commonLater),
        ),
        ElevatedButton(
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(context.l10n.commonSave),
        ),
      ],
    );
  }
}
