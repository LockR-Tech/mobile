/// Ánh xạ thông báo (push hoặc danh sách trong app) ⇒ màn hình, theo VAI TRÒ
/// của người đang đăng nhập. Dùng chung cho bấm push và bấm thông báo trong
/// danh sách để hai đường không lệch nhau.
///
/// Quy ước đường dẫn:
/// - KTV tủ: `/technician-home?tab=<inspect|incidents|mine|schedules|devices|recovery>&reportId=&scheduleId=`
/// - KTV drone: `/maintenance-home?tab=<dispatch|fleet|incidents|mine|schedules|tools>&reportId=&scheduleId=&orderId=`
/// - Khách: đơn `/locker/my-orders?orderId=`, phiếu `/locker/my-reports?reportId=`,
///   chuyến drone `/drone-delivery?orderId=`, đơn được ủy quyền lấy hộ
///   `/my-delegations?orderId=`.
///
/// KTV drone không bao giờ bị đưa sang trang KTV tủ (kể cả khi backend cũ còn
/// gửi type `locker.*` cho phiếu drone).
library;

import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_laundry_locker/core/routing/app_router.dart';
import 'package:smart_laundry_locker/core/routing/role_routes.dart';
import 'package:smart_laundry_locker/core/services/token_service.dart';

/// Type thông báo hành trình giao drone gửi khách (mốc chặng, huỷ nhiệm vụ,
/// báo rơi kiện, đề xuất xử lý sự cố). Giữ các type cũ trong thời gian chuyển.
const customerDroneDeliveryTypes = <String>{
  'DRONE_DELIVERY_STATUS_CHANGED',
  'drone_dispatched',
  'drone_approaching',
  'drone_arrived',
  'drone_delivered',
  'drone_delayed',
  'drone_failed',
  'DRONE_PARCEL_DROP_REPORTED',
  'DRONE_PARCEL_RECOVERY_VERIFIED',
  'DRONE_INCIDENT_RESOLUTION_PROPOSED',
};

/// Type báo đội bay có đơn drone mới cần tiếp nhận.
const droneDispatchTypes = <String>{'DRONE_ORDER_CREATED'};

/// Đường dẫn đích của một thông báo; `null` ⇒ không có màn riêng (nơi gọi tự
/// hiện nội dung thông báo hoặc mở danh sách Thông báo).
///
/// [referenceId] là id đối tượng backend gắn với thông báo (đơn, phiếu, lịch);
/// [orderId] là `orderId` riêng trong payload push (mốc chặng giao drone).
String? notificationLocation({
  required String? type,
  required AppRole role,
  String? referenceId,
  String? referenceType,
  String? orderId,
}) {
  final kind = (type ?? '').trim();
  final refType = (referenceType ?? '').trim().toUpperCase();
  final refId = _id(referenceId);
  return switch (role) {
    AppRole.droneTechnician => _droneTechnicianLocation(
      kind,
      refType,
      refId,
      _id(orderId) ?? refId,
    ),
    AppRole.lockerTechnician => technicianRouteForNotification(
      kind,
      referenceType: referenceType,
      referenceId: referenceId,
    ),
    AppRole.customer => _customerLocation(kind, refType, refId, _id(orderId)),
    // ADMIN dùng web console; mobile chỉ hiện nội dung thông báo.
    AppRole.admin => null,
  };
}

String? _droneTechnicianLocation(
  String type,
  String referenceType,
  int? referenceId,
  int? orderId,
) {
  switch (type) {
    case 'drone.report.assigned':
      return maintenanceHomeLocation(tab: 'mine', reportId: referenceId);
    case 'drone.report.routed':
      return maintenanceHomeLocation(tab: 'incidents', reportId: referenceId);
    case 'drone.schedule.due':
      return maintenanceHomeLocation(tab: 'schedules', scheduleId: referenceId);
    // Backend cũ gửi phiếu/lịch drone bằng type của KTV tủ.
    case 'locker.report.assigned':
      return referenceType == 'LOCKER'
          ? maintenanceHomeLocation(tab: 'incidents')
          : maintenanceHomeLocation(tab: 'mine', reportId: referenceId);
    case 'locker.report.routed':
      return maintenanceHomeLocation(tab: 'incidents', reportId: referenceId);
    case 'locker.schedule.due':
      return maintenanceHomeLocation(tab: 'schedules', scheduleId: referenceId);
    // KTV drone được giao thu hồi kiện rơi / được báo trạm cần mang kiện tới ⇒ tab Sự cố.
    case 'DRONE_PARCEL_RECOVERY_ASSIGNED':
    case 'DRONE_PARCEL_RECOVERY_STATION':
      return maintenanceHomeLocation(tab: 'incidents');
  }
  if (droneDispatchTypes.contains(type) ||
      customerDroneDeliveryTypes.contains(type) ||
      referenceType == 'DELIVERY') {
    return maintenanceHomeLocation(tab: 'dispatch', orderId: orderId);
  }
  return null;
}

String? _customerLocation(
  String type,
  String referenceType,
  int? referenceId,
  int? orderId,
) {
  // Mốc chặng giao drone dùng chung `ORDER_STATUS_CHANGED` với đơn tủ, chỉ khác
  // `referenceType = DELIVERY` ⇒ xét trước nhóm đơn.
  if (customerDroneDeliveryTypes.contains(type) ||
      referenceType == 'DELIVERY') {
    final id = orderId ?? referenceId;
    return id == null
        ? null
        : Uri(
            path: AppRouter.droneDeliveryTracking,
            queryParameters: {'orderId': '$id'},
          ).toString();
  }
  if (type == 'OPEN_PROMOTION_TAB') return AppRouter.promotions;
  // Ví đã gỡ khỏi app; tin cũ về rút tiền / điều chỉnh ví vẫn mở lịch sử giao dịch.
  if (type == 'wallet.updated') return AppRouter.transactions;
  // Admin điều chỉnh điểm ⇒ hồ sơ (mục Điểm thưởng).
  if (type == 'loyalty.points.changed') return AppRouter.profile;
  // Người khác ủy quyền cho mình lấy hộ (referenceId = orderId) ⇒ "Đơn ủy quyền".
  if (type == 'ORDER_DELEGATED_TO_YOU') {
    return _withId(AppRouter.myDelegations, 'orderId', orderId ?? referenceId);
  }
  if (type.startsWith('locker.report.') ||
      referenceType == 'LOCKER_REPORT' ||
      referenceType == 'REPORT') {
    return _withId(AppRouter.myLockerReports, 'reportId', referenceId);
  }
  final orderType =
      type.startsWith('ORDER_') ||
      type.startsWith('order.') ||
      type.startsWith('REFUND_') ||
      type.startsWith('PAYMENT_') ||
      type == 'FEEDBACK_REPLY' ||
      type == 'OPEN_ORDER_DETAIL';
  if (orderType || referenceType == 'ORDER') {
    // Chỉ coi referenceId là id đơn khi backend gắn đúng loại tham chiếu.
    final id = referenceType.isEmpty || referenceType == 'ORDER'
        ? (orderId ?? referenceId)
        : orderId;
    return _withId(AppRouter.myLockerOrders, 'orderId', id);
  }
  return null;
}

String _withId(String path, String key, int? id) => id == null
    ? path
    : Uri(path: path, queryParameters: {key: '$id'}).toString();

int? _id(String? raw) {
  final value = int.tryParse(raw?.trim() ?? '');
  return value == null || value <= 0 ? null : value;
}

/// Như [notificationLocation] nhưng tự đọc vai trò từ token hiện tại.
Future<String?> resolveNotificationLocation({
  required String? type,
  String? referenceId,
  String? referenceType,
  String? orderId,
}) async {
  final roles = await TokenService.getCurrentRoles();
  return notificationLocation(
    type: type,
    role: primaryRole(roles),
    referenceId: referenceId,
    referenceType: referenceType,
    orderId: orderId,
  );
}

/// Trang chủ theo vai trò (hai trang KTV) mở bằng `go` để thay cả stack —
/// tránh hai trang chủ chồng nhau, mỗi trang tự làm mới dữ liệu riêng.
bool isRoleHomeLocation(String location) {
  final path = Uri.parse(location).path;
  return path == AppRouter.technicianHome || path == AppRouter.maintenanceHome;
}

/// Mở [location] từ danh sách thông báo: trang chủ KTV thay stack, màn khác
/// được đẩy lên để nút quay lại về đúng danh sách.
void openNotificationLocation(BuildContext context, String location) {
  if (isRoleHomeLocation(location)) {
    context.go(location);
  } else {
    context.push(location);
  }
}
