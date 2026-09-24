import 'package:flutter/material.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:intl/intl.dart';
import 'package:smart_laundry_locker/core/config/business_config_provider.dart';
import 'package:smart_laundry_locker/core/constants/app_assets.dart';
import 'package:smart_laundry_locker/core/network/api_client.dart';
import 'package:smart_laundry_locker/core/theme/shadcn_theme.dart';
import 'package:smart_laundry_locker/features/transactions/presentation/providers/transaction_injection.dart';
import 'package:smart_laundry_locker/features/transactions/presentation/providers/transaction_provider.dart';
import 'package:smart_laundry_locker/features/wallet/presentation/providers/wallet_provider.dart';
import 'package:provider/provider.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:smart_laundry_locker/shared/widgets/user_ui_kit.dart';
import 'package:smart_laundry_locker/shared/shared.dart';

class TopUpPage extends StatefulWidget {
  const TopUpPage({super.key});

  @override
  State<TopUpPage> createState() => _TopUpPageState();
}

class _TopUpPageState extends State<TopUpPage> with BusinessConfigStateMixin {
  /// Mốc nạp nhanh + số tiền mặc định do admin cấu hình.
  List<int> get _amounts => businessConfig.topupPresets;
  late int _selectedAmount;
  String _selectedMethod = 'SEPAY';

  /// Người dùng đã tự chọn mốc — cấu hình đổi thì không ghi đè lựa chọn.
  bool _amountTouched = false;
  late final TransactionProvider _provider;

  String _formatCurrency(int amount) {
    return NumberFormat.currency(
      locale: 'vi_VN',
      symbol: 'đ',
    ).format(amount).replaceAll(' ', ' ');
  }

  @override
  void initState() {
    super.initState();
    _selectedAmount = businessConfig.topupDefaultAmount;
    if (businessConfig.isPaymentMethodEnabled('SEPAY')) {
      _selectedMethod = 'SEPAY';
    } else if (businessConfig.isPaymentMethodEnabled('VNPAY')) {
      _selectedMethod = 'VNPAY';
    }
    _provider = TransactionInjection.provideTransactionProvider(ApiClient());
  }

  @override
  void onBusinessConfigChanged(BusinessConfig config) {
    if (!_amountTouched) _selectedAmount = config.topupDefaultAmount;
    if (!config.isPaymentMethodEnabled(_selectedMethod)) {
      if (config.isPaymentMethodEnabled('SEPAY')) {
        _selectedMethod = 'SEPAY';
      } else if (config.isPaymentMethodEnabled('VNPAY')) {
        _selectedMethod = 'VNPAY';
      }
    }
  }

  /// Kiểm tra trước khi gọi API. Trả `false` (và báo lỗi) nếu không nạp được.
  bool _validateTopUp() {
    final config = businessConfig;
    if (!config.isPaymentMethodEnabled(_selectedMethod)) {
      SmartDialog.showToast('Phương thức $_selectedMethod đang tạm ngưng.');
      return false;
    }
    final error = config.validateTopupAmount(_selectedAmount, _formatCurrency);
    if (error != null) {
      SmartDialog.showToast(error);
      return false;
    }
    return true;
  }

  @override
  void dispose() {
    _provider.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenH = MediaQuery.sizeOf(context).height;

    return ChangeNotifierProvider.value(
      value: _provider,
      child: Consumer2<TransactionProvider, WalletProvider>(
        builder: (context, provider, walletProvider, child) {
          return Scaffold(
            backgroundColor: AISLShadcnTheme.navySurface,
            body: Column(
              children: [
                BrandHeroHeader(
                  title: 'Nạp tiền vào ví',
                  subtitle: 'Nạp tiền để sử dụng các dịch vụ Lock.R',
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                  _TopUpAmountGrid(
                    amounts: _amounts,
                    selectedAmount: _selectedAmount,
                    formatCurrency: _formatCurrency,
                    onSelected: (value) {
                      setState(() {
                        _amountTouched = true;
                        _selectedAmount = value;
                      });
                    },
                    screenH: screenH,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Số tiền nạp: ${_formatCurrency(_selectedAmount)} · '
                    'Mỗi lần nạp từ '
                    '${_formatCurrency(businessConfig.topupMinAmount)} đến '
                    '${_formatCurrency(businessConfig.topupMaxAmount)}',
                    style: const TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                  const SizedBox(height: 32),
                  _PaymentMethodSection(
                    selectedMethod: _selectedMethod,
                    onMethodChanged: (m) => setState(() => _selectedMethod = m),
                    vnpayEnabled: businessConfig.isPaymentMethodEnabled('VNPAY'),
                    sepayEnabled: businessConfig.isPaymentMethodEnabled('SEPAY'),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(height: screenH * 0.08),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: _ActionBottomButton(
          isLoading: provider.isCreatingTopUpUrl,
          onPressed: () async {
            debugPrint(
              '[TOPUP][page] pressed selectedAmount=$_selectedAmount, method=$_selectedMethod',
            );
            if (!_validateTopUp()) return;
            final result = await provider.initiateTopUp(
              _selectedAmount,
              method: _selectedMethod,
            );
            if (!mounted) return;
            if (result == null || result.paymentUrl.isEmpty) {
              final msg =
                  provider.topUpError ?? 'Không thể tạo link thanh toán.';
              debugPrint(
                '[TOPUP][page] no result / empty url. error="$msg"',
              );
              SmartDialog.showToast(msg);
              return;
            }
            final uri = Uri.tryParse(result.paymentUrl);
            if (uri == null || !uri.hasScheme) {
              debugPrint(
                '[TOPUP][page] invalid url="${result.paymentUrl}"',
              );
              SmartDialog.showToast('Link thanh toán không hợp lệ.');
              return;
            }
            debugPrint(
              '[TOPUP][page] navigating to WebView url="${result.paymentUrl}"',
            );

            final ok = await Navigator.of(context).push<bool>(
              MaterialPageRoute(
                builder: (_) =>
                    TopUpWebViewPage(paymentUrl: result.paymentUrl),
              ),
            );

            if (!mounted) return;
            if (ok == true) {
              await walletProvider.getWalletBalance();
              if (mounted) {
                final fmtAmount = NumberFormat.currency(
                  locale: 'vi_VN',
                  symbol: 'đ',
                  decimalDigits: 0,
                ).format(_selectedAmount);

                await showPaymentResultDialog<void>(
                  context,
                  type: PaymentStatusType.success,
                  title: 'Nạp tiền thành công!',
                  amountText: '+$fmtAmount',
                  message: 'Số dư ví của bạn đã được cập nhật thành công.',
                );
                if (mounted) Navigator.of(context).pop(true);
              }
            } else if (ok == false) {
              if (mounted) {
                final fmtAmount = NumberFormat.currency(
                  locale: 'vi_VN',
                  symbol: 'đ',
                  decimalDigits: 0,
                ).format(_selectedAmount);

                await showPaymentResultDialog<void>(
                  context,
                  type: PaymentStatusType.failure,
                  title: 'Thanh toán thất bại',
                  amountText: fmtAmount,
                  message: 'Giao dịch nạp ví đã bị hủy hoặc không thành công. Vui lòng kiểm tra lại.',
                );
              }
            }
          },
        ),
      ),
    );
  },
      ),
    );
  }
}

class _TopUpAmountGrid extends StatelessWidget {
  final List<int> amounts;
  final int selectedAmount;
  final String Function(int) formatCurrency;
  final ValueChanged<int> onSelected;
  final double screenH;

  const _TopUpAmountGrid({
    required this.amounts,
    required this.selectedAmount,
    required this.formatCurrency,
    required this.onSelected,
    required this.screenH,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Chọn số tiền',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: screenH > 700 ? 1.5 : 1.4,
          ),
          itemCount: amounts.length,
          itemBuilder: (context, index) {
            final amount = amounts[index];
            final isSelected = amount == selectedAmount;
            return GestureDetector(
              onTap: () => onSelected(amount),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AISLShadcnTheme.navyPrimary
                      : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? AISLShadcnTheme.navyPrimary
                        : Colors.grey.shade300,
                    width: 1.2,
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  formatCurrency(amount),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ).copyWith(color: isSelected ? Colors.white : Colors.black),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _PaymentMethodSection extends StatelessWidget {
  const _PaymentMethodSection({
    required this.selectedMethod,
    required this.onMethodChanged,
    required this.vnpayEnabled,
    required this.sepayEnabled,
  });

  final String selectedMethod;
  final ValueChanged<String> onMethodChanged;
  final bool vnpayEnabled;
  final bool sepayEnabled;

  @override
  Widget build(BuildContext context) {
    if (!vnpayEnabled && !sepayEnabled) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFFFFBEB),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFFCD34D)),
        ),
        child: const Text(
          'Dịch vụ nạp tiền đang tạm ngưng. Vui lòng thử lại sau.',
          style: TextStyle(fontSize: 15, color: Color(0xFF92400E)),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Phương thức nạp tiền',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 16),
        if (sepayEnabled)
          _PaymentMethodCard(
            isSelected: selectedMethod == 'SEPAY',
            onTap: () => onMethodChanged('SEPAY'),
            iconWidget: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.qr_code_2_rounded,
                color: Color(0xFF0284C7),
                size: 30,
              ),
            ),
            title: 'SePay (VietQR)',
            subtitle: 'Quét mã VietQR chuyển khoản nhanh 24/7',
            badge: 'Khuyên dùng',
          ),
        if (sepayEnabled && vnpayEnabled) const SizedBox(height: 12),
        if (vnpayEnabled)
          _PaymentMethodCard(
            isSelected: selectedMethod == 'VNPAY',
            onTap: () => onMethodChanged('VNPAY'),
            iconWidget: SizedBox(
              width: 58,
              child: Image.asset(
                AppAssets.vnpayLogo,
                height: 28,
                fit: BoxFit.contain,
              ),
            ),
            title: 'VNPAY',
            subtitle: 'Cổng thanh toán điện tử VNPAY',
          ),
      ],
    );
  }
}

class _PaymentMethodCard extends StatelessWidget {
  final bool isSelected;
  final VoidCallback onTap;
  final Widget iconWidget;
  final String title;
  final String subtitle;
  final String? badge;

  const _PaymentMethodCard({
    required this.isSelected,
    required this.onTap,
    required this.iconWidget,
    required this.title,
    required this.subtitle,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? AISLShadcnTheme.navyPrimary
                : const Color(0xFFE2E8F0),
            width: isSelected ? 2.0 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            iconWidget,
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      if (badge != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFDCFCE7),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            badge!,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF15803D),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                ],
              ),
            ),
            Icon(
              isSelected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              color: isSelected
                  ? AISLShadcnTheme.navyPrimary
                  : const Color(0xFFCBD5E1),
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionBottomButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onPressed;

  const _ActionBottomButton({required this.isLoading, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 58,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AISLShadcnTheme.navyPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(26),
          ),
          elevation: 0,
        ),
        child: isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.white,
                ),
              )
            : const Text(
                'Nạp ngay',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }
}

class TopUpWebViewPage extends StatefulWidget {
  final String paymentUrl;

  const TopUpWebViewPage({super.key, required this.paymentUrl});

  @override
  State<TopUpWebViewPage> createState() => _TopUpWebViewPageState();
}

class _TopUpWebViewPageState extends State<TopUpWebViewPage> {
  late final WebViewController _controller;
  bool _isLoading = true;
  bool _popped = false;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) => setState(() => _isLoading = true),
          onPageFinished: (_) => setState(() => _isLoading = false),
          onNavigationRequest: (request) {
            final url = request.url;
            if ((url.contains('/payments/vnpay/callback') ||
                    url.contains('/payments/vnpay/return') ||
                    url.contains('/payments/sepay/callback') ||
                    url.contains('/payments/sepay/return')) &&
                !_popped) {
              _popped = true;
              final uri = Uri.tryParse(url);
              bool isSuccess = true;
              if (url.contains('/vnpay/')) {
                isSuccess = uri?.queryParameters['vnp_ResponseCode'] == '00';
              } else if (url.contains('/sepay/')) {
                final status = uri?.queryParameters['status'];
                isSuccess = status == null || (!status.contains('cancel') && !status.contains('failed'));
              }
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) Navigator.of(context).pop(isSuccess);
              });
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.paymentUrl));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Thanh toán'), centerTitle: true),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading)
            const Center(
              child: AppLoadingIndicator(
                size: 80,
                message: 'Đang kết nối cổng thanh toán...',
              ),
            ),
        ],
      ),
    );
  }
}
