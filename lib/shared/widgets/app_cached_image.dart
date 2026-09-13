import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

/// Lightweight wrapper around CachedNetworkImage with optional cache controls.
///
/// Used across the app to ensure a single place for image loading behavior,
/// making it easy to tweak fading, cache keys, and placeholders.
class AppCachedImage extends StatelessWidget {
  final String imageUrl;
  final BoxFit? fit;
  final double? width;
  final double? height;
  final Widget Function(BuildContext, String)? placeholder;
  final Widget Function(BuildContext, String, Object)? errorWidget;
  final CacheManager? cacheManager;
  final String? cacheKey;
  final Duration? fadeInDuration;
  final Duration? fadeOutDuration;
  final Duration? placeholderFadeInDuration;
  final Map<String, String>? httpHeaders;
  final Color? color;
  final BlendMode? colorBlendMode;
  final FilterQuality filterQuality;
  final Alignment alignment;
  final ImageRepeat repeat;
  final int? memCacheWidth;
  final int? memCacheHeight;
  final int? maxWidthDiskCache;
  final int? maxHeightDiskCache;

  /// When true, keeps showing the old image while the new URL is loading.
  /// This prevents flicker when switching between image versions.
  /// CRITICAL for smooth avatar/cover photo transitions after upload.
  final bool useOldImageOnUrlChange;

  const AppCachedImage({
    super.key,
    required this.imageUrl,
    this.fit,
    this.width,
    this.height,
    this.placeholder,
    this.errorWidget,
    this.cacheManager,
    this.cacheKey,
    this.fadeInDuration,
    this.fadeOutDuration,
    this.placeholderFadeInDuration,
    this.httpHeaders,
    this.color,
    this.colorBlendMode,
    this.filterQuality = FilterQuality.low,
    this.alignment = Alignment.center,
    this.repeat = ImageRepeat.noRepeat,
    this.memCacheWidth,
    this.memCacheHeight,
    this.maxWidthDiskCache,
    this.maxHeightDiskCache,
    this.useOldImageOnUrlChange = false,
  });

  @override
  Widget build(BuildContext context) {
    // Validate URL to prevent crashes with invalid URIs (e.g. file:///string)
    // This ensures we don't pass malformed URLs to CachedNetworkImage
    final uri = Uri.tryParse(imageUrl);
    final isValid =
        uri != null &&
        uri.hasScheme &&
        (uri.scheme == 'http' || uri.scheme == 'https') &&
        uri.hasAuthority &&
        uri.host.isNotEmpty;

    if (!isValid) {
      if (errorWidget != null) {
        return errorWidget!(context, imageUrl, 'Invalid URL');
      }
      return placeholder != null
          ? placeholder!(context, imageUrl)
          : const SizedBox();
    }

    return CachedNetworkImage(
      imageUrl: imageUrl,
      cacheManager: cacheManager,
      cacheKey: cacheKey,
      fit: fit,
      width: width,
      height: height,
      placeholder: placeholder,
      errorWidget: errorWidget,
      fadeInDuration: fadeInDuration ?? const Duration(milliseconds: 300),
      fadeOutDuration: fadeOutDuration ?? const Duration(milliseconds: 300),
      placeholderFadeInDuration: placeholderFadeInDuration ?? Duration.zero,
      httpHeaders: httpHeaders,
      color: color,
      colorBlendMode: colorBlendMode,
      filterQuality: filterQuality,
      alignment: alignment,
      repeat: repeat,
      memCacheWidth: memCacheWidth,
      memCacheHeight: memCacheHeight,
      maxWidthDiskCache: maxWidthDiskCache,
      maxHeightDiskCache: maxHeightDiskCache,
      useOldImageOnUrlChange: useOldImageOnUrlChange,
    );
  }
}

/// Builder-style cached image for advanced use-cases.
class AppCachedImageBuilder extends StatelessWidget {
  final String imageUrl;
  final Widget Function(BuildContext, ImageProvider) imageBuilder;
  final Widget Function(BuildContext, String)? placeholder;
  final Widget Function(BuildContext, String, Object)? errorWidget;
  final CacheManager? cacheManager;
  final String? cacheKey;
  final Map<String, String>? httpHeaders;

  const AppCachedImageBuilder({
    super.key,
    required this.imageUrl,
    required this.imageBuilder,
    this.placeholder,
    this.errorWidget,
    this.cacheManager,
    this.cacheKey,
    this.httpHeaders,
  });

  @override
  Widget build(BuildContext context) {
    return CachedNetworkImage(
      imageUrl: imageUrl,
      cacheManager: cacheManager,
      cacheKey: cacheKey,
      httpHeaders: httpHeaders,
      imageBuilder: (context, provider) => imageBuilder(context, provider),
      placeholder: placeholder,
      errorWidget: errorWidget,
    );
  }
}

/// Circular avatar that falls back to initials when network image is absent.
class ProfileAvatar extends StatelessWidget {
  final String? imageUrl;
  final String userId;
  final int avatarVersion;
  final double size;
  final String? fallbackText;
  final CacheManager? cacheManager;
  final Color? backgroundColor;
  final Color? textColor;

  const ProfileAvatar({
    super.key,
    this.imageUrl,
    required this.userId,
    this.avatarVersion = 0,
    this.size = 100,
    this.fallbackText,
    this.cacheManager,
    this.backgroundColor,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    // Generate cache key for avatar
    final cacheKey = 'avatar_${userId}_v$avatarVersion';

    if (imageUrl == null || imageUrl!.isEmpty) {
      return _buildFallback(context);
    }

    return AppCachedImage(
      imageUrl: imageUrl!,
      cacheManager: cacheManager,
      cacheKey: cacheKey,
      width: size,
      height: size,
      fit: BoxFit.cover,
      fadeInDuration: Duration.zero,
      fadeOutDuration: Duration.zero,
      placeholderFadeInDuration: Duration.zero,
      placeholder: (context, url) => _buildFallback(context),
      errorWidget: (context, url, error) => _buildFallback(context),
    );
  }

  Widget _buildFallback(BuildContext context) {
    final firstLetter = (fallbackText?.isNotEmpty ?? false)
        ? fallbackText!.trim().substring(0, 1).toUpperCase()
        : 'U';

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: backgroundColor ?? Colors.grey[800],
      ),
      child: Center(
        child: Text(
          firstLetter,
          style: TextStyle(
            fontSize: size * 0.4,
            fontWeight: FontWeight.w600,
            color: textColor ?? Colors.white,
          ),
        ),
      ),
    );
  }
}
