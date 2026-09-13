import 'package:smart_laundry_locker/core/network/dio_client.dart';
import 'package:smart_laundry_locker/core/routing/app_router.dart';
import 'package:smart_laundry_locker/core/services/token_service.dart';
import 'package:smart_laundry_locker/core/constants/api_constants.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';

/// Interceptor to handle authentication errors (401 Unauthorized).
///
/// On a 401 the access token has usually just expired. Instead of logging the
/// user out immediately we try to silently refresh the access token using the
/// stored refresh token, then retry the original request. We only force a
/// logout when there is no refresh token or the refresh itself fails.
class AuthInterceptor extends Interceptor {
  /// Shared in-flight refresh so concurrent 401s (the app fires several
  /// requests on startup) trigger only ONE refresh. The backend rotates the
  /// refresh token on every use, so a second concurrent refresh with the old
  /// token would fail.
  static Future<bool>? _refreshing;

  // Marks a request we have already retried so we never loop on it.
  static const _retriedFlag = '__auth_retried__';

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final requestOptions = err.requestOptions;
    final isAuthFailure = err.response?.statusCode == 401;
    final alreadyRetried = requestOptions.extra[_retriedFlag] == true;
    final isRefreshCall =
        requestOptions.path.contains('/api/auth/refresh-token');

    if (!isAuthFailure || alreadyRetried || isRefreshCall) {
      return handler.next(err);
    }

    final refreshed =
        await (_refreshing ??=
            _refreshAccessToken().whenComplete(() => _refreshing = null));

    if (!refreshed) {
      await _forceLogout();
      return handler.next(err);
    }

    // Retry the original request with the new access token.
    try {
      final newToken = await TokenService.getAccessToken();
      final response = await DioClient.instance.dio.request<dynamic>(
        requestOptions.path,
        data: requestOptions.data,
        queryParameters: requestOptions.queryParameters,
        options: Options(
          method: requestOptions.method,
          headers: {
            ...requestOptions.headers,
            if (newToken != null && newToken.isNotEmpty)
              'Authorization': 'Bearer $newToken',
          },
          responseType: requestOptions.responseType,
          contentType: requestOptions.contentType,
          extra: {...requestOptions.extra, _retriedFlag: true},
        ),
      );
      return handler.resolve(response);
    } catch (_) {
      // Retry failed for some other reason: surface the original error.
      return handler.next(err);
    }
  }

  /// Calls the backend refresh endpoint using a clean Dio (no AuthInterceptor)
  /// so the expired access token isn't attached and we don't recurse.
  /// Returns true and persists the new tokens on success.
  Future<bool> _refreshAccessToken() async {
    try {
      final refreshToken = await TokenService.getRefreshToken();
      if (refreshToken == null || refreshToken.isEmpty) return false;

      final dio = Dio(
        BaseOptions(
          baseUrl: ApiConstants.apiBaseUrl,
          connectTimeout: const Duration(seconds: 20),
          receiveTimeout: const Duration(seconds: 20),
          headers: const {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        ),
      );

      final res = await dio.post<dynamic>(
        '/api/auth/refresh-token',
        data: {'refreshToken': refreshToken},
      );

      final body = res.data;
      final Map? data = (body is Map && body['data'] is Map)
          ? body['data'] as Map
          : (body is Map ? body : null);
      if (data == null) return false;

      final newAccess = data['accessToken']?.toString();
      final newRefresh = data['refreshToken']?.toString();
      if (newAccess == null || newAccess.isEmpty) return false;

      await TokenService.saveTokens(
        newAccess,
        (newRefresh != null && newRefresh.isNotEmpty)
            ? newRefresh
            : refreshToken,
      );
      debugPrint('AuthInterceptor: access token refreshed successfully.');
      return true;
    } catch (e) {
      debugPrint('AuthInterceptor: token refresh failed: $e');
      return false;
    }
  }

  Future<void> _forceLogout() async {
    debugPrint('AuthInterceptor: cannot refresh, logging out.');
    await TokenService.clearTokens();
    DioClient.instance.clearAuthToken();
    SmartDialog.showToast('Phiên đăng nhập hết hạn. Vui lòng đăng nhập lại.');
    AppRouter.router.go(AppRouter.onboarding);
  }
}
