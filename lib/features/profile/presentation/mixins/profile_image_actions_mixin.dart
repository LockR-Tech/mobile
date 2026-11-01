import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:logger/logger.dart';
import 'package:smart_laundry_locker/core/network/api_client.dart';
import 'package:smart_laundry_locker/core/services/image_cache_manager.dart';
import 'package:smart_laundry_locker/features/profile/domain/validators/avatar_image_validator.dart';
import 'package:smart_laundry_locker/features/profile/infrastructure/data_sources/profile_remote_data_source_impl.dart';
import 'package:smart_laundry_locker/features/profile/infrastructure/repositories/profile_repository_impl.dart';
import 'package:smart_laundry_locker/shared/shared.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:smart_laundry_locker/core/l10n/l10n.dart';

final _logger = Logger(printer: PrettyPrinter());

/// Shared mixin chứa toàn bộ logic chọn & upload ảnh đại diện.
///
/// (Ảnh bìa "mô phỏng" cũ đã bỏ — backend không có endpoint ảnh bìa.)
mixin ProfileImageActionsMixin<T extends StatefulWidget> on State<T> {
  // Abstract members to be implemented by the consuming widget
  File? get localAvatarFile;
  set localAvatarFile(File? file);

  bool get isAvatarSyncing;
  set isAvatarSyncing(bool value);

  /// ID user hiện tại dùng cho upload avatar
  String? get currentUserIdForAvatar;

  // Helper to update state in the consuming widget
  void updateState(VoidCallback fn) {
    if (mounted) setState(fn);
  }

  /// Handle avatar selection flow
  Future<void> handleAvatarSelection() async {
    if (!mounted) return;

    if (isAvatarSyncing) {
      _showSnackBar(context.l10n.avWaitSync, isError: true);
      return;
    }

    // Show picker dialog
    final source = await _showImageSourcePicker(context.l10n.avChooseAvatar);
    if (source == null || !mounted) return;

    // Process image
    final tempFile = await ProfileImageFlow.process(
      source: source,
      cropRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
      cropPreset: CropAspectRatioPreset.square,
      quality: 85,
      maxWidth: 1024,
      maxHeight: 1024,
      maxSizeMB: 1,
      minCompressQuality: 20,
      title: context.l10n.avEditAvatar,
      lockAspectRatio: true,
    );

    if (tempFile == null) {
      if (mounted) {
        final sourceName = source == ImageSource.camera
            ? context.l10n.avCamera
            : context.l10n.avGallery;
        _showSnackBar(
          context.l10n.avCantAccess(sourceName),
          isError: true,
        );
      }
      return;
    }

    if (!mounted) return;

    // Set local file for preview
    updateState(() {
      localAvatarFile = tempFile;
    });

    _showSnackBar(
      context.l10n.avSelected,
      isError: false,
    );
  }

  /// Upload avatar
  Future<void> uploadAvatarImage() async {
    if (!mounted) return;

    if (localAvatarFile == null) {
      _showSnackBar(context.l10n.avNothingToUpload, isError: true);
      return;
    }

    final userId = currentUserIdForAvatar;
    if (userId == null || userId.isEmpty) {
      _showSnackBar(
        context.l10n.avNoAccount,
        isError: true,
      );
      return;
    }

    // Validate file before upload
    final validationResult = await AvatarImageValidator.validateFile(
      localAvatarFile!,
    );
    if (!validationResult.isValid) {
      _showSnackBar(
        validationResult.error ?? L10n.current.avInvalid,
        isError: true,
      );
      return;
    }

    updateState(() {
      isAvatarSyncing = true;
    });

    final currentContext = context;
    final uploadProgress = ValueNotifier<double>(0);
    BuildContext? progressDialogContext;

    bool isProgressValid = true;

    // Show progress dialog
    showDialog<void>(
      context: currentContext,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.35),
      builder: (dialogContext) {
        progressDialogContext = dialogContext;
        return _buildProgressDialog(progress: uploadProgress);
      },
    );

    void closeProgressDialog() =>
        _safelyCloseDialog(progressDialogContext ?? currentContext);

    void safeUpdateProgress(double value) {
      if (isProgressValid && mounted) {
        try {
          uploadProgress.value = value;
        } catch (e) {
          _logger.w('[Avatar Upload] Could not update progress: $e');
        }
      }
    }

    void safeDisposeProgress() {
      if (isProgressValid) {
        isProgressValid = false;
        try {
          uploadProgress.dispose();
        } catch (e) {
          _logger.w('[Avatar Upload] Progress already disposed: $e');
        }
      }
    }

    try {
      final apiClient = ApiClient();
      final remoteDataSource = ProfileRemoteDataSourceImpl(apiClient);
      final repository = ProfileRepositoryImpl(
        remoteDataSource: remoteDataSource,
      );

      safeUpdateProgress(0.15);

      final result = await repository.uploadAvatar(
        userId: userId,
        filePath: localAvatarFile!.path,
      );

      if (!mounted) {
        safeDisposeProgress();
        return;
      }

      result.fold(
        (failure) {
          safeDisposeProgress();
          SchedulerBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            closeProgressDialog();
            updateState(() {
              isAvatarSyncing = false;
            });
            _showSnackBar(failure.message, isError: true);
          });
        },
        (_) {
          safeUpdateProgress(1.0);
          SchedulerBinding.instance.addPostFrameCallback((_) async {
            if (!mounted) {
              safeDisposeProgress();
              return;
            }

            closeProgressDialog();
            safeDisposeProgress();

            ProfileImageCacheManager.clearAllMemoryCache();

            if (await localAvatarFile?.exists() == true) {
              await localAvatarFile?.delete();
            }

            updateState(() {
              localAvatarFile = null;
              isAvatarSyncing = false;
            });

            _showSnackBar(L10n.current.avUpdated, isError: false);
          });
        },
      );
    } catch (e) {
      _logger.e('Error uploading avatar', error: e);

      safeDisposeProgress();

      if (!mounted) return;

      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        closeProgressDialog();
        updateState(() {
          isAvatarSyncing = false;
        });
        _showSnackBar(context.l10n.rfError(e), isError: true);
      });
    }
  }

  /// Cancel avatar selection
  void cancelAvatarSelection() {
    if (!mounted) return;

    final file = localAvatarFile;

    updateState(() {
      localAvatarFile = null;
    });

    if (file != null) {
      file.delete().catchError((Object e) {
        _logger.w('Error deleting temp file', error: e);
        return file;
      });
    }

    _showSnackBar(context.l10n.avCancelled, isError: false);
  }

  /// Show image source picker bottom sheet (centered modal style)
  Future<ImageSource?> _showImageSourcePicker(String title) async {
    if (!mounted) return null;

    final theme = ShadTheme.of(context);

    return showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        final navigator = Navigator.of(sheetContext);
        final backgroundColor = theme.colorScheme.popover;
        final foregroundColor = theme.colorScheme.foreground;
        final mutedForegroundColor = theme.colorScheme.mutedForeground;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Centered modal card
                Container(
                  decoration: BoxDecoration(
                    color: backgroundColor,
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                        spreadRadius: 2,
                      ),
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Title
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: foregroundColor,
                          letterSpacing: -0.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),

                      // Subtitle
                      Text(
                        context.l10n.avChooseSource,
                        style: TextStyle(
                          fontSize: 14,
                          color: mutedForegroundColor,
                          fontWeight: FontWeight.w400,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),

                      // 1. Camera Button (First)
                      _buildActionButton(
                        context: sheetContext,
                        icon: LucideIcons.camera,
                        label: 'Camera',
                        backgroundColor: theme.colorScheme.accent,
                        foregroundColor: foregroundColor,
                        onPressed: () {
                          if (navigator.canPop()) {
                            navigator.pop(ImageSource.camera);
                          }
                        },
                      ),
                      const SizedBox(height: 12),

                      // 2. Gallery Button (Second)
                      _buildActionButton(
                        context: sheetContext,
                        icon: LucideIcons.image,
                        label: context.l10n.avLibrary,
                        backgroundColor: theme.colorScheme.accent,
                        foregroundColor: foregroundColor,
                        onPressed: () {
                          if (navigator.canPop()) {
                            navigator.pop(ImageSource.gallery);
                          }
                        },
                      ),
                      const SizedBox(height: 12),

                      // 3. Cancel Button (Last - with destructive style)
                      _buildCancelButton(
                        context: sheetContext,
                        onPressed: () {
                          if (navigator.canPop()) {
                            navigator.pop();
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Build action button (Camera, Gallery)
  Widget _buildActionButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required Color backgroundColor,
    required Color foregroundColor,
    required VoidCallback onPressed,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(14),
        splashColor: foregroundColor.withOpacity(0.1),
        highlightColor: foregroundColor.withOpacity(0.05),
        child: Ink(
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Container(
            height: 56,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 22, color: foregroundColor),
                const SizedBox(width: 12),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: foregroundColor,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Build cancel button with destructive hover effect
  Widget _buildCancelButton({
    required BuildContext context,
    required VoidCallback onPressed,
  }) {
    final theme = ShadTheme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(14),
        // Red highlight on press
        splashColor: const Color(0xFFFFE5E5),
        highlightColor: const Color(0xFFFFE5E5).withOpacity(0.5),
        child: Ink(
          decoration: BoxDecoration(
            color: theme.colorScheme.muted,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: theme.colorScheme.border.withOpacity(0.5),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Container(
            height: 56,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  LucideIcons.x,
                  size: 22,
                  // Grey by default, changes to red on press via InkWell
                  color: theme.colorScheme.mutedForeground,
                ),
                const SizedBox(width: 12),
                Text(
                  context.l10n.commonCancel,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    // Grey by default
                    color: theme.colorScheme.mutedForeground,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Build progress dialog
  Widget _buildProgressDialog({required ValueNotifier<double> progress}) {
    return ValueListenableBuilder<double>(
      valueListenable: progress,
      builder: (context, value, child) {
        final theme = ShadTheme.of(context);
        final percentLabel =
            '${(value * 100).clamp(0, 100).toStringAsFixed(0)}%';
        return ShadDialog(
          title: Text(
            context.l10n.avUploading,
            style: TextStyle(color: theme.colorScheme.foreground),
          ),
          description: Text(
            context.l10n.avProgress(percentLabel),
            style: TextStyle(color: theme.colorScheme.mutedForeground),
          ),
          backgroundColor: theme.colorScheme.popover,
          child: ShadCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: value,
                    minHeight: 6,
                    backgroundColor: theme.colorScheme.mutedForeground,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      theme.colorScheme.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  context.l10n.avPleaseWait,
                  style: theme.textTheme.muted,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Show snackbar with white background and dark text for profile actions
  void _showSnackBar(String message, {required bool isError}) {
    SmartDialog.showToast(message);
  }

  /// Safely close dialog
  void _safelyCloseDialog(BuildContext? dialogContext) {
    final contextToUse = dialogContext ?? (mounted ? context : null);
    if (contextToUse == null) return;

    final navigator = Navigator.maybeOf(contextToUse, rootNavigator: true);
    if (navigator != null && navigator.canPop()) {
      navigator.pop();
    }
  }
}
