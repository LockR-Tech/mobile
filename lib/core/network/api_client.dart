import 'dart:convert';
import 'package:smart_laundry_locker/core/network/dio_client.dart';
import 'package:smart_laundry_locker/core/services/token_service.dart';
import 'package:dio/dio.dart';

/// ApiClient: Wrapper around DioClient cho việc gọi API
/// Cung cấp các method tiện ích và xử lý error thống nhất.
class ApiClient {
  final DioClient _dioClient;
  bool _tokenLoaded = false;

  ApiClient({DioClient? dioClient})
    : _dioClient = dioClient ?? DioClient.instance {
    _loadTokenFromStorage();
  }

  Future<void> _loadTokenFromStorage() async {
    if (_tokenLoaded) return;
    final accessToken = await TokenService.getAccessToken();
    if (accessToken != null && accessToken.isNotEmpty) {
      setAuthToken(accessToken);
    }
    _tokenLoaded = true;
  }

  Future<void> _ensureTokenLoaded() async {
    if (!_tokenLoaded) {
      await _loadTokenFromStorage();
    }
  }

  Dio get _dio => _dioClient.dio;

  // ==================== HTTP Methods ====================

  /// GET request
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    await _ensureTokenLoaded();
    try {
      return await _dio.get<T>(
        path,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// POST request
  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    await _ensureTokenLoaded();
    try {
      return await _dio.post<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// PUT request
  Future<Response<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    await _ensureTokenLoaded();
    try {
      return await _dio.put<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// PATCH request
  Future<Response<T>> patch<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    await _ensureTokenLoaded();
    try {
      return await _dio.patch<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// DELETE request
  Future<Response<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    await _ensureTokenLoaded();
    try {
      return await _dio.delete<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  // ==================== Auth Methods ====================

  /// Set authorization token
  void setAuthToken(String token) {
    _dioClient.setAuthToken(token);
  }

  /// Clear authorization token
  void clearAuthToken() {
    _dioClient.clearAuthToken();
  }

  // ==================== Error Handling ====================

  /// Handle DioException và convert sang custom Exception
  Exception _handleDioError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return NetworkException('Kết nối timeout. Vui lòng thử lại.');

      case DioExceptionType.connectionError:
        return NetworkException(
          'Không thể kết nối đến server. Kiểm tra kết nối mạng.',
        );

      case DioExceptionType.badResponse:
        return _handleBadResponse(e.response);

      case DioExceptionType.cancel:
        return NetworkException('Request đã bị hủy.');

      default:
        return NetworkException(e.message ?? 'Đã xảy ra lỗi không xác định.');
    }
  }

  /// Handle bad response (4xx, 5xx)
  Exception _handleBadResponse(Response? response) {
    if (response == null) {
      return ServerException('Không có response từ server.');
    }

    final statusCode = response.statusCode ?? 0;
    var data = response.data;

    if (data is String) {
      try {
        data = jsonDecode(data);
      } catch (_) {}
    }

    String message = 'Đã xảy ra lỗi.';
    if (data is Map<String, dynamic>) {
      final msg = data['message'];
      if (msg is String) {
        message = msg;
      } else if (msg is List) {
        message = msg.map((item) => item.toString()).join(', ');
      } else if (msg != null) {
        message = msg.toString();
      } else {
        final errorMsg = data['error'];
        if (errorMsg is String) {
          message = errorMsg;
        } else if (errorMsg != null) {
          message = errorMsg.toString();
        }
      }
    } else if (data != null) {
      message = data.toString();
    }

    final cleanMessage = _cleanErrorMessage(message);

    switch (statusCode) {
      case 400:
        return ValidationException(cleanMessage);
      case 409:
        return ValidationException(cleanMessage);
      case 401:
        return AuthenticationException(
          'Phiên đăng nhập hết hạn. Vui lòng đăng nhập lại.',
        );
      case 403:
        return AuthorizationException(
          'Bạn không có quyền thực hiện hành động này.',
        );
      case 404:
        return NotFoundException(cleanMessage);
      case 422:
        return ValidationException(cleanMessage);
      case >= 500:
        final errorMessage =
            cleanMessage.isNotEmpty && cleanMessage != 'Đã xảy ra lỗi.'
            ? cleanMessage
            : 'Lỗi server. Vui lòng thử lại sau.';
        return ServerException(errorMessage);
      default:
        return ServerException(cleanMessage);
    }
  }

  String _cleanErrorMessage(String msg) {
    try {
      final trimmed = msg.trim();
      if (trimmed.startsWith('{') && trimmed.endsWith('}')) {
        final decoded = jsonDecode(trimmed);
        if (decoded is Map) {
          if (decoded.containsKey('message')) {
            final m = decoded['message'];
            if (m is String) return m;
            if (m is List) return m.join(', ');
          }
          if (decoded.containsKey('error')) {
            final e = decoded['error'];
            if (e is String) return e;
          }
        }
      }
    } catch (_) {}
    final regExp = RegExp(r'^\d+\s+[A-Z_]+:\s*', caseSensitive: false);
    return msg.replaceFirst(regExp, '').trim();
  }
}

// ==================== Custom Exceptions ====================

/// Server Exception: Lỗi từ server (5xx)
class ServerException implements Exception {
  final String message;
  ServerException(this.message);

  @override
  String toString() => 'ServerException: $message';
}

/// Network Exception: Lỗi kết nối mạng
class NetworkException implements Exception {
  final String message;
  NetworkException(this.message);

  @override
  String toString() => 'NetworkException: $message';
}

/// Validation Exception: Lỗi validate dữ liệu (400, 422)
class ValidationException implements Exception {
  final String message;
  ValidationException(this.message);

  @override
  String toString() => 'ValidationException: $message';
}

/// Authentication Exception: Lỗi xác thực (401)
class AuthenticationException implements Exception {
  final String message;
  AuthenticationException(this.message);

  @override
  String toString() => 'AuthenticationException: $message';
}

/// Authorization Exception: Lỗi phân quyền (403)
class AuthorizationException implements Exception {
  final String message;
  AuthorizationException(this.message);

  @override
  String toString() => 'AuthorizationException: $message';
}

/// NotFoundException: Không tìm thấy resource (404)
class NotFoundException implements Exception {
  final String message;
  NotFoundException(this.message);

  @override
  String toString() => 'NotFoundException: $message';
}
