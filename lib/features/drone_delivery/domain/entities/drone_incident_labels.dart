/// Nhãn tiếng Việt cho sự cố rơi kiện drone phía khách (`DroneIncidentStates`
/// và các mã sự kiện của order-service). Mã lạ ⇒ viết lại cho dễ đọc thay vì
/// hiện nguyên `UPPER_SNAKE`.
library;

const _incidentStatus = <String, String>{
  'REPORTED': 'Đã ghi nhận',
  'EVIDENCE_PENDING': 'Đang thu thập bằng chứng',
  'INVESTIGATING': 'Đang điều tra',
  'RECOVERY_IN_PROGRESS': 'Đang thu hồi kiện',
  'AWAITING_ADMIN_REVIEW': 'Chờ quản trị viên xem xét',
  'RESOLUTION_PROPOSED': 'Đã có phương án xử lý',
  'AWAITING_CUSTOMER_RESPONSE': 'Chờ bạn phản hồi phương án',
  'RESOLUTION_IN_PROGRESS': 'Đang thực hiện phương án',
  'DISPUTED': 'Đang xem xét lại theo yêu cầu',
  'RESOLVED': 'Đã xử lý xong',
  'CLOSED': 'Đã đóng',
  'MANUAL_INTERVENTION_REQUIRED': 'Nhân viên đang xử lý trực tiếp',
};

const _recoveryStatus = <String, String>{
  'OPEN': 'Mới mở',
  'AWAITING_ASSIGNMENT': 'Chờ phân công người thu hồi',
  'ASSIGNED': 'Đã phân công',
  'ACCEPTED': 'Nhân viên đã nhận việc',
  'SEARCHING': 'Đang tìm kiện',
  'PARCEL_FOUND': 'Đã tìm thấy kiện',
  'PARCEL_NOT_FOUND': 'Chưa tìm thấy kiện',
  'RECOVERED': 'Đã thu hồi kiện',
  'SUBMITTED': 'Đã báo kết quả thu hồi',
  'VERIFIED': 'Đã xác minh kết quả',
  'CLOSED': 'Đã bàn giao kiện về kho',
  'CANCELLED': 'Đã huỷ',
};

const _parcelStatus = <String, String>{
  'IN_TRANSIT': 'Đang vận chuyển',
  'DROP_REPORTED': 'Đã báo rơi',
  'RECOVERY_PENDING': 'Chờ thu hồi',
  'FOUND': 'Đã tìm thấy',
  'RECOVERED': 'Đã thu hồi',
  'DAMAGED': 'Bị hư hỏng',
  'LOST': 'Thất lạc',
  'RETURNED_TO_HUB': 'Đã về kho Lock.R',
  'REDELIVERY_PENDING': 'Chờ giao lại',
  'REDELIVERED': 'Đã giao lại',
  'COMPENSATED': 'Đã bồi thường',
};

const _eventTypes = <String, String>{
  // Người báo có thể là đội bay hoặc quản trị viên.
  'INCIDENT_REPORTED': 'Ghi nhận kiện rơi khỏi drone',
  'RECOVERY_ASSIGNED': 'Phân công người thu hồi kiện',
  'RECOVERY_ACCEPT': 'Nhân viên nhận việc thu hồi',
  'RECOVERY_START_SEARCHING': 'Nhân viên bắt đầu tìm kiện',
  'RETURN_FLIGHT_CONFIRMED': 'Drone đã về trạm',
  'RECOVERY_SUBMITTED': 'Báo kết quả thu hồi',
  'RECOVERY_VERIFIED': 'Xác minh kết quả thu hồi',
  'PARCEL_RETURNED_TO_HUB': 'Kiện đã về kho Lock.R',
  'RESOLUTION_PROPOSED': 'Lock.R đề xuất phương án',
  'CUSTOMER_ACCEPT': 'Bạn đồng ý phương án',
  'CUSTOMER_REQUEST_REVIEW': 'Bạn yêu cầu xem xét lại',
  'RETURN_FLIGHT_UPDATED': 'Cập nhật chuyến bay về trạm',
  'REDELIVERY_REQUESTED': 'Đã tạo đơn giao lại',
  'REDELIVERY_INTEGRATION_UNAVAILABLE': 'Chưa tạo được đơn giao lại — nhân viên sẽ liên hệ',
  'REDELIVERY_COMPLETED': 'Đã giao lại thành công',
  'COMPENSATION_SUBMITTED': 'Đã gửi yêu cầu chi bồi thường',
  'COMPENSATION_PAID': 'Đã chi bồi thường',
  'COMPENSATION_PAYMENT_FAILED': 'Chi bồi thường chưa thành công',
  'INCIDENT_RESOLVED': 'Đã hoàn tất xử lý sự cố',
};

const _resolutionTypes = <String, String>{
  'FREE_REDELIVERY': 'Giao lại miễn phí',
  'REDELIVERY_PARTIAL_COMPENSATION': 'Giao lại kèm bồi thường một phần',
  'COMPENSATION_ONLY': 'Bồi thường',
  'MANUAL_RESOLUTION': 'Thỏa thuận riêng',
};

/// Tình trạng kiện KTV ghi khi thu hồi (`DroneIncidentStates.CONDITIONS`).
const _parcelCondition = <String, String>{
  'INTACT': 'còn nguyên vẹn',
  'MINOR_DAMAGE': 'hư hại nhẹ',
  'MAJOR_DAMAGE': 'hư hại nặng',
  'UNUSABLE': 'không thể sử dụng',
};

const _proposalStatus = <String, String>{
  'AWAITING_CUSTOMER_ACCEPTANCE': 'Chờ bạn phản hồi',
  'ACCEPTED': 'Bạn đã đồng ý',
  'DISPUTED': 'Đã yêu cầu xem xét lại',
  'SUPERSEDED': 'Đã thay bằng phương án mới',
  'CANCELLED': 'Đã huỷ',
};

String droneIncidentStatusLabel(Object? code) => _label(_incidentStatus, code);

String droneRecoveryStatusLabel(Object? code) => _label(_recoveryStatus, code);

String droneParcelStatusLabel(Object? code) => _label(_parcelStatus, code);

/// "Đã về kho Lock.R · hư hại nhẹ" — khách cần biết kiện có hỏng không trước khi chọn phương án.
String droneParcelStateLabel(Object? status, Object? condition) {
  final base = droneParcelStatusLabel(status);
  final extra = _parcelCondition['${condition ?? ''}'.toUpperCase()];
  if (extra == null) return base;
  // Kiện hỏng: nói đúng mức KTV ghi ("Hư hại nhẹ"), không gộp thành "Bị hư hỏng".
  if ('${status ?? ''}'.toUpperCase() == 'DAMAGED') {
    return extra[0].toUpperCase() + extra.substring(1);
  }
  return '$base · $extra';
}

String droneResolutionTypeLabel(Object? code) =>
    _label(_resolutionTypes, code);

String droneProposalStatusLabel(Object? code) => _label(_proposalStatus, code);

/// Sự kiện trong nhật ký sự cố; nhóm `RECOVERY_*`, `COMPENSATION_*`,
/// `RETURN_*` có câu chung khi chưa có nhãn riêng.
String droneIncidentEventLabel(Object? code) {
  final key = '${code ?? ''}'.trim().toUpperCase();
  final known = _eventTypes[key];
  if (known != null) return known;
  if (key.startsWith('RECOVERY_')) return 'Cập nhật thu hồi kiện';
  if (key.startsWith('COMPENSATION_')) return 'Cập nhật bồi thường';
  if (key.startsWith('RETURN_')) return 'Cập nhật chuyến bay về trạm';
  if (key.startsWith('REDELIVERY_')) return 'Cập nhật giao lại';
  return _humanize(key);
}

String _label(Map<String, String> table, Object? code) {
  final key = '${code ?? ''}'.trim().toUpperCase();
  if (key.isEmpty || key == 'NULL') return '—';
  return table[key] ?? _humanize(key);
}

String _humanize(String key) {
  if (key.isEmpty || key == 'NULL') return '—';
  final words = key.toLowerCase().split('_').where((w) => w.isNotEmpty);
  final text = words.join(' ');
  return text.isEmpty ? '—' : '${text[0].toUpperCase()}${text.substring(1)}';
}
