/// Application-wide constants
class AppConstants {
  AppConstants._(); // Private constructor to prevent instantiation

  /// Default avatar URL (empty string means use fallback UI)
  static const String defaultAvatarUrl = '';

  /// Default cover photo URL (empty string means use fallback UI)
  static const String defaultCoverPhotoUrl = '';

  /// Default local asset used when no banner image exists
  static const String defaultBannerAsset =
      'assets/icon/logo_revoland_black_169_nobg.png';

  /// Minimum valid URL length (https://a.co = 13 chars)
  static const int minValidUrlLength = 10;

  /// Avatar image constraints
  static const int avatarMaxSizeBytes = 1 * 1024 * 1024; // 1MB
  static const int avatarMaxWidth = 1024;
  static const int avatarMaxHeight = 1024;
  static const int avatarMinQuality = 20;
  static const int avatarDefaultQuality = 85;

  /// Cover photo constraints
  static const int coverMaxSizeBytes = 2 * 1024 * 1024; // 2MB
  static const int coverMaxWidth = 1920;
  static const int coverMaxHeight = 1080;

  /// Cache constants
  static const int avatarCacheStaleAfterDays = 90;
  static const int maxCachedImages = 500;
}
