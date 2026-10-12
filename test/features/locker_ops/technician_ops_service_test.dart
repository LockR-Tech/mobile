import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_laundry_locker/features/locker_ops/data/locker_ops_service.dart';

import '../../helpers/test_helpers.dart';

DioException _error(int status, Map<String, dynamic>? body) => DioException(
  requestOptions: RequestOptions(path: '/x'),
  response: Response(
    requestOptions: RequestOptions(path: '/x'),
    statusCode: status,
    data: body,
  ),
  type: DioExceptionType.badResponse,
);

void main() {
  late LockerOpsService service;
  late DioAdapter adapter;
  late List<RequestOptions> captured;

  const attachment = {
    'publicId': 'lockr/reports/u7/abc',
    'version': 1726390012,
    'signature': 'sig',
    'format': 'jpg',
    'capturedAt': '2026-10-12T08:10:00',
  };

  setUp(() {
    final mock = createMockDio();
    adapter = mock.adapter;
    captured = [];
    mock.dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          captured.add(options);
          handler.next(options);
        },
      ),
    );
    service = LockerOpsService(dio: mock.dio);
  });

  group('forceOpenBox (CONTRACTS §2)', () {
    test('gửi reason, note, ảnh và reportId', () async {
      adapter.onPost(
        '/api/locker-technician/boxes/5/force-open',
        (server) => server.reply(
          200,
          apiOk({'accepted': true, 'status': 'OPENED', 'message': 'Đã mở ô #5'}),
        ),
      );

      final result = await service.forceOpenBox(
        5,
        reason: ' Cửa ô bị kẹt ',
        note: 'Đã báo khách',
        attachments: [attachment],
        reportId: 42,
      );

      expect(result.accepted, isTrue);
      expect(captured.single.data, {
        'reason': 'Cửa ô bị kẹt',
        'note': 'Đã báo khách',
        'attachments': [attachment],
        'reportId': 42,
      });
    });

    test('forceOpenBody bỏ trường rỗng; không có gì ⇒ null (web admin cũ)', () {
      expect(LockerOpsService.forceOpenBody(), isNull);
      expect(
        LockerOpsService.forceOpenBody(reason: 'Kiểm tra', note: '  ', attachments: const []),
        {'reason': 'Kiểm tra'},
      );
    });
  });

  group('extendReportSla (CONTRACTS §4)', () {
    test('gửi {hours, reason} (kèm extensionHours cho máy chủ cũ)', () async {
      adapter.onPut(
        '/api/locker-technician/reports/42/extend-sla',
        (server) => server.reply(
          200,
          apiOk({'id': 42, 'slaExtensionsUsed': 1, 'slaExtensionsMax': 2}),
        ),
      );

      final report = await service.extendReportSla(42, hours: 8, reason: ' Chờ linh kiện ');

      expect(report['slaExtensionsUsed'], 1);
      expect(captured.single.data, {
        'hours': 8,
        'extensionHours': 8,
        'reason': 'Chờ linh kiện',
      });
    });

    test('lỗi được ném ra, KHÔNG gọi sang endpoint admin', () async {
      adapter.onPut(
        '/api/locker-technician/reports/42/extend-sla',
        (server) => server.reply(409, {
          'success': false,
          'code': 'SLA_EXTENSION_LIMIT_REACHED',
          'message': 'Phiếu đã gia hạn SLA 2/2 lần — liên hệ admin nếu cần thêm thời gian',
        }),
      );

      await expectLater(
        service.extendReportSla(42, hours: 4, reason: 'x'),
        throwsA(isA<DioException>()),
      );
      expect(captured, hasLength(1));
      expect(captured.single.path, '/api/locker-technician/reports/42/extend-sla');
    });
  });

  test('releaseReport() PUT {reason}', () async {
    adapter.onPut(
      '/api/locker-technician/reports/42/release',
      (server) => server.reply(200, apiOk({'id': 42, 'status': 'OPEN'})),
    );

    final report = await service.releaseReport(42, reason: ' Đổi ca ');

    expect(report['status'], 'OPEN');
    expect(captured.single.method, 'PUT');
    expect(captured.single.data, {'reason': 'Đổi ca'});
  });

  group('techRestartDevice (CONTRACTS §3)', () {
    test('ACCEPTED', () async {
      adapter.onPost(
        '/api/locker-technician/devices/3/restart',
        (server) => server.reply(
          200,
          apiOk({
            'accepted': true,
            'status': 'ACCEPTED',
            'message': 'Bộ điều khiển tủ đã nhận lệnh và đang khởi động lại',
          }),
        ),
      );

      final result = await service.techRestartDevice(3);

      expect(result.isAccepted, isTrue);
      expect(result.displayMessage, contains('đang khởi động lại'));
    });

    test('TIMEOUT ⇒ không phải thành công', () async {
      adapter.onPost(
        '/api/locker-technician/devices/3/restart',
        (server) => server.reply(
          200,
          apiOk({'accepted': false, 'status': 'TIMEOUT'}),
        ),
      );

      final result = await service.techRestartDevice(3);

      expect(result.isAccepted, isFalse);
      expect(result.isUnconfirmed, isFalse);
      expect(result.displayMessage, contains('không phản hồi'));
    });

    test('máy chủ cũ không trả accepted ⇒ chưa xác nhận, không báo thành công', () async {
      adapter.onPost(
        '/api/locker-technician/devices/3/restart',
        (server) => server.reply(200, apiOk({'deviceId': 'DEV-1', 'lockerId': 7})),
      );

      final result = await service.techRestartDevice(3);

      expect(result.isAccepted, isFalse);
      expect(result.isUnconfirmed, isTrue);
      expect(result.displayMessage, contains('chưa trả kết quả'));
    });
  });

  test('resolveBoxIncident() ném lỗi server, không có đường dự phòng', () async {
    adapter.onPost(
      '/api/locker-technician/reports/42/resolve-box-incident',
      (server) => server.reply(400, {
        'success': false,
        'code': 'TARGET_BOX_NOT_AVAILABLE',
        'message': 'Ô đích không còn ở trạng thái trống',
      }),
    );

    await expectLater(
      service.resolveBoxIncident(
        reportId: 42,
        boxId: 5,
        action: 'RELOCATE',
        targetBoxId: 6,
      ),
      throwsA(isA<DioException>()),
    );
    // Không còn tự gọi /api/boxes/{id}/fault, ghi log giả hay trả success.
    expect(captured, hasLength(1));
  });

  group('không đăng nhập ngầm tài khoản khác (U5/K5)', () {
    test('getMaintenanceReport 403 ⇒ ném lỗi, không gọi /api/auth/login', () async {
      adapter.onGet(
        '/api/locker-technician/reports/42',
        (server) => server.reply(403, {'success': false, 'code': 'FORBIDDEN'}),
      );

      await expectLater(
        service.getMaintenanceReport(42),
        throwsA(isA<DioException>()),
      );
      expect(captured.map((o) => o.path), ['/api/locker-technician/reports/42']);
    });

    test('userReportLogs chỉ dùng endpoint của khách; rỗng = chưa có nhật ký', () async {
      adapter.onGet(
        '/api/lockers/reports/42/logs',
        (server) => server.reply(200, apiOk(<Object>[])),
      );

      final logs = await service.userReportLogs(42);

      expect(logs, isEmpty);
      expect(captured.map((o) => o.path), ['/api/lockers/reports/42/logs']);
    });

    test('reportLogs lỗi ⇒ ném ra (màn hình phân biệt lỗi với rỗng)', () async {
      adapter.onGet(
        '/api/locker-technician/reports/42/logs',
        (server) => server.reply(500, {'success': false, 'code': 'INTERNAL_ERROR'}),
      );

      await expectLater(service.reportLogs(42), throwsA(isA<DioException>()));
      expect(captured, hasLength(1));
    });
  });

  group('getActiveOrderByBox', () {
    test('404 ⇒ ô không có đơn', () async {
      adapter.onGet(
        '/api/locker-technician/boxes/5/active-order',
        (server) => server.reply(404, {'success': false, 'code': 'NOT_FOUND'}),
      );

      expect(await service.getActiveOrderByBox(5), isNull);
    });

    test('lỗi khác ⇒ ném ra (không coi như ô trống)', () async {
      adapter.onGet(
        '/api/locker-technician/boxes/5/active-order',
        (server) => server.reply(503, {'success': false, 'code': 'X'}),
      );

      await expectLater(
        service.getActiveOrderByBox(5),
        throwsA(isA<DioException>()),
      );
    });
  });

  test('allKioskReports() lỗi ⇒ ném ra, không đổi sang API admin', () async {
    adapter.onGet(
      '/api/locker-technician/reports',
      (server) => server.reply(500, {'success': false, 'code': 'INTERNAL_ERROR'}),
    );

    await expectLater(service.allKioskReports(), throwsA(isA<DioException>()));
    expect(captured, hasLength(1));
    expect(captured.single.queryParameters, {'all': true});
  });

  test('myRatingAverage / myPerformance theo vai trò KTV drone (D3)', () async {
    adapter
      ..onGet(
        '/api/drone-technician/my-rating-average',
        (server) => server.reply(200, apiOk({'count': 0, 'average': 0.0})),
      )
      ..onGet(
        '/api/drone-technician/my-performance',
        (server) => server.reply(200, apiOk({'penaltyLevel': 'NORMAL'})),
      );

    final rating = await service.myRatingAverage(drone: true);
    final perf = await service.myPerformance(drone: true);

    expect(rating['count'], 0);
    expect(perf['penaltyLevel'], 'NORMAL');
  });

  group('errorMessage — mã lỗi luồng KTV', () {
    test('ưu tiên câu server (có số liệu) cho SLA_EXTENSION_*', () {
      final message = LockerOpsService.errorMessage(_error(400, {
        'code': 'SLA_EXTENSION_HOURS_EXCEEDED',
        'message': 'Mỗi lần chỉ được gia hạn tối đa 8 giờ',
      }));
      expect(message, 'Mỗi lần chỉ được gia hạn tối đa 8 giờ');
    });

    test('server không gửi câu ⇒ câu tiếng Việt dự phòng theo mã', () {
      final message = LockerOpsService.errorMessage(
        _error(409, {'code': 'SLA_EXTENSION_LIMIT_REACHED'}),
      );
      expect(message, contains('hết lượt tự gia hạn'));
    });

    test('HANDOVER_FAILED luôn là câu tiếng Việt cố định (không lộ lỗi kỹ thuật)', () {
      final message = LockerOpsService.errorMessage(_error(400, {
        'code': 'HANDOVER_FAILED',
        'message': 'Bàn giao thất bại: [409 Conflict] during [POST] ...',
      }));
      expect(message, contains('mã PIN 6 số hoặc mã QR'));
    });

    test('INTERNAL_ERROR / 404 không mã ⇒ tiếng Việt, không tiếng Anh', () {
      expect(
        LockerOpsService.errorMessage(_error(500, {
          'code': 'INTERNAL_ERROR',
          'message': 'Unexpected server error',
        })),
        isNot(contains('Unexpected')),
      );
      expect(
        LockerOpsService.errorMessage(_error(404, {'error': 'Not Found', 'message': ''})),
        contains('chưa hỗ trợ'),
      );
    });

    test('TECHNICIAN_SLA_RESTRICTED được nhận diện qua errorCode', () {
      final error = _error(400, {
        'code': 'TECHNICIAN_SLA_RESTRICTED',
        'message': 'Kỹ thuật viên đang có 3 sự cố trễ hạn SLA.',
      });
      expect(LockerOpsService.errorCode(error), 'TECHNICIAN_SLA_RESTRICTED');
      expect(LockerOpsService.errorMessage(error), contains('3 sự cố trễ hạn'));
    });
  });

  test('lockerPublicSettings() đọc cấu hình locker công khai', () async {
    adapter.onGet(
      '/api/settings/locker/public',
      (server) => server.reply(
        200,
        apiOk({
          'app.maintenance.sla-max-extensions': 2,
          'app.maintenance.sla-max-hours-per-extension': 24,
        }),
      ),
    );

    final settings = await service.lockerPublicSettings();

    expect(settings['app.maintenance.sla-max-extensions'], 2);
  });
}
