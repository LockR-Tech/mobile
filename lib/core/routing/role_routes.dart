import 'package:smart_laundry_locker/core/routing/app_router.dart';

/// Landing page per signed-in role. Mobile only serves 3 roles:
/// LOCKER_TECHNICIAN (kỹ thuật viên tủ) -> locker maintenance + IoT,
/// DRONE_TECHNICIAN (kỹ thuật viên drone) -> drone fleet, else customer home.
/// ADMIN manages the system on the web app only, so mobile shows a
/// "use the web console" notice.
String homeForRoles(List<String> roles) {
  if (roles.contains('ADMIN') || roles.contains('ROLE_ADMIN')) {
    return AppRouter.adminWebNotice;
  }
  if (roles.contains('LOCKER_TECHNICIAN') ||
      roles.contains('ROLE_LOCKER_TECHNICIAN')) {
    return AppRouter.technicianHome;
  }
  if (roles.contains('DRONE_TECHNICIAN') ||
      roles.contains('ROLE_DRONE_TECHNICIAN')) {
    return AppRouter.maintenanceHome;
  }
  return AppRouter.home;
}
