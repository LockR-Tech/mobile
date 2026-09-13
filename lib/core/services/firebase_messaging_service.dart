import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_laundry_locker/core/network/api_client.dart';
import 'package:smart_laundry_locker/core/routing/app_router.dart';
import 'package:smart_laundry_locker/features/notifications/domain/entities/delivery_notification.dart';
import 'package:go_router/go_router.dart';

/// Top-level background message handler
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // If you're going to use other Firebase services in the background, such as Firestore,
  // make sure you call `initializeApp` before using other Firebase services.
  debugPrint("Handling a background message: ${message.messageId}");
}

class FirebaseMessagingService {
  FirebaseMessagingService._();
  static final FirebaseMessagingService instance = FirebaseMessagingService._();

  /// Push cập nhật chuyến giao drone cho customer. Giữ các type cũ trong thời
  /// gian chuyển contract; type chuẩn mới dùng một event cho mọi stage.
  static const Set<String> droneDeliveryTypes = {
    'DRONE_DELIVERY_STATUS_CHANGED',
    'drone_dispatched',
    'drone_approaching',
    'drone_arrived',
    'drone_delivered',
    'drone_delayed',
    'drone_failed',
  };

  static const Set<String> maintenanceDroneTypes = {'DRONE_ORDER_CREATED'};

  static bool _isDroneDeliveryType(Object? type) =>
      type is String && droneDeliveryTypes.contains(type);

  static bool _isMaintenanceDroneType(Object? type) =>
      type is String && maintenanceDroneTypes.contains(type);

  FirebaseMessaging get _firebaseMessaging => FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  final StreamController<RemoteMessage> _messageStreamController =
      StreamController<RemoteMessage>.broadcast();
  Stream<RemoteMessage> get onMessageReceived =>
      _messageStreamController.stream;

  bool _initialized = false;

  /// Lưu lại ApiClient (sau khi đăng nhập) để có thể tự đăng ký lại token khi
  /// FCM xoay vòng token (onTokenRefresh) mà không cần truyền lại từ UI.
  ApiClient? _apiClient;

  Future<void> init() async {
    if (_initialized) return;

    // 1. Initialize local notifications
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
          requestAlertPermission: false, // handled below via requestPermission
          requestBadgePermission: false,
          requestSoundPermission: false,
        );
    const InitializationSettings initializationSettings =
        InitializationSettings(
          android: initializationSettingsAndroid,
          iOS: initializationSettingsIOS,
        );

    await _localNotificationsPlugin.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Bấm vào banner local (lúc app foreground): parse JSON payload rồi
        // deep-link như khi bấm noti hệ thống.
        debugPrint('Notification tapped: ${response.payload}');
        final raw = response.payload;
        if (raw == null || raw.isEmpty) return;
        try {
          final data = jsonDecode(raw);
          if (data is Map) {
            _handleTapData(Map<String, dynamic>.from(data));
          }
        } catch (e) {
          debugPrint('Cannot parse notification payload: $e');
        }
      },
    );

    // Create Android Notification Channel
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'aisl_high_importance_channel',
      'High Importance Notifications',
      description: 'This channel is used for important notifications.',
      importance: Importance.max,
    );

    await _localNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);

    // Request Android 13+ notification permission explicitly
    await _localNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();

    // 2. Request permissions (FCM)
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    debugPrint('User granted permission: ${settings.authorizationStatus}');

    // iOS: Allow FCM to show banners while app is in foreground
    await FirebaseMessaging.instance
        .setForegroundNotificationPresentationOptions(
          alert: true,
          badge: true,
          sound: true,
        );

    // 3. Set the background messaging handler early on, as a named top-level function
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // 4. Setup foreground messaging listeners
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // 5. Handle any interaction when app is in background or terminated
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

    // 6. Check if app was opened via a notification when terminated
    final initialMessage = await _firebaseMessaging.getInitialMessage();
    if (initialMessage != null) {
      _handleMessageOpenedApp(initialMessage);
    }

    // 7. Xử lý token bị xoay vòng (refresh): đăng ký lại token mới lên backend
    //    để thiết bị không bị "mất" khỏi danh sách nhận noti.
    _firebaseMessaging.onTokenRefresh.listen(_onTokenRefresh);

    _initialized = true;
  }

  /// Get the device FCM token (useful for sending to your backend to register this device)
  Future<String?> getToken() async {
    try {
      String? token = await _firebaseMessaging.getToken();
      debugPrint("FCM Token: $token");
      return token;
    } catch (e) {
      debugPrint("Error getting FCM token: $e");
      return null;
    }
  }

  /// Sync device token to backend using general API client.
  /// Lưu lại [apiClient] để dùng cho onTokenRefresh về sau.
  Future<void> updateBackendDeviceToken(ApiClient apiClient) async {
    _apiClient = apiClient;
    final token = await getToken();
    if (token != null) {
      await _registerToken(token);
    }
  }

  /// Khi FCM xoay vòng token: đăng ký lại token mới (nếu đã có ApiClient sau
  /// đăng nhập).
  void _onTokenRefresh(String token) {
    debugPrint("FCM token refreshed");
    if (_apiClient != null) {
      unawaited(_registerToken(token));
    }
  }

  /// Gửi token (kèm deviceType/deviceId ổn định) lên backend để đăng ký nhận
  /// noti cho user hiện tại (backend lấy userId từ JWT).
  Future<void> _registerToken(String token) async {
    final apiClient = _apiClient;
    if (apiClient == null) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      String? deviceId = prefs.getString('aisl_app_device_id');
      if (deviceId == null) {
        deviceId =
            'DEV-${DateTime.now().millisecondsSinceEpoch}-${Random().nextInt(99999)}';
        await prefs.setString('aisl_app_device_id', deviceId);
      }

      final String platform = defaultTargetPlatform == TargetPlatform.iOS
          ? 'IOS'
          : 'ANDROID';

      final response = await apiClient.post(
        '/api/notifications/fcm-tokens',
        data: {'token': token, 'deviceType': platform, 'deviceId': deviceId},
      );
      debugPrint(
        "FCM Token successfully registered with backend: ${response.statusCode}",
      );
    } catch (e) {
      debugPrint("Failed to update device token on backend: $e");
    }
  }

  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('Got a message whilst in the foreground!');
    debugPrint('Message data: ${message.data}');

    if (message.notification != null) {
      debugPrint(
        'Message also contained a notification: ${message.notification}',
      );
    }

    final type = message.data['type']?.toString();
    final delivery = DeliveryNotification.fromData(message.data);

    // Push to stream so listeners (like NotificationProvider) can refresh
    _messageStreamController.add(message);

    // Always show a local notification banner (handles both notification+data
    // messages and pure data-only messages from the backend)
    _showLocalNotification(message);

    if (!_isDroneDeliveryType(type) &&
        !_isMaintenanceDroneType(type) &&
        delivery == null) {
      // Noti giao hàng (kể cả drone_*) đã hiển thị banner local ở trên rồi ->
      // không toast trùng. Các noti khác: fallback toast tiêu đề.
      final title =
          message.notification?.title ??
          message.data['title'] as String? ??
          'Thông báo mới';
      SmartDialog.showToast(title);
    }
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
    // Với noti giao hàng (data-only), lấy title/body theo status nếu thiếu.
    final delivery = DeliveryNotification.fromData(message.data);

    // Prefer the FCM notification object; fall back to data fields
    // (data-only messages from the backend will not have a notification object)
    final title =
        message.notification?.title ??
        message.data['title'] as String? ??
        delivery?.displayTitle ??
        'Thông báo';
    final body =
        message.notification?.body ??
        message.data['content'] as String? ??
        message.data['body'] as String? ??
        delivery?.displayBody ??
        '';

    if (title.isEmpty && body.isEmpty) return;

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'aisl_high_importance_channel',
          'High Importance Notifications',
          channelDescription:
              'This channel is used for important notifications.',
          importance: Importance.max,
          priority: Priority.high,
          showWhen: true,
          icon: '@mipmap/ic_launcher',
          playSound: true,
          enableVibration: true,
        );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotificationsPlugin.show(
      id: message.hashCode,
      title: title,
      body: body,
      notificationDetails: platformDetails,
      // Payload dạng JSON để khi bấm vào banner foreground có thể parse lại
      // data (orderId/status...) và deep-link đúng màn.
      payload: jsonEncode(message.data),
    );
  }

  void _handleMessageOpenedApp(RemoteMessage message) {
    debugPrint("Message opened app: ${message.data}");
    _handleTapData(message.data);
  }

  /// Điều hướng khi người dùng bấm vào noti (background/terminated qua
  /// onMessageOpenedApp/getInitialMessage, hoặc foreground qua local-notif).
  ///
  /// Ưu tiên: đơn drone mới -> hàng đợi MAINTENANCE; cập nhật chuyến drone ->
  /// timeline customer; noti giao hàng khác -> chi tiết đơn; còn lại -> Thông báo.
  void _handleTapData(Map<String, dynamic> data) {
    final type = data['type']?.toString();
    final delivery = DeliveryNotification.fromData(data);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final context = AppRouter.navigatorKey.currentContext;
      if (context == null) return;

      if (_isMaintenanceDroneType(type)) {
        context.go(AppRouter.maintenanceHome);
      } else if (_isDroneDeliveryType(type)) {
        final orderId = data['orderId']?.toString() ?? '';
        context.go(AppRouter.droneDeliveryTracking, extra: orderId);
      } else if (delivery != null) {
        // Deep-link tới chi tiết đơn theo orderId (route nhận String orderId).
        context.push(AppRouter.orderDetail, extra: delivery.orderId);
      } else {
        context.go(AppRouter.notifications);
      }
    });
  }
}
