import 'package:flutter/material.dart';
import 'package:smart_laundry_locker/features/transactions/application/use_cases/get_transactions_use_case.dart';
import 'package:smart_laundry_locker/features/transactions/application/use_cases/get_spending_stats_use_case.dart';
import 'package:smart_laundry_locker/features/transactions/application/use_cases/get_total_by_method_use_case.dart';
import 'package:smart_laundry_locker/features/transactions/domain/entities/transaction.dart';
import 'package:smart_laundry_locker/features/transactions/domain/entities/spending_stats.dart';
import 'package:smart_laundry_locker/features/transactions/domain/entities/transaction_method_total.dart';
import 'package:smart_laundry_locker/features/transactions/domain/entities/transaction_extensions.dart';
import 'package:flutter/foundation.dart';

class TransactionProvider extends ChangeNotifier {
  final GetTransactionsUseCase getTransactionsUseCase;
  final GetSpendingStatsUseCase getSpendingStatsUseCase;
  final GetTotalByMethodUseCase getTotalByMethodUseCase;

  TransactionProvider({
    required this.getTransactionsUseCase,
    required this.getSpendingStatsUseCase,
    required this.getTotalByMethodUseCase,
  });

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isLoadingMore = false;
  bool get isLoadingMore => _isLoadingMore;

  String? _error;
  String? get error => _error;

  List<Transaction> _transactions = [];
  List<Transaction> get transactions => _transactions;

  // Periods: 'ALL', 'DAY', 'MONTH', 'YEAR'
  String _selectedPeriod = 'ALL';
  String get selectedPeriod => _selectedPeriod;

  // Methods: 'ALL', 'WALLET', 'SEPAY', 'WITHDRAW' (+ 'VNPAY'/'MOMO' khi còn giao
  // dịch cũ qua hai cổng đã bỏ)
  String _selectedMethod = 'ALL';
  String get selectedMethod => _selectedMethod;

  SpendingStats? _spendingStats;
  SpendingStats? get spendingStats => _spendingStats ?? computeStatsForPeriod(_selectedPeriod);

  TransactionMethodTotal? _methodTotal;
  TransactionMethodTotal? get methodTotal => _methodTotal;

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
    fetchTotalByMethod(period: period);
  }

  void setMethodFilter(String method) {
    if (_selectedMethod == method) return;
    _selectedMethod = method;
    notifyListeners();
    fetchTotalByMethod(method: method);
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

  double getMethodAmount(String method) {
    if (_methodTotal != null && _methodTotal!.summary.isNotEmpty) {
      if (method == 'ALL') {
        return _methodTotal!.totalAmount;
      }
      if (_methodTotal!.summary.containsKey(method)) {
        return _methodTotal!.summary[method] ?? 0.0;
      }
    }
    final list = periodTransactions;
    if (method == 'ALL') {
      return list.fold(0.0, (sum, t) => sum + t.amount);
    }
    return list
        .where((t) => t.detectedMethod == method)
        .fold(0.0, (sum, t) => sum + t.amount);
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
      if (tx.isCredit) {
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

  Future<void> fetchTotalByMethod({String? method, String? period}) async {
    final p = period ?? _selectedPeriod;
    final m = method ?? _selectedMethod;
    final result = await getTotalByMethodUseCase(period: p, method: m);
    result.fold(
      (failure) {
        debugPrint('[TX][provider] fetchTotalByMethod failed: ${failure.message}');
      },
      (data) {
        debugPrint('[TX][provider] fetchTotalByMethod success: totalAmount=${data.totalAmount}, count=${data.transactionCount}');
        _methodTotal = data;
        notifyListeners();
      },
    );
  }

  /// [silent] (cùng [refresh]): tải lại ngầm khi có tin realtime — giữ danh
  /// sách đang hiện tới khi có dữ liệu mới, không nháy vòng tải.
  Future<void> fetchTransactions({bool refresh = false, bool silent = false}) async {
    if (refresh && silent) {
      _currentPage = 1;
      _hasReachedMax = false;
    } else if (refresh) {
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

    // `GET /api/wallet/transactions` đã gồm cả biến động ví lẫn thanh toán đơn
    // trực tiếp qua cổng (SePay/VNPay/MoMo/tiền mặt) — backend ghép sẵn. Trước
    // đây app tự dựng thêm dòng "Thanh toán SePay" từ danh sách đơn (kể cả dòng
    // bịa `SEPAY-<orderId>` khi không có bản ghi thanh toán) ⇒ bỏ hẳn.
    // Endpoint không phân trang: một lần tải là đủ, tải tiếp sẽ nhân đôi dòng.
    result.fold(
      (failure) {
        debugPrint('[TX][provider] wallet transactions FAILURE: ${failure.message}');
        _error = failure.message;
      },
      (data) {
        final sorted = [...data.transactions]
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
        _transactions = sorted;
        _totalItems = data.total;
        _error = null;
        _hasReachedMax = true;
      },
    );

    _isLoading = false;
    _isLoadingMore = false;

    // Recompute stats and attempt API sync
    _spendingStats = computeStatsForPeriod(_selectedPeriod);
    fetchSpendingStats(period: _selectedPeriod);
    fetchTotalByMethod(period: _selectedPeriod);
    notifyListeners();
  }
}
