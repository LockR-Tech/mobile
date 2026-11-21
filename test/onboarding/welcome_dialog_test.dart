// Hộp chào hướng dẫn (F3-G13): chưa có tên người dùng (KTV — token không mang tên) thì ghi "Chào bạn!",
// không để "Chào !".
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_laundry_locker/features/onboarding/domain/tour_models.dart';
import 'package:smart_laundry_locker/features/onboarding/presentation/onboarding_dialogs.dart';

void main() {
  final group = TourGroup(id: 'locker-tech-home', version: 1, roles: const ['LOCKER_TECHNICIAN'], steps: const [
    TourStep(id: 'locker-tech-home-a', anchor: 'tech-home-a', platforms: ['mobile']),
  ]);

  Future<void> open(WidgetTester tester, String name) async {
    await tester.pumpWidget(MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () => showWelcomeDialog(context, name: name, groups: [group], text: (key) => key),
            child: const Text('open'),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  bool titleIs(WidgetTester tester, List<String> any) =>
      tester.widgetList<Text>(find.byType(Text)).any((t) => any.contains(t.data));

  testWidgets('không có tên ⇒ "Chào bạn!" / "Hi there!"', (tester) async {
    await open(tester, '  ');
    expect(titleIs(tester, ['Chào bạn!', 'Hi there!']), isTrue);
    expect(titleIs(tester, ['Chào !', 'Hi !', 'Chào   !', 'Hi   !']), isFalse);
  });

  testWidgets('có tên ⇒ "Chào <tên>!"', (tester) async {
    await open(tester, 'Minh');
    expect(titleIs(tester, ['Chào Minh!', 'Hi Minh!']), isTrue);
  });
}
