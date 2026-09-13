import 'package:smart_laundry_locker/core/constants/app_colors.dart';
import 'package:smart_laundry_locker/core/network/api_client.dart';
import 'package:smart_laundry_locker/core/routing/app_router.dart';
import 'package:smart_laundry_locker/features/auth/presentation/providers/auth_injection.dart';
import 'package:smart_laundry_locker/features/auth/presentation/providers/verify_otp_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class OtpPage extends StatefulWidget {
  final String? phoneNumber;
  final String? email;

  const OtpPage({super.key, this.phoneNumber, this.email});

  @override
  State<OtpPage> createState() => _OtpPageState();
}

class _OtpPageState extends State<OtpPage> {
  final List<TextEditingController> _controllers = List.generate(
    6,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  late VerifyOtpProvider _verifyOtpProvider;

  bool get _isComplete {
    return _controllers.every((controller) => controller.text.isNotEmpty);
  }

  @override
  void initState() {
    super.initState();
    final apiClient = ApiClient();
    _verifyOtpProvider = AuthInjection.provideVerifyOtpProvider(apiClient);
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var focusNode in _focusNodes) {
      focusNode.dispose();
    }
    _verifyOtpProvider.dispose();
    super.dispose();
  }

  void _onChanged(int index, String value) {
    if (value.length > 1) {
      final chars = value.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '').toUpperCase();
      for (int i = 0; i < _controllers.length && i < chars.length; i++) {
        _controllers[i].text = chars[i];
        if (i < _focusNodes.length - 1) {
          _focusNodes[i + 1].requestFocus();
        }
      }
      if (chars.length == 6) {
        _focusNodes[5].unfocus();
      }
      return;
    }

    if (value.isNotEmpty) {
      final upper = value.toUpperCase();
      if (value != upper) {
        _controllers[index].value = TextEditingValue(
          text: upper,
          selection: TextSelection.collapsed(offset: upper.length),
        );
      }
      if (index < _controllers.length - 1) {
        _focusNodes[index + 1].requestFocus();
      } else {
        _focusNodes[index].unfocus();
      }
    } else {
      if (index > 0) {
        _focusNodes[index - 1].requestFocus();
      }
    }
    setState(() {});
  }

  void _onContinue() {
    if (_isComplete) {
      final otp = _controllers.map((c) => c.text).join();
      _verifyOtpProvider.verifyOtp(
        phoneNumber: null,
        email: widget.email,
        otp: otp,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _verifyOtpProvider,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.onBackground),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: const Text(
            'Xác thực OTP',
            style: TextStyle(
              color: AppColors.onBackground,
              fontWeight: FontWeight.w600,
            ),
          ),
          centerTitle: true,
        ),
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 40),
                      const Text(
                        'Nhập mã OTP',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.onBackground,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      if (widget.email != null)
                        Text(
                          'Mã OTP đã được gửi đến ${widget.email}',
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.onSurfaceVariant,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      const SizedBox(height: 40),

                      // OTP Input Fields
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: List.generate(6, (index) {
                          return SizedBox(
                            width: 45,
                            height: 60,
                            child: TextField(
                              controller: _controllers[index],
                              focusNode: _focusNodes[index],
                              textAlign: TextAlign.center,
                              keyboardType: TextInputType.text,
                              textCapitalization: TextCapitalization.characters,
                              maxLength: 1,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: AppColors.onBackground,
                              ),
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(
                                  RegExp(r'[a-zA-Z0-9]'),
                                ),
                              ],
                              decoration: InputDecoration(
                                counterText: '',
                                filled: true,
                                fillColor: AppColors.surface,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: _focusNodes[index].hasFocus
                                        ? AppColors.success
                                        : AppColors.outlineVariant,
                                    width: 2,
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: AppColors.outlineVariant,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: AppColors.success,
                                    width: 2,
                                  ),
                                ),
                              ),
                              onChanged: (value) => _onChanged(index, value),
                            ),
                          );
                        }),
                      ),
                      const SizedBox(height: 40),

                      // Error Message
                      Consumer<VerifyOtpProvider>(
                        builder: (context, provider, child) {
                          if (provider.error != null) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: Text(
                                provider.error!,
                                style: const TextStyle(
                                  color: AppColors.error,
                                  fontSize: 14,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),

                      // Continue Button
                      Consumer<VerifyOtpProvider>(
                        builder: (context, provider, child) {
                          return ElevatedButton(
                            onPressed: _isComplete && !provider.isLoading
                                ? _onContinue
                                : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.success,
                              foregroundColor: AppColors.white,
                              disabledBackgroundColor: AppColors.grey300,
                              disabledForegroundColor: AppColors.grey500,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                            child: provider.isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        AppColors.white,
                                      ),
                                    ),
                                  )
                                : const Text(
                                    'Tiếp tục',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                          );
                        },
                      ),

                      Consumer<VerifyOtpProvider>(
                        builder: (context, provider, child) {
                          if (provider.isSuccess) {
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              if (!mounted) return;
                              context.go(AppRouter.home);
                            });
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ],
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
