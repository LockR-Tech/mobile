import 'package:dio/dio.dart';
import 'package:smart_laundry_locker/core/constants/payment_methods.dart';
import 'package:smart_laundry_locker/core/media/media_upload.dart';
import 'package:smart_laundry_locker/core/network/dio_client.dart';
import 'package:smart_laundry_locker/features/locker_ops/data/device_restart_result.dart';
import 'package:smart_laundry_locker/features/locker_ops/data/force_open_result.dart';
import 'package:smart_laundry_locker/core/l10n/l10n.dart';

export 'package:smart_laundry_locker/features/locker_ops/data/device_restart_result.dart';
export 'package:smart_laundry_locker/features/locker_ops/data/force_open_result.dart';

/// Lỗi phía app trong luồng đơn/thanh toán, [message] đã là câu tiếng Việt cho
/// người dùng (vd. server không trả mã VietQR). [LockerOpsService.errorMessage]
/// trả nguyên câu này.
class LockerOpsException implements Exception {
  const LockerOpsException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Thin typed gateway client for the locker flow (Phase 1+2 backend).
/// All calls go through the API gateway with the JWT already attached
/// by [DioClient]/AuthInterceptor.
class LockerOpsService {
  LockerOpsService({Dio? dio}) : _dio = dio ?? DioClient.instance.dio;

  final Dio _dio;

  Future<List<Map<String, dynamic>>> _list(
    String path, {
    Map<String, dynamic>? query,
  }) async {
    final res = await _dio.get(path, queryParameters: query);
    var data = res.data?['data'];
    // Backend có endpoint trả thẳng List, có endpoint trả Spring Page (.content).
    if (data is Map && data['content'] is List) {
      data = data['content'];
    }
    if (data is List) {
      return data
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }
    return const [];
  }

  Future<Map<String, dynamic>> _map(
    String method,
    String path, {
    Map<String, dynamic>? body,
    Map<String, dynamic>? query,
    Map<String, dynamic>? headers,
  }) async {
    final res = await _dio.request(
      path,
      data: body,
      queryParameters: query,
      options: Options(method: method, headers: headers),
    );
    final data = res.data?['data'];
    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }
    return <String, dynamic>{};
  }

  /// POST trả về danh sách (hoặc object có `attachments[]`).
  Future<List<Map<String, dynamic>>> _postList(
    String path,
    Map<String, dynamic> body,
  ) async {
    final res = await _dio.post<dynamic>(path, data: body);
    final raw = res.data;
    var data = raw is Map ? raw['data'] : null;
    if (data is Map && data['attachments'] is List) {
      data = data['attachments'];
    }
    if (data is List) {
      return data
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList(growable: false);
    }
    return const [];
  }

  // ---- Catalogue ----
  Future<List<Map<String, dynamic>>> lockers() => _list('/api/lockers');

  Future<List<Map<String, dynamic>>> lockersByStore(int storeId) =>
      _list('/api/lockers', query: {'storeId': storeId});

  Future<Map<String, dynamic>> locker(int lockerId) =>
      _map('GET', '/api/lockers/$lockerId');

  Future<Map<String, dynamic>> layout(int lockerId) =>
      _map('GET', '/api/lockers/$lockerId/layout');

  // ---- Thử mở ô qua Bluetooth (F3-G11) ----
  /// Tủ admin cho tài khoản này thử mở ô qua Bluetooth; rỗng ⇒ ẩn nút ở Hồ sơ.
  Future<List<Map<String, dynamic>>> bleTestLockers() =>
      _list('/api/iot/ble-test/lockers');

  /// Mã mở ô [boxNumber] (sống 2 phút, dùng một lần) để ghi cho Pi qua BLE.
  Future<Map<String, dynamic>> bleOpenToken(int lockerId, int boxNumber) =>
      _map('POST', '/api/iot/ble-test/lockers/$lockerId/boxes/$boxNumber/token');

  // ---- Customer orders ----
  Future<List<Map<String, dynamic>>> myOrders() =>
      _list('/api/orders/my-orders');

  /// Lịch sử chuyển trạng thái của đơn, cũ trước mới sau.
  /// Mỗi phần tử: `oldStatus`, `newStatus`, `changedByUserId`, `note`, `createdAt`
  /// (`createdAt` là `LocalDateTime` UTC không offset, giống các trường thời gian khác).
  Future<List<Map<String, dynamic>>> orderTimeline(int orderId) =>
      _list('/api/orders/$orderId/timeline');

  Future<Map<String, dynamic>> createSend({
    required int lockerId,
    required String receiverPhone,
    String? receiverName,

    /// Bắt buộc với server mới (`RECEIVER_EMAIL_REQUIRED`): Lock.R báo người
    /// nhận qua email lúc tạo đơn và gửi mã mở tủ khi hàng vào ô.
    String? receiverEmail,
    String? note,
    String? promotionCode,
    String? size,

    /// Ô khách đã chọn trên sơ đồ tủ; bỏ trống thì server tự chọn theo [size].
    int? boxId,

    /// Số điểm thưởng muốn dùng (`maxPoints` của redeem-preview). Server tự
    /// kẹp lại theo quy tắc và trả `pointsUsed`/`pointsDiscount` thật.
    int? pointsToUse,
  }) => _map(
    'POST',
    '/api/orders/send',
    body: {
      'lockerId': lockerId,
      if (boxId != null) 'boxId': boxId,
      'receiverPhone': receiverPhone,
      'receiverName': receiverName,
      'note': note,
      if (receiverEmail != null) 'receiverEmail': receiverEmail,
      if (size != null) 'size': size,
      if (promotionCode != null) 'promotionCode': promotionCode,
      if (pointsToUse != null && pointsToUse > 0) 'pointsToUse': pointsToUse,
    },
  );

  Future<Map<String, dynamic>> createRental({
    required int lockerId,
    required String cellType,
    required int hours,
    String? note,
    String? promotionCode,
    int? boxId,

    /// Số điểm thưởng muốn dùng — xem [createSend].
    int? pointsToUse,
  }) => _map(
    'POST',
    '/api/orders/rental',
    body: {
      'lockerId': lockerId,
      if (boxId != null) 'boxId': boxId,
      'cellType': cellType,
      'hours': hours,
      'note': note,
      if (promotionCode != null) 'promotionCode': promotionCode,
      if (pointsToUse != null && pointsToUse > 0) 'pointsToUse': pointsToUse,
    },
  );

  /// Đặt giao drone lấy hàng tận nhà. [body] là
  /// `DroneBookingRequest.toJson()` — điểm lấy hàng, liên hệ người gửi/người nhận,
  /// tủ nhận và khai báo kiện; hệ thống tự chọn tủ gửi gần điểm lấy hàng nhất.
  Future<Map<String, dynamic>> createDroneDeliveryOrder({
    required Map<String, dynamic> body,
    required String idempotencyKey,
  }) => _map(
    'POST',
    '/api/orders/drone-deliveries',
    headers: {'Idempotency-Key': idempotencyKey},
    body: body,
  );

  /// Hỏi trước khi đặt: drone cất cánh ở tủ nào, bao xa, phí bao nhiêu.
  Future<Map<String, dynamic>> quoteDroneDelivery({
    required int destinationLockerId,
    required double pickupLatitude,
    required double pickupLongitude,
    required int parcelWeightGrams,
  }) => _map(
    'POST',
    '/api/orders/drone-deliveries/quote',
    body: {
      'destinationLockerId': destinationLockerId,
      'pickupLatitude': pickupLatitude,
      'pickupLongitude': pickupLongitude,
      'parcelWeightGrams': parcelWeightGrams,
    },
  );

  // ---- Promotions / loyalty / payments ----
  /// Validate a promo code. Returns `{code, valid, reason?, promotion:{...}}`.
  /// [lockerId] để backend check mã theo tủ (mã của tủ khác ⇒ `valid:false`
  /// kèm lý do nêu tên tủ áp dụng); [orderTotal] để kiểm đơn tối thiểu; đăng
  /// nhập rồi thì backend còn check lượt dùng còn lại của chính user.
  Future<Map<String, dynamic>> validatePromotion(
    String code, {
    int? lockerId,
    int? orderTotal,
  }) => _map(
    'GET',
    '/api/promotions/validate/$code',
    query: {
      if (lockerId != null) 'lockerId': lockerId,
      if (orderTotal != null) 'orderTotal': orderTotal,
    },
  );

  /// Khuyến mãi đang chạy. Có [lockerId] ⇒ server chỉ trả mã toàn hệ thống +
  /// mã của đúng tủ đó; mỗi mã có `lockerId`/`lockerCode`/`lockerName` (null
  /// = toàn hệ thống).
  Future<List<Map<String, dynamic>>> activePromotions({int? lockerId}) => _list(
    '/api/promotions/active',
    query: lockerId == null ? null : {'lockerId': lockerId},
  );

  /// Xem trước dùng điểm cho đơn [orderTotal] đ (số tiền SAU voucher):
  /// `{enabled, balance, vndPerPoint, maxPercent, minPoints, maxPoints,
  /// maxDiscount}`. `maxPoints = 0` khi tắt hoặc chưa đủ điểm tối thiểu.
  Future<Map<String, dynamic>> loyaltyRedeemPreview(int orderTotal) => _map(
    'GET',
    '/api/loyalty/redeem-preview',
    query: {'orderTotal': orderTotal},
  );

  /// Current user's loyalty account: `{id, userId, points, stamps, tier}`.
  Future<Map<String, dynamic>> loyaltyPoints() =>
      _map('GET', '/api/loyalty/points');

  /// Lịch sử điểm của chính người dùng, mới → cũ:
  /// `[{id, userId, orderId, points, type, createdAt}]`. Điểm tích từ đơn hoàn
  /// tất là `type = ORDER_EARN`, thu hồi khi hoàn tiền là `ORDER_EARN_REVERSAL`.
  Future<List<Map<String, dynamic>>> loyaltyHistory() =>
      _list('/api/loyalty/points/history');

  /// Tài khoản điểm của chính người dùng (server lấy người dùng từ token):
  /// `{points, tier, tierLabel?…}`.
  Future<Map<String, dynamic>> loyaltySummary() =>
      _map('GET', '/api/loyalty/summary');

  /// Voucher người dùng đã lưu (`status` SAVED / USED / EXPIRED, kèm thông tin
  /// khuyến mãi: `code`, `name`, `discountType`, `minOrderAmount`, `lockerId`,
  /// `lockerName`…). Có [lockerId] ⇒ chỉ mã dùng được ở tủ đó.
  Future<List<Map<String, dynamic>>> myVouchers({int? lockerId}) => _list(
    '/api/promotions/vouchers/my',
    query: lockerId == null ? null : {'lockerId': lockerId},
  );

  /// Payments recorded for an order (latest first by convention).
  Future<List<Map<String, dynamic>>> paymentsByOrder(int orderId) =>
      _list('/api/payments/order/$orderId');

  /// Refunds recorded for an order.
  Future<List<Map<String, dynamic>>> refundsByOrder(int orderId) =>
      _list('/api/payments/order/$orderId/refunds');

  /// Tạo giao dịch thanh toán đơn. App khách chỉ gửi `SEPAY` (xem
  /// `SepayPaymentController`); VNPAY/MOMO bị backend trả 400
  /// `PAYMENT_METHOD_UNSUPPORTED`. SEPAY trả `qrCodeUrl` VietQR và
  /// `bankTransfer {bankBin, accountNo, accountName, amount, transferContent}`.
  Future<Map<String, dynamic>> checkout(
    int orderId,
    String method, {
    String? bankCode,
    String? returnUrl,

    /// Lý do trả tiền lần này ("Phí quá hạn"…). Một đơn có thể trả nhiều lần —
    /// thuê rồi gia hạn — nên chi tiết đơn cần biết khoản nào là gì. Bỏ trống thì
    /// server tự suy ra đây là lần trả đầu hay trả bổ sung.
    String? description,
    String? orderCode,
  }) => _map(
    'POST',
    '/api/payments/checkout',
    body: {
      'orderId': orderId,
      'method': method,
      if (bankCode != null) 'bankCode': bankCode,
      if (returnUrl != null) 'returnUrl': returnUrl,
      if (description != null) 'description': description,
      if (orderCode != null) 'orderCode': orderCode,
    },
  );

  /// Giả lập đã nhận chuyển khoản (chỉ khi admin bật giả lập thanh toán):
  /// [paymentId] của giao dịch đơn; [amount] bỏ trống = đủ số tiền.
  Future<Map<String, dynamic>> simulatePayment({
    int? paymentId,
    num? amount,
  }) => _map(
    'POST',
    '/api/payments/simulate',
    body: {
      if (paymentId != null) 'paymentId': paymentId,
      if (amount != null) 'amount': amount,
    },
  );

  Future<Map<String, dynamic>> order(int orderId) =>
      _map('GET', '/api/orders/$orderId');

  /// Kiểm tra ngay một lần xem đơn đã PAID chưa (dùng để poll trong QR sheet).
  Future<bool> orderStatus(int orderId) async {
    final status = await _map('GET', '/api/orders/$orderId/status');
    return status['isPaid'] == true;
  }

  /// Đơn đã PAID chưa, đã nhận bao nhiêu và còn thiếu bao nhiêu (server cũ chưa trả hai số này ⇒ null).
  Future<({bool paid, num? paidAmount, num? amountDue})> orderPaymentProgress(
    int orderId,
  ) async {
    final status = await _map('GET', '/api/orders/$orderId/status');
    num? number(Object? raw) => raw is num ? raw : num.tryParse('${raw ?? ''}');
    return (
      paid: status['isPaid'] == true,
      paidAmount: number(status['paidAmount']),
      amountDue: number(status['amountDue']),
    );
  }

  /// Chờ đơn được ghi nhận đã thanh toán. Server ghi PAID bất đồng bộ (sự kiện
  /// payment → order), nên ngay sau checkout đơn có thể vẫn UNPAID vài giây.
  Future<bool> awaitOrderPaid(
    int orderId, {
    Duration timeout = const Duration(seconds: 60),
    Duration interval = const Duration(milliseconds: 1500),
  }) async {
    final deadline = DateTime.now().add(timeout);
    while (true) {
      try {
        final status = await _map('GET', '/api/orders/$orderId/status');
        if (status['isPaid'] == true) return true;
      } catch (_) {
        // Lỗi mạng tạm thời — thử lại tới hết hạn.
      }
      if (!DateTime.now().isBefore(deadline)) return false;
      await Future<void>.delayed(interval);
    }
  }

  Future<Map<String, dynamic>> confirmDrop(int orderId) =>
      _map('PUT', '/api/orders/$orderId/confirm');

  Future<Map<String, dynamic>> completePickup(int orderId) =>
      _map('PUT', '/api/orders/$orderId/complete');

  Future<Map<String, dynamic>> endRental(int orderId) =>
      _map('POST', '/api/orders/$orderId/pickup-storage');

  Future<Map<String, dynamic>> extendRental(int orderId, int hours) => _map(
    'POST',
    '/api/orders/$orderId/extend-rental',
    body: {'hours': hours},
  );

  Future<Map<String, dynamic>> assessOvertime(int orderId) =>
      _map('POST', '/api/orders/$orderId/assess-overtime');

  Future<Map<String, dynamic>> cancelOrder(int orderId) =>
      _map('PUT', '/api/orders/$orderId/cancel');

  /// Ủy quyền người khác lấy hộ (chỉ đơn STORING/RETURNED của chính mình). Server
  /// cấp PIN mới — PIN cũ hết hiệu lực — và người được ủy quyền thấy đơn ở
  /// [delegatedToMe].
  Future<Map<String, dynamic>> delegate(
    int orderId, {
    required String phone,
    String? name,
    String? note,
  }) => _map(
    'POST',
    '/api/orders/$orderId/delegate',
    body: {
      'phone': phone,
      if (name != null && name.trim().isNotEmpty) 'name': name.trim(),
      if (note != null && note.trim().isNotEmpty) 'note': note.trim(),
    },
  );

  /// Đơn mà tôi là người nhận (`ReceiverOrderResponse`): có `pickupPin`/`qrToken`
  /// khi `readyForPickup`.
  Future<List<Map<String, dynamic>>> incomingOrders({
    bool activeOnly = false,
    int? limit,
  }) => _list(
    '/api/orders/incoming',
    query: {'activeOnly': activeOnly, if (limit != null) 'limit': limit},
  );

  /// Đơn người khác ủy quyền cho tôi lấy hộ (cùng DTO với [incomingOrders]).
  Future<List<Map<String, dynamic>>> delegatedToMe({bool activeOnly = false}) =>
      _list('/api/orders/delegated-to-me', query: {'activeOnly': activeOnly});

  /// Chi tiết một đơn gửi tới tôi / ủy quyền cho tôi (`ReceiverOrderDetailResponse`):
  /// liên hệ người gửi, kiện hàng, tủ/ô, mốc thời gian, hành trình drone. Hai
  /// đường cùng quy tắc quyền; [delegated] chỉ chọn đường khớp với màn đang mở.
  /// Đơn không thuộc danh sách của mình ⇒ server trả 404 `NOT_FOUND`.
  Future<Map<String, dynamic>> receiverOrderDetail(
    int orderId, {
    bool delegated = false,
  }) => _map(
    'GET',
    delegated
        ? '/api/orders/delegated-to-me/$orderId'
        : '/api/orders/incoming/$orderId',
  );

  /// Người gửi đơn gửi hàng thêm / đổi email người nhận ([email] null = giữ email đang có) rồi gửi lại thư
  /// cho người nhận: hàng đã vào tủ ⇒ kèm mã mở tủ; đã thanh toán, chưa bỏ hàng ⇒ thư báo có đơn (không mã);
  /// chưa thanh toán ⇒ chỉ lưu email (`sentAt` null). Trả `{maskedEmail, includesPickupCode, sentAt}`.
  Future<Map<String, dynamic>> sendReceiverEmail(int orderId, {String? email}) => _map(
    'POST',
    '/api/orders/$orderId/receiver-email',
    body: {if (email != null && email.trim().isNotEmpty) 'email': email.trim()},
  );

  /// Gửi lại thông tin đơn nhận (kèm mã mở tủ khi hàng đã vào tủ) tới email tài khoản của mình.
  /// Trả `{maskedEmail, includesPickupCode, sentAt}`. Lỗi: `RECEIVER_EMAIL_MISSING` (tài khoản chưa có
  /// email), `RECEIVER_EMAIL_TOO_SOON` (bấm lại trong 1 phút), `RECEIVER_EMAIL_FAILED`.
  Future<Map<String, dynamic>> resendReceiverEmail(
    int orderId, {
    bool delegated = false,
  }) => _map(
    'POST',
    delegated
        ? '/api/orders/delegated-to-me/$orderId/email'
        : '/api/orders/incoming/$orderId/email',
  );

  /// Mở ô chỉ bằng mã (PIN/QR/mã ủy quyền) — server tự tra ô theo mã.
  /// Trả `{accepted, message, boxId…}`; `accepted == false` là chưa mở.
  Future<Map<String, dynamic>> unlockWithCode(int lockerId, String code) =>
      _map(
        'POST',
        '/api/iot/unlock-with-code',
        body: {'lockerId': lockerId, 'code': code.trim()},
      );

  /// Cấp PIN mới cho đơn của mình; PIN cũ hết hiệu lực.
  Future<Map<String, dynamic>> resetPin(int orderId) =>
      _map('POST', '/api/orders/$orderId/reset-pin');

  // ---- Đánh giá / khiếu nại đơn ----
  /// Đánh giá đơn đã hoàn tất (1–5 sao). Gửi lại thì server ghi đè.
  Future<Map<String, dynamic>> rateOrder(
    int orderId,
    int rating, {
    String? comment,
  }) => _map(
    'POST',
    '/api/orders/$orderId/rate',
    body: {
      'rating': rating,
      if (comment != null && comment.trim().isNotEmpty)
        'comment': comment.trim(),
    },
  );

  /// Đánh giá của đơn; `null` khi chưa đánh giá (server trả 404).
  Future<Map<String, dynamic>?> orderRating(int orderId) async {
    try {
      final res = await _map('GET', '/api/orders/$orderId/rating');
      return res.isEmpty ? null : res;
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      rethrow;
    }
  }

  Future<Map<String, dynamic>> complainOrder(
    int orderId, {
    required String description,
    String? type,
  }) => _map(
    'POST',
    '/api/orders/$orderId/complaint',
    body: {'description': description.trim(), if (type != null) 'type': type},
  );

  /// Khiếu nại của chính mình (mới nhất trước).
  Future<List<Map<String, dynamic>>> myOrderComplaints() =>
      _list('/api/orders/my-complaints');

  /// Đánh giá của chính mình (mới nhất trước).
  Future<List<Map<String, dynamic>>> myOrderRatings() =>
      _list('/api/orders/my-ratings');

  // ---- Hoàn tiền ----
  /// Các yêu cầu hoàn tiền của đơn (chỉ chủ đơn).
  Future<List<Map<String, dynamic>>> orderRefunds(int orderId) =>
      _list('/api/payments/order/$orderId/refunds');

  /// Khách gửi yêu cầu hoàn tiền. Bỏ trống [amount] thì server hoàn toàn bộ khoản
  /// đã trả; không gửi tài khoản ngân hàng thì server dùng tài khoản đã lưu
  /// (chưa lưu ⇒ `BANK_ACCOUNT_REQUIRED`). Cùng hợp đồng với
  /// `PaymentService.requestRefund` nhưng giữ nguyên mã lỗi của server để báo đúng.
  Future<Map<String, dynamic>> requestRefund(
    int orderId, {
    required String reason,
    num? amount,
  }) => _map(
    'POST',
    '/api/payments/refund-request',
    body: {
      'orderId': orderId,
      'reason': reason.trim(),
      if (amount != null && amount > 0) 'amount': amount,
    },
  );

  /// Báo hỏng ô. [attachments] = ReportAttachmentRequest[≤5] (stage REPORT),
  /// dựng bằng `PhotoPickerController.uploadAll()` / `MediaUpload.toAttachmentJson`.
  Future<Map<String, dynamic>> reportFault(
    int boxId,
    String reason, {
    List<Map<String, dynamic>>? attachments,
  }) => _map(
    'POST',
    '/api/boxes/$boxId/fault',
    body: {
      'reason': reason,
      if (attachments != null && attachments.isNotEmpty)
        'attachments': attachments,
    },
  );

  Future<Map<String, dynamic>> reportOrderFault(
    int orderId,
    String reason, {
    List<Map<String, dynamic>>? attachments,
  }) => _map(
    'POST',
    '/api/orders/$orderId/report-box-fault',
    body: {
      'reason': reason,
      if (attachments != null && attachments.isNotEmpty)
        'attachments': attachments,
    },
  );

  /// Báo sự cố cấp tủ (không gắn ô). [blocking] (chỉ LOCKER_TECHNICIAN/ADMIN)
  /// đưa cả tủ vào MAINTENANCE — ngưng nhận đơn tới khi phiếu được hoàn tất.
  Future<Map<String, dynamic>> reportLocker(
    int lockerId,
    String title,
    String description, {
    bool blocking = false,
    int? boxId,
    List<Map<String, dynamic>>? attachments,
  }) => _map(
    'POST',
    '/api/lockers/$lockerId/report',
    body: {
      'title': title,
      'description': description,
      if (boxId != null) 'boxId': boxId,
      if (attachments != null && attachments.isNotEmpty)
        'attachments': attachments,
      if (blocking) 'blocking': true,
    },
  );

  /// All fault reports the signed-in customer has filed, newest first.
  /// Mỗi phiếu có `attachments[]`, `orderId`, `orderCode`.
  Future<List<Map<String, dynamic>>> myReports() =>
      _list('/api/lockers/my-reports');

  /// Phiếu của chính khách gắn với một đơn — lọc bằng trường có cấu trúc
  /// (`GET /api/lockers/my-reports?orderId=`), không dò mã đơn trong ghi chú.
  Future<List<Map<String, dynamic>>> myReportsForOrder(int orderId) =>
      _list('/api/lockers/my-reports', query: {'orderId': orderId});

  /// Chi tiết 1 phiếu của người dùng
  Future<Map<String, dynamic>> userReport(int reportId) =>
      _map('GET', '/api/lockers/reports/$reportId');

  /// Nhật ký xử lý của KTV trên phiếu (chủ phiếu xem tiến độ) — đọc bằng token
  /// của chính khách. Danh sách rỗng = phiếu chưa có nhật ký.
  Future<List<Map<String, dynamic>>> userReportLogs(int reportId) =>
      _list('/api/lockers/reports/$reportId/logs');

  /// Ảnh của phiếu do chính khách gửi (chỉ chủ phiếu).
  Future<List<Map<String, dynamic>>> myReportAttachments(int reportId) =>
      _list('/api/lockers/reports/$reportId/attachments');

  /// Chủ phiếu bổ sung ảnh REPORT (1..5, phiếu chưa RESOLVED, ≤10 ảnh/phiếu).
  Future<List<Map<String, dynamic>>> addMyReportAttachments(
    int reportId,
    List<Map<String, dynamic>> attachments,
  ) => _postList('/api/lockers/reports/$reportId/attachments', {
    'attachments': attachments,
  });

  /// Recreate a COMPLETED/CANCELED order with the same parameters
  /// (locker, receiver, cell type/hours) and a fresh PIN/QR.
  Future<Map<String, dynamic>> reorder(int orderId) =>
      _map('POST', '/api/orders/$orderId/reorder');

  /// Simulated/real cabinet unlock: verifies [pinCode] against [boxId] then
  /// asks the IoT layer to open the door. See `IotService.unlock` backend-side.
  Future<Map<String, dynamic>> unlock(
    int lockerId,
    int boxId,
    String pinCode,
  ) => _map(
    'POST',
    '/api/iot/unlock',
    body: {'lockerId': lockerId, 'boxId': boxId, 'pinCode': pinCode},
  );

  /// Mở thử một ô bằng QR, không cần đơn (tờ "QR mở ô (thử tủ)" trên admin web). Server chỉ
  /// cho khi admin bật chế độ thử và tài khoản + tủ nằm trong danh sách; trả
  /// `{accepted, status, message}`.
  Future<Map<String, dynamic>> testOpenBox(int lockerId, int boxId) =>
      _map('POST', '/api/iot/test-open/lockers/$lockerId/boxes/$boxId');

  /// Customer feedback on a RESOLVED fault report — the other half of the
  /// claim/resolve notification loop.
  Future<Map<String, dynamic>> rateReport(
    int reportId,
    int rating,
    String? comment,
  ) => _map(
    'POST',
    '/api/lockers/reports/$reportId/rate',
    body: {'rating': rating, 'comment': comment},
  );

  Future<Map<String, dynamic>?> getReportRating(int reportId) async {
    try {
      return await _map('GET', '/api/lockers/reports/$reportId/rating');
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      rethrow;
    }
  }

  // ---- Maintenance ----
  Future<List<Map<String, dynamic>>> faults() =>
      _list('/api/locker-technician/faults');

  Future<List<Map<String, dynamic>>> reports({bool mine = false}) =>
      _list('/api/locker-technician/reports', query: {'mine': mine});

  /// Phiếu OPEN của các tủ mình phụ trách (`routedToUserId` = mình), chờ nhận.
  Future<List<Map<String, dynamic>>> routedReports() =>
      _list('/api/locker-technician/reports', query: {'routed': true});

  /// Tủ mình phụ trách (`assignedTechnicianId/Name`, `status`, `landingPad`…).
  Future<List<Map<String, dynamic>>> myLockers() =>
      _list('/api/locker-technician/lockers', query: {'mine': true});

  /// Tất cả phiếu sự cố (OPEN + IN_PROGRESS + RESOLVED) cho tab "Sự cố" của KTV.
  /// Lỗi được ném ra để màn hình báo lỗi + "Thử lại" (không đổi sang API khác).
  Future<List<Map<String, dynamic>>> allKioskReports() =>
      _list('/api/locker-technician/reports', query: {'all': true});

  // ---- Phiếu sự cố Drone (DRONE_TECHNICIAN) ----
  // Có route riêng, tuyệt đối không đi qua /api/locker-technician/** vì gateway
  // tách quyền giữa đội Drone và KTV Kiosk.
  Future<List<Map<String, dynamic>>> droneReports({
    bool mine = false,
    bool routed = false,
    bool all = false,
  }) => _list(
    '/api/drone-technician/reports',
    query: {
      if (mine) 'mine': true,
      if (routed) 'routed': true,
      if (all) 'all': true,
    },
  );

  Future<Map<String, dynamic>> claimDroneReport(int reportId) =>
      _map('PUT', '/api/drone-technician/reports/$reportId/claim');

  Future<Map<String, dynamic>> getDroneReport(int reportId) =>
      _map('GET', '/api/drone-technician/reports/$reportId');

  Future<Map<String, dynamic>> resolveDroneReport(
    int reportId, {
    String? note,
    List<Map<String, dynamic>>? attachments,
  }) {
    final trimmedNote = note?.trim();
    final hasNote = trimmedNote != null && trimmedNote.isNotEmpty;
    final hasAttachments = attachments != null && attachments.isNotEmpty;
    return _map(
      'PUT',
      '/api/drone-technician/reports/$reportId/resolve',
      body: hasNote || hasAttachments
          ? {
              if (hasNote) 'note': trimmedNote,
              if (hasAttachments) 'attachments': attachments,
            }
          : null,
    );
  }

  Future<List<Map<String, dynamic>>> droneReportAttachments(
    int reportId, {
    String? stage,
  }) => _list(
    '/api/drone-technician/reports/$reportId/attachments',
    query: stage == null ? null : {'stage': stage},
  );

  Future<List<Map<String, dynamic>>> addDroneReportAttachments(
    int reportId,
    String stage,
    List<Map<String, dynamic>> attachments, {
    String? note,
  }) => _postList('/api/drone-technician/reports/$reportId/attachments', {
    'stage': stage,
    if (note != null && note.trim().isNotEmpty) 'note': note.trim(),
    'attachments': attachments,
  });

  Future<List<Map<String, dynamic>>> droneReportLogs(int reportId) =>
      _list('/api/drone-technician/reports/$reportId/logs');

  Future<Map<String, dynamic>> addDroneReportLog(
    int reportId,
    String note, {
    List<Map<String, dynamic>>? attachments,
  }) => _map(
    'POST',
    '/api/drone-technician/reports/$reportId/logs',
    body: {
      'note': note,
      if (attachments != null && attachments.isNotEmpty)
        'attachments': attachments,
    },
  );

  /// KTV drone đang giữ phiếu xin gia hạn SLA (bắt buộc lý do; số lần và số giờ
  /// tối đa do server kiểm). Trả về phiếu sau gia hạn, kèm `slaExtensionsUsed`,
  /// `slaExtensionsMax`.
  Future<Map<String, dynamic>> extendDroneReportSla(
    int reportId, {
    required int hours,
    required String reason,
  }) => _map(
    'PUT',
    '/api/drone-technician/reports/$reportId/extend-sla',
    body: {'hours': hours, 'reason': reason.trim()},
  );

  /// KTV drone trả phiếu đang giữ về hàng chờ (OPEN, bỏ người được giao).
  Future<Map<String, dynamic>> releaseDroneReport(
    int reportId, {
    required String reason,
  }) => _map(
    'PUT',
    '/api/drone-technician/reports/$reportId/release',
    body: {'reason': reason.trim()},
  );

  /// Điểm đánh giá trung bình của KTV drone đang đăng nhập (`count`, `average`).
  Future<Map<String, dynamic>> droneMyRatingAverage() =>
      _map('GET', '/api/drone-technician/my-rating-average');

  /// Hiệu suất & chế tài SLA của KTV drone đang đăng nhập (cùng dạng bản KTV tủ).
  Future<Map<String, dynamic>> droneMyPerformance() =>
      _map('GET', '/api/drone-technician/my-performance');

  // ---- Technician Presence & Live Location (LOCKER_TECHNICIAN & DRONE_TECHNICIAN) ----

  /// Cập nhật trạng thái ca làm việc (vào ca/kết thúc ca) và tọa độ GPS của KTV.
  Future<Map<String, dynamic>> updateTechnicianPresence({
    required bool onDuty,
    double? latitude,
    double? longitude,
    double? accuracyM,
    double? headingDeg,
    double? speedMs,
    double? altitudeM,
    int? batteryLevel,
    String? deviceInfo,
  }) => _map(
    'POST',
    '/api/maintenance/technician/presence',
    body: {
      'onDuty': onDuty,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (accuracyM != null) 'accuracyM': accuracyM,
      if (headingDeg != null) 'headingDeg': headingDeg,
      if (speedMs != null) 'speedMs': speedMs,
      if (altitudeM != null) 'altitudeM': altitudeM,
      if (batteryLevel != null) 'batteryLevel': batteryLevel,
      if (deviceInfo != null) 'deviceInfo': deviceInfo,
    },
  );

  /// Lấy vị trí GPS và trạng thái ca làm việc của KTV hiện tại.
  Future<Map<String, dynamic>> getTechnicianPresence() =>
      _map('GET', '/api/maintenance/technician/presence');

  /// Danh sách KTV đang trực (on-duty) phục vụ điều phối và giám sát.
  Future<List<Map<String, dynamic>>> getActiveTechnicians({String? type}) =>
      _list('/api/maintenance/technicians/presence', query: {
        if (type != null && type.isNotEmpty) 'type': type,
      });

  Future<Map<String, dynamic>> claimReport(int reportId) =>
      _map('PUT', '/api/locker-technician/reports/$reportId/claim');

  /// 1 phiếu (LOCKER_TECHNICIAN/ADMIN), có `attachments[]`. Khách xem phiếu
  /// của mình qua [userReport].
  Future<Map<String, dynamic>> getMaintenanceReport(int reportId) =>
      _map('GET', '/api/locker-technician/reports/$reportId');

  /// KTV đang giữ phiếu trả phiếu về hàng chờ (OPEN, bỏ người được giao).
  /// [reason] bắt buộc (`REPORT_RELEASE_REASON_REQUIRED`).
  Future<Map<String, dynamic>> releaseReport(
    int reportId, {
    required String reason,
  }) => _map(
    'PUT',
    '/api/locker-technician/reports/$reportId/release',
    body: {'reason': reason.trim()},
  );

  /// KTV kiểm tra thấy không đúng như người báo mô tả: phiếu đóng ở REJECTED,
  /// [feedback] (bắt buộc — `REJECT_FEEDBACK_REQUIRED`) được gửi cho người báo,
  /// ô trở lại hoạt động và đơn có đồ trong ô lấy đồ được (bù thời gian chờ).
  Future<Map<String, dynamic>> rejectReport(
    int reportId, {
    required String feedback,
    List<Map<String, dynamic>>? attachments,
  }) => _map(
    'POST',
    '/api/locker-technician/reports/$reportId/reject',
    body: {
      'feedback': feedback.trim(),
      if (attachments != null && attachments.isNotEmpty) 'attachments': attachments,
    },
  );

  /// Hoàn tất phiếu. Ảnh [attachments] lưu stage RESOLUTION trước khi đóng.
  /// Không có [note]/[attachments] ⇒ PUT không body (như cũ).
  Future<Map<String, dynamic>> resolveReport(
    int reportId, {
    String? note,
    List<Map<String, dynamic>>? attachments,
  }) {
    final trimmedNote = note?.trim();
    final hasNote = trimmedNote != null && trimmedNote.isNotEmpty;
    final hasAttachments = attachments != null && attachments.isNotEmpty;
    return _map(
      'PUT',
      '/api/locker-technician/reports/$reportId/resolve',
      body: hasNote || hasAttachments
          ? {
              if (hasNote) 'note': trimmedNote,
              if (hasAttachments) 'attachments': attachments,
            }
          : null,
    );
  }

  /// Tra cứu đơn hàng đang giữ ô; `null` khi ô không có đơn (kể cả 404).
  /// Lỗi khác (mạng, 5xx, 403) được ném ra: nơi gọi phải báo "không tra được"
  /// thay vì coi như ô trống.
  Future<Map<String, dynamic>?> getActiveOrderByBox(int boxId) async {
    final Map<String, dynamic> res;
    try {
      res = await _map(
        'GET',
        '/api/locker-technician/boxes/$boxId/active-order',
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      rethrow;
    }
    if (res.isEmpty ||
        (res['id'] == null &&
            res['orderId'] == null &&
            res['orderCode'] == null)) {
      return null;
    }
    return res;
  }

  /// Xử lý sự cố ô tủ theo các kịch bản (RELOCATE / HANDOVER / HUB_ESCROW / QUICK_FIX / LOCK_ONLY).
  /// Lỗi server (TARGET_BOX_NOT_AVAILABLE, HANDOVER_FAILED, ORDER_RELOCATE_FAILED…)
  /// được ném nguyên vẹn cho màn hình báo đúng lý do — không có đường dự phòng.
  Future<Map<String, dynamic>> resolveBoxIncident({
    required int reportId,
    required int boxId,
    required String action,
    int? targetBoxId,
    String? reason,
    String? customerOtp,
    String? sealNumber,
    List<Map<String, dynamic>>? attachments,
    List<Map<String, dynamic>>? progressAttachments,
    bool? lockBox,
  }) => _map(
    'POST',
    '/api/locker-technician/reports/$reportId/resolve-box-incident',
    body: {
      'boxId': boxId,
      'action': action,
      if (targetBoxId != null) 'targetBoxId': targetBoxId,
      if (reason != null && reason.isNotEmpty) 'reason': reason,
      if (customerOtp != null && customerOtp.isNotEmpty)
        'customerOtp': customerOtp,
      if (sealNumber != null && sealNumber.isNotEmpty) 'sealNumber': sealNumber,
      if (attachments != null && attachments.isNotEmpty)
        'attachments': attachments,
      if (progressAttachments != null && progressAttachments.isNotEmpty)
        'progressAttachments': progressAttachments,
      if (lockBox != null) 'lockBox': lockBox,
    },
  );

  /// Ảnh của phiếu, lọc theo [stage] (REPORT/INSPECTION/PROGRESS/RESOLUTION).
  Future<List<Map<String, dynamic>>> reportAttachments(
    int reportId, {
    String? stage,
  }) => _list(
    '/api/locker-technician/reports/$reportId/attachments',
    query: stage == null ? null : {'stage': stage},
  );

  /// KTV được giao gắn ảnh INSPECTION/PROGRESS/RESOLUTION (phiếu IN_PROGRESS).
  /// Có [note] ⇒ backend tạo 1 dòng nhật ký và gắn ảnh vào đó.
  Future<List<Map<String, dynamic>>> addReportAttachments(
    int reportId,
    String stage,
    List<Map<String, dynamic>> attachments, {
    String? note,
  }) => _postList('/api/locker-technician/reports/$reportId/attachments', {
    'stage': stage,
    if (note != null && note.trim().isNotEmpty) 'note': note.trim(),
    'attachments': attachments,
  });

  Future<void> deleteReportAttachment(int reportId, int attachmentId) async {
    await _dio.delete<dynamic>(
      '/api/locker-technician/reports/$reportId/attachments/$attachmentId',
    );
  }

  Future<Map<String, dynamic>> clearFault(int boxId) =>
      _map('POST', '/api/locker-technician/boxes/$boxId/clear-fault');

  /// Ngưng dùng ô có chủ đích (bảo trì/đóng). Ô bị loại khỏi mọi reserve.
  Future<Map<String, dynamic>> outOfService(int boxId, {String? reason}) =>
      _map(
        'POST',
        '/api/locker-technician/boxes/$boxId/out-of-service',
        body: reason == null ? null : {'reason': reason},
      );

  /// Đưa ô vào trạng thái đang vệ sinh/khử khuẩn.
  Future<Map<String, dynamic>> cleaning(int boxId) =>
      _map('POST', '/api/locker-technician/boxes/$boxId/cleaning');

  /// Khôi phục ô từ OUT_OF_SERVICE/CLEANING về AVAILABLE.
  Future<Map<String, dynamic>> returnToService(int boxId) =>
      _map('POST', '/api/locker-technician/boxes/$boxId/return-to-service');

  /// Nhật ký xử lý của 1 phiếu bảo trì (work-log nhiều bước) — chỉ KTV/admin.
  /// Lỗi được ném ra để màn hình phân biệt "lỗi tải" với "chưa có nhật ký".
  Future<List<Map<String, dynamic>>> reportLogs(int reportId) =>
      _list('/api/locker-technician/reports/$reportId/logs');

  /// Dòng nhật ký; [attachments] (≤10) lưu stage PROGRESS gắn với dòng này.
  Future<Map<String, dynamic>> addReportLog(
    int reportId,
    String note, {
    List<Map<String, dynamic>>? attachments,
  }) => _map(
    'POST',
    '/api/locker-technician/reports/$reportId/logs',
    body: {
      'note': note,
      if (attachments != null && attachments.isNotEmpty)
        'attachments': attachments,
    },
  );

  /// Lịch bảo trì phòng ngừa (mỗi mục kèm cờ `due`, `checklistItems`,
  /// `lastResult`, `pendingReportId`). [mine] ⇒ chỉ lịch giao cho mình;
  /// [target] = LOCKER / DRONE lọc theo đối tượng.
  Future<List<Map<String, dynamic>>> maintenanceSchedules({
    bool mine = false,
    String? target,
  }) {
    final query = <String, dynamic>{
      if (mine) 'mine': true,
      if (target != null) 'target': target,
    };
    return _list(
      '/api/maintenance/schedules',
      query: query.isEmpty ? null : query,
    );
  }

  /// Lấy nhật ký các lần kiểm tra của lịch định kỳ (kèm checklist, ảnh, KTV thực hiện).
  Future<List<Map<String, dynamic>>> scheduleInspectionLogs(int scheduleId) =>
      _list('/api/maintenance/schedules/$scheduleId/logs');

  /// KTV đánh dấu đã kiểm tra xong 1 lịch → dời mốc đến hạn kế tiếp.
  Future<Map<String, dynamic>> completeSchedule(
    int scheduleId, {
    Map<String, dynamic>? data,
  }) => _map(
    'POST',
    '/api/maintenance/schedules/$scheduleId/complete',
    body: data,
  );

  /// Hoàn tất 1 lần kiểm tra theo checklist. [items] phải phủ đúng
  /// `checklistItems` của lịch: `{label, result: PASS|FAIL|NA, note?}`; server
  /// tự suy kết quả — có mục FAIL ⇒ FAILED: không dời hạn, tự mở phiếu giao cho
  /// mình (`pendingReportId` trong response), [faultBoxId] thì ô đó chuyển FAULT.
  /// Lịch không có checklist ⇒ [items] rỗng và gửi [status] PASSED/FAILED.
  Future<Map<String, dynamic>> completeInspection(
    int scheduleId,
    List<Map<String, dynamic>> items, {
    String? status,
    String? note,
    int? faultBoxId,
    String? faultReason,
    List<String>? photoUrls,
  }) {
    final trimmedNote = note?.trim();
    final trimmedReason = faultReason?.trim();
    return completeSchedule(
      scheduleId,
      data: {
        if (items.isNotEmpty) 'items': items else 'status': status ?? 'PASSED',
        if (trimmedNote != null && trimmedNote.isNotEmpty) 'note': trimmedNote,
        if (faultBoxId != null) 'faultBoxId': faultBoxId,
        if (trimmedReason != null && trimmedReason.isNotEmpty)
          'faultReason': trimmedReason,
        if (photoUrls != null && photoUrls.isNotEmpty) 'photoUrls': photoUrls,
      },
    );
  }

  /// Mở ô khẩn cấp không cần PIN khách — luôn được ghi vào audit log
  /// (credential MASTER) ở backend. Backend trả 200 cả khi ô chưa mở: nơi gọi
  /// phải kiểm tra [ForceOpenResult.accepted] trước khi báo thành công.
  ///
  /// App KTV luôn gửi [reason]; [note] + [attachments] (ReportAttachmentRequest
  /// từ `PhotoPickerController.uploadAll()`) + [reportId] ⇒ backend ghi thêm một
  /// dòng nhật ký vào phiếu đó. Backend cũ bỏ qua body.
  Future<ForceOpenResult> forceOpenBox(
    int boxId, {
    String? reason,
    String? note,
    List<Map<String, dynamic>>? attachments,
    int? reportId,
  }) async => ForceOpenResult.fromResponse(
    await _map(
      'POST',
      '/api/locker-technician/boxes/$boxId/force-open',
      body: forceOpenBody(
        reason: reason,
        note: note,
        attachments: attachments,
        reportId: reportId,
      ),
    ),
  );

  /// Body của [forceOpenBox]; `null` khi không có gì để gửi (giữ tương thích
  /// với web admin không gửi body).
  static Map<String, dynamic>? forceOpenBody({
    String? reason,
    String? note,
    List<Map<String, dynamic>>? attachments,
    int? reportId,
  }) {
    final r = reason?.trim();
    final n = note?.trim();
    final body = <String, dynamic>{
      if (r != null && r.isNotEmpty) 'reason': r,
      if (n != null && n.isNotEmpty) 'note': n,
      if (attachments != null && attachments.isNotEmpty)
        'attachments': attachments,
      if (reportId != null) 'reportId': reportId,
    };
    return body.isEmpty ? null : body;
  }

  /// Điểm đánh giá trung bình KTV nhận được từ các phiếu mình xử lý
  /// (`{count, average}`). [drone] ⇒ endpoint của KTV drone.
  Future<Map<String, dynamic>> myRatingAverage({bool drone = false}) => _map(
    'GET',
    drone
        ? '/api/drone-technician/my-rating-average'
        : '/api/locker-technician/my-rating-average',
  );

  /// Thống kê hiệu suất & trạng thái chế tài SLA của chính KTV đang đăng nhập
  /// (`totalAssigned, inProgress, resolved, overdue, penaltyLevel, penaltyReason,
  /// ratingCount, averageRating`). [drone] ⇒ endpoint của KTV drone.
  Future<Map<String, dynamic>> myPerformance({bool drone = false}) => _map(
    'GET',
    drone
        ? '/api/drone-technician/my-performance'
        : '/api/locker-technician/my-performance',
  );

  /// KTV đang được giao phiếu tự gia hạn SLA: body `{hours, reason}`; server
  /// giới hạn số lần / số giờ (SLA_EXTENSION_*), trả phiếu sau gia hạn kèm
  /// `slaExtensionsUsed` / `slaExtensionsMax`. Không có đường dự phòng.
  Future<Map<String, dynamic>> extendReportSla(
    int reportId, {
    required int hours,
    required String reason,
  }) => _map(
    'PUT',
    '/api/locker-technician/reports/$reportId/extend-sla',
    body: extendSlaBody(hours: hours, reason: reason),
  );

  /// Cấu hình công khai scope locker (`GET /api/settings/locker/public`) — đọc
  /// giới hạn tự gia hạn SLA (`app.maintenance.sla-max-extensions`,
  /// `app.maintenance.sla-max-hours-per-extension`).
  Future<Map<String, dynamic>> lockerPublicSettings() =>
      _map('GET', '/api/settings/locker/public');

  /// Body gia hạn SLA. Gửi kèm `extensionHours` (cùng giá trị) để máy chủ chưa
  /// cập nhật — vốn chỉ đọc tên trường cũ — vẫn hiểu đúng số giờ.
  static Map<String, dynamic> extendSlaBody({
    required int hours,
    required String reason,
  }) => {'hours': hours, 'extensionHours': hours, 'reason': reason.trim()};

  /// Box-health cho bảo trì: trạng thái logic (theo đơn) đặt cạnh trạng thái
  /// phần cứng cửa cabinet báo lên (GAP 2). Mỗi phần tử:
  /// `{boxId, boxNumber, cellType, logicalStatus, hwState, lastReportedAt,
  /// doorOpen, needsAttention}`. `needsAttention` = cửa đang mở nhưng ô không
  /// `OCCUPIED` (nghi cửa kẹt/quên đóng).
  Future<List<Map<String, dynamic>>> boxHealth(int lockerId) =>
      _list('/api/locker-technician/lockers/$lockerId/box-health');

  /// Tổng quan ca trực: mọi ô trên TẤT CẢ tủ đang có cửa phần cứng MỞ nhưng
  /// không `OCCUPIED` (nghi cửa kẹt/quên đóng). Mỗi phần tử kèm metadata locker
  /// (`lockerName/lockerAddress/lockerLatitude/lockerLongitude` để chỉ đường) +
  /// `boxId/boxNumber/cellType/logicalStatus/hwState/lastReportedAt`.
  Future<List<Map<String, dynamic>>> boxAnomalies() =>
      _list('/api/locker-technician/box-anomalies');

  // ---- Drone fleet (maintenance) ----
  // Pin/trạng thái bay hiện chưa có telemetry thật, KTV nhập tay qua các
  // endpoint dưới đây (xem locker-service V10__drone_units.sql).

  /// Danh sách toàn bộ drone (thiết bị bay vật lý, khác ô tủ cellType=DRONE).
  Future<List<Map<String, dynamic>>> droneUnits() =>
      _list('/api/drone-technician/drones');

  /// KTV nhận phụ trách một drone.
  Future<Map<String, dynamic>> claimDrone(int id) =>
      _map('POST', '/api/drone-technician/drones/$id/claim');

  /// KTV nhả quyền phụ trách một drone (bàn giao ca).
  Future<Map<String, dynamic>> releaseDrone(int id) =>
      _map('POST', '/api/drone-technician/drones/$id/release');

  /// Đổi trạng thái drone (IDLE/CHARGING/IN_FLIGHT/MAINTENANCE/FAULT).
  /// [reason] bắt buộc khi chuyển sang FAULT.
  Future<Map<String, dynamic>> updateDroneStatus(
    int id,
    String status, {
    String? reason,
  }) => _map(
    'POST',
    '/api/drone-technician/drones/$id/status',
    body: {'status': status, if (reason != null) 'reason': reason},
  );

  /// Cập nhật % pin hiện tại của drone (nhập tay).
  Future<Map<String, dynamic>> updateDroneBattery(int id, int batteryPercent) =>
      _map(
        'POST',
        '/api/drone-technician/drones/$id/battery',
        body: {'batteryPercent': batteryPercent},
      );

  /// Nhật ký bảo trì của một drone.
  Future<List<Map<String, dynamic>>> droneLogs(int id) =>
      _list('/api/drone-technician/drones/$id/logs');

  Future<Map<String, dynamic>> addDroneLog(int id, String note) => _map(
    'POST',
    '/api/drone-technician/drones/$id/logs',
    body: {'note': note},
  );

  /// Hàng đợi order-based cho đội bay theo Phase 2.
  Future<List<Map<String, dynamic>>> droneOrderQueue({String? deliveryStage}) =>
      _list(
        '/api/drone-technician/drone-orders',
        query: deliveryStage == null ? null : {'deliveryStage': deliveryStage},
      );

  Future<Map<String, dynamic>> droneOrderDetail(int orderId) =>
      _map('GET', '/api/drone-technician/drone-orders/$orderId');

  /// Thời tiết dọc tuyến bay của một đơn — cùng nguồn với kiểm tra lúc đặt
  /// đơn / phóng drone. KTV dùng đường của đội bay, khách dùng đường của đơn.
  Future<Map<String, dynamic>> droneRouteWeather(
    int orderId, {
    bool asTechnician = false,
  }) => _map(
    'GET',
    asTechnician
        ? '/api/drone-technician/drone-orders/$orderId/weather'
        : '/api/orders/$orderId/drone-delivery/weather',
  );

  /// Thời tiết tại từng tủ có bãi đáp drone (KTV điều phối).
  Future<List<Map<String, dynamic>>> droneLockerWeather() =>
      _list('/api/drone-technician/drone-orders/weather/lockers');

  /// Metadata camera/telemetry có kiểm soát quyền cho Journey Detail.
  Future<Map<String, dynamic>> droneOrderCamera(int orderId) =>
      _map('GET', '/api/drone-technician/drone-orders/$orderId/camera');

  /// Báo rơi kiện; idempotency key ngăn bấm lặp tạo nhiều incident/ticket.
  Future<Map<String, dynamic>> reportDroppedParcel(
    int orderId, {
    required String idempotencyKey,
    required String reason,
    double? latitude,
    double? longitude,
    double? gpsAccuracyM,
    String? cameraStatus,
    Map<String, dynamic>? cameraSnapshot,
    String? snapshotCapturedAt,
  }) => _map(
    'POST',
    '/api/drone-technician/drone-orders/$orderId/drop-incident',
    headers: {'Idempotency-Key': idempotencyKey},
    body: {
      'reason': reason.trim(),
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (gpsAccuracyM != null) 'gpsAccuracyM': gpsAccuracyM,
      'cameraStatus': cameraStatus ?? 'UNAVAILABLE',
      if (cameraSnapshot != null) 'cameraSnapshot': cameraSnapshot,
      if (snapshotCapturedAt != null) 'snapshotCapturedAt': snapshotCapturedAt,
    },
  );

  /// Sự cố rơi kiện liên quan tới KTV drone (mình báo hoặc được giao thu hồi).
  Future<List<Map<String, dynamic>>> droneIncidents() =>
      _list('/api/drone-technician/drone-incidents');

  Future<Map<String, dynamic>> droneIncident(int incidentId) =>
      _map('GET', '/api/drone-technician/drone-incidents/$incidentId');

  // ---- Thu hồi kiện rơi (LOCKER_TECHNICIAN) ----
  // Không còn dữ liệu mẫu: trước đây API lỗi hoặc rỗng thì app hiện nhiệm vụ giả INC-2026-DROP-001 và các nút
  // thao tác sửa nó trong bộ nhớ — API hỏng trông như chạy (test 2026-10-29). Lỗi phải hiện lỗi, rỗng là rỗng.
  Future<List<Map<String, dynamic>>> droneRecoveries() =>
      _list('/api/locker-technician/drone-recoveries');

  Future<Map<String, dynamic>> droneRecovery(int incidentId) =>
      _map('GET', '/api/locker-technician/drone-recoveries/$incidentId');

  Future<Map<String, dynamic>> updateDroneRecovery(
    int incidentId,
    String action,
  ) => _map(
    'POST',
    '/api/locker-technician/drone-recoveries/$incidentId/actions',
    body: {'action': action},
  );

  Future<Map<String, dynamic>> submitDroneRecovery(
    int incidentId, {
    required String outcome,
    String? parcelCondition,
    String? note,
    double? latitude,
    double? longitude,
    double? gpsAccuracyM,
    required List<Map<String, dynamic>> evidence,
  }) => _map(
    'POST',
    '/api/locker-technician/drone-recoveries/$incidentId/submit',
    body: {
      'outcome': outcome,
      if (parcelCondition != null) 'parcelCondition': parcelCondition,
      if (note != null && note.trim().isNotEmpty) 'note': note.trim(),
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (gpsAccuracyM != null) 'gpsAccuracyM': gpsAccuracyM,
      'evidence': evidence,
    },
  );

  Future<Map<String, dynamic>> confirmDroneRecoveryHubHandover(
    int incidentId,
  ) => _map(
    'POST',
    '/api/locker-technician/drone-recoveries/$incidentId/hub-handover',
  );

  // ---- Khách hàng theo dõi sự cố và phản hồi phương án ----
  Future<List<Map<String, dynamic>>> myDroneIncidents() =>
      _list('/api/orders/drone-incidents');

  Future<Map<String, dynamic>> respondDroneIncident(
    int incidentId, {
    required String decision,
    String? note,
  }) => _map(
    'POST',
    '/api/orders/drone-incidents/$incidentId/response',
    body: {
      'decision': decision,
      if (note != null && note.trim().isNotEmpty) 'note': note.trim(),
    },
  );

  /// Đội bay tiếp nhận một order drone và gán drone cho mission.
  Future<Map<String, dynamic>> acceptDroneOrder(
    int orderId, {
    required int droneUnitId,
    required String idempotencyKey,
  }) => _map(
    'POST',
    '/api/drone-technician/drone-orders/$orderId/accept',
    headers: {'Idempotency-Key': idempotencyKey},
    body: {'droneUnitId': droneUnitId},
  );

  /// Xác nhận kiện đã được cân, đối chiếu, cố định và khóa khoang hàng.
  Future<Map<String, dynamic>> confirmDroneLoading(
    int orderId, {
    required int payloadWeightGrams,

    /// Bỏ trống thì server tự sinh mã niêm phong.
    String? sealCode,
    required bool parcelMatched,
    required bool payloadSecured,
    required bool compartmentLocked,
    String? note,
    required String idempotencyKey,
  }) => _map(
    'POST',
    '/api/drone-technician/drone-orders/$orderId/loading-confirmation',
    headers: {'Idempotency-Key': idempotencyKey},
    body: {
      'payloadWeightGrams': payloadWeightGrams,
      if (sealCode != null && sealCode.trim().isNotEmpty)
        'sealCode': sealCode.trim(),
      'parcelMatched': parcelMatched,
      'payloadSecured': payloadSecured,
      'compartmentLocked': compartmentLocked,
      if (note != null && note.trim().isNotEmpty) 'note': note.trim(),
    },
  );

  /// Đội bay phát lệnh launch cho mission đã sẵn sàng.
  Future<Map<String, dynamic>> launchDroneOrder(
    int orderId, {
    required String idempotencyKey,
  }) => _map(
    'POST',
    '/api/drone-technician/drone-orders/$orderId/launch',
    headers: {'Idempotency-Key': idempotencyKey},
  );

  /// Đơn drone thật (STANDARD): điều phối viên xác nhận drone sang chặng kế tiếp.
  /// [expectedStage] = chặng app đang hiển thị; server đã ở chặng khác thì trả
  /// 409 `DRONE_STAGE_CHANGED` thay vì nhảy thêm một chặng.
  /// Trả về chi tiết nhiệm vụ sau khi đổi chặng.
  Future<Map<String, dynamic>> advanceDroneOrder(
    int orderId, {
    String? expectedStage,
  }) => _map(
    'POST',
    '/api/drone-technician/drone-orders/$orderId/advance',
    body: expectedStage == null || expectedStage.isEmpty
        ? null
        : {'expectedStage': expectedStage},
  );

  Future<Map<String, dynamic>> cancelDroneOrder(
    int orderId, {
    required int reasonCode,
    String? note,
  }) => _map(
    'POST',
    '/api/drone-technician/drone-orders/$orderId/cancel',
    body: {
      'reasonCode': reasonCode,
      if (note != null && note.trim().isNotEmpty) 'note': note.trim(),
    },
  );

  /// Chuyến bay không giao được hàng sau khi đã phóng: đơn đóng lại, ô nhận được
  /// nhả, drone chuyển FAULT và khách được tạo yêu cầu hoàn tiền. Cùng bảng lý do
  /// với [cancelDroneOrder].
  Future<Map<String, dynamic>> failDroneOrder(
    int orderId, {

    /// Mã trong `DroneFailureReasons` của backend; null = lấy lý do đơn đang bị chặn.
    String? reason,
    String? note,
  }) => _map(
    'POST',
    '/api/drone-technician/drone-orders/$orderId/fail',
    body: {
      if (reason != null) 'reason': reason,
      if (note != null && note.trim().isNotEmpty) 'note': note.trim(),
    },
  );

  // ---- Lấy hàng tận nhà (KTV drone) ----

  /// KTV drone đang trong ca không, vị trí gần nhất và có đang bận không.
  Future<Map<String, dynamic>> droneTechnicianPresence() =>
      _map('GET', '/api/drone-technician/drone-orders/presence');

  /// Vào/ra ca và gửi vị trí; trường null thì giữ nguyên.
  Future<Map<String, dynamic>> updateDroneTechnicianPresence({
    bool? onDuty,
    double? latitude,
    double? longitude,
  }) => _map(
    'PUT',
    '/api/drone-technician/drone-orders/presence',
    body: {
      if (onDuty != null) 'onDuty': onDuty,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
    },
  );

  Future<Map<String, dynamic>> acceptDronePickup(int orderId) =>
      _map('POST', '/api/drone-technician/drone-orders/$orderId/pickup/accept');

  Future<Map<String, dynamic>> declineDronePickup(int orderId) => _map(
    'POST',
    '/api/drone-technician/drone-orders/$orderId/pickup/decline',
  );

  /// Đã cầm kiện tại nhà người gửi: [pickupCode] do người gửi đọc.
  Future<Map<String, dynamic>> confirmDronePickup(
    int orderId, {
    required String pickupCode,
    required Map<String, dynamic> pickupPhoto,
    String? note,
  }) => _map(
    'POST',
    '/api/drone-technician/drone-orders/$orderId/pickup/confirm',
    body: {
      'pickupCode': pickupCode.trim(),
      'parcelMatched': true,
      'pickupPhoto': pickupPhoto,
      if (note != null && note.trim().isNotEmpty) 'note': note.trim(),
    },
  );

  /// Tới nơi nhưng không lấy được kiện ⇒ đơn giao không hoàn tất, hoàn tiền.
  Future<Map<String, dynamic>> failDronePickup(
    int orderId, {
    required String reason,
    String? note,
  }) => _map(
    'POST',
    '/api/drone-technician/drone-orders/$orderId/pickup/fail',
    body: {
      'reason': reason,
      if (note != null && note.trim().isNotEmpty) 'note': note.trim(),
    },
  );

  /// Drone đã gán gặp sự cố trước khi phóng: đổi sang drone rảnh khác ở tủ gửi.
  Future<Map<String, dynamic>> changeDroneOfOrder(
    int orderId, {
    required int droneUnitId,
  }) => _map(
    'POST',
    '/api/drone-technician/drone-orders/$orderId/change-drone',
    body: {'droneUnitId': droneUnitId},
  );

  /// Đơn drone đang bị một phiếu sự cố chặn hoặc đã kết thúc vì phiếu đó.
  Future<List<Map<String, dynamic>>> droneOrdersByTicket(
    int ticketId, {
    bool lockerTechnician = false,
  }) => _list(
    '/api/${lockerTechnician ? 'locker-technician' : 'drone-technician'}'
    '/drone-orders/by-ticket/$ticketId',
  );

  /// Người gửi xác nhận đã bỏ kiện vào ô drone ở tủ gửi — đội bay chỉ tiếp nhận
  /// được đơn đã có mốc này.
  Future<Map<String, dynamic>> confirmDroneParcelDrop(int orderId) =>
      _map('POST', '/api/orders/$orderId/drone-delivery/drop-confirmation');

  /// Khách từ chối trả phụ thu cân lệch: đơn huỷ, phần đã trả được hoàn, đội bay
  /// trả lại kiện.
  Future<Map<String, dynamic>> declineDroneSurcharge(int orderId) =>
      _map('POST', '/api/orders/$orderId/drone-delivery/decline-surcharge');

  /// Đội bay xác nhận đã trả kiện của một đơn không giao được cho người gửi.
  Future<Map<String, dynamic>> confirmDroneParcelReturn(
    int orderId, {
    String? note,
  }) => _map(
    'POST',
    '/api/drone-technician/drone-orders/$orderId/parcel-return',
    body: {if (note != null && note.trim().isNotEmpty) 'note': note.trim()},
  );

  /// Đội bay điều phối yêu cầu; gán [droneUnitId] thì drone đó chuyển IN_FLIGHT.
  Future<Map<String, dynamic>> dispatchDroneDelivery(
    int id, {
    int? droneUnitId,
  }) => _map(
    'POST',
    '/api/drone-technician/drone-deliveries/$id/dispatch',
    body: droneUnitId == null ? null : {'droneUnitId': droneUnitId},
  );

  /// Drone đã thả hàng xong — yêu cầu DELIVERED, drone quay về IDLE.
  Future<Map<String, dynamic>> completeDroneDelivery(int id) =>
      _map('POST', '/api/drone-technician/drone-deliveries/$id/complete');

  /// #6 KTV cập nhật trạng thái bảo trì bãi đáp drone của 1 tủ; trả về layout tủ.
  /// [status] = OK / FAULT / MAINTENANCE. Khác OK ⇒ server mở 1 phiếu
  /// LANDING_PAD (KTV tủ tự báo thì tự nhận). Về OK khi phiếu đó còn mở ⇒ server
  /// hoàn tất phiếu (chỉ người được giao, áp luật ảnh nghiệm thu).
  Future<Map<String, dynamic>> updateLandingPadStatus(
    int lockerId,
    String status, {
    String? reason,
  }) => _map(
    'POST',
    '/api/locker-technician/lockers/$lockerId/landing-pad',
    body: {'status': status, if (reason != null) 'reason': reason},
  );

  // ── LOCKER_TECHNICIAN ──────────────────────────────────────────────────────

  /// Danh sách thiết bị IoT mà LOCKER_TECHNICIAN phụ trách.
  Future<List<Map<String, dynamic>>> techDevices() =>
      _list('/api/locker-technician/devices');

  /// Chi tiết một thiết bị IoT theo ID.
  Future<Map<String, dynamic>> techDeviceDetail(int id) =>
      _map('GET', '/api/locker-technician/devices/$id');

  /// Đánh dấu tay thiết bị OFFLINE / ERROR (vd. đã rút điện trước khi hết cửa
  /// sổ online). ONLINE do server tự tính theo `lastSeenAt`, không đặt tay.
  Future<void> techUpdateStatus(int id, String status) async {
    await _map(
      'PUT',
      '/api/locker-technician/devices/$id/status',
      body: {'status': status},
    );
  }

  /// Nhật ký audit của một thiết bị IoT.
  Future<List<Map<String, dynamic>>> techDeviceLogs(int id) =>
      _list('/api/locker-technician/devices/$id/logs');

  /// Khởi động lại bộ điều khiển tủ và chờ tủ trả lời. Backend trả 200 cho cả
  /// ACCEPTED / TIMEOUT / FAILED: nơi gọi phải đọc [DeviceRestartResult].
  Future<DeviceRestartResult> techRestartDevice(int id) async =>
      DeviceRestartResult.fromResponse(
        await _map('POST', '/api/locker-technician/devices/$id/restart'),
      );

  /// Mã lỗi nghiệp vụ (`code` của ApiResponse lỗi), ví dụ `REPORT_OPEN`.
  static String? errorCode(Object error) {
    if (error is! DioException) return null;
    final data = error.response?.data;
    final code = data is Map ? data['code'] : null;
    return code?.toString();
  }

  /// Endpoint chưa có trên máy chủ đang chạy (backend chưa deploy bản mới):
  /// 404/405/501 mà không kèm mã nghiệp vụ (gateway / Spring trả trang lỗi mặc
  /// định). 404 nghiệp vụ (`NOT_FOUND`, `ORDER_NOT_FOUND`…) luôn có `code`.
  static bool isEndpointUnavailable(Object error) {
    if (error is! DioException) return false;
    final status = error.response?.statusCode;
    if (status != 404 && status != 405 && status != 501) return false;
    final code = errorCode(error);
    return code == null || code.isEmpty;
  }

  /// Các mã lỗi mà server trả `message` tiếng Anh — hiển thị bản tiếng Việt.
  static Map<String, String> get _codeMessages => <String, String>{
    'BLE_TEST_NOT_GRANTED':
        L10n.current.apiErrBleTestNotGranted,
    'RESOLUTION_PHOTO_REQUIRED':
        L10n.current.apiErrResolutionPhotoRequired,
    'LANDING_PAD_ABSENT': L10n.current.apiErrLandingPadAbsent,
    'LANDING_PAD_STATUS_INVALID': L10n.current.apiErrLandingPadStatusInvalid,
    'REPORT_NOT_CLAIMABLE': L10n.current.apiErrReportNotClaimable,
    // ── Luồng giao drone (order-service / locker-service) ──
    'DRONE_ROUTE_REQUIRED': L10n.current.apiErrDroneRouteRequired,
    'DRONE_ROUTE_INVALID': L10n.current.apiErrDroneRouteInvalid,
    'DRONE_ROUTE_TOO_FAR':
        L10n.current.apiErrDroneRouteTooFar,
    'DRONE_ROUTE_TOO_SHORT':
        L10n.current.apiErrDroneRouteTooShort,
    'DRONE_PICKUP_OUT_OF_RANGE':
        L10n.current.apiErrDronePickupOutOfRange,
    'DRONE_NO_SOURCE_LOCKER':
        L10n.current.apiErrDroneNoSourceLocker,
    'DRONE_LOCKER_LOCATION_MISSING':
        L10n.current.apiErrDroneLockerLocationMissing,
    'DRONE_PICKUP_ADDRESS_REQUIRED': L10n.current.apiErrDronePickupAddressRequired,
    'DRONE_PICKUP_LOCATION_REQUIRED': L10n.current.apiErrDronePickupLocationRequired,
    'DRONE_SENDER_NAME_REQUIRED': L10n.current.apiErrDroneSenderNameRequired,
    'DRONE_SENDER_PHONE_INVALID': L10n.current.apiErrDroneSenderPhoneInvalid,
    'DRONE_SENDER_EMAIL_INVALID': L10n.current.apiErrDroneSenderEmailInvalid,
    'DRONE_RECEIVER_NAME_REQUIRED': L10n.current.apiErrDroneReceiverNameRequired,
    'DRONE_RECEIVER_EMAIL_INVALID': L10n.current.apiErrDroneReceiverEmailInvalid,
    'DRONE_PARCEL_CATEGORY_REQUIRED': L10n.current.apiErrDroneParcelCategoryRequired,
    'DRONE_PICKUP_NOT_OFFERED': L10n.current.apiErrDronePickupNotOffered,
    'DRONE_PICKUP_OFFER_EXPIRED': L10n.current.apiErrDronePickupOfferExpired,
    'DRONE_PICKUP_NOT_ASSIGNED_TO_USER':
        L10n.current.apiErrDronePickupNotAssignedToUser,
    'DRONE_PICKUP_NOT_FOUND':
        L10n.current.apiErrDronePickupNotFound,
    'DRONE_PICKUP_CODE_INVALID':
        L10n.current.apiErrDronePickupCodeInvalid,
    'DRONE_PICKUP_PARCEL_NOT_VERIFIED':
        L10n.current.apiErrDronePickupParcelNotVerified,
    'DRONE_PARCEL_NOT_PICKED_UP': L10n.current.apiErrDroneParcelNotPickedUp,
    'DRONE_ORDER_BLOCKED':
        L10n.current.apiErrDroneOrderBlocked,
    'DRONE_TECHNICIAN_LOCATION_REQUIRED':
        L10n.current.apiErrDroneTechnicianLocationRequired,
    'DRONE_TECHNICIAN_HAS_ACTIVE_PICKUP':
        L10n.current.apiErrDroneTechnicianHasActivePickup,
    'DRONE_TECHNICIAN_OFF_DUTY': L10n.current.apiErrDroneTechnicianOffDuty,
    'DRONE_TECHNICIAN_BUSY': L10n.current.apiErrDroneTechnicianBusy,
    'DRONE_FAILURE_REASON_INVALID': L10n.current.apiErrDroneFailureReasonInvalid,
    'DRONE_UNCHANGED': L10n.current.apiErrDroneUnchanged,
    'DRONE_FLIGHTS_SUSPENDED':
        L10n.current.apiErrDroneFlightsSuspended,
    'DRONE_OUTSIDE_FLIGHT_HOURS': L10n.current.apiErrDroneOutsideFlightHours,
    'DRONE_OPEN_ORDER_LIMIT':
        L10n.current.apiErrDroneOpenOrderLimit,
    'DRONE_PROHIBITED_ITEMS_NOT_DECLARED':
        L10n.current.apiErrDroneProhibitedItemsNotDeclared,
    'DRONE_PARCEL_SIZE_INVALID':
        L10n.current.apiErrDroneParcelSizeInvalid,
    'DRONE_PARCEL_TOO_LARGE': L10n.current.apiErrDroneParcelTooLarge,
    'DRONE_PARCEL_CATEGORY_INVALID': L10n.current.apiErrDroneParcelCategoryInvalid,
    'DRONE_DECLARED_VALUE_TOO_HIGH':
        L10n.current.apiErrDroneDeclaredValueTooHigh,
    'DRONE_PARCEL_NOT_DROPPED':
        L10n.current.apiErrDroneParcelNotDropped,
    'DRONE_PARCEL_RETURN_NOT_PENDING': L10n.current.apiErrDroneParcelReturnNotPending,
    'DRONE_BATTERY_UNKNOWN':
        L10n.current.apiErrDroneBatteryUnknown,
    'DRONE_SURCHARGE_NOT_OWED': L10n.current.apiErrDroneSurchargeNotOwed,
    'DRONE_SOURCE_NOT_FOUND': L10n.current.apiErrDroneSourceNotFound,
    'DRONE_DESTINATION_NOT_FOUND': L10n.current.apiErrDroneDestinationNotFound,
    'DRONE_LOCKER_INACTIVE': L10n.current.apiErrDroneLockerInactive,
    'DRONE_SOURCE_CELL_UNAVAILABLE':
        L10n.current.apiErrDroneSourceCellUnavailable,
    'DRONE_SOURCE_CELL_MISMATCH': L10n.current.apiErrDroneSourceCellMismatch,
    'DRONE_CELL_REQUIRED': L10n.current.apiErrDroneCellRequired,
    'BOX_NOT_AVAILABLE': L10n.current.apiErrBoxNotAvailable,
    'DRONE_DEMO_NOT_ALLOWED': L10n.current.apiErrDroneDemoNotAllowed,
    'DRONE_ORDER_UNPAID': L10n.current.apiErrDroneOrderUnpaid,
    'DRONE_ORDER_STATUS_INVALID': L10n.current.apiErrDroneOrderStatusInvalid,
    'DRONE_MISSION_ALREADY_EXISTS': L10n.current.apiErrDroneMissionAlreadyExists,
    'DRONE_MISSION_STATUS_INVALID':
        L10n.current.apiErrDroneMissionStatusInvalid,
    'DRONE_MISSION_NOT_ASSIGNED_TO_USER':
        L10n.current.apiErrDroneMissionNotAssignedToUser,
    'DRONE_WRONG_SOURCE_LOCKER': L10n.current.apiErrDroneWrongSourceLocker,
    'DRONE_INACTIVE': L10n.current.apiErrDroneInactive,
    'DRONE_NOT_IDLE': L10n.current.apiErrDroneNotIdle,
    'DRONE_BATTERY_TOO_LOW': L10n.current.apiErrDroneBatteryTooLow,
    'DRONE_STATUS_CONFLICT':
        L10n.current.apiErrDroneStatusConflict,
    'DRONE_RESERVATION_LOST':
        L10n.current.apiErrDroneReservationLost,
    'DRONE_PAYLOAD_TOO_HEAVY': L10n.current.apiErrDronePayloadTooHeavy,
    'DRONE_LOADING_NOT_CONFIRMED': L10n.current.apiErrDroneLoadingNotConfirmed,
    'DRONE_SURCHARGE_UNPAID':
        L10n.current.apiErrDroneSurchargeUnpaid,
    'DRONE_PARCEL_WEIGHT_INVALID': L10n.current.apiErrDroneParcelWeightInvalid,
    'DRONE_ALREADY_IN_FLIGHT': L10n.current.apiErrDroneAlreadyInFlight,
    'DRONE_CANCEL_NOTE_REQUIRED': L10n.current.apiErrDroneCancelNoteRequired,
    'DRONE_STAGE_AUTOMATED':
        L10n.current.apiErrDroneStageAutomated,
    'DRONE_RECEIVER_PHONE_INVALID': L10n.current.apiErrDroneReceiverPhoneInvalid,
    'LOCKER_INACTIVE': L10n.current.apiErrLockerInactive,
    'LANDING_PAD_UNAVAILABLE': L10n.current.apiErrLandingPadUnavailable,
    'DRONE_OWNERSHIP_REQUIRED': L10n.current.apiErrDroneOwnershipRequired,
    'DRONE_ALREADY_ASSIGNED': L10n.current.apiErrDroneAlreadyAssigned,
    'DRONE_ACTIVE_MISSION': L10n.current.apiErrDroneActiveMission,
    'DRONE_FAULT_REASON_REQUIRED': L10n.current.apiErrDroneFaultReasonRequired,
    'DRONE_PAYMENT_REQUIRED_BEFORE_PICKUP':
        L10n.current.apiErrDronePaymentRequiredBeforePickup,
    // ── Đơn của khách (order-service) ──
    'ORDER_STATUS_INVALID': L10n.current.apiErrOrderStatusInvalid,
    // ── Thanh toán: MoMo/VNPay đã bỏ ──
    PaymentMethods.unsupportedErrorCode: PaymentMethods.unsupportedMessage,
  };

  // ── Mã lỗi luồng KTV tủ ──
  /// Mã mà `message` server là tiếng Anh / lẫn chi tiết kỹ thuật ⇒ luôn thay
  /// bằng câu tiếng Việt cố định.
  static const _technicianCodeMessages = <String, String>{
    'HANDOVER_FAILED':
        'Bàn giao trực tiếp thất bại — kiểm tra lại mã PIN 6 số hoặc mã QR của đơn rồi thử lại.',
    'INVALID_OTP': 'Mã PIN/QR của đơn không đúng.',
    'ORDER_RELOCATE_FAILED':
        'Không chuyển được đơn sang ô mới. Hàng vẫn ở ô cũ — thử lại hoặc chọn phương án khác.',
    'VALIDATION_ERROR': 'Dữ liệu gửi lên không hợp lệ, vui lòng kiểm tra lại.',
    'INTERNAL_ERROR':
        'Máy chủ gặp lỗi hoặc chưa hỗ trợ thao tác này. Vui lòng thử lại sau.',
    'NOT_FOUND': 'Không tìm thấy dữ liệu (có thể đã bị xoá hoặc thay đổi).',
  };

  /// Mã mà server đã kèm câu tiếng Việt có số liệu cụ thể (giới hạn, số phiếu…)
  /// ⇒ ưu tiên câu của server, chỉ dùng câu dưới đây khi server không gửi.
  static const _technicianCodeFallbacks = <String, String>{
    'SLA_EXTENSION_NOT_ASSIGNEE':
        'Chỉ KTV đang được giao phiếu mới gia hạn được SLA.',
    'SLA_EXTENSION_LIMIT_REACHED':
        'Phiếu đã hết lượt tự gia hạn SLA — liên hệ admin nếu cần thêm thời gian.',
    'SLA_EXTENSION_HOURS_EXCEEDED': 'Số giờ gia hạn vượt mức cho phép mỗi lần.',
    'SLA_EXTENSION_REASON_REQUIRED': 'Cần nêu lý do gia hạn SLA.',
    'INVALID_EXTENSION_HOURS': 'Thời gian gia hạn phải từ 1 giờ trở lên.',
    'TECHNICIAN_SLA_RESTRICTED':
        'Bạn đang có quá nhiều phiếu trễ hạn SLA nên tạm thời không nhận được việc mới.',
    'REPORT_RELEASE_REASON_REQUIRED': 'Cần nêu lý do trả phiếu về hàng chờ.',
    'REPORT_NOT_CLAIMED': 'Phiếu đang ở hàng chờ, chưa có KTV nhận.',
    'REPORT_ALREADY_RESOLVED': 'Phiếu đã được hoàn tất.',
    'REPORT_OPEN':
        'Ô/bãi đáp đang có phiếu sự cố mở — hoàn tất phiếu đó trước.',
    'TARGET_BOX_REQUIRED': 'Cần chọn ô trống đích để điều chuyển hàng.',
    'TARGET_BOX_NOT_AVAILABLE':
        'Ô đích không còn trống — tải lại sơ đồ và chọn ô khác.',
    'BOX_NOT_FAULT': 'Ô không còn ở trạng thái lỗi.',
    'HANDOVER_OTP_REQUIRED': 'Cần mã PIN 6 số hoặc mã QR của đơn để bàn giao.',
    'HANDOVER_OTP_UNAVAILABLE':
        'Đơn chưa có mã lấy hàng nên chưa bàn giao trực tiếp được.',
    'SEAL_NUMBER_REQUIRED': 'Nhập mã Seal in trên túi niêm phong.',
    'INCIDENT_ACTION_INVALID': 'Phương án xử lý không hợp lệ.',
    'INCIDENT_BOX_NOT_IN_LOCKER': 'Ô đã chọn không thuộc tủ của phiếu.',
    'FORCE_OPEN_REPORT_REQUIRED':
        'Ảnh khi mở khẩn cấp chỉ lưu được khi mở từ một phiếu sự cố.',
    'FORCE_OPEN_REPORT_MISMATCH': 'Phiếu sự cố không thuộc tủ của ô này.',
    'DRONE_REPORT_REQUIRED': 'Phiếu này không phải phiếu drone.',
    'DEVICE_NOT_PAIRED': 'Thiết bị chưa được gắn với tủ nào.',
    'DEVICE_NOT_IN_SCOPE': 'Thiết bị không thuộc tủ bạn phụ trách.',
    'DEVICE_STATUS_ONLINE_NOT_ALLOWED':
        'Trạng thái trực tuyến do máy chủ tự tính, không đặt tay được.',
    'LOCKER_SERVICE_UNAVAILABLE':
        'Dịch vụ tủ đang tạm gián đoạn, vui lòng thử lại sau.',
  };

  static const Set<String> _serverWordedCodes = {'DRONE_ROUTE_TOO_SHORT'};

  /// Human-readable message from an [ApiResponse] error payload.
  static String errorMessage(Object error) {
    if (error is MediaUploadException) return error.message;
    if (error is LockerOpsException) return error.message;
    if (error is DioException) {
      final data = error.response?.data;
      final mediaMessage = data is Map
          ? MediaErrorMessages.forCode(data['code']?.toString())
          : null;
      if (mediaMessage != null) return mediaMessage;
      final code = errorCode(error);
      final serverMessage = data is Map && data['message'] is String
          ? (data['message'] as String).trim()
          : '';
      // Mã mà máy chủ đã viết câu tiếng Việt kèm số liệu cụ thể (vd. "Tủ nhận chỉ cách điểm lấy hàng 87 m").
      if (_serverWordedCodes.contains(code) && serverMessage.isNotEmpty) {
        return serverMessage;
      }
      final codeMessage = _codeMessages[code] ?? _technicianCodeMessages[code];
      if (codeMessage != null) return codeMessage;
      // 404 không kèm mã nghiệp vụ = máy chủ chưa có API này (bản cũ).
      if (code == null && error.response?.statusCode == 404) {
        return L10n.current.apiErrNotSupportedUpdate;
      }
      if (serverMessage.isNotEmpty) return serverMessage;
      final fallback = _technicianCodeFallbacks[code];
      if (fallback != null) return fallback;
      if (error.response?.statusCode == 403) {
        return L10n.current.apiErrForbidden;
      }
      return L10n.current.apiErrConnection;
    }
    return L10n.current.apiErrGeneric;
  }
}
