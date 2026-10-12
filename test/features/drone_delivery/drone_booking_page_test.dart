import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_laundry_locker/core/config/business_config.dart';
import 'package:smart_laundry_locker/features/drone_delivery/domain/entities/drone_booking.dart';
import 'package:smart_laundry_locker/features/drone_delivery/presentation/pages/drone_booking_page.dart';
import 'package:smart_laundry_locker/features/locker_ops/presentation/widgets/order_payment_sheet.dart';

import '../../helpers/test_helpers.dart';

const _pickup = PickupLocation(
  latitude: 10.7,
  longitude: 106.7,
  address: '12 Nguyễn Huệ, Quận 1',
);

const _lockers = [
  {'id': 5, 'name': 'Locker B', 'landingPad': true, 'status': 'ACTIVE'},
  {'id': 6, 'name': 'Locker C', 'landingPad': true, 'status': 'ACTIVE'},
  // Không có bãi đáp / đang bảo trì: không chọn được làm tủ nhận.
  {'id': 7, 'name': 'Locker D', 'landingPad': false, 'status': 'ACTIVE'},
  {'id': 8, 'name': 'Locker E', 'landingPad': true, 'status': 'MAINTENANCE'},
];

void main() {
  setUp(() => useBusinessConfig());

  late List<DroneBookingRequest> created;
  late List<String> messages;
  late List<String> steps;
  late List<Map<String, Object>> quotes;

  setUp(() {
    created = [];
    messages = [];
    steps = [];
    quotes = [];
  });

  Future<void> pump(
    WidgetTester tester, {
    int? destination = 5,
    DroneContact? sender = const DroneContact(
      name: 'Nguyễn Văn Gửi',
      phone: '0901000111',
      email: 'gui@gmail.com',
    ),
    Object? quoteError,
  }) async {
    tester.view.physicalSize = const Size(1200, 5000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        home: DroneBookingPage(
          initialDestinationLockerId: destination,
          preferredBoxId: 9001,
          initialSender: sender,
          destinationLockers: _lockers,
          pickLocation: (context, current) async => _pickup,
          loadQuote: ({
            required destinationLockerId,
            required pickupLatitude,
            required pickupLongitude,
            required parcelWeightGrams,
          }) async {
            quotes.add({
              'destination': destinationLockerId,
              'weight': parcelWeightGrams,
            });
            if (quoteError != null) throw quoteError;
            return const DroneQuote(
              sourceLockerName: 'Locker A',
              sourceLockerAddress: '1 Lê Lợi',
              pickupDistanceMeters: 110,
              routeDistanceMeters: 2400,
              fee: 24000,
            );
          },
          createOrder: (request, key) async {
            created.add(request);
            steps.add('create');
            return {'orderId': 77, 'totalPrice': 24000};
          },
          payOrder: (context, {required orderId, required total}) async {
            steps.add('pay $orderId $total');
            return OrderPaymentOutcome.paid;
          },
          onBooked: (orderId) => steps.add('booked $orderId'),
          showMessage: messages.add,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> submit(WidgetTester tester) async {
    await tester.tap(find.byKey(const ValueKey('drone-submit')));
    await tester.pumpAndSettle();
  }

  Future<void> type(WidgetTester tester, String key, String text) =>
      tester.enterText(find.byKey(ValueKey(key)), text);

  Future<void> fillReceiver(WidgetTester tester) async {
    await type(tester, 'drone-receiver-name', 'Trần Thị Nhận');
    await type(tester, 'drone-receiver-phone', '0902000222');
    await type(tester, 'drone-receiver-email', 'nhan@gmail.com');
  }

  testWidgets('bắt buộc đủ điểm lấy hàng, người gửi, người nhận, loại hàng, cam kết', (
    tester,
  ) async {
    await pump(tester);

    await submit(tester);
    expect(messages.last, 'Chọn điểm lấy hàng');

    await tester.tap(find.byKey(const ValueKey('drone-pickup-location')));
    await tester.pumpAndSettle();
    expect(find.text('12 Nguyễn Huệ, Quận 1'), findsOneWidget);

    // Người gửi điền sẵn từ tài khoản; xoá email thì không qua.
    await type(tester, 'drone-sender-email', 'khong-phai-email');
    await submit(tester);
    expect(messages.last, 'Email người gửi không hợp lệ');
    await type(tester, 'drone-sender-email', 'gui@gmail.com');

    await submit(tester);
    expect(messages.last, 'Nhập tên người nhận');
    await type(tester, 'drone-receiver-name', 'Trần Thị Nhận');
    await submit(tester);
    expect(messages.last, 'Số điện thoại người nhận không hợp lệ');
    await type(tester, 'drone-receiver-phone', '0902000222');
    // Email người nhận là bắt buộc: thư báo đơn và mã mở ô đi qua email.
    await submit(tester);
    expect(messages.last, 'Email người nhận không hợp lệ');
    await type(tester, 'drone-receiver-email', 'nhan@gmail.com');

    await submit(tester);
    expect(messages.last, 'Chọn loại hàng');
    await tester.tap(find.byKey(const ValueKey('drone-category-DOCUMENT')));
    await tester.pumpAndSettle();

    await submit(tester);
    expect(messages.last, contains('cam kết'));
    expect(created, isEmpty);
  });

  testWidgets('gửi đủ điểm lấy hàng, liên hệ hai đầu và khai báo kiện; trả tiền rồi sang theo dõi', (
    tester,
  ) async {
    await pump(tester);
    await tester.tap(find.byKey(const ValueKey('drone-pickup-location')));
    await tester.pumpAndSettle();
    await fillReceiver(tester);
    await type(tester, 'drone-pickup-note', 'Gọi trước khi tới');
    await tester.tap(find.byKey(const ValueKey('drone-weight-2000')));
    await tester.tap(find.byKey(const ValueKey('drone-category-ELECTRONICS')));
    await tester.tap(find.byKey(const ValueKey('drone-parcel-fragile')));
    await type(tester, 'drone-parcel-length', '20');
    await type(tester, 'drone-parcel-width', '30');
    await type(tester, 'drone-parcel-height', '25');
    await type(tester, 'drone-parcel-value', '500000');
    await tester.tap(find.byKey(const ValueKey('drone-prohibited-declaration')));
    await tester.pumpAndSettle();

    // Báo trước tủ gửi hệ thống chọn, quãng đường và phí theo khối lượng vừa chọn.
    expect(find.text('Drone cất cánh tại Locker A'), findsOneWidget);
    expect(find.textContaining('110 m'), findsOneWidget);
    expect(find.textContaining('2,4 km'), findsOneWidget);
    expect(quotes.last, {'destination': 5, 'weight': 2000});

    await submit(tester);

    expect(created.single.toJson(), {
      'destinationLockerId': 5,
      'preferredBoxId': 9001,
      'pickupAddress': '12 Nguyễn Huệ, Quận 1',
      'pickupLatitude': 10.7,
      'pickupLongitude': 106.7,
      'pickupNote': 'Gọi trước khi tới',
      'senderName': 'Nguyễn Văn Gửi',
      'senderPhone': '0901000111',
      'senderEmail': 'gui@gmail.com',
      'receiverName': 'Trần Thị Nhận',
      'receiverPhone': '0902000222',
      'receiverEmail': 'nhan@gmail.com',
      'parcelWeightGrams': 2000,
      'parcelCategory': 'ELECTRONICS',
      'parcelLengthCm': 20,
      'parcelWidthCm': 30,
      'parcelHeightCm': 25,
      'declaredValue': 500000,
      'fragile': true,
      'prohibitedItemsDeclared': true,
    });
    expect(steps, ['create', 'pay 77 24000.0', 'booked 77']);
    expect(messages.last, 'Đã thanh toán. Đội bay sẽ tiếp nhận đơn của bạn.');
  });

  testWidgets('kiện quá khổ hoặc khai giá quá trần bị chặn trước khi gọi server', (
    tester,
  ) async {
    await pump(tester);
    await tester.tap(find.byKey(const ValueKey('drone-pickup-location')));
    await tester.pumpAndSettle();
    await fillReceiver(tester);
    await tester.tap(find.byKey(const ValueKey('drone-category-OTHER')));
    await tester.tap(find.byKey(const ValueKey('drone-prohibited-declaration')));

    await type(tester, 'drone-parcel-length', '40');
    await submit(tester);
    expect(messages.last, contains('Nhập đủ dài, rộng, cao'));

    await type(tester, 'drone-parcel-width', '10');
    await type(tester, 'drone-parcel-height', '10');
    await submit(tester);
    expect(messages.last, contains('không lọt khoang drone'));

    await type(tester, 'drone-parcel-length', '20');
    await type(tester, 'drone-parcel-value', '2000001');
    await submit(tester);
    expect(messages.last, contains('giá trị tới'));
    expect(created, isEmpty);
  });

  testWidgets('điểm lấy hàng ngoài vùng phục vụ: báo lý do và khoá nút tạo đơn', (
    tester,
  ) async {
    await pump(tester, quoteError: StateError('out of range'));
    await tester.tap(find.byKey(const ValueKey('drone-pickup-location')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('drone-quote-problem')), findsOneWidget);
    final button = tester.widget<FilledButton>(
      find.byKey(const ValueKey('drone-submit')),
    );
    expect(button.onPressed, isNull);
  });

  testWidgets('chỉ tủ đang hoạt động có bãi đáp mới là tủ nhận; đổi tủ thì bỏ ô đã chạm', (
    tester,
  ) async {
    await pump(tester, destination: 5);
    await tester.tap(find.byKey(const ValueKey('drone-destination-locker')));
    await tester.pumpAndSettle();
    expect(find.text('Locker C'), findsWidgets);
    expect(find.text('Locker D'), findsNothing);
    expect(find.text('Locker E'), findsNothing);
    await tester.tap(find.text('Locker C').last);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('drone-pickup-location')));
    await tester.pumpAndSettle();
    await fillReceiver(tester);
    await tester.tap(find.byKey(const ValueKey('drone-category-FOOD')));
    await tester.tap(find.byKey(const ValueKey('drone-prohibited-declaration')));
    await submit(tester);

    final json = created.single.toJson();
    expect(json['destinationLockerId'], 6);
    // Ô 9001 thuộc tủ khách mở form từ đó, không phải tủ vừa đổi sang.
    expect(json.containsKey('preferredBoxId'), isFalse);
  });

  testWidgets('tạm dừng bay: báo rõ và không cho tạo đơn', (tester) async {
    useBusinessConfig(
      BusinessConfig.fromPublicMaps(
        order: {'app.order.drone-flights-suspended': true},
      ),
    );
    await pump(tester);

    expect(find.textContaining('đang tạm dừng'), findsOneWidget);
    expect(
      tester.widget<FilledButton>(find.byKey(const ValueKey('drone-submit'))).onPressed,
      isNull,
    );
  });
}
