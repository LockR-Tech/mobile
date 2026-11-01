import 'dart:io';

import 'package:flutter/material.dart';
import 'package:smart_laundry_locker/core/services/image_cache_manager.dart';
import 'package:smart_laundry_locker/shared/utils/avatar_url_helper.dart';
import 'package:smart_laundry_locker/shared/widgets/app_cached_image.dart';
import 'package:smart_laundry_locker/shared/widgets/user_ui_kit.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:smart_laundry_locker/core/l10n/l10n.dart';

/// Profile header widget with user information
class ProfileHeader extends StatelessWidget {
  const ProfileHeader({
    required this.user,
    super.key,
    this.onEditAvatar,
    this.onSaveAvatar,
    this.onCancelAvatar,
    this.onEditProfile,
    this.avatarVersion = 0,
    this.localAvatarFile,
    this.isAvatarSyncing = false,
    this.showSaveAvatarButton = false,
  });
  final Map<String, dynamic> user;
  final VoidCallback? onEditAvatar;
  final VoidCallback? onSaveAvatar;
  final VoidCallback? onCancelAvatar;
  final VoidCallback? onEditProfile;
  final int avatarVersion;
  final File? localAvatarFile;
  final bool isAvatarSyncing;
  final bool showSaveAvatarButton;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Avatar section
          _buildAvatarSection(context),
          const SizedBox(height: 14),

          // Save avatar button (only when local file exists)
          if (showSaveAvatarButton && localAvatarFile != null) ...[
            _buildSaveAvatarButton(context),
            const SizedBox(height: 14),
          ],

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
      clipBehavior: Clip.none,
      children: [
        // Avatar
        GestureDetector(
          onTap: (localAvatarFile == null && !isAvatarSyncing)
              ? onEditAvatar
              : null,
          child: Container(
            width: 104,
            height: 104,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              border: Border.all(color: Colors.white, width: 3.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.10),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ],
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
                      width: 104,
                      height: 104,
                      filterQuality: FilterQuality.high,
                    ),
                ],
              ),
            ),
          ),
        ),

        // Camera badge icon at bottom right of avatar
        if (onEditAvatar != null && localAvatarFile == null)
          Positioned(
            bottom: 2,
            right: 2,
            child: GestureDetector(
              onTap: !isAvatarSyncing ? onEditAvatar : null,
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AislBrand.navy,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.16),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  LucideIcons.camera,
                  size: 14,
                  color: Colors.white,
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
                    color: Colors.white,
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.16),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
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
    return Container(
      constraints: const BoxConstraints(maxWidth: 220),
      height: 44,
      child: ShadButton(
        enabled: !isAvatarSyncing && onSaveAvatar != null,
        onPressed: isAvatarSyncing ? null : onSaveAvatar,
        backgroundColor: AislBrand.navy,
        child: isAvatarSyncing
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                  SizedBox(width: 8),
                  Text(
                    context.l10n.phSyncing,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(LucideIcons.check, size: 16, color: Colors.white),
                  SizedBox(width: 6),
                  Text(
                    context.l10n.phSaveAvatar,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildDefaultAvatar(BuildContext context) {
    // Get the first letter of the user's name
    final fullName = user['fullName']?.toString() ?? context.l10n.commonUser;
    final firstLetter = fullName.isNotEmpty
        ? fullName.trim().substring(0, 1).toUpperCase()
        : 'N';

    return Container(
      width: 104,
      height: 104,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Color(0xFFE2E8F0),
      ),
      child: Center(
        child: Text(
          firstLetter,
          style: const TextStyle(
            fontFamily: 'Roboto',
            fontSize: 36,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1E293B),
          ),
        ),
      ),
    );
  }

  Widget _buildUserInfoSection(BuildContext context) {
    return GestureDetector(
      onTap: onEditProfile,
      behavior: HitTestBehavior.opaque,
      child: Column(
        children: [
          // Full name
          Text(
            user['fullName']?.toString() ?? context.l10n.commonUser,
            style: TextStyle(
              fontFamily: 'Roboto',
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: context.textPrimary,
              letterSpacing: -0.3,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),

          // Email (only show if not null)
          if (user['email'] != null && user['email'].toString().isNotEmpty)
            Text(
              user['email'].toString(),
              style: TextStyle(
                fontFamily: 'Roboto',
                fontSize: 13.5,
                fontWeight: FontWeight.w500,
                color: context.textMuted,
              ),
              textAlign: TextAlign.center,
            ),
        ],
      ),
    );
  }
}

