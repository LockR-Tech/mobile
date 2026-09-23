import 'dart:async';
import 'package:flutter/material.dart';
import 'package:smart_laundry_locker/core/config/feature_flags.dart';
import 'package:smart_laundry_locker/core/network/api_client.dart';
import 'package:smart_laundry_locker/core/services/token_service.dart';
import 'package:smart_laundry_locker/core/services/app_event_bus.dart';

class WalletProvider extends ChangeNotifier {
  final ApiClient _apiClient;
  StreamSubscription<AppEvent>? _eventSub;

  WalletProvider({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient() {
    TokenService.authState.addListener(_onAuthStateChanged);
    _eventSub = AppEventBus.instance.events.listen((event) {
      if (event is WalletUpdatedEvent || event is PaymentCompletedEvent) {
        getWalletBalance();
      }
    });
  }

  void _onAuthStateChanged() {
    if (TokenService.authState.value) {
      getWalletBalance();
    } else {
      _balance = 0;
      notifyListeners();
    }
  }

  double _balance = 0;
  double get balance => _balance;

  double _withdrawableBalance = 0;
  double get withdrawableBalance => _withdrawableBalance;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  void setBalance(double value) {
    if (_balance == value) return;
    _balance = value;
    notifyListeners();
  }

  Future<void> getWalletBalance() async {
    if (!FeatureFlags.walletEnabled) return;
    if (_isLoading) return;
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      try {
        final response = await _apiClient.get<dynamic>('/api/wallet/withdrawable-balance');
        final data = response.data;
        Map<String, dynamic>? payload;
        if (data is Map<String, dynamic>) {
          payload = (data['data'] is Map<String, dynamic>)
              ? (data['data'] as Map<String, dynamic>)
              : data;
        }

        if (payload != null) {
          final rawTotal = payload['totalBalance'];
          _balance = rawTotal is num
              ? rawTotal.toDouble()
              : double.tryParse('$rawTotal') ?? 0;

          final rawWithdrawable = payload['withdrawableBalance'];
          _withdrawableBalance = rawWithdrawable is num
              ? rawWithdrawable.toDouble()
              : double.tryParse('$rawWithdrawable') ?? 0;
          return;
        }
      } catch (_) {
        // Fallback to /api/wallet if withdrawable-balance endpoint is unavailable
      }

      final response = await _apiClient.get<dynamic>('/api/wallet');
      final data = response.data;
      Map<String, dynamic>? payload;
      if (data is Map<String, dynamic>) {
        payload = (data['data'] is Map<String, dynamic>)
            ? (data['data'] as Map<String, dynamic>)
            : data;
      }

      final raw = payload?['balance'];
      final balance = raw is num
          ? raw.toDouble()
          : double.tryParse('$raw') ?? 0;
      _balance = balance;
      _withdrawableBalance = balance;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>> withdraw({
    required String bankName,
    required String bankCode,
    required String accountNumber,
    required String accountHolderName,
    required double amount,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiClient.post<Map<String, dynamic>>(
        '/api/wallet/withdraw',
        data: {
          'bankName': bankName,
          'bankCode': bankCode,
          'accountNumber': accountNumber,
          'accountHolderName': accountHolderName,
          'amount': amount,
        },
      );

      final data = response.data;
      Map<String, dynamic>? payload;
      if (data != null) {
        payload = (data['data'] is Map<String, dynamic>)
            ? data['data'] as Map<String, dynamic>
            : data;
      }

      if (payload != null) {
        final balAfter = payload['balanceAfter'];
        if (balAfter is num) {
          _balance = balAfter.toDouble();
        }
        final withAfter = payload['withdrawableBalance'];
        if (withAfter is num) {
          _withdrawableBalance = withAfter.toDouble();
        }
      }

      AppEventBus.instance.emit(const WalletUpdatedEvent());
      return payload ?? {};
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _eventSub?.cancel();
    TokenService.authState.removeListener(_onAuthStateChanged);
    super.dispose();
  }
}
