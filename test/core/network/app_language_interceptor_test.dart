import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_laundry_locker/core/l10n/l10n.dart';
import 'package:smart_laundry_locker/core/network/dio_client.dart';

/// Ghi lại header của request rồi trả 200 rỗng, không gọi mạng thật.
class _CaptureAdapter implements HttpClientAdapter {
  Map<String, dynamic>? headers;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    headers = options.headers;
    return ResponseBody.fromString(
      '{}',
      200,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  tearDown(() => L10n.load(L10n.vi));

  test('mỗi request gửi ngôn ngữ app đang chọn', () async {
    final adapter = _CaptureAdapter();
    final dio = Dio(BaseOptions(baseUrl: 'http://localhost'))
      ..httpClientAdapter = adapter
      ..interceptors.add(AppLanguageInterceptor());

    await dio.get<dynamic>('/api/notifications');
    expect(adapter.headers?[AppLanguageInterceptor.header], 'vi');

    // Đổi ngôn ngữ có hiệu lực ngay ở request kế tiếp.
    L10n.load(L10n.en);
    await dio.get<dynamic>('/api/notifications');
    expect(adapter.headers?[AppLanguageInterceptor.header], 'en');
  });
}
