// Bước có `via` (F3-G13): chưa thấy phần tử thì lớp khoanh tự chạm neo `via` (mục đầu danh sách, tab…) để mở màn
// chi tiết rồi mới khoanh; đã ở sẵn màn chi tiết thì không chạm lại.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_laundry_locker/features/onboarding/domain/tour_models.dart';
import 'package:smart_laundry_locker/features/onboarding/presentation/tour_anchor.dart';
import 'package:smart_laundry_locker/features/onboarding/presentation/tour_overlay.dart';

class _Host extends StatefulWidget {
  const _Host({required this.groups});

  final List<TourGroup> groups;

  @override
  State<_Host> createState() => _HostState();
}

class _HostState extends State<_Host> {
  int taps = 0;

  @override
  Widget build(BuildContext context) => Stack(
        fit: StackFit.expand,
        children: [
          Column(
            children: [
              TourAnchor(
                'first-row',
                child: TextButton(onPressed: () => setState(() => taps++), child: const Text('Đơn đầu tiên')),
              ),
              if (taps > 0) const TourAnchor('detail-pin', child: SizedBox(width: 100, height: 40, child: Text('PIN'))),
            ],
          ),
          Positioned.fill(
            child: TourOverlay(
              groups: widget.groups,
              text: (key) => key,
              findTimeout: const Duration(milliseconds: 600),
              onGroupDone: (_) {},
              onClose: (_) {},
            ),
          ),
        ],
      );
}

void main() {
  testWidgets('chạm neo via một lần để mở chi tiết rồi khoanh phần tử', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: _Host(groups: [
          TourGroup(id: 'g', version: 1, roles: const ['CUSTOMER'], steps: const [
            TourStep(id: 'g-pin', anchor: 'detail-pin', via: 'first-row', platforms: ['mobile']),
            TourStep(id: 'g-pin-again', anchor: 'detail-pin', via: 'first-row', platforms: ['mobile']),
          ]),
        ]),
      ),
    ));
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    final host = tester.state<_HostState>(find.byType(_Host));
    expect(host.taps, 1);
    expect(find.byKey(const ValueKey('tour-missing')), findsNothing);
    expect(tester.widget<Text>(find.byKey(const ValueKey('tour-step-title'))).data, 'steps.g-pin.title');

    // Bước sau cũng ở màn chi tiết: phần tử đã có ⇒ không chạm lại.
    await tester.tap(find.byKey(const ValueKey('tour-next')));
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(host.taps, 1);
    expect(tester.widget<Text>(find.byKey(const ValueKey('tour-step-title'))).data, 'steps.g-pin-again.title');
  });
}
