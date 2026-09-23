import 'package:flutter/material.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:smart_laundry_locker/core/routing/app_router.dart';
import 'package:smart_laundry_locker/core/theme/shadcn_theme.dart';
import 'package:smart_laundry_locker/core/utils/currency_formatter.dart';
import 'package:smart_laundry_locker/features/wallet/data/vietnamese_banks.dart';
import 'package:smart_laundry_locker/features/wallet/presentation/providers/wallet_provider.dart';
import 'package:smart_laundry_locker/shared/widgets/user_ui_kit.dart';

class WithdrawPage extends StatefulWidget {
  const WithdrawPage({super.key});

  @override
  State<WithdrawPage> createState() => _WithdrawPageState();
}

class _WithdrawPageState extends State<WithdrawPage> {
  final _formKey = GlobalKey<FormState>();
  final _accountNumberController = TextEditingController();
  final _accountHolderController = TextEditingController();
  final _amountController = TextEditingController();

  VietnameseBank? _selectedBank;
  double _enteredAmount = 0;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    // Default to MBBank
    _selectedBank = vietnameseBanks.firstWhere(
      (b) => b.code == 'MB',
      orElse: () => vietnameseBanks.first,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<WalletProvider>().getWalletBalance();
    });
  }

  @override
  void dispose() {
    _accountNumberController.dispose();
    _accountHolderController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  void _onAmountChanged(String val) {
    final clean = val.replaceAll(RegExp(r'[^0-9]'), '');
    final numVal = double.tryParse(clean) ?? 0;
    setState(() {
      _enteredAmount = numVal;
    });
  }

  void _setAmount(double amt) {
    setState(() {
      _enteredAmount = amt;
      _amountController.text = NumberFormat.currency(
        locale: 'vi_VN',
        symbol: '',
        decimalDigits: 0,
      ).format(amt).trim();
    });
  }

  void _openBankPicker() {
    showModalBottomSheet<VietnameseBank>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => _BankPickerSheet(
        selected: _selectedBank,
        onSelect: (bank) {
          setState(() => _selectedBank = bank);
          Navigator.pop(ctx);
        },
      ),
    );
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedBank == null) {
      SmartDialog.showToast('Vui lòng chọn ngân hàng thụ hưởng');
      return;
    }

    final wallet = context.read<WalletProvider>();
    final withdrawable = wallet.withdrawableBalance;

    if (_enteredAmount < 10000) {
      SmartDialog.showToast('Số tiền rút tối thiểu là 10.000 đ');
      return;
    }

    if (_enteredAmount > withdrawable) {
      SmartDialog.showToast(
        'Số tiền rút vượt quá số dư hợp lệ từ SePay (${CurrencyFormatter.formatVnd(withdrawable)})',
      );
      return;
    }

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(LucideIcons.shieldCheck, color: AISLShadcnTheme.navyPrimary),
            SizedBox(width: 10),
            Text(
              'Xác nhận rút tiền',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildConfirmRow('Ngân hàng', '${_selectedBank!.shortName} (${_selectedBank!.code})'),
            _buildConfirmRow('Số tài khoản', _accountNumberController.text.trim()),
            _buildConfirmRow('Chủ tài khoản', _accountHolderController.text.trim().toUpperCase()),
            const Divider(height: 20),
            _buildConfirmRow('Số tiền rút', CurrencyFormatter.formatVnd(_enteredAmount), isHighlight: true),
            _buildConfirmRow('Phí dịch vụ', 'Miễn phí (0 đ)'),
            _buildConfirmRow('Thực nhận', CurrencyFormatter.formatVnd(_enteredAmount)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.amber.shade200),
              ),
              child: Row(
                children: [
                  Icon(LucideIcons.clock, size: 16, color: Colors.amber.shade800),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Yêu cầu sẽ ở trạng thái Chờ xử lý và được quản trị viên duyệt chuyển khoản.',
                      style: TextStyle(fontSize: 12, color: Colors.amber.shade900),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AISLShadcnTheme.navyPrimary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Xác nhận rút'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isSubmitting = true);
    SmartDialog.showLoading(msg: 'Đang gửi yêu cầu rút tiền...');

    try {
      final res = await wallet.withdraw(
        bankName: '${_selectedBank!.shortName} - ${_selectedBank!.name}',
        bankCode: _selectedBank!.code,
        accountNumber: _accountNumberController.text.trim(),
        accountHolderName: _accountHolderController.text.trim().toUpperCase(),
        amount: _enteredAmount,
      );
      SmartDialog.dismiss();

      if (!mounted) return;

      final refId = res['referenceId'] ?? '';
      _showSuccessDialog(refId);
    } catch (e) {
      SmartDialog.dismiss();
      if (!mounted) return;
      SmartDialog.showToast('Lỗi rút tiền: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showSuccessDialog(String refId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                LucideIcons.check,
                color: Color(0xFF2E7D32),
                size: 36,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Gửi yêu cầu thành công!',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Yêu cầu rút ${CurrencyFormatter.formatVnd(_enteredAmount)} đã được tiếp nhận.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade700, fontSize: 14),
            ),
            if (refId.isNotEmpty) ...[
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Mã GD: $refId',
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                ),
              ),
            ],
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(LucideIcons.info, size: 18, color: Colors.blue.shade800),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Trạng thái: Đang chờ duyệt. Tiền sẽ được chuyển về tài khoản ${_selectedBank!.shortName} của bạn sau khi quản trị viên phê duyệt.',
                      style: TextStyle(fontSize: 12, color: Colors.blue.shade900),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.pop(true);
            },
            child: const Text('Đóng'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.pushReplacement(AppRouter.transactions);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AISLShadcnTheme.navyPrimary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Xem lịch sử ví'),
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmRow(String label, String value, {bool isHighlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isHighlight ? FontWeight.bold : FontWeight.w600,
              color: isHighlight ? AISLShadcnTheme.navyPrimary : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: Consumer<WalletProvider>(
        builder: (context, wallet, child) {
          final totalBalance = wallet.balance;
          final withdrawable = wallet.withdrawableBalance;

          return Column(
            children: [
              BrandHeroHeader(
                title: 'Rút tiền về tài khoản',
                subtitle: 'Rút tiền từ ví Lock.R về tài khoản ngân hàng',
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Dual Balance Card
                        _buildBalanceCard(totalBalance, withdrawable),
                        const SizedBox(height: 20),

                        // Form Section
                        Card(
                          elevation: 0,
                          color: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                            side: BorderSide(color: Colors.grey.shade200),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Thông tin tài khoản nhận tiền',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 16),

                                // Bank Selector
                                const Text(
                                  'Ngân hàng thụ hưởng *',
                                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                                ),
                                const SizedBox(height: 6),
                                InkWell(
                                  onTap: _openBankPicker,
                                  borderRadius: BorderRadius.circular(12),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                    decoration: BoxDecoration(
                                      border: Border.all(color: Colors.grey.shade300),
                                      borderRadius: BorderRadius.circular(12),
                                      color: Colors.grey.shade50,
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 38,
                                          height: 38,
                                          decoration: BoxDecoration(
                                            color: AISLShadcnTheme.navySurface,
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: const Icon(
                                            LucideIcons.landmark,
                                            color: AISLShadcnTheme.navyPrimary,
                                            size: 20,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                _selectedBank?.shortName ?? 'Chọn ngân hàng',
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 14,
                                                ),
                                              ),
                                              Text(
                                                _selectedBank?.name ?? '',
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  color: Colors.grey.shade600,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ],
                                          ),
                                        ),
                                        Icon(LucideIcons.chevronRight, size: 18, color: Colors.grey.shade500),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),

                                // Account Number
                                const Text(
                                  'Số tài khoản ngân hàng *',
                                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                                ),
                                const SizedBox(height: 6),
                                TextFormField(
                                  controller: _accountNumberController,
                                  keyboardType: TextInputType.number,
                                  decoration: InputDecoration(
                                    hintText: 'Nhập số tài khoản',
                                    prefixIcon: const Icon(LucideIcons.creditCard, size: 18),
                                    filled: true,
                                    fillColor: Colors.grey.shade50,
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(color: Colors.grey.shade300),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(color: Colors.grey.shade300),
                                    ),
                                  ),
                                  validator: (v) {
                                    if (v == null || v.trim().isEmpty) {
                                      return 'Vui lòng nhập số tài khoản';
                                    }
                                    if (v.trim().length < 6) {
                                      return 'Số tài khoản không hợp lệ';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),

                                // Account Holder Name
                                const Text(
                                  'Tên chủ tài khoản *',
                                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                                ),
                                const SizedBox(height: 6),
                                TextFormField(
                                  controller: _accountHolderController,
                                  textCapitalization: TextCapitalization.characters,
                                  decoration: InputDecoration(
                                    hintText: 'VD: NGUYEN VAN A',
                                    helperText: 'Vui lòng nhập in hoa không dấu như trên thẻ ATM',
                                    helperStyle: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                                    prefixIcon: const Icon(LucideIcons.user, size: 18),
                                    filled: true,
                                    fillColor: Colors.grey.shade50,
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(color: Colors.grey.shade300),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(color: Colors.grey.shade300),
                                    ),
                                  ),
                                  validator: (v) {
                                    if (v == null || v.trim().isEmpty) {
                                      return 'Vui lòng nhập tên chủ tài khoản';
                                    }
                                    return null;
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Amount Section
                        Card(
                          elevation: 0,
                          color: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                            side: BorderSide(color: Colors.grey.shade200),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Số tiền cần rút',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                TextFormField(
                                  controller: _amountController,
                                  keyboardType: TextInputType.number,
                                  onChanged: _onAmountChanged,
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: AISLShadcnTheme.navyPrimary,
                                  ),
                                  decoration: InputDecoration(
                                    hintText: '0',
                                    suffixText: 'đ',
                                    suffixStyle: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: AISLShadcnTheme.navyPrimary,
                                    ),
                                    filled: true,
                                    fillColor: Colors.grey.shade50,
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(color: Colors.grey.shade300),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(color: Colors.grey.shade300),
                                    ),
                                  ),
                                  validator: (v) {
                                    if (_enteredAmount < 10000) {
                                      return 'Số tiền rút tối thiểu là 10.000 đ';
                                    }
                                    if (_enteredAmount > withdrawable) {
                                      return 'Số tiền vượt quá số dư hợp lệ từ SePay';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 12),

                                // Quick Amount Chips
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    _buildQuickChip(50000, '50.000 đ', withdrawable),
                                    _buildQuickChip(100000, '100.000 đ', withdrawable),
                                    _buildQuickChip(200000, '200.000 đ', withdrawable),
                                    if (withdrawable > 0)
                                      ActionChip(
                                        label: const Text(
                                          'Tối đa từ SePay',
                                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                        ),
                                        backgroundColor: AISLShadcnTheme.navySurface,
                                        labelStyle: const TextStyle(color: AISLShadcnTheme.navyPrimary),
                                        onPressed: () => _setAmount(withdrawable),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Policy Notice Box
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0FDF4),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFFBBF7D0)),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(LucideIcons.shieldAlert, size: 20, color: Color(0xFF16A34A)),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Chính sách rút tiền an toàn',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF15803D),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Chỉ cho phép rút tiền có nguồn gốc từ tiền thật đã nạp hoặc hoàn tiền qua cổng SePay. Yêu cầu rút sẽ được quản trị viên duyệt và chuyển khoản trong vòng 24 giờ làm việc.',
                                      style: TextStyle(fontSize: 12, color: Colors.green.shade900, height: 1.3),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Submit Button
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            onPressed: _isSubmitting || withdrawable < 10000 ? null : _handleSubmit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AISLShadcnTheme.navyPrimary,
                              disabledBackgroundColor: Colors.grey.shade300,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 0,
                            ),
                            child: _isSubmitting
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                                  )
                                : const Text(
                                    'Xác nhận rút tiền',
                                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 30),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBalanceCard(double totalBalance, double withdrawable) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(LucideIcons.wallet, color: Colors.white, size: 18),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Số dư ví khả dụng',
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Miễn phí rút',
                  style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            CurrencyFormatter.formatVnd(totalBalance),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 14),
          const Divider(color: Colors.white24, height: 1),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(LucideIcons.badgeCheck, size: 16, color: Colors.greenAccent.shade200),
                  const SizedBox(width: 6),
                  const Text(
                    'Được rút từ SePay:',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
              Text(
                CurrencyFormatter.formatVnd(withdrawable),
                style: TextStyle(
                  color: Colors.greenAccent.shade200,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickChip(double amount, String label, double maxWithdrawable) {
    final enabled = amount <= maxWithdrawable;
    final isSelected = _enteredAmount == amount;

    return ActionChip(
      label: Text(label),
      backgroundColor: isSelected
          ? AISLShadcnTheme.navyPrimary
          : enabled
              ? Colors.grey.shade100
              : Colors.grey.shade200,
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        color: isSelected
            ? Colors.white
            : enabled
                ? Colors.black87
                : Colors.grey.shade500,
      ),
      onPressed: enabled ? () => _setAmount(amount) : null,
    );
  }
}

class _BankPickerSheet extends StatefulWidget {
  final VietnameseBank? selected;
  final ValueChanged<VietnameseBank> onSelect;

  const _BankPickerSheet({
    required this.selected,
    required this.onSelect,
  });

  @override
  State<_BankPickerSheet> createState() => _BankPickerSheetState();
}

class _BankPickerSheetState extends State<_BankPickerSheet> {
  final _searchController = TextEditingController();
  List<VietnameseBank> _filtered = vietnameseBanks;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearch);
  }

  void _onSearch() {
    final query = _searchController.text.trim().toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filtered = vietnameseBanks;
      } else {
        _filtered = vietnameseBanks.where((b) {
          return b.shortName.toLowerCase().contains(query) ||
              b.code.toLowerCase().contains(query) ||
              b.name.toLowerCase().contains(query);
        }).toList();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.75,
      ),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Chọn ngân hàng nhận tiền',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Tìm kiếm theo tên hoặc mã ngân hàng',
              prefixIcon: const Icon(LucideIcons.search, size: 18),
              filled: true,
              fillColor: Colors.grey.shade100,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ListView.separated(
              itemCount: _filtered.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final bank = _filtered[index];
                final isSelected = widget.selected?.code == bank.code;

                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: isSelected ? AISLShadcnTheme.navySurface : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      bank.code,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: isSelected ? AISLShadcnTheme.navyPrimary : Colors.black87,
                      ),
                    ),
                  ),
                  title: Text(
                    bank.shortName,
                    style: TextStyle(
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                      color: isSelected ? AISLShadcnTheme.navyPrimary : Colors.black87,
                    ),
                  ),
                  subtitle: Text(
                    bank.name,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: isSelected
                      ? const Icon(LucideIcons.check, color: AISLShadcnTheme.navyPrimary, size: 20)
                      : null,
                  onTap: () => widget.onSelect(bank),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
