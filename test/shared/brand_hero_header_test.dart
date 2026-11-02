import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:smart_laundry_locker/shared/widgets/user_ui_kit.dart';

Widget _host(Widget header, {Brightness brightness = Brightness.light}) => MaterialApp(
      theme: ThemeData(brightness: brightness),
      home: Scaffold(body: Column(children: [header])),
    );

void main() {
  testWidgets('tiêu đề dài xuống tối đa 2 dòng thay vì cắt ngay ở dòng đầu', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    // Font test vẽ mỗi ký tự rộng bằng cỡ chữ: 16 ký tự × 26 px không vừa một dòng.
    await tester.pumpWidget(_host(const BrandHeroHeader(
      title: 'Đơn hàng của tôi',
      subtitle: 'Theo dõi các đơn gửi và nhận',
      art: HeroArt.order,
    )));

    final title = tester.widget<Text>(find.text('Đơn hàng của tôi'));
    expect(title.maxLines, 2);
    final paragraph = tester.renderObject<RenderParagraph>(find.text('Đơn hàng của tôi'));
    expect(paragraph.didExceedMaxLines, isFalse);
    expect(paragraph.size.height, greaterThan(26 * 1.15 * 1.5), reason: 'đã xuống dòng thứ hai');
    expect(find.byIcon(LucideIcons.receipt), findsOneWidget);
  });

  testWidgets('nút tròn trong header sáng: nền trắng, icon navy', (tester) async {
    await tester.pumpWidget(_host(BrandHeroHeader(
      title: 'Ví',
      art: HeroArt.wallet,
      trailing: BrandCircleIconButton(icon: LucideIcons.refreshCw, onTap: () {}),
    )));

    final icon = tester.widget<Icon>(find.byIcon(LucideIcons.refreshCw));
    expect(icon.color, const Color(0xFF0A2342));
    // Hình minh hoạ: icon ví trong thẻ nghiêng góc phải.
    expect(find.byIcon(LucideIcons.wallet), findsOneWidget);
  });

  testWidgets('dark mode: header tông tối, nút icon trắng', (tester) async {
    await tester.pumpWidget(_host(
      BrandHeroHeader(
        title: 'Ví',
        trailing: BrandCircleIconButton(icon: LucideIcons.refreshCw, onTap: () {}),
      ),
      brightness: Brightness.dark,
    ));

    expect(tester.widget<Icon>(find.byIcon(LucideIcons.refreshCw)).color, Colors.white);
    expect(tester.widget<Text>(find.text('Ví')).style!.color, const Color(0xFFF1F5F9));
  });

  testWidgets('ngoài header nút tròn giữ kiểu kính tối cũ', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: BrandCircleIconButton(icon: LucideIcons.refreshCw, onTap: () {}),
    ));
    expect(tester.widget<Icon>(find.byIcon(LucideIcons.refreshCw)).color, Colors.white);
  });
}
