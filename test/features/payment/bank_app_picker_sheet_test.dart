import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
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
  testWidgets('chỉ liệt kê app tự điền, có ô tìm kiếm, mở link điền sẵn', (
    tester,
  ) async {
    final opened = <Uri>[];
    bool? result;
    await _pump(
      tester,
      (url) async {
        opened.add(url);
        return true;
      },
      onResult: (r) => result = r,
    );

    expect(find.text('Vietcombank'), findsOneWidget);
    expect(find.text('Techcombank'), findsOneWidget);
    expect(find.text('Không tự điền'), findsNothing);

    await tester.enterText(find.byType(TextField), 'tech');
    await tester.pumpAndSettle();
    expect(find.text('Vietcombank'), findsNothing);

    await tester.tap(find.text('Techcombank'));
    await tester.pumpAndSettle();
    expect(
      opened.single.toString(),
      'https://dl.vietqr.io/pay?app=tcb&ba=0123456789@mb&am=20000&tn=LKR81',
    );
    // Mở được app ⇒ bảng đóng lại; quay về app thì màn thanh toán tự kiểm tra.
    expect(result, isTrue);
    expect(find.text('Thanh toán bằng app ngân hàng'), findsNothing);
  });

  testWidgets('không mở được app (chưa cài) ⇒ gợi ý quét mã QR', (tester) async {
    await _pump(tester, (_) async => false);

    await tester.tap(find.text('Vietcombank'));
    await tester.pumpAndSettle();

    expect(find.textContaining('hãy quét mã QR'), findsOneWidget);
  });
}
