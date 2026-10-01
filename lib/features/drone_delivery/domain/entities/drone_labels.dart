/// Nhãn tiếng Việt cho các mã backend trả về trong luồng giao drone. Mã lạ được
/// trả nguyên văn để màn hình không vỡ khi backend thêm giá trị mới.
library;

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

/// `1.250 g (1,25 kg)`; null ⇒ `—`.
String droneWeightLabel(int? grams) {
  if (grams == null) return '—';
  final kg = (grams / 1000).toStringAsFixed(2).replaceAll('.', ',');
  return '$grams g ($kg kg)';
}
