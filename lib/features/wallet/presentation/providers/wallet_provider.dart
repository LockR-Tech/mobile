import 'dart:async';
import 'package:flutter/material.dart';
import 'package:smart_laundry_locker/core/config/feature_flags.dart';
import 'package:smart_laundry_locker/core/network/api_client.dart';
import 'package:smart_laundry_locker/core/services/token_service.dart';
import 'package:smart_laundry_locker/core/services/app_event_bus.dart';
import 'package:smart_laundry_locker/core/utils/user_error_message.dart';
import 'package:smart_laundry_locker/features/wallet/domain/withdrawal_request.dart';

class WalletProvider extends ChangeNotifier {
  final ApiClient _apiClient;
  StreamSubscription<AppEvent>? _eventSub;

  WalletProvider({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient() {
    TokenService.authState.addListener(_onAuthStateChanged);
    _eventSub = AppEventBus.instance.events.listen((event) {
      if (event is WalletUpdatedEvent || event is PaymentCompletedEvent) {
        getWalletBalance();
        // Admin duyệt/từ chối rút tiền: danh sách yêu cầu rút cũng đổi.
        if (_withdrawalsFetched) fetchWithdrawals();
      }
    });
  }

  void _onAuthStateChanged() {
    if (TokenService.authState.value) {
      getWalletBalance();
    } else {
      _balance = 0;
      _withdrawableBalance = 0;
      _withdrawableKnown = false;
      _withdrawals = const [];
      _withdrawalsFetched = false;
      notifyListeners();
    }
  }

  double _balance = 0;
  double get balance => _balance;

  double _withdrawableBalance = 0;
  double get withdrawableBalance => _withdrawableBalance;

  /// `false` khi không đọc được `GET /api/wallet/withdrawable-balance`. Khi đó
  /// KHÔNG được coi cả số dư là rút được (chỉ tiền nạp/hoàn qua cổng thanh toán mới
  /// rút được) — màn rút tiền báo "chưa xác định" và để backend kiểm.
  bool _withdrawableKnown = false;
  bool get withdrawableKnown => _withdrawableKnown;

  List<WithdrawalRequest> _withdrawals = const [];
  List<WithdrawalRequest> get withdrawals => _withdrawals;

  bool _isLoadingWithdrawals = false;
  bool _withdrawalsFetched = false;
  bool get isLoadingWithdrawals => _isLoadingWithdrawals;

  String? _withdrawalsError;
  String? get withdrawalsError => _withdrawalsError;

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
          final withdrawable = rawWithdrawable is num
              ? rawWithdrawable.toDouble()
              : double.tryParse('$rawWithdrawable');
          _withdrawableBalance = withdrawable ?? 0;
          _withdrawableKnown = withdrawable != null;
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
      // Không biết phần rút được ⇒ không suy ra từ tổng số dư.
      _withdrawableBalance = 0;
      _withdrawableKnown = false;
    } catch (e) {
      _error = userErrorMessage(e, fallback: 'Không tải được số dư ví.');
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
          _withdrawableKnown = true;
        }
      }

      AppEventBus.instance.emit(const WalletUpdatedEvent());
      return payload ?? {};
    } catch (e) {
      _error = userErrorMessage(e, fallback: 'Không gửi được yêu cầu rút tiền.');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Yêu cầu rút tiền của tôi (`GET /api/wallet/withdrawals`), mới nhất trước.
  Future<void> fetchWithdrawals() async {
    if (_isLoadingWithdrawals) return;
    _isLoadingWithdrawals = true;
    _withdrawalsFetched = true;
    _withdrawalsError = null;
    notifyListeners();
    try {
      final response = await _apiClient.get<dynamic>('/api/wallet/withdrawals');
      final body = response.data;
      final data = body is Map<String, dynamic> ? body['data'] : body;
      final list = data is List
          ? data
                .whereType<Map<String, dynamic>>()
                .map(WithdrawalRequest.fromJson)
                .toList()
          : <WithdrawalRequest>[];
      list.sort((a, b) {
        final at = a.createdAt, bt = b.createdAt;
        if (at == null || bt == null) return b.id.compareTo(a.id);
        return bt.compareTo(at);
      });
      _withdrawals = list;
    } catch (e) {
      _withdrawalsError = userErrorMessage(
        e,
        notFound: 'Máy chủ chưa hỗ trợ xem yêu cầu rút tiền.',
        fallback: 'Không tải được danh sách yêu cầu rút tiền.',
      );
    } finally {
      _isLoadingWithdrawals = false;
      notifyListeners();
    }
  }

  /// Yêu cầu rút tiền ứng với giao dịch ví có [referenceId] (`WDR-…`).
  WithdrawalRequest? withdrawalFor(String? referenceId) {
    if (referenceId == null || referenceId.isEmpty) return null;
    for (final w in _withdrawals) {
      if (w.referenceId == referenceId) return w;
    }
    return null;
  }

  @override
  void dispose() {
    _eventSub?.cancel();
    TokenService.authState.removeListener(_onAuthStateChanged);
    super.dispose();
  }
}
