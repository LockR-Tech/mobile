/// Người gửi tự chuyển mã lấy hàng cho người nhận.
///
/// Server chỉ nhắn được mã tới người nhận khi kênh SMS/email đã cấu hình hoặc
/// người nhận có tài khoản Lock.R. Thiếu cả hai thì người nhận không có mã, nên
/// app cho người gửi tự gửi một tin nhắn soạn sẵn (bảng chia sẻ của máy, ứng
/// dụng SMS, hoặc sao chép).
///
/// Thuần Dart, không phụ thuộc Flutter: dựng tin nhắn và link `sms:` ở đây để
/// test được mà không cần widget.
library;

import 'package:smart_laundry_locker/core/utils/app_date_time.dart';
import 'package:smart_laundry_locker/core/l10n/l10n.dart';

/// Loại đơn có mã dành cho người nhận.
enum PickupShareKind {
  /// Gửi hàng qua tủ (SEND): người gửi bỏ hàng, người nhận lấy bằng PIN mới
  /// sinh lúc xác nhận bỏ hàng.
  lockerParcel,

  /// Giao bằng drone: drone thả hàng vào ô tủ nhận, người nhận lấy bằng PIN.
  droneDelivery,
}

/// Dữ liệu để chia sẻ mã lấy hàng. Trường nào không biết thì để `null`, tin
/// nhắn sẽ bỏ phần đó.
class PickupCodeShare {
  const PickupCodeShare({
    required this.code,
    this.kind = PickupShareKind.lockerParcel,
    this.lockerName,
    this.lockerAddress,
    this.boxNumber,
    this.deadline,
    this.receiverName,
    this.receiverPhone,
  });

  /// Mã người nhận nhập tại kiosk.
  final String code;
  final PickupShareKind kind;
  final String? lockerName;
  final String? lockerAddress;

  /// Số ô in trên tủ (không phải id nội bộ).
  final int? boxNumber;

  /// Hạn lấy hàng, giờ máy.
  final DateTime? deadline;
  final String? receiverName;
  final String? receiverPhone;

  String get message => buildPickupShareMessage(
    code: code,
    kind: kind,
    lockerName: lockerName,
    lockerAddress: lockerAddress,
    boxNumber: boxNumber,
    deadline: deadline,
  );

  /// Số điện thoại người nhận đã chuẩn hoá; `null` khi không dùng được.
  String? get smsPhone => normalizeSmsPhone(receiverPhone);

  /// Link mở ứng dụng SMS điền sẵn số người nhận và tin nhắn; `null` khi không
  /// có số hợp lệ.
  Uri? smsUri({bool iosStyle = false}) =>
      buildPickupSmsUri(receiverPhone, message, iosStyle: iosStyle);
}

String _two(int n) => n.toString().padLeft(2, '0');

/// `HH:mm dd/MM` — hạn lấy chỉ cách vài ngày nên bỏ năm và giây cho tin ngắn.
String formatPickupDeadline(DateTime value) {
  final d = value.toLocal();
  return '${_two(d.hour)}:${_two(d.minute)} ${_two(d.day)}/${_two(d.month)}';
}

/// Bỏ khoảng trắng và dấu chấm cuối để ghép câu không bị "..".
String? _clean(String? value) {
  if (value == null) return null;
  final trimmed = value.trim().replaceAll(RegExp(r'[\s.]+$'), '');
  return trimmed.isEmpty ? null : trimmed;
}

/// Tin nhắn gửi người nhận. Viết ngắn (khoảng 2 tin SMS) và bỏ phần nào không
/// biết:
///
/// `Lock.R: Bạn có kiện hàng gửi tới tủ {tên tủ}, {địa chỉ}. Ô số {n}. Mã lấy
/// hàng: {mã}. Hạn lấy: {HH:mm dd/MM}. Nhập mã tại màn hình tủ (kiosk) để mở
/// ô.`
String buildPickupShareMessage({
  required String code,
  PickupShareKind kind = PickupShareKind.lockerParcel,
  String? lockerName,
  String? lockerAddress,
  int? boxNumber,
  DateTime? deadline,
}) {
  final name = _clean(lockerName) ?? 'Lock.R';
  final address = _clean(lockerAddress);
  final where = address == null ? name : '$name, $address';
  final intro = switch (kind) {
    PickupShareKind.lockerParcel => L10n.current.shareMsgLocker(where),
    PickupShareKind.droneDelivery =>
      L10n.current.shareMsgDrone(where),
  };
  return [
    'Lock.R: $intro',
    if (boxNumber != null) L10n.current.shareMsgBox(boxNumber),
    L10n.current.shareMsgCode(code.trim()),
    if (deadline != null) L10n.current.shareMsgDeadline(formatPickupDeadline(deadline)),
    L10n.current.shareMsgHowTo,
  ].join(' ');
}

/// Giữ chữ số và dấu `+` đầu (số quốc tế). Ít hơn 8 chữ số thì coi như không
/// có số — ứng dụng SMS sẽ báo lỗi khó hiểu hơn là để người dùng tự nhập.
String? normalizeSmsPhone(String? phone) {
  if (phone == null) return null;
  final trimmed = phone.trim();
  final digits = trimmed.replaceAll(RegExp(r'[^0-9]'), '');
  if (digits.length < 8) return null;
  return trimmed.startsWith('+') ? '+$digits' : digits;
}

/// `sms:<số>?body=<tin nhắn>`. iOS đọc phần nội dung sau `&body=`, Android sau
/// `?body=`.
///
/// Mã hoá bằng [Uri.encodeComponent] (khoảng trắng thành `%20`), không dùng
/// `queryParameters` vì cách đó đổi khoảng trắng thành `+` và một số ứng dụng
/// SMS hiện nguyên dấu `+` trong tin nhắn.
Uri? buildPickupSmsUri(String? phone, String body, {bool iosStyle = false}) {
  final number = normalizeSmsPhone(phone);
  if (number == null) return null;
  final separator = iosStyle ? '&' : '?';
  return Uri.parse('sms:$number${separator}body=${Uri.encodeComponent(body)}');
}

int? _asInt(dynamic value) =>
    value is int ? value : (value is num ? value.toInt() : int.tryParse('$value'));

String? _text(dynamic value) {
  if (value == null) return null;
  final text = '$value'.trim();
  return text.isEmpty ? null : text;
}

/// Mã trong đơn (`OrderResponse` của `GET /api/orders/my-orders` hoặc kết quả
/// tạo/xác nhận đơn gửi) có phải mã người gửi nên chuyển cho người nhận không.
///
/// Chỉ khi hàng đã nằm trong ô chờ lấy (`STORING`):
/// - đơn gửi hàng `SEND`: PIN lúc này là PIN nhận hàng, PIN bỏ hàng đã hết hiệu
///   lực khi người gửi xác nhận bỏ hàng;
/// - đơn giao drone `DRONE_DELIVERY` đã thanh toán: PIN cấp lúc drone thả hàng.
///
/// Người nhận chính là tài khoản đặt đơn (`receiverId == userId`) thì không có
/// ai để chia sẻ ⇒ `null`. Hạn lấy đã qua thì bỏ dòng hạn khỏi tin nhắn.
PickupCodeShare? pickupCodeShareForOrder(
  Map<String, dynamic> order, {
  String? lockerName,
  String? lockerAddress,
  int? boxNumber,
  DateTime? now,
}) {
  final code = _text(order['pinCode']);
  if (code == null) return null;
  final status = (_text(order['status']) ?? '').toUpperCase();
  if (status != 'STORING') return null;

  final type = (_text(order['type']) ?? '').toUpperCase();
  final PickupShareKind kind;
  if (type == 'SEND') {
    kind = PickupShareKind.lockerParcel;
  } else if (type == 'DRONE_DELIVERY') {
    final paid = (_text(order['paymentStatus']) ?? '').toUpperCase() == 'PAID';
    if (!paid) return null;
    kind = PickupShareKind.droneDelivery;
  } else {
    return null;
  }

  final owner = _asInt(order['userId']);
  final receiver = _asInt(order['receiverId']);
  if (owner != null && receiver != null && owner == receiver) return null;

  final deadline = parseServerDateTime(order['pickupDeadline']);
  final current = now ?? DateTime.now();
  return PickupCodeShare(
    code: code,
    kind: kind,
    lockerName: lockerName,
    lockerAddress: lockerAddress,
    boxNumber: boxNumber,
    deadline: deadline != null && deadline.isAfter(current) ? deadline : null,
    receiverName: _text(order['receiverName']),
    receiverPhone: _text(order['receiverPhone']),
  );
}
