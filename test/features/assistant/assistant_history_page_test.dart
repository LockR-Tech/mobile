import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_laundry_locker/core/routing/app_router.dart';
import 'package:smart_laundry_locker/features/assistant/data/models/assistant_models.dart';
import 'package:smart_laundry_locker/features/assistant/presentation/pages/assistant_chat_page.dart';
import 'package:smart_laundry_locker/features/assistant/presentation/pages/assistant_history_page.dart';

import 'assistant_fakes.dart';

Finder _text(String text) => find.textContaining(text, findRichText: true);

/// Nút "Xoá" của hộp thoại xác nhận (nền vuốt của Dismissible cũng có chữ "Xoá").
final _confirmDelete = find.widgetWithText(TextButton, 'Xoá');

FakeAssistantService _serviceWithHistory() {
  final service = FakeAssistantService();
  service.conversationList = [
    const AssistantConversation(
      id: 9,
      title: 'Làm sao để gửi hàng qua tủ?',
      messageCount: 2,
    ),
    const AssistantConversation(
      id: 8,
      title: 'Hết giờ thuê ô thì làm sao?',
      messageCount: 4,
    ),
  ];
  service.details[9] = const AssistantConversationDetail(
    conversation: AssistantConversation(
      id: 9,
      title: 'Làm sao để gửi hàng qua tủ?',
      messageCount: 2,
    ),
    messages: [
      AssistantMessage(
        role: AssistantRole.user,
        content: 'Làm sao để gửi hàng qua tủ?',
      ),
      AssistantMessage(
        role: AssistantRole.assistant,
        content: 'Chọn tủ, chọn ô trống rồi bấm Gửi hàng.',
        sources: [
          AssistantSource(
            documentId: 3,
            documentTitle: 'Hướng dẫn gửi hàng',
            chunkId: 11,
            citedText: 'Chọn tủ gần bạn nhất.',
          ),
        ],
      ),
    ],
  );
  return service;
}

Future<void> _pumpChatWithHistory(
  WidgetTester tester,
  FakeAssistantService service,
) async {
  usePhoneScreen(tester);
  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => AssistantChatPage(
          service: service,
          availability: fakeAvailability(service),
          roles: const ['CUSTOMER'],
        ),
      ),
      GoRoute(
        path: AppRouter.assistantHistory,
        builder: (context, state) => AssistantHistoryPage(service: service),
      ),
    ],
  );
  await tester.pumpWidget(MaterialApp.router(routerConfig: router));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('mở lịch sử, chạm một hội thoại ⇒ nạp tin nhắn và hỏi tiếp '
      'trong hội thoại đó', (tester) async {
    final service = _serviceWithHistory();
    service.answers.add(fakeAnswer(conversationId: 9));
    await _pumpChatWithHistory(tester, service);

    await tester.tap(find.byTooltip('Lịch sử hỏi đáp'));
    await tester.pumpAndSettle();

    expect(find.text('Lịch sử hỏi đáp'), findsOneWidget);
    expect(find.text('Làm sao để gửi hàng qua tủ?'), findsOneWidget);
    expect(find.text('Hết giờ thuê ô thì làm sao?'), findsOneWidget);
    expect(_text('2 tin nhắn'), findsOneWidget);

    await tester.tap(find.text('Làm sao để gửi hàng qua tủ?'));
    await tester.pumpAndSettle();

    expect(find.text('Trợ lý hỏi đáp'), findsOneWidget);
    expect(_text('rồi bấm Gửi hàng'), findsOneWidget);
    expect(find.text('Nguồn (1)'), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('assistant-input')),
      'Còn phí thì sao?',
    );
    await tester.pump();
    await tester.tap(find.byKey(const Key('assistant-send')));
    await tester.pumpAndSettle();

    expect(service.askCalls.single.conversationId, 9);
  });

  testWidgets('nhấn giữ ⇒ xác nhận ⇒ xoá hội thoại', (tester) async {
    final service = _serviceWithHistory();
    await _pumpChatWithHistory(tester, service);
    await tester.tap(find.byTooltip('Lịch sử hỏi đáp'));
    await tester.pumpAndSettle();

    await tester.longPress(find.text('Hết giờ thuê ô thì làm sao?'));
    await tester.pumpAndSettle();
    expect(find.text('Xoá cuộc hội thoại?'), findsOneWidget);

    // Huỷ thì không xoá.
    await tester.tap(find.text('Huỷ'));
    await tester.pumpAndSettle();
    expect(service.deletedIds, isEmpty);
    expect(find.text('Hết giờ thuê ô thì làm sao?'), findsOneWidget);

    await tester.longPress(find.text('Hết giờ thuê ô thì làm sao?'));
    await tester.pumpAndSettle();
    await tester.tap(_confirmDelete);
    await tester.pumpAndSettle();

    expect(service.deletedIds, [8]);
    expect(find.text('Hết giờ thuê ô thì làm sao?'), findsNothing);
    expect(find.text('Đã xoá cuộc hội thoại'), findsOneWidget);
  });

  testWidgets('vuốt trái ⇒ xác nhận ⇒ xoá hội thoại', (tester) async {
    final service = _serviceWithHistory();
    await _pumpChatWithHistory(tester, service);
    await tester.tap(find.byTooltip('Lịch sử hỏi đáp'));
    await tester.pumpAndSettle();

    await tester.drag(
      find.text('Làm sao để gửi hàng qua tủ?'),
      const Offset(-500, 0),
    );
    await tester.pumpAndSettle();
    expect(find.text('Xoá cuộc hội thoại?'), findsOneWidget);
    await tester.tap(_confirmDelete);
    await tester.pumpAndSettle();

    expect(service.deletedIds, [9]);
    expect(find.text('Làm sao để gửi hàng qua tủ?'), findsNothing);
  });

  testWidgets('xoá hội thoại đang mở ⇒ màn chat về hội thoại mới', (
    tester,
  ) async {
    final service = _serviceWithHistory();
    service.answers.add(fakeAnswer(conversationId: 8));
    await _pumpChatWithHistory(tester, service);

    await tester.enterText(
      find.byKey(const Key('assistant-input')),
      'Hết giờ thuê ô thì làm sao?',
    );
    await tester.pump();
    await tester.tap(find.byKey(const Key('assistant-send')));
    await tester.pumpAndSettle();
    expect(find.text('Nguồn (2)'), findsOneWidget);

    await tester.tap(find.byTooltip('Lịch sử hỏi đáp'));
    await tester.pumpAndSettle();
    await tester.longPress(find.text('Hết giờ thuê ô thì làm sao?').last);
    await tester.pumpAndSettle();
    await tester.tap(_confirmDelete);
    await tester.pumpAndSettle();

    // Nút quay lại của header.
    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();

    expect(find.text('Trợ lý hỏi đáp'), findsOneWidget);
    expect(find.text('Nguồn (2)'), findsNothing);
    // Về màn giới thiệu với câu hỏi gợi ý.
    expect(find.text('Làm sao để gửi hàng qua tủ?'), findsOneWidget);
  });
}
