import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_laundry_locker/features/locker_ops/data/locker_ops_service.dart';
import 'package:smart_laundry_locker/features/locker_ops/data/receiver_order.dart';
import 'package:smart_laundry_locker/features/locker_ops/presentation/pages/receiver_order_detail_page.dart';
import 'package:smart_laundry_locker/features/locker_ops/presentation/widgets/ops_widgets.dart';

import '../../helpers/test_helpers.dart';

/// Bản ghi của danh sách "Hàng chờ nhận" — dữ liệu ban đầu của màn chi tiết.
const _listItem = <String, dynamic>{
  'id': 90,
  'orderCode': 'ORD-90',
  'type': 'SEND',
  'status': 'STORING',
  'senderName': 'Nguyễn An',
  'lockerId': 7,
  'lockerCode': 'CAB-TU01',
  'lockerName': 'Tủ thư viện',
  'boxNumber': 2,
  'readyForPickup': true,
  'pickupPin': '246810',
  'qrToken': 'LLQR.abc',
};

Map<String, dynamic> _fullDetail({Map<String, dynamic> overrides = const {}}) =>
    {
      ..._listItem,
      'viewerRole': 'RECEIVER',
      'senderPhone': '0900000010',
      'receiverName': 'Lê Bình',
      'receiverPhone': '0912000111',
      'receiverEmail': 'binh@example.com',
      'lockerAddress': 'Khu A, Thư viện',
      'boxSize': 'MEDIUM',
      'boxType': 'STANDARD',
      'customerNote': 'Nhẹ tay giúp mình',
      'parcel': {
        'description': 'Sách giáo trình',
        'actualWeight': 1.5,
        'weightUnit': 'kg',
      },
      'paymentStatus': 'PAID',
      'pickupDeadline': '2099-01-01T00:00:00',
      'createdAt': '2026-10-12T01:00:00',
      'timeline': [
        {
          'code': 'CREATED',
          'label': 'Đơn được tạo',
          'occurredAt': '2026-10-12T01:00:00',
        },
        {
          'code': 'STORED',
          'label': 'Hàng đã vào ô, chờ lấy',
          'occurredAt': '2026-10-12T01:20:00',
        },
      ],
      'journey': <Map<String, dynamic>>[],
      ...overrides,
    };

class _FakeService extends LockerOpsService {
  _FakeService(this.responses) : super(dio: createMockDio().dio);

  /// Lần gọi thứ i trả phần tử i (Map ⇒ dữ liệu, Object khác ⇒ ném lỗi).
  final List<Object> responses;
  int calls = 0;
  bool? lastDelegated;

  @override
  Future<Map<String, dynamic>> receiverOrderDetail(
    int orderId, {
    bool delegated = false,
  }) async {
    lastDelegated = delegated;
    final next = responses[calls < responses.length ? calls : responses.length - 1];
    calls++;
    if (next is Map<String, dynamic>) return next;
    throw next;
  }
}

DioException _http(int status, {String? code}) {
  final options = RequestOptions(path: '/api/orders/incoming/90');
  return DioException(
    requestOptions: options,
    response: Response(
      requestOptions: options,
      statusCode: status,
      data: {
        'status': status,
        if (code != null) 'code': code,
        'message': 'Order not found: 90',
      },
    ),
  );
}

Future<void> _pump(
  WidgetTester tester,
  LockerOpsService service, {
  Map<String, dynamic> listItem = _listItem,
  bool delegatedView = false,
}) async {
  await tester.binding.setSurfaceSize(const Size(390, 3200));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    MaterialApp(
      home: ReceiverOrderDetailPage(
        order: ReceiverOrder.tryParse(listItem)!,
        service: service,
        delegatedView: delegatedView,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUp(() {
    mockSecureStorage({
      'access_token': makeFakeJwt(sub: '55', roles: ['CUSTOMER']),
    });
    useBusinessConfig();
  });

  testWidgets('hiện đủ các mục có dữ liệu và ẩn mục rỗng', (tester) async {
    final service = _FakeService([_fullDetail()]);
    await _pump(tester, service);

    expect(service.calls, 1);
    expect(service.lastDelegated, isFalse);
    expect(find.text('Chi tiết đơn nhận'), findsOneWidget);
    expect(find.text('#ORD-90'), findsOneWidget);
    expect(find.text('Bạn là người nhận của đơn này.'), findsOneWidget);

    // Mã lấy hàng + QR + thao tác của thẻ.
    final creds = tester.widget<AccessCredentials>(
      find.byType(AccessCredentials),
    );
    expect(creds.pin, '246810');
    expect(creds.showQr, isTrue);
    expect(find.text('Mở ô số 2 lấy hàng'), findsOneWidget);

    // Người gửi, người nhận.
    expect(find.text('Nguyễn An'), findsOneWidget);
    expect(find.text('0900000010'), findsOneWidget);
    expect(find.text('binh@example.com'), findsOneWidget);
    expect(find.text('Email người gửi'), findsNothing);

    // Tủ & ô.
    expect(find.text('CAB-TU01'), findsOneWidget);
    expect(find.text('Khu A, Thư viện'), findsOneWidget);
    expect(find.text('Vừa (M)'), findsOneWidget);
    expect(find.text('Ô thường'), findsOneWidget);

    // Kiện hàng.
    expect(find.text('Sách giáo trình'), findsOneWidget);
    expect(find.text('1,5 kg'), findsOneWidget);
    expect(find.text('Nhẹ tay giúp mình'), findsOneWidget);
    expect(find.text('Kích thước'), findsNothing);
    expect(find.text('Giá trị khai báo'), findsNothing);

    // Thời gian + dòng thời gian.
    expect(find.text('Hạn lấy'), findsOneWidget);
    expect(find.text('Còn lại'), findsOneWidget);
    expect(find.text('Người gửi đã thanh toán'), findsOneWidget);
    expect(find.text('Đơn được tạo'), findsOneWidget);
    expect(find.text('Hàng đã vào ô, chờ lấy'), findsOneWidget);

    // Không phải đơn drone, không có sự cố ⇒ không có hai mục này.
    expect(find.text('Hành trình drone'), findsNothing);
    expect(find.text('Sự cố'), findsNothing);
  });

  testWidgets('chưa sẵn sàng ⇒ không có mã, giải thích khi nào có', (
    tester,
  ) async {
    final notReady = <String, dynamic>{
      ..._listItem,
      'status': 'INITIALIZED',
      'readyForPickup': false,
      'pickupPin': null,
      'qrToken': null,
    };
    final service = _FakeService([_fullDetail(overrides: notReady)]);
    await _pump(tester, service, listItem: notReady);

    expect(find.byType(AccessCredentials), findsNothing);
    expect(find.textContaining('Người gửi chưa bỏ hàng vào ô'), findsOneWidget);
    expect(find.textContaining('lấy hàng'), findsWidgets);
    expect(find.text('Mở ô số 2 lấy hàng'), findsNothing);
  });

  testWidgets('đơn đã ủy quyền cho người khác ⇒ người nhận không thấy mã', (
    tester,
  ) async {
    final detail = _fullDetail(
      overrides: {
        'pickupPin': null,
        'qrToken': null,
        'delegated': true,
        'delegatedAt': '2026-10-12T02:00:00',
      },
    );
    await _pump(tester, _FakeService([detail]));

    expect(find.byType(AccessCredentials), findsNothing);
    expect(find.textContaining('mã lấy hàng không còn'), findsOneWidget);
    expect(find.text('Chủ đơn đã ủy quyền người khác lấy hộ'), findsOneWidget);
    expect(find.text('Ủy quyền lúc'), findsOneWidget);
  });

  testWidgets('tải lỗi ⇒ vẫn hiện dữ liệu danh sách, bấm Thử lại tải lại', (
    tester,
  ) async {
    final failure = _http(500, code: 'INTERNAL_ERROR');
    final service = _FakeService([failure, _fullDetail()]);
    await _pump(tester, service);

    // Dữ liệu ban đầu của danh sách vẫn hiện.
    expect(find.text('#ORD-90'), findsOneWidget);
    expect(find.text('Nguyễn An'), findsOneWidget);
    expect(find.text(LockerOpsService.errorMessage(failure)), findsOneWidget);
    expect(find.text('Thử lại'), findsOneWidget);
    expect(find.text('Sách giáo trình'), findsNothing);

    await tester.tap(find.text('Thử lại'));
    await tester.pumpAndSettle();

    expect(service.calls, 2);
    expect(find.text('Thử lại'), findsNothing);
    expect(find.text('Sách giáo trình'), findsOneWidget);
  });

  testWidgets('đơn không còn thuộc mình (404) ⇒ báo rõ bằng tiếng Việt', (
    tester,
  ) async {
    await _pump(tester, _FakeService([_http(404, code: 'NOT_FOUND')]));

    expect(
      find.textContaining('Đơn không còn trong danh sách của bạn'),
      findsOneWidget,
    );
    expect(find.text('Order not found: 90'), findsNothing);
  });

  testWidgets('đơn drone ủy quyền: đúng đường, chặng, hành trình, sự cố', (
    tester,
  ) async {
    const droneItem = {
      'id': 91,
      'orderCode': 'ORD-91',
      'type': 'DRONE_DELIVERY',
      'status': 'STORING',
      'deliveryStage': 'EN_ROUTE',
      'senderName': 'Chị Gửi',
      'lockerId': 7,
      'lockerName': 'Tủ thư viện',
      'readyForPickup': false,
      'delegated': true,
      'delegateName': 'Người Lấy Hộ',
      'delegateNote': 'Lấy giúp trước 6h',
    };
    final service = _FakeService([
      {
        ...droneItem,
        'viewerRole': 'DELEGATE',
        'delegatePhone': '0907654321',
        'sourceLockerName': 'Tủ nguồn',
        'sourceLockerCode': 'CAB-NGUON',
        'routeDistanceMeters': 1200,
        'etaMinutes': 6,
        'parcel': {
          'weightGrams': 800,
          'lengthCm': 30,
          'widthCm': 20,
          'heightCm': 10,
          'category': 'DOCUMENT',
          'declaredValue': 250000,
          'fragile': true,
        },
        'deliveryBlockReasonLabel': 'Drone gặp sự cố',
        'deliveryBlockedAt': '2026-10-12T01:35:00',
        'journey': [
          {'fromStage': 'AWAITING_DISPATCH', 'toStage': 'EN_ROUTE',
            'occurredAt': '2026-10-12T01:30:00'},
          {'fromStage': null, 'toStage': 'AWAITING_DISPATCH',
            'occurredAt': '2026-10-12T01:00:00'},
        ],
      },
    ]);
    await _pump(tester, service, listItem: droneItem, delegatedView: true);

    expect(service.lastDelegated, isTrue);
    expect(find.text('Chi tiết đơn lấy hộ'), findsOneWidget);
    expect(find.text('Người ủy quyền'), findsOneWidget);
    expect(find.text('Người Lấy Hộ (bạn)'), findsOneWidget);
    expect(find.text('Lấy giúp trước 6h'), findsOneWidget);
    expect(find.text('Tủ nguồn (CAB-NGUON)'), findsOneWidget);
    expect(find.text('1,2 km'), findsOneWidget);
    expect(find.text('800 g'), findsOneWidget);
    expect(find.text('30 × 20 × 10 cm'), findsOneWidget);
    expect(find.text('Tài liệu'), findsOneWidget);
    expect(find.text('250.000đ'), findsOneWidget);
    expect(find.text('Giao bằng drone'), findsOneWidget); // loại đơn ở đầu trang
    expect(find.text('Hành trình drone'), findsOneWidget);
    expect(find.text('Khoảng 6 phút'), findsOneWidget);
    expect(find.text('Chờ kỹ thuật viên nhận lấy hàng'), findsOneWidget);
    expect(find.text('Drone gặp sự cố'), findsOneWidget);
    expect(find.byType(AccessCredentials), findsNothing);
    expect(find.textContaining('Mã lấy hàng sẽ hiện khi drone'), findsOneWidget);
  });
}
