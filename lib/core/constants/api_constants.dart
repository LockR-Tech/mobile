import 'package:flutter/foundation.dart';
import '../config/env_config.dart';

/// API constants for the Revoland app
class ApiConstants {
  // Base URLs
  static const String localBaseUrl = 'http://localhost:5094';
  static const String baseUrl = 'https://api.revoland.com';
  static const String devBaseUrl = 'http://localhost:5094';

  // Get base URL from environment
  static String get apiBaseUrl {
    final url = EnvConfig.apiBaseUrl;
    // Handle web platform where 10.0.2.2 (Android emulator localhost alias) doesn't work
    if (kIsWeb && url.contains('10.0.2.2')) {
      return url.replaceAll('10.0.2.2', 'localhost');
    }
    return url;
  }

  // Environment info for debugging
  static String get environmentInfo => 'API Base URL: $apiBaseUrl';

  // API Endpoints
  static const String authEndpoint = '/auth';
  static const String propertiesEndpoint = '/properties';
  static const String usersEndpoint = '/users';
  static const String favoritesEndpoint = '/favorites';
  static const String collectionsEndpoint = '/collection-properties';

  // Auth Endpoints
  static const String loginEndpoint = '/api/auth/login';
  static const String registerEndpoint = '/api/auth/register';
  static const String googleLoginEndpoint = '/api/auth/google-login';
  static const String refreshTokenEndpoint = '/api/auth/refresh';

  // OTP Endpoints (Profile linking)
  static const String otpLinkEndpoint = '/api/auth/link';
  static const String otpVerifyEndpoint = '/api/auth/verify-auth-link-otp';

  // OTP Endpoints (Auth flow)
  static const String verifyOtpEndpoint = '/api/auth/verify-otp';
  static const String requestOtpEndpoint = '/api/auth/request-otp';

  // Change Password Endpoint
  static const String changePasswordEndpoint = '/api/auth/change-password';

  // Orders Endpoints
  static const String ordersMyEndpoint = '/orders/me';
  static const String ordersActiveEndpoint = '/orders/my/active';
  static const String ordersFixedRentEndpoint = '/orders/locker/fixed-rent';

  // Properties Endpoints
  static const String searchPropertiesEndpoint = '$propertiesEndpoint/search';
  static const String propertyDetailEndpoint = propertiesEndpoint;
  static const String featuredPropertiesEndpoint =
      '$propertiesEndpoint/featured';
  static const String nearbyPropertiesEndpoint = '$propertiesEndpoint/nearby';

  // Collections Endpoints
  static const String mineCollectionsEndPoint = '$collectionsEndpoint/mine';

  // User Endpoints
  static const String userProfileEndpoint = '/api/users/profile';
  static const String updateProfileEndpoint = '/api/users/update-profile';
  static const String uploadAvatarEndpoint = '/api/users/update-avatar';
  static const String uploadCoverPhotoEndpoint =
      '/api/users/update-cover-photo';
  static const String uploadBannerEndpoint = '/api/users/profile/banner';
  static const String userFavoritesEndpoint = '/api/users/favorites';
  static const String roommateInfoEndpoint = '/api/users/me/roommate-info';

  // Views History Endpoints
  static const String viewsHistoryEndpoint = '/api/PropertyViewHistory';
  static const String viewsLogEndpoint = '/api/PropertyViewHistory';

  // Provinces/Locations Endpoints
  // TODO: Update with actual provinces API endpoint from backend
  static const String provincesEndpoint = '/api/provinces';
  static const String districtsEndpoint = '/api/provinces/districts';
  static const String wardsEndpoint = '/api/provinces/wards';

  // Headers
  static const String contentTypeHeader = 'Content-Type';
  static const String authorizationHeader = 'Authorization';
  static const String acceptHeader = 'Accept';

  // Content Types
  static const String jsonContentType = 'application/json';
  static const String multipartContentType = 'multipart/form-data';

  // Timeouts
  static const int connectTimeout = 30000; // 30 seconds
  static const int receiveTimeout = 30000; // 30 seconds
  static const int sendTimeout = 30000; // 30 seconds

  // Pagination
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;
}
