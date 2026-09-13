import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

/// Custom cache manager for profile images with longer cache duration
/// Optimized for Zalo-like experience: persistent cache, survives app restarts
class ProfileImageCacheManager {
  static const key = 'revoland_profile_images_v2';

  // Singleton instance
  static final CacheManager instance = CacheManager(
    Config(
      key,
      stalePeriod: const Duration(days: 90), // Cache for 90 days - very long!
      maxNrOfCacheObjects: 500, // Max 500 images (support multi-user scenarios)
      repo: JsonCacheInfoRepository(databaseName: key),
      fileService: HttpFileService(),
    ),
  );

  /// FIX: Clear Flutter's in-memory image cache for a specific URL
  /// This is CRITICAL for ensuring new images are displayed immediately after upload.
  /// CachedNetworkImage uses both disk cache (flutter_cache_manager) and memory cache
  /// (PaintingBinding.instance.imageCache). We must clear BOTH for instant refresh.
  static void clearMemoryCacheForUrl(String imageUrl) {
    try {
      // Clear from Flutter's global image cache
      final imageCache = PaintingBinding.instance.imageCache;
      imageCache.evict(NetworkImage(imageUrl));
      debugPrint('[Cache] Cleared memory cache for: $imageUrl');
    } catch (e) {
      debugPrint('[Cache] Error clearing memory cache: $e');
    }
  }

  /// FIX: Clear memory cache for a versioned URL pattern
  /// Clears both old and new version URLs from memory
  static void clearMemoryCacheForVersionedUrl(
    String baseUrl,
    int oldVersion,
    int newVersion, {
    String versionParam = 'v',
  }) {
    try {
      final imageCache = PaintingBinding.instance.imageCache;

      // Clear old versioned URL
      final oldUrl = baseUrl.contains('?')
          ? '$baseUrl&$versionParam=$oldVersion'
          : '$baseUrl?$versionParam=$oldVersion';
      imageCache.evict(NetworkImage(oldUrl));

      // Clear new versioned URL (in case it was somehow cached)
      final newUrl = baseUrl.contains('?')
          ? '$baseUrl&$versionParam=$newVersion'
          : '$baseUrl?$versionParam=$newVersion';
      imageCache.evict(NetworkImage(newUrl));

      // Also clear base URL without version
      imageCache.evict(NetworkImage(baseUrl));

      debugPrint(
        '[Cache] Cleared memory cache for URLs: $oldUrl, $newUrl, $baseUrl',
      );
    } catch (e) {
      debugPrint('[Cache] Error clearing memory cache: $e');
    }
  }

  /// FIX: Clear ALL memory image cache - use after profile image update
  /// This ensures no stale images remain in memory
  static void clearAllMemoryCache() {
    try {
      final imageCache = PaintingBinding.instance.imageCache;
      imageCache.clear();
      imageCache.clearLiveImages();
      debugPrint('[Cache] Cleared ALL memory image cache');
    } catch (e) {
      debugPrint('[Cache] Error clearing all memory cache: $e');
    }
  }

  /// FIX: Evict specific cache key from CachedNetworkImage's internal cache
  static Future<void> evictFromCachedNetworkImage(String imageUrl) async {
    try {
      await CachedNetworkImage.evictFromCache(imageUrl);
      debugPrint('[Cache] Evicted from CachedNetworkImage: $imageUrl');
    } catch (e) {
      debugPrint('[Cache] Error evicting from CachedNetworkImage: $e');
    }
  }

  /// Generate stable cache key for user avatar
  /// Format: avatar_userId_version
  /// This ensures cache persists even if URL changes (e.g., with timestamps)
  static String getAvatarCacheKey(String userId, int version) {
    return 'avatar_${userId}_v$version';
  }

  /// Generate stable cache key for cover photo
  static String getCoverCacheKey(String userId, [int? version]) {
    return version != null ? 'cover_${userId}_v$version' : 'cover_$userId';
  }

  /// Preload/warmup avatar into cache
  static Future<void> warmupAvatar(
    String imageUrl,
    String userId,
    int version, {
    bool bypassCDNCache = true,
  }) async {
    try {
      final cacheKey = getAvatarCacheKey(userId, version);

      // Add cache busting to bypass CDN cache
      final urlWithVersion = bypassCDNCache && !imageUrl.contains('?v=')
          ? (imageUrl.contains('?')
                ? '$imageUrl&v=$version'
                : '$imageUrl?v=$version')
          : imageUrl;

      debugPrint('[Cache] Warming up avatar: $cacheKey from $urlWithVersion');
      await instance.downloadFile(urlWithVersion, key: cacheKey);
      debugPrint('[Cache] Warmup success: $cacheKey');
    } catch (e) {
      debugPrint('[Cache] Warmup error: $e');
      // Non-critical, don't throw
    }
  }

  /// Preload/warmup banner/cover into cache
  static Future<void> warmupBanner(
    String imageUrl,
    String userId,
    int version, {
    bool bypassCDNCache = true,
  }) async {
    try {
      final cacheKey = getCoverCacheKey(userId, version);

      // Add cache busting with 'bv=' (banner version) to bypass CDN cache
      final urlWithVersion = bypassCDNCache && !imageUrl.contains('?bv=')
          ? (imageUrl.contains('?')
                ? '$imageUrl&bv=$version'
                : '$imageUrl?bv=$version')
          : imageUrl;

      debugPrint('[Cache] Warming up banner: $cacheKey from $urlWithVersion');
      await instance.downloadFile(urlWithVersion, key: cacheKey);
      debugPrint('[Cache] Warmup success: $cacheKey');
    } catch (e) {
      debugPrint('[Cache] Warmup error: $e');
      // Non-critical, don't throw
    }
  }

  /// Clear only specific user's avatar cache
  static Future<void> clearUserAvatar(String userId, int oldVersion) async {
    try {
      final oldKey = getAvatarCacheKey(userId, oldVersion);
      debugPrint('[Cache] Clearing old avatar: $oldKey');
      await instance.removeFile(oldKey);
    } catch (e) {
      debugPrint('[Cache] Error clearing avatar: $e');
      // Ignore errors
    }
  }

  /// Clear only specific user's banner/cover cache
  static Future<void> clearUserBanner(String userId, int oldVersion) async {
    try {
      final oldKey = getCoverCacheKey(userId, oldVersion);
      debugPrint('[Cache] Clearing old banner: $oldKey');
      await instance.removeFile(oldKey);
    } catch (e) {
      debugPrint('[Cache] Error clearing banner: $e');
      // Ignore errors
    }
  }

  /// Clear all cache - use with caution!
  static Future<void> clearAllCache() async {
    debugPrint('[Cache] Clearing all cache');
    await instance.emptyCache();
  }
}
