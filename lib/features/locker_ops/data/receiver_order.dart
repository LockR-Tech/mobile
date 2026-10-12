import 'package:smart_laundry_locker/core/utils/app_date_time.dart';

/// Một đơn nhìn từ phía người nhận — `ReceiverOrderResponse` của
/// `GET /api/orders/incoming` (hàng gửi tới tôi) và
/// `GET /api/orders/delegated-to-me` (đơn được ủy quyền cho tôi lấy hộ).
///
/// Mọi trường đều tuỳ chọn: backend cũ có thể thiếu trường, app vẫn hiện được
/// phần có dữ liệu thay vì lỗi.
class ReceiverOrder {
  const ReceiverOrder({
    required this.id,
    this.orderCode,
    this.type,
    this.status,
    this.deliveryStage,
    this.senderName,
    this.receiverName,
    this.receiverPhone,
    this.lockerId,
    this.lockerCode,
    this.lockerName,
    this.lockerAddress,
    this.lockerLatitude,
    this.lockerLongitude,
    this.boxId,
    this.boxNumber,
    this.pickupDeadline,
    this.overdue = false,
    this.readyForPickup = false,
    this.pickupPin,
    this.qrToken,
    this.paymentStatus,
    this.delegated = false,
    this.delegateName,
    this.delegateNote,
    this.delegatedAt,
    this.createdAt,
    this.completedAt,
  });

  final int id;
  final String? orderCode;
  final String? type;
  final String? status;
  final String? deliveryStage;
  final String? senderName;
  final String? receiverName;
  final String? receiverPhone;
  final int? lockerId;
  final String? lockerCode;
  final String? lockerName;
  final String? lockerAddress;
  final double? lockerLatitude;
  final double? lockerLongitude;
  final int? boxId;

  /// Số ô in trên tủ (không phải `boxId` nội bộ).
  final int? boxNumber;
  final DateTime? pickupDeadline;
  final bool overdue;

  /// Hàng đã nằm trong ô và mở được bằng [pickupPin].
  final bool readyForPickup;
  final String? pickupPin;
  final String? qrToken;
  final String? paymentStatus;

  /// Chủ đơn đã ủy quyền cho người khác — người nhận gốc không còn mã.
  final bool delegated;
  final String? delegateName;
  final String? delegateNote;
  final DateTime? delegatedAt;
  final DateTime? createdAt;
  final DateTime? completedAt;

  static ReceiverOrder? tryParse(Map<String, dynamic> json) {
    final id = _int(json['id']);
    if (id == null) return null;
    return ReceiverOrder(
      id: id,
      orderCode: _text(json['orderCode']),
      type: _text(json['type'])?.toUpperCase(),
      status: _text(json['status'])?.toUpperCase(),
      deliveryStage: _text(json['deliveryStage'])?.toUpperCase(),
      senderName: _text(json['senderName']),
      receiverName: _text(json['receiverName']),
      receiverPhone: _text(json['receiverPhone']),
      lockerId: _int(json['lockerId']),
      lockerCode: _text(json['lockerCode']),
      lockerName: _text(json['lockerName']),
      lockerAddress: _text(json['lockerAddress']),
      lockerLatitude: _double(json['lockerLatitude']),
      lockerLongitude: _double(json['lockerLongitude']),
      boxId: _int(json['boxId']),
      boxNumber: _int(json['boxNumber']),
      pickupDeadline: parseServerDateTime(json['pickupDeadline']),
      overdue: json['overdue'] == true,
      readyForPickup: json['readyForPickup'] == true,
      pickupPin: _text(json['pickupPin']),
      qrToken: _text(json['qrToken']),
      paymentStatus: _text(json['paymentStatus'])?.toUpperCase(),
      delegated: json['delegated'] == true,
      delegateName: _text(json['delegateName']),
      delegateNote: _text(json['delegateNote']),
      delegatedAt: parseServerDateTime(json['delegatedAt']),
      createdAt: parseServerDateTime(json['createdAt']),
      completedAt: parseServerDateTime(json['completedAt']),
    );
  }

  /// Bỏ qua phần tử không có `id` thay vì làm hỏng cả danh sách.
  static List<ReceiverOrder> listFrom(List<Map<String, dynamic>> raw) =>
      raw.map(tryParse).whereType<ReceiverOrder>().toList(growable: false);

  bool get isFinished =>
      status == 'COMPLETED' || status == 'CANCELED' || status == 'CANCELLED';

  /// Đang chờ lấy và còn mở được bằng mã.
  bool get isActive => readyForPickup && !isFinished;

  /// Có đủ dữ liệu để mở ô bằng mã ngay trên app.
  bool get canUnlockWithCode =>
      isActive && lockerId != null && (pickupPin ?? '').isNotEmpty;

  /// `Ô số 4` — chỉ dùng số in trên tủ; thiếu thì nói chung chung.
  String get boxLabel => boxNumber == null ? 'ô của đơn' : 'ô số $boxNumber';

  String get displayCode =>
      (orderCode == null || orderCode!.isEmpty) ? '#$id' : '#$orderCode';

  static int? _int(dynamic v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse('${v ?? ''}');
  }

  static double? _double(dynamic v) {
    final d = v is num ? v.toDouble() : double.tryParse('${v ?? ''}');
    if (d == null || d.isNaN || d.isInfinite) return null;
    return d;
  }

  static String? _text(dynamic v) {
    if (v == null) return null;
    final s = '$v'.trim();
    return s.isEmpty ? null : s;
  }
}
