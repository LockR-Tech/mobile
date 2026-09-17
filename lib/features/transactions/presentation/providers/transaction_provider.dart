import 'package:flutter/material.dart';
import 'package:smart_laundry_locker/features/transactions/application/use_cases/initiate_top_up_use_case.dart';
import 'package:smart_laundry_locker/features/transactions/application/use_cases/get_transactions_use_case.dart';
import 'package:smart_laundry_locker/features/transactions/domain/entities/transaction.dart';
import 'package:smart_laundry_locker/features/transactions/domain/entities/top_up_result.dart';
import 'package:flutter/foundation.dart';

class TransactionProvider extends ChangeNotifier {
  final GetTransactionsUseCase getTransactionsUseCase;
  final InitiateTopUpUseCase initiateTopUpUseCase;

  TransactionProvider({
    required this.getTransactionsUseCase,
    required this.initiateTopUpUseCase,
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

  List<Transaction> filtered() {
    return _transactions;
  }

  int _currentPage = 1;
  int _totalItems = 0;
  bool _hasReachedMax = false;
  bool get hasReachedMax => _hasReachedMax;

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

    result.fold(
      (failure) {
        debugPrint('[TX][provider] FAILURE: ${failure.message}');
        _error = failure.message;
        if (refresh)
          _isLoading = false;
        else
          _isLoadingMore = false;
        notifyListeners();
      },
      (data) {
        debugPrint(
          '[TX][provider] fetched ${data.transactions.length} transactions (total=${data.total})',
        );
        if (data.transactions.isNotEmpty) {
          for (var i = 0; i < data.transactions.length; i++) {
            final t = data.transactions[i];
            debugPrint(
              '[TX][provider]   #$i: id=${t.id} ref=${t.referenceId} type=${t.type} amount=${t.amount}',
            );
          }
        } else {
          debugPrint('[TX][provider]   -> list is empty from API');
        }

        if (refresh) {
          _transactions = data.transactions;
        } else {
          _transactions.addAll(data.transactions);
        }

        _totalItems = data.total;
        _hasReachedMax =
            _transactions.length >= _totalItems || data.transactions.isEmpty;

        if (!_hasReachedMax) {
          _currentPage++;
        }

        if (refresh)
          _isLoading = false;
        else
          _isLoadingMore = false;
        notifyListeners();
      },
    );
  }

  Future<TopUpResult?> initiateTopUp(int amount) async {
    if (_isCreatingTopUpUrl) return null;
    debugPrint('[TOPUP][provider] initiateTopUp(amount=$amount)');
    if (amount <= 0) {
      _topUpError = 'Số tiền không hợp lệ.';
      notifyListeners();
      debugPrint('[TOPUP][provider] invalid amount -> abort');
      return null;
    }
    _isCreatingTopUpUrl = true;
    _topUpError = null;
    notifyListeners();

    final result = await initiateTopUpUseCase(amount: amount);

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
