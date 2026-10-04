/// Nhãn tiếng Việt cho các mã backend trả về trong luồng giao drone. Mã lạ được
/// trả nguyên văn để màn hình không vỡ khi backend thêm giá trị mới.
library;

import 'dart:math';

/// `DroneMission.status` — trạng thái vận hành phía đội bay.
String droneMissionStatusLabel(String? status) =>
    switch ((status ?? '').toUpperCase()) {
      '' => 'Chưa khởi tạo',
      'AWAITING_LOADING' => 'Chờ nạp hàng',
      'READY_TO_LAUNCH' => 'Sẵn sàng phóng',
      'LAUNCHING' => 'Đang khởi phóng',
      'DEPARTED' => 'Đã rời trạm',
      'EN_ROUTE' => 'Đang bay',
      'APPROACHING' => 'Sắp tới tủ nhận',
      'ARRIVED' => 'Đã tới tủ nhận',
      'DEPOSITED' => 'Đã gửi hàng vào ô',
      'CANCELED' => 'Đã huỷ',
      _ => status!,
    };

/// `orders.status` của đơn drone.
String droneOrderStatusLabel(String? status) =>
    switch ((status ?? '').toUpperCase()) {
      '' => '—',
      'AWAITING_DISPATCH' => 'Đang giao bằng drone',
      'STORING' => 'Hàng đang trong tủ nhận',
      'COMPLETED' => 'Hoàn tất',
      'CANCELED' => 'Đã huỷ',
      'EXPIRED' => 'Quá hạn nhận',
      _ => status!,
    };

String dronePaymentStatusLabel(String? status) =>
    switch ((status ?? '').toUpperCase()) {
      '' => '—',
      'PAID' => 'Đã thanh toán',
      'UNPAID' => 'Chưa thanh toán',
      'REFUNDED' => 'Đã hoàn tiền',
      _ => status!,
    };

/// `payments.method` của payment-service.
String dronePaymentMethodLabel(String? method) =>
    switch ((method ?? '').toUpperCase()) {
      '' => '—',
      'WALLET' => 'Ví Lock.R',
      'CASH' => 'Tiền mặt',
      'VNPAY' => 'VNPay',
      'MOMO' => 'MoMo',
      'SEPAY' => 'Chuyển khoản (SePay)',
      _ => method!,
    };

/// Thời lượng chuyển chặng: `45 giây`, `3 phút 20 giây`, `1 giờ 5 phút`, `2 ngày 3 giờ`.
String droneDurationLabel(Duration duration) {
  final d = duration.isNegative ? Duration.zero : duration;
  if (d.inDays > 0) {
    final hours = d.inHours % 24;
    return hours == 0 ? '${d.inDays} ngày' : '${d.inDays} ngày $hours giờ';
  }
  if (d.inHours > 0) {
    final minutes = d.inMinutes % 60;
    return minutes == 0 ? '${d.inHours} giờ' : '${d.inHours} giờ $minutes phút';
  }
  if (d.inMinutes > 0) {
    final seconds = d.inSeconds % 60;
    return seconds == 0
        ? '${d.inMinutes} phút'
        : '${d.inMinutes} phút $seconds giây';
  }
  return '${d.inSeconds} giây';
}

/// Lý do đội bay huỷ nhiệm vụ — khớp `DroneOrderMaintenanceService.cancelReasonLabel`.
String? droneCancelReasonLabel(int? code) => switch (code) {
  null => null,
  1 => 'Thời tiết xấu',
  2 => 'Drone lỗi',
  3 => 'Bãi đáp không sẵn sàng',
  4 => 'Lý do vận hành',
  5 => 'Lý do khác',
  _ => 'Lý do #$code',
};

String droneFulfillmentModeLabel(String? mode) =>
    switch ((mode ?? '').toUpperCase()) {
      'DEMO' => 'Mô phỏng (DEMO)',
      'STANDARD' => 'Drone thật',
      _ => mode ?? '—',
    };

/// Nhãn ngắn cho nút chọn khối lượng: `500 g`, `1 kg`, `1,5 kg`.
String droneWeightShortLabel(int grams) {
  if (grams < 1000) return '$grams g';
  final kg = grams / 1000;
  final text = kg == kg.roundToDouble()
      ? kg.toStringAsFixed(0)
      : kg.toString().replaceAll('.', ',');
  return '$text kg';
}

/// Mã niêm phong hệ thống cấp cho một lần nạp hàng: `NP-<yyMMdd>-<6 ký tự>`, bỏ các
/// ký tự dễ đọc nhầm (0/O, 1/I). Cùng định dạng với mã order-service tự sinh.
String generateDroneSealCode({DateTime? now, Random? random}) {
  const alphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  final rng = random ?? Random.secure();
  final at = now ?? DateTime.now();
  String two(int n) => n.toString().padLeft(2, '0');
  final suffix = List.generate(
    6,
    (_) => alphabet[rng.nextInt(alphabet.length)],
  ).join();
  return 'NP-${two(at.year % 100)}${two(at.month)}${two(at.day)}-$suffix';
}

/// `1.250 g (1,25 kg)`; null ⇒ `—`.
String droneWeightLabel(int? grams) {
  if (grams == null) return '—';
  final kg = (grams / 1000).toStringAsFixed(2).replaceAll('.', ',');
  return '$grams g ($kg kg)';
}
