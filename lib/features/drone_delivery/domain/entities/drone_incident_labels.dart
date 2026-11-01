/// Nhãn tiếng Việt cho sự cố rơi kiện drone phía khách (`DroneIncidentStates`
/// và các mã sự kiện của order-service). Mã lạ ⇒ viết lại cho dễ đọc thay vì
/// hiện nguyên `UPPER_SNAKE`.
library;

import 'package:smart_laundry_locker/core/l10n/l10n.dart';

Map<String, String> get _incidentStatus => <String, String>{
  'REPORTED': L10n.current.incStReported,
  'EVIDENCE_PENDING': L10n.current.incStEvidencePending,
  'INVESTIGATING': L10n.current.incStInvestigating,
  'RECOVERY_IN_PROGRESS': L10n.current.incStRecoveryInProgress,
  'AWAITING_ADMIN_REVIEW': L10n.current.incStAwaitingAdmin,
  'RESOLUTION_PROPOSED': L10n.current.incStResolutionProposed,
  'AWAITING_CUSTOMER_RESPONSE': L10n.current.incStAwaitingCustomer,
  'RESOLUTION_IN_PROGRESS': L10n.current.incStResolutionInProgress,
  'DISPUTED': L10n.current.incStDisputed,
  'RESOLVED': L10n.current.incStResolved,
  'CLOSED': L10n.current.incStClosed,
  'MANUAL_INTERVENTION_REQUIRED': L10n.current.incStManual,
};

Map<String, String> get _recoveryStatus => <String, String>{
  'OPEN': L10n.current.recStOpen,
  'AWAITING_ASSIGNMENT': L10n.current.recStAwaitingAssignment,
  'ASSIGNED': L10n.current.recStAssigned,
  'ACCEPTED': L10n.current.recStAccepted,
  'SEARCHING': L10n.current.recStSearching,
  'PARCEL_FOUND': L10n.current.recStFound,
  'PARCEL_NOT_FOUND': L10n.current.recStNotFound,
  'RECOVERED': L10n.current.recStRecovered,
  'SUBMITTED': L10n.current.recStSubmitted,
  'VERIFIED': L10n.current.recStVerified,
  'CLOSED': L10n.current.recStClosed,
  'CANCELLED': L10n.current.recStCancelled,
};

Map<String, String> get _parcelStatus => <String, String>{
  'IN_TRANSIT': L10n.current.parStInTransit,
  'DROP_REPORTED': L10n.current.parStDropReported,
  'RECOVERY_PENDING': L10n.current.parStRecoveryPending,
  'FOUND': L10n.current.parStFound,
  'RECOVERED': L10n.current.parStRecovered,
  'DAMAGED': L10n.current.parStDamaged,
  'LOST': L10n.current.parStLost,
  'RETURNED_TO_HUB': L10n.current.parStReturnedToHub,
  'REDELIVERY_PENDING': L10n.current.parStRedeliveryPending,
  'REDELIVERED': L10n.current.parStRedelivered,
  'COMPENSATED': L10n.current.parStCompensated,
};

Map<String, String> get _eventTypes => <String, String>{
  // Người báo có thể là đội bay hoặc quản trị viên.
  'INCIDENT_REPORTED': L10n.current.incEvReported,
  'RECOVERY_ASSIGNED': L10n.current.incEvRecoveryAssigned,
  'RECOVERY_ACCEPT': L10n.current.incEvRecoveryAccept,
  'RECOVERY_START_SEARCHING': L10n.current.incEvRecoverySearching,
  'RETURN_FLIGHT_CONFIRMED': L10n.current.incEvReturnFlightConfirmed,
  'RECOVERY_SUBMITTED': L10n.current.incEvRecoverySubmitted,
  'RECOVERY_VERIFIED': L10n.current.incEvRecoveryVerified,
  'RECOVERY_STATION_DISPATCHED': L10n.current.incEvStationDispatched,
  'RECOVERY_STATION_UNAVAILABLE': L10n.current.incEvStationUnavailable,
  'PARCEL_RETURNED_TO_HUB': L10n.current.incEvReturnedToHub,
  'RESOLUTION_PROPOSED': L10n.current.incEvResolutionProposed,
  'CUSTOMER_ACCEPT': L10n.current.incEvCustomerAccept,
  'CUSTOMER_REQUEST_REVIEW': L10n.current.incEvCustomerReview,
  'RETURN_FLIGHT_UPDATED': L10n.current.incEvReturnFlightUpdated,
  'REDELIVERY_REQUESTED': L10n.current.incEvRedeliveryRequested,
  'REDELIVERY_INTEGRATION_UNAVAILABLE': L10n.current.incEvRedeliveryUnavailable,
  'REDELIVERY_COMPLETED': L10n.current.incEvRedeliveryCompleted,
  'COMPENSATION_SUBMITTED': L10n.current.incEvCompensationSubmitted,
  'COMPENSATION_PAID': L10n.current.incEvCompensationPaid,
  'COMPENSATION_PAYMENT_FAILED': L10n.current.incEvCompensationFailed,
  'INCIDENT_RESOLVED': L10n.current.incEvResolved,
};

Map<String, String> get _resolutionTypes => <String, String>{
  'FREE_REDELIVERY': L10n.current.resFreeRedelivery,
  'REDELIVERY_PARTIAL_COMPENSATION': L10n.current.resRedeliveryPartial,
  'COMPENSATION_ONLY': L10n.current.resCompensationOnly,
  'MANUAL_RESOLUTION': L10n.current.resManual,
};

/// Tình trạng kiện KTV ghi khi thu hồi (`DroneIncidentStates.CONDITIONS`).
Map<String, String> get _parcelCondition => <String, String>{
  'INTACT': L10n.current.condIntact,
  'MINOR_DAMAGE': L10n.current.condMinor,
  'MAJOR_DAMAGE': L10n.current.condMajor,
  'UNUSABLE': L10n.current.condUnusable,
};

Map<String, String> get _proposalStatus => <String, String>{
  'AWAITING_CUSTOMER_ACCEPTANCE': L10n.current.propAwaiting,
  'ACCEPTED': L10n.current.propAccepted,
  'DISPUTED': L10n.current.propDisputed,
  'SUPERSEDED': L10n.current.propSuperseded,
  'CANCELLED': L10n.current.recStCancelled,
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
  if (key.startsWith('RECOVERY_')) return L10n.current.incEvRecoveryUpdate;
  if (key.startsWith('COMPENSATION_')) return L10n.current.incEvCompensationUpdate;
  if (key.startsWith('RETURN_')) return L10n.current.incEvReturnFlightUpdated;
  if (key.startsWith('REDELIVERY_')) return L10n.current.incEvRedeliveryUpdate;
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
