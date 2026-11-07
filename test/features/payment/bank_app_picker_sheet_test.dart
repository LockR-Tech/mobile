import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_laundry_locker/features/payment/data/vietqr_service.dart';
import 'package:smart_laundry_locker/features/payment/domain/sepay_transfer.dart';
import 'package:smart_laundry_locker/features/payment/presentation/widgets/bank_app_picker_sheet.dart';

import '../../helpers/test_helpers.dart';

VietQrService _service() {
  final dio = Dio();
  DioAdapter(dio: dio)
    ..onGet(
      'https://api.vietqr.io/v2/android-app-deeplinks',
      (server) => server.reply(200, {
        'apps': [
          {'appId': 'vcb', 'appName': 'Vietcombank', 'autofill': 1},
          {'appId': 'tcb', 'appName': 'Techcombank', 'autofill': 1},
          {'appId': 'xyz', 'appName': 'Không tự điền', 'autofill': 0},
        ],
      }),
    )
    ..onGet(
      'https://api.vietqr.io/v2/banks',
      (server) => server.reply(200, {
        'data': [
          {'bin': '970422', 'code': 'MB'},
        ],
      }),
    );
  return VietQrService(dio: dio);
}

const _transfer = SepayTransfer(
  qrImageUrl: 'https://img.vietqr.io/image/970422-0123456789-compact2.jpg?amount=20000&addInfo=LKR81',
  bankBin: '970422',
  accountNo: '0123456789',
  amount: 20000,
  transferContent: 'LKR81',
);

/// Mở bảng như màn thanh toán thật; [onResult] nhận "đã mở app ngân hàng".
Future<void> _pump(
  WidgetTester tester,
  ExternalUrlLauncher launcher, {
  void Function(bool opened)? onResult,
  QrGallerySaver? saveQr,
  List<String>? savedNames,
}) async {
  await tester.binding.setSurfaceSize(const Size(400, 900));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              final opened = await showBankAppPicker(
                context,
                transfer: _transfer,
                service: _service(),
                launcher: launcher,
                saveQr: saveQr ??
                    (url, name) async {
                      savedNames?.add(name);
                      return true;
                    },
              );
              onResult?.call(opened);
            },
            child: const Text('Mở'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Mở'));
  await tester.pumpAndSettle();
}

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async => null);
  });

  testWidgets('hiện mọi app ngân hàng, có ô tìm kiếm', (tester) async {
    await _pump(tester, (_) async => true);

    expect(find.text('Vietcombank'), findsOneWidget);
    expect(find.text('Techcombank'), findsOneWidget);
    // Link dl.vietqr.io không tự điền ở app nào trên Android ⇒ không lọc theo autofill.
    expect(find.text('Không tự điền'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'tech');
    await tester.pumpAndSettle();
    expect(find.text('Vietcombank'), findsNothing);
  });

  testWidgets('chọn app ⇒ lưu mã QR, hiện các bước quét từ ảnh rồi mới mở app', (
    tester,
  ) async {
    final opened = <Uri>[];
    final saved = <String>[];
    bool? result;
    await _pump(
      tester,
      (url) async {
        opened.add(url);
        return true;
      },
      onResult: (r) => result = r,
      savedNames: saved,
    );

    await tester.tap(find.text('Techcombank'));
    await tester.pumpAndSettle();

    expect(saved, ['LockR-LKR81']);
    expect(opened, isEmpty, reason: 'chưa mở app trước khi khách đọc các bước');
    expect(find.textContaining('Đã lưu mã QR vào Thư viện ảnh'), findsOneWidget);
    expect(find.textContaining('Quét QR'), findsOneWidget);
    expect(find.textContaining('20.000đ'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Mở Techcombank'));
    await tester.pumpAndSettle();
    expect(
      opened.single.toString(),
      'https://dl.vietqr.io/pay?app=tcb&ba=0123456789@mb&am=20000&tn=LKR81',
    );
    expect(result, isTrue);
    expect(find.text('Thanh toán bằng app ngân hàng'), findsNothing);
  });

  testWidgets('không lưu được mã QR ⇒ hướng dẫn chuyển tay kèm nội dung', (
    tester,
  ) async {
    await _pump(tester, (_) async => true, saveQr: (_, __) async => false);

    await tester.tap(find.text('Vietcombank'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Không lưu được mã QR'), findsOneWidget);
    expect(find.textContaining('0123456789'), findsOneWidget);
    expect(find.textContaining('LKR81'), findsOneWidget);
  });

  testWidgets('bấm Hủy ở các bước ⇒ không mở app, vẫn ở bảng chọn', (tester) async {
    final opened = <Uri>[];
    await _pump(tester, (url) async {
      opened.add(url);
      return true;
    });

    await tester.tap(find.text('Vietcombank'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Hủy'));
    await tester.pumpAndSettle();

    expect(opened, isEmpty);
    expect(find.text('Thanh toán bằng app ngân hàng'), findsOneWidget);
  });

  testWidgets('không mở được app (chưa cài) ⇒ gợi ý quét mã QR', (tester) async {
    await _pump(tester, (_) async => false);

    await tester.tap(find.text('Vietcombank'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Mở Vietcombank'));
    await tester.pumpAndSettle();

    expect(find.textContaining('hãy quét mã QR'), findsOneWidget);
  });
}
