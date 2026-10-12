import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_laundry_locker/features/qr_login/domain/kiosk_qr_payload.dart';
import 'package:smart_laundry_locker/features/qr_login/infrastructure/data_sources/qr_login_remote_datasource.dart';
import 'package:smart_laundry_locker/features/qr_login/presentation/providers/qr_login_provider.dart';

import '../../helpers/test_helpers.dart';

const _sid = '3f2b8c1e-9d4a-4c7b-8e21-5a6f0d9c1b2e';

void main() {
  group('KioskQrPayload.tryParse', () {
    test('đọc đúng QR đăng nhập kiosk', () {
      final payload = KioskQrPayload.tryParse(
        'lockr://kiosk-login?sid=$_sid&code=AB3K9Z',
      );
      expect(payload, const KioskQrPayload(sessionId: _sid, confirmCode: 'AB3K9Z'));
    });

    test('không phân biệt hoa thường ở scheme/host, cắt khoảng trắng', () {
      final payload = KioskQrPayload.tryParse(
        '  LOCKR://Kiosk-Login?sid=$_sid&code=ab3k9z \n',
      );
      expect(payload?.sessionId, _sid);
      expect(payload?.confirmCode, 'AB3K9Z');
    });

    test('từ chối QR không phải đăng nhập kiosk', () {
      for (final raw in [
        null,
        '',
        'https://locker-drone.tech/kiosk-login?sid=$_sid&code=AB3K9Z',
        'lockr://order?id=12',
        'lockr://kiosk-login?sid=$_sid',
        'lockr://kiosk-login?code=AB3K9Z',
        'lockr://kiosk-login?sid=abc&code=AB3K9Z',
        'lockr://kiosk-login?sid=$_sid&code=AB',
        // QR cũ chỉ là chuỗi phiên dài — không còn được chấp nhận.
        'a3f2b8c19d4a4c7b8e215a6f0d9c1b2e0011',
      ]) {
        expect(KioskQrPayload.tryParse(raw), isNull, reason: '$raw');
      }
    });

    test('nhập tay: mã phiên + mã xác nhận, hoặc dán nguyên link', () {
      expect(
        KioskQrPayload.fromParts(' $_sid ', ' ab3 k9z '),
        const KioskQrPayload(sessionId: _sid, confirmCode: 'AB3K9Z'),
      );
      expect(
        KioskQrPayload.fromParts('lockr://kiosk-login?sid=$_sid&code=AB3K9Z', ''),
        const KioskQrPayload(sessionId: _sid, confirmCode: 'AB3K9Z'),
      );
      expect(KioskQrPayload.fromParts('', 'AB3K9Z'), isNull);
      expect(KioskQrPayload.fromParts(_sid, ''), isNull);
    });
  });

  group('QrLoginRemoteDataSourceImpl', () {
    late ({Dio dio, DioAdapter adapter}) mock;

    setUp(() => mock = createMockDio());

    const payload = KioskQrPayload(sessionId: _sid, confirmCode: 'AB3K9Z');
    const path = '/api/auth/kiosk/qr-sessions/$_sid/confirm';

    test('gửi confirmCode và chỉ báo thành công khi server trả confirmed', () async {
      mock.adapter.onPost(
        path,
        (server) => server.reply(
          200,
          apiOk({'lockerId': 7, 'lockerName': null, 'confirmed': true}),
        ),
        data: {'confirmCode': 'AB3K9Z'},
      );
      final result = await QrLoginRemoteDataSourceImpl(
        dioOverride: mock.dio,
      ).confirmKioskLogin(payload);
      expect(result.lockerId, 7);
      expect(result.lockerName, isNull);
    });

    test('không có confirmed: true thì không coi là thành công', () async {
      mock.adapter.onPost(
        path,
        (server) => server.reply(200, apiOk({'lockerId': 7})),
        data: {'confirmCode': 'AB3K9Z'},
      );
      expect(
        QrLoginRemoteDataSourceImpl(dioOverride: mock.dio).confirmKioskLogin(payload),
        throwsA(isA<KioskQrLoginException>()),
      );
    });

    Future<String?> errorFor(int status, Map<String, dynamic> body) async {
      mock.adapter.onPost(
        path,
        (server) => server.reply(status, body),
        data: {'confirmCode': 'AB3K9Z'},
      );
      final provider = QrLoginProvider(
        remoteDataSource: QrLoginRemoteDataSourceImpl(dioOverride: mock.dio),
      );
      final result = await provider.confirmKioskLogin(payload);
      expect(result, isNull);
      return provider.error;
    }

    test('lỗi theo mã có câu tiếng Việt rõ ràng', () async {
      expect(
        await errorFor(410, {'success': false, 'code': 'KIOSK_QR_EXPIRED', 'message': 'expired'}),
        contains('hết hạn'),
      );
      expect(
        await errorFor(409, {'success': false, 'code': 'KIOSK_QR_ALREADY_USED', 'message': 'used'}),
        contains('đã được dùng'),
      );
      expect(
        await errorFor(404, {
          'success': false,
          'code': 'KIOSK_QR_INVALID',
          'message': 'Mã xác nhận không đúng (còn 3 lần thử)',
        }),
        'Mã xác nhận không đúng (còn 3 lần thử)',
      );
      expect(
        await errorFor(403, {'success': false, 'code': 'AUTH_ACCOUNT_INACTIVE', 'message': 'x'}),
        contains('khoá'),
      );
    });

    test('404 không mã (server chưa triển khai) ⇒ báo chưa hỗ trợ', () async {
      expect(
        await errorFor(404, {'status': 404, 'error': 'Not Found'}),
        contains('chưa hỗ trợ'),
      );
    });
  });
}
