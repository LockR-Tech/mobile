import 'dart:async';

import 'package:smart_laundry_locker/core/config/business_config_service.dart';
import 'package:smart_laundry_locker/core/l10n/l10n.dart';
import 'package:smart_laundry_locker/core/l10n/locale_provider.dart';
import 'package:smart_laundry_locker/core/network/dio_client.dart';
import 'package:smart_laundry_locker/core/routing/app_router.dart';
import 'package:smart_laundry_locker/core/routing/app_back_navigation.dart';
import 'package:smart_laundry_locker/core/services/app_messenger_service.dart';
import 'package:smart_laundry_locker/core/services/app_restart_service.dart';
import 'package:smart_laundry_locker/core/services/token_service.dart';
import 'package:smart_laundry_locker/core/theme/shadcn_theme.dart';
import 'package:smart_laundry_locker/core/services/firebase_messaging_service.dart';
import 'package:smart_laundry_locker/firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:provider/provider.dart';
import 'package:smart_laundry_locker/features/notifications/presentation/providers/notification_injection.dart';
import 'package:smart_laundry_locker/features/profile/presentation/providers/profile_injection.dart';
import 'package:smart_laundry_locker/core/network/api_client.dart';
import 'package:smart_laundry_locker/features/qr_login/presentation/providers/qr_login_provider.dart';
import 'package:flutter/cupertino.dart';
import 'package:smart_laundry_locker/features/home/presentation/providers/home_provider.dart';
import 'package:smart_laundry_locker/features/home/data/repositories/home_repository.dart';
import 'package:smart_laundry_locker/features/vouchers/presentation/providers/voucher_provider.dart';
import 'package:smart_laundry_locker/core/theme/theme_provider.dart';
import 'package:smart_laundry_locker/shared/shared.dart';

class _AislLoadingWidget extends StatelessWidget {
  final String msg;
  const _AislLoadingWidget({required this.msg});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const AppLoadingIndicator(size: 96),
          if (msg.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              msg,
              style: const TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.w700,
                fontSize: 15,
                letterSpacing: -0.2,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// `SmartDialog.showNotify` — cùng kiểu thẻ với toast, đặt giữa màn hình.
class _AislNotifyWidget extends StatelessWidget {
  final String msg;
  final ToastTone tone;
  const _AislNotifyWidget({required this.msg, required this.tone});

  @override
  Widget build(BuildContext context) {
    return AppToast(
      message: msg,
      tone: tone,
      margin: const EdgeInsets.symmetric(horizontal: 16),
    );
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (kIsWeb) {
    // Web chỉ khởi tạo Firebase khi đã dán cấu hình Web App vào
    // DefaultFirebaseOptions.web — chưa có thì bỏ qua hẳn (nút SĐT/Google ẩn,
    // console sạch). Web chỉ dùng Firebase Auth, không đăng ký push.
    if (DefaultFirebaseOptions.isWebConfigured) {
      try {
        // Firebase JS SDK tải từ CDN: không để mạng chậm/chặn treo khởi động.
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        ).timeout(const Duration(seconds: 10));
      } catch (e) {
        debugPrint("Firebase web init failed: $e");
      }
    }
  } else {
    try {
      // Firebase is also auto-initialized natively (google-services plugin), so
      // calling initializeApp again throws `[core/duplicate-app]` — which used to
      // swallow the whole block and skip messaging init. Only initialize when no
      // default app exists yet.
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
      }
      // Thông báo khởi tạo nền: kênh thông báo, listener, noti đã mở app không
      // được chặn khung hình đầu (trước đây màn trắng tới khi xong cả chuỗi).
      unawaited(
        FirebaseMessagingService.instance.init().catchError(
          (Object e) => debugPrint("Firebase messaging init failed: $e"),
        ),
      );
    } catch (e) {
      debugPrint("Firebase init failed: $e");
    }
  }

  if (!kIsWeb) {
    // Cache tile bản đồ là singleton, tạo sớm để mọi TileLayer dùng chung cấu
    // hình. OSM chỉ cho max-age ~1 ngày; quá hạn thì flutter_map chờ OSM xác
    // nhận lại từng tile (0.6–3s) rồi mới vẽ. Chính sách OSM cho phép giữ 7 ngày.
    BuiltInMapCachingProvider.getOrCreateInstance(
      overrideFreshAge: const Duration(days: 7),
    );
  }

  DioClient.instance.init();
  // Ngôn ngữ đã chọn (mặc định tiếng Việt) phải có trước khung hình đầu.
  await LocaleProvider.instance.restore();
  // Initialize token service from secure storage
  await TokenService.initializeFromStorage();
  // Quy tắc nghiệp vụ (giá, phí, giới hạn) do admin cấu hình: khôi phục
  // last-known rồi làm mới nền, KHÔNG chặn khởi động (lỗi ⇒ giá trị mặc định).
  unawaited(BusinessConfigService.instance.init());

  // Nút quay lại của điện thoại đi theo lịch sử trang (tab trước, trang trước), không thoát app.
  AppBackNavigation.instance.attach(AppRouter.router);

  AppMessengerService.configureToasts();
  runApp(const ProviderScope(child: RestartableApp(child: AislApp())));
}

class AislApp extends StatelessWidget {
  const AislApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) =>
              NotificationInjection.provideNotificationProvider(ApiClient())
                ..loadUnreadCount(),
        ),
        ChangeNotifierProvider(create: (_) => QrLoginProvider()),
        ChangeNotifierProvider(
          create: (_) => ProfileInjection.provideProfileProvider(ApiClient()),
        ),
        ChangeNotifierProvider(
          create: (_) =>
              HomeProvider(HomeRepository(ApiClient()))..loadHomeData(),
        ),
        ChangeNotifierProvider(create: (_) => VoucherProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider.value(value: LocaleProvider.instance),
      ],
      child: Builder(
        builder: (context) {
          final themeMode = context.watch<ThemeProvider>().themeMode;
          final locale = context.watch<LocaleProvider>().locale;
          return ShadApp.router(
            title: 'Lockerly',
            locale: locale,
            supportedLocales: L10n.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            routerConfig: AppRouter.router,
            onNavigationNotification: AppBackNavigation.onNavigationNotification,
            theme: AISLShadcnTheme.lightTheme,
            darkTheme: AISLShadcnTheme.darkTheme,
            themeMode: themeMode,
            builder: (context, child) {
              // Toast/loading/dialog của SmartDialog nằm ngoài AdaptiveViewport:
              // nó tính chỗ tránh bàn phím bằng toạ độ màn hình thật.
              return AdaptiveViewport.clampTextScale(
                child: AppScaffoldMessenger(
                  key: AppMessengerService.scaffoldMessengerKey,
                  child:
                      FlutterSmartDialog.init(
                        toastBuilder: (String msg) => AppToastSlot(child: AppToast(message: msg)),
                        loadingBuilder: (String msg) =>
                            _AislLoadingWidget(msg: msg),
                        notifyStyle: FlutterSmartNotifyStyle(
                          successBuilder: (msg) =>
                              _AislNotifyWidget(msg: msg, tone: ToastTone.success),
                          failureBuilder: (msg) =>
                              _AislNotifyWidget(msg: msg, tone: ToastTone.error),
                          warningBuilder: (msg) =>
                              _AislNotifyWidget(msg: msg, tone: ToastTone.warning),
                          alertBuilder: (msg) =>
                              _AislNotifyWidget(msg: msg, tone: ToastTone.info),
                          errorBuilder: (msg) =>
                              _AislNotifyWidget(msg: msg, tone: ToastTone.error),
                        ),
                      )(
                        context,
                        AdaptiveViewport(
                          child: child ?? const SizedBox.shrink(),
                        ),
                      ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
