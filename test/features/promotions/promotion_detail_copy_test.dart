import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:smart_laundry_locker/core/l10n/l10n.dart';
import 'package:smart_laundry_locker/core/services/app_messenger_service.dart';
import 'package:smart_laundry_locker/core/services/platform_info.dart';
import 'package:smart_laundry_locker/features/promotions/data/models/promotion_model.dart';
import 'package:smart_laundry_locker/features/promotions/presentation/pages/promotion_detail_page.dart';

import '../../helpers/test_helpers.dart';

void main() {
  const promo = PromotionModel(
    id: 1,
    code: 'GIAM20',
    name: 'Giảm 20%',
    discountType: 'PERCENTAGE',
    discountValue: 20,
    status: 'ACTIVE',
  );
  String? copied;

  setUp(() {
    L10n.load(L10n.vi);
    copied = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
          if (call.method == 'Clipboard.setData') {
            copied = (call.arguments as Map)['text'] as String?;
          }
          return null;
        });
  });

  tearDown(() => PlatformInfo.androidSdk = 0);

  Future<void> copyTwice(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.6;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        navigatorObservers: smartDialogObservers,
        locale: L10n.vi,
        supportedLocales: L10n.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        builder: smartDialogBuilder((context, child) => AppScaffoldMessenger(child: child!)),
        home: const PromotionDetailPage(promo: promo),
      ),
    );
    await tester.pumpAndSettle();
    // Hai chỗ bấm sao chép trên trang: nút vuông và dòng chữ bên dưới.
    final buttons = find.byIcon(LucideIcons.copy);
    await tester.tap(buttons.first);
    await tester.pump();
    await tester.tap(buttons.last);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
  }

  testWidgets('Android 13+: chỉ ô "Đã sao chép" của hệ thống, app không hiện thêm toast', (
    tester,
  ) async {
    PlatformInfo.androidSdk = 34;
    await copyTwice(tester);
    expect(copied, 'GIAM20');
    expect(find.text(L10n.current.commonCopiedValue('GIAM20')), findsNothing);
  });

  testWidgets('Android cũ / iOS: bấm sao chép hai lần chỉ còn một toast', (
    tester,
  ) async {
    PlatformInfo.androidSdk = 30;
    await copyTwice(tester);
    await pumpToast(tester);
    expect(copied, 'GIAM20');
    // Toast mới thay toast cũ (AppMessengerService.configureToasts), không xếp hàng.
    expect(find.text(L10n.current.commonCopiedValue('GIAM20')), findsOneWidget);
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
  });
}
