import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:smart_laundry_locker/core/l10n/l10n.dart';

/// `purpose` khi xin chữ ký upload (docs/01-overview/media-storage.md §3).
abstract final class MediaPurpose {
  static const reportEvidence = 'REPORT_EVIDENCE';
  static const dronePickup = 'DRONE_PICKUP';
  static const avatar = 'AVATAR';
  static const storeImage = 'STORE_IMAGE';
  static const promotionImage = 'PROMOTION_IMAGE';
}

/// Một phần tử `uploads[]` của phản hồi xin chữ ký: dùng cho đúng 1 file.
class UploadSignatureItem {
  const UploadSignatureItem({required this.publicId, required this.fields});

  final String publicId;

  /// Toàn bộ field phải gửi nguyên giá trị lên Cloudinary
  /// (`api_key`, `timestamp`, `public_id`, `allowed_formats`, `signature`).
  final Map<String, String> fields;

  factory UploadSignatureItem.fromJson(Map<String, dynamic> json) {
    final rawFields = json['fields'];
    final fields = <String, String>{};
    if (rawFields is Map) {
      rawFields.forEach((key, value) {
        if (value != null) fields['$key'] = '$value';
      });
    }
    return UploadSignatureItem(
      publicId: '${json['publicId'] ?? fields['public_id'] ?? ''}',
      fields: fields,
    );
  }
}

/// Phản hồi `POST /api/media/upload-signatures`.
class UploadSignatureBatch {
  const UploadSignatureBatch({
    required this.uploadUrl,
    required this.uploads,
    this.provider,
    this.cloudName,
    this.maxBytes,
    this.allowedFormats = const [],
    this.expiresAt,
  });

  final String? provider;
  final String? cloudName;
  final String uploadUrl;
  final int? maxBytes;
  final List<String> allowedFormats;
  final DateTime? expiresAt;
  final List<UploadSignatureItem> uploads;

  factory UploadSignatureBatch.fromJson(Map<String, dynamic> json) {
    final rawUploads = json['uploads'];
    final rawFormats = json['allowedFormats'];
    return UploadSignatureBatch(
      provider: json['provider']?.toString(),
      cloudName: json['cloudName']?.toString(),
      uploadUrl: '${json['uploadUrl'] ?? ''}',
      maxBytes: _asInt(json['maxBytes']),
      allowedFormats: rawFormats is List
          ? rawFormats.map((e) => '$e').toList(growable: false)
          : const [],
      expiresAt: DateTime.tryParse('${json['expiresAt'] ?? ''}'),
      uploads: rawUploads is List
          ? rawUploads
                .whereType<Map>()
                .map(
                  (e) => UploadSignatureItem.fromJson(
                    Map<String, dynamic>.from(e),
                  ),
                )
                .toList(growable: false)
          : const [],
    );
  }
}

/// **MediaUpload** — lấy nguyên từ phản hồi Cloudinary, gửi kèm mọi API gắn ảnh.
class MediaUpload {
  const MediaUpload({
    required this.publicId,
    required this.version,
    required this.signature,
    required this.format,
    this.bytes,
    this.width,
    this.height,
    this.secureUrl,
  });

  final String publicId;
  final int version;
  final String signature;
  final String format;
  final int? bytes;
  final int? width;
  final int? height;

  /// Chỉ để xem trước phía client — backend tự dựng URL, không nhận field này.
  final String? secureUrl;

  /// Parse phản hồi JSON (snake_case) của Cloudinary upload API.
  factory MediaUpload.fromCloudinary(Map<String, dynamic> json) {
    final publicId = json['public_id']?.toString() ?? '';
    final version = _asInt(json['version']);
    final signature = json['signature']?.toString() ?? '';
    if (publicId.isEmpty || version == null || signature.isEmpty) {
      throw MediaUploadException(
        L10n.current.mediaBadResponse,
        code: 'CLOUDINARY_BAD_RESPONSE',
      );
    }
    return MediaUpload(
      publicId: publicId,
      version: version,
      signature: signature,
      format: json['format']?.toString() ?? '',
      bytes: _asInt(json['bytes']),
      width: _asInt(json['width']),
      height: _asInt(json['height']),
      secureUrl: json['secure_url']?.toString(),
    );
  }

  /// Body `MediaUpload` theo hợp đồng (camelCase).
  Map<String, dynamic> toJson() => {
    'publicId': publicId,
    'version': version,
    'signature': signature,
    'format': format,
    if (bytes != null) 'bytes': bytes,
    if (width != null) 'width': width,
    if (height != null) 'height': height,
  };

  /// **ReportAttachmentRequest** = MediaUpload + caption/capturedAt/lat/lng.
  Map<String, dynamic> toAttachmentJson({
    String? caption,
    DateTime? capturedAt,
    double? latitude,
    double? longitude,
  }) {
    final trimmed = caption?.trim();
    return {
      ...toJson(),
      if (trimmed != null && trimmed.isNotEmpty)
        'caption': trimmed.length > 500 ? trimmed.substring(0, 500) : trimmed,
      if (capturedAt != null) 'capturedAt': formatLocalIsoDateTime(capturedAt),
      if (latitude != null && longitude != null) ...{
        'latitude': latitude,
        'longitude': longitude,
      },
    };
  }
}

/// `yyyy-MM-ddTHH:mm:ss` theo giờ máy (backend dùng LocalDateTime).
String formatLocalIsoDateTime(DateTime value) {
  final d = value.toLocal();
  String two(int n) => n.toString().padLeft(2, '0');
  return '${d.year.toString().padLeft(4, '0')}-${two(d.month)}-${two(d.day)}'
      'T${two(d.hour)}:${two(d.minute)}:${two(d.second)}';
}

/// Lỗi thân thiện (tiếng Việt) cho mọi bước upload ảnh.
class MediaUploadException implements Exception {
  const MediaUploadException(this.message, {this.code, this.statusCode});

  final String message;
  final String? code;
  final int? statusCode;

  bool get storageDisabled => code == 'MEDIA_STORAGE_DISABLED';

  /// Lỗi từ API backend (xin chữ ký / gắn ảnh).
  factory MediaUploadException.fromApi(DioException error) {
    final status = error.response?.statusCode;
    final data = _decodeBody(error.response?.data);
    final code = data is Map ? data['code']?.toString() : null;
    final serverMessage = data is Map ? data['message']?.toString() : null;
    final friendly = MediaErrorMessages.forCode(code);
    if (friendly != null) {
      return MediaUploadException(friendly, code: code, statusCode: status);
    }
    if (error.type == DioExceptionType.cancel) {
      return MediaUploadException(
        L10n.current.mediaUploadCancelled,
        code: 'CANCELLED',
        statusCode: status,
      );
    }
    if (error.response == null) {
      return MediaUploadException(
        L10n.current.mediaCannotConnect,
        code: code,
        statusCode: status,
      );
    }
    if (status == 403) {
      return MediaUploadException(
        L10n.current.mediaPurposeForbidden,
        code: code,
        statusCode: status,
      );
    }
    return MediaUploadException(
      (serverMessage != null && serverMessage.trim().isNotEmpty)
          ? serverMessage
          : L10n.current.mediaNoUploadPermission,
      code: code,
      statusCode: status,
    );
  }

  /// Lỗi khi POST multipart lên Cloudinary.
  factory MediaUploadException.fromCloudinary(DioException error) {
    final status = error.response?.statusCode;
    if (error.type == DioExceptionType.cancel) {
      return MediaUploadException(
        L10n.current.mediaUploadCancelled,
        code: 'CANCELLED',
        statusCode: status,
      );
    }
    if (error.response == null) {
      return MediaUploadException(
        L10n.current.mediaUploadNetwork,
        code: 'CLOUDINARY_NETWORK',
        statusCode: status,
      );
    }
    final data = _decodeBody(error.response?.data);
    var raw = '';
    if (data is Map) {
      final err = data['error'];
      raw = (err is Map ? err['message'] : err)?.toString() ?? '';
    }
    final lower = raw.toLowerCase();
    final String message;
    if (lower.contains('stale request') ||
        lower.contains('expired') ||
        lower.contains('invalid signature') ||
        status == 401) {
      message = L10n.current.mediaSessionExpired;
    } else if (lower.contains('too large') || status == 413) {
      message = L10n.current.mediaTooLarge;
    } else if (lower.contains('format') || lower.contains('invalid image')) {
      message = L10n.current.mediaFormatUnsupported;
    } else if (status == 420 || status == 429) {
      message = L10n.current.mediaServerOverloaded;
    } else {
      message = L10n.current.mediaUploadFailedRetry;
    }
    return MediaUploadException(
      message,
      code: 'CLOUDINARY_ERROR',
      statusCode: status,
    );
  }

  @override
  String toString() => message;
}

/// Mã lỗi backend liên quan ảnh ⇒ câu thông báo tiếng Việt.
abstract final class MediaErrorMessages {
  static Map<String, String> get _messages => <String, String>{
    'MEDIA_STORAGE_DISABLED':
        L10n.current.mediaStorageDisabled,
    'MEDIA_PURPOSE_INVALID': L10n.current.mediaPurposeInvalid,
    'MEDIA_PURPOSE_FORBIDDEN': L10n.current.mediaPurposeForbidden,
    'MEDIA_SIGNATURE_INVALID': L10n.current.mediaSignatureInvalid,
    'MEDIA_OWNER_MISMATCH': L10n.current.mediaOwnerMismatch,
    'MEDIA_FORMAT_INVALID': L10n.current.mediaFormatUnsupported,
    'ATTACHMENT_LIMIT_EXCEEDED': L10n.current.mediaAttachmentLimit,
    'ATTACHMENT_STAGE_INVALID': L10n.current.mediaAttachmentStageInvalid,
    'REPORT_NOT_IN_PROGRESS': L10n.current.mediaReportNotInProgress,
    'REPORT_ALREADY_RESOLVED': L10n.current.mediaReportResolved,
    'REPORT_NOT_ASSIGNED': L10n.current.mediaReportNotAssigned,
    'REPORT_NOT_OWNED': L10n.current.mediaReportNotOwned,
    'ATTACHMENT_DELETE_FORBIDDEN': L10n.current.mediaDeleteForbidden,
    'RESOLUTION_PHOTO_REQUIRED': L10n.current.mediaResolutionPhotoRequired,
    'DATA_CONFLICT': L10n.current.mediaAlreadyAttached,
  };

  /// `null` nếu [code] không phải lỗi ảnh đã biết.
  static String? forCode(String? code) => code == null ? null : _messages[code];
}

dynamic _decodeBody(dynamic data) {
  if (data is String && data.trim().startsWith('{')) {
    try {
      return jsonDecode(data);
    } catch (_) {}
  }
  return data;
}

int? _asInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse('${value ?? ''}');
}
