import 'dart:io';

import 'package:flutter/material.dart';
import 'package:smart_laundry_locker/core/services/image_cache_manager.dart';
import 'package:smart_laundry_locker/shared/utils/avatar_url_helper.dart';
import 'package:smart_laundry_locker/shared/widgets/app_cached_image.dart';
import 'package:smart_laundry_locker/shared/widgets/user_ui_kit.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

/// Profile header widget with user information
class ProfileHeader extends StatelessWidget {
  const ProfileHeader({
    required this.user,
    super.key,
    this.onEditAvatar,
    this.onSaveAvatar,
    this.onCancelAvatar,
    this.avatarVersion = 0,
    this.localAvatarFile,
    this.isAvatarSyncing = false,
    this.showSaveAvatarButton = false,
  });
  final Map<String, dynamic> user;
  final VoidCallback? onEditAvatar;
  final VoidCallback? onSaveAvatar;
  final VoidCallback? onCancelAvatar;
  final int avatarVersion;
  final File? localAvatarFile;
  final bool isAvatarSyncing;
  final bool showSaveAvatarButton;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      padding: const EdgeInsets.all(26),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: AislBrand.brandGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AislBrand.navy.withValues(alpha: 0.30),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // Avatar section
          _buildAvatarSection(context),
          const SizedBox(height: 16),

          // Save avatar button (only when local file exists)
          if (showSaveAvatarButton && localAvatarFile != null)
            _buildSaveAvatarButton(context),
          if (showSaveAvatarButton && localAvatarFile != null)
            const SizedBox(height: 16),

          // User info section
          _buildUserInfoSection(context),
        ],
      ),
    );
  }

  Widget _buildAvatarSection(BuildContext context) {
    final userId = user['id']?.toString() ?? 'unknown';
    final rawAvatarUrl = user['avatar'] as String?;

    // Generate stable cache key
    final avatarCacheKey = ProfileImageCacheManager.getAvatarCacheKey(
      userId,
      avatarVersion,
    );

    // ✅ DEFENSE IN DEPTH: Validate avatar URL one more time at UI layer
    // Repository and AuthProvider should already normalize, but we add extra safety
    final validatedAvatarUrl = AvatarUrlHelper.validateAndNormalize(
      rawAvatarUrl,
    );

    // ✅ Generate versioned URL to bypass CDN/browser cache
    // Only add version if URL is valid (not null after validation)
    final versionedAvatarUrl =
        validatedAvatarUrl != null && validatedAvatarUrl.isNotEmpty
        ? (validatedAvatarUrl.contains('?')
              ? '$validatedAvatarUrl&v=$avatarVersion'
              : '$validatedAvatarUrl?v=$avatarVersion')
        : null;

    debugPrint('[ProfileHeader] Building avatar for user: $userId');
    debugPrint('[ProfileHeader] Avatar URL (raw): $rawAvatarUrl');
    debugPrint('[ProfileHeader] Avatar URL (validated): $validatedAvatarUrl');
    debugPrint('[ProfileHeader] Avatar URL (versioned): $versionedAvatarUrl');
    debugPrint('[ProfileHeader] Avatar Version: $avatarVersion');
    debugPrint('[ProfileHeader] Cache Key: $avatarCacheKey');

    return Stack(
      children: [
        // Avatar
        GestureDetector(
          onTap: (localAvatarFile == null && !isAvatarSyncing)
              ? onEditAvatar
              : null,
          child: ClipOval(
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                border: Border.all(color: Colors.white, width: 3),
              ),
              child: ClipOval(
                clipBehavior: Clip.hardEdge,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Base layer: Always render cached image or placeholder
                    // This ensures widget stays in tree during transitions
                    if (versionedAvatarUrl != null &&
                        versionedAvatarUrl.isNotEmpty)
                      AppCachedImage(
                        key: ValueKey(avatarCacheKey),
                        imageUrl: versionedAvatarUrl,
                        cacheManager: ProfileImageCacheManager.instance,
                        cacheKey: avatarCacheKey,
                        fit: BoxFit.cover,
                        fadeInDuration: Duration.zero,
                        fadeOutDuration: Duration.zero,
                        placeholderFadeInDuration: Duration.zero,
                        // ✅ FIX: Disable useOldImageOnUrlChange because we use Stack overlay
                        // Local preview acts as transition buffer, so we want immediate switch
                        // to new image when it's ready (not keep showing old image)
                        useOldImageOnUrlChange: false,
                        placeholder: (context, url) =>
                            _buildDefaultAvatar(context),
                        errorWidget: (context, url, error) =>
                            _buildDefaultAvatar(context),
                      )
                    else
                      _buildDefaultAvatar(context),
                    // Overlay layer: Local preview when available
                    if (localAvatarFile != null &&
                        localAvatarFile!.existsSync())
                      Image.file(
                        localAvatarFile!,
                        fit: BoxFit.cover,
                        width: 100,
                        height: 100,
                        filterQuality: FilterQuality.high,
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),

        // Cancel button (X icon) when local file exists
        if (localAvatarFile != null &&
            onCancelAvatar != null &&
            !isAvatarSyncing)
          Positioned(
            top: 0,
            right: 0,
            child: GestureDetector(
              onTap: onCancelAvatar,
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: ShadTheme.of(context).colorScheme.destructive,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: ShadTheme.of(context).colorScheme.card,
                    width: 2,
                  ),
                ),
                child: Icon(
                  LucideIcons.x,
                  size: 14,
                  color: ShadTheme.of(
                    context,
                  ).colorScheme.destructiveForeground,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSaveAvatarButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ShadButton.secondary(
        enabled: !isAvatarSyncing && onSaveAvatar != null,
        onPressed: isAvatarSyncing ? null : onSaveAvatar,
        backgroundColor: ShadTheme.of(context).colorScheme.accent,
        child: isAvatarSyncing
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        ShadTheme.of(context).colorScheme.foreground,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Đang đồng bộ...',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: ShadTheme.of(context).colorScheme.foreground,
                    ),
                  ),
                ],
              )
            : Text(
                'Lưu ảnh đại diện',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: ShadTheme.of(context).colorScheme.foreground,
                ),
              ),
      ),
    );
  }

  Widget _buildDefaultAvatar(BuildContext context) {
    // Get the first letter of the user's name
    final fullName = user['fullName']?.toString() ?? 'Người dùng';
    final firstLetter = fullName.isNotEmpty
        ? fullName.trim().substring(0, 1).toUpperCase()
        : 'N';

    return Container(
      width: 100,
      height: 100,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
      ),
      child: Center(
        child: Text(
          firstLetter,
          style: const TextStyle(
            fontFamily: 'Manrope',
            fontSize: 36,
            fontWeight: FontWeight.w700,
            color: AislBrand.navy,
          ),
        ),
      ),
    );
  }

  Widget _buildUserInfoSection(BuildContext context) {
    return Column(
      children: [
        // Full name
        Text(
          user['fullName']?.toString() ?? 'Người dùng',
          style: const TextStyle(
            fontFamily: 'Manrope',
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),

        // Email (only show if not null)
        if (user['email'] != null)
          Text(
            user['email'].toString(),
            style: const TextStyle(
              fontFamily: 'Manrope',
              fontSize: 14,
              color: Colors.white70,
            ),
            textAlign: TextAlign.center,
          ),
      ],
    );
  }
}
