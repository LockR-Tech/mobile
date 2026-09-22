import 'package:flutter/material.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:smart_laundry_locker/core/config/business_config.dart';
import 'package:smart_laundry_locker/core/network/dio_client.dart';
import 'package:smart_laundry_locker/features/transactions/presentation/pages/top_up_page.dart';
import 'package:smart_laundry_locker/features/wallet/presentation/providers/wallet_provider.dart';

import '../../helpers/test_helpers.dart';

Future<void> _pumpTopUp(WidgetTester tester) async {
  await tester.binding.setSurfaceSize(const Size(800, 1600));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    ChangeNotifierProvider(
      create: (_) => WalletProvider(),
      child: MaterialApp(
        builder: FlutterSmartDialog.init(),
        home: const TopUpPage(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUp(() {
    DioClient.instance.init(baseUrl: kTestBaseUrl);
    mockSecureStorage();
  });

  testWidgets('mốc nạp, số tiền mặc định và giới hạn lấy theo cấu hình', (
    tester,
  ) async {
    useBusinessConfig(
      BusinessConfig.fromPublicMaps(
        payment: {
          'app.payment.topup-min-amount': 20000,
          'app.payment.topup-max-amount': 3000000,
          'app.payment.topup-default-amount': 60000,
          'app.payment.topup-presets': [30000, 60000, 90000],
        },
      ),
    );

    await _pumpTopUp(tester);

    expect(find.textContaining('30.000'), findsOneWidget);
    expect(find.textContaining('90.000'), findsOneWidget);
    // Mốc cũ không còn trong cấu hình.
    expect(find.textContaining('1.000.000'), findsNothing);
    expect(find.textContaining('Số tiền nạp: 60.000'), findsOneWidget);
    expect(find.textContaining('từ 20.000'), findsOneWidget);
    expect(find.textContaining('3.000.000'), findsOneWidget);
    expect(find.text('VNPAY'), findsOneWidget);
    expect(find.text('SePay (VietQR)'), findsOneWidget);

    await tester.tap(find.textContaining('90.000').first);
    await tester.pumpAndSettle();
    expect(find.textContaining('Số tiền nạp: 90.000'), findsOneWidget);
  });

  testWidgets('admin tắt cả VNPAY và SEPAY ⇒ ẩn cổng và không gọi API nạp', (
    tester,
  ) async {
    useBusinessConfig(
      BusinessConfig.fromPublicMaps(
        payment: {'app.payment.enabled-methods': 'CASH,WALLET'},
      ),
    );

    await _pumpTopUp(tester);

    expect(find.text('VNPAY'), findsNothing);
    expect(find.text('SePay (VietQR)'), findsNothing);
    expect(
      find.text('Dịch vụ nạp tiền đang tạm ngưng. Vui lòng thử lại sau.'),
      findsOneWidget,
    );

    await tester.tap(find.text('Nạp ngay'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.textContaining('đang tạm ngưng'), findsWidgets);
    expect(find.byType(TopUpWebViewPage), findsNothing);

    // Chờ toast tự đóng để không còn timer treo.
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
  });

  testWidgets('admin chỉ bật SEPAY ⇒ chỉ hiển thị SePay', (tester) async {
    useBusinessConfig(
      BusinessConfig.fromPublicMaps(
        payment: {'app.payment.enabled-methods': 'SEPAY'},
      ),
    );

    await _pumpTopUp(tester);

    expect(find.text('SePay (VietQR)'), findsOneWidget);
    expect(find.text('VNPAY'), findsNothing);
  });
}
