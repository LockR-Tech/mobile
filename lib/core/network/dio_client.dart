import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';

import '../constants/api_constants.dart';
import 'auth_interceptor.dart';

/// A singleton wrapper around Dio for making HTTP requests.
class DioClient {
  DioClient._();
  static final DioClient instance = DioClient._();

  /// Test-only: creates a DioClient backed by the given [dio] (already configured).
  @visibleForTesting
  DioClient.withDio(Dio dio) {
    _dio = dio;
    _initialized = true;
  }

  late final Dio _dio;

  bool _initialized = false;

  /// Initialize the Dio client with base configuration from EnvConfig.
  void init({
    String? baseUrl,
    Duration connectTimeout = const Duration(seconds: 30),
    Duration receiveTimeout = const Duration(seconds: 30),
    Duration sendTimeout = const Duration(seconds: 30),
  }) {
    if (_initialized) return;

    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl ?? ApiConstants.apiBaseUrl,
        connectTimeout: connectTimeout,
        receiveTimeout: receiveTimeout,
        sendTimeout: sendTimeout,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    // Add pretty logger only in debug mode.
    // Chỉ log dòng request + lỗi; KHÔNG in header/body để tránh đổ token và
    // dữ liệu nhạy cảm/không cần thiết ra console (yêu cầu của user).
    if (kDebugMode) {
      _dio.interceptors.add(
        PrettyDioLogger(
          request: true,
          requestHeader: false,
          requestBody: false,
          responseBody: false,
          responseHeader: false,
          error: true,
          compact: true,
          maxWidth: 90,
        ),
      );
    }

    // Add Auth Interceptor
    _dio.interceptors.add(AuthInterceptor());

    _initialized = true;
  }

  /// Get the Dio instance.
  Dio get dio {
    assert(_initialized, 'DioClient must be initialized before use');
    return _dio;
  }

  /// Set authorization token.
  void setAuthToken(String token) {
    _dio.options.headers['Authorization'] = 'Bearer $token';
  }

  /// Remove authorization token.
  void clearAuthToken() {
    _dio.options.headers.remove('Authorization');
  }

  /// Add a custom interceptor.
  void addInterceptor(Interceptor interceptor) {
    _dio.interceptors.add(interceptor);
  }
}
