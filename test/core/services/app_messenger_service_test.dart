import 'package:flutter/material.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_laundry_locker/core/services/app_messenger_service.dart';

void main() {
  late BuildContext pageContext;

  Future<void> pumpApp(WidgetTester tester) async {
    AppMessengerService.configureToasts();
    await tester.pumpWidget(
      MaterialApp(
        navigatorObservers: [FlutterSmartDialog.observer],
        builder: (context, child) => AppScaffoldMessenger(
          key: AppMessengerService.scaffoldMessengerKey,
          child: FlutterSmartDialog.init(
            toastBuilder: (msg) =>
                AppToastSlot(child: Material(child: Text('toast:$msg'))),
          )(context, child),
        ),
        home: Scaffold(
          body: Builder(
            builder: (context) {
              pageContext = context;
              return const SizedBox.expand();
            },
          ),
        ),
      ),
    );
  }

  Future<void> drain(WidgetTester tester) async {
    await tester.pump(const Duration(seconds: 10));
    await tester.pumpAndSettle();
  }

  testWidgets('SnackBar mới thay ngay SnackBar cũ, không chờ cái cũ hết giờ', (
    tester,
  ) async {
    await pumpApp(tester);
    ScaffoldMessenger.of(
      pageContext,
    ).showSnackBar(const SnackBar(content: Text('Đang gửi lệnh mở ô')));
    await tester.pumpAndSettle();
    ScaffoldMessenger.of(pageContext)
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('Ô đã mở')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Đang gửi lệnh mở ô'), findsNothing);
    expect(find.text('Ô đã mở'), findsOneWidget);
    await drain(tester);
  });

  testWidgets('toast và SnackBar không cùng hiện: cái sau thay cái trước', (
    tester,
  ) async {
    await pumpApp(tester);
    ScaffoldMessenger.of(
      pageContext,
    ).showSnackBar(const SnackBar(content: Text('snack')));
    await tester.pumpAndSettle();

    SmartDialog.showToast('một');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester
        .pump(); // SnackBar được bỏ ở khung hình ngay sau khi toast dựng xong.
    expect(find.text('toast:một'), findsOneWidget);
    expect(find.text('snack'), findsNothing);

    // Toast mới đẩy toast cũ đi, không xếp hàng.
    SmartDialog.showToast('hai');
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.text('toast:một'), findsNothing);
    expect(find.text('toast:hai'), findsOneWidget);

    ScaffoldMessenger.of(
      pageContext,
    ).showSnackBar(const SnackBar(content: Text('snack 2')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('toast:hai'), findsNothing);
    expect(find.text('snack 2'), findsOneWidget);
    await drain(tester);
  });

  testWidgets('SnackBar có nút (vd. "Báo sự cố") vẫn tự tắt, không nằm mãi', (
    tester,
  ) async {
    await pumpApp(tester);
    ScaffoldMessenger.of(pageContext).showSnackBar(
      SnackBar(
        content: const Text('Ô số 2 đang hỏng'),
        action: SnackBarAction(label: 'Báo sự cố', onPressed: () {}),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Ô số 2 đang hỏng'), findsOneWidget);

    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    expect(find.text('Ô số 2 đang hỏng'), findsNothing);
  });

  testWidgets(
    'app không dùng MaterialApp (ShadApp): ScaffoldMessenger.of() trả AppScaffoldMessenger, không ném ở debug',
    (tester) async {
      final key = GlobalKey<ScaffoldMessengerState>();
      late BuildContext inner;
      // Không có MaterialApp ⇒ không có ScaffoldMessenger "thường" nào ở trên, như cây của ShadApp.router.
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: AppScaffoldMessenger.wrap(
            key: key,
            child: Builder(
              builder: (context) {
                inner = context;
                return const SizedBox.expand();
              },
            ),
          ),
        ),
      );
      expect(ScaffoldMessenger.of(inner), same(key.currentState));
      expect(key.currentState.runtimeType.toString(), '_AppScaffoldMessengerState');
    },
  );

  test('chỉ đổi persist, giữ nguyên các thuộc tính khác', () {
    final original = SnackBar(
      content: const Text('x'),
      duration: const Duration(seconds: 7),
      behavior: SnackBarBehavior.floating,
      action: SnackBarAction(label: 'a', onPressed: () {}),
    );
    expect(original.persist, isTrue);
    final fixed = autoDismissing(original);
    expect(fixed.persist, isFalse);
    expect(fixed.duration, const Duration(seconds: 7));
    expect(fixed.behavior, SnackBarBehavior.floating);
    expect(fixed.action, same(original.action));
  });
}
