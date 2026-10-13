import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_laundry_locker/features/drone_delivery/domain/entities/drone_delivery_stage.dart';
import 'package:smart_laundry_locker/features/drone_delivery/domain/entities/drone_delivery_status.dart';
import 'package:smart_laundry_locker/features/drone_delivery/infrastructure/models/drone_delivery_response.dart';
import 'package:smart_laundry_locker/features/drone_delivery/presentation/widgets/drone_delivery_detail.dart';

import '../../helpers/test_helpers.dart';

/// Read model đúng dạng order-service trả cho một đơn lấy hàng tận nhà.
Map<String, dynamic> _raw(Map<String, dynamic> extra) => {
  'orderId': 21,
  'orderCode': 'ORD-21',
  'userId': 44,
  'receiverUserId': 55,
  'status': 'AWAITING_DISPATCH',
  'deliveryStage': 'PICKUP_ASSIGNED',
  'paymentStatus': 'PAID',
  'totalPrice': 24000,
  'parcelWeightGrams': 1200,
  'parcelReturnPending': false,
  'sender': {'name': 'Nguyễn Văn Gửi', 'phone': '0901000111', 'email': 'gui@gmail.com'},
  'receiverName': 'Trần Thị Nhận',
  'receiverPhone': '0902000222',
  'receiverEmail': 'nhan@gmail.com',
  'pickup': {
    'status': 'ACCEPTED',
    'address': '12 Nguyễn Huệ, Quận 1',
    'latitude': 10.7,
    'longitude': 106.7,
    'note': 'Gọi trước khi tới',
    'distanceToSourceLockerMeters': 110,
    'technicianId': 99,
    'technicianName': 'Kỹ Thuật Viên A',
    'technicianPhone': '0909999999',
    'technicianDistanceMeters': 850,
    'pickupCode': '482913',
  },
  ...extra,
};

DroneDeliveryStatus _status([Map<String, dynamic> extra = const {}]) =>
    DroneDeliveryResponse.fromJson(_raw(extra)).toEntity();

void main() {
  setUp(() => useBusinessConfig());

  Future<void> pump(
    WidgetTester tester,
    DroneDeliveryStatus status, {
    bool isSender = true,
    bool forOperator = false,
  }) async {
    tester.view.physicalSize = const Size(1000, 6000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: DroneDeliveryDetail(
              status: status,
              isSender: isSender,
              forOperator: forOperator,
              onPay: () {},
              onCancel: () {},
              onConfirmDrop: () {},
              onDeclineSurcharge: () {},
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  test('đọc đủ lấy hàng tận nhà, liên hệ hai đầu, sự cố và người đặt đơn', () {
    final status = _status({
      'block': {
        'reason': 'DRONE_FAULT',
        'reasonLabel': 'Drone gặp sự cố',
        'ticketId': 77,
        'note': 'Drone DRONE-A1 đang lỗi',
        'at': '2026-10-12T03:00:00',
        'autoCloseAt': '2026-10-12T03:30:00',
      },
    });

    expect(status.stage, DroneDeliveryStage.pickupAssigned);
    expect(status.pickup!.isAccepted, isTrue);
    expect(status.pickup!.pickupCode, '482913');
    expect(status.pickup!.technicianName, 'Kỹ Thuật Viên A');
    expect(status.senderEmail, 'gui@gmail.com');
    expect(status.receiverEmail, 'nhan@gmail.com');
    expect(status.block!.reason, 'DRONE_FAULT');
    expect(status.block!.ticketId, 77);
    expect(status.block!.autoCloseAt, isNotNull);
    // Người gửi (44) được thao tác; người nhận (55) chỉ theo dõi.
    expect(status.isSender(44), isTrue);
    expect(status.isSender(55), isFalse);
    // Lấy hàng tận nhà: huỷ được tới khi kỹ thuật viên cầm kiện; không còn bước tự bỏ kiện.
    expect(status.canCustomerCancel, isTrue);
    expect(status.needsParcelDrop, isFalse);
    expect(_status({'deliveryStage': 'PICKED_UP'}).canCustomerCancel, isFalse);
  });

  testWidgets('người gửi thấy mã lấy hàng, kỹ thuật viên đang tới và được huỷ đơn', (
    tester,
  ) async {
    await pump(tester, _status());

    expect(find.text('Kỹ Thuật Viên A đang tới lấy hàng'), findsOneWidget);
    expect(find.byKey(const ValueKey('drone-pickup-code')), findsOneWidget);
    expect(find.text('482913'), findsOneWidget);
    expect(find.text('0909999999'), findsOneWidget);
    expect(find.text('12 Nguyễn Huệ, Quận 1'), findsOneWidget);
    expect(find.text('Huỷ đơn'), findsWidgets);
    // Timeline có hai chặng lấy hàng tận nhà.
    expect(find.text('Kỹ thuật viên đang tới lấy hàng'), findsWidgets);
    expect(find.text('Đã lấy hàng, đang mang về tủ'), findsOneWidget);
    expect(find.text('gui@gmail.com'), findsOneWidget);
    expect(find.text('nhan@gmail.com'), findsOneWidget);
    // Mã lấy hàng tận nhà là để đọc cho kỹ thuật viên, không chia sẻ cho người nhận.
    expect(find.text('Chia sẻ mã cho người nhận'), findsNothing);
  });

  testWidgets('người nhận chỉ theo dõi: không thấy mã lấy hàng, không huỷ, không thanh toán', (
    tester,
  ) async {
    // Server không trả mã lấy hàng cho người nhận; kể cả có thì app cũng không hiện.
    await pump(tester, _status({'paymentStatus': 'UNPAID', 'deliveryStage': 'AWAITING_DISPATCH'}), isSender: false);

    expect(find.byKey(const ValueKey('drone-pickup-code')), findsNothing);
    expect(find.text('Thanh toán ngay'), findsNothing);
    expect(find.text('Huỷ đơn'), findsNothing);
    expect(find.textContaining('sau khi người gửi thanh toán'), findsOneWidget);
  });

  testWidgets('kỹ thuật viên không được thấy mã lấy hàng của người gửi', (tester) async {
    await pump(tester, _status(), forOperator: true);

    expect(find.byKey(const ValueKey('drone-pickup-code')), findsNothing);
    expect(find.text('Bạn đang tới lấy hàng'), findsOneWidget);
    expect(find.text('Gọi trước khi tới'), findsOneWidget);
  });

  testWidgets('đơn đang gặp sự cố: lý do, phiếu sự cố và hạn tự hoàn tiền', (tester) async {
    await pump(
      tester,
      _status({
        'deliveryStage': 'ACCEPTED',
        'block': {
          'reason': 'DRONE_FAULT',
          'reasonLabel': 'Drone gặp sự cố',
          'ticketId': 77,
          'autoCloseAt': '2026-10-12T03:30:00',
        },
      }),
    );

    final banner = find.byKey(const ValueKey('drone-block-banner'));
    expect(banner, findsOneWidget);
    expect(find.descendant(of: banner, matching: find.textContaining('Drone gặp sự cố')), findsOneWidget);
    expect(find.descendant(of: banner, matching: find.textContaining('Phiếu sự cố: #77')), findsOneWidget);
    expect(find.descendant(of: banner, matching: find.textContaining('bạn được hoàn tiền')), findsOneWidget);
  });

  testWidgets('giao không hoàn tất: lý do, phiếu, hoàn tiền và kiện được mang trả', (
    tester,
  ) async {
    await pump(
      tester,
      _status({
        'status': 'CANCELED',
        'deliveryStage': 'FAILED',
        'paymentStatus': 'REFUND_PENDING',
        'parcelReturnPending': true,
        'parcelHeldAt': 'FLIGHT_TEAM',
        'pickup': {'status': 'PICKED_UP', 'address': '12 Nguyễn Huệ, Quận 1'},
        'failure': {
          'reason': 'DRONE_FAULT',
          'reasonLabel': 'Drone gặp sự cố',
          'ticketId': 77,
          'at': '2026-10-12T03:31:00',
        },
      }),
    );

    expect(find.text('Giao không hoàn tất'), findsWidgets);
    expect(find.textContaining('Lý do: Drone gặp sự cố'), findsOneWidget);
    expect(find.textContaining('Phiếu sự cố: #77'), findsOneWidget);
    expect(find.textContaining('Yêu cầu hoàn tiền đã được ghi nhận'), findsOneWidget);
    expect(find.textContaining('mang trả lại tại 12 Nguyễn Huệ, Quận 1'), findsOneWidget);
    // Đơn đã đóng: không còn thẻ lấy hàng, mã lấy hàng hay nút huỷ.
    expect(find.byKey(const ValueKey('drone-pickup-headline')), findsNothing);
    expect(find.text('Huỷ đơn'), findsNothing);
  });

  testWidgets('đơn cũ khách tự mang kiện ra tủ không có chặng lấy hàng tận nhà', (
    tester,
  ) async {
    final legacy = DroneDeliveryResponse.fromJson({
      'orderId': 9,
      'status': 'AWAITING_DISPATCH',
      'deliveryStage': 'ACCEPTED',
      'paymentStatus': 'PAID',
      'parcelReturnPending': false,
    }).toEntity();
    await pump(tester, legacy);

    expect(legacy.pickup, isNull);
    expect(find.text('Lấy hàng tận nhà'), findsNothing);
    expect(find.text('Đã lấy hàng, đang mang về tủ'), findsNothing);
    expect(find.text('Đang nạp hàng lên drone'), findsWidgets);
  });
}
