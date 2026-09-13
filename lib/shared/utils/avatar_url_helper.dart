import 'package:flutter/foundation.dart';

/// Avatar URL validation utility
///
/// CRITICAL: This helper ONLY validates URLs. It NEVER modifies or rewrites them.
/// The app MUST use the exact URL returned from the backend/server.
///
/// Valid Firebase Storage URL formats:
/// - https://storage.googleapis.com/<bucket>/<path>
/// - https://firebasestorage.googleapis.com/v0/b/<bucket>/o/<path>
///
/// DO NOT convert storage.googleapis.com to firebasestorage.app domains
/// unless the custom domain is actually configured on Firebase.
class AvatarUrlHelper {
  /// Validates avatar URL from backend WITHOUT modifying it
  ///
  /// Returns null if URL is invalid, otherwise returns the ORIGINAL URL unchanged
  ///
  /// Only filters out:
  /// - null values
  /// - "null" string literal
  /// - "undefined" string literal
  /// - Empty strings
  /// - Non-HTTP(S) URLs
  static String? validateAndNormalize(dynamic value) {
    // Handle null
    if (value == null) {
      debugPrint('[AvatarUrlHelper] Received null avatar');
      return null;
    }

    // Handle non-string types
    if (value is! String) {
      debugPrint(
        '[AvatarUrlHelper] Received non-string avatar: ${value.runtimeType}',
      );
      return null;
    }

    final url = value.trim();

    // Handle empty string
    if (url.isEmpty) {
      debugPrint('[AvatarUrlHelper] Received empty avatar URL');
      return null;
    }

    // Handle "null" or "undefined" string literals (backend bug)
    if (url == 'null' ||
        url == 'undefined' ||
        url == 'NULL' ||
        url == 'UNDEFINED') {
      debugPrint('[AvatarUrlHelper] Received invalid avatar literal: $url');
      return null;
    }

    // Validate URL format (must be HTTP or HTTPS)
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      debugPrint('[AvatarUrlHelper] Invalid avatar URL scheme: $url');
      return null;
    }

    // ✅ CRITICAL FIX: Return the ORIGINAL URL without modification
    // Do NOT rewrite domains. The backend knows the correct URL format.
    // Valid Firebase Storage URLs include:
    // - https://storage.googleapis.com/bucket-name/path
    // - https://firebasestorage.googleapis.com/v0/b/bucket/o/path

    // ✅ Removed verbose debug log - only log errors, not every valid URL
    // debugPrint('[AvatarUrlHelper] Valid URL (unchanged): $url');
    return url;
  }

  /// Validates avatar URL with default fallback
  ///
  /// Returns empty string if URL is invalid (for non-nullable contexts)
  /// Does NOT modify the URL - only validates it
  static String validateWithDefault(dynamic value, {String defaultValue = ''}) {
    return validateAndNormalize(value) ?? defaultValue;
  }

  /// Checks if URL is valid without normalizing
  static bool isValidUrl(dynamic value) {
    return validateAndNormalize(value) != null;
  }

  /// Batch validate multiple URLs
  static List<String?> validateBatch(List<dynamic> urls) {
    return urls.map(validateAndNormalize).toList();
  }
}
