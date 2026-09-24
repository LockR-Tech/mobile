import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_laundry_locker/core/config/business_config.dart';
import 'package:smart_laundry_locker/core/network/dio_client.dart';
import 'package:smart_laundry_locker/features/locker_ops/data/locker_ops_service.dart';
import 'package:smart_laundry_locker/features/locker_ops/presentation/pages/send_parcel_page.dart';

import '../../helpers/test_helpers.dart';

class _FakeSendLockerOpsService extends LockerOpsService {
  _FakeSendLockerOpsService() : super(dio: createMockDio().dio);

  int checkoutCalls = 0;
  int unlockCalls = 0;
  int confirmDropCalls = 0;
  String? lastCheckoutMethod;

  final Map<String, dynamic> _order = {
    'id': 91,
    'type': 'SEND',
    'status': 'INITIALIZED',
    'paymentStatus': 'UNPAID',
    'totalPrice': 15000,
    'lockerId': 5,
    'sendBoxId': 5002,
    'pinCode': '111111',
    'qrToken': 'QR-111111',
    'orderCode': 'ORD-91',
    'receiverPhone': '0909000000',
  };

  @override
  Future<Map<String, dynamic>> createSend({
    required int lockerId,
    required String receiverPhone,
    String? receiverName,
    String? receiverEmail,
    String? note,
    String? promotionCode,
    String? size,
  }) async =>
      Map.of(_order);

  @override
  Future<num> walletBalance() async => 50000;

  @override
  Future<Map<String, dynamic>> checkout(
    int orderId,
    String method, {
    String? bankCode,
    String? returnUrl,
    String? description,
  }) async {
    checkoutCalls++;
    lastCheckoutMethod = method;
    return {'id': 1, 'orderId': orderId, 'method': method, 'status': 'COMPLETED'};
  }

  /// SePay đã báo nhận tiền hay chưa. Tách khỏi `checkoutCalls` vì trang tự gọi
  /// checkout('SEPAY') ngay khi tạo đơn để dựng mã VietQR — gọi checkout không còn
  /// đồng nghĩa với việc khách đã chuyển khoản.
  bool paid = false;

  /// Trang bật Timer.periodic hỏi trạng thái ngay sau khi tạo đơn; không chặn ở đây
  /// thì poll gọi qua mock dio, lỗi, rồi lặp mãi và pumpAndSettle không bao giờ lắng.
  @override
  Future<bool> orderStatus(int orderId) async => paid;

  @override
  Future<bool> awaitOrderPaid(
    int orderId, {
    Duration timeout = const Duration(seconds: 20),
    Duration interval = const Duration(milliseconds: 1500),
  }) async =>
      paid;

  @override
  Future<Map<String, dynamic>> order(int orderId) async =>
      {..._order, 'paymentStatus': paid ? 'PAID' : 'UNPAID'};

  @override
  Future<Map<String, dynamic>> unlock(int lockerId, int boxId, String pinCode) async {
    unlockCalls++;
    return {'accepted': true, 'nextStep': 'CONFIRM_DROP'};
  }

  @override
  Future<Map<String, dynamic>> confirmDrop(int orderId) async {
    confirmDropCalls++;
    return {
      ..._order,
      'status': 'STORING',
      'paymentStatus': 'PAID',
      'pinCode': '222222',
      'pickupDeadline': '2026-09-23T10:00:00',
    };
  }

  @override
  Future<List<Map<String, dynamic>>> paymentsByOrder(int orderId) async => const [];
}

void main() {
  setUp(() {
    DioClient.instance.init(baseUrl: kTestBaseUrl);
    mockSecureStorage({
      'access_token': makeFakeJwt(sub: '99', roles: ['CUSTOMER']),
    });
  });

  testWidgets('phí gửi và hạn lấy hàng lấy theo cấu hình admin', (tester) async {
    final service = useBusinessConfig(
      BusinessConfig.fromPublicMaps(
        order: {
          'app.order.send-base-fee': 18000,
          'app.order.send-pickup-hours-limit': 36,
          'app.order.pickup-overtime-fee-per-hour': 0,
        },
      ),
    );
    await tester.binding.setSurfaceSize(const Size(800, 1800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      const MaterialApp(
        home: SendParcelPage(initialLockerId: 5, initialLockerName: 'Tủ demo'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('18.000đ'), findsOneWidget);
    expect(
      find.text(
        'Người nhận có 36 giờ để lấy hàng kể từ lúc bạn bỏ hàng vào ô. '
        'Không tính phí quá giờ.',
      ),
      findsOneWidget,
    );
    expect(service.current.sendBaseFee, 18000);
  });

  testWidgets('thanh toán thật rồi mới mở ô và xác nhận bỏ hàng', (tester) async {
    useBusinessConfig();
    await tester.binding.setSurfaceSize(const Size(800, 1800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final service = _FakeSendLockerOpsService();

    await tester.pumpWidget(
      MaterialApp(
        home: SendParcelPage(
          initialLockerId: 5,
          initialLockerName: 'Tủ demo',
          service: service,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).first, '0909000000');
    await tester.tap(find.text('Tạo đơn & lấy PIN bỏ hàng'));
    // Không pumpAndSettle: đơn vừa tạo còn UNPAID nên trang đang chạy vòng poll,
    // trạng thái "đã lắng" sẽ không bao giờ tới.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    // Trang tự dựng mã VietQR rồi chờ SePay xác nhận. Chưa có tiền về thì không có
    // nút mock, không mở được ô.
    expect(service.lastCheckoutMethod, 'SEPAY');
    expect(find.textContaining('Quét mã VietQR'), findsOneWidget);
    expect(find.textContaining('Mock'), findsNothing);
    expect(find.text('Mở ô để bỏ hàng'), findsNothing);
    expect(service.unlockCalls, 0);

    // SePay báo đã nhận tiền: vòng poll 3 giây thấy đơn chuyển sang PAID.
    service.paid = true;
    await tester.pump(const Duration(seconds: 3));
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.text('Mở ô để bỏ hàng'), findsOneWidget);
    expect(service.confirmDropCalls, 0);

    await tester.tap(find.text('Mở ô để bỏ hàng'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(service.unlockCalls, 1);
    expect(service.confirmDropCalls, 0);

    await tester.tap(find.text('Tôi đã bỏ hàng vào ô'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(service.confirmDropCalls, 1);
    expect(find.text('Bước 2 — Đã bỏ hàng xong'), findsOneWidget);
  });
}
