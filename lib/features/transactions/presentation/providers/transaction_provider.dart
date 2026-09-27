import 'package:flutter/material.dart';
import 'package:smart_laundry_locker/features/transactions/application/use_cases/initiate_top_up_use_case.dart';
import 'package:smart_laundry_locker/features/transactions/application/use_cases/get_transactions_use_case.dart';
import 'package:smart_laundry_locker/features/transactions/application/use_cases/get_spending_stats_use_case.dart';
import 'package:smart_laundry_locker/features/transactions/domain/entities/transaction.dart';
import 'package:smart_laundry_locker/features/transactions/domain/entities/top_up_result.dart';
import 'package:smart_laundry_locker/features/transactions/domain/entities/spending_stats.dart';
import 'package:smart_laundry_locker/features/transactions/domain/entities/transaction_extensions.dart';
import 'package:smart_laundry_locker/features/locker_ops/data/locker_ops_service.dart';
import 'package:flutter/foundation.dart';

class TransactionProvider extends ChangeNotifier {
  final GetTransactionsUseCase getTransactionsUseCase;
  final InitiateTopUpUseCase initiateTopUpUseCase;
  final GetSpendingStatsUseCase getSpendingStatsUseCase;

  TransactionProvider({
    required this.getTransactionsUseCase,
    required this.initiateTopUpUseCase,
    required this.getSpendingStatsUseCase,
  });

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isLoadingMore = false;
  bool get isLoadingMore => _isLoadingMore;

  String? _error;
  String? get error => _error;

  bool _isCreatingTopUpUrl = false;
  bool get isCreatingTopUpUrl => _isCreatingTopUpUrl;

  String? _topUpError;
  String? get topUpError => _topUpError;

  List<Transaction> _transactions = [];
  List<Transaction> get transactions => _transactions;

  // Periods: 'ALL', 'DAY', 'MONTH', 'YEAR'
  String _selectedPeriod = 'ALL';
  String get selectedPeriod => _selectedPeriod;

  // Methods: 'ALL', 'WALLET', 'SEPAY', 'VNPAY', 'WITHDRAW'
  String _selectedMethod = 'ALL';
  String get selectedMethod => _selectedMethod;

  SpendingStats? _spendingStats;
  SpendingStats? get spendingStats => _spendingStats ?? computeStatsForPeriod(_selectedPeriod);

  bool _isLoadingStats = false;
  bool get isLoadingStats => _isLoadingStats;

  int _currentPage = 1;
  int _totalItems = 0;
  int get totalItems => _totalItems;
  bool _hasReachedMax = false;
  bool get hasReachedMax => _hasReachedMax;

  void setPeriod(String period) {
    if (_selectedPeriod == period) return;
    _selectedPeriod = period;
    notifyListeners();
    fetchSpendingStats(period: period);
  }

  void setMethodFilter(String method) {
    if (_selectedMethod == method) return;
    _selectedMethod = method;
    notifyListeners();
  }

  List<Transaction> get periodTransactions {
    final now = DateTime.now();
    return _transactions.where((t) {
      final created = t.createdAt.toLocal();
      if (_selectedPeriod == 'DAY') {
        return created.year == now.year &&
            created.month == now.month &&
            created.day == now.day;
      } else if (_selectedPeriod == 'MONTH') {
        return created.year == now.year && created.month == now.month;
      } else if (_selectedPeriod == 'YEAR') {
        return created.year == now.year;
      }
      return true;
    }).toList();
  }

  List<Transaction> get filteredTransactions {
    final list = periodTransactions;
    if (_selectedMethod == 'ALL') {
      return list;
    }
    return list.where((t) => t.detectedMethod == _selectedMethod).toList();
  }

  int getMethodCount(String method) {
    final list = periodTransactions;
    if (method == 'ALL') return list.length;
    return list.where((t) => t.detectedMethod == method).length;
  }

  SpendingStats computeStatsForPeriod(String period) {
    final list = periodTransactions;
    double totalExpense = 0;
    double totalIncome = 0;
    final byService = <String, double>{
      'RENTAL': 0,
      'SEND': 0,
      'TOPUP': 0,
      'WITHDRAW': 0,
      'OTHER': 0,
    };
    final byMethod = <String, double>{
      'WALLET': 0,
      'SEPAY': 0,
      'VNPAY': 0,
      'MOMO': 0,
      'WITHDRAW': 0,
    };

    for (final tx in list) {
      final isIncome = tx.type == 'TOP_UP' || tx.type == 'CREDIT';
      if (isIncome) {
        totalIncome += tx.amount;
      } else {
        totalExpense += tx.amount;
      }

      final srv = tx.detectedService;
      byService[srv] = (byService[srv] ?? 0) + tx.amount;

      final m = tx.detectedMethod;
      byMethod[m] = (byMethod[m] ?? 0) + tx.amount;
    }

    return SpendingStats(
      period: period,
      totalExpense: totalExpense,
      totalIncome: totalIncome,
      netChange: totalIncome - totalExpense,
      transactionCount: list.length,
      byService: byService,
      byMethod: byMethod,
    );
  }

  Future<void> fetchSpendingStats({String? period}) async {
    final p = period ?? _selectedPeriod;
    _isLoadingStats = true;
    notifyListeners();

    final result = await getSpendingStatsUseCase(period: p);
    result.fold(
      (failure) {
        debugPrint('[TX][provider] fetchSpendingStats API failed: ${failure.message}, fallback to local compute');
        _spendingStats = computeStatsForPeriod(p);
      },
      (data) {
        debugPrint('[TX][provider] fetchSpendingStats API success: totalExpense=${data.totalExpense}');
        _spendingStats = data;
      },
    );

    _isLoadingStats = false;
    notifyListeners();
  }

  Future<void> fetchTransactions({bool refresh = false}) async {
    if (refresh) {
      _currentPage = 1;
      _hasReachedMax = false;
      _transactions.clear();
      _isLoading = true;
      _error = null;
      notifyListeners();
    } else {
      if (_hasReachedMax || _isLoadingMore || _isLoading) return;
      _isLoadingMore = true;
      notifyListeners();
    }

    final result = await getTransactionsUseCase(page: _currentPage, limit: 10);

    List<Transaction> walletTxs = [];
    result.fold(
      (failure) {
        debugPrint('[TX][provider] wallet transactions FAILURE: ${failure.message}');
        _error = failure.message;
      },
      (data) {
        walletTxs = data.transactions;
        _totalItems = data.total;
        _hasReachedMax = data.transactions.isEmpty;
        if (!_hasReachedMax) {
          _currentPage++;
        }
      },
    );

    // Đồng bộ thêm các đơn thanh toán trực tiếp (SePay, VNPay...) từ danh sách đơn
    List<Transaction> externalTxs = [];
    try {
      final opsService = LockerOpsService();
      final myOrders = await opsService.myOrders();

      final existingOrderIds = <int>{};
      final existingOrderCodes = <String>{};
      for (final t in walletTxs) {
        if (t.relatedOrderId != null) existingOrderIds.add(t.relatedOrderId!);
        if (t.orderCode != null && t.orderCode!.isNotEmpty) {
          existingOrderCodes.add(t.orderCode!.toUpperCase());
        }
        final match = RegExp(r'#(\d+)').firstMatch(t.description);
        if (match != null) {
          final idNum = int.tryParse(match.group(1)!);
          if (idNum != null) existingOrderIds.add(idNum);
        }
      }

      for (final o in myOrders) {
        final orderId = o['id'] is num ? (o['id'] as num).toInt() : int.tryParse('${o['id']}');
        final orderCode = o['orderCode']?.toString();
        final paymentStatus = '${o['paymentStatus']}'.toUpperCase();
        final isPaid = paymentStatus == 'PAID' || paymentStatus == 'COMPLETED';

        if (!isPaid || orderId == null) continue;

        if (existingOrderIds.contains(orderId) ||
            (orderCode != null && existingOrderCodes.contains(orderCode.toUpperCase()))) {
          continue;
        }

        try {
          final payments = await opsService.paymentsByOrder(orderId);
          final donePayments = payments
              .where((p) => '${p['status']}'.toUpperCase() == 'COMPLETED')
              .toList();

          if (donePayments.isNotEmpty) {
            for (final p in donePayments) {
              final method = (p['method'] ?? 'SEPAY').toString().toUpperCase();
              if (method == 'WALLET') continue;

              final refId = (p['referenceTransactionId'] != null && '${p['referenceTransactionId']}'.isNotEmpty)
                  ? '${p['referenceTransactionId']}'
                  : (p['referenceId']?.toString() ?? 'SEPAY-$orderId');

              final amount = (p['amount'] is num)
                  ? (p['amount'] as num).toDouble()
                  : (double.tryParse('${p['amount']}') ??
                      (o['paidAmount'] is num
                          ? (o['paidAmount'] as num).toDouble()
                          : (o['totalPrice'] is num ? (o['totalPrice'] as num).toDouble() : 0.0)));

              final createdStr = p['createdAt'] ?? p['updatedAt'] ?? o['createdAt'];
              final createdAt = createdStr != null
                  ? (DateTime.tryParse('$createdStr')?.toLocal() ?? DateTime.now())
                  : DateTime.now();

              externalTxs.add(Transaction(
                id: 'PAY-${p['id'] ?? orderId}',
                referenceId: refId,
                relatedOrderId: orderId,
                orderCode: orderCode,
                amount: amount,
                type: 'DEBIT',
                source: method,
                description: 'Thanh toán đơn ${orderCode ?? '#$orderId'}',
                balanceAfter: 0.0,
                createdAt: createdAt,
              ));
            }
          } else {
            final amount = (o['paidAmount'] is num)
                ? (o['paidAmount'] as num).toDouble()
                : (o['totalPrice'] is num ? (o['totalPrice'] as num).toDouble() : 0.0);
            final createdStr = o['createdAt'];
            final createdAt = createdStr != null
                ? (DateTime.tryParse('$createdStr')?.toLocal() ?? DateTime.now())
                : DateTime.now();

            externalTxs.add(Transaction(
              id: 'ORD-$orderId',
              referenceId: 'SEPAY-$orderId',
              relatedOrderId: orderId,
              orderCode: orderCode,
              amount: amount,
              type: 'DEBIT',
              source: 'SEPAY',
              description: 'Thanh toán đơn ${orderCode ?? '#$orderId'}',
              balanceAfter: 0.0,
              createdAt: createdAt,
            ));
          }
        } catch (e) {
          debugPrint('[TX][provider] paymentsByOrder error for order $orderId: $e');
        }
      }
    } catch (e) {
      debugPrint('[TX][provider] fetch myOrders error: $e');
    }

    final combined = <Transaction>[...walletTxs, ...externalTxs];
    combined.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    if (refresh) {
      _transactions = combined;
    } else {
      _transactions.addAll(combined);
    }

    if (refresh) {
      _isLoading = false;
    } else {
      _isLoadingMore = false;
    }

    // Recompute stats and attempt API sync
    _spendingStats = computeStatsForPeriod(_selectedPeriod);
    fetchSpendingStats(period: _selectedPeriod);
    notifyListeners();
  }

  Future<TopUpResult?> initiateTopUp(int amount, {String method = 'VNPAY'}) async {
    if (_isCreatingTopUpUrl) return null;
    debugPrint('[TOPUP][provider] initiateTopUp(amount=$amount, method=$method)');
    if (amount <= 0) {
      _topUpError = 'Số tiền không hợp lệ.';
      notifyListeners();
      return null;
    }
    _isCreatingTopUpUrl = true;
    _topUpError = null;
    notifyListeners();

    final result = await initiateTopUpUseCase(amount: amount, method: method);

    TopUpResult? entity;
    result.fold(
      (failure) {
        debugPrint('[TOPUP][provider] failure=${failure.message}');
        _topUpError = failure.message;
      },
      (data) {
        debugPrint(
          '[TOPUP][provider] success url="${data.paymentUrl}" ref="${data.txnRef}"',
        );
        entity = data;
      },
    );

    _isCreatingTopUpUrl = false;
    notifyListeners();
    return entity;
  }
}
