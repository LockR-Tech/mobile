import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_laundry_locker/core/routing/app_router.dart';
import 'package:smart_laundry_locker/core/network/api_client.dart';
import 'package:smart_laundry_locker/core/theme/shadcn_theme.dart';
import 'package:smart_laundry_locker/features/transactions/domain/entities/transaction.dart';
import 'package:smart_laundry_locker/features/transactions/presentation/providers/transaction_injection.dart';
import 'package:smart_laundry_locker/features/transactions/presentation/providers/transaction_provider.dart';
import 'package:smart_laundry_locker/features/wallet/presentation/providers/wallet_provider.dart';
import 'package:smart_laundry_locker/core/utils/currency_formatter.dart';

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
    final screenH = MediaQuery.sizeOf(context).height;

    // Header navy cố định ~80, nhưng vẫn tương đối theo chiều cao màn
    final expandedHeaderHeight = (screenH * 0.10).clamp(72.0, 80.0);

    return ChangeNotifierProvider.value(
      value: _provider,
      child: Scaffold(
        backgroundColor: Colors.grey.shade50,
        body: Consumer2<TransactionProvider, WalletProvider>(
          builder: (context, provider, walletProvider, child) {
            return RefreshIndicator(
              onRefresh: () async {
                await provider.fetchTransactions(refresh: true);
                if (!context.mounted) return;
                await context.read<WalletProvider>().getWalletBalance();
              },
              child: CustomScrollView(
                slivers: [
                  SliverAppBar(
                    pinned: true,
                    expandedHeight: expandedHeaderHeight,
                    backgroundColor: AISLShadcnTheme.navyPrimary,
                    elevation: 0,
                    centerTitle: true,
                    title: const Text(
                      'LỊCH SỬ GIAO DỊCH',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                        letterSpacing: 0.5,
                      ),
                    ),
                    actions: [
                      IconButton(
                        icon: const Icon(Icons.refresh, color: Colors.white),
                        onPressed: () async {
                          await provider.fetchTransactions(refresh: true);
                          await walletProvider.getWalletBalance();
                        },
                      ),
                      const SizedBox(width: 8),
                    ],
                    flexibleSpace: FlexibleSpaceBar(
                      background: Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AISLShadcnTheme.navyPrimary,
                              AISLShadcnTheme.navyAccent,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Column(
                      children: [
                        SizedBox(height: screenH * 0.015),
                        Card(
                          margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                          elevation: 0,
                          shadowColor: Colors.black12,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              color: Colors.white,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.05),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: AISLShadcnTheme.navySurface,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Icons.account_balance_wallet_rounded,
                                    color: AISLShadcnTheme.navyPrimary,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Số dư ví',
                                        style: TextStyle(
                                          fontSize: 15,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        CurrencyFormatter.formatVnd(
                                          walletProvider.balance,
                                        ),
                                        style: const TextStyle(
                                          fontSize: 26,
                                          fontWeight: FontWeight.w800,
                                          color: Colors.black87,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                TextButton(
                                  onPressed: () async {
                                    final ok = await context.push<bool>(
                                      AppRouter.topUp,
                                    );
                                    if (!mounted) return;
                                    if (ok == true) {
                                      await _provider.fetchTransactions(
                                        refresh: true,
                                      );
                                      await walletProvider.getWalletBalance();
                                    }
                                  },
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 8,
                                    ),
                                    backgroundColor:
                                        AISLShadcnTheme.navyPrimary,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: const Text(
                                    'Nạp tiền',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(height: screenH * 0.015),
                      ],
                    ),
                  ),
                  const _TransactionsSliverList(),
                  const SliverPadding(padding: EdgeInsets.only(bottom: 24)),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _TransactionsSliverList extends StatelessWidget {
  const _TransactionsSliverList();

  @override
  Widget build(BuildContext context) {
    return Consumer<TransactionProvider>(
      builder: (context, provider, child) {
        final transactions = provider.transactions;

        if (provider.isLoading && transactions.isEmpty) {
          return const SliverFillRemaining(
            hasScrollBody: false,
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (provider.error != null && transactions.isEmpty) {
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
          return const SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: Text(
                'Chưa có giao dịch nào',
                style: TextStyle(color: Colors.grey, fontSize: 16),
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
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Text(
        date,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 14,
          color: Colors.black87,
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
        transaction.type == 'TOP_UP' || transaction.type == 'DEPOSIT';
    final dotColor =
        isIncome ? const Color(0xFF4CAF50) : const Color(0xFFE65100);
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

    final walletShort = transaction.walletId.length > 6
        ? '${transaction.walletId.substring(0, 6)}xxx'
        : transaction.walletId;

    final title = isIncome ? 'Thông báo nạp tiền ví' : 'Thông báo biến động số dư';
    final content =
        'VI $walletShort|GD: $amountSign$amountFmt|SD: $balanceFmt|ND: ${transaction.description}';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade100),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  content,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  time,
                  style: TextStyle(
                    fontSize: 12,
                    color: dotColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 10,
            height: 10,
            margin: const EdgeInsets.only(top: 4),
            decoration: BoxDecoration(
              color: dotColor,
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }
}
