import 'package:smart_laundry_locker/features/locker_ops/data/locker_ops_service.dart';

/// Câu báo lỗi cho thao tác của khách trên đơn drone. Bổ sung các mã chỉ luồng
/// khách gặp (giữ ngoài bảng chung của `LockerOpsService` để các nhánh sửa song
/// song không đụng nhau), còn lại dùng `LockerOpsService.errorMessage`.
String droneCustomerErrorMessage(Object error) {
  switch (LockerOpsService.errorCode(error)) {
    case 'ORDER_FORBIDDEN':
      return 'Chỉ người đặt đơn mới thực hiện được thao tác này.';
    case 'INCIDENT_CUSTOMER_FORBIDDEN':
      return 'Sự cố này không thuộc đơn của bạn.';
    case 'INCIDENT_DISPUTE_DISABLED':
      return 'Chính sách của đơn không cho yêu cầu xem xét lại phương án.';
    case 'PROPOSAL_ALREADY_RESPONDED':
      return 'Phương án này đã được phản hồi. Vui lòng tải lại.';
    case 'RESOLUTION_PROPOSAL_NOT_FOUND':
      return 'Chưa có phương án nào chờ bạn phản hồi.';
    case 'CUSTOMER_DECISION_INVALID':
      return 'Lựa chọn không hợp lệ.';
    case 'USER_LOOKUP_UNAVAILABLE':
      return 'Chưa tra được thông tin người nhận. Vui lòng thử lại sau.';
  }
  return LockerOpsService.errorMessage(error);
}
