import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:smart_laundry_locker/features/assistant/data/assistant_service.dart';
import 'package:smart_laundry_locker/features/assistant/data/models/assistant_models.dart';
import 'package:smart_laundry_locker/features/assistant/presentation/providers/assistant_availability.dart';
import 'package:smart_laundry_locker/features/assistant/presentation/providers/assistant_chat_controller.dart';

import 'assistant_fakes.dart';

void main() {
  late FakeAssistantService service;
  late AssistantChatController chat;

  setUp(() {
    service = FakeAssistantService();
    chat = AssistantChatController(service: service);
  });

  tearDown(() => chat.dispose());

  group('AssistantChatController', () {
    test('câu đầu mở hội thoại mới, câu sau giữ conversationId', () async {
      service.answers
        ..add(fakeAnswer(conversationId: 7))
        ..add(fakeAnswer(conversationId: 7));

      await chat.send('Làm sao để gửi hàng qua tủ?');
      await chat.send('Còn phí thì sao?');

      expect(service.askCalls.map((c) => c.conversationId), [null, 7]);
      expect(chat.conversationId, 7);
      expect(chat.messages.map((m) => m.role), [
        AssistantRole.user,
        AssistantRole.assistant,
        AssistantRole.user,
        AssistantRole.assistant,
      ]);
    });

    test('startNew() ⇒ câu kế tiếp mở hội thoại mới', () async {
      service.answers
        ..add(fakeAnswer(conversationId: 7))
        ..add(fakeAnswer(conversationId: 8));

      await chat.send('Câu 1');
      chat.startNew();
      expect(chat.messages, isEmpty);
      await chat.send('Câu 2');

      expect(service.askCalls.map((c) => c.conversationId), [null, null]);
      expect(chat.conversationId, 8);
    });

    test('lỗi ⇒ đánh dấu chưa gửi được, thử lại gửi đúng câu', () async {
      service.answers
        ..add(
          const AssistantException(
            'Trợ lý đang bận hoặc gặp sự cố, vui lòng thử lại sau',
            code: 'ASSISTANT_UNAVAILABLE',
            statusCode: 503,
          ),
        )
        ..add(fakeAnswer());

      await chat.send('Hết giờ thuê ô thì làm sao?');

      expect(chat.error?.code, 'ASSISTANT_UNAVAILABLE');
      expect(chat.canRetry, isTrue);
      expect(chat.messages.single.failed, isTrue);

      await chat.retry();

      expect(chat.error, isNull);
      expect(service.askCalls.map((c) => c.question), [
        'Hết giờ thuê ô thì làm sao?',
        'Hết giờ thuê ô thì làm sao?',
      ]);
      expect(chat.messages, hasLength(2));
      expect(chat.messages.first.failed, isFalse);
    });

    test('hội thoại đã bị xoá (404) ⇒ thử lại sẽ mở hội thoại mới', () async {
      service.answers
        ..add(fakeAnswer(conversationId: 7))
        ..add(
          const AssistantException(
            'Không tìm thấy cuộc hội thoại này, có thể nó đã bị xoá.',
            code: 'NOT_FOUND',
            statusCode: 404,
          ),
        )
        ..add(fakeAnswer(conversationId: 9));

      await chat.send('Câu 1');
      await chat.send('Câu 2');
      await chat.retry();

      expect(service.askCalls.map((c) => c.conversationId), [null, 7, null]);
      expect(chat.conversationId, 9);
    });

    test('không gửi khi đang chờ trả lời', () async {
      final pending = Completer<AssistantAnswer>();
      service.answers.add(pending);

      final first = chat.send('Câu 1');
      expect(chat.sending, isTrue);
      expect(chat.busy, isTrue);
      await chat.send('Câu 2');
      expect(service.askCalls, hasLength(1));

      pending.complete(fakeAnswer());
      await first;
      expect(chat.sending, isFalse);
    });

    test('câu trả lời về muộn của hội thoại cũ bị bỏ qua', () async {
      final pending = Completer<AssistantAnswer>();
      service.answers.add(pending);

      final first = chat.send('Câu 1');
      chat.startNew();
      pending.complete(fakeAnswer(conversationId: 7));
      await first;

      expect(chat.messages, isEmpty);
      expect(chat.conversationId, isNull);
      expect(chat.sending, isFalse);
    });

    test('mở hội thoại cũ ⇒ nạp tin nhắn, hỏi tiếp trong đó', () async {
      service.details[9] = const AssistantConversationDetail(
        conversation: AssistantConversation(
          id: 9,
          title: 'Gửi hàng',
          messageCount: 2,
        ),
        messages: [
          AssistantMessage(role: AssistantRole.user, content: 'Câu cũ'),
          AssistantMessage(
            role: AssistantRole.assistant,
            content: 'Trả lời cũ',
          ),
        ],
      );
      service.answers.add(fakeAnswer(conversationId: 9));

      await chat.openConversation(9);
      expect(chat.messages, hasLength(2));
      expect(chat.conversationId, 9);

      await chat.send('Câu mới');
      expect(service.askCalls.single.conversationId, 9);
    });

    test('mở hội thoại lỗi ⇒ báo lỗi, khoá ô nhập', () async {
      await chat.openConversation(404);

      expect(chat.loadError, contains('Không tìm thấy'));
      expect(chat.busy, isTrue);
      expect(chat.conversationId, isNull);
    });

    test('hội thoại đang mở bị xoá ở màn Lịch sử ⇒ về hội thoại mới', () async {
      service.answers.add(fakeAnswer(conversationId: 7));
      await chat.send('Câu 1');

      await chat.applyHistoryResult(
        const AssistantHistoryResult(deletedIds: {7}),
      );

      expect(chat.conversationId, isNull);
      expect(chat.messages, isEmpty);
    });
  });

  group('AssistantAvailability', () {
    test('chưa đăng nhập thì không gọi status', () async {
      var created = 0;
      final availability = AssistantAvailability(
        serviceFactory: () {
          created++;
          return service;
        },
        isSignedIn: () => false,
      );

      expect(await availability.refresh(), isNull);
      expect(created, 0);
      expect(availability.enabled, isFalse);
    });

    test('đọc status và dùng lại kết quả còn mới', () async {
      var calls = 0;
      final availability = AssistantAvailability(
        serviceFactory: () {
          calls++;
          return service;
        },
        isSignedIn: () => true,
      );

      final status = await availability.refresh();
      await availability.refresh();

      expect(status?.enabled, isTrue);
      expect(availability.enabled, isTrue);
      expect(calls, 1);
    });

    test('lỗi mạng ⇒ giữ null (lối vào ẩn), không ném lỗi', () async {
      service.statusError = const AssistantException(
        'Trợ lý đang bận hoặc gặp sự cố, vui lòng thử lại sau.',
        statusCode: 503,
      );
      final availability = AssistantAvailability(
        serviceFactory: () => service,
        isSignedIn: () => true,
      );

      expect(await availability.refresh(), isNull);
      expect(availability.enabled, isFalse);
    });
  });
}
