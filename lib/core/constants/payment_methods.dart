/// Phương thức thanh toán của app khách.
///
/// Quyết định của chủ sản phẩm: MỌI khoản thanh toán đơn (gửi hàng, thuê tủ,
/// gia hạn, phí quá hạn, đơn drone) chỉ qua chuyển khoản SePay VietQR — không
/// còn bảng chọn phương thức, không trả bằng ví (ví đã gỡ khỏi app). MoMo và
/// VNPay đã bỏ hẳn: backend từ chối với `400 PAYMENT_METHOD_UNSUPPORTED`. Giao
/// dịch/thanh toán CŨ có method `VNPAY`/`MOMO`/`WALLET` vẫn hiển thị đúng nhãn
/// ở lịch sử (màn chi tiết đơn, đơn drone, lịch sử giao dịch).
class PaymentMethods {
  const PaymentMethods._();

  static const String sepay = 'SEPAY';

  /// Phương thức duy nhất gửi lên `POST /api/payments/checkout`.
  static const String orderPayment = sepay;

  /// Mã lỗi backend khi gửi phương thức đã bỏ (MOMO/VNPAY).
  static const String unsupportedErrorCode = 'PAYMENT_METHOD_UNSUPPORTED';

  static const String unsupportedMessage =
      'Phương thức thanh toán này không còn được hỗ trợ. '
      'Vui lòng thanh toán bằng chuyển khoản SePay (VietQR).';

  /// Lọc danh sách admin bật (`enabled-methods`) về các phương thức app hỗ trợ
  /// trong [allowed], giữ thứ tự của [allowed].
  static List<String> enabledAmong(
    Iterable<String> adminEnabled, {
    List<String> allowed = const [orderPayment],
  }) {
    final enabled = adminEnabled.map((m) => m.trim().toUpperCase()).toSet();
    return [
      for (final method in allowed)
        if (enabled.contains(method)) method,
    ];
  }
}
