import 'package:smart_laundry_locker/core/routing/main_navigation_wrapper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:smart_laundry_locker/features/auth/presentation/pages/forgot_password_page.dart';
import 'package:smart_laundry_locker/features/auth/presentation/pages/login_screen.dart';
import 'package:smart_laundry_locker/features/auth/presentation/pages/otp_page.dart';
import 'package:smart_laundry_locker/features/auth/presentation/pages/splash_screen.dart';
import 'package:smart_laundry_locker/features/home/presentation/pages/home_page.dart';
import 'package:smart_laundry_locker/features/locker/presentation/pages/locker_page.dart';
import 'package:smart_laundry_locker/features/locker/presentation/pages/locker_map_page.dart';
import 'package:smart_laundry_locker/features/delegations/presentation/pages/authorized_opening_page.dart';
import 'package:smart_laundry_locker/features/delegations/presentation/pages/my_delegations_page.dart';
import 'package:smart_laundry_locker/features/delegations/presentation/providers/delegation_injection.dart';
import 'package:smart_laundry_locker/features/maintenance/presentation/pages/create_report_page.dart';
import 'package:smart_laundry_locker/features/maintenance/presentation/pages/report_list_page.dart';
import 'package:smart_laundry_locker/core/network/api_client.dart';
import 'package:provider/provider.dart';
import 'package:smart_laundry_locker/features/profile/domain/entities/user_profile.dart';
import 'package:smart_laundry_locker/features/profile/presentation/pages/policy_page.dart';
import 'package:smart_laundry_locker/features/profile/presentation/pages/profile_page.dart';
import 'package:smart_laundry_locker/features/profile/presentation/pages/profile_detail_page.dart';
import 'package:smart_laundry_locker/features/profile/presentation/pages/edit_profile_page.dart';
import 'package:smart_laundry_locker/features/profile/presentation/pages/face_verify_page.dart';
import 'package:smart_laundry_locker/features/profile/presentation/pages/face_registration_page.dart';
import 'package:smart_laundry_locker/features/profile/presentation/pages/security_page.dart';
import 'package:smart_laundry_locker/features/subscription/presentation/pages/plans_page.dart';
import 'package:smart_laundry_locker/features/transactions/presentation/pages/transactions_page.dart';
import 'package:smart_laundry_locker/features/transactions/presentation/pages/top_up_page.dart';
import 'package:smart_laundry_locker/core/presentation/pages/qr_scanner_page.dart';
import 'package:smart_laundry_locker/core/presentation/pages/directions_map_page.dart';
import 'package:smart_laundry_locker/features/notifications/presentation/pages/notification_list_page.dart';
import 'package:smart_laundry_locker/features/vouchers/presentation/pages/my_vouchers_page.dart';
import 'package:smart_laundry_locker/features/promotions/presentation/pages/promotions_page.dart';
import 'package:smart_laundry_locker/core/services/token_service.dart';
import 'package:go_router/go_router.dart';

import 'package:smart_laundry_locker/features/orders/domain/entities/order.dart';
import 'package:smart_laundry_locker/features/orders/presentation/pages/customer/customer_order_detail_page.dart';
import 'package:smart_laundry_locker/features/locker_ops/presentation/pages/admin_web_notice_page.dart';
import 'package:smart_laundry_locker/features/locker_ops/presentation/pages/maintenance_home_page.dart';
import 'package:smart_laundry_locker/features/locker_ops/presentation/pages/technician_home_page.dart';
import 'package:smart_laundry_locker/features/locker_ops/presentation/pages/send_parcel_page.dart';
import 'package:smart_laundry_locker/features/locker_ops/presentation/pages/rent_locker_page.dart';
import 'package:smart_laundry_locker/features/locker_ops/presentation/pages/my_locker_orders_page.dart';
import 'package:smart_laundry_locker/features/locker_ops/presentation/pages/my_reports_page.dart';
import 'package:smart_laundry_locker/features/drone_mission/presentation/mission_planner_page.dart';
import 'package:smart_laundry_locker/features/drone_telemetry/presentation/flight_data_page.dart';
import 'package:smart_laundry_locker/features/drone_delivery/presentation/pages/drone_delivery_tracking_page.dart';
import 'package:smart_laundry_locker/features/drone_delivery/presentation/pages/drone_live_map_page.dart';
import 'package:smart_laundry_locker/features/stores/domain/entities/store.dart';
import 'package:smart_laundry_locker/features/stores/presentation/pages/stores_page.dart';
import 'package:smart_laundry_locker/features/stores/presentation/pages/store_detail_page.dart';
import 'package:smart_laundry_locker/features/stores/presentation/pages/store_lockers_page.dart';
import 'package:latlong2/latlong.dart';

class AppRouter {
  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String otp = '/otp';
  static const String forgotPassword = '/forgot-password';
  static const String home = '/home';
  static const String lockers = '/lockers';
  static const String lockerMap = '/locker-map';
  static const String orders = '/orders';
  static const String profile = '/profile';
  static const String profileDetail = '/profile/detail';
  static const String editProfile = '/profile/edit';
  static const String security = '/profile/security';
  static const String plans = '/profile/plans';
  static const String transactions = '/transactions';
  static const String topUp = '/top-up';
  static const String policy = '/policy';
  static const String createReport = '/maintenance/create-report';
  static const String myReports = '/maintenance/my-reports';
  static const String qrScan = '/qr-scan';
  static const String notifications = '/notifications';
  static const String faceVerify = '/auth/face-verify';
  static const String authorizedOpening = '/authorized-opening';
  static const String faceRegistration = '/profile/face-registration';
  static const String orderDetail = '/orders/detail';
  static const String myDelegations = '/my-delegations';
  static const String myVouchers = '/my-vouchers';
  static const String promotions = '/promotions';
  static const String maintenanceHome = '/maintenance-home';
  static const String technicianHome = '/technician-home';
  static const String adminWebNotice = '/admin-web-notice';
  static const String sendParcel = '/locker/send-parcel';
  static const String rentLocker = '/locker/rent';
  static const String myLockerOrders = '/locker/my-orders';
  static const String myLockerReports = '/locker/my-reports';
  static const String stores = '/stores';
  static const String storeDetail = '/stores/detail';
  static const String storeLockers = '/stores/lockers';
  static const String directions = '/directions';
  static const String droneMissionPlanner = '/drone/mission-planner';
  static const String droneFlightData = '/drone/flight-data';
  static const String droneDeliveryTracking = '/drone-delivery';
  static const String droneLiveMap = '/drone-delivery/live-map';

  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  static final router = GoRouter(
    navigatorKey: navigatorKey,
    initialLocation: splash,
    observers: [FlutterSmartDialog.observer],
    refreshListenable: TokenService.authState,
    redirect: (context, state) {
      final isLoggedIn = TokenService.authState.value;
      final location = state.matchedLocation;

      final isProtectedRoute = location == transactions || location == topUp;

      if (!isLoggedIn && isProtectedRoute) {
        return onboarding;
      }

      return null;
    },
    routes: [
      GoRoute(path: splash, builder: (context, state) => const SplashScreen()),
      GoRoute(
        path: onboarding,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: otp,
        builder: (context, state) {
          final Map<String, dynamic>? params =
              state.extra as Map<String, dynamic>?;
          return OtpPage(
            phoneNumber: params?['phoneNumber'] as String?,
            email: params?['email'] as String?,
          );
        },
      ),
      GoRoute(
        path: forgotPassword,
        builder: (context, state) => const ForgotPasswordPage(),
      ),
      GoRoute(
        path: '/profile/detail',
        name: 'profile_detail',
        builder: (context, state) => const ProfileDetailPage(),
      ),
      GoRoute(
        path: editProfile,
        name: 'edit_profile',
        builder: (context, state) {
          final extra = state.extra;
          final profile = extra is UserProfile ? extra : null;
          return EditProfilePage(profile: profile);
        },
      ),
      GoRoute(
        path: security,
        name: 'security',
        builder: (context, state) => const SecurityPage(),
      ),
      GoRoute(
        path: plans,
        name: 'plans',
        builder: (context, state) => const PlansPage(),
      ),
      GoRoute(
        path: lockerMap,
        builder: (context, state) => const LockerMapPage(),
      ),
      ShellRoute(
        builder: (context, state, child) {
          return MainNavigationWrapper(child: child);
        },
        routes: [
          GoRoute(path: home, builder: (context, state) => const HomePage()),
          GoRoute(
            path: lockers,
            builder: (context, state) => const LockerPage(),
          ),
          GoRoute(
            // Bottom-nav "Đơn hàng" shows the customer's real locker orders
            // (locker_ops). The legacy OrderPage hit the old /orders/me API and
            // is no longer wired to the current backend.
            path: orders,
            builder: (context, state) => const MyLockerOrdersPage(),
          ),
          GoRoute(
            path: profile,
            builder: (context, state) => const ProfilePage(),
          ),
        ],
      ),
      GoRoute(
        path: orderDetail,
        name: 'order_detail',
        builder: (context, state) {
          final extra = state.extra;
          if (extra is Order) {
            return CustomerOrderDetailPage(orderId: extra.id, order: extra);
          }
          final qp = state.uri.queryParameters;
          final orderId =
              (extra is String ? extra : null) ?? qp['orderId'] ?? '';
          return CustomerOrderDetailPage(orderId: orderId);
        },
      ),
      GoRoute(
        path: transactions,
        name: 'transactions',
        builder: (context, state) => const TransactionsPage(),
      ),
      GoRoute(
        path: topUp,
        name: 'top_up',
        builder: (context, state) => const TopUpPage(),
      ),
      GoRoute(
        path: policy,
        builder: (context, state) {
          final Map<String, dynamic>? params =
              state.extra as Map<String, dynamic>?;
          if (params == null ||
              !params.containsKey('title') ||
              !params.containsKey('assetPath')) {
            return const PolicyPage(
              title: 'Chính sách',
              assetPath: 'assets/markdown/privacy_policy.md',
            );
          }
          return PolicyPage(
            title: params['title'] as String,
            assetPath: params['assetPath'] as String,
          );
        },
      ),
      GoRoute(
        path: createReport,
        name: 'create_report',
        builder: (context, state) {
          final params = state.extra as Map<String, dynamic>;
          return CreateReportPage(
            lockerId: params['lockerId'] as String,
            cabinetId: params['cabinetId'] as String,
            lockerName: params['lockerName'] as String?,
            cabinetName: params['cabinetName'] as String?,
          );
        },
      ),
      GoRoute(
        path: myReports,
        name: 'my_reports',
        builder: (context, state) => const ReportListPage(),
      ),
      GoRoute(
        path: qrScan,
        name: 'qr_scan',
        builder: (context, state) => const QrScannerPage(),
      ),
      GoRoute(
        path: notifications,
        name: 'notifications',
        builder: (context, state) => const NotificationListPage(),
      ),
      GoRoute(
        path: faceVerify,
        builder: (context, state) => const FaceVerifyPage(),
      ),
      GoRoute(
        path: faceRegistration,
        name: 'face_registration',
        builder: (context, state) => const FaceRegistrationPage(),
      ),
      GoRoute(
        path: authorizedOpening,
        name: 'authorized_opening',
        builder: (context, state) {
          final Map<String, dynamic>? params =
              state.extra as Map<String, dynamic>?;
          return ChangeNotifierProvider(
            create: (_) =>
                DelegationInjection.provideDelegationProvider(ApiClient()),
            child: AuthorizedOpeningPage(
              orderId: params?['orderId'] as String?,
              orderCode: params?['orderCode'] as String?,
              lockerId: params?['lockerId'] as String?,
              accessCode: params?['accessCode'] as String?,
            ),
          );
        },
      ),
      GoRoute(
        path: myDelegations,
        name: 'my_delegations',
        builder: (context, state) => const MyDelegationsPage(),
      ),
      GoRoute(
        path: maintenanceHome,
        name: 'maintenance_home',
        builder: (context, state) => const MaintenanceHomePage(),
      ),
      GoRoute(
        path: technicianHome,
        name: 'technician_home',
        builder: (context, state) => const TechnicianHomePage(),
      ),
      GoRoute(
        path: adminWebNotice,
        name: 'admin_web_notice',
        builder: (_, __) => const AdminWebNoticePage(),
      ),
      GoRoute(
        path: sendParcel,
        name: 'send_parcel',
        builder: (context, state) {
          final map = state.extra is Map<String, dynamic>
              ? state.extra as Map<String, dynamic>
              : null;
          return SendParcelPage(
            initialLockerId: map?['initialLockerId'] as int?,
            locationName: map?['locationName'] as String?,
          );
        },
      ),
      GoRoute(
        path: rentLocker,
        name: 'rent_locker',
        builder: (context, state) {
          final map = state.extra is Map<String, dynamic>
              ? state.extra as Map<String, dynamic>
              : null;
          return RentLockerPage(
            initialLockerId: map?['initialLockerId'] as int?,
            locationName: map?['locationName'] as String?,
          );
        },
      ),
      GoRoute(
        path: myLockerOrders,
        name: 'my_locker_orders',
        builder: (context, state) => const MyLockerOrdersPage(),
      ),
      GoRoute(
        path: myLockerReports,
        name: 'my_locker_reports',
        builder: (context, state) => const MyReportsPage(),
      ),
      GoRoute(
        path: myVouchers,
        name: 'my_vouchers',
        builder: (context, state) => const MyVouchersPage(),
      ),
      GoRoute(
        path: promotions,
        name: 'promotions',
        builder: (context, state) => const PromotionsPage(),
      ),
      GoRoute(
        path: stores,
        name: 'stores',
        builder: (context, state) => const StoresPage(),
      ),
      GoRoute(
        path: storeDetail,
        name: 'store_detail',
        builder: (context, state) {
          final extra = state.extra;
          if (extra is Store) {
            return StoreDetailPage(store: extra);
          }
          final id = int.tryParse(
            extra is String ? extra : (state.uri.queryParameters['id'] ?? ''),
          );
          if (id != null) {
            return StoreDetailPage(storeId: id);
          }
          return const StoresPage();
        },
      ),
      GoRoute(
        path: storeLockers,
        name: 'store_lockers',
        builder: (context, state) {
          final store = state.extra as Store;
          return StoreLockerGridPage(store: store);
        },
      ),
      GoRoute(
        path: directions,
        name: 'directions',
        builder: (context, state) {
          final extra = state.extra;
          final map = extra is Map<String, dynamic>
              ? extra
              : const <String, dynamic>{};
          final lat = (map['lat'] as num?)?.toDouble();
          final lng = (map['lng'] as num?)?.toDouble();
          if (lat == null || lng == null) {
            return const Scaffold(
              body: Center(child: Text('Thiếu toạ độ điểm đến.')),
            );
          }
          return DirectionsMapPage(
            destination: LatLng(lat, lng),
            title: (map['title'] as String?) ?? 'Điểm đến',
            subtitle: map['subtitle'] as String?,
          );
        },
      ),
      GoRoute(
        path: droneMissionPlanner,
        name: 'drone_mission_planner',
        builder: (context, state) => const MissionPlannerPage(),
      ),
      GoRoute(
        path: droneFlightData,
        name: 'drone_flight_data',
        builder: (context, state) => const FlightDataPage(),
      ),
      GoRoute(
        path: droneDeliveryTracking,
        name: 'drone_delivery_tracking',
        builder: (context, state) {
          // Deep-link từ FCM: `extra` là orderId (String); fallback query param.
          final extra = state.extra;
          final orderId =
              (extra is String ? extra : null) ??
              state.uri.queryParameters['orderId'] ??
              '';
          return DroneDeliveryTrackingPage(orderId: orderId);
        },
      ),
      GoRoute(
        path: droneLiveMap,
        name: 'drone_live_map',
        builder: (context, state) {
          // `extra` là orderId (String); fallback query param.
          final extra = state.extra;
          final orderId =
              (extra is String ? extra : null) ??
              state.uri.queryParameters['orderId'] ??
              '';
          return DroneLiveMapPage(orderId: orderId);
        },
      ),
    ],
  );
}
