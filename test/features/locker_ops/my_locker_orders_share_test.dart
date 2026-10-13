import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_laundry_locker/features/locker_ops/data/locker_ops_service.dart';
import 'package:smart_laundry_locker/features/locker_ops/domain/pickup_code_share.dart';
import 'package:smart_laundry_locker/features/locker_ops/presentation/pages/my_locker_orders_page.dart';
import 'package:smart_laundry_locker/features/locker_ops/presentation/widgets/ops_widgets.dart';
import 'package:smart_laundry_locker/features/locker_ops/presentation/widgets/pickup_code_share_actions.dart';

import '../../helpers/test_helpers.dart';

/// "Đơn của tôi" với đúng một đơn — người đang xem luôn là người đặt (userId 99).
class _OneOrderService extends LockerOpsService {
  _OneOrderService(this._order) : super(dio: createMockDio().dio);

  final Map<String, dynamic> _order;

  @override
  Future<List<Map<String, dynamic>>> myOrders() async => [Map.of(_order)];

  @override
  Future<Map<String, dynamic>> locker(int lockerId) async => {
    'id': lockerId,
    'name': 'Tủ nhận B',
    'address': 'Sảnh Thử Nghiệm',
  };

  @override
  Future<Map<String, dynamic>> layout(int lockerId) async => const {
    'cells': [],
  };

  @override
  Future<List<Map<String, dynamic>>> myReports() async => const [];

  @override
  Future<List<Map<String, dynamic>>> incomingOrders({
    bool activeOnly = false,
    int? limit,
  }) async => const [];
}

/// Đơn drone đã thả hàng vào ô tủ nhận (STORING, đã trả tiền).
Map<String, dynamic> _droneOrder([Map<String, dynamic> extra = const {}]) => {
  'id': 71,
  'type': 'DRONE_DELIVERY',
  'status': 'STORING',
  'deliveryStage': 'READY_FOR_PICKUP',
  'paymentStatus': 'PAID',
  'totalPrice': 24000,
  'userId': 99,
  'receiverId': 55,
  'receiverName': 'Trần Nhận',
  'receiverPhone': '0902000222',
  'lockerId': 8,
  'pinCode': '907711',
  'orderCode': 'ORD-71',
  'createdAt': '2026-07-15T09:00:00',
  ...extra,
};

Future<void> _openDetail(WidgetTester tester, LockerOpsService service) async {
  await tester.binding.setSurfaceSize(const Size(390, 844));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    MaterialApp(
      home: MediaQuery(
        data: const MediaQueryData(size: Size(390, 844)),
        child: MyLockerOrdersPage(service: service),
      ),
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.text('Tủ nhận B'));
  await tester.pumpAndSettle();
}

void main() {
  setUp(() {
    mockSecureStorage({
      'access_token': makeFakeJwt(sub: '99', roles: ['CUSTOMER']),
    });
    useBusinessConfig();
  });

  testWidgets('đơn drone gửi cho người khác: người gửi chia sẻ được mã', (
    tester,
  ) async {
    await _openDetail(tester, _OneOrderService(_droneOrder()));

    await tester.ensureVisible(find.text('Chia sẻ mã cho người nhận'));
    expect(find.text('Chia sẻ mã cho người nhận'), findsOneWidget);
    final share = tester
        .widget<PickupCodeShareActions>(find.byType(PickupCodeShareActions))
        .share;
    expect(share.kind, PickupShareKind.droneDelivery);
    expect(share.receiverPhone, '0902000222');
    expect(
      share.message,
      'Lock.R: Bạn có kiện hàng giao bằng drone đang chờ tại tủ Tủ nhận B, '
      'Sảnh Thử Nghiệm. Mã lấy hàng: 907711. '
      'Nhập mã tại màn hình tủ (kiosk) để mở ô.',
    );
  });

  testWidgets('đơn drone người đặt tự nhận: không có nút chia sẻ', (
    tester,
  ) async {
    await _openDetail(tester, _OneOrderService(_droneOrder({'receiverId': 99})));

    // Vẫn thấy mã của chính mình, chỉ không có ai để chia sẻ.
    expect(find.byType(AccessCredentials), findsOneWidget);
    expect(find.text('Chia sẻ mã cho người nhận'), findsNothing);
    expect(find.byType(PickupCodeShareActions), findsNothing);
  });

  testWidgets('đơn drone đang bay (chưa vào ô): không có nút chia sẻ', (
    tester,
  ) async {
    await _openDetail(
      tester,
      _OneOrderService(
        _droneOrder({'status': 'ACCEPTED', 'deliveryStage': 'EN_ROUTE'}),
      ),
    );

    expect(find.byType(PickupCodeShareActions), findsNothing);
  });

  testWidgets('đơn gửi hàng chưa có mã: không có nút chia sẻ', (tester) async {
    await _openDetail(
      tester,
      _OneOrderService(
        _droneOrder({'type': 'SEND', 'pinCode': null, 'receiverId': null}),
      ),
    );

    expect(find.byType(PickupCodeShareActions), findsNothing);
  });
}
