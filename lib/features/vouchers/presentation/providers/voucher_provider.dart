import 'dart:async';

import 'package:flutter/material.dart';
import 'package:smart_laundry_locker/core/services/app_event_bus.dart';
import 'package:smart_laundry_locker/core/utils/user_error_message.dart';
import '../../data/models/exchangeable_voucher_model.dart';
import '../../data/models/voucher_model.dart';
import '../../data/repositories/voucher_repository.dart';
import 'package:smart_laundry_locker/core/l10n/l10n.dart';

class VoucherProvider extends ChangeNotifier {
  final VoucherRepository _repository = VoucherRepository();

  StreamSubscription<AppEvent>? _eventSub;
  bool _vouchersLoaded = false;
  String? _lastStatus;
  bool _exchangeLoaded = false;
  bool _disposed = false;

  VoucherProvider() {
    _eventSub = AppEventBus.instance.events.listen((event) {
      // Admin sửa/tắt/xoá khuyến mãi ⇒ kho voucher + danh sách đổi điểm đổi.
      if (event is CatalogChangedEvent && event.isPromotion) {
        if (_vouchersLoaded && !_isLoading) {
          loadMyVouchers(status: _lastStatus, silent: true);
        }
        if (_exchangeLoaded && !_exchangeLoading) loadExchange(silent: true);
      }
      // Số điểm đổi (cộng sau đơn, admin điều chỉnh) ⇒ số điểm ở tab Đổi điểm.
      if (event is LoyaltyUpdatedEvent && _exchangeLoaded && !_exchangeLoading) {
        loadExchange(silent: true);
      }
    });
  }

  @override
  void dispose() {
    _disposed = true;
    _eventSub?.cancel();
    super.dispose();
  }

  @override
  void notifyListeners() {
    if (!_disposed) super.notifyListeners();
  }

  List<VoucherModel> _vouchers = [];
  bool _isLoading = false;
  String? _error;

  List<VoucherModel> get vouchers => _vouchers;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // ---- Đổi điểm lấy voucher ----
  List<ExchangeableVoucherModel> _exchangeable = [];
  int? _pointsBalance;
  bool _exchangeLoading = false;
  String? _exchangeError;
  int? _exchangingId;

  List<ExchangeableVoucherModel> get exchangeable => _exchangeable;

  /// Số điểm hiện có; null khi chưa tải được.
  int? get pointsBalance => _pointsBalance;
  bool get exchangeLoading => _exchangeLoading;
  String? get exchangeError => _exchangeError;

  /// Voucher đang gửi lệnh đổi (để khoá nút, tránh bấm hai lần).
  int? get exchangingId => _exchangingId;

  /// [silent]: tải lại ngầm khi có tin realtime — giữ dữ liệu đang hiện, lỗi
  /// thì giữ nguyên.
  Future<void> loadExchange({bool silent = false}) async {
    _exchangeLoaded = true;
    _exchangeLoading = true;
    if (!silent) {
      _exchangeError = null;
      notifyListeners();
    }
    try {
      final results = await Future.wait([
        _repository.getExchangeableVouchers(),
        _repository.getPointsBalance(),
      ]);
      _exchangeable = results[0] as List<ExchangeableVoucherModel>;
      _pointsBalance = results[1] as int;
      _exchangeError = null;
    } catch (e) {
      if (silent) return;
      _exchangeable = [];
      _exchangeError = userErrorMessage(
        e,
        notFound: L10n.current.voucherExchangeNotSupported,
        fallback: L10n.current.voucherExchangeLoadFailed,
      );
    } finally {
      _exchangeLoading = false;
      notifyListeners();
    }
  }

  /// Đổi điểm lấy voucher. Trả null khi thành công, câu lỗi khi thất bại.
  /// Thành công thì tải lại kho voucher + danh sách đổi + số điểm.
  Future<String?> exchange(ExchangeableVoucherModel voucher) async {
    if (_exchangingId != null) return null;
    _exchangingId = voucher.id;
    notifyListeners();
    try {
      final outcome = await _repository.exchangeVoucher(voucher.id);
      _pointsBalance = outcome.balance;
      await Future.wait([loadMyVouchers(), loadExchange()]);
      return null;
    } catch (e) {
      return userErrorMessage(
        e,
        fallback: L10n.current.voucherExchangeFailed,
      );
    } finally {
      _exchangingId = null;
      notifyListeners();
    }
  }

  Future<void> loadMyVouchers({String? status, bool silent = false}) async {
    _vouchersLoaded = true;
    _lastStatus = status;
    _isLoading = true;
    if (!silent) {
      _error = null;
      notifyListeners();
    }

    try {
      _vouchers = await _repository.getMyVouchers(status: status);
      _error = null;
    } catch (e) {
      if (silent) return;
      _vouchers = [];
      _error = userErrorMessage(
        e,
        notFound: L10n.current.voucherWalletNotSupported,
        fallback: L10n.current.voucherMineLoadFailed,
      );
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Lưu một khuyến mãi vào ví (từ trang Khuyến mãi). Trả về false nếu lỗi.
  Future<bool> claimPromotion(int promotionId) async {
    try {
      await _repository.claimPromotion(promotionId);
      await loadMyVouchers();
      return true;
    } catch (_) {
      return false;
    }
  }
}
