import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_laundry_locker/features/locker_ops/data/locker_ops_service.dart';

import '../../helpers/test_helpers.dart';

void main() {
  late LockerOpsService service;
  late DioAdapter adapter;

  setUp(() {
    final mock = createMockDio();
    adapter = mock.adapter;
    service = LockerOpsService(dio: mock.dio);
  });

  group('Hàng chờ nhận / ủy quyền', () {
    test('incomingOrders() gọi /api/orders/incoming', () async {
      adapter.onGet(
        '/api/orders/incoming',
        (server) => server.reply(
          200,
          apiOk([
            {'id': 3, 'readyForPickup': true, 'pickupPin': '123456'},
          ]),
        ),
        queryParameters: {'activeOnly': false},
      );
      final list = await service.incomingOrders();
      expect(list.single['pickupPin'], '123456');
    });

    test('delegatedToMe() gọi /api/orders/delegated-to-me', () async {
      adapter.onGet(
        '/api/orders/delegated-to-me',
        (server) => server.reply(
          200,
          apiOk([
            {'id': 4},
          ]),
        ),
        queryParameters: {'activeOnly': false},
      );
      expect(await service.delegatedToMe(), hasLength(1));
    });

    test('delegate() chỉ gửi trường có giá trị', () async {
      adapter.onPost(
        '/api/orders/9/delegate',
        (server) => server.reply(200, apiOk({'id': 9, 'pinCode': '654321'})),
        data: {'phone': '0909000000', 'name': 'Bình'},
      );
      final res = await service.delegate(
        9,
        phone: '0909000000',
        name: ' Bình ',
        note: '  ',
      );
      expect(res['pinCode'], '654321');
    });

    test('receiverOrderDetail() gọi /incoming/{id} hoặc /delegated-to-me/{id}', () async {
      adapter
        ..onGet(
          '/api/orders/incoming/90',
          (server) => server.reply(200, apiOk({'id': 90, 'viewerRole': 'RECEIVER'})),
        )
        ..onGet(
          '/api/orders/delegated-to-me/91',
          (server) => server.reply(200, apiOk({'id': 91, 'viewerRole': 'DELEGATE'})),
        );
      expect((await service.receiverOrderDetail(90))['viewerRole'], 'RECEIVER');
      expect(
        (await service.receiverOrderDetail(91, delegated: true))['viewerRole'],
        'DELEGATE',
      );
    });

    test('unlockWithCode() gửi {lockerId, code}', () async {
      adapter.onPost(
        '/api/iot/unlock-with-code',
        (server) => server.reply(200, apiOk({'accepted': true, 'boxId': 701})),
        data: {'lockerId': 7, 'code': '123456'},
      );
      final res = await service.unlockWithCode(7, ' 123456 ');
      expect(res['accepted'], isTrue);
    });
  });

  group('Đánh giá / khiếu nại / PIN', () {
    test('orderRating() trả null khi chưa đánh giá (404)', () async {
      adapter.onGet(
        '/api/orders/5/rating',
        (server) => server.reply(404, {
          'success': false,
          'code': 'NOT_FOUND',
          'message': 'OrderRating not found',
        }),
      );
      expect(await service.orderRating(5), isNull);
    });

    test('rateOrder() và complainOrder() gửi đúng body', () async {
      adapter
        ..onPost(
          '/api/orders/5/rate',
          (server) => server.reply(200, apiOk({'rating': 4})),
          data: {'rating': 4, 'comment': 'Tốt'},
        )
        ..onPost(
          '/api/orders/5/complaint',
          (server) => server.reply(200, apiOk({'id': 1, 'status': 'OPEN'})),
          data: {'description': 'Hàng ướt', 'type': 'DAMAGED'},
        );
      expect((await service.rateOrder(5, 4, comment: 'Tốt'))['rating'], 4);
      final c = await service.complainOrder(
        5,
        description: ' Hàng ướt ',
        type: 'DAMAGED',
      );
      expect(c['status'], 'OPEN');
    });

    test('resetPin() gọi POST /reset-pin', () async {
      adapter.onPost(
        '/api/orders/5/reset-pin',
        (server) => server.reply(200, apiOk({'id': 5, 'pinCode': '000111'})),
      );
      expect((await service.resetPin(5))['pinCode'], '000111');
    });
  });

  group('Hoàn tiền', () {
    test('requestRefund() bỏ trống số tiền ⇒ server hoàn toàn bộ', () async {
      adapter.onPost(
        '/api/payments/refund-request',
        (server) => server.reply(200, apiOk({'id': 1, 'status': 'PENDING'})),
        data: {'orderId': 8, 'reason': 'Ô hỏng'},
      );
      final res = await service.requestRefund(8, reason: ' Ô hỏng ');
      expect(res['status'], 'PENDING');
    });

    test('orderRefunds() đọc danh sách hoàn tiền của đơn', () async {
      adapter.onGet(
        '/api/payments/order/8/refunds',
        (server) => server.reply(
          200,
          apiOk([
            {'id': 1, 'status': 'REJECTED', 'rejectionReason': 'Quá hạn'},
          ]),
        ),
      );
      final list = await service.orderRefunds(8);
      expect(list.single['status'], 'REJECTED');
    });
  });

  group('Phiếu sự cố của khách', () {
    test('myReportsForOrder() lọc theo đơn bằng tham số có cấu trúc', () async {
      adapter.onGet(
        '/api/lockers/my-reports',
        (server) => server.reply(
          200,
          apiOk([
            {'id': 31, 'orderId': 8},
          ]),
        ),
        queryParameters: {'orderId': 8},
      );
      final list = await service.myReportsForOrder(8);
      expect(list.single['id'], 31);
    });

    test(
      'userReportLogs() chỉ dùng endpoint của chủ phiếu; rỗng là rỗng',
      () async {
        adapter.onGet(
          '/api/lockers/reports/31/logs',
          (server) => server.reply(200, apiOk(<Object>[])),
        );
        expect(await service.userReportLogs(31), isEmpty);
      },
    );
  });

  group('LockerOpsService.isEndpointUnavailable', () {
    DioException err(int status, Object? body) => DioException(
      requestOptions: RequestOptions(path: '/x'),
      response: Response(
        requestOptions: RequestOptions(path: '/x'),
        statusCode: status,
        data: body,
      ),
    );

    test('404 không mã nghiệp vụ = máy chủ chưa có endpoint', () {
      expect(
        LockerOpsService.isEndpointUnavailable(
          err(404, {'status': 404, 'error': 'Not Found'}),
        ),
        isTrue,
      );
    });

    test('404 có mã nghiệp vụ (vd. NOT_FOUND) không phải thiếu endpoint', () {
      expect(
        LockerOpsService.isEndpointUnavailable(
          err(404, {'code': 'NOT_FOUND', 'message': 'Order not found: 5'}),
        ),
        isFalse,
      );
      expect(LockerOpsService.isEndpointUnavailable(err(403, null)), isFalse);
    });

    test('LockerOpsException giữ nguyên câu cho người dùng', () {
      expect(
        LockerOpsService.errorMessage(
          const LockerOpsException('Câu tiếng Việt'),
        ),
        'Câu tiếng Việt',
      );
    });
  });
}
