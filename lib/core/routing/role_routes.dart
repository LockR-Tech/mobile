import 'package:smart_laundry_locker/core/routing/app_router.dart';

/// Landing page per signed-in role. Mobile only serves 3 roles:
/// TECHNICIAN -> locker maintenance + IoT, MAINTENANCE -> drone fleet,
/// else customer home. ADMIN manages the system on the web app only,
/// so mobile shows a "use the web console" notice.
String homeForRoles(List<String> roles) {
  if (roles.contains('ADMIN') || roles.contains('ROLE_ADMIN')) {
    return AppRouter.adminWebNotice;
  }
  if (roles.contains('TECHNICIAN') || roles.contains('ROLE_TECHNICIAN')) {
    return AppRouter.technicianHome;
  }
  if (roles.contains('MAINTENANCE') || roles.contains('ROLE_MAINTENANCE')) {
    return AppRouter.maintenanceHome;
  }
  return AppRouter.home;
}
