import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:smart_laundry_locker/core/media/media.dart';

import '../../helpers/test_helpers.dart';

/// Giả lập Cloudinary: ghi lại request, trả JSON cố định.
class _FakeCloudinaryAdapter implements HttpClientAdapter {
  _FakeCloudinaryAdapter({this.statusCode = 200, this.body});

  final int statusCode;
  final Map<String, dynamic>? body;
  final requests = <RequestOptions>[];
  var _counter = 0;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    // Tiêu thụ body multipart để dio hoàn tất onSendProgress.
    if (requestStream != null) await requestStream.drain<void>();
    _counter++;
    final fields = (options.data as FormData).fields;
    final publicId = fields
        .firstWhere(
          (f) => f.key == 'public_id',
          orElse: () => const MapEntry('', ''),
        )
        .value;
    final payload =
        body ??
        {
          'public_id': publicId,
          'version': 1726390000 + _counter,
          'signature': 'cloud-sig-$_counter',
          'format': 'jpg',
          'bytes': 2048,
          'width': 1600,
          'height': 1200,
          'secure_url': 'https://res.cloudinary.com/demo/$publicId.jpg',
        };
    return ResponseBody.fromString(
      jsonEncode(payload),
      statusCode,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

Map<String, dynamic> _signatureData(int count, {int maxBytes = 10485760}) => {
  'provider': 'CLOUDINARY',
  'cloudName': 'demo',
  'uploadUrl': 'https://api.cloudinary.com/v1_1/demo/image/upload',
  'maxBytes': maxBytes,
  'allowedFormats': ['jpg', 'jpeg', 'png', 'webp', 'heic', 'heif'],
  'expiresAt': '2026-09-15T09:10:00',
  'uploads': [
    for (var i = 0; i < count; i++)
      {
        'publicId': 'lockr/reports/u42/id$i',
        'fields': {
          'api_key': '123456',
          'timestamp': 1726390000,
          'public_id': 'lockr/reports/u42/id$i',
          'allowed_formats': 'jpg,jpeg,png,webp,heic,heif',
          'signature': 'server-sig-$i',
        },
      },
  ],
};

XFile _photo(String name, [int size = 16]) =>
    XFile.fromData(Uint8List.fromList(List.filled(size, 7)), name: name);

void main() {
  late Dio apiDio;
  late DioAdapter apiAdapter;
  late List<RequestOptions> apiRequests;
  late Dio uploadDio;
  late _FakeCloudinaryAdapter cloudinary;
  late MediaUploadService service;

  setUp(() {
    final mock = createMockDio();
    apiDio = mock.dio;
    apiAdapter = mock.adapter;
    // Dio của API gateway mang JWT như DioClient thật.
    apiDio.options.headers['Authorization'] = 'Bearer secret-jwt';
    apiRequests = [];
    apiDio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          apiRequests.add(options);
          handler.next(options);
        },
      ),
    );

    cloudinary = _FakeCloudinaryAdapter();
    // Cố tình gắn Authorization để chắc service tự gỡ trước khi gọi Cloudinary.
    uploadDio = Dio(BaseOptions(headers: {'Authorization': 'Bearer leak'}))
      ..httpClientAdapter = cloudinary;

    service = MediaUploadService(
      apiDio: apiDio,
      uploadDio: uploadDio,
      preparer: (file) async =>
          PreparedImage(await file.readAsBytes(), 'prepared.jpg'),
    );
  });

  group('requestSignatures()', () {
    test('posts purpose/count and parses the batch', () async {
      apiAdapter.onPost(
        MediaUploadService.signaturesPath,
        (server) => server.reply(200, apiOk(_signatureData(2))),
      );

      final batch = await service.requestSignatures(
        MediaPurpose.reportEvidence,
        2,
      );

      expect(apiRequests.single.method, 'POST');
      expect(apiRequests.single.data, {
        'purpose': 'REPORT_EVIDENCE',
        'count': 2,
      });
      expect(
        batch.uploadUrl,
        'https://api.cloudinary.com/v1_1/demo/image/upload',
      );
      expect(batch.maxBytes, 10485760);
      expect(batch.uploads, hasLength(2));
      expect(batch.uploads.first.fields['timestamp'], '1726390000');
      expect(batch.uploads.first.publicId, 'lockr/reports/u42/id0');
    });

    test('maps 503 MEDIA_STORAGE_DISABLED to a friendly exception', () async {
      apiAdapter.onPost(
        MediaUploadService.signaturesPath,
        (server) => server.reply(503, {
          'success': false,
          'code': 'MEDIA_STORAGE_DISABLED',
          'message': 'Media storage disabled',
        }),
      );

      await expectLater(
        service.requestSignatures(MediaPurpose.avatar, 1),
        throwsA(
          isA<MediaUploadException>()
              .having((e) => e.storageDisabled, 'storageDisabled', isTrue)
              .having((e) => e.message, 'message', contains('tạm tắt')),
        ),
      );
    });
  });

  group('uploadToCloudinary()', () {
    test(
      'forwards every signed field + file and sends NO Authorization',
      () async {
        final batch = UploadSignatureBatch.fromJson(_signatureData(1));
        final progress = <double>[];

        final upload = await service.uploadToCloudinary(
          _photo('broken.jpg'),
          batch.uploads.single,
          uploadUrl: batch.uploadUrl,
          maxBytes: batch.maxBytes,
          onProgress: progress.add,
        );

        final request = cloudinary.requests.single;
        expect(request.uri.toString(), batch.uploadUrl);
        expect(request.method, 'POST');
        expect(
          request.headers.keys.map((k) => k.toLowerCase()),
          isNot(contains('authorization')),
        );
        final form = request.data as FormData;
        expect(Map.fromEntries(form.fields), {
          'api_key': '123456',
          'timestamp': '1726390000',
          'public_id': 'lockr/reports/u42/id0',
          'allowed_formats': 'jpg,jpeg,png,webp,heic,heif',
          'signature': 'server-sig-0',
        });
        expect(form.files.single.key, 'file');
        expect(form.files.single.value.filename, 'prepared.jpg');

        expect(upload.publicId, 'lockr/reports/u42/id0');
        expect(upload.signature, 'cloud-sig-1');
        expect(upload.toJson(), {
          'publicId': 'lockr/reports/u42/id0',
          'version': 1726390001,
          'signature': 'cloud-sig-1',
          'format': 'jpg',
          'bytes': 2048,
          'width': 1600,
          'height': 1200,
        });
        expect(progress.last, 1.0);
        // JWT chỉ nằm ở Dio của gateway.
        expect(apiDio.options.headers['Authorization'], 'Bearer secret-jwt');
      },
    );

    test(
      'rejects files larger than maxBytes without calling Cloudinary',
      () async {
        final batch = UploadSignatureBatch.fromJson(_signatureData(1));

        await expectLater(
          service.uploadToCloudinary(
            _photo('big.jpg', 64),
            batch.uploads.single,
            uploadUrl: batch.uploadUrl,
            maxBytes: 10,
          ),
          throwsA(
            isA<MediaUploadException>().having(
              (e) => e.code,
              'code',
              'FILE_TOO_LARGE',
            ),
          ),
        );
        expect(cloudinary.requests, isEmpty);
      },
    );

    test('maps Cloudinary errors to Vietnamese messages', () async {
      final failing = _FakeCloudinaryAdapter(
        statusCode: 400,
        body: {
          'error': {'message': 'Stale request - reported time is 1 hour ago'},
        },
      );
      final svc = MediaUploadService(
        apiDio: apiDio,
        uploadDio: Dio()..httpClientAdapter = failing,
      );
      final batch = UploadSignatureBatch.fromJson(_signatureData(1));

      await expectLater(
        svc.uploadToCloudinary(
          _photo('a.jpg'),
          batch.uploads.single,
          uploadUrl: batch.uploadUrl,
          compress: false,
        ),
        throwsA(
          isA<MediaUploadException>().having(
            (e) => e.message,
            'message',
            contains('hết hạn'),
          ),
        ),
      );
    });
  });

  group('uploadImages()', () {
    test('requests N signatures once and keeps file order', () async {
      apiAdapter.onPost(
        MediaUploadService.signaturesPath,
        (server) => server.reply(200, apiOk(_signatureData(3))),
      );
      final uploaded = <int>[];

      final uploads = await service.uploadImages(
        [_photo('1.jpg'), _photo('2.jpg'), _photo('3.jpg')],
        MediaPurpose.reportEvidence,
        onUploaded: (i, _) => uploaded.add(i),
      );

      expect(apiRequests, hasLength(1));
      expect(apiRequests.single.data, {
        'purpose': 'REPORT_EVIDENCE',
        'count': 3,
      });
      expect(cloudinary.requests, hasLength(3));
      expect(uploads.map((u) => u.publicId), [
        'lockr/reports/u42/id0',
        'lockr/reports/u42/id1',
        'lockr/reports/u42/id2',
      ]);
      expect(uploaded..sort(), [0, 1, 2]);
    });

    test('does nothing for an empty list', () async {
      final uploads = await service.uploadImages(
        const [],
        MediaPurpose.reportEvidence,
      );
      expect(uploads, isEmpty);
      expect(apiRequests, isEmpty);
    });
  });

  group('models', () {
    test('toAttachmentJson adds caption/capturedAt/location', () {
      const upload = MediaUpload(
        publicId: 'p',
        version: 1,
        signature: 's',
        format: 'jpg',
      );
      final json = upload.toAttachmentJson(
        caption: ' Bản lề lệch ',
        capturedAt: DateTime(2026, 9, 15, 8, 10, 5),
        latitude: 10.77,
        longitude: 106.7,
      );
      expect(json, {
        'publicId': 'p',
        'version': 1,
        'signature': 's',
        'format': 'jpg',
        'caption': 'Bản lề lệch',
        'capturedAt': '2026-09-15T08:10:05',
        'latitude': 10.77,
        'longitude': 106.7,
      });
    });

    test('ReportAttachment parses response and groups by stage', () {
      final list = ReportAttachment.listFrom([
        {
          'id': 9,
          'stage': 'RESOLUTION',
          'url': 'https://res.cloudinary.com/demo/9.jpg',
          'thumbnailUrl': 'https://res.cloudinary.com/demo/t/9.jpg',
          'capturedAt': '2026-09-15T08:10:00',
        },
        {'id': 7, 'stage': 'INSPECTION', 'url': 'https://x/7.jpg'},
        {'id': 8, 'stage': 'REPORT', 'url': 'https://x/8.jpg'},
        {'id': 10, 'stage': 'REPORT', 'url': ''},
      ]);

      expect(list, hasLength(3));
      expect(list.first.previewUrl, 'https://res.cloudinary.com/demo/t/9.jpg');
      expect(list[1].previewUrl, 'https://x/7.jpg');
      expect(list.first.capturedAt, DateTime(2026, 9, 15, 8, 10));

      final groups = ReportAttachment.groupByStage(list);
      expect(groups.keys, ['REPORT', 'INSPECTION', 'RESOLUTION']);
      expect(ReportAttachment.listFrom(null), isEmpty);
    });
  });

  group('PhotoPickerController', () {
    test('uploadAll() without photos makes no network call', () async {
      final controller = PhotoPickerController(service: service);
      expect(await controller.uploadAll(), isEmpty);
      expect(apiRequests, isEmpty);
      controller.dispose();
    });

    test('uploadAll() reuses finished uploads on retry', () async {
      apiAdapter.onPost(
        MediaUploadService.signaturesPath,
        (server) => server.reply(200, apiOk(_signatureData(2))),
      );
      final controller = PhotoPickerController(
        service: service,
        captureLocation: false,
      )..addFiles([_photo('1.jpg'), _photo('2.jpg')]);

      final first = await controller.uploadAll(caption: 'Kẹt cửa');
      final second = await controller.uploadAll();

      expect(first, hasLength(2));
      expect(first.first['caption'], 'Kẹt cửa');
      expect(first.first['capturedAt'], isA<String>());
      expect(second.map((a) => a['publicId']), first.map((a) => a['publicId']));
      expect(apiRequests, hasLength(1));
      expect(cloudinary.requests, hasLength(2));
      controller.dispose();
    });
  });
}
