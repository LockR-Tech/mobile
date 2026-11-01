import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_laundry_locker/core/l10n/l10n.dart';
import 'package:smart_laundry_locker/core/l10n/language_toggle.dart';
import 'package:smart_laundry_locker/core/l10n/locale_provider.dart';
import 'package:smart_laundry_locker/core/services/app_restart_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Ngôn ngữ là trạng thái toàn cục: trả về tiếng Việt cho các test khác.
  tearDown(() => L10n.load(L10n.vi));

  test('mặc định là tiếng Việt', () {
    expect(L10n.isEnglish, isFalse);
    expect(L10n.current.navHome, 'Trang chủ');
  });

  test('đổi sang tiếng Anh và lưu lựa chọn', () async {
    SharedPreferences.setMockInitialValues({});

    await LocaleProvider.instance.setLocale(L10n.en);

    expect(L10n.isEnglish, isTrue);
    expect(L10n.current.navHome, 'Home');
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('app_locale'), 'en');
  });

  test('khôi phục ngôn ngữ đã lưu khi mở app', () async {
    SharedPreferences.setMockInitialValues({'app_locale': 'en'});

    await LocaleProvider.instance.restore();

    expect(L10n.isEnglish, isTrue);
  });

  test('tiếng Anh chia số ít / số nhiều', () {
    L10n.load(L10n.en);

    expect(L10n.current.hoursValue(1), '1 hour');
    expect(L10n.current.hoursValue(3), '3 hours');
    expect(L10n.current.ordAddHours(1), 'Add 1 hour');
  });

  test('tra bản dịch theo từng ngôn ngữ', () {
    final vi = lookupAppLocalizations(L10n.vi);
    final en = lookupAppLocalizations(L10n.en);

    expect(vi.commonRetry, 'Thử lại');
    expect(en.commonRetry, 'Try again');
  });

  testWidgets('nút VI | EN đổi ngôn ngữ và dựng lại app', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(
      RestartableApp(
        child: MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              backgroundColor: Colors.black,
              body: Column(
                children: [
                  const LanguageToggle(),
                  Text(context.l10n.navHome),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    expect(find.text('Trang chủ'), findsOneWidget);

    await tester.tap(find.text('EN'));
    await tester.pumpAndSettle();

    expect(L10n.isEnglish, isTrue);
    expect(find.text('Home'), findsOneWidget);
  });
}
