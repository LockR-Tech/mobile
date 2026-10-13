import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_laundry_locker/features/locker_ops/domain/pickup_code_share.dart';
import 'package:smart_laundry_locker/features/locker_ops/presentation/widgets/pickup_code_share_actions.dart';

const _share = PickupCodeShare(
  code: '654321',
  lockerName: 'Tủ A',
  boxNumber: 3,
  receiverName: 'Bình',
  receiverPhone: '0909 123 456',
);

Future<void> _pump(WidgetTester tester, Widget child) => tester.pumpWidget(
  MaterialApp(
    home: Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: child,
      ),
    ),
  ),
);

void main() {
  testWidgets('chia sẻ mở bảng chia sẻ với tin nhắn soạn sẵn', (tester) async {
    String? sharedText;
    await _pump(
      tester,
      PickupCodeShareActions(
        share: _share,
        smsSupported: true,
        shareText: (text, origin) async => sharedText = text,
        launchSms: (_) async => true,
      ),
    );

    expect(find.text('Gửi mã cho người nhận'), findsOneWidget);
    expect(find.textContaining('cho Bình qua Zalo'), findsOneWidget);
    await tester.tap(find.text('Chia sẻ mã cho người nhận'));
    await tester.pump();

    expect(sharedText, _share.message);
    expect(sharedText, contains('Mã lấy hàng: 654321.'));
  });

  testWidgets('Nhắn SMS mở ứng dụng tin nhắn với số người nhận', (
    tester,
  ) async {
    Uri? opened;
    await _pump(
      tester,
      PickupCodeShareActions(
        share: _share,
        smsSupported: true,
        shareText: (_, _) async {},
        launchSms: (uri) async {
          opened = uri;
          return true;
        },
      ),
    );

    await tester.tap(find.text('Nhắn SMS'));
    await tester.pump();

    expect(opened, isNotNull);
    expect(opened!.toString(), startsWith('sms:0909123456?body='));
    expect(
      Uri.decodeComponent(opened.toString().split('body=').last),
      _share.message,
    );
  });

  testWidgets('không có số người nhận hoặc trên web thì ẩn Nhắn SMS', (
    tester,
  ) async {
    await _pump(
      tester,
      PickupCodeShareActions(
        share: const PickupCodeShare(code: '111222'),
        smsSupported: true,
        shareText: (_, _) async {},
      ),
    );
    expect(find.text('Nhắn SMS'), findsNothing);
    expect(find.text('Sao chép tin nhắn'), findsOneWidget);
    expect(find.textContaining('cho người nhận qua Zalo'), findsOneWidget);

    await _pump(
      tester,
      PickupCodeShareActions(
        share: _share,
        smsSupported: false,
        shareText: (_, _) async {},
      ),
    );
    expect(find.text('Nhắn SMS'), findsNothing);
    expect(find.text('Chia sẻ mã cho người nhận'), findsOneWidget);
  });

  testWidgets('Sao chép tin nhắn chép cả tin vào clipboard', (tester) async {
    String? copied;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          copied = (call.arguments as Map)['text'] as String?;
        }
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
    await _pump(
      tester,
      PickupCodeShareActions(
        share: _share,
        smsSupported: false,
        shareText: (_, _) async {},
      ),
    );

    await tester.tap(find.text('Sao chép tin nhắn'));
    await tester.pump();

    expect(copied, _share.message);
    expect(find.textContaining('Đã sao chép tin nhắn'), findsOneWidget);
  });

  testWidgets('bảng chia sẻ lỗi thì chép tin nhắn và báo cho người dùng', (
    tester,
  ) async {
    String? copied;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          copied = (call.arguments as Map)['text'] as String?;
        }
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
    await _pump(
      tester,
      PickupCodeShareActions(
        share: _share,
        smsSupported: true,
        shareText: (_, _) async => throw PlatformException(code: 'x'),
        launchSms: (_) async => false,
      ),
    );

    await tester.tap(find.text('Chia sẻ mã cho người nhận'));
    await tester.pump();
    expect(copied, _share.message);
    expect(find.textContaining('Không mở được bảng chia sẻ'), findsOneWidget);

    copied = null;
    await tester.tap(find.text('Nhắn SMS'));
    await tester.pump();
    expect(copied, _share.message);
    expect(
      find.textContaining('Không mở được ứng dụng tin nhắn'),
      findsOneWidget,
    );
  });
}
