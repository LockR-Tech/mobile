import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../network/auth_interceptor.dart';
import '../network/dio_client.dart';
import 'business_config.dart';

/// Nơi lưu last-known cấu hình để lần mở app sau hiển thị ngay giá trị cũ.
abstract class BusinessConfigStore {
  Future<String?> read();
  Future<void> write(String value);
}

/// Lưu bằng `shared_preferences` (không phải dữ liệu nhạy cảm).
class SharedPreferencesBusinessConfigStore implements BusinessConfigStore {
  const SharedPreferencesBusinessConfigStore();

  static const _key = 'business_config.v1';

  @override
  Future<String?> read() async =>
      (await SharedPreferences.getInstance()).getString(_key);

  @override
  Future<void> write(String value) async =>
      (await SharedPreferences.getInstance()).setString(_key, value);
}

/// Tải quy tắc nghiệp vụ công khai (`GET /api/settings/{scope}/public`).
///
/// - Các scope tải song song, timeout ngắn; scope lỗi (404/5xx/timeout) giữ
///   giá trị đã biết (last-known hoặc mặc định) — app không bao giờ bị chặn.
/// - Cache trong bộ nhớ với TTL; [refresh] trong TTL không gọi mạng.
/// - Lưu last-known vào [BusinessConfigStore] để lần mở sau dùng ngay.
class BusinessConfigService {
  BusinessConfigService({
    Dio? dio,
    BusinessConfigStore? store,
    this.ttl = const Duration(minutes: 5),
    this.timeout = const Duration(seconds: 6),
    this.failureBackoff = const Duration(seconds: 30),
    DateTime Function()? clock,
    BusinessConfig? initial,
  }) : _dio = dio,
       _store = store ?? const SharedPreferencesBusinessConfigStore(),
       _clock = clock ?? DateTime.now,
       _notifier = ValueNotifier(initial ?? BusinessConfig.defaults());

  static BusinessConfigService _instance = BusinessConfigService();

  /// Instance dùng chung toàn app.
  static BusinessConfigService get instance => _instance;

  @visibleForTesting
  static set instance(BusinessConfigService service) => _instance = service;

  final Dio? _dio;
  final BusinessConfigStore _store;
  final DateTime Function() _clock;
  final ValueNotifier<BusinessConfig> _notifier;

  /// Thời gian cấu hình vừa tải được coi là còn mới.
  final Duration ttl;

  /// Timeout cho mỗi request scope.
  final Duration timeout;

  /// Sau khi mọi scope đều lỗi, chờ khoảng này mới thử lại (trừ khi `force`).
  final Duration failureBackoff;

  /// Dữ liệu `/public` thô theo scope — nguồn để dựng [current].
  final Map<String, Map<String, dynamic>> _rawScopes = {};

  DateTime? _fetchedAt;
  DateTime? _failedAt;
  Future<BusinessConfig>? _inFlight;
  Future<void>? _restoring;

  /// Cấu hình hiện tại (luôn có giá trị: mặc định → last-known → server).
  BusinessConfig get current => _notifier.value;

  /// Lắng nghe thay đổi cấu hình (dùng cho `ValueListenableBuilder`).
  ValueListenable<BusinessConfig> get listenable => _notifier;

  /// Lần tải thành công gần nhất (ít nhất một scope).
  DateTime? get fetchedAt => _fetchedAt;

  bool get isFresh {
    final at = _fetchedAt;
    return at != null && _clock().difference(at) < ttl;
  }

  /// Gọi khi khởi động app: khôi phục last-known rồi làm mới nền.
  /// Không cần `await` — không bao giờ ném lỗi.
  Future<void> init() async {
    await restore();
    await refresh();
  }

  /// Khôi phục cấu hình đã lưu (chỉ chạy một lần).
  Future<void> restore() => _restoring ??= _restore();

  Future<void> _restore() async {
    try {
      final saved = await _store.read();
      if (saved == null || saved.isEmpty) return;
      final decoded = jsonDecode(saved);
      final scopes = decoded is Map ? decoded['scopes'] : null;
      if (scopes is! Map) return;
      for (final entry in scopes.entries) {
        final key = entry.key;
        final value = entry.value;
        // Không đè scope đã tải được từ server trong lúc đang khôi phục.
        if (key is String && value is Map && !_rawScopes.containsKey(key)) {
          _rawScopes[key] = Map<String, dynamic>.from(value);
        }
      }
      _publish();
    } catch (e) {
      debugPrint('[BusinessConfig] restore failed: $e');
    }
  }

  /// Làm mới từ server. Trong TTL (hoặc đang backoff sau lỗi) thì trả ngay
  /// [current], trừ khi [force]. Các lời gọi đồng thời dùng chung một request.
  Future<BusinessConfig> refresh({bool force = false}) {
    if (!force) {
      if (isFresh) return Future.value(current);
      final failedAt = _failedAt;
      if (failedAt != null && _clock().difference(failedAt) < failureBackoff) {
        return Future.value(current);
      }
    }
    return _inFlight ??= _fetch().whenComplete(() => _inFlight = null);
  }

  Future<BusinessConfig> _fetch() async {
    final Dio dio;
    try {
      dio = _dio ?? DioClient.instance.dio;
    } catch (e) {
      // DioClient chưa init (vd. test) — giữ nguyên cấu hình hiện có.
      _failedAt = _clock();
      return current;
    }

    final results = await Future.wait(
      BusinessConfig.scopes.map((scope) => _fetchScope(dio, scope)),
    );

    var anySuccess = false;
    for (var i = 0; i < BusinessConfig.scopes.length; i++) {
      final data = results[i];
      if (data == null) continue;
      anySuccess = true;
      _rawScopes[BusinessConfig.scopes[i]] = data;
    }

    if (!anySuccess) {
      _failedAt = _clock();
      return current;
    }

    _fetchedAt = _clock();
    _failedAt = null;
    _publish();
    unawaited(_persist());
    return current;
  }

  Future<Map<String, dynamic>?> _fetchScope(Dio dio, String scope) async {
    try {
      final res = await dio
          .get<dynamic>(
            '/api/settings/$scope/public',
            options: Options(
              receiveTimeout: timeout,
              extra: const {AuthInterceptor.skipAuthRefresh: true},
            ),
          )
          .timeout(timeout);
      final body = res.data;
      if (body is! Map) return null;
      if (body['success'] == false) return null;
      final data = body['data'];
      return data is Map ? Map<String, dynamic>.from(data) : null;
    } catch (e) {
      final reason = e is DioException
          ? (e.response?.statusCode ?? e.type.name)
          : e.runtimeType;
      debugPrint('[BusinessConfig] scope "$scope" unavailable ($reason)');
      return null;
    }
  }

  void _publish() {
    _notifier.value = BusinessConfig.fromPublicMaps(
      order: _rawScopes['order'],
      payment: _rawScopes['payment'],
      locker: _rawScopes['locker'],
      loyalty: _rawScopes['loyalty'],
      store: _rawScopes['store'],
    );
  }

  Future<void> _persist() async {
    try {
      await _store.write(
        jsonEncode({
          'savedAt': _fetchedAt?.toIso8601String(),
          'scopes': _rawScopes,
        }),
      );
    } catch (e) {
      debugPrint('[BusinessConfig] persist failed: $e');
    }
  }
}
