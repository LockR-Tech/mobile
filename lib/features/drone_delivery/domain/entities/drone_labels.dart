/// Nhãn tiếng Việt cho các mã backend trả về trong luồng giao drone. Mã lạ được
/// trả nguyên văn để màn hình không vỡ khi backend thêm giá trị mới.
library;

import 'dart:math';
import 'package:smart_laundry_locker/core/l10n/l10n.dart';

/// `DroneMission.status` — trạng thái vận hành phía đội bay.
String droneMissionStatusLabel(String? status) =>
    switch ((status ?? '').toUpperCase()) {
      '' => L10n.current.msNotInit,
      'AWAITING_LOADING' => L10n.current.msAwaitingLoading,
      'READY_TO_LAUNCH' => L10n.current.msReadyToLaunch,
      'LAUNCHING' => L10n.current.msLaunching,
      'DEPARTED' => L10n.current.msDeparted,
      'EN_ROUTE' => L10n.current.msEnRoute,
      'APPROACHING' => L10n.current.msApproaching,
      'ARRIVED' => L10n.current.msArrived,
      'DEPOSITED' => L10n.current.msDeposited,
      'CANCELED' => L10n.current.recStCancelled,
      'FAILED' => L10n.current.msFailed,
      'DROP_REPORTED' => L10n.current.msDropReported,
      _ => status!,
    };

/// `orders.status` của đơn drone.
String droneOrderStatusLabel(String? status) =>
    switch ((status ?? '').toUpperCase()) {
      '' => '—',
      'AWAITING_DISPATCH' => L10n.current.dosAwaitingDispatch,
      'STORING' => L10n.current.dosStoring,
      'COMPLETED' => L10n.current.commonDone,
      'CANCELED' => L10n.current.recStCancelled,
      'EXPIRED' => L10n.current.dosExpired,
      _ => status!,
    };

String dronePaymentStatusLabel(String? status) =>
    switch ((status ?? '').toUpperCase()) {
      '' => '—',
      'PAID' => L10n.current.enumPaid,
      'UNPAID' => L10n.current.enumUnpaid,
      'REFUND_PENDING' => L10n.current.enumAwaitingRefund,
      'REFUNDED' => L10n.current.enumRefunded,
      _ => status!,
    };

/// `payments.method` của payment-service.
String dronePaymentMethodLabel(String? method) =>
    switch ((method ?? '').toUpperCase()) {
      '' => '—',
      'WALLET' => L10n.current.payMethodWallet,
      'CASH' => L10n.current.payMethodCash,
      'VNPAY' => 'VNPay',
      'MOMO' => 'MoMo',
      'SEPAY' => L10n.current.payMethodSepay,
      _ => method!,
    };

/// Thời lượng chuyển chặng: `45 giây`, `3 phút 20 giây`, `1 giờ 5 phút`, `2 ngày 3 giờ`.
String droneDurationLabel(Duration duration) {
  final d = duration.isNegative ? Duration.zero : duration;
  if (d.inDays > 0) {
    final hours = d.inHours % 24;
    return hours == 0
        ? L10n.current.durDays(d.inDays)
        : L10n.current.durDaysHoursLong(d.inDays, hours);
  }
  if (d.inHours > 0) {
    final minutes = d.inMinutes % 60;
    return minutes == 0
        ? L10n.current.durHours(d.inHours)
        : L10n.current.durHoursMinutesLong(d.inHours, minutes);
  }
  if (d.inMinutes > 0) {
    final seconds = d.inSeconds % 60;
    return seconds == 0
        ? L10n.current.minutesShort(d.inMinutes)
        : L10n.current.durMinutesSeconds(d.inMinutes, seconds);
  }
  return L10n.current.secondsValue(d.inSeconds);
}

/// Lý do đội bay huỷ nhiệm vụ hoặc báo chuyến bay thất bại — khớp `DroneOrderMaintenanceService.cancelReasonLabel`.
String? droneCancelReasonLabel(int? code) => switch (code) {
  null => null,
  1 => L10n.current.cancelWeather,
  2 => L10n.current.cancelDroneFault,
  3 => L10n.current.cancelPadNotReady,
  4 => L10n.current.cancelOperational,
  5 => L10n.current.cancelOther,
  _ => L10n.current.cancelReasonCode(code),
};

String droneFulfillmentModeLabel(String? mode) =>
    switch ((mode ?? '').toUpperCase()) {
      'DEMO' => L10n.current.modeDemo,
      'STANDARD' => L10n.current.modeStandard,
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
