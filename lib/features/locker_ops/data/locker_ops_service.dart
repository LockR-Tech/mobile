import 'package:dio/dio.dart';
import 'package:smart_laundry_locker/core/network/dio_client.dart';

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
      return data.cast<Map<String, dynamic>>();
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
    return data is Map<String, dynamic> ? data : <String, dynamic>{};
  }

  // ---- Catalogue ----
  Future<List<Map<String, dynamic>>> lockers() => _list('/api/lockers');

  Future<List<Map<String, dynamic>>> lockersByStore(int storeId) =>
      _list('/api/lockers', query: {'storeId': storeId});

  Future<Map<String, dynamic>> locker(int lockerId) =>
      _map('GET', '/api/lockers/$lockerId');

  Future<Map<String, dynamic>> layout(int lockerId) =>
      _map('GET', '/api/lockers/$lockerId/layout');

  // ---- Customer orders ----
  Future<List<Map<String, dynamic>>> myOrders() =>
      _list('/api/orders/my-orders');

  Future<Map<String, dynamic>> createSend({
    required int lockerId,
    required String receiverPhone,
    String? receiverName,
    String? note,
    String? promotionCode,
    String? size,
  }) => _map(
    'POST',
    '/api/orders/send',
    body: {
      'lockerId': lockerId,
      'receiverPhone': receiverPhone,
      'receiverName': receiverName,
      'note': note,
      if (size != null) 'size': size,
      if (promotionCode != null) 'promotionCode': promotionCode,
    },
  );

  Future<Map<String, dynamic>> createRental({
    required int lockerId,
    required String cellType,
    required int hours,
    String? note,
    String? promotionCode,
    int? boxId,
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
    },
  );

  Future<Map<String, dynamic>> createDroneDeliveryOrder({
    required int destinationLockerId,
    int? preferredBoxId,
    String? description,
    required int parcelWeightGrams,
    required String paymentMethod,
    required String idempotencyKey,
  }) => _map(
    'POST',
    '/api/orders/drone-deliveries',
    headers: {'Idempotency-Key': idempotencyKey},
    body: {
      'destinationLockerId': destinationLockerId,
      if (preferredBoxId != null) 'preferredBoxId': preferredBoxId,
      if (description != null) 'description': description,
      'parcelWeightGrams': parcelWeightGrams,
      'paymentMethod': paymentMethod,
    },
  );

  // ---- Promotions / loyalty / payments ----
  /// Validate a promo code. Returns `{code, valid, reason?, promotion:{...}}`.
  /// [lockerId] để backend check mã có scope theo tủ/kiosk; đăng nhập rồi thì
  /// backend còn check lượt dùng còn lại của chính user.
  Future<Map<String, dynamic>> validatePromotion(
    String code, {
    int? lockerId,
  }) => _map(
    'GET',
    '/api/promotions/validate/$code',
    query: lockerId == null ? null : {'lockerId': lockerId},
  );

  /// Current user's loyalty account: `{id, userId, points, stamps, tier}`.
  Future<Map<String, dynamic>> loyaltyPoints() =>
      _map('GET', '/api/loyalty/points');

  /// Payments recorded for an order (latest first by convention).
  Future<List<Map<String, dynamic>>> paymentsByOrder(int orderId) =>
      _list('/api/payments/order/$orderId');

  /// Số dư ví hiện tại của khách (VND).
  Future<num> walletBalance() async {
    final data = await _map('GET', '/api/wallet');
    final raw = data['balance'];
    return raw is num ? raw : num.tryParse('$raw') ?? 0;
  }

  /// Thanh toán đơn theo phương thức WALLET | VNPAY | MOMO | CASH.
  /// WALLET/CASH trả về payment đã COMPLETED; VNPAY/MOMO trả `url`/`deeplink`/`qr`
  /// để mở cổng thanh toán. `returnUrl` để WebView detect callback.
  Future<Map<String, dynamic>> checkout(
    int orderId,
    String method, {
    String? bankCode,
    String? returnUrl,
  }) => _map(
    'POST',
    '/api/payments/checkout',
    body: {
      'orderId': orderId,
      'method': method,
      if (bankCode != null) 'bankCode': bankCode,
      if (returnUrl != null) 'returnUrl': returnUrl,
    },
  );

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

  Future<Map<String, dynamic>> cancelOrder(int orderId) =>
      _map('PUT', '/api/orders/$orderId/cancel');

  Future<Map<String, dynamic>> delegate(
    int orderId, {
    required String phone,
    String? name,
    String? note,
  }) => _map(
    'POST',
    '/api/orders/$orderId/delegate',
    body: {'phone': phone, 'name': name, 'note': note},
  );

  Future<Map<String, dynamic>> reportFault(int boxId, String reason) =>
      _map('POST', '/api/boxes/$boxId/fault', body: {'reason': reason});

  Future<Map<String, dynamic>> reportOrderFault(int orderId, String reason) =>
      _map(
        'POST',
        '/api/orders/$orderId/report-box-fault',
        body: {'reason': reason},
      );

  /// All fault reports the signed-in customer has filed, newest first.
  Future<List<Map<String, dynamic>>> myReports() =>
      _list('/api/lockers/my-reports');

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
      _list('/api/maintenance/faults');

  Future<List<Map<String, dynamic>>> reports({bool mine = false}) =>
      _list('/api/maintenance/reports', query: {'mine': mine});

  Future<Map<String, dynamic>> claimReport(int reportId) =>
      _map('PUT', '/api/maintenance/reports/$reportId/claim');

  Future<Map<String, dynamic>> resolveReport(int reportId) =>
      _map('PUT', '/api/maintenance/reports/$reportId/resolve');

  Future<Map<String, dynamic>> clearFault(int boxId) =>
      _map('POST', '/api/maintenance/boxes/$boxId/clear-fault');

  /// Ngưng dùng ô có chủ đích (bảo trì/đóng). Ô bị loại khỏi mọi reserve.
  Future<Map<String, dynamic>> outOfService(int boxId, {String? reason}) =>
      _map(
        'POST',
        '/api/maintenance/boxes/$boxId/out-of-service',
        body: reason == null ? null : {'reason': reason},
      );

  /// Đưa ô vào trạng thái đang vệ sinh/khử khuẩn.
  Future<Map<String, dynamic>> cleaning(int boxId) =>
      _map('POST', '/api/maintenance/boxes/$boxId/cleaning');

  /// Khôi phục ô từ OUT_OF_SERVICE/CLEANING về AVAILABLE.
  Future<Map<String, dynamic>> returnToService(int boxId) =>
      _map('POST', '/api/maintenance/boxes/$boxId/return-to-service');

  /// Nhật ký xử lý của 1 phiếu bảo trì (work-log nhiều bước).
  Future<List<Map<String, dynamic>>> reportLogs(int reportId) =>
      _list('/api/maintenance/reports/$reportId/logs');

  Future<Map<String, dynamic>> addReportLog(int reportId, String note) => _map(
    'POST',
    '/api/maintenance/reports/$reportId/logs',
    body: {'note': note},
  );

  /// Lịch bảo trì phòng ngừa (mỗi mục kèm cờ `due`).
  Future<List<Map<String, dynamic>>> maintenanceSchedules() =>
      _list('/api/maintenance/schedules');

  /// KTV đánh dấu đã kiểm tra xong 1 lịch → dời mốc đến hạn kế tiếp.
  Future<Map<String, dynamic>> completeSchedule(int scheduleId) =>
      _map('POST', '/api/maintenance/schedules/$scheduleId/complete');

  /// Mở ô khẩn cấp không cần PIN khách — luôn được ghi vào audit log
  /// (credential MASTER) ở backend.
  Future<Map<String, dynamic>> forceOpenBox(int boxId) =>
      _map('POST', '/api/maintenance/boxes/$boxId/force-open');

  /// Điểm đánh giá trung bình KTV nhận được từ các report mình xử lý.
  Future<Map<String, dynamic>> myRatingAverage() =>
      _map('GET', '/api/maintenance/my-rating-average');

  /// Box-health cho bảo trì: trạng thái logic (theo đơn) đặt cạnh trạng thái
  /// phần cứng cửa cabinet báo lên (GAP 2). Mỗi phần tử:
  /// `{boxId, boxNumber, cellType, logicalStatus, hwState, lastReportedAt,
  /// doorOpen, needsAttention}`. `needsAttention` = cửa đang mở nhưng ô không
  /// `OCCUPIED` (nghi cửa kẹt/quên đóng).
  Future<List<Map<String, dynamic>>> boxHealth(int lockerId) =>
      _list('/api/maintenance/lockers/$lockerId/box-health');

  /// Tổng quan ca trực: mọi ô trên TẤT CẢ tủ đang có cửa phần cứng MỞ nhưng
  /// không `OCCUPIED` (nghi cửa kẹt/quên đóng). Mỗi phần tử kèm metadata locker
  /// (`lockerName/lockerAddress/lockerLatitude/lockerLongitude` để chỉ đường) +
  /// `boxId/boxNumber/cellType/logicalStatus/hwState/lastReportedAt`.
  Future<List<Map<String, dynamic>>> boxAnomalies() =>
      _list('/api/maintenance/box-anomalies');

  // ---- Drone fleet (maintenance) ----
  // Pin/trạng thái bay hiện chưa có telemetry thật, KTV nhập tay qua các
  // endpoint dưới đây (xem locker-service V10__drone_units.sql).

  /// Danh sách toàn bộ drone (thiết bị bay vật lý, khác ô tủ cellType=DRONE).
  Future<List<Map<String, dynamic>>> droneUnits() =>
      _list('/api/maintenance/drones');

  /// KTV nhận phụ trách một drone.
  Future<Map<String, dynamic>> claimDrone(int id) =>
      _map('POST', '/api/maintenance/drones/$id/claim');

  /// KTV nhả quyền phụ trách một drone (bàn giao ca).
  Future<Map<String, dynamic>> releaseDrone(int id) =>
      _map('POST', '/api/maintenance/drones/$id/release');

  /// Đổi trạng thái drone (IDLE/CHARGING/IN_FLIGHT/MAINTENANCE/FAULT).
  /// [reason] bắt buộc khi chuyển sang FAULT.
  Future<Map<String, dynamic>> updateDroneStatus(
    int id,
    String status, {
    String? reason,
  }) => _map(
    'POST',
    '/api/maintenance/drones/$id/status',
    body: {'status': status, if (reason != null) 'reason': reason},
  );

  /// Cập nhật % pin hiện tại của drone (nhập tay).
  Future<Map<String, dynamic>> updateDroneBattery(int id, int batteryPercent) =>
      _map(
        'POST',
        '/api/maintenance/drones/$id/battery',
        body: {'batteryPercent': batteryPercent},
      );

  /// Nhật ký bảo trì của một drone.
  Future<List<Map<String, dynamic>>> droneLogs(int id) =>
      _list('/api/maintenance/drones/$id/logs');

  Future<Map<String, dynamic>> addDroneLog(int id, String note) =>
      _map('POST', '/api/maintenance/drones/$id/logs', body: {'note': note});

  // ---- Drone delivery requests (khách tạo -> đội bay điều phối) ----

  /// Khách tạo yêu cầu giao hàng bằng drone tới 1 tủ (ô DRONE tuỳ chọn).
  Future<Map<String, dynamic>> createDroneDelivery({
    required int lockerId,
    int? boxId,
    String? receiverPhone,
    String? description,
  }) => _map(
    'POST',
    '/api/drone-deliveries',
    body: {
      'lockerId': lockerId,
      if (boxId != null) 'boxId': boxId,
      if (receiverPhone != null) 'receiverPhone': receiverPhone,
      if (description != null) 'description': description,
    },
  );

  /// Các yêu cầu giao drone của chính khách (mọi trạng thái, mới nhất trước).
  Future<List<Map<String, dynamic>>> myDroneDeliveries() =>
      _list('/api/drone-deliveries/my');

  /// Khách huỷ yêu cầu khi còn PENDING.
  Future<Map<String, dynamic>> cancelDroneDelivery(int id) =>
      _map('PUT', '/api/drone-deliveries/$id/cancel');

  /// Hàng đợi điều phối cho đội bay (MAINTENANCE); lọc theo [status] nếu có.
  Future<List<Map<String, dynamic>>> droneDeliveryQueue({String? status}) =>
      _list(
        '/api/maintenance/drone-deliveries',
        query: status == null ? null : {'status': status},
      );

  /// Hàng đợi order-based cho đội bay theo Phase 2.
  Future<List<Map<String, dynamic>>> droneOrderQueue({String? deliveryStage}) =>
      _list(
        '/api/maintenance/drone-orders',
        query: deliveryStage == null ? null : {'deliveryStage': deliveryStage},
      );

  /// Đội bay tiếp nhận một order drone và gán drone cho mission.
  Future<Map<String, dynamic>> acceptDroneOrder(
    int orderId, {
    required int droneUnitId,
    required String idempotencyKey,
  }) => _map(
    'POST',
    '/api/maintenance/drone-orders/$orderId/accept',
    headers: {'Idempotency-Key': idempotencyKey},
    body: {'droneUnitId': droneUnitId},
  );

  /// Đội bay phát lệnh launch cho mission đã sẵn sàng.
  Future<Map<String, dynamic>> launchDroneOrder(
    int orderId, {
    required String idempotencyKey,
  }) => _map(
    'POST',
    '/api/maintenance/drone-orders/$orderId/launch',
    headers: {'Idempotency-Key': idempotencyKey},
  );

  Future<Map<String, dynamic>> cancelDroneOrder(
    int orderId, {
    required int reasonCode,
    String? note,
  }) => _map(
    'POST',
    '/api/maintenance/drone-orders/$orderId/cancel',
    body: {
      'reasonCode': reasonCode,
      if (note != null && note.trim().isNotEmpty) 'note': note.trim(),
    },
  );

  /// Đội bay điều phối yêu cầu; gán [droneUnitId] thì drone đó chuyển IN_FLIGHT.
  Future<Map<String, dynamic>> dispatchDroneDelivery(
    int id, {
    int? droneUnitId,
  }) => _map(
    'POST',
    '/api/maintenance/drone-deliveries/$id/dispatch',
    body: droneUnitId == null ? null : {'droneUnitId': droneUnitId},
  );

  /// Drone đã thả hàng xong — yêu cầu DELIVERED, drone quay về IDLE.
  Future<Map<String, dynamic>> completeDroneDelivery(int id) =>
      _map('POST', '/api/maintenance/drone-deliveries/$id/complete');

  /// #6 KTV cập nhật trạng thái bảo trì bãi đáp drone của 1 tủ.
  /// [status] = OK / FAULT / MAINTENANCE.
  Future<Map<String, dynamic>> updateLandingPadStatus(
    int lockerId,
    String status, {
    String? reason,
  }) => _map(
    'POST',
    '/api/maintenance/lockers/$lockerId/landing-pad',
    body: {'status': status, if (reason != null) 'reason': reason},
  );

  // ── TECHNICIAN ─────────────────────────────────────────────────────────────

  /// Danh sách thiết bị IoT mà TECHNICIAN phụ trách.
  Future<List<Map<String, dynamic>>> techDevices() =>
      _list('/api/technician/devices');

  /// Chi tiết một thiết bị IoT theo ID.
  Future<Map<String, dynamic>> techDeviceDetail(int id) =>
      _map('GET', '/api/technician/devices/$id');

  /// Cập nhật trạng thái thiết bị (ONLINE / OFFLINE / ERROR).
  Future<void> techUpdateStatus(int id, String status) async {
    await _map(
      'PUT',
      '/api/technician/devices/$id/status',
      body: {'status': status},
    );
  }

  /// Nhật ký audit của một thiết bị IoT.
  Future<List<Map<String, dynamic>>> techDeviceLogs(int id) =>
      _list('/api/technician/devices/$id/logs');

  /// Gửi lệnh restart thiết bị IoT.
  Future<void> techRestartDevice(int id) async {
    await _map('POST', '/api/technician/devices/$id/restart');
  }

  /// Human-readable message from an [ApiResponse] error payload.
  static String errorMessage(Object error) {
    if (error is DioException) {
      final data = error.response?.data;
      if (data is Map && data['message'] is String) {
        return data['message'] as String;
      }
      if (error.response?.statusCode == 403) {
        return 'Bạn không có quyền thực hiện thao tác này';
      }
      return 'Lỗi kết nối máy chủ';
    }
    return 'Đã xảy ra lỗi';
  }
}
