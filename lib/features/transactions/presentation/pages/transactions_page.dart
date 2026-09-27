import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_laundry_locker/core/routing/app_router.dart';
import 'package:smart_laundry_locker/core/network/api_client.dart';
import 'package:smart_laundry_locker/core/theme/shadcn_theme.dart';
import 'package:smart_laundry_locker/features/transactions/domain/entities/transaction.dart';
import 'package:smart_laundry_locker/features/transactions/domain/entities/transaction_extensions.dart';
import 'package:smart_laundry_locker/features/transactions/domain/entities/spending_stats.dart';
import 'package:smart_laundry_locker/features/transactions/presentation/providers/transaction_injection.dart';
import 'package:smart_laundry_locker/features/transactions/presentation/providers/transaction_provider.dart';
import 'package:smart_laundry_locker/features/wallet/presentation/providers/wallet_provider.dart';
import 'package:smart_laundry_locker/core/utils/currency_formatter.dart';
import 'package:smart_laundry_locker/shared/widgets/user_ui_kit.dart';
import 'package:smart_laundry_locker/shared/shared.dart';

class TransactionsPage extends StatefulWidget {
  const TransactionsPage({super.key});

  @override
  State<TransactionsPage> createState() => _TransactionsPageState();
}

class _TransactionsPageState extends State<TransactionsPage> {
  late final TransactionProvider _provider;

  @override
  void initState() {
    super.initState();
    _provider = TransactionInjection.provideTransactionProvider(ApiClient());

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _provider.fetchTransactions(refresh: true).then((_) {
        if (!mounted) return;
        context.read<WalletProvider>().getWalletBalance();
      });
    });
  }

  @override
  void dispose() {
    _provider.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _provider,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        body: Consumer2<TransactionProvider, WalletProvider>(
          builder: (context, provider, walletProvider, child) {
            return Column(
              children: [
                BrandHeroHeader(
                  title: 'Lịch sử giao dịch',
                  subtitle: 'Biến động số dư & chi tiết giao dịch ví',
                  trailing: BrandCircleIconButton(
                    icon: Icons.refresh,
                    onTap: () async {
                      await provider.fetchTransactions(refresh: true);
                      await walletProvider.getWalletBalance();
                    },
                  ),
                ),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () async {
                      await provider.fetchTransactions(refresh: true);
                      if (!context.mounted) return;
                      await context.read<WalletProvider>().getWalletBalance();
                    },
                    child: CustomScrollView(
                      physics: const AlwaysScrollableScrollPhysics(
                        parent: BouncingScrollPhysics(),
                      ),
                      slivers: [
                        SliverToBoxAdapter(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 12),
                              // Card 1: Số dư ví
                              _WalletBalanceCard(
                                balance: walletProvider.balance,
                                onTopUp: () async {
                                  final ok = await context.push<bool>(
                                    AppRouter.topUp,
                                  );
                                  if (!mounted) return;
                                  if (ok == true) {
                                    await _provider.fetchTransactions(refresh: true);
                                    await walletProvider.getWalletBalance();
                                  }
                                },
                                onWithdraw: () async {
                                  final ok = await context.push<bool>(
                                    AppRouter.withdraw,
                                  );
                                  if (!mounted) return;
                                  if (ok == true) {
                                    await _provider.fetchTransactions(refresh: true);
                                    await walletProvider.getWalletBalance();
                                  }
                                },
                              ),
                              const SizedBox(height: 12),

                              // Card 2: Thống kê chi tiêu & phân bổ dịch vụ theo kỳ (Ngày, Tháng, Năm, Tất cả)
                              _SpendingStatsCard(provider: provider),

                              const SizedBox(height: 16),

                              // Card 3: Bộ lọc hình thức giao dịch (Ví, SePay, VNPay, Rút tiền)
                              _PaymentMethodFilterBar(provider: provider),

                              const SizedBox(height: 8),
                            ],
                          ),
                        ),
                        const _TransactionsSliverList(),
                        const SliverPadding(padding: EdgeInsets.only(bottom: 32)),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Card Số dư ví (Giữ phong cách hiện có và tối ưu độ hoàn thiện)
class _WalletBalanceCard extends StatelessWidget {
  final double balance;
  final VoidCallback onTopUp;
  final VoidCallback onWithdraw;

  const _WalletBalanceCard({
    required this.balance,
    required this.onTopUp,
    required this.onWithdraw,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AISLShadcnTheme.navySurface,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.account_balance_wallet_rounded,
              color: AISLShadcnTheme.navyPrimary,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Số dư ví',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  CurrencyFormatter.formatVnd(balance),
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FilledButton(
                onPressed: onTopUp,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 7,
                  ),
                  minimumSize: const Size(82, 34),
                  backgroundColor: AISLShadcnTheme.navyPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'Nạp tiền',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              OutlinedButton(
                onPressed: onWithdraw,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 7,
                  ),
                  minimumSize: const Size(82, 34),
                  foregroundColor: AISLShadcnTheme.navyPrimary,
                  side: const BorderSide(
                    color: AISLShadcnTheme.navyPrimary,
                    width: 1.2,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'Rút tiền',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Card Thống kê chi tiêu & phân bổ theo từng dịch vụ / hình thức theo kỳ (Hôm nay, Tháng này, Năm nay, Tất cả)
class _SpendingStatsCard extends StatefulWidget {
  final TransactionProvider provider;

  const _SpendingStatsCard({required this.provider});

  @override
  State<_SpendingStatsCard> createState() => _SpendingStatsCardState();
}

class _SpendingStatsCardState extends State<_SpendingStatsCard> {
  bool _showMethodBreakdown = false;

  @override
  Widget build(BuildContext context) {
    final provider = widget.provider;
    final stats = provider.spendingStats ?? SpendingStats.empty(provider.selectedPeriod);
    final period = provider.selectedPeriod;

    final expenseFmt = NumberFormat.currency(
      locale: 'vi_VN',
      symbol: 'đ',
      decimalDigits: 0,
    ).format(stats.totalExpense);

    final incomeFmt = NumberFormat.currency(
      locale: 'vi_VN',
      symbol: 'đ',
      decimalDigits: 0,
    ).format(stats.totalIncome);

    final netFmt = NumberFormat.currency(
      locale: 'vi_VN',
      symbol: 'đ',
      decimalDigits: 0,
    ).format(stats.netChange.abs());
    final isNetPositive = stats.netChange >= 0;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Period Selector Bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(
                    Icons.insights_rounded,
                    size: 18,
                    color: AISLShadcnTheme.navyPrimary,
                  ),
                  SizedBox(width: 6),
                  Text(
                    'Thống kê chi tiêu',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
              if (provider.isLoadingStats)
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),
          const SizedBox(height: 12),

          // Period Segment Tabs
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                _buildPeriodTab('Hôm nay', 'DAY', period),
                _buildPeriodTab('Tháng này', 'MONTH', period),
                _buildPeriodTab('Năm nay', 'YEAR', period),
                _buildPeriodTab('Tất cả', 'ALL', period),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Summary Metrics Grid (Tổng chi, Tổng nạp, Biến động ròng)
          Row(
            children: [
              Expanded(
                child: _MetricItem(
                  label: 'Tổng chi tiêu',
                  value: '-$expenseFmt',
                  valueColor: const Color(0xFFDC2626),
                  icon: Icons.arrow_outward_rounded,
                  iconBg: const Color(0xFFFEE2E2),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MetricItem(
                  label: 'Tổng nạp vào',
                  value: '+$incomeFmt',
                  valueColor: const Color(0xFF16A34A),
                  icon: Icons.south_west_rounded,
                  iconBg: const Color(0xFFDCFCE7),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Net summary row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      isNetPositive
                          ? Icons.trending_up_rounded
                          : Icons.trending_down_rounded,
                      size: 16,
                      color: isNetPositive
                          ? const Color(0xFF16A34A)
                          : const Color(0xFFDC2626),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'Biến động ròng:',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                Text(
                  '${isNetPositive ? '+' : '-'}$netFmt (${stats.transactionCount} GD)',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: isNetPositive
                        ? const Color(0xFF16A34A)
                        : const Color(0xFFDC2626),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 14),

          // Breakdown header with toggle tabs: [Theo dịch vụ] [Theo hình thức]
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    _showMethodBreakdown ? Icons.account_balance_wallet_outlined : Icons.pie_chart_rounded,
                    size: 16,
                    color: const Color(0xFF475569),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _showMethodBreakdown ? 'Tổng tiền theo hình thức' : 'Chi tiết theo từng dịch vụ',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF334155),
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    _buildSubTab(
                      title: 'Dịch vụ',
                      isSelected: !_showMethodBreakdown,
                      onTap: () => setState(() => _showMethodBreakdown = false),
                    ),
                    _buildSubTab(
                      title: 'Hình thức',
                      isSelected: _showMethodBreakdown,
                      onTap: () => setState(() => _showMethodBreakdown = true),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Services or Methods Breakdown List
          if (!_showMethodBreakdown)
            _ServiceBreakdownList(
              stats: stats,
              periodTransactions: provider.periodTransactions,
            )
          else
            _MethodBreakdownList(
              provider: provider,
              periodTransactions: provider.periodTransactions,
            ),
        ],
      ),
    );
  }

  Widget _buildSubTab({
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? AISLShadcnTheme.navyPrimary : const Color(0xFF64748B),
          ),
        ),
      ),
    );
  }

  Widget _buildPeriodTab(String title, String value, String current) {
    final isSelected = current == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => widget.provider.setPeriod(value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 7),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ]
                : null,
          ),
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected
                  ? AISLShadcnTheme.navyPrimary
                  : const Color(0xFF64748B),
            ),
          ),
        ),
      ),
    );
  }
}

class _MetricItem extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;
  final IconData icon;
  final Color iconBg;

  const _MetricItem({
    required this.label,
    required this.value,
    required this.valueColor,
    required this.icon,
    required this.iconBg,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  size: 15,
                  color: valueColor,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: valueColor,
              letterSpacing: -0.3,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

/// Danh sách tiến độ và chi tiêu cho từng dịch vụ
class _ServiceBreakdownList extends StatelessWidget {
  final SpendingStats stats;
  final List<Transaction> periodTransactions;

  const _ServiceBreakdownList({
    required this.stats,
    required this.periodTransactions,
  });

  @override
  Widget build(BuildContext context) {
    final rentalAmt = stats.byService['RENTAL'] ?? 0.0;
    final sendAmt = stats.byService['SEND'] ?? 0.0;
    final laundryAmt = stats.byService['LAUNDRY'] ?? 0.0;
    final topupAmt = stats.byService['TOPUP'] ?? 0.0;
    final withdrawAmt = stats.byService['WITHDRAW'] ?? 0.0;
    final otherAmt = stats.byService['OTHER'] ?? 0.0;

    // Đếm số lượt theo dịch vụ trong kỳ
    int rentalCount = 0;
    int sendCount = 0;
    int laundryCount = 0;
    int topupCount = 0;
    int withdrawCount = 0;
    int otherCount = 0;

    for (final tx in periodTransactions) {
      switch (tx.detectedService) {
        case 'RENTAL':
          rentalCount++;
          break;
        case 'SEND':
          sendCount++;
          break;
        case 'LAUNDRY':
          laundryCount++;
          break;
        case 'TOPUP':
          topupCount++;
          break;
        case 'WITHDRAW':
          withdrawCount++;
          break;
        default:
          otherCount++;
          break;
      }
    }

    final totalVolume = rentalAmt + sendAmt + laundryAmt + topupAmt + withdrawAmt + otherAmt;

    final services = <Map<String, dynamic>>[
      {
        'key': 'RENTAL',
        'title': 'Thuê tủ thông minh',
        'amount': rentalAmt,
        'count': rentalCount,
        'color': const Color(0xFF2563EB),
        'icon': Icons.inventory_2_rounded,
      },
      {
        'key': 'SEND',
        'title': 'Gửi đồ / Giao nhận',
        'amount': sendAmt,
        'count': sendCount,
        'color': const Color(0xFF7C3AED),
        'icon': Icons.local_shipping_rounded,
      },
      if (laundryAmt > 0 || laundryCount > 0)
        {
          'key': 'LAUNDRY',
          'title': 'Giặt sấy tủ',
          'amount': laundryAmt,
          'count': laundryCount,
          'color': const Color(0xFF0D9488),
          'icon': Icons.local_laundry_service_rounded,
        },
      {
        'key': 'TOPUP',
        'title': 'Nạp tiền ví',
        'amount': topupAmt,
        'count': topupCount,
        'color': const Color(0xFF16A34A),
        'icon': Icons.add_circle_outline_rounded,
      },
      {
        'key': 'WITHDRAW',
        'title': 'Rút tiền về STK',
        'amount': withdrawAmt,
        'count': withdrawCount,
        'color': const Color(0xFFEA580C),
        'icon': Icons.outbox_rounded,
      },
      if (otherAmt > 0 || otherCount > 0)
        {
          'key': 'OTHER',
          'title': 'Khác / Điều chỉnh',
          'amount': otherAmt,
          'count': otherCount,
          'color': const Color(0xFF64748B),
          'icon': Icons.receipt_long_rounded,
        },
    ];

    return Column(
      children: services.map((s) {
        final double amt = (s['amount'] as num).toDouble();
        final int cnt = s['count'] as int;
        final double ratio = totalVolume > 0 ? (amt / totalVolume).clamp(0.0, 1.0) : 0.0;
        final Color color = s['color'] as Color;
        final IconData icon = s['icon'] as IconData;
        final String title = s['title'] as String;

        final amtStr = NumberFormat.currency(
          locale: 'vi_VN',
          symbol: 'đ',
          decimalDigits: 0,
        ).format(amt);

        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, size: 16, color: color),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        Text(
                          '$cnt giao dịch',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF94A3B8),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    amtStr,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: ratio,
                  minHeight: 5,
                  backgroundColor: const Color(0xFFF1F5F9),
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

/// Danh sách tổng tiền và giao dịch cho từng hình thức thanh toán (Ví, SePay, VNPay, MoMo, Rút tiền...)
class _MethodBreakdownList extends StatelessWidget {
  final TransactionProvider provider;
  final List<Transaction> periodTransactions;

  const _MethodBreakdownList({
    required this.provider,
    required this.periodTransactions,
  });

  @override
  Widget build(BuildContext context) {
    final walletAmt = provider.getMethodAmount('WALLET');
    final sepayAmt = provider.getMethodAmount('SEPAY');
    final vnpayAmt = provider.getMethodAmount('VNPAY');
    final momoAmt = provider.getMethodAmount('MOMO');
    final withdrawAmt = provider.getMethodAmount('WITHDRAW');

    final walletCnt = provider.getMethodCount('WALLET');
    final sepayCnt = provider.getMethodCount('SEPAY');
    final vnpayCnt = provider.getMethodCount('VNPAY');
    final momoCnt = provider.getMethodCount('MOMO');
    final withdrawCnt = provider.getMethodCount('WITHDRAW');

    final totalVolume = walletAmt + sepayAmt + vnpayAmt + momoAmt + withdrawAmt;

    final methods = <Map<String, dynamic>>[
      {
        'key': 'WALLET',
        'title': 'Ví Lock.R',
        'amount': walletAmt,
        'count': walletCnt,
        'color': const Color(0xFF1E293B),
        'icon': Icons.account_balance_wallet_rounded,
      },
      {
        'key': 'SEPAY',
        'title': 'Cổng SePay QR',
        'amount': sepayAmt,
        'count': sepayCnt,
        'color': const Color(0xFF0284C7),
        'icon': Icons.qr_code_2_rounded,
      },
      {
        'key': 'VNPAY',
        'title': 'Cổng VNPay',
        'amount': vnpayAmt,
        'count': vnpayCnt,
        'color': const Color(0xFFE11D48),
        'icon': Icons.credit_card_rounded,
      },
      if (momoAmt > 0 || momoCnt > 0)
        {
          'key': 'MOMO',
          'title': 'Ví MoMo',
          'amount': momoAmt,
          'count': momoCnt,
          'color': const Color(0xFFC026D3),
          'icon': Icons.account_balance_wallet_outlined,
        },
      {
        'key': 'WITHDRAW',
        'title': 'Rút tiền về STK',
        'amount': withdrawAmt,
        'count': withdrawCnt,
        'color': const Color(0xFFEA580C),
        'icon': Icons.outbox_rounded,
      },
    ];

    return Column(
      children: methods.map((m) {
        final double amt = (m['amount'] as num).toDouble();
        final int cnt = m['count'] as int;
        final double ratio = totalVolume > 0 ? (amt / totalVolume).clamp(0.0, 1.0) : 0.0;
        final Color color = m['color'] as Color;
        final IconData icon = m['icon'] as IconData;
        final String title = m['title'] as String;

        final amtStr = NumberFormat.currency(
          locale: 'vi_VN',
          symbol: 'đ',
          decimalDigits: 0,
        ).format(amt);

        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, size: 16, color: color),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        Text(
                          '$cnt giao dịch',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF94A3B8),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    amtStr,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: ratio,
                  minHeight: 5,
                  backgroundColor: const Color(0xFFF1F5F9),
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

/// Thanh bộ lọc hình thức giao dịch (Ví Lock.R, SePay QR, VNPay, Rút tiền...)
class _PaymentMethodFilterBar extends StatelessWidget {
  final TransactionProvider provider;

  const _PaymentMethodFilterBar({required this.provider});

  @override
  Widget build(BuildContext context) {
    final filters = [
      {'key': 'ALL', 'label': 'Tất cả hình thức', 'icon': Icons.tune_rounded},
      {'key': 'WALLET', 'label': 'Ví Lock.R', 'icon': Icons.account_balance_wallet_rounded},
      {'key': 'SEPAY', 'label': 'Cổng SePay', 'icon': Icons.qr_code_2_rounded},
      {'key': 'VNPAY', 'label': 'Cổng VNPay', 'icon': Icons.credit_card_rounded},
      {'key': 'WITHDRAW', 'label': 'Rút tiền', 'icon': Icons.outbox_rounded},
    ];

    final currentFilter = filters.firstWhere(
      (f) => f['key'] == provider.selectedMethod,
      orElse: () => filters.first,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Icon(
                Icons.filter_list_rounded,
                size: 16,
                color: Color(0xFF475569),
              ),
              SizedBox(width: 6),
              Text(
                'Lọc theo hình thức giao dịch',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF334155),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 38,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: filters.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final f = filters[index];
              final key = f['key'] as String;
              final label = f['label'] as String;
              final icon = f['icon'] as IconData;
              final isSelected = provider.selectedMethod == key;
              final count = provider.getMethodCount(key);

              return InkWell(
                onTap: () => provider.setMethodFilter(key),
                borderRadius: BorderRadius.circular(10),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AISLShadcnTheme.navyPrimary
                        : Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSelected
                          ? AISLShadcnTheme.navyPrimary
                          : const Color(0xFFE2E8F0),
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: AISLShadcnTheme.navyPrimary.withValues(alpha: 0.2),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        icon,
                        size: 14,
                        color: isSelected ? Colors.white : const Color(0xFF64748B),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          color: isSelected ? Colors.white : const Color(0xFF334155),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Colors.white.withValues(alpha: 0.2)
                              : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '$count',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: isSelected ? Colors.white : const Color(0xFF64748B),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),

        // Thẻ hiển thị tổng tiền cho hình thức giao dịch đang chọn
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: AISLShadcnTheme.navySurface,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Icon(
                        currentFilter['icon'] as IconData,
                        size: 14,
                        color: AISLShadcnTheme.navyPrimary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      provider.selectedMethod == 'ALL'
                          ? 'Tổng tiền (tất cả):'
                          : 'Tổng tiền ${currentFilter['label']}:',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                Text(
                  '${NumberFormat.currency(locale: 'vi_VN', symbol: 'đ', decimalDigits: 0).format(provider.getMethodAmount(provider.selectedMethod))} (${provider.getMethodCount(provider.selectedMethod)} GD)',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _TransactionsSliverList extends StatelessWidget {
  const _TransactionsSliverList();

  @override
  Widget build(BuildContext context) {
    return Consumer<TransactionProvider>(
      builder: (context, provider, child) {
        final transactions = provider.filteredTransactions;

        if (provider.isLoading && provider.transactions.isEmpty) {
          return const SliverFillRemaining(
            hasScrollBody: false,
            child: AppLoadingIndicator(
              fullScreen: true,
              message: 'Đang tải lịch sử giao dịch...',
            ),
          );
        }

        if (provider.error != null && provider.transactions.isEmpty) {
          return SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Lỗi: ${provider.error}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            ),
          );
        }

        if (transactions.isEmpty) {
          return SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.receipt_long_outlined,
                      size: 28,
                      color: Color(0xFF94A3B8),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Không có giao dịch nào',
                    style: TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Không tìm thấy giao dịch theo bộ lọc đã chọn',
                    style: TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        // Group by date
        final grouped = <String, List<Transaction>>{};
        for (final tx in transactions) {
          final key = DateFormat('dd/MM/yyyy').format(tx.createdAt.toLocal());
          (grouped[key] ??= []).add(tx);
        }

        // Flatten: [dateString, Transaction, Transaction, dateString, ...]
        final items = <dynamic>[];
        for (final entry in grouped.entries) {
          items.add(entry.key);
          items.addAll(entry.value);
        }

        return SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final item = items[index];
              if (item is String) return _DateHeader(date: item);
              return _MBStyleTransactionItem(transaction: item as Transaction);
            },
            childCount: items.length,
          ),
        );
      },
    );
  }
}

class _DateHeader extends StatelessWidget {
  final String date;
  const _DateHeader({required this.date});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
      child: Text(
        date,
        style: const TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 13,
          color: Color(0xFF475569),
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}

class _MBStyleTransactionItem extends StatelessWidget {
  final Transaction transaction;
  const _MBStyleTransactionItem({required this.transaction});

  @override
  Widget build(BuildContext context) {
    final isIncome =
        transaction.type == 'TOP_UP' || transaction.type == 'CREDIT';
    final dotColor =
        isIncome ? const Color(0xFF16A34A) : const Color(0xFFEA580C);
    final amountSign = isIncome ? '+' : '-';
    final time =
        DateFormat('HH:mm').format(transaction.createdAt.toLocal());

    final amountFmt = NumberFormat.currency(
      locale: 'vi_VN',
      symbol: 'đ',
      decimalDigits: 0,
    ).format(transaction.amount);
    final balanceFmt = NumberFormat.currency(
      locale: 'vi_VN',
      symbol: 'đ',
      decimalDigits: 0,
    ).format(transaction.balanceAfter);

    // Method and service info
    final methodLabel = transaction.detectedMethodLabel;
    final methodIcon = transaction.detectedMethodIcon;
    final methodColor = transaction.detectedMethodColor;

    final serviceLabel = transaction.detectedServiceLabel;
    final serviceColor = transaction.detectedServiceColor;

    final isWallet = transaction.detectedMethod == 'WALLET';
    final title = isIncome
        ? 'Thông báo nạp tiền ví'
        : (isWallet ? 'Thông báo biến động số dư' : 'Thanh toán đơn qua $methodLabel');
    final infoPart = isWallet ? 'SD: $balanceFmt' : 'PT: $methodLabel';
    final content =
        'GD: $amountSign$amountFmt | $infoPart\nND: ${transaction.description}';

    final descLower = transaction.description.toLowerCase();
    final isFailed = descLower.contains('thất bại') ||
        descLower.contains('failed') ||
        descLower.contains('hủy') ||
        descLower.contains('cancel');

    return InkWell(
      onTap: () {
        showPaymentResultDialog<void>(
          context,
          type: isFailed ? PaymentStatusType.failure : PaymentStatusType.success,
          title: isFailed ? 'Giao dịch không thành công' : 'Giao dịch thành công',
          amountText: '$amountSign$amountFmt',
          message: transaction.description,
          detailsWidget: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              children: [
                _dialogRow('Hình thức GD', methodLabel),
                const SizedBox(height: 6),
                _dialogRow('Dịch vụ', serviceLabel),
                const SizedBox(height: 6),
                _dialogRow(
                  'Thời gian',
                  DateFormat('dd/MM/yyyy HH:mm').format(transaction.createdAt.toLocal()),
                ),
                if (transaction.referenceId != null && transaction.referenceId!.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  _dialogRow('Mã GD', transaction.referenceId!),
                ],
                if (transaction.orderCode != null && transaction.orderCode!.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  _dialogRow('Mã đơn', transaction.orderCode!),
                ],
                if (isWallet) ...[
                  const SizedBox(height: 6),
                  _dialogRow('Số dư sau GD', balanceFmt),
                ],
              ],
            ),
          ),
          primaryButtonText: 'Đóng',
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFF1F5F9)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row with title & badges
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ),
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: dotColor,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),

            // Badges row: Method badge + Service badge
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                // Method Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: methodColor.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: methodColor.withValues(alpha: 0.25),
                      width: 0.8,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(methodIcon, size: 12, color: methodColor),
                      const SizedBox(width: 4),
                      Text(
                        methodLabel,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: methodColor,
                        ),
                      ),
                    ],
                  ),
                ),

                // Service Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: serviceColor.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    serviceLabel,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: serviceColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Description / SMS text
            Text(
              content,
              style: const TextStyle(
                fontSize: 12.5,
                color: Color(0xFF64748B),
                height: 1.45,
              ),
            ),
            const SizedBox(height: 6),

            // Time & Amount highlight
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  time,
                  style: TextStyle(
                    fontSize: 11.5,
                    color: dotColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '$amountSign$amountFmt',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: dotColor,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _dialogRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            color: Color(0xFF64748B),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: Color(0xFF0F172A),
          ),
        ),
      ],
    );
  }
}
