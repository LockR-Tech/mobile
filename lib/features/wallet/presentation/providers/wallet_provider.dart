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
    } catch (e) {
      _error = e.toString();
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
