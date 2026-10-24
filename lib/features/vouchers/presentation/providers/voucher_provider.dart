import 'package:flutter/material.dart';
import 'package:smart_laundry_locker/core/utils/user_error_message.dart';
import '../../data/models/exchangeable_voucher_model.dart';
import '../../data/models/voucher_model.dart';
import '../../data/repositories/voucher_repository.dart';

class VoucherProvider extends ChangeNotifier {
  final VoucherRepository _repository = VoucherRepository();

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

  Future<void> loadExchange() async {
    _exchangeLoading = true;
    _exchangeError = null;
    notifyListeners();
    try {
      final results = await Future.wait([
        _repository.getExchangeableVouchers(),
        _repository.getPointsBalance(),
      ]);
      _exchangeable = results[0] as List<ExchangeableVoucherModel>;
      _pointsBalance = results[1] as int;
    } catch (e) {
      _exchangeable = [];
      _exchangeError = userErrorMessage(
        e,
        notFound: 'Máy chủ chưa hỗ trợ đổi điểm. Vui lòng thử lại sau.',
        fallback: 'Không tải được danh sách đổi điểm. Vui lòng thử lại.',
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
        fallback: 'Chưa đổi được voucher. Vui lòng thử lại.',
      );
    } finally {
      _exchangingId = null;
      notifyListeners();
    }
  }

  Future<void> loadMyVouchers({String? status}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _vouchers = await _repository.getMyVouchers(status: status);
    } catch (e) {
      _vouchers = [];
      _error = userErrorMessage(
        e,
        notFound: 'Máy chủ chưa hỗ trợ kho ưu đãi. Vui lòng thử lại sau.',
        fallback: 'Không tải được ưu đãi của bạn. Vui lòng thử lại.',
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
