import 'dart:io';
import 'package:flutter/foundation.dart';

/// Validation result for avatar image
class AvatarValidationResult {
  const AvatarValidationResult({required this.isValid, this.error});

  factory AvatarValidationResult.success() =>
      const AvatarValidationResult(isValid: true);

  factory AvatarValidationResult.failure(String error) =>
      AvatarValidationResult(isValid: false, error: error);
  final bool isValid;
  final String? error;
}

/// Validator for avatar images following web FE spec
///
/// Validation rules from avatar.md:
/// - Max file size: 5MB
/// - Min dimensions: 200x200px
/// - Max dimensions: 2000x2000px
/// - Allowed formats: JPG, JPEG, PNG, WebP
class AvatarImageValidator {
  // Validation constants from spec
  static const int maxFileSizeBytes = 5 * 1024 * 1024; // 5MB
  static const int minDimension = 200;
  static const int maxDimension = 2000;
  static const List<String> allowedMimeTypes = [
    'image/jpeg',
    'image/jpg',
    'image/png',
    'image/webp',
  ];
  static const List<String> allowedExtensions = [
    '.jpg',
    '.jpeg',
    '.png',
    '.webp',
  ];

  /// Validate file size
  /// Max: 5MB
  static AvatarValidationResult validateFileSize(int fileSizeBytes) {
    if (fileSizeBytes > maxFileSizeBytes) {
      final sizeMB = (fileSizeBytes / (1024 * 1024)).toStringAsFixed(1);
      return AvatarValidationResult.failure(
        'Ảnh không được vượt quá 5MB (kích thước hiện tại: ${sizeMB}MB)',
      );
    }
    return AvatarValidationResult.success();
  }

  /// Validate image dimensions
  /// Min: 200x200px, Max: 2000x2000px
  static AvatarValidationResult validateDimensions(int width, int height) {
    if (width < minDimension || height < minDimension) {
      return AvatarValidationResult.failure(
        'Ảnh phải có kích thước tối thiểu ${minDimension}x${minDimension}px (kích thước hiện tại: ${width}x${height}px)',
      );
    }

    if (width > maxDimension || height > maxDimension) {
      return AvatarValidationResult.failure(
        'Ảnh không được vượt quá ${maxDimension}x${maxDimension}px (kích thước hiện tại: ${width}x${height}px)',
      );
    }

    return AvatarValidationResult.success();
  }

  /// Validate file format by MIME type
  /// Allowed: JPG, JPEG, PNG, WebP
  static AvatarValidationResult validateMimeType(String? mimeType) {
    if (mimeType == null || mimeType.isEmpty) {
      return AvatarValidationResult.failure(
        'Không thể xác định định dạng file',
      );
    }

    final normalizedMimeType = mimeType.toLowerCase();
    if (!allowedMimeTypes.contains(normalizedMimeType)) {
      return AvatarValidationResult.failure(
        'Chỉ hỗ trợ định dạng JPG, PNG, WebP',
      );
    }

    return AvatarValidationResult.success();
  }

  /// Validate file format by extension (fallback if MIME type not available)
  static AvatarValidationResult validateFileExtension(String filePath) {
    final extension = filePath.toLowerCase().substring(
      filePath.lastIndexOf('.'),
    );

    if (!allowedExtensions.contains(extension)) {
      return AvatarValidationResult.failure(
        'Chỉ hỗ trợ định dạng JPG, PNG, WebP',
      );
    }

    return AvatarValidationResult.success();
  }

  /// Complete validation for a File object
  /// This validates file size and extension
  static Future<AvatarValidationResult> validateFile(File file) async {
    try {
      // Check if file exists
      if (!await file.exists()) {
        return AvatarValidationResult.failure('File không tồn tại');
      }

      // Validate file size
      final fileSize = await file.length();
      final sizeValidation = validateFileSize(fileSize);
      if (!sizeValidation.isValid) {
        return sizeValidation;
      }

      // Validate file extension
      final extensionValidation = validateFileExtension(file.path);
      if (!extensionValidation.isValid) {
        return extensionValidation;
      }

      return AvatarValidationResult.success();
    } catch (e) {
      debugPrint('Error validating file: $e');
      return AvatarValidationResult.failure('Không thể kiểm tra file: $e');
    }
  }

  /// Complete validation with dimensions
  /// Use this when you have access to image dimensions (e.g., from image_picker)
  static AvatarValidationResult validateComplete({
    required int fileSizeBytes,
    required int width,
    required int height,
    String? mimeType,
    String? filePath,
  }) {
    // Validate file size
    final sizeValidation = validateFileSize(fileSizeBytes);
    if (!sizeValidation.isValid) {
      return sizeValidation;
    }

    // Validate dimensions
    final dimensionsValidation = validateDimensions(width, height);
    if (!dimensionsValidation.isValid) {
      return dimensionsValidation;
    }

    // Validate format (prefer MIME type, fallback to extension)
    if (mimeType != null && mimeType.isNotEmpty) {
      final mimeValidation = validateMimeType(mimeType);
      if (!mimeValidation.isValid) {
        return mimeValidation;
      }
    } else if (filePath != null && filePath.isNotEmpty) {
      final extensionValidation = validateFileExtension(filePath);
      if (!extensionValidation.isValid) {
        return extensionValidation;
      }
    } else {
      return AvatarValidationResult.failure(
        'Không thể xác định định dạng file',
      );
    }

    return AvatarValidationResult.success();
  }

  /// Helper to format file size for display
  static String formatFileSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
  }

  /// Helper to check if dimensions are within acceptable range
  static bool areDimensionsValid(int width, int height) {
    return width >= minDimension &&
        width <= maxDimension &&
        height >= minDimension &&
        height <= maxDimension;
  }

  /// Helper to check if file size is within acceptable range
  static bool isFileSizeValid(int bytes) {
    return bytes <= maxFileSizeBytes;
  }
}
