import 'package:smart_laundry_locker/features/delegations/presentation/providers/delegation_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

class AuthorizedOpeningPage extends StatefulWidget {
  final String? orderId;
  final String? orderCode;
  final String? lockerId;
  final String? accessCode;

  const AuthorizedOpeningPage({
    super.key,
    this.orderId,
    this.orderCode,
    this.lockerId,
    this.accessCode,
  });

  @override
  State<AuthorizedOpeningPage> createState() => _AuthorizedOpeningPageState();
}

class _AuthorizedOpeningPageState extends State<AuthorizedOpeningPage> {
  final _otpController = TextEditingController();
  final _hiddenFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    if (widget.accessCode != null) {
      _otpController.text = widget.accessCode!;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        FocusScope.of(context).requestFocus(_hiddenFocusNode);
      }
    });
  }

  @override
  void dispose() {
    _otpController.dispose();
    _hiddenFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mở tủ ủy quyền'),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 16),
            const Icon(Icons.lock_open_outlined, size: 72, color: Colors.blue),
            const SizedBox(height: 16),
            const Text(
              'Nhập mã ủy quyền',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Vui lòng nhập mã OTP ủy quyền được gửi tới bạn hoặc hiển thị trong danh sách ủy quyền.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
            const SizedBox(height: 32),

            // Hidden TextField để nhập OTP, hiển thị qua 6 ô
            TextField(
              controller: _otpController,
              focusNode: _hiddenFocusNode,
              keyboardType: TextInputType.text,
              textCapitalization: TextCapitalization.characters,
              maxLength: 6,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                counterText: '',
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
              style: const TextStyle(color: Colors.transparent),
              cursorColor: Colors.transparent,
            ),

            const SizedBox(height: 8),
            GestureDetector(
              onTap: () {
                FocusScope.of(context).requestFocus(_hiddenFocusNode);
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(6, (index) {
                  final isFocused =
                      _otpController.text.length == index &&
                      _hiddenFocusNode.hasFocus;
                  final isFilled = index < _otpController.text.length;
                  final char = isFilled ? _otpController.text[index] : '';

                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    width: 44,
                    height: 52,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isFocused
                            ? Colors.blue
                            : (isFilled
                                  ? Colors.blue.withOpacity(0.4)
                                  : Colors.grey.shade300),
                        width: isFocused ? 2 : 1,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      char,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  );
                }),
              ),
            ),

            const SizedBox(height: 64),

            SizedBox(
              width: double.infinity,
              child: Consumer<DelegationProvider>(
                builder: (context, provider, _) {
                  return ElevatedButton(
                    onPressed: provider.isLoading ? null : _onVerifyPressed,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: const StadiumBorder(),
                      elevation: 3,
                    ),
                    child: provider.isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            'Xác nhận mở tủ',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.white,
                            ),
                          ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _onVerifyPressed() async {
    final otp = _otpController.text.trim();
    if (otp.length < 6) {
      SmartDialog.showToast('Vui lòng nhập đủ 6 ký tự');
      return;
    }

    final provider = context.read<DelegationProvider>();

    SmartDialog.showLoading<void>(msg: 'Đang mở tủ...');
    final success = await provider.openLocker(accessCode: otp);
    SmartDialog.dismiss<void>();

    if (success) {
      SmartDialog.showToast('Mở tủ thành công!');
      if (mounted) context.pop();
    } else {
      SmartDialog.showToast(provider.error ?? 'Mở tủ thất bại');
    }
  }
}
