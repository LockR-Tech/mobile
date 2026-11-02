import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:smart_laundry_locker/shared/widgets/app_toast.dart';

void main() {
  group('toastToneOf', () {
    test('lỗi được nhận trước "đã" — "Đã xảy ra lỗi" là lỗi', () {
      expect(toastToneOf('Đã xảy ra lỗi, vui lòng thử lại'), ToastTone.error);
      expect(toastToneOf('Thanh toán thất bại'), ToastTone.error);
      expect(toastToneOf('Số dư ví không đủ'), ToastTone.error);
    });

    test('câu server đã dịch sang tiếng Anh', () {
      expect(toastToneOf('Insufficient wallet balance'), ToastTone.error);
      expect(
        toastToneOf('The OTP code is incorrect or has expired'),
        ToastTone.error,
      );
      expect(toastToneOf('Wallet top-up unsuccessful'), ToastTone.error);
      expect(
        toastToneOf(
          'The locker did not respond to the open command, please try again.',
        ),
        ToastTone.error,
      );
      expect(toastToneOf('Payment successful'), ToastTone.success);
      expect(toastToneOf('Order details sent by email'), ToastTone.success);
      expect(toastToneOf('Please sign in'), ToastTone.warning);
    });

    test('thành công, cảnh báo, thông tin', () {
      expect(toastToneOf('Đã lưu thông tin tài khoản'), ToastTone.success);
      expect(toastToneOf('Đăng ký thành công!'), ToastTone.success);
      expect(toastToneOf('Vui lòng nhập tiêu đề'), ToastTone.warning);
      expect(toastToneOf('Bấm quay lại lần nữa để thoát'), ToastTone.info);
      expect(toastToneOf('Press back again to exit'), ToastTone.info);
    });
  });

  group('AppToast', () {
    Future<void> pump(
      WidgetTester tester,
      Widget toast, {
      Brightness b = Brightness.light,
    }) {
      return tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(brightness: b),
          home: Scaffold(
            body: Align(alignment: Alignment.bottomCenter, child: toast),
          ),
        ),
      );
    }

    testWidgets('hiện câu và icon theo loại tin', (tester) async {
      await pump(tester, const AppToast(message: 'Payment successful'));
      expect(find.text('Payment successful'), findsOneWidget);
      expect(find.byIcon(LucideIcons.circleCheck), findsOneWidget);

      await pump(
        tester,
        const AppToast(message: 'Insufficient wallet balance'),
      );
      expect(find.byIcon(LucideIcons.circleX), findsOneWidget);
    });

    testWidgets('loại tin truyền vào thắng loại đoán từ câu', (tester) async {
      await pump(
        tester,
        const AppToast(message: 'Đã gửi', tone: ToastTone.warning),
      );
      expect(find.byIcon(LucideIcons.triangleAlert), findsOneWidget);
    });

    testWidgets('chế độ tối dùng nền than, chữ sáng', (tester) async {
      await pump(tester, const AppToast(message: 'Hello'), b: Brightness.dark);
      final box = tester.widget<DecoratedBox>(
        find.descendant(
          of: find.byType(AppToast),
          matching: find.byType(DecoratedBox),
        ),
      );
      expect((box.decoration as BoxDecoration).color, const Color(0xFF1C1F24));
      final text = tester.widget<Text>(find.text('Hello'));
      expect(text.style?.color, const Color(0xFFF4F5F7));
    });

    testWidgets('câu dài không tràn trên máy hẹp', (tester) async {
      tester.view.physicalSize = const Size(360 * 2, 800 * 2);
      tester.view.devicePixelRatio = 2;
      addTearDown(tester.view.reset);
      await pump(
        tester,
        const AppToast(
          message:
              'The locker did not respond to the emergency open command after 30 seconds — '
              'the box may not be open, please check at the locker and try again',
        ),
      );
      expect(tester.takeException(), isNull);
    });
  });
}
