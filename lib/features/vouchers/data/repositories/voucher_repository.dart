import 'package:smart_laundry_locker/core/network/api_client.dart';
import '../models/voucher_model.dart';

/// "Ví voucher" — backed by order-service promotion_claims:
/// user lưu mã từ trang Khuyến mãi, mã tự chuyển USED khi được áp vào đơn.
class VoucherRepository {
  final ApiClient _apiClient = ApiClient();

  /// Các mã user đã lưu (SAVED / USED / EXPIRED), mới nhất trước.
  Future<List<VoucherModel>> getMyVouchers({String? status}) async {
    final response = await _apiClient.get(
      '/api/promotions/vouchers/my',
      queryParameters: status == null ? null : {'status': status},
    );
    final data = response.data;
    final items = data is Map ? (data['data'] ?? []) : data;
    if (items is! List) return const [];
    return items
        .whereType<Map<String, dynamic>>()
        .map(VoucherModel.fromJson)
        .toList();
  }

  /// Lưu một khuyến mãi vào ví. Idempotent — lưu lại mã đã có không lỗi.
  Future<VoucherModel?> claimPromotion(int promotionId) async {
    final response =
        await _apiClient.post('/api/promotions/$promotionId/claim', data: {});
    final data = response.data;
    final item = data is Map ? data['data'] : null;
    return item is Map<String, dynamic> ? VoucherModel.fromJson(item) : null;
  }
}
