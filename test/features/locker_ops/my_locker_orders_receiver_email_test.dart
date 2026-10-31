/// Chi tiết đơn gửi hàng của người gửi: gửi lại mã mở tủ cho người nhận qua email, thêm email cho đơn cũ.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_laundry_locker/features/locker_ops/data/locker_ops_service.dart';
import 'package:smart_laundry_locker/features/locker_ops/presentation/pages/my_locker_orders_page.dart';
import '../../helpers/test_helpers.dart';

/// Đơn gửi hàng đã vào tủ, có email người nhận: người gửi gửi lại mã qua email.
class _FakeSendEmailService extends LockerOpsService {
  _FakeSendEmailService({this.email = 'nhan@example.com'}) : super(dio: createMockDio().dio);

  final String? email;
  int emailCalls = 0;
  String? sentEmail;

  @override
  Future<List<Map<String, dynamic>>> myOrders() async => [
    {
      'id': 61,
      'type': 'SEND',
      'status': 'STORING',
      'paymentStatus': 'PAID',
      'totalPrice': 2500,
      'lockerId': 6,
      'sendBoxId': 6001,
      'pinCode': '795296',
      'orderCode': 'ORD-61',
      'receiverPhone': '0901000002',
      'receiverEmail': email,
      'pickupDeadline': DateTime.now().toUtc().add(const Duration(days: 1)).toIso8601String().split('.').first,
      'createdAt': DateTime.now().toUtc().subtract(const Duration(hours: 1)).toIso8601String().split('.').first,
    },
  ];

  @override
  Future<Map<String, dynamic>> locker(int lockerId) async => {'id': lockerId, 'name': 'Tủ gửi'};

  @override
  Future<Map<String, dynamic>> layout(int lockerId) async => {
    'cells': [
      {'id': 6001, 'boxNumber': 2},
    ],
  };

  @override
  Future<List<Map<String, dynamic>>> myReports() async => const [];

  @override
  Future<Map<String, dynamic>> sendReceiverEmail(int orderId, {String? email}) async {
    emailCalls++;
    sentEmail = email;
    return {'maskedEmail': 'nh***@example.com', 'includesPickupCode': true};
  }
}

void main() {
  setUp(() {
    mockSecureStorage({
      'access_token': makeFakeJwt(sub: '99', roles: ['CUSTOMER']),
    });
    useBusinessConfig();
  });

  testWidgets('đơn gửi hàng đã vào tủ: "Gửi lại mã cho người nhận qua email" giữ email cũ và báo đã gửi', (
    tester,
  ) async {
    final service = _FakeSendEmailService();
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(size: Size(390, 844)),
          child: MyLockerOrdersPage(service: service),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tủ gửi'));
    await tester.pumpAndSettle();

    final action = find.byKey(const ValueKey('send-receiver-email-action'));
    await tester.ensureVisible(action);
    expect(find.text('Gửi lại mã cho người nhận qua email'), findsOneWidget);
    await tester.tap(action);
    await tester.pumpAndSettle();

    expect(find.widgetWithText(AlertDialog, 'Gửi mã cho người nhận'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('receiver-email-submit')));
    await tester.pumpAndSettle();

    expect(service.emailCalls, 1);
    expect(service.sentEmail, isNull); // email không đổi ⇒ không gửi email mới
    expect(find.text('Đã gửi mã mở tủ tới nh***@example.com.'), findsOneWidget);
  });

  testWidgets('đơn cũ chưa có email: phải nhập email hợp lệ rồi mới gửi', (tester) async {
    final service = _FakeSendEmailService(email: null);
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(size: Size(390, 844)),
          child: MyLockerOrdersPage(service: service),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tủ gửi'));
    await tester.pumpAndSettle();

    final action = find.byKey(const ValueKey('send-receiver-email-action'));
    await tester.ensureVisible(action);
    expect(find.text('Thêm email người nhận'), findsOneWidget);
    await tester.tap(action);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('receiver-email-submit')));
    await tester.pumpAndSettle();
    expect(find.text('Nhập email người nhận'), findsWidgets);
    expect(service.emailCalls, 0);

    await tester.enterText(find.byKey(const ValueKey('receiver-email-input')), ' moi@example.com ');
    await tester.tap(find.byKey(const ValueKey('receiver-email-submit')));
    await tester.pumpAndSettle();
    expect(service.emailCalls, 1);
    expect(service.sentEmail, 'moi@example.com');
  });
}
