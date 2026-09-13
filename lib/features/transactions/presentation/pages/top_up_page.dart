import 'package:flutter/material.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:intl/intl.dart';
import 'package:smart_laundry_locker/core/constants/app_assets.dart';
import 'package:smart_laundry_locker/core/network/api_client.dart';
import 'package:smart_laundry_locker/core/theme/shadcn_theme.dart';
import 'package:smart_laundry_locker/features/transactions/presentation/providers/transaction_injection.dart';
import 'package:smart_laundry_locker/features/transactions/presentation/providers/transaction_provider.dart';
import 'package:smart_laundry_locker/features/wallet/presentation/providers/wallet_provider.dart';
import 'package:provider/provider.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:flutter/foundation.dart';

class TopUpPage extends StatefulWidget {
  const TopUpPage({super.key});

  @override
  State<TopUpPage> createState() => _TopUpPageState();
}

class _TopUpPageState extends State<TopUpPage> {
  final List<int> _amounts = [20000, 50000, 100000, 200000, 500000, 1000000];
  int _selectedAmount = 100000;
  late final TransactionProvider _provider;

  String _formatCurrency(int amount) {
    return NumberFormat.currency(
      locale: 'vi_VN',
      symbol: 'đ',
    ).format(amount).replaceAll(' ', ' ');
  }

  @override
  void initState() {
    super.initState();
    _provider = TransactionInjection.provideTransactionProvider(ApiClient());
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
            appBar: AppBar(
              elevation: 0,
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
              centerTitle: true,
              title: const Text(
                'NẠP TIỀN',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                  color: Colors.black87,
                ),
              ),
            ),
            body: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _TopUpAmountGrid(
                    amounts: _amounts,
                    selectedAmount: _selectedAmount,
                    formatCurrency: _formatCurrency,
                    onSelected: (value) {
                      setState(() => _selectedAmount = value);
                    },
                    screenH: screenH,
                  ),
                  const SizedBox(height: 32),
                  const _PaymentMethodSection(),
                  const SizedBox(height: 32),
                  SizedBox(height: screenH * 0.08),
                ],
              ),
            ),
            bottomNavigationBar: SafeArea(
              minimum: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: _ActionBottomButton(
                isLoading: provider.isCreatingTopUpUrl,
                onPressed: () async {
                  debugPrint(
                    '[TOPUP][page] pressed selectedAmount=$_selectedAmount',
                  );
                  final result = await provider.initiateTopUp(_selectedAmount);
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
                    if (mounted) Navigator.of(context).pop(true);
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
  const _PaymentMethodSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Thanh toán qua',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF90CAF9), width: 1.2),
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
              SizedBox(
                width: 96,
                child: Image.asset(
                  AppAssets.vnpayLogo,
                  height: 34,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: const [
                        Text(
                          'VNPAY',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        SizedBox(width: 6),
                        Icon(Icons.verified, size: 20, color: Colors.green),
                      ],
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Cổng thanh toán điện tử',
                      style: TextStyle(fontSize: 15, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
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
                    url.contains('/payments/vnpay/return')) &&
                !_popped) {
              _popped = true;
              final uri = Uri.tryParse(url);
              final isSuccess =
                  uri?.queryParameters['vnp_ResponseCode'] == '00';
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
          if (_isLoading) const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }
}
