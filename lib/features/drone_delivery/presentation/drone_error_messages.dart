import 'package:smart_laundry_locker/features/locker_ops/data/locker_ops_service.dart';
import 'package:smart_laundry_locker/core/l10n/l10n.dart';

/// Câu báo lỗi cho thao tác của khách trên đơn drone. Bổ sung các mã chỉ luồng
/// khách gặp (giữ ngoài bảng chung của `LockerOpsService` để các nhánh sửa song
/// song không đụng nhau), còn lại dùng `LockerOpsService.errorMessage`.
String droneCustomerErrorMessage(Object error) {
  switch (LockerOpsService.errorCode(error)) {
    case 'ORDER_FORBIDDEN':
      return L10n.current.droneErrOwnerOnly;
    case 'INCIDENT_CUSTOMER_FORBIDDEN':
      return L10n.current.droneErrNotYourIncident;
    case 'INCIDENT_DISPUTE_DISABLED':
      return L10n.current.droneErrNoReview;
    case 'PROPOSAL_ALREADY_RESPONDED':
      return L10n.current.droneErrAlreadyResponded;
    case 'RESOLUTION_PROPOSAL_NOT_FOUND':
      return L10n.current.droneErrNoProposal;
    case 'CUSTOMER_DECISION_INVALID':
      return L10n.current.droneErrInvalidChoice;
    case 'USER_LOOKUP_UNAVAILABLE':
      return L10n.current.droneErrRecipientLookup;
  }
  return LockerOpsService.errorMessage(error);
}
