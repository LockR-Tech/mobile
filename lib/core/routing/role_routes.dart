import 'package:smart_laundry_locker/core/routing/app_router.dart';

/// Vai trò chính của tài khoản trên mobile. Thứ tự ưu tiên khi một tài khoản
/// mang nhiều role: ADMIN > LOCKER_TECHNICIAN > DRONE_TECHNICIAN > khách.
enum AppRole { admin, lockerTechnician, droneTechnician, customer }

bool _hasRole(List<String> roles, String role) =>
    roles.contains(role) || roles.contains('ROLE_$role');

AppRole primaryRole(List<String> roles) {
  if (_hasRole(roles, 'ADMIN')) return AppRole.admin;
  if (_hasRole(roles, 'LOCKER_TECHNICIAN')) return AppRole.lockerTechnician;
  if (_hasRole(roles, 'DRONE_TECHNICIAN')) return AppRole.droneTechnician;
  return AppRole.customer;
}

/// Landing page per signed-in role. Mobile only serves 3 roles:
/// LOCKER_TECHNICIAN (kỹ thuật viên tủ) -> locker maintenance + IoT,
/// DRONE_TECHNICIAN (kỹ thuật viên drone) -> drone fleet, else customer home.
/// ADMIN manages the system on the web app only, so mobile shows a
/// "use the web console" notice.
String homeForRoles(List<String> roles) => homeForRole(primaryRole(roles));

String homeForRole(AppRole role) => switch (role) {
  AppRole.admin => AppRouter.adminWebNotice,
  AppRole.lockerTechnician => AppRouter.technicianHome,
  AppRole.droneTechnician => AppRouter.maintenanceHome,
  AppRole.customer => AppRouter.home,
};

/// Màn chỉ mở khi đã đăng nhập (mọi vai trò); chưa đăng nhập ⇒ router đưa
/// về màn đăng nhập thay vì để màn gọi API rồi hiện lỗi 401 thô.
bool requiresSignIn(String location) {
  if (_signInRoutes.contains(location)) return true;
  return location.startsWith('${AppRouter.assistant}/') ||
      location.startsWith('$_droneToolsPrefix/');
}

const _droneToolsPrefix = '/drone';

const _signInRoutes = <String>{
  // Ví, giao dịch, hoàn tiền
  AppRouter.transactions,
  AppRouter.refundBankAccount,
  AppRouter.refundRequests,
  // Trợ lý hỏi đáp gọi API cần JWT
  AppRouter.assistant,
  // Đơn, gửi/thuê tủ, theo dõi drone
  AppRouter.sendParcel,
  AppRouter.rentLocker,
  AppRouter.myLockerOrders,
  AppRouter.orderDetail,
  AppRouter.droneDeliveryTracking,
  AppRouter.droneLiveMap,
  // Báo sự cố
  AppRouter.createReport,
  AppRouter.myReports,
  AppRouter.myLockerReports,
  // Thông báo, ủy quyền, ưu đãi đã lưu
  AppRouter.notifications,
  AppRouter.myDelegations,
  AppRouter.authorizedOpening,
  AppRouter.myVouchers,
  // Hồ sơ cá nhân
  AppRouter.profileDetail,
  AppRouter.editProfile,
  AppRouter.security,
  AppRouter.faceRegistration,
  AppRouter.bleTest,
  // Trang theo vai trò
  AppRouter.technicianHome,
  AppRouter.technicianProfile,
  AppRouter.maintenanceHome,
};

/// Chặn route theo đăng nhập và vai trò. Trả về đường dẫn cần chuyển tới, hoặc
/// `null` nếu được vào. Hàm thuần (không đọc storage) để kiểm thử được.
///
/// - Chưa đăng nhập mà mở màn cần đăng nhập ⇒ màn đăng nhập.
/// - Trang KTV tủ chỉ cho LOCKER_TECHNICIAN, trang KTV drone và `/drone/*`
///   chỉ cho DRONE_TECHNICIAN; vai trò khác được đưa về trang chủ của mình
///   (deep link giữa hai trang KTV được dịch tab tương ứng).
String? routeRedirect(
  Uri uri, {
  required bool signedIn,
  required List<String> roles,
}) {
  final path = uri.path;
  if (!signedIn) {
    return requiresSignIn(path) ? AppRouter.onboarding : null;
  }
  if (!isRoleRestricted(path)) return null;

  final role = primaryRole(roles);
  if (path == AppRouter.technicianHome) {
    if (role == AppRole.lockerTechnician) return null;
    if (role == AppRole.droneTechnician) {
      return _translateTechnicianLink(uri, to: AppRouter.maintenanceHome);
    }
    return homeForRole(role);
  }
  if (path == AppRouter.maintenanceHome) {
    if (role == AppRole.droneTechnician) return null;
    if (role == AppRole.lockerTechnician) {
      return _translateTechnicianLink(uri, to: AppRouter.technicianHome);
    }
    return homeForRole(role);
  }
  if (path == AppRouter.technicianProfile) {
    return role == AppRole.lockerTechnician || role == AppRole.droneTechnician
        ? null
        : homeForRole(role);
  }
  // `/drone/*`: công cụ bay (Mission Planner, Flight Data).
  return role == AppRole.droneTechnician ? null : homeForRole(role);
}

/// Route cần biết vai trò mới quyết định được (router chỉ đọc role khi cần).
bool isRoleRestricted(String path) =>
    path == AppRouter.technicianHome ||
    path == AppRouter.maintenanceHome ||
    path == AppRouter.technicianProfile ||
    path.startsWith('$_droneToolsPrefix/');

/// Tab dùng chung giữa hai trang KTV (cùng tên `?tab=`).
const _sharedTechnicianTabs = {'incidents', 'mine', 'schedules'};

String _translateTechnicianLink(Uri uri, {required String to}) {
  final qp = uri.queryParameters;
  final tab = qp['tab'];
  return Uri(
    path: to,
    queryParameters: _nonEmpty({
      if (tab != null && _sharedTechnicianTabs.contains(tab)) 'tab': tab,
      'reportId': qp['reportId'],
      'scheduleId': qp['scheduleId'],
    }),
  ).toString();
}

Map<String, String>? _nonEmpty(Map<String, String?> values) {
  final result = <String, String>{
    for (final entry in values.entries)
      if (entry.value != null && entry.value!.isNotEmpty)
        entry.key: entry.value!,
  };
  return result.isEmpty ? null : result;
}

/// Tab của trang KTV tủ theo thứ tự hiển thị — giá trị `?tab=` của
/// [AppRouter.technicianHome].
const technicianTabs = [
  'inspect',
  'incidents',
  'mine',
  'schedules',
  'devices',
  'recovery',
];

/// `?tab=` ⇒ chỉ số tab; tên lạ/thiếu ⇒ tab đầu.
int technicianTabIndex(String? tab) {
  final index = technicianTabs.indexOf(tab ?? '');
  return index < 0 ? 0 : index;
}

/// Tab của trang KTV drone theo thứ tự hiển thị — giá trị `?tab=` của
/// [AppRouter.maintenanceHome].
const maintenanceTabs = [
  'dispatch',
  'fleet',
  'incidents',
  'mine',
  'schedules',
  'tools',
];

/// `?tab=` ⇒ chỉ số tab trang KTV drone; tên lạ/thiếu ⇒ tab đầu (Điều phối).
int maintenanceTabIndex(String? tab) {
  final index = maintenanceTabs.indexOf(tab ?? '');
  return index < 0 ? 0 : index;
}

/// Id số trong query (`reportId`, `scheduleId`, `orderId`); thiếu/sai ⇒ null.
int? queryId(Map<String, String> queryParameters, String key) {
  final value = int.tryParse(queryParameters[key]?.trim() ?? '');
  return value == null || value <= 0 ? null : value;
}

/// `/technician-home?tab=&reportId=&scheduleId=` (quy ước deep link KTV tủ).
String technicianHomeLocation({String? tab, int? reportId, int? scheduleId}) =>
    Uri(
      path: AppRouter.technicianHome,
      queryParameters: _nonEmpty({
        'tab': tab,
        'reportId': reportId?.toString(),
        'scheduleId': scheduleId?.toString(),
      }),
    ).toString();

/// `/maintenance-home?tab=&reportId=&scheduleId=&orderId=` (quy ước deep link
/// KTV drone).
String maintenanceHomeLocation({
  String? tab,
  int? reportId,
  int? scheduleId,
  int? orderId,
}) => Uri(
  path: AppRouter.maintenanceHome,
  queryParameters: _nonEmpty({
    'tab': tab,
    'reportId': reportId?.toString(),
    'scheduleId': scheduleId?.toString(),
    'orderId': orderId?.toString(),
  }),
).toString();

/// Noti (push hoặc trong app) gửi KTV tủ ⇒ đường dẫn tới đúng tab (kèm id phiếu
/// / lịch nếu có); `null` nếu không phải noti của KTV tủ. `locker.report.assigned`
/// có `referenceType` LOCKER là admin giao tủ (referenceId là id tủ), còn lại là
/// giao phiếu. Ánh xạ đầy đủ theo vai trò: `notification_deep_link.dart`.
String? technicianRouteForNotification(
  String? type, {
  String? referenceType,
  String? referenceId,
}) {
  final id = int.tryParse(referenceId?.trim() ?? '');
  final refType = (referenceType ?? '').trim().toUpperCase();
  final kind = (type ?? '').trim();
  final normalized = kind.toLowerCase().replaceAll('_', '.');

  // Không xử lý thông báo dành riêng cho KTV drone
  if (normalized.startsWith('drone.report.') ||
      normalized.startsWith('drone.schedule.') ||
      normalized == 'drone.order.created') {
    return null;
  }

  // Thu hồi kiện hàng rơi từ drone giao cho KTV tủ
  if (normalized.startsWith('drone.parcel.recovery.') ||
      refType == 'DRONE_PARCEL_INCIDENT' ||
      refType == 'RECOVERY') {
    return technicianHomeLocation(tab: 'recovery');
  }

  // Lịch bảo trì định kỳ tủ
  if (normalized == 'locker.schedule.due' ||
      (normalized == 'locker.report.assigned' && refType == 'MAINTENANCE_SCHEDULE') ||
      refType == 'MAINTENANCE_SCHEDULE' ||
      refType == 'SCHEDULE') {
    return technicianHomeLocation(tab: 'schedules', scheduleId: id);
  }

  // Phân công KTV phụ trách tủ
  if (normalized == 'locker.report.assigned' && refType == 'LOCKER') {
    return technicianHomeLocation(tab: 'incidents');
  }

  // Giao phiếu sự cố hoặc phiếu gán trực tiếp cho KTV tủ
  if (normalized == 'locker.report.assigned') {
    return technicianHomeLocation(tab: 'mine', reportId: id);
  }

  // Phiếu sự cố mới được định tuyến chờ KTV nhận
  if (normalized == 'locker.report.routed') {
    return technicianHomeLocation(tab: 'incidents', reportId: id);
  }

  // Báo hỏng ô tủ
  if (normalized == 'locker.box.fault') {
    return technicianHomeLocation(tab: 'incidents', reportId: id);
  }

  // Khách hàng đánh giá phiếu sự cố đã xử lý
  if (normalized == 'locker.report.rated' ||
      refType == 'LOCKER_REPORT_RATING') {
    return technicianHomeLocation(tab: 'mine', reportId: id);
  }

  // Cảnh báo phần cứng hoặc thiết bị IoT
  if (normalized == 'iot.device.status.changed' || refType == 'DEVICE') {
    return technicianHomeLocation(tab: 'devices');
  }

  if (refType == 'LOCKER_REPORT' || refType == 'REPORT') {
    return technicianHomeLocation(tab: 'mine', reportId: id);
  }

  return null;
}
