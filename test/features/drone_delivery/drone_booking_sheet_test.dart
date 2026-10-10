import 'package:flutter/material.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:smart_laundry_locker/core/config/business_config.dart';
import 'package:smart_laundry_locker/features/drone_delivery/presentation/widgets/drone_booking_sheet.dart';
import 'package:smart_laundry_locker/features/locker_ops/presentation/widgets/order_payment_sheet.dart';

import '../../helpers/test_helpers.dart';

Future<OrderPaymentOutcome> _skipPayment(
  BuildContext context, {
  required int orderId,
  required double total,
}) async => OrderPaymentOutcome.cancelled;

/// Cam kết không gửi hàng cấm là bắt buộc trước khi tạo đơn.
Future<void> _acceptDeclaration(WidgetTester tester) async {
  final box = find.byKey(const ValueKey('drone-prohibited-declaration'));
  await tester.ensureVisible(box);
  await tester.pumpAndSettle();
  if (tester.widget<Checkbox>(box).value == true) return;
  await tester.tap(box);
  await tester.pumpAndSettle();
}

void main() {
  setUp(() => useBusinessConfig());

  testWidgets('mở thanh toán ngay khi đơn vừa tạo, trước khi sang màn theo dõi', (
    tester,
  ) async {
    final steps = <String>[];
    final messages = <String>[];

    await tester.pumpWidget(
      MaterialApp(
        builder: FlutterSmartDialog.init(),
        home: Scaffold(
          body: DroneBookingSheet(
            cell: const {'id': 9001, 'boxNumber': 7},
            lockerName: 'Locker A',
            origin: const LatLng(10.0, 106.0),
            lockerId: 5,
            destinationLockers: const [
              {'id': 6, 'name': 'Locker B', 'landingPad': true, 'status': 'ACTIVE'},
            ],
            createOrder: ({
              required sourceLockerId,
              required destinationLockerId,
              required sourceBoxId,
              required preferredBoxId,
              required receiverPhone,
              required receiverName,
              required receiverEmail,
              required description,
              required parcelWeightGrams,
              required parcel,
              required paymentMethod,
              required idempotencyKey,
            }) async => {'orderId': 77, 'totalPrice': 30000},
            payOrder: (context, {required orderId, required total}) async {
              steps.add('pay $orderId $total');
              return OrderPaymentOutcome.paid;
            },
            onBooked: (orderId) => steps.add('booked $orderId'),
            showMessage: messages.add,
          ),
        ),
      ),
    );

    await _acceptDeclaration(tester);
    await tester.ensureVisible(find.text('Tạo đơn và thanh toán'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tạo đơn và thanh toán'));
    await tester.pumpAndSettle();

    expect(steps, ['pay 77 30000.0', 'booked 77']);
    expect(messages.single, 'Đã thanh toán. Đội bay sẽ tiếp nhận đơn của bạn.');
  });

  testWidgets('tủ nhận hết ô drone: báo trước, chọn sẵn tủ còn ô, không tạo đơn vào tủ đầy', (
    tester,
  ) async {
    final sentDestinations = <int>[];

    Widget sheet(Map<int, int> free) => MaterialApp(
      builder: FlutterSmartDialog.init(),
      home: Scaffold(
        body: DroneBookingSheet(
          key: ValueKey(free),
          cell: const {'id': 9001, 'boxNumber': 7},
          lockerName: 'Locker A',
          origin: const LatLng(10.0, 106.0),
          lockerId: 5,
          destinationLockers: const [
            {'id': 6, 'name': 'Locker B', 'landingPad': true, 'status': 'ACTIVE'},
            {'id': 7, 'name': 'Locker C', 'landingPad': true, 'status': 'ACTIVE'},
          ],
          freeDroneCells: (lockerId) async => free[lockerId],
          createOrder: ({
            required sourceLockerId,
            required destinationLockerId,
            required sourceBoxId,
            required preferredBoxId,
            required receiverPhone,
            required receiverName,
            required receiverEmail,
            required description,
            required parcelWeightGrams,
            required parcel,
            required paymentMethod,
            required idempotencyKey,
          }) async {
            sentDestinations.add(destinationLockerId);
            return {'orderId': 80};
          },
          payOrder: _skipPayment,
          showMessage: (_) {},
        ),
      ),
    );

    final submit = find.text('Tạo đơn và thanh toán');

    // Mọi tủ nhận đều hết ô: có thông báo, nút tạo đơn bị khoá.
    await tester.pumpWidget(sheet({6: 0, 7: 0}));
    await tester.pumpAndSettle();
    expect(
      find.textContaining('Locker B đã hết ô drone trống'),
      findsOneWidget,
    );
    await _acceptDeclaration(tester);
    await tester.ensureVisible(submit);
    await tester.pumpAndSettle();
    await tester.tap(submit);
    await tester.pumpAndSettle();
    expect(sentDestinations, isEmpty);

    // Tủ đầu hết ô, tủ sau còn: tự chọn tủ còn ô.
    await tester.pumpWidget(sheet({6: 0, 7: 2}));
    await tester.pumpAndSettle();
    expect(find.textContaining('đã hết ô drone trống'), findsNothing);
    expect(find.text('Locker C · còn 2 ô drone'), findsOneWidget);
    await _acceptDeclaration(tester);
    await tester.ensureVisible(submit);
    await tester.pumpAndSettle();
    await tester.tap(submit);
    await tester.pumpAndSettle();
    expect(sentDestinations, [7]);
  });

  testWidgets('khai báo kiện: bắt buộc cam kết, chặn kiện quá khổ, gửi đủ khai báo', (
    tester,
  ) async {
    final messages = <String>[];
    final sent = <Map<String, dynamic>>[];

    await tester.pumpWidget(
      MaterialApp(
        builder: FlutterSmartDialog.init(),
        home: Scaffold(
          body: DroneBookingSheet(
            cell: const {'id': 9001, 'boxNumber': 7},
            lockerName: 'Locker A',
            origin: const LatLng(10.0, 106.0),
            lockerId: 5,
            destinationLockers: const [
              {'id': 6, 'name': 'Locker B', 'landingPad': true, 'status': 'ACTIVE'},
            ],
            createOrder: ({
              required sourceLockerId,
              required destinationLockerId,
              required sourceBoxId,
              required preferredBoxId,
              required receiverPhone,
              required receiverName,
              required receiverEmail,
              required description,
              required parcelWeightGrams,
              required parcel,
              required paymentMethod,
              required idempotencyKey,
            }) async {
              sent.add(parcel.toJson());
              return {'orderId': 77};
            },
            payOrder: _skipPayment,
            showMessage: messages.add,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final submit = find.text('Tạo đơn và thanh toán');

    Future<void> tapSubmit() async {
      await tester.ensureVisible(submit);
      await tester.pumpAndSettle();
      await tester.tap(submit);
      await tester.pumpAndSettle();
    }

    // Chưa cam kết không gửi hàng cấm: không tạo đơn.
    await tapSubmit();
    expect(sent, isEmpty);
    expect(messages.last, contains('cam kết'));

    await _acceptDeclaration(tester);

    // Khoang mặc định 30 × 25 × 20 cm: cạnh 40 cm không lọt.
    await tester.enterText(find.byKey(const ValueKey('drone-parcel-length')), '40');
    await tester.enterText(find.byKey(const ValueKey('drone-parcel-width')), '10');
    await tapSubmit();
    expect(sent, isEmpty);
    expect(messages.last, contains('Nhập đủ dài, rộng, cao'));

    await tester.enterText(find.byKey(const ValueKey('drone-parcel-height')), '10');
    await tapSubmit();
    expect(sent, isEmpty);
    expect(messages.last, contains('không lọt khoang drone'));

    // Kiện xoay được: 20 × 30 × 25 vẫn lọt khoang 30 × 25 × 20.
    await tester.enterText(find.byKey(const ValueKey('drone-parcel-length')), '20');
    await tester.enterText(find.byKey(const ValueKey('drone-parcel-width')), '30');
    await tester.enterText(find.byKey(const ValueKey('drone-parcel-height')), '25');
    await tester.enterText(find.byKey(const ValueKey('drone-parcel-value')), '500000');
    final electronics = find.byKey(const ValueKey('drone-category-ELECTRONICS'));
    await tester.ensureVisible(electronics);
    await tester.pumpAndSettle();
    await tester.tap(electronics);
    final fragile = find.byKey(const ValueKey('drone-parcel-fragile'));
    await tester.ensureVisible(fragile);
    await tester.pumpAndSettle();
    await tester.tap(fragile);
    await tester.pumpAndSettle();
    await tapSubmit();

    expect(sent.single, {
      'parcelCategory': 'ELECTRONICS',
      'parcelLengthCm': 20,
      'parcelWidthCm': 30,
      'parcelHeightCm': 25,
      'declaredValue': 500000,
      'fragile': true,
      'prohibitedItemsDeclared': true,
    });
  });

  testWidgets('books with backend orderId instead of local mock id', (tester) async {
    int? bookedOrderId;

    await tester.pumpWidget(
      MaterialApp(
        builder: FlutterSmartDialog.init(),
        home: Scaffold(
          body: DroneBookingSheet(
            cell: const {'id': 9001, 'boxNumber': 7},
            lockerName: 'Locker A',
            origin: const LatLng(10.0, 106.0),
            lockerId: 5,
            destinationLockers: const [
              {'id': 6, 'name': 'Locker B', 'landingPad': true, 'status': 'ACTIVE'},
            ],
            createOrder: ({
              required sourceLockerId,
              required destinationLockerId,
              required sourceBoxId,
              required preferredBoxId,
              required receiverPhone,
              required receiverName,
              required receiverEmail,
              required description,
              required parcelWeightGrams,
              required parcel,
              required paymentMethod,
              required idempotencyKey,
            }) async => {
              'orderId': 77,
              'reservedBoxId': 9001,
            },
            onBooked: (orderId) => bookedOrderId = orderId,
            payOrder: _skipPayment,
            showMessage: (_) {},
          ),
        ),
      ),
    );

    // Sheet có thêm ô người nhận nên nút nằm dưới mép màn test 800×600.
    await _acceptDeclaration(tester);
    await tester.ensureVisible(find.text('Tạo đơn và thanh toán'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tạo đơn và thanh toán'));
    await tester.pumpAndSettle();

    expect(bookedOrderId, equals(77));
  });

  testWidgets('phí drone, hạn lấy hàng và khối lượng kiện theo cấu hình admin', (
    tester,
  ) async {
    useBusinessConfig(
      BusinessConfig.fromPublicMaps(
        order: {
          'app.order.drone-delivery-fee': 25000,
          'app.order.drone-default-parcel-weight-grams': 900,
          'app.order.drone-weight-step-fee': 2000,
          'app.order.drone-pickup-hours-limit': 12,
          'app.order.pickup-overtime-fee-per-hour': 0,
        },
      ),
    );
    int? sentWeight;

    await tester.pumpWidget(
      MaterialApp(
        builder: FlutterSmartDialog.init(),
        home: Scaffold(
          body: DroneBookingSheet(
            cell: const {'id': 9001, 'boxNumber': 7},
            lockerName: 'Locker A',
            origin: const LatLng(10.0, 106.0),
            lockerId: 5,
            destinationLockers: const [
              {'id': 6, 'name': 'Locker B', 'landingPad': true, 'status': 'ACTIVE'},
            ],
            createOrder: ({
              required sourceLockerId,
              required destinationLockerId,
              required sourceBoxId,
              required preferredBoxId,
              required receiverPhone,
              required receiverName,
              required receiverEmail,
              required description,
              required parcelWeightGrams,
              required parcel,
              required paymentMethod,
              required idempotencyKey,
            }) async {
              sentWeight = parcelWeightGrams;
              return {'orderId': 78};
            },
            payOrder: _skipPayment,
            showMessage: (_) {},
          ),
        ),
      ),
    );

    // Mặc định 900 g ⇒ chọn sẵn mức 1 kg: 25.000 + 2 nấc 250 g × 2.000 = 29.000đ.
    expect(find.text('29.000đ'), findsOneWidget);
    expect(
      find.text(
        'Người nhận có 12 giờ để lấy hàng kể từ lúc drone thả hàng vào ô. '
        'Không tính phí quá giờ.',
      ),
      findsOneWidget,
    );

    // Sheet có thêm ô người nhận nên nút nằm dưới mép màn test 800×600.
    await _acceptDeclaration(tester);
    await tester.ensureVisible(find.text('Tạo đơn và thanh toán'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tạo đơn và thanh toán'));
    await tester.pumpAndSettle();

    expect(sentWeight, 1000);
  });

  testWidgets('khách chọn mức khối lượng: phí đổi theo mức và gửi đúng mức đã chọn', (
    tester,
  ) async {
    useBusinessConfig(
      BusinessConfig.fromPublicMaps(
        order: {
          'app.order.drone-delivery-fee': 15000,
          'app.order.drone-weight-step-fee': 3000,
          'app.order.drone-weight-options-grams': [500, 750, 1000, 6000],
        },
      ),
    );
    int? sentWeight;
    double? payTotal;

    await tester.pumpWidget(
      MaterialApp(
        builder: FlutterSmartDialog.init(),
        home: Scaffold(
          body: DroneBookingSheet(
            cell: const {'id': 9001, 'boxNumber': 7},
            lockerName: 'Locker A',
            origin: const LatLng(10.0, 106.0),
            lockerId: 5,
            destinationLockers: const [
              {'id': 6, 'name': 'Locker B', 'landingPad': true, 'status': 'ACTIVE'},
            ],
            createOrder: ({
              required sourceLockerId,
              required destinationLockerId,
              required sourceBoxId,
              required preferredBoxId,
              required receiverPhone,
              required receiverName,
              required receiverEmail,
              required description,
              required parcelWeightGrams,
              required parcel,
              required paymentMethod,
              required idempotencyKey,
            }) async {
              sentWeight = parcelWeightGrams;
              return {'orderId': 79};
            },
            payOrder: (context, {required orderId, required total}) async {
              payTotal = total;
              return OrderPaymentOutcome.cancelled;
            },
            showMessage: (_) {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Mức vượt tải tối đa của drone (5 kg) không hiện.
    expect(find.text('6 kg'), findsNothing);

    final chip = find.byKey(const ValueKey('drone-weight-750'));
    await tester.ensureVisible(chip);
    await tester.pumpAndSettle();
    await tester.tap(chip);
    await tester.pumpAndSettle();
    expect(find.text('18.000đ'), findsOneWidget);

    await _acceptDeclaration(tester);
    await tester.ensureVisible(find.text('Tạo đơn và thanh toán'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tạo đơn và thanh toán'));
    await tester.pumpAndSettle();

    expect(sentWeight, 750);
    expect(payTotal, 18000);
  });

  testWidgets('sends the tapped drone cell and the receiver, rejects a bad phone', (
    tester,
  ) async {
    // Màn cao đủ chứa cả sheet: ô đang nhập giữ focus sẽ kéo cuộn ngược lại, làm
    // nút tạo đơn trượt khỏi màn 800×600 mặc định.
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    int? sentSourceBox;
    String? sentPhone;
    String? sentName;
    String? sentEmail;
    var calls = 0;
    final messages = <String>[];

    await tester.pumpWidget(
      MaterialApp(
        builder: FlutterSmartDialog.init(),
        home: Scaffold(
          body: DroneBookingSheet(
            cell: const {'id': 9001, 'boxNumber': 7},
            lockerName: 'Locker A',
            origin: const LatLng(10.0, 106.0),
            lockerId: 5,
            destinationLockers: const [
              {'id': 6, 'name': 'Locker B', 'landingPad': true, 'status': 'ACTIVE'},
            ],
            createOrder: ({
              required sourceLockerId,
              required destinationLockerId,
              required sourceBoxId,
              required preferredBoxId,
              required receiverPhone,
              required receiverName,
              required receiverEmail,
              required description,
              required parcelWeightGrams,
              required parcel,
              required paymentMethod,
              required idempotencyKey,
            }) async {
              calls++;
              sentSourceBox = sourceBoxId;
              sentPhone = receiverPhone;
              sentName = receiverName;
              sentEmail = receiverEmail;
              return {'orderId': 78};
            },
            payOrder: _skipPayment,
            showMessage: messages.add,
          ),
        ),
      ),
    );

    final submit = find.text('Tạo đơn và thanh toán');
    await tester.enterText(
      find.byKey(const ValueKey('drone-receiver-phone')),
      '12ab',
    );
    await _acceptDeclaration(tester);
    await tester.ensureVisible(submit);
    await tester.pumpAndSettle();
    await tester.tap(submit);
    await tester.pumpAndSettle();

    expect(calls, 0);
    expect(messages.single, contains('không hợp lệ'));

    await tester.enterText(
      find.byKey(const ValueKey('drone-receiver-phone')),
      '0909 000 111',
    );
    await tester.enterText(
      find.byKey(const ValueKey('drone-receiver-name')),
      'Chi B',
    );
    await tester.enterText(
      find.byKey(const ValueKey('drone-receiver-email')),
      'khong-phai-email',
    );
    await tester.ensureVisible(submit);
    await tester.pumpAndSettle();
    await tester.tap(submit);
    await tester.pumpAndSettle();

    expect(calls, 0);
    expect(messages.last, 'Email người nhận không hợp lệ');

    await tester.enterText(
      find.byKey(const ValueKey('drone-receiver-email')),
      ' chib@gmail.com ',
    );
    await tester.ensureVisible(submit);
    await tester.pumpAndSettle();
    await tester.tap(submit);
    await tester.pumpAndSettle();

    expect(calls, 1);
    expect(sentSourceBox, 9001);
    expect(sentPhone, '0909000111');
    expect(sentName, 'Chi B');
    expect(sentEmail, 'chib@gmail.com');
  });
}
