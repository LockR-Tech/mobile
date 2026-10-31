import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_laundry_locker/core/routing/app_back_navigation.dart';

/// Nút quay lại đi theo lịch sử trang (tab trước, trang trước) thay vì thoát app; vuốt cạnh phải là "đi tới".
void main() {
  late GoRouter router;
  final nav = AppBackNavigation.instance;

  Widget page(String name) => Scaffold(body: Text(name));

  Future<void> pumpApp(WidgetTester tester) async {
    router = GoRouter(
      initialLocation: '/home',
      routes: [
        GoRoute(path: '/home', builder: (_, _) => page('home')),
        GoRoute(path: '/orders', builder: (_, _) => page('orders')),
        GoRoute(path: '/profile', builder: (_, _) => page('profile')),
        GoRoute(path: '/detail', builder: (_, _) => page('detail')),
      ],
    );
    nav.attach(router);
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();
  }

  tearDown(() => nav.detach());

  Future<void> go(WidgetTester tester, String location) async {
    router.go(location);
    await tester.pumpAndSettle();
  }

  Future<void> back(WidgetTester tester) async {
    final handled = await nav.handleBack();
    if (!handled) router.pop(); // router tự đóng trang chồng như nút quay lại thật
    await tester.pumpAndSettle();
  }

  PredictiveBackEvent swipe(SwipeEdge edge) => PredictiveBackEvent.fromMap({
    'touchOffset': <double>[0, 0],
    'progress': 0.0,
    'swipeEdge': edge.index,
  });

  testWidgets('ở trang gốc: quay lại về tab đã xem trước đó, không thoát app', (tester) async {
    await pumpApp(tester);
    await go(tester, '/orders');
    await go(tester, '/profile');

    await back(tester);
    expect(find.text('orders'), findsOneWidget);
    await back(tester);
    expect(find.text('home'), findsOneWidget);
    expect(nav.forwardHistory, ['/profile', '/orders']);
  });

  testWidgets('có trang chồng: để router đóng trang đó như cũ', (tester) async {
    await pumpApp(tester);
    router.push('/detail');
    await tester.pumpAndSettle();

    expect(await nav.handleBack(), isFalse);
    router.pop();
    await tester.pumpAndSettle();
    expect(find.text('home'), findsOneWidget);
    expect(nav.forwardHistory, ['/detail']);
  });

  testWidgets('vuốt cạnh phải đi tới trang vừa quay lại; cạnh trái là quay lại', (tester) async {
    await pumpApp(tester);
    await go(tester, '/orders');
    router.push('/detail');
    await tester.pumpAndSettle();

    nav.handleStartBackGesture(swipe(SwipeEdge.left));
    await back(tester);
    expect(find.text('orders'), findsOneWidget);

    nav.handleStartBackGesture(swipe(SwipeEdge.left));
    await back(tester);
    expect(find.text('home'), findsOneWidget);

    nav.handleStartBackGesture(swipe(SwipeEdge.right));
    expect(await nav.handleBack(), isTrue);
    await tester.pumpAndSettle();
    expect(find.text('orders'), findsOneWidget);

    nav.handleStartBackGesture(swipe(SwipeEdge.right));
    expect(await nav.handleBack(), isTrue);
    await tester.pumpAndSettle();
    expect(find.text('detail'), findsOneWidget);
    expect(nav.forwardHistory, isEmpty);

    // Đi tới xong vẫn quay lại được bình thường.
    await back(tester);
    expect(find.text('orders'), findsOneWidget);
  });

  testWidgets('mở trang mới sau khi quay lại thì xoá phần "đi tới"', (tester) async {
    await pumpApp(tester);
    await go(tester, '/orders');
    await back(tester);
    expect(nav.forwardHistory, ['/orders']);

    await go(tester, '/profile');
    expect(nav.forwardHistory, isEmpty);
    nav.handleStartBackGesture(swipe(SwipeEdge.right));
    expect(await nav.handleBack(), isTrue);
    await tester.pumpAndSettle();
    expect(find.text('profile'), findsOneWidget);
  });

  testWidgets('cử chỉ bị huỷ thì lần bấm nút sau là quay lại bình thường', (tester) async {
    await pumpApp(tester);
    await go(tester, '/orders');
    await back(tester);

    nav.handleStartBackGesture(swipe(SwipeEdge.right));
    nav.handleCancelBackGesture();
    await go(tester, '/orders');
    await back(tester);
    expect(find.text('home'), findsOneWidget);
  });
}
