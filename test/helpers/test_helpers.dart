import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_laundry_locker/core/network/api_client.dart';
import 'package:smart_laundry_locker/core/network/dio_client.dart';

export 'package:http_mock_adapter/http_mock_adapter.dart';

const kTestBaseUrl = 'http://test.local';

// ── For LockerOpsService (accepts Dio directly) ────────────────────────────

/// Creates a fresh [Dio] + [DioAdapter] pair.
/// Inject the returned [dio] into [LockerOpsService(dio: dio)].
({Dio dio, DioAdapter adapter}) createMockDio() {
  final dio = Dio(BaseOptions(baseUrl: kTestBaseUrl));
  final adapter = DioAdapter(dio: dio, matcher: const UrlRequestMatcher());
  return (dio: dio, adapter: adapter);
}

// ── For UserGatewayClient subclasses (accept ApiClient) ────────────────────

/// Ensures the DioClient singleton has a real Dio so TokenService callbacks
/// (saveTokens/clearTokens → setAuthToken/clearAuthToken) don't crash in tests.
void _ensureSingleton() => DioClient.instance.init(baseUrl: kTestBaseUrl);

/// Creates a fresh [ApiClient] backed by a mock [Dio] + [DioAdapter].
/// Use for: StoreService, UserOrderService, UserLockerService, etc.
({ApiClient apiClient, DioAdapter adapter}) createMockApiClient() {
  _ensureSingleton();
  FlutterSecureStorage.setMockInitialValues({});
  final dio = Dio(BaseOptions(baseUrl: kTestBaseUrl));
  final adapter = DioAdapter(dio: dio, matcher: const UrlRequestMatcher());
  final dioClient = DioClient.withDio(dio);
  return (apiClient: ApiClient(dioClient: dioClient), adapter: adapter);
}

/// Creates an [ApiClient] pre-seeded with a fake JWT (sub=[userId]).
/// Use when the service calls [currentUserId()] internally (e.g. createPayment).
({ApiClient apiClient, DioAdapter adapter}) createAuthenticatedApiClient({
  String userId = '1',
  List<String> roles = const ['CUSTOMER'],
}) {
  _ensureSingleton();
  final token = makeFakeJwt(sub: userId, roles: roles);
  FlutterSecureStorage.setMockInitialValues({'access_token': token});
  final dio = Dio(BaseOptions(baseUrl: kTestBaseUrl));
  final adapter = DioAdapter(dio: dio, matcher: const UrlRequestMatcher());
  final dioClient = DioClient.withDio(dio);
  return (apiClient: ApiClient(dioClient: dioClient), adapter: adapter);
}

// ── SharedPreferences (FavoriteStoresService) ──────────────────────────────

/// Initialises SharedPreferences with an empty in-memory store.
Future<void> mockSharedPreferences([Map<String, Object> initial = const {}]) async {
  SharedPreferences.setMockInitialValues(initial);
}

// ── Secure Storage ─────────────────────────────────────────────────────────

/// Standard mock for FlutterSecureStorage — call once in setUpAll.
void mockSecureStorage([Map<String, String> initial = const {}]) {
  FlutterSecureStorage.setMockInitialValues(initial);
}

// ── JWT helpers ────────────────────────────────────────────────────────────

/// Builds a structurally valid fake JWT.
/// The signature is not verified — only [sub] and [roles] claims matter.
String makeFakeJwt({String sub = '1', List<String> roles = const ['CUSTOMER']}) {
  String _b64(Map<String, dynamic> m) =>
      base64Url.encode(utf8.encode(json.encode(m)));

  final header = _b64({'alg': 'none', 'typ': 'JWT'});
  final payload = _b64({
    'sub': sub,
    'roles': roles,
    'tokenUse': 'access',
    'exp': 9999999999,
  });
  return '$header.$payload.fake_sig';
}

// ── Response envelope builders ─────────────────────────────────────────────

/// Wraps data in the backend success envelope.
Map<String, dynamic> apiOk(dynamic data, {String message = 'OK'}) => {
  'success': true,
  'code': 'SUCCESS',
  'message': message,
  'data': data,
  'errors': null,
};

/// Wraps a message in the error envelope.
Map<String, dynamic> apiError(String message, {int code = 400}) => {
  'success': false,
  'code': 'ERROR',
  'message': message,
  'data': null,
  'errors': [message],
};
