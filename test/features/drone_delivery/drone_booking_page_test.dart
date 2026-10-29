import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_laundry_locker/core/config/business_config.dart';
import 'package:smart_laundry_locker/features/drone_delivery/domain/entities/drone_booking.dart';
import 'package:smart_laundry_locker/features/drone_delivery/presentation/pages/drone_booking_page.dart';
import 'package:smart_laundry_locker/features/locker_ops/data/locker_ops_service.dart';
import 'package:smart_laundry_locker/features/locker_ops/presentation/widgets/order_payment_sheet.dart';

import '../../helpers/test_helpers.dart';

const _pickup = PickupLocation(
  latitude: 10.7,
  longitude: 106.7,
  address: '12 Nguyễn Huệ, Quận 1',
);

const _lockers = [
  {
    'id': 5,
    'name': 'Locker B',
    'landingPad': true,
    'status': 'ACTIVE',
    'latitude': 10.8,
    'longitude': 106.7,
  },
  {
    'id': 6,
    'name': 'Locker C',
    'landingPad': true,
    'status': 'ACTIVE',
    'latitude': 10.8,
    'longitude': 106.7,
  },
  // Không có bãi đáp / đang bảo trì: không chọn được làm tủ nhận.
  {
    'id': 7,
    'name': 'Locker D',
    'landingPad': false,
    'status': 'ACTIVE',
    'latitude': 10.8,
    'longitude': 106.7,
  },
  {
    'id': 8,
    'name': 'Locker E',
    'landingPad': true,
    'status': 'MAINTENANCE',
    'latitude': 10.8,
    'longitude': 106.7,
  },
  // Có bãi đáp, còn ô drone nhưng chưa nhập toạ độ: drone không biết bay tới đâu.
  {
    'id': 9,
    'name': 'Locker F',
    'landingPad': true,
    'status': 'ACTIVE',
    'latitude': null,
    'longitude': null,
  },
];

/// Mã giảm giá + điểm thưởng cho đơn drone (tủ gửi = tủ #3).
class _FakeOffersService extends LockerOpsService {
  _FakeOffersService() : super(dio: createMockDio().dio);

  final List<int?> activeLockerIds = [];
  final List<({String code, int? lockerId, int? orderTotal})> validated = [];
  final List<int> previewTotals = [];

  @override
  Future<List<Map<String, dynamic>>> activePromotions({int? lockerId}) async {
    activeLockerIds.add(lockerId);
    return [
      {
        'id': 1,
        'code': 'TOANQUOC',
        'name': 'Giảm 5.000đ',
        'discountType': 'FIXED_AMOUNT',
        'discountValue': 5000,
      },
      {
        'id': 2,
        'code': 'TUA',
        'name': 'Giảm 10.000đ tại tủ A',
        'discountType': 'FIXED_AMOUNT',
        'discountValue': 10000,
        'lockerId': 3,
        'lockerName': 'Locker A',
      },
      // Server cũ trả lẫn mã của tủ khác ⇒ app tự lọc bỏ.
      {
        'id': 3,
        'code': 'TUKHAC',
        'name': 'Tủ khác',
        'discountType': 'FIXED_AMOUNT',
        'discountValue': 9000,
        'lockerId': 9,
        'lockerName': 'Locker Z',
      },
    ];
  }

  @override
  Future<List<Map<String, dynamic>>> myVouchers({int? lockerId}) async =>
      const [];

  @override
  Future<Map<String, dynamic>> validatePromotion(
    String code, {
    int? lockerId,
    int? orderTotal,
  }) async {
    validated.add((code: code, lockerId: lockerId, orderTotal: orderTotal));
    return {
      'code': code,
      'valid': true,
      'promotion': {
        'code': code,
        'discountType': 'FIXED_AMOUNT',
        'discountValue': 10000,
        'lockerId': 3,
      },
    };
  }

  @override
  Future<Map<String, dynamic>> loyaltyRedeemPreview(int orderTotal) async {
    previewTotals.add(orderTotal);
    final points = (orderTotal * 50) ~/ (100 * 100);
    return {
      'enabled': true,
      'balance': 1000,
      'vndPerPoint': 100,
      'maxPercent': 50,
      'minPoints': 10,
      'maxPoints': points,
      'maxDiscount': points * 100,
    };
  }
}

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
    bool weatherSafe = true,
    LockerOpsService? service,
    Map<String, dynamic> createResponse = const {
      'orderId': 77,
      'totalPrice': 24000,
    },
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
          loadDroneSlots: (_) async => [
            {
              'id': 9001,
              'boxNumber': 1,
              'cellType': 'DRONE',
              'status': 'AVAILABLE',
            },
            {
              'id': 9002,
              'boxNumber': 2,
              'cellType': 'DRONE',
              'status': 'AVAILABLE',
            },
            {
              'id': 9003,
              'boxNumber': 3,
              'cellType': 'DRONE',
              'status': 'AVAILABLE',
            },
          ],
          pickLocation: (context, current) async => _pickup,
          loadQuote:
              ({
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
                return DroneQuote(
                  sourceLockerId: 3,
                  sourceLockerName: 'Locker A',
                  sourceLockerAddress: '1 Lê Lợi',
                  pickupDistanceMeters: 110,
                  routeDistanceMeters: 2400,
                  fee: 24000,
                  weatherSafe: weatherSafe,
                  weatherStatus: weatherSafe ? 'SAFE' : 'UNSAFE',
                  weatherMessage: weatherSafe
                      ? 'Dự báo tuyến bay an toàn trong 30 phút tới.'
                      : 'Có mưa dông trên tuyến trong 30 phút tới.',
                  weatherProvider: 'MET_NORWAY',
                  weatherTemperatureC: 27.6,
                  weatherCondition: weatherSafe ? 'Có mây' : 'Dông',
                );
              },

          createOrder: (request, key) async {
            created.add(request);
            steps.add('create');
            return createResponse;
          },
          payOrder: (context, {required orderId, required total}) async {
            steps.add('pay $orderId $total');
            return OrderPaymentOutcome.paid;
          },
          onBooked: (orderId) => steps.add('booked $orderId'),
          showMessage: messages.add,
          service: service,
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

  testWidgets(
    'bắt buộc đủ điểm lấy hàng, người gửi, người nhận, loại hàng, cam kết',
    (tester) async {
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
    },
  );

  testWidgets(
    'gửi đủ điểm lấy hàng, liên hệ hai đầu và khai báo kiện; trả tiền rồi sang theo dõi',
    (tester) async {
      await pump(tester);
      await tester.tap(find.byKey(const ValueKey('drone-pickup-location')));
      await tester.pumpAndSettle();
      await fillReceiver(tester);
      await type(tester, 'drone-pickup-note', 'Gọi trước khi tới');
      await tester.tap(find.byKey(const ValueKey('drone-weight-2000')));
      await tester.tap(
        find.byKey(const ValueKey('drone-category-ELECTRONICS')),
      );
      await tester.tap(find.byKey(const ValueKey('drone-parcel-fragile')));
      await type(tester, 'drone-parcel-length', '20');
      await type(tester, 'drone-parcel-width', '30');
      await type(tester, 'drone-parcel-height', '25');
      await type(tester, 'drone-parcel-value', '500000');
      await tester.tap(
        find.byKey(const ValueKey('drone-prohibited-declaration')),
      );
      await tester.pumpAndSettle();

      // Báo trước tủ gửi hệ thống chọn, quãng đường và phí theo khối lượng vừa chọn.
      await tester.tap(find.byKey(const ValueKey('drone-destination-box')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ô số 1').last);
      await tester.pumpAndSettle();
      expect(find.text('Tủ bay do hệ thống chọn: Locker A'), findsOneWidget);
      expect(find.text('Ô nhận drone còn trống: 3'), findsOneWidget);
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
    },
  );

  testWidgets(
    'kiện quá khổ hoặc khai giá quá trần bị chặn trước khi gọi server',
    (tester) async {
      await pump(tester);
      await tester.tap(find.byKey(const ValueKey('drone-pickup-location')));
      await tester.pumpAndSettle();
      await fillReceiver(tester);
      await tester.tap(find.byKey(const ValueKey('drone-category-OTHER')));
      await tester.tap(
        find.byKey(const ValueKey('drone-prohibited-declaration')),
      );

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
    },
  );

  testWidgets(
    'mưa dông dọc tuyến trong 30 phút thì hiển thị cảnh báo và khóa đặt đơn',
    (tester) async {
      await pump(tester, weatherSafe: false);
      await tester.tap(find.byKey(const ValueKey('drone-pickup-location')));
      await tester.pumpAndSettle();

      expect(find.text('Thời tiết tuyến bay: Tạm ngưng bay'), findsOneWidget);
      expect(find.textContaining('Có mưa dông trên tuyến'), findsOneWidget);
      final button = tester.widget<FilledButton>(
        find.byKey(const ValueKey('drone-submit')),
      );
      expect(button.onPressed, isNull);
      expect(
        find.textContaining('Đơn chỉ đặt được khi trời đủ điều kiện bay'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'thời tiết 30 phút tới tính từ nơi gửi tới tủ nhận, có nguồn dự báo và nút xem lại',
    (tester) async {
      await pump(tester);
      await tester.tap(find.byKey(const ValueKey('drone-pickup-location')));
      await tester.pumpAndSettle();

      expect(find.text('Thời tiết tuyến bay: Đủ điều kiện'), findsOneWidget);
      expect(
        find.textContaining('từ nơi gửi → Locker A → tủ nhận'),
        findsOneWidget,
      );
      expect(find.textContaining('Có mây · 28°C · gió'), findsOneWidget);
      expect(find.textContaining('nguồn MET Norway'), findsOneWidget);

      final before = quotes.length;
      await tester.tap(
        find.byKey(const ValueKey('drone-quote-weather-refresh')),
      );
      await tester.pumpAndSettle();
      expect(quotes.length, before + 1);
    },
  );

  testWidgets(
    'điểm lấy hàng ngoài vùng phục vụ: báo lý do và khoá nút tạo đơn',
    (tester) async {
      await pump(tester, quoteError: StateError('out of range'));
      await tester.tap(find.byKey(const ValueKey('drone-pickup-location')));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('drone-quote-problem')), findsOneWidget);
      final button = tester.widget<FilledButton>(
        find.byKey(const ValueKey('drone-submit')),
      );
      expect(button.onPressed, isNull);
    },
  );

  testWidgets('hiện tất cả tủ; chỉ cho chọn tủ nhận drone còn đủ điều kiện', (
    tester,
  ) async {
    await pump(tester, destination: 5);
    await tester.tap(find.byKey(const ValueKey('drone-destination-locker')));
    await tester.pumpAndSettle();
    expect(find.textContaining('Locker C'), findsWidgets);
    expect(find.textContaining('Locker D'), findsOneWidget);
    expect(find.textContaining('Chưa có bãi đáp drone'), findsOneWidget);
    expect(find.textContaining('Locker E'), findsOneWidget);
    expect(find.textContaining('Đang bảo trì'), findsOneWidget);
    expect(find.textContaining('Locker F · Chưa có toạ độ tủ'), findsOneWidget);
    await tester.tap(find.textContaining('Locker C').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('drone-destination-box')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ô số 1').last);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('drone-pickup-location')));
    await tester.pumpAndSettle();
    await fillReceiver(tester);
    await tester.tap(find.byKey(const ValueKey('drone-category-FOOD')));
    await tester.tap(
      find.byKey(const ValueKey('drone-prohibited-declaration')),
    );
    await submit(tester);

    final json = created.single.toJson();
    expect(json['destinationLockerId'], 6);
    expect(json['preferredBoxId'], 9001);
  });

  testWidgets(
    'mã giảm giá theo tủ gửi + điểm thưởng: chỉ hiện mã dùng được ở tủ gửi, '
    'gửi promotionCode/pointsToUse; server trả PAID ⇒ không mở thanh toán',
    (tester) async {
      final service = _FakeOffersService();
      await pump(
        tester,
        service: service,
        createResponse: const {
          'orderId': 77,
          'totalPrice': 0,
          'paymentStatus': 'PAID',
          'pointsUsed': 70,
        },
      );
      await tester.tap(find.byKey(const ValueKey('drone-pickup-location')));
      await tester.pumpAndSettle();
      await fillReceiver(tester);
      await tester.tap(find.byKey(const ValueKey('drone-category-DOCUMENT')));
      await tester.tap(
        find.byKey(const ValueKey('drone-prohibited-declaration')),
      );
      await tester.pumpAndSettle();

      // Có báo giá (tủ gửi #3) ⇒ mở mục ưu đãi; điểm hỏi theo phí 24.000đ.
      expect(find.text('Ưu đãi'), findsOneWidget);
      expect(service.previewTotals, [24000]);

      await tester.tap(find.text('Chọn mã giảm giá'));
      await tester.pumpAndSettle();
      expect(service.activeLockerIds, [3]);
      expect(find.text('TOANQUOC'), findsOneWidget);
      expect(find.text('TUA'), findsOneWidget);
      expect(find.text('TUKHAC'), findsNothing);
      expect(find.text('Toàn hệ thống'), findsOneWidget);
      expect(find.text('Áp dụng tại: Locker A'), findsOneWidget);

      await tester.tap(find.text('TUA'));
      await tester.pumpAndSettle();
      expect(service.validated.single, (
        code: 'TUA',
        lockerId: 3,
        orderTotal: 24000,
      ));
      expect(find.text('Đã áp mã "TUA"'), findsOneWidget);

      // Sau voucher còn 14.000đ ⇒ hỏi lại điểm theo số tiền mới (debounce).
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();
      expect(service.previewTotals.last, 14000);
      await tester.tap(find.byKey(const ValueKey('loyalty-redeem-switch')));
      await tester.pumpAndSettle();
      expect(find.text('-7.000đ (70 điểm)'), findsOneWidget);
      expect(
        find.textContaining('Tạo đơn và thanh toán 7.000đ'),
        findsOneWidget,
      );

      await submit(tester);
      final json = created.single.toJson();
      expect(json['promotionCode'], 'TUA');
      expect(json['pointsToUse'], 70);
      // Đơn đã PAID (0đ) ⇒ không mở bảng thanh toán.
      expect(steps, ['create', 'booked 77']);
      expect(
        messages.last,
        'Đơn đã được thanh toán bằng ưu đãi. Đội bay sẽ tiếp nhận đơn của bạn.',
      );
    },
  );

  testWidgets('tạm dừng bay: báo rõ và không cho tạo đơn', (tester) async {
    useBusinessConfig(
      BusinessConfig.fromPublicMaps(
        order: {'app.order.drone-flights-suspended': true},
      ),
    );
    await pump(tester);

    expect(find.textContaining('đang tạm dừng'), findsOneWidget);
    expect(
      tester
          .widget<FilledButton>(find.byKey(const ValueKey('drone-submit')))
          .onPressed,
      isNull,
    );
  });
}
