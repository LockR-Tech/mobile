import 'package:smart_laundry_locker/core/network/dio_client.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenService {
  static const _storage = FlutterSecureStorage();
  static const _accessTokenKey = 'access_token';
  static const _refreshTokenKey = 'refresh_token';

  static final ValueNotifier<bool> authState = ValueNotifier<bool>(false);

  static Future<void> initializeFromStorage() async {
    try {
      final accessToken = await getAccessToken();
      if (accessToken != null && accessToken.isNotEmpty) {
        DioClient.instance.setAuthToken(accessToken);
        authState.value = true;
      } else {
        authState.value = false;
      }
    } catch (e) {
      // If corrupted, clear tokens to allow fresh login
      await clearTokens();
    }
  }

  static Future<void> saveTokens(
    String accessToken,
    String refreshToken,
  ) async {
    await Future.wait([
      _storage.write(key: _accessTokenKey, value: accessToken),
      _storage.write(key: _refreshTokenKey, value: refreshToken),
    ]);
    DioClient.instance.setAuthToken(accessToken);
    authState.value = true;
  }

  static Future<String?> getAccessToken() async {
    try {
      return await _storage.read(key: _accessTokenKey);
    } catch (e) {
      return null;
    }
  }

  static Future<String?> getRefreshToken() async {
    try {
      return await _storage.read(key: _refreshTokenKey);
    } catch (e) {
      return null;
    }
  }

  static Future<void> clearTokens() async {
    await Future.wait([
      _storage.delete(key: _accessTokenKey),
      _storage.delete(key: _refreshTokenKey),
      _storage.delete(key: 'is_courier_user'),
      _storage.delete(key: 'courier_mode'),
    ]);
    DioClient.instance.clearAuthToken();
    authState.value = false;
  }

  static Future<bool> isLoggedIn() async {
    final token = await getAccessToken();
    return token != null && token.isNotEmpty;
  }

  static Future<bool> hasToken() async {
    final token = await getAccessToken();
    return token != null && token.isNotEmpty;
  }

  static Future<List<String>> getCurrentRoles() async {
    final token = await getAccessToken();
    if (token == null || token.isEmpty) return const [];
    try {
      final parts = token.split('.');
      if (parts.length < 2) return const [];
      final payload = jsonDecode(
        utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
      );
      if (payload is! Map<String, dynamic>) return const [];

      print('DEBUG: Token Payload: $payload');

      final List<String> extractedRoles = [];

      final fromRoles = payload['roles'];
      if (fromRoles is List) {
        extractedRoles.addAll(fromRoles.map((e) => e.toString().toUpperCase()));
      }

      final realmAccess = payload['realm_access'];
      if (realmAccess is Map<String, dynamic> && realmAccess['roles'] is List) {
        extractedRoles.addAll(
          (realmAccess['roles'] as List).map((e) => e.toString().toUpperCase()),
        );
      }

      final resourceAccess = payload['resource_access'];
      if (resourceAccess is Map<String, dynamic>) {
        resourceAccess.forEach((client, value) {
          if (value is Map<String, dynamic> && value['roles'] is List) {
            extractedRoles.addAll(
              (value['roles'] as List).map((e) => e.toString().toUpperCase()),
            );
          }
        });
      }

      final uniqueRoles = extractedRoles.toSet().toList();
      print('DEBUG: Extracted Roles: $uniqueRoles');
      return uniqueRoles;
    } catch (_) {
      return const [];
    }
  }

  static Future<String?> getUserId() async {
    final token = await getAccessToken();
    if (token == null || token.isEmpty) {
      debugPrint('TokenService.getUserId: No access token found');
      return null;
    }
    try {
      final parts = token.split('.');
      if (parts.length < 2) {
        debugPrint('TokenService.getUserId: Invalid JWT format (no parts)');
        return null;
      }
      final payload = jsonDecode(
        utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
      );
      debugPrint('TokenService.getUserId: Payload: $payload');
      final userId = payload['sub']?.toString();
      debugPrint('TokenService.getUserId: Found sub=$userId');
      return userId;
    } catch (e) {
      debugPrint('TokenService.getUserId error: $e');
      return null;
    }
  }

  static Future<void> saveActiveDispatchId(String id) async {
    await _storage.write(key: 'active_dispatch_id', value: id);
  }

  static Future<String?> getActiveDispatchId() async {
    return await _storage.read(key: 'active_dispatch_id');
  }

  static Future<void> clearActiveDispatchId() async {
    await _storage.delete(key: 'active_dispatch_id');
  }
}
