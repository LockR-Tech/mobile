import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:smart_laundry_locker/core/media/media_upload.dart';
import 'package:smart_laundry_locker/core/media/media_upload_service.dart';

enum PendingPhotoStatus { pending, uploading, uploaded, failed }

/// Ảnh vừa chụp/chọn, chưa gắn vào phiếu.
class PendingPhoto {
  PendingPhoto(this.file, {DateTime? capturedAt})
    : capturedAt = capturedAt ?? DateTime.now();

  final XFile file;

  /// Thời điểm chọn/chụp (máy không đọc EXIF để tiết kiệm).
  final DateTime capturedAt;
  double? latitude;
  double? longitude;

  PendingPhotoStatus status = PendingPhotoStatus.pending;
  double progress = 0;
  String? error;

  /// Có rồi thì không upload lại khi người dùng bấm gửi lần 2.
  MediaUpload? upload;

  Map<String, dynamic> toAttachmentJson({String? caption}) {
    final u = upload;
    if (u == null) {
      throw StateError('Photo has not been uploaded yet');
    }
    return u.toAttachmentJson(
      caption: caption,
      capturedAt: capturedAt,
      latitude: latitude,
      longitude: longitude,
    );
  }
}

/// Trạng thái danh sách ảnh chờ gửi + upload có tiến độ từng ảnh.
/// Dùng cùng widget `PhotoPickerField`.
class PhotoPickerController extends ChangeNotifier {
  PhotoPickerController({
    this.maxPhotos = 5,
    this.purpose = MediaPurpose.reportEvidence,
    this.captureLocation = true,
    MediaUploadService? service,
    ImagePicker? picker,
  }) : _service = service,
       _picker = picker;

  final int maxPhotos;
  final String purpose;

  /// Gắn toạ độ nếu quyền vị trí ĐÃ được cấp (không hỏi quyền mới).
  final bool captureLocation;

  MediaUploadService? _service;
  ImagePicker? _picker;
  final List<PendingPhoto> _photos = [];
  CancelToken? _cancelToken;
  bool _uploading = false;
  bool _disposed = false;

  MediaUploadService get service => _service ??= MediaUploadService();

  List<PendingPhoto> get photos => List.unmodifiable(_photos);
  int get length => _photos.length;
  bool get isEmpty => _photos.isEmpty;
  bool get isNotEmpty => _photos.isNotEmpty;
  int get remaining => (maxPhotos - _photos.length).clamp(0, maxPhotos);
  bool get canAddMore => remaining > 0 && !_uploading;
  bool get isUploading => _uploading;

  /// Mở camera hoặc thư viện. Trả số ảnh đã thêm (0 nếu huỷ / đã đủ).
  /// Có thể ném lỗi của image_picker (thiếu quyền, không có camera…).
  Future<int> pick(ImageSource source) async {
    if (!canAddMore) return 0;
    final picker = _picker ??= ImagePicker();
    final List<XFile> picked;
    // image_picker tự thu nhỏ trước; service vẫn nén lại theo quy ước.
    if (source == ImageSource.camera || remaining == 1) {
      final one = await picker.pickImage(
        source: source,
        maxWidth: MediaUploadService.maxLongEdge.toDouble(),
        maxHeight: MediaUploadService.maxLongEdge.toDouble(),
        imageQuality: 90,
      );
      picked = one == null ? const [] : [one];
    } else {
      picked = await picker.pickMultiImage(
        maxWidth: MediaUploadService.maxLongEdge.toDouble(),
        maxHeight: MediaUploadService.maxLongEdge.toDouble(),
        imageQuality: 90,
        limit: remaining,
      );
    }
    if (_disposed || picked.isEmpty) return 0;
    final now = DateTime.now();
    final added = picked
        .take(remaining)
        .map((f) => PendingPhoto(f, capturedAt: now))
        .toList(growable: false);
    _photos.addAll(added);
    _notify();
    unawaited(_attachLocation(added));
    return added.length;
  }

  /// Thêm file có sẵn (vd. test, luồng khác đã chọn ảnh).
  void addFiles(Iterable<XFile> files) {
    final added = files
        .take(remaining)
        .map((f) => PendingPhoto(f))
        .toList(growable: false);
    if (added.isEmpty) return;
    _photos.addAll(added);
    _notify();
  }

  void remove(PendingPhoto photo) {
    if (_uploading) return;
    if (_photos.remove(photo)) _notify();
  }

  void clear() {
    if (_uploading) return;
    _photos.clear();
    _notify();
  }

  /// Upload mọi ảnh chưa có [PendingPhoto.upload] rồi trả danh sách
  /// ReportAttachmentRequest (JSON) theo đúng thứ tự. Rỗng nếu không có ảnh —
  /// khi đó KHÔNG gọi mạng. Lỗi ném [MediaUploadException].
  Future<List<Map<String, dynamic>>> uploadAll({String? caption}) async {
    if (_photos.isEmpty) return const [];
    final todo = _photos.where((p) => p.upload == null).toList();
    if (todo.isNotEmpty) {
      _uploading = true;
      _cancelToken = CancelToken();
      for (final p in todo) {
        p
          ..status = PendingPhotoStatus.uploading
          ..progress = 0
          ..error = null;
      }
      _notify();
      try {
        await service.uploadImages(
          todo.map((p) => p.file).toList(growable: false),
          purpose,
          cancelToken: _cancelToken,
          onProgress: (i, progress) {
            todo[i].progress = progress;
            _notify();
          },
          onUploaded: (i, upload) {
            todo[i]
              ..upload = upload
              ..status = PendingPhotoStatus.uploaded
              ..progress = 1;
            _notify();
          },
        );
      } catch (e) {
        final message = e is MediaUploadException
            ? e.message
            : 'Tải ảnh lên thất bại, vui lòng thử lại';
        for (final p in todo.where((p) => p.upload == null)) {
          p
            ..status = PendingPhotoStatus.failed
            ..error = message;
        }
        if (e is MediaUploadException) rethrow;
        throw MediaUploadException(message);
      } finally {
        _uploading = false;
        _cancelToken = null;
        _notify();
      }
    }
    return [for (final p in _photos) p.toAttachmentJson(caption: caption)];
  }

  Future<void> _attachLocation(List<PendingPhoto> photos) async {
    if (!captureLocation || kIsWeb || photos.isEmpty) return;
    try {
      final permission = await Geolocator.checkPermission();
      if (permission != LocationPermission.always &&
          permission != LocationPermission.whileInUse) {
        return;
      }
      Position? position = await Geolocator.getLastKnownPosition();
      final stale =
          position == null ||
          DateTime.now().difference(position.timestamp).inMinutes.abs() > 10;
      if (stale) {
        position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.medium,
            timeLimit: Duration(seconds: 8),
          ),
        );
      }
      if (_disposed) return;
      for (final p in photos) {
        p
          ..latitude = position.latitude
          ..longitude = position.longitude;
      }
    } catch (_) {
      // Không có vị trí thì thôi — toạ độ chỉ là thông tin phụ.
    }
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _cancelToken?.cancel();
    super.dispose();
  }
}
