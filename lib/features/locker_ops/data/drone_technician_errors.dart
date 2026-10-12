import 'package:dio/dio.dart';
import 'package:smart_laundry_locker/features/locker_ops/data/locker_ops_service.dart';

/// Thông báo tiếng Việt cho các mã lỗi của luồng KTV drone (đổi trạng thái
/// drone, xác nhận chặng, gia hạn SLA, trả phiếu, sự cố rơi kiện). Mã không có
/// ở đây dùng bảng chung của [LockerOpsService.errorMessage].
const droneTechnicianErrorMessages = <String, String>{
  'DRONE_HAS_OPEN_REPORT':
      'Drone còn phiếu sự cố chưa hoàn tất. Hoàn tất phiếu trước khi đưa drone về Sẵn sàng hoặc Đang sạc.',
  'DRONE_IN_FLIGHT_USE_FAIL':
      'Drone đang bay: dùng "Báo chuyến bay thất bại" trên nhiệm vụ đang bay thay vì đổi trạng thái.',
  'DRONE_STAGE_CHANGED':
      'Chặng bay vừa thay đổi (drone tự cập nhật hoặc đã có người xác nhận). Danh sách đã được tải lại, hãy kiểm tra rồi xác nhận lại.',
  'SLA_EXTENSION_NOT_ASSIGNEE':
      'Chỉ KTV đang được giao phiếu mới gia hạn được SLA.',
  'SLA_EXTENSION_LIMIT_REACHED':
      'Phiếu đã dùng hết số lần gia hạn SLA. Liên hệ quản trị nếu cần thêm thời gian.',
  'SLA_EXTENSION_HOURS_EXCEEDED':
      'Số giờ gia hạn vượt mức tối đa cho mỗi lần.',
  'SLA_EXTENSION_REASON_REQUIRED': 'Cần nhập lý do gia hạn SLA.',
  'INVALID_EXTENSION_HOURS': 'Thời gian gia hạn phải từ 1 giờ trở lên.',
  'REPORT_NOT_ASSIGNED': 'Chỉ KTV đang giữ phiếu mới trả được phiếu.',
  'REPORT_NOT_CLAIMED': 'Phiếu đang ở hàng chờ, chưa có KTV nhận.',
  'REPORT_RELEASE_REASON_REQUIRED': 'Cần nhập lý do trả phiếu.',
  'REPORT_ALREADY_RESOLVED': 'Phiếu đã hoàn tất, không thao tác được nữa.',
  'DRONE_REPORT_REQUIRED': 'Phiếu này không phải phiếu sự cố drone.',
  'DRONE_JOURNEY_FORBIDDEN':
      'Chỉ KTV đã tiếp nhận nhiệm vụ mới xem được camera của chuyến bay.',
  'DRONE_MISSION_NOT_FOUND': 'Đơn này chưa có nhiệm vụ bay.',
  'DRONE_INCIDENT_NOT_FOUND': 'Không tìm thấy sự cố.',
  'DRONE_TECHNICIAN_REQUIRED': 'Chức năng này chỉ dành cho KTV drone.',
  'INCIDENT_FORBIDDEN': 'Bạn không có quyền xem sự cố này.',
};

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
    return unsupported ?? 'Máy chủ chưa hỗ trợ chức năng này.';
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
