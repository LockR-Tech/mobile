import 'package:smart_laundry_locker/core/network/dio_client.dart';
import 'package:smart_laundry_locker/core/routing/app_router.dart';
import 'package:smart_laundry_locker/core/services/app_messenger_service.dart';
import 'package:smart_laundry_locker/core/services/app_restart_service.dart';
import 'package:smart_laundry_locker/core/services/token_service.dart';
import 'package:smart_laundry_locker/core/theme/shadcn_theme.dart';
import 'package:smart_laundry_locker/core/services/firebase_messaging_service.dart';
import 'package:smart_laundry_locker/firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:provider/provider.dart';
import 'package:smart_laundry_locker/features/notifications/presentation/providers/notification_injection.dart';
import 'package:smart_laundry_locker/features/profile/presentation/providers/profile_injection.dart';
import 'package:smart_laundry_locker/core/network/api_client.dart';
import 'package:smart_laundry_locker/features/wallet/presentation/providers/wallet_provider.dart';
import 'package:smart_laundry_locker/features/qr_login/presentation/providers/qr_login_provider.dart';
import 'package:flutter/cupertino.dart';
import 'package:smart_laundry_locker/features/home/presentation/providers/home_provider.dart';
import 'package:smart_laundry_locker/features/home/data/repositories/home_repository.dart';
import 'package:smart_laundry_locker/features/vouchers/presentation/providers/voucher_provider.dart';
import 'package:smart_laundry_locker/core/theme/theme_provider.dart';

class _AislToastWidget extends StatelessWidget {
  final String msg;
  const _AislToastWidget({required this.msg});

  @override
  Widget build(BuildContext context) {
    IconData iconData = LucideIcons.info;
    Color iconColor = AISLShadcnTheme.navyPrimary;

    final lowerMsg = msg.toLowerCase();
    if (lowerMsg.contains('thành công') ||
        lowerMsg.contains('thành công!') ||
        lowerMsg.contains('đã ') ||
        lowerMsg.contains('xong')) {
      iconData = LucideIcons.circleCheckBig;
      iconColor = const Color(0xFF10B981);
    } else if (lowerMsg.contains('lỗi') ||
        lowerMsg.contains('thất bại') ||
        lowerMsg.contains('sai') ||
        lowerMsg.contains('không thể')) {
      iconData = LucideIcons.circleAlert;
      iconColor = const Color(0xFFEF4444);
    } else if (lowerMsg.contains('cảnh báo') || lowerMsg.contains('chú ý')) {
      iconData = LucideIcons.triangleAlert;
      iconColor = const Color(0xFFF59E0B);
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 50),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.85),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(iconData, color: iconColor, size: 20),
                const SizedBox(width: 12),
                Flexible(
                  child: Text(
                    msg,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AislLoadingWidget extends StatelessWidget {
  final String msg;
  const _AislLoadingWidget({required this.msg});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 40,
            width: 40,
            child: CircularProgressIndicator(
              strokeWidth: 4,
              strokeCap: StrokeCap.round,
              valueColor: AlwaysStoppedAnimation<Color>(
                AISLShadcnTheme.navyPrimary,
              ),
              backgroundColor: const Color(0xFF0A2342).withOpacity(0.15),
            ),
          ),
          if (msg.isNotEmpty) ...[
            const SizedBox(height: 20),
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

class _AislNotifyWidget extends StatelessWidget {
  final String msg;
  final IconData icon;
  final Color iconColor;
  const _AislNotifyWidget({
    required this.msg,
    required this.icon,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: IntrinsicHeight(
          child: Row(
            children: [
              Container(width: 6, color: iconColor),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: iconColor.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(icon, size: 20, color: iconColor),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          msg,
                          style: const TextStyle(
                            color: Colors.black87,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            height: 1.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase chỉ chạy trên Android/iOS. Web chưa được cấu hình
  // DefaultFirebaseOptions nên gọi vào sẽ ném lỗi đỏ "have not been configured
  // for web" — bỏ qua hẳn trên web để console sạch.
  if (!kIsWeb) {
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
      // Initialize Messaging Service
      await FirebaseMessagingService.instance.init();
    } catch (e) {
      debugPrint("Firebase init/messaging failed: $e");
    }
  }

  DioClient.instance.init();
  // Initialize token service from secure storage
  await TokenService.initializeFromStorage();

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
        ChangeNotifierProvider(
          create: (_) =>
              WalletProvider(apiClient: ApiClient())..getWalletBalance(),
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
      ],
      child: Builder(
        builder: (context) {
          final themeMode =
              context.watch<ThemeProvider>().themeMode;
          return ShadApp.router(
            title: 'Lockerly',
            routerConfig: AppRouter.router,
            theme: AISLShadcnTheme.lightTheme,
            darkTheme: AISLShadcnTheme.darkTheme,
            themeMode: themeMode,
            builder: (context, child) {
              return ScaffoldMessenger(
                  key: AppMessengerService.scaffoldMessengerKey,
                  child: FlutterSmartDialog.init(
                    toastBuilder: (String msg) => _AislToastWidget(msg: msg),
                    loadingBuilder: (String msg) => _AislLoadingWidget(msg: msg),
                    notifyStyle: FlutterSmartNotifyStyle(
                      successBuilder: (msg) => _AislNotifyWidget(
                        msg: msg,
                        icon: LucideIcons.circleCheckBig,
                        iconColor: const Color(0xFF10B981),
                      ),
                      failureBuilder: (msg) => _AislNotifyWidget(
                        msg: msg,
                        icon: LucideIcons.circleX,
                        iconColor: const Color(0xFFEF4444),
                      ),
                      warningBuilder: (msg) => _AislNotifyWidget(
                        msg: msg,
                        icon: LucideIcons.triangleAlert,
                        iconColor: const Color(0xFFF59E0B),
                      ),
                      alertBuilder: (msg) => _AislNotifyWidget(
                        msg: msg,
                        icon: LucideIcons.info,
                        iconColor: AISLShadcnTheme.navyPrimary,
                      ),
                      errorBuilder: (msg) => _AislNotifyWidget(
                        msg: msg,
                        icon: LucideIcons.octagonAlert,
                        iconColor: const Color(0xFFEF4444),
                      ),
                    ),
                )(context, child ?? const SizedBox.shrink()),
              );
            },
          );
        },
      ),
    );
  }
}
