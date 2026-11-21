// Neo hướng dẫn (F3-G13): nút semantics mang identifier `tour:<neo>` để script chụp ảnh HDSD tìm phần tử trên bản
// Flutter web — kể cả khi phần tử là vùng bấm được có chữ (thẻ ca làm của KTV từng mất identifier vì bị gộp).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_laundry_locker/features/onboarding/presentation/tour_anchor.dart';

void main() {
  testWidgets('vùng bấm được có chữ vẫn giữ identifier riêng của neo', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Column(
          children: [
            TourAnchor(
              'shift-card',
              child: Material(
                child: InkWell(
                  onTap: () {},
                  child: const Padding(padding: EdgeInsets.all(12), child: Text('ĐANG TRONG CA')),
                ),
              ),
            ),
            const TourAnchor('plain', child: SizedBox(width: 40, height: 40)),
          ],
        ),
      ),
    ));
    expect(find.bySemanticsIdentifier('tour:shift-card'), findsOneWidget);
    expect(find.bySemanticsIdentifier('tour:plain'), findsOneWidget);
    // Phần tử bấm được vẫn là một nút riêng có nhãn và thao tác bấm (trình đọc màn hình không mất gì).
    expect(
      tester.getSemantics(find.text('ĐANG TRONG CA')),
      matchesSemantics(label: 'ĐANG TRONG CA', hasTapAction: true, isFocusable: true, hasFocusAction: true),
    );
    handle.dispose();
  });
}
