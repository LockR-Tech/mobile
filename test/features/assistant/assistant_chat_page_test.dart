import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_laundry_locker/core/routing/app_router.dart';
import 'package:smart_laundry_locker/features/assistant/data/assistant_service.dart';
import 'package:smart_laundry_locker/features/assistant/data/models/assistant_models.dart';
import 'package:smart_laundry_locker/features/assistant/presentation/pages/assistant_chat_page.dart';
import 'package:smart_laundry_locker/features/assistant/presentation/pages/assistant_history_page.dart';

import '../../helpers/test_helpers.dart';
import 'assistant_fakes.dart';

final _input = find.byKey(const Key('assistant-input'));
final _sendButton = find.byKey(const Key('assistant-send'));

Finder _text(String text) => find.textContaining(text, findRichText: true);

Future<void> _pumpChat(
  WidgetTester tester,
  AssistantService service, {
  FakeAssistantService? statusSource,
  List<String> roles = const ['CUSTOMER'],
}) async {
  usePhoneScreen(tester);
  final status = statusSource ?? (service as FakeAssistantService);
  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => AssistantChatPage(
          service: service,
          availability: fakeAvailability(status),
          roles: roles,
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

Future<void> _ask(WidgetTester tester, String question) async {
  await tester.enterText(_input, question);
  await tester.pump();
  await tester.tap(_sendButton);
  await tester.pump();
}

void main() {
  testWidgets('màn giới thiệu: giải thích nguồn tài liệu + câu hỏi gợi ý '
      'cho khách hàng', (tester) async {
    await _pumpChat(tester, FakeAssistantService());

    expect(_text('tài liệu chính thức của Lock.R'), findsOneWidget);
    expect(find.text('Làm sao để gửi hàng qua tủ?'), findsOneWidget);
    expect(find.text('Tôi thanh toán bằng những cách nào?'), findsOneWidget);
    expect(find.text('Hết giờ thuê ô thì làm sao?'), findsOneWidget);
    expect(
      find.text('Kiểm tra định kỳ không đạt thì xử lý thế nào?'),
      findsNothing,
    );
  });

  testWidgets('kỹ thuật viên thấy câu hỏi gợi ý dành cho kỹ thuật viên', (
    tester,
  ) async {
    await _pumpChat(
      tester,
      FakeAssistantService(),
      roles: const ['LOCKER_TECHNICIAN'],
    );

    expect(
      find.text('Kiểm tra định kỳ không đạt thì xử lý thế nào?'),
      findsOneWidget,
    );
    expect(find.text('Làm sao để gửi hàng qua tủ?'), findsNothing);
  });

  testWidgets('gửi câu hỏi ⇒ hiện câu trả lời và mục Nguồn; chạm nguồn xem '
      'nguyên văn', (tester) async {
    final service = FakeAssistantService();
    service.answers.add(fakeAnswer());
    await _pumpChat(tester, service);

    await _ask(tester, 'Làm sao để gửi hàng qua tủ?');
    await tester.pumpAndSettle();

    expect(service.askCalls.single.question, 'Làm sao để gửi hàng qua tủ?');
    expect(service.askCalls.single.conversationId, isNull);
    expect(find.text('Làm sao để gửi hàng qua tủ?'), findsOneWidget);
    expect(_text('rồi bấm Gửi hàng'), findsOneWidget);
    expect(find.text('Nguồn (2)'), findsOneWidget);
    // Thu gọn mặc định.
    expect(_text('Hướng dẫn gửi hàng'), findsNothing);

    await tester.tap(find.text('Nguồn (2)'));
    await tester.pumpAndSettle();

    expect(find.text('1. Hướng dẫn gửi hàng'), findsOneWidget);
    expect(find.text('Bước 1: Chọn tủ'), findsOneWidget);
    expect(find.text('2. Câu hỏi thường gặp'), findsOneWidget);
    expect(
      find.text('“Mở ứng dụng và chọn tủ gần bạn nhất trên bản đồ.”'),
      findsOneWidget,
    );

    await tester.tap(find.text('1. Hướng dẫn gửi hàng'));
    await tester.pumpAndSettle();

    expect(find.text('TRÍCH DẪN NGUỒN'), findsOneWidget);
    expect(
      find.text('Mở ứng dụng và chọn tủ gần bạn nhất trên bản đồ.'),
      findsOneWidget,
    );
  });

  testWidgets('câu hỏi tiếp theo gửi kèm conversationId của câu trả lời đầu', (
    tester,
  ) async {
    final service = FakeAssistantService();
    service.answers
      ..add(fakeAnswer(conversationId: 7))
      ..add(fakeAnswer(conversationId: 7, answer: 'Phí tính theo giờ.'));
    await _pumpChat(tester, service);

    await _ask(tester, 'Làm sao để gửi hàng qua tủ?');
    await tester.pumpAndSettle();
    await _ask(tester, 'Còn phí thì sao?');
    await tester.pumpAndSettle();

    expect(service.askCalls.map((c) => c.conversationId), [null, 7]);
    expect(_text('Phí tính theo giờ.'), findsOneWidget);
  });

  testWidgets('đang chờ: hiện "Đang tìm trong tài liệu…" và khoá ô nhập', (
    tester,
  ) async {
    final service = FakeAssistantService();
    final pending = Completer<AssistantAnswer>();
    service.answers.add(pending);
    await _pumpChat(tester, service);

    await _ask(tester, 'Hết giờ thuê ô thì làm sao?');
    await tester.pump();

    expect(find.text('Đang tìm trong tài liệu…'), findsOneWidget);
    expect(tester.widget<TextField>(_input).enabled, isFalse);
    expect(tester.widget<IconButton>(_sendButton).onPressed, isNull);

    pending.complete(fakeAnswer(answer: 'Bạn có thể gia hạn thêm giờ.'));
    await tester.pumpAndSettle();

    expect(find.text('Đang tìm trong tài liệu…'), findsNothing);
    expect(_text('Bạn có thể gia hạn thêm giờ.'), findsOneWidget);
    expect(tester.widget<TextField>(_input).enabled, isTrue);
  });

  testWidgets('câu trả lời bị từ chối hiện như ghi chú, không có nguồn', (
    tester,
  ) async {
    final service = FakeAssistantService();
    service.answers.add(
      fakeAnswer(
        refused: true,
        sources: const [],
        answer:
            'Tài liệu hiện có chưa đề cập nội dung này. Bạn có thể liên hệ '
            'bộ phận hỗ trợ Lock.R để được giúp đỡ.',
      ),
    );
    await _pumpChat(tester, service);

    await _ask(tester, 'Thời tiết hôm nay thế nào?');
    await tester.pumpAndSettle();

    expect(find.text('Chưa có trong tài liệu'), findsOneWidget);
    expect(_text('chưa đề cập nội dung này'), findsOneWidget);
    expect(_text('Nguồn ('), findsNothing);
  });

  testWidgets('giới hạn lượt hỏi: hiện thông báo máy chủ, thử lại được', (
    tester,
  ) async {
    final service = FakeAssistantService();
    service.answers
      ..add(
        const AssistantException(
          'Bạn đã hỏi 20 câu trong một giờ qua, vui lòng thử lại sau',
          code: 'ASSISTANT_RATE_LIMITED',
          statusCode: 429,
        ),
      )
      ..add(fakeAnswer());
    await _pumpChat(tester, service);

    await _ask(tester, 'Tôi thanh toán bằng những cách nào?');
    await tester.pumpAndSettle();

    expect(
      find.text('Bạn đã hỏi 20 câu trong một giờ qua, vui lòng thử lại sau'),
      findsOneWidget,
    );
    expect(find.text('Chưa gửi được'), findsOneWidget);

    await tester.tap(find.text('Thử lại'));
    await tester.pumpAndSettle();

    expect(service.askCalls, hasLength(2));
    expect(
      service.askCalls.last.question,
      'Tôi thanh toán bằng những cách nào?',
    );
    expect(find.text('Chưa gửi được'), findsNothing);
    expect(find.text('Nguồn (2)'), findsOneWidget);
  });

  testWidgets('lỗi 429 thật từ máy chủ đi qua AssistantService tới màn hình', (
    tester,
  ) async {
    final mock = createMockDio();
    mock.adapter.onPost(
      '/api/assistant/ask',
      (server) => server.reply(429, {
        'success': false,
        'code': 'ASSISTANT_RATE_LIMITED',
        'message': 'Bạn đã hỏi 20 câu trong một giờ qua, vui lòng thử lại sau',
        'data': null,
        'errors': null,
      }),
    );
    await _pumpChat(
      tester,
      AssistantService(dio: mock.dio),
      statusSource: FakeAssistantService(),
    );

    await _ask(tester, 'Hết giờ thuê ô thì làm sao?');
    await tester.pumpAndSettle();

    expect(
      find.text('Bạn đã hỏi 20 câu trong một giờ qua, vui lòng thử lại sau'),
      findsOneWidget,
    );
  });

  testWidgets('chạm câu hỏi gợi ý là hỏi ngay', (tester) async {
    final service = FakeAssistantService();
    service.answers.add(fakeAnswer());
    await _pumpChat(tester, service);

    final example = find.text('Hết giờ thuê ô thì làm sao?');
    await tester.ensureVisible(example);
    await tester.tap(example);
    await tester.pumpAndSettle();

    expect(service.askCalls.single.question, 'Hết giờ thuê ô thì làm sao?');
    expect(find.text('Nguồn (2)'), findsOneWidget);
  });

  testWidgets('chưa cấu hình: hiện "Trợ lý chưa sẵn sàng" thay cho ô nhập', (
    tester,
  ) async {
    final service = FakeAssistantService(
      currentStatus: const AssistantStatus(enabled: true, configured: false),
    );
    await _pumpChat(tester, service);

    expect(find.text('Trợ lý chưa sẵn sàng'), findsOneWidget);
    expect(_input, findsNothing);

    // Câu hỏi gợi ý chỉ để đọc.
    final example = find.text('Hết giờ thuê ô thì làm sao?');
    await tester.ensureVisible(example);
    await tester.tap(example);
    await tester.pumpAndSettle();
    expect(service.askCalls, isEmpty);
  });

  testWidgets('đang tắt: hiện "Trợ lý đang tạm tắt"', (tester) async {
    final service = FakeAssistantService(
      currentStatus: const AssistantStatus(enabled: false, configured: true),
    );
    await _pumpChat(tester, service);

    expect(find.text('Trợ lý đang tạm tắt'), findsOneWidget);
    expect(_input, findsNothing);
  });
}
