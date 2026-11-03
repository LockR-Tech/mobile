import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_laundry_locker/core/config/business_config.dart';
import 'package:smart_laundry_locker/core/config/business_config_service.dart';
import 'package:smart_laundry_locker/core/routing/app_router.dart';
import 'package:smart_laundry_locker/features/auth/presentation/pages/splash_screen.dart';
import 'package:smart_laundry_locker/core/l10n/l10n.dart';

import '../../helpers/test_helpers.dart';

void main() {
  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
  });

  testWidgets('SplashScreen sử dụng splashDurationMs cấu hình từ BusinessConfig', (tester) async {
    // Cấu hình thời gian splash 500 ms
    final config = BusinessConfig.fromPublicMaps(
      auth: {'app.auth.splash-duration-ms': 500},
    );
    useBusinessConfig(config);

    expect(BusinessConfigService.instance.current.splashDurationMs, 500);

    String? navigatedRoute;
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const SplashScreen(),
        ),
        GoRoute(
          path: AppRouter.onboarding,
          builder: (context, state) {
            navigatedRoute = AppRouter.onboarding;
            return const Scaffold(body: Text('Onboarding Page'));
          },
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp.router(
        routerConfig: router,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    );

    // Màn splash hiển thị
    expect(find.byType(SplashScreen), findsOneWidget);
    expect(find.text('LOCK.R'), findsOneWidget);

    // Chưa hết thời gian chờ -> vẫn ở màn splash
    await tester.pump(const Duration(milliseconds: 200));
    expect(navigatedRoute, isNull);

    // Đợi quá 500 ms + fallback Lottie
    await tester.pumpAndSettle(const Duration(seconds: 4));

    // Đã chuyển sang onboarding vì chưa có token
    expect(navigatedRoute, AppRouter.onboarding);
  });
}
