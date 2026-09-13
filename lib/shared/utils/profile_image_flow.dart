import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:logger/logger.dart';
import 'package:permission_handler/permission_handler.dart';

final _logger = Logger(printer: PrettyPrinter());

/// Unified image processing flow: pick -> crop -> compress -> temp file.
class ProfileImageFlow {
  /// Process image with all steps.
  static Future<File?> process({
    required ImageSource source,
    required CropAspectRatio cropRatio,
    required int quality,
    required int maxWidth,
    required int maxHeight,
    required int maxSizeMB,
    required int minCompressQuality,
    required String title,
    CropAspectRatioPreset? cropPreset,
    bool lockAspectRatio = false,
  }) async {
    try {
      // Step 0: Check and request permission
      final hasPermission = await _requestPermission(source);
      if (!hasPermission) {
        _logger.w('Permission denied for ${source.name}');
        return null;
      }

      // Step 1: Pick image
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: source,
        imageQuality: quality,
        maxWidth: maxWidth.toDouble(),
        maxHeight: maxHeight.toDouble(),
      );

      if (pickedFile == null) return null;

      // Step 2: Crop image
      final croppedFile = await _cropImage(
        pickedFile.path,
        cropRatio: cropRatio,
        title: title,
        cropPreset: cropPreset,
        lockAspectRatio: lockAspectRatio,
      );

      if (croppedFile == null) {
        _logger.w('Crop cancelled or failed');
        return null;
      }

      // Log cropped file info
      final croppedFileObj = File(croppedFile.path);
      final croppedSize = await croppedFileObj.length();
      _logger.d('Cropped file: ${croppedFile.path}, size: $croppedSize bytes');

      // Step 3: Compress image to exact square dimensions
      final compressedBytes = await _compressImage(
        croppedFile.path,
        quality: quality,
        targetWidth: maxWidth,
        targetHeight: maxHeight,
        maxSizeMB: maxSizeMB,
        minQuality: minCompressQuality,
      );

      if (compressedBytes == null) return null;

      // Step 4: Save to temp file
      return _saveToTemp(compressedBytes);
    } catch (e) {
      _logger.e('Error in image flow', error: e);
      return null;
    }
  }

  /// Step 2: Crop with rotation controls enabled.
  static Future<CroppedFile?> _cropImage(
    String path, {
    required CropAspectRatio cropRatio,
    required String title,
    CropAspectRatioPreset? cropPreset,
    bool lockAspectRatio = false,
  }) async {
    try {
      final isPresetMode = cropPreset != null;
      const toolbarColor = Color(0xFFFDFDFD);
      const toolbarForeground = Color(0xFF1D1D1F);
      const surfaceColor = Color(0xFFFFFFFF); // White background
      const controlsColor = Color(0xFF111111);
      const dimLayerColor = Color(0x99FFFFFF); // White semi-transparent
      const gridColor = Color(0x1F000000);
      // Use transparent status bar to inherit from system
      const statusBarColor = Color(0x00000000); // Transparent

      final uiSettings = [
        AndroidUiSettings(
          toolbarTitle: title,
          toolbarColor: toolbarColor,
          // CRITICAL FIX: statusBarLight/navBarLight control ICON colors:
          // - false = dark icons (for light backgrounds)
          // - true = light/white icons (for dark backgrounds)
          statusBarLight: false, // Dark icons on light background
          navBarLight: false, // Dark navigation icons
          statusBarColor: statusBarColor, // Transparent to show system bar
          toolbarWidgetColor: toolbarForeground,
          backgroundColor: surfaceColor,
          activeControlsWidgetColor: controlsColor,
          dimmedLayerColor: dimLayerColor,
          cropFrameColor: toolbarForeground,
          cropGridColor: gridColor,
          cropFrameStrokeWidth: 2,
          cropGridStrokeWidth: 1,
          cropGridRowCount: 3,
          cropGridColumnCount: 3,
          showCropGrid: true,
          lockAspectRatio: lockAspectRatio,
          hideBottomControls: lockAspectRatio,
          initAspectRatio: isPresetMode
              ? cropPreset
              : CropAspectRatioPreset.original,
          aspectRatioPresets: isPresetMode
              ? [cropPreset]
              : [CropAspectRatioPreset.original],
        ),
        IOSUiSettings(
          title: title,
          aspectRatioLockEnabled: lockAspectRatio,
          resetAspectRatioEnabled: !lockAspectRatio,
          aspectRatioPickerButtonHidden: lockAspectRatio,
          aspectRatioPresets: isPresetMode
              ? [cropPreset]
              : [CropAspectRatioPreset.original],
        ),
      ];

      return await ImageCropper().cropImage(
        sourcePath: path,
        uiSettings: uiSettings,
        aspectRatio: lockAspectRatio ? cropRatio : null,
      );
    } catch (e) {
      _logger.e('Error during cropping', error: e);
      return null;
    }
  }

  /// Step 3: Compress to exact square dimensions with iterative quality reduction.
  static Future<List<int>?> _compressImage(
    String path, {
    required int quality,
    required int targetWidth,
    required int targetHeight,
    required int maxSizeMB,
    required int minQuality,
  }) async {
    var currentQuality = quality;
    List<int>? compressedBytes;
    final maxBytes = maxSizeMB * 1024 * 1024;

    do {
      // Use minWidth/minHeight with exact same value to force square output
      compressedBytes = await FlutterImageCompress.compressWithFile(
        path,
        quality: currentQuality,
        minWidth: targetWidth,
        minHeight: targetHeight,
        keepExif: false, // Remove EXIF to avoid orientation issues
        format: CompressFormat.jpeg, // Always use JPEG for consistency
      );

      if (compressedBytes == null) break;

      if (compressedBytes.length > maxBytes && currentQuality > minQuality) {
        currentQuality -= 10;
        _logger.d(
          'Compressing: quality=$currentQuality, size=${compressedBytes.length}',
        );
      } else {
        break;
      }
    } while (currentQuality > minQuality);

    if (compressedBytes == null || compressedBytes.length > maxBytes) {
      _logger.w('Cannot compress below ${maxSizeMB}MB');
      return null;
    }

    _logger.d(
      'Compressed to ${targetWidth}x${targetHeight}: ${compressedBytes.length} bytes, quality=$currentQuality',
    );
    return compressedBytes;
  }

  /// Step 4: Persist bytes into a temp file for uploads/previews.
  static Future<File?> _saveToTemp(List<int> bytes) async {
    try {
      final tempDir = Directory.systemTemp;
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final tempFile = File('${tempDir.path}/img_$timestamp.jpg');

      await tempFile.writeAsBytes(bytes, flush: true);
      _logger.d('Saved to temp: ${tempFile.path}');

      return tempFile;
    } catch (e) {
      _logger.e('Error saving to temp', error: e);
      return null;
    }
  }

  /// Step 0: Request permission for camera or photos
  /// This ensures permission is always requested before accessing camera/gallery
  static Future<bool> _requestPermission(ImageSource source) async {
    try {
      Permission permission;

      if (source == ImageSource.camera) {
        // Camera requires camera permission
        permission = Permission.camera;
      } else {
        // Gallery requires photos/storage permission
        if (Platform.isIOS) {
          permission = Permission.photos;
        } else {
          // Android 13+ uses photos, older versions use storage
          permission = Permission.photos;
        }
      }

      // Check current permission status
      var status = await permission.status;
      _logger.d('Current permission status for ${source.name}: $status');

      // If permission is already granted, return true
      if (status.isGranted) {
        return true;
      }

      // If permission is denied (not permanently), request it
      // This will show the permission dialog every time for "use this time only"
      if (status.isDenied || status.isLimited) {
        status = await permission.request();
        _logger.d('Permission request result: $status');
        return status.isGranted || status.isLimited;
      }

      // If permission is permanently denied, open app settings
      if (status.isPermanentlyDenied) {
        _logger.w('Permission permanently denied, opening settings');
        await openAppSettings();
        return false;
      }

      return false;
    } catch (e) {
      _logger.e('Error requesting permission', error: e);
      return false;
    }
  }
}
