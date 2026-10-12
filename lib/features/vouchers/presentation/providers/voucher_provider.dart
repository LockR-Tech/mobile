import 'package:flutter/material.dart';
import 'package:smart_laundry_locker/core/utils/user_error_message.dart';
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
