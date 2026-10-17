import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_laundry_locker/core/config/business_config.dart';
import 'package:smart_laundry_locker/core/network/dio_client.dart';
import 'package:smart_laundry_locker/features/locker_ops/data/locker_ops_service.dart';
import 'package:smart_laundry_locker/features/locker_ops/presentation/pages/rent_locker_page.dart';

import '../../helpers/test_helpers.dart';

class _FakeRentLockerOpsService extends LockerOpsService {
  _FakeRentLockerOpsService() : super(dio: createMockDio().dio);

  int? createRentalBoxId;
  int checkoutCalls = 0;
  int confirmDropCalls = 0;
  int unlockCalls = 0;
  int? lastCheckoutOrderId;
  String? lastCheckoutMethod;
  int? lastConfirmOrderId;

  /// Server đã ghi nhận đơn PAID hay chưa (test bật khi "tiền về").
  bool paid = false;

  /// Bật trả lời redeem-preview (theo đúng công thức server, số dư [balance]).
  bool loyaltyEnabled = false;
  int balance = 1000;
  final List<int> previewTotals = [];
  int? sentPointsToUse;

  @override
  Future<Map<String, dynamic>> loyaltyRedeemPreview(int orderTotal) async {
    previewTotals.add(orderTotal);
    if (!loyaltyEnabled) throw StateError('no loyalty');
    final cap = (orderTotal * 50) ~/ (100 * 100);
    var points = cap < balance ? cap : balance;
    if (points < 10) points = 0;
    return {
      'enabled': true,
      'balance': balance,
      'vndPerPoint': 100,
      'maxPercent': 50,
      'minPoints': 10,
      'maxPoints': points,
      'maxDiscount': points * 100,
    };
  }

  @override
  Future<bool> orderStatus(int orderId) async => paid;

  @override
  Future<num> walletBalance() async => 50000;

  @override
  Future<bool> awaitOrderPaid(
    int orderId, {
    Duration timeout = const Duration(seconds: 20),
    Duration interval = const Duration(milliseconds: 1500),
  }) async =>
      paid;

  @override
  Future<Map<String, dynamic>> order(int orderId) async => {
        ..._createdOrder,
        'id': orderId,
        'paymentStatus': paid ? 'PAID' : 'UNPAID',
      };

  @override
  Future<Map<String, dynamic>> unlock(int lockerId, int boxId, String pinCode) async {
    unlockCalls++;
    return {'accepted': true, 'nextStep': 'CONFIRM_DROP'};
  }

  final Map<String, dynamic> _createdOrder = {
    'id': 81,
    'type': 'RENTAL',
    'status': 'INITIALIZED',
    'paymentStatus': 'UNPAID',
    'totalPrice': 20000,
    'lockerId': 5,
    'sendBoxId': 5004,
    'pinCode': '490912',
    'qrToken': 'QR-490912',
    'orderCode': 'ORD-81',
    'createdAt': '2026-07-24T09:00:00',
    'pickupDeadline': null,
  };

  @override
  Future<Map<String, dynamic>> createRental({
    required int lockerId,
    required String cellType,
    required int hours,
    String? note,
    String? promotionCode,
    int? boxId,
    int? pointsToUse,
  }) async {
    createRentalBoxId = boxId;
    sentPointsToUse = pointsToUse;
    return Map.of(_createdOrder);
  }

  @override
  Future<Map<String, dynamic>> checkout(
    int orderId,
    String method, {
    String? bankCode,
    String? returnUrl,
    String? description,
    String? orderCode,
  }) async {
    checkoutCalls++;
    lastCheckoutOrderId = orderId;
    lastCheckoutMethod = method;
    return {
      'id': 991,
      'orderId': orderId,
      'method': method,
      'status': 'PENDING',
      'qrCodeUrl':
          'https://img.vietqr.io/image/970422-0123456789-compact2.jpg?amount=20000&addInfo=LKR81&accountName=LOCKR',
      'bankTransfer': {
        'bankBin': '970422',
        'accountNo': '0123456789',
        'accountName': 'LOCKR',
        'amount': 20000,
        'transferContent': 'LKR81',
      },
    };
  }

  @override
  Future<Map<String, dynamic>> confirmDrop(int orderId) async {
    confirmDropCalls++;
    lastConfirmOrderId = orderId;
    return {
      ..._createdOrder,
      'id': orderId,
      'status': 'STORING',
      'paymentStatus': 'UNPAID',
      'pickupDeadline': '2026-07-24T13:00:00',
    };
  }

  @override
  Future<List<Map<String, dynamic>>> paymentsByOrder(int orderId) async {
    if (paid) {
      return [
        {
          'id': 991,
          'orderId': orderId,
          'status': 'COMPLETED',
          'amount': 20000,
        }
      ];
    }
    return const [];
  }
}

void main() {
  setUp(() {
    DioClient.instance.init(baseUrl: kTestBaseUrl);
    mockSecureStorage({
      'access_token': makeFakeJwt(sub: '99', roles: ['CUSTOMER']),
    });
    useBusinessConfig();
  });

  testWidgets('hiển thị giá, kích thước ô và giờ thuê theo cấu hình admin', (
    tester,
  ) async {
    useBusinessConfig(
      BusinessConfig.fromPublicMaps(
        order: {
          'app.order.rental-rate-standard': 6000,
          'app.order.rental-rate-xl': 12000,
          'app.order.rental-min-hours': 2,
          'app.order.rental-max-hours': 12,
          'app.order.rental-default-hours': 3,
          'app.order.rental-quick-hours': [3, 6, 48],
          'app.order.pickup-overtime-fee-per-hour': 1000,
          'app.order.pickup-max-overtime-fee': 30000,
          'app.order.pickup-max-overtime-percent': 40,
        },
        locker: {
          'app.locker.cell-dimensions-standard': '40 × 40 × 40 cm',
          'app.locker.cell-dimensions-xl': '60 × 90 × 50 cm',
        },
      ),
    );
    await tester.binding.setSurfaceSize(const Size(800, 1800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        home: RentLockerPage(
          initialLockerId: 5,
          initialLockerName: 'Tủ demo',
          service: _FakeRentLockerOpsService(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('6.000đ/giờ'), findsOneWidget);
    expect(find.text('12.000đ/giờ'), findsOneWidget);
    expect(find.text('40 × 40 × 40 cm'), findsOneWidget);
    expect(find.text('60 × 90 × 50 cm'), findsOneWidget);
    // Nút nhanh ngoài [min, max] bị bỏ.
    expect(find.text('3h'), findsOneWidget);
    expect(find.text('6h'), findsOneWidget);
    expect(find.text('48h'), findsNothing);
    expect(find.text('3 giờ'), findsOneWidget);
    expect(find.text('18.000đ'), findsOneWidget);

    final slider = tester.widget<Slider>(find.byType(Slider));
    expect(slider.min, 2);
    expect(slider.max, 12);
    expect(
      find.textContaining(
        'Thuê từ 2 đến 12 giờ. Phí quá giờ 1.000đ/giờ '
        '(tối đa 30.000đ và 40% giá trị đơn).',
      ),
      findsOneWidget,
    );

    await tester.tap(find.text('6h'));
    await tester.pumpAndSettle();
    expect(find.text('36.000đ'), findsOneWidget);
  });

  testWidgets('pays for real, opens the box, then confirms — never auto-confirms', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(800, 1800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final service = _FakeRentLockerOpsService();

    await tester.pumpWidget(
      MaterialApp(
        home: RentLockerPage(
          initialLockerId: 5,
          initialLockerName: 'Tủ demo',
          locationName: 'Cửa hàng A',
          initialCellType: 'STANDARD',
          initialBoxId: 5004,
          initialBoxNumber: 4,
          service: service,
        ),
      ),
    );

    await tester.pumpAndSettle();

    await tester.tap(find.text('Thuê ngay'));
    // Mã VietQR có vòng chờ chạy liên tục ⇒ chỉ pump theo khung.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    expect(service.createRentalBoxId, 5004);
    // Vừa tạo đơn là hiện ngay mã VietQR SePay (một checkout), chưa lộ mã mở ô,
    // chưa cho mở; không bảng chọn phương thức, không ví, không nút giả lập.
    expect(service.checkoutCalls, 1);
    expect(service.lastCheckoutOrderId, 81);
    expect(service.lastCheckoutMethod, 'SEPAY');
    expect(find.text('Quét mã VietQR để thanh toán'), findsOneWidget);
    expect(find.text('Số tiền cần chuyển:'), findsOneWidget);
    expect(find.text('20.000đ'), findsWidgets);
    expect(find.text('LKR81'), findsOneWidget);
    expect(find.text('Thanh toán bằng app ngân hàng'), findsOneWidget);
    expect(find.text('Chọn phương thức thanh toán'), findsNothing);
    expect(find.text('Ví của tôi'), findsNothing);
    expect(find.textContaining('Giả lập'), findsNothing);
    expect(find.textContaining('mở ô số 4'), findsNothing);
    expect(find.text('Mở ô để bỏ đồ'), findsNothing);
    expect(service.unlockCalls, 0);

    // Dựng lại màn / hỏi trạng thái nhiều lần không tạo thêm giao dịch.
    await tester.pump(const Duration(seconds: 7));
    expect(service.checkoutCalls, 1);

    // Tiền về ⇒ hỏi định kỳ thấy PAID, màn chuyển sang bước PIN / mở ô.
    service.paid = true;
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();

    expect(service.checkoutCalls, 1);
    expect(find.text('Quét mã VietQR để thanh toán'), findsNothing);
    expect(find.textContaining('mở ô số 4'), findsOneWidget);
    expect(service.confirmDropCalls, 0);

    final openButton = find.text('Mở ô để bỏ đồ');
    await tester.dragUntilVisible(
      openButton,
      find.byType(Scrollable).first,
      const Offset(0, -300),
    );
    // SnackBar "Thanh toán thành công" có thể che nút ⇒ gọi thẳng onTap.
    tester
        .widget<InkWell>(find.ancestor(of: openButton, matching: find.byType(InkWell)).first)
        .onTap
        ?.call();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pumpAndSettle();

    expect(service.unlockCalls, 1);
    expect(service.confirmDropCalls, 1);
    expect(service.lastConfirmOrderId, 81);
    expect(find.text('Tôi đã bỏ đồ — bắt đầu kỳ thuê'), findsNothing);
  });

  testWidgets(
    'điểm thưởng: đổi giờ thuê thì tạm tính đổi ngay và hỏi lại server, '
    'tạo đơn gửi pointsToUse',
    (tester) async {
      useBusinessConfig(
        BusinessConfig.fromPublicMaps(
          order: {
            'app.order.rental-rate-standard': 5000,
            'app.order.rental-default-hours': 4,
            'app.order.rental-quick-hours': [4, 8],
          },
        ),
      );
      await tester.binding.setSurfaceSize(const Size(800, 2200));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final service = _FakeRentLockerOpsService()
        ..loyaltyEnabled = true
        ..balance = 150;

      await tester.pumpWidget(
        MaterialApp(
          home: RentLockerPage(
            initialLockerId: 5,
            initialLockerName: 'Tủ demo',
            initialCellType: 'STANDARD',
            service: service,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 4 giờ × 5.000đ = 20.000đ ⇒ tối đa 50% = 100 điểm.
      expect(service.previewTotals, [20000]);
      await tester.tap(find.byKey(const ValueKey('loyalty-redeem-switch')));
      await tester.pumpAndSettle();
      expect(find.text('Điểm thưởng: -10.000đ (100 điểm)'), findsOneWidget);
      expect(find.text('10.000đ'), findsOneWidget);

      // 8 giờ = 40.000đ ⇒ 50% = 200 điểm nhưng chỉ có 150 điểm.
      await tester.tap(find.text('8h'));
      await tester.pump();
      await tester.pump();
      expect(find.text('Điểm thưởng: -15.000đ (150 điểm)'), findsOneWidget);
      expect(find.text('25.000đ'), findsOneWidget);
      // Hỏi lại server sau khi ngừng đổi (debounce).
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();
      expect(service.previewTotals, [20000, 40000]);

      await tester.tap(find.text('Thuê ngay'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));
      expect(service.sentPointsToUse, 150);
    },
  );
}
