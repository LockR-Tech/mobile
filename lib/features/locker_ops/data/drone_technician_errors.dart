import 'package:dio/dio.dart';
import 'package:smart_laundry_locker/features/locker_ops/data/locker_ops_service.dart';
import 'package:smart_laundry_locker/core/l10n/l10n.dart';

/// Thông báo cho các mã lỗi của luồng KTV drone (đổi trạng thái drone, xác
/// nhận chặng, gia hạn SLA, trả phiếu, sự cố rơi kiện) theo ngôn ngữ app. Mã
/// không có ở đây dùng bảng chung của [LockerOpsService.errorMessage].
Map<String, String> get droneTechnicianErrorMessages {
  final l10n = L10n.current;
  return {
    'DRONE_HAS_OPEN_REPORT': l10n.dtErrDroneHasOpenReport,
    'DRONE_IN_FLIGHT_USE_FAIL': l10n.dtErrDroneInFlightUseFail,
    'DRONE_STAGE_CHANGED': l10n.dtErrStageChanged,
    'SLA_EXTENSION_NOT_ASSIGNEE': l10n.dtErrSlaNotAssignee,
    'SLA_EXTENSION_LIMIT_REACHED': l10n.dtErrSlaLimitReached,
    'SLA_EXTENSION_HOURS_EXCEEDED': l10n.dtErrSlaHoursExceeded,
    'SLA_EXTENSION_REASON_REQUIRED': l10n.dtErrSlaReasonRequired,
    'INVALID_EXTENSION_HOURS': l10n.dtErrInvalidExtensionHours,
    'REPORT_NOT_ASSIGNED': l10n.dtErrReportNotAssigned,
    'REPORT_NOT_CLAIMED': l10n.dtErrReportNotClaimed,
    'REPORT_RELEASE_REASON_REQUIRED': l10n.dtErrReleaseReasonRequired,
    'REPORT_ALREADY_RESOLVED': l10n.dtErrReportAlreadyResolved,
    'DRONE_REPORT_REQUIRED': l10n.dtErrDroneReportRequired,
    'DRONE_JOURNEY_FORBIDDEN': l10n.dtErrJourneyForbidden,
    'DRONE_MISSION_NOT_FOUND': l10n.dtErrMissionNotFound,
    'DRONE_INCIDENT_NOT_FOUND': l10n.dtErrIncidentNotFound,
    'DRONE_TECHNICIAN_REQUIRED': l10n.dtErrTechnicianRequired,
    'INCIDENT_FORBIDDEN': l10n.dtErrIncidentForbidden,
  };
}

/// Mã lỗi nghiệp vụ của response (vd. `DRONE_STAGE_CHANGED`).
String? droneTechnicianErrorCode(Object error) =>
    LockerOpsService.errorCode(error);

/// Endpoint chưa có trên máy chủ đang chạy: 404 mà không kèm mã nghiệp vụ.
bool isEndpointMissing(Object error) {
  if (error is! DioException) return false;
  if (error.response?.statusCode != 404) return false;
  final code = LockerOpsService.errorCode(error);
  return code == null || code.isEmpty || code == 'NOT_FOUND';
}

/// Câu báo lỗi cho người dùng. [unsupported] = câu hiện khi máy chủ chưa có
/// endpoint (bản backend cũ).
String droneTechnicianErrorMessage(Object error, {String? unsupported}) {
  final code = LockerOpsService.errorCode(error);
  // Server ghi kèm số lần / số giờ tối đa đang cấu hình — hiện nguyên câu đó.
  if (_serverWordedCodes.contains(code)) {
    final message = _serverMessage(error);
    if (message != null) return message;
  }
  final mapped = code == null ? null : droneTechnicianErrorMessages[code];
  if (mapped != null) return mapped;
  if (isEndpointMissing(error)) {
    return unsupported ?? L10n.current.dtErrServerUnsupported;
  }
  return LockerOpsService.errorMessage(error);
}

const _serverWordedCodes = {
  'SLA_EXTENSION_LIMIT_REACHED',
  'SLA_EXTENSION_HOURS_EXCEEDED',
};

String? _serverMessage(Object error) {
  if (error is! DioException) return null;
  final data = error.response?.data;
  final message = data is Map ? data['message'] : null;
  return message is String && message.trim().isNotEmpty ? message.trim() : null;
}
