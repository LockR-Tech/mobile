import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:smart_laundry_locker/core/utils/phone_utils.dart';
import 'package:smart_laundry_locker/features/auth/presentation/providers/login_provider.dart';

import 'package:smart_laundry_locker/core/l10n/l10n.dart';
/// Hộp thoại đăng nhập / đăng ký bằng số điện thoại (Firebase Phone Auth),
/// dùng chung cho màn đăng nhập và bottom sheet đăng nhập.
///
/// Bước 1 nhập SĐT → gửi mã; bước 2 nhập mã 6 số (đủ 6 số tự xác nhận), có
/// đếm ngược "Gửi lại mã" và "Đổi số điện thoại". Số chưa có tài khoản thì
/// backend tự tạo khi xác nhận mã. Đăng nhập xong hộp thoại tự đóng; màn gọi
/// tự điều hướng theo [LoginProvider.isSuccess].
class PhoneOtpDialog extends StatefulWidget {
  const PhoneOtpDialog({
    super.key,
    required this.provider,
    required this.accentColor,
  });

  final LoginProvider provider;
  final Color accentColor;

  /// Mở hộp thoại ở bước nhập SĐT.
  static void show(LoginProvider provider, {required Color accentColor}) {
    provider.clearPhoneVerification();
    SmartDialog.show(
      builder: (_) =>
          PhoneOtpDialog(provider: provider, accentColor: accentColor),
    );
  }

  @override
  State<PhoneOtpDialog> createState() => _PhoneOtpDialogState();
}

class _PhoneOtpDialogState extends State<PhoneOtpDialog> {
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  Timer? _ticker;
  bool _wasCodeSent = false;
  bool _dismissScheduled = false;

  LoginProvider get _provider => widget.provider;

  @override
  void initState() {
    super.initState();
    _provider.addListener(_onProviderChanged);
  }

  @override
  void dispose() {
    _provider.removeListener(_onProviderChanged);
    _ticker?.cancel();
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  void _onProviderChanged() {
    if (!mounted) return;
    if (_provider.isSuccess && !_dismissScheduled) {
      // Tự xác minh hoặc mã đúng ⇒ đóng; màn gọi lo điều hướng.
      _dismissScheduled = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => SmartDialog.dismiss());
    }
    final codeSent = _provider.isPhoneCodeSent;
    if (codeSent && !_wasCodeSent) _otpController.clear();
    _wasCodeSent = codeSent;
    // Vừa gửi (hoặc gửi lại) mã ⇒ chạy đếm ngược "Gửi lại mã".
    if (codeSent &&
        _provider.resendSecondsLeft() > 0 &&
        !(_ticker?.isActive ?? false)) {
      _startTicker();
    }
    setState(() {});
  }

  /// Mỗi giây vẽ lại đếm ngược "Gửi lại mã"; hết giờ thì dừng.
  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted || _provider.resendSecondsLeft() == 0) timer.cancel();
      if (mounted) setState(() {});
    });
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (_provider.isPhoneCodeSent) {
      await _provider.confirmPhoneOtp(_otpController.text);
    } else {
      await _provider.sendPhoneOtp(_phoneController.text);
    }
  }

  Future<void> _resend() async {
    _otpController.clear();
    await _provider.resendPhoneOtp();
  }

  void _changeNumber() {
    _ticker?.cancel();
    _otpController.clear();
    _provider.clearPhoneVerification();
  }

  @override
  Widget build(BuildContext context) {
    final provider = _provider;
    final codeSent = provider.isPhoneCodeSent;
    final loading = provider.isLoading;
    final secondsLeft = provider.resendSecondsLeft();
    final sentTo = provider.phoneNumberSentTo;

    return Material(
      color: Colors.transparent,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24),
        padding: const EdgeInsets.all(24),
        constraints: const BoxConstraints(maxWidth: 420),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              codeSent ? context.l10n.authEnterOtp : context.l10n.authPhoneLogin,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              codeSent
                  ? context.l10n.authSmsSentTo(
                      sentTo == null
                          ? context.l10n.authYourNumber
                          : displayPhone(sentTo),
                    )
                  : context.l10n.authPhoneAutoCreateAccount,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 16),
            if (!codeSent) ...[
              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                autofocus: true,
                autofillHints: const [AutofillHints.telephoneNumber],
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9+ ]')),
                  LengthLimitingTextInputFormatter(16),
                ],
                textInputAction: TextInputAction.done,
                onSubmitted: (_) {
                  if (!loading) _submit();
                },
                decoration: InputDecoration(
                  labelText: context.l10n.commonPhoneNumber,
                  hintText: '0912345678',
                  border: OutlineInputBorder(),
                ),
              ),
              Padding(
                padding: EdgeInsets.only(top: 6),
                child: Text(
                  context.l10n.authPhoneFormatHint,
                  style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                ),
              ),
            ] else
              TextField(
                controller: _otpController,
                keyboardType: TextInputType.number,
                autofocus: true,
                autofillHints: const [AutofillHints.oneTimeCode],
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(6),
                ],
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 22,
                  letterSpacing: 8,
                  fontWeight: FontWeight.w700,
                ),
                onChanged: (value) {
                  // Đủ 6 số (gõ tay hoặc tự điền từ SMS) ⇒ xác nhận luôn.
                  if (value.length == 6 && !provider.isLoading) _submit();
                },
                decoration: InputDecoration(
                  labelText: context.l10n.authOtp6Digits,
                  hintText: '------',
                  border: OutlineInputBorder(),
                ),
              ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: loading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: widget.accentColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: loading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(codeSent ? context.l10n.commonConfirm : context.l10n.authSendOtp),
              ),
            ),
            if (codeSent)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: loading ? null : _changeNumber,
                    child: Text(
                      context.l10n.authChangePhone,
                      style: TextStyle(color: widget.accentColor),
                    ),
                  ),
                  TextButton(
                    onPressed: loading || secondsLeft > 0 ? null : _resend,
                    child: Text(
                      secondsLeft > 0
                          ? context.l10n.authResendCodeIn(secondsLeft)
                          : context.l10n.authResendCode,
                      style: TextStyle(
                        color: loading || secondsLeft > 0
                            ? const Color(0xFF94A3B8)
                            : widget.accentColor,
                      ),
                    ),
                  ),
                ],
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
      ),
    );
  }
}
