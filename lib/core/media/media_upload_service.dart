import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
// Cũng export XFile (cross_file) dùng chung với image_picker.
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:smart_laundry_locker/core/media/media_upload.dart';
import 'package:smart_laundry_locker/core/network/dio_client.dart';

/// Bytes đã sẵn sàng gửi lên Cloudinary.
class PreparedImage {
  const PreparedImage(this.bytes, this.filename, {this.contentType});

  final Uint8List bytes;
  final String filename;
  final DioMediaType? contentType;
}

typedef ImagePreparer = Future<PreparedImage> Function(XFile file);

/// Upload ảnh trực tiếp lên Cloudinary theo chữ ký của backend
/// (docs/01-overview/media-storage.md):
/// 1. xin chữ ký qua API gateway (có JWT),
/// 2. POST multipart thẳng tới Cloudinary bằng một [Dio] riêng — KHÔNG gửi
///    header `Authorization`, không đi qua interceptor của app,
/// 3. trả [MediaUpload] để gửi kèm API nghiệp vụ.
class MediaUploadService {
  MediaUploadService({Dio? apiDio, Dio? uploadDio, ImagePreparer? preparer})
    : _apiDioOverride = apiDio,
      _uploadDioOverride = uploadDio,
      _preparer = preparer;

  static const signaturesPath = '/api/media/upload-signatures';
  static const maxConcurrentUploads = 3;
  static const maxSignaturesPerRequest = 10;
  static const maxLongEdge = 1920;
  static const jpegQuality = 80;

  final Dio? _apiDioOverride;
  final Dio? _uploadDioOverride;
  final ImagePreparer? _preparer;

  // Lazy: tạo service không cần DioClient đã init (widget test, dialog chưa có ảnh).
  Dio get _apiDio => _apiDioOverride ?? DioClient.instance.dio;

  late final Dio _uploadDio = () {
    final dio =
        _uploadDioOverride ??
        Dio(
          BaseOptions(
            connectTimeout: const Duration(seconds: 30),
            sendTimeout: const Duration(minutes: 3),
            receiveTimeout: const Duration(seconds: 60),
          ),
        );
    // Phòng hờ: tuyệt đối không mang JWT sang api.cloudinary.com.
    dio.options.headers.remove('Authorization');
    dio.options.headers.remove('authorization');
    return dio;
  }();

  /// `POST /api/media/upload-signatures {purpose, count}` (count 1–10).
  Future<UploadSignatureBatch> requestSignatures(
    String purpose,
    int count, {
    CancelToken? cancelToken,
  }) async {
    final safeCount = count.clamp(1, maxSignaturesPerRequest);
    try {
      final res = await _apiDio.post<dynamic>(
        signaturesPath,
        data: {'purpose': purpose, 'count': safeCount},
        cancelToken: cancelToken,
      );
      final body = res.data;
      final data = body is Map ? body['data'] : null;
      if (data is! Map) {
        throw const MediaUploadException(
          'Không lấy được quyền tải ảnh, vui lòng thử lại',
          code: 'SIGNATURE_BAD_RESPONSE',
        );
      }
      final batch = UploadSignatureBatch.fromJson(
        Map<String, dynamic>.from(data),
      );
      if (batch.uploadUrl.isEmpty || batch.uploads.length < safeCount) {
        throw const MediaUploadException(
          'Không lấy được quyền tải ảnh, vui lòng thử lại',
          code: 'SIGNATURE_BAD_RESPONSE',
        );
      }
      return batch;
    } on DioException catch (e) {
      throw MediaUploadException.fromApi(e);
    }
  }

  /// Upload 1 file lên Cloudinary với 1 phần tử chữ ký.
  /// Gửi **toàn bộ** `fields` (giữ nguyên giá trị) + `file`.
  Future<MediaUpload> uploadToCloudinary(
    XFile file,
    UploadSignatureItem signature, {
    required String uploadUrl,
    int? maxBytes,
    void Function(double progress)? onProgress,
    CancelToken? cancelToken,
    bool compress = true,
  }) async {
    final prepared = compress ? await _prepare(file) : await _readRaw(file);
    if (maxBytes != null && maxBytes > 0 && prepared.bytes.length > maxBytes) {
      final mb = (maxBytes / (1024 * 1024)).toStringAsFixed(0);
      throw MediaUploadException(
        'Ảnh quá lớn (tối đa $mb MB), vui lòng chọn ảnh khác',
        code: 'FILE_TOO_LARGE',
      );
    }

    final form = FormData();
    signature.fields.forEach((key, value) {
      form.fields.add(MapEntry(key, value));
    });
    form.files.add(
      MapEntry(
        'file',
        MultipartFile.fromBytes(
          prepared.bytes,
          filename: prepared.filename,
          contentType: prepared.contentType,
        ),
      ),
    );

    try {
      onProgress?.call(0);
      final res = await _uploadDio.post<dynamic>(
        uploadUrl,
        data: form,
        cancelToken: cancelToken,
        options: Options(responseType: ResponseType.json),
        onSendProgress: onProgress == null
            ? null
            : (sent, total) {
                if (total > 0) {
                  // Giữ 1 chút cho bước chờ phản hồi Cloudinary.
                  onProgress((sent / total * 0.95).clamp(0.0, 0.95));
                }
              },
      );
      final body = res.data;
      if (body is! Map) {
        throw const MediaUploadException(
          'Máy chủ ảnh trả về dữ liệu không hợp lệ, vui lòng thử lại',
          code: 'CLOUDINARY_BAD_RESPONSE',
        );
      }
      final upload = MediaUpload.fromCloudinary(
        Map<String, dynamic>.from(body),
      );
      onProgress?.call(1);
      return upload;
    } on DioException catch (e) {
      throw MediaUploadException.fromCloudinary(e);
    }
  }

  /// Xin N chữ ký một lần (chia lô 10) rồi upload song song tối đa 3 file.
  /// Kết quả giữ đúng thứ tự [files]. Lỗi đầu tiên dừng các file chưa bắt đầu
  /// và được ném ra; [onUploaded] báo từng file thành công để caller giữ lại
  /// (không phải upload lại khi thử lần 2).
  Future<List<MediaUpload>> uploadImages(
    List<XFile> files,
    String purpose, {
    void Function(int index, double progress)? onProgress,
    void Function(int index, MediaUpload upload)? onUploaded,
    CancelToken? cancelToken,
    bool compress = true,
  }) async {
    if (files.isEmpty) return const [];
    final results = List<MediaUpload?>.filled(files.length, null);
    for (
      var start = 0;
      start < files.length;
      start += maxSignaturesPerRequest
    ) {
      final end = math.min(start + maxSignaturesPerRequest, files.length);
      final batch = await requestSignatures(
        purpose,
        end - start,
        cancelToken: cancelToken,
      );
      await _runPool(
        [for (var i = start; i < end; i++) i],
        maxConcurrentUploads,
        (i) async {
          final upload = await uploadToCloudinary(
            files[i],
            batch.uploads[i - start],
            uploadUrl: batch.uploadUrl,
            maxBytes: batch.maxBytes,
            cancelToken: cancelToken,
            compress: compress,
            onProgress: onProgress == null ? null : (p) => onProgress(i, p),
          );
          results[i] = upload;
          onUploaded?.call(i, upload);
        },
      );
    }
    return results.cast<MediaUpload>();
  }

  /// Tiện ích 1 ảnh (avatar…).
  Future<MediaUpload> uploadImage(
    XFile file,
    String purpose, {
    void Function(double progress)? onProgress,
    CancelToken? cancelToken,
    bool compress = true,
  }) async {
    final uploads = await uploadImages(
      [file],
      purpose,
      onProgress: onProgress == null ? null : (_, p) => onProgress(p),
      cancelToken: cancelToken,
      compress: compress,
    );
    return uploads.first;
  }

  Future<void> _runPool(
    List<int> items,
    int concurrency,
    Future<void> Function(int item) task,
  ) async {
    var next = 0;
    Object? firstError;
    StackTrace? firstStack;
    Future<void> worker() async {
      while (firstError == null && next < items.length) {
        final item = items[next++];
        try {
          await task(item);
        } catch (e, st) {
          firstError ??= e;
          firstStack ??= st;
        }
      }
    }

    await Future.wait([
      for (var i = 0; i < math.min(concurrency, items.length); i++) worker(),
    ]);
    if (firstError != null) {
      Error.throwWithStackTrace(firstError!, firstStack ?? StackTrace.current);
    }
  }

  Future<PreparedImage> _prepare(XFile file) {
    final preparer = _preparer;
    if (preparer != null) return preparer(file);
    return compressForUpload(file);
  }

  Future<PreparedImage> _readRaw(XFile file) async =>
      PreparedImage(await file.readAsBytes(), _filenameOf(file));

  /// Nén: cạnh dài ≤ [maxLongEdge], JPEG chất lượng [jpegQuality], bỏ EXIF
  /// (xoay ảnh đúng chiều trước). Web: gửi thẳng bytes gốc.
  /// Nén lỗi (định dạng lạ…) ⇒ gửi bytes gốc để Cloudinary tự kiểm tra.
  static Future<PreparedImage> compressForUpload(XFile file) async {
    final original = await file.readAsBytes();
    if (kIsWeb) return PreparedImage(original, _filenameOf(file));
    try {
      final size = await _decodeSize(original);
      var minSide = maxLongEdge;
      if (size != null) {
        final long = math.max(size.$1, size.$2);
        final short = math.min(size.$1, size.$2);
        // flutter_image_compress co theo min(w/minW, h/minH) ⇒ đặt minW=minH
        // theo tỉ lệ cạnh ngắn/cạnh dài để cạnh DÀI ra đúng maxLongEdge,
        // không phụ thuộc chiều xoay EXIF.
        minSide = long <= maxLongEdge
            ? short
            : math.max(1, (maxLongEdge * short / long).round());
      }
      final out = await FlutterImageCompress.compressWithList(
        original,
        minWidth: minSide,
        minHeight: minSide,
        quality: jpegQuality,
        format: CompressFormat.jpeg,
      );
      if (out.isEmpty) return PreparedImage(original, _filenameOf(file));
      return PreparedImage(
        out,
        'photo_${DateTime.now().millisecondsSinceEpoch}.jpg',
        contentType: DioMediaType('image', 'jpeg'),
      );
    } catch (_) {
      return PreparedImage(original, _filenameOf(file));
    }
  }

  static Future<(int, int)?> _decodeSize(Uint8List bytes) async {
    ui.ImmutableBuffer? buffer;
    ui.ImageDescriptor? descriptor;
    try {
      buffer = await ui.ImmutableBuffer.fromUint8List(bytes);
      descriptor = await ui.ImageDescriptor.encoded(buffer);
      if (descriptor.width <= 0 || descriptor.height <= 0) return null;
      return (descriptor.width, descriptor.height);
    } catch (_) {
      return null;
    } finally {
      descriptor?.dispose();
      buffer?.dispose();
    }
  }

  static String _filenameOf(XFile file) {
    final name = file.name.trim();
    if (name.isNotEmpty) return name;
    return 'photo_${DateTime.now().millisecondsSinceEpoch}.jpg';
  }
}
