import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_laundry_locker/features/assistant/data/assistant_service.dart';
import 'package:smart_laundry_locker/features/assistant/data/models/assistant_models.dart';

import '../../helpers/test_helpers.dart';

/// Ghi lại request cuối cùng Dio gửi đi (method, path, body, timeout).
class _RequestRecorder extends Interceptor {
  final List<RequestOptions> requests = [];

  RequestOptions get last => requests.last;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    requests.add(options);
    handler.next(options);
  }
}

Map<String, dynamic> _apiErrorBody(String code, String message) => {
  'success': false,
  'code': code,
  'message': message,
  'data': null,
  'errors': null,
};

Map<String, dynamic> _answerJson({
  int conversationId = 7,
  bool refused = false,
  List<Map<String, dynamic>>? sources,
}) => {
  'conversationId': conversationId,
  'messageId': 42,
  'answer': 'Bạn chọn tủ, chọn ô trống rồi bấm **Gửi hàng**.',
  'refused': refused,
  'sources':
      sources ??
      [
        {
          'documentId': 3,
          'documentTitle': 'Hướng dẫn gửi hàng',
          'chunkId': 11,
          'heading': 'Bước 1',
          'citedText': 'Chọn tủ gần bạn nhất.',
        },
        {
          'documentId': 4,
          'documentTitle': 'Câu hỏi thường gặp',
          'chunkId': 12,
          'heading': null,
          'citedText': 'Có thể thanh toán bằng ví.',
        },
      ],
  'createdAt': '2026-09-21T03:15:00',
};

void main() {
  late Dio dio;
  late DioAdapter adapter;
  late _RequestRecorder recorder;
  late AssistantService service;

  setUp(() {
    final mock = createMockDio();
    dio = mock.dio;
    adapter = mock.adapter;
    recorder = _RequestRecorder();
    dio.interceptors.add(recorder);
    service = AssistantService(dio: dio);
  });

  group('status()', () {
    test('GET /api/assistant/status và đọc enabled/configured', () async {
      adapter.onGet(
        '/api/assistant/status',
        (server) =>
            server.reply(200, apiOk({'enabled': true, 'configured': false})),
      );

      final status = await service.status();

      expect(recorder.last.method, 'GET');
      expect(recorder.last.path, '/api/assistant/status');
      expect(status.enabled, isTrue);
      expect(status.configured, isFalse);
      expect(status.canAsk, isFalse);
    });
  });

  group('ask()', () {
    test('hội thoại mới: POST /api/assistant/ask chỉ gửi question '
        '(đã trim), không kèm conversationId', () async {
      adapter.onPost(
        '/api/assistant/ask',
        (server) => server.reply(200, apiOk(_answerJson())),
      );

      final answer = await service.ask('  Làm sao để gửi hàng qua tủ?  ');

      expect(recorder.last.method, 'POST');
      expect(recorder.last.path, '/api/assistant/ask');
      expect(recorder.last.data, {'question': 'Làm sao để gửi hàng qua tủ?'});
      expect(answer.conversationId, 7);
      expect(answer.messageId, 42);
      expect(answer.refused, isFalse);
      expect(answer.sources, hasLength(2));
      expect(answer.sources.first.documentTitle, 'Hướng dẫn gửi hàng');
      expect(answer.sources.first.heading, 'Bước 1');
      expect(answer.sources.first.citedText, 'Chọn tủ gần bạn nhất.');
      expect(answer.sources.last.heading, isNull);
      // LocalDateTime không offset của backend được hiểu là UTC.
      expect(answer.createdAt, DateTime.utc(2026, 9, 21, 3, 15).toLocal());
    });

    test('hỏi tiếp: gửi kèm conversationId', () async {
      adapter.onPost(
        '/api/assistant/ask',
        (server) => server.reply(200, apiOk(_answerJson())),
      );

      await service.ask('Còn phí thì sao?', conversationId: 7);

      expect(recorder.last.data, {
        'conversationId': 7,
        'question': 'Còn phí thì sao?',
      });
    });

    test('request hỏi có receiveTimeout riêng 120 s, '
        'không đổi mặc định của Dio', () async {
      dio.options.receiveTimeout = const Duration(seconds: 30);
      adapter.onPost(
        '/api/assistant/ask',
        (server) => server.reply(200, apiOk(_answerJson())),
      );

      await service.ask('Hết giờ thuê ô thì làm sao?');

      expect(recorder.last.receiveTimeout, const Duration(seconds: 120));
      expect(AssistantService.askReceiveTimeout, const Duration(seconds: 120));
      expect(dio.options.receiveTimeout, const Duration(seconds: 30));
    });

    test('các request khác giữ timeout mặc định', () async {
      dio.options.receiveTimeout = const Duration(seconds: 30);
      adapter.onGet(
        '/api/assistant/conversations',
        (server) => server.reply(200, apiOk([])),
      );

      await service.conversations();

      expect(recorder.last.receiveTimeout, const Duration(seconds: 30));
    });

    test('câu trả lời bị từ chối: refused=true, không có nguồn', () async {
      adapter.onPost(
        '/api/assistant/ask',
        (server) => server.reply(
          200,
          apiOk(_answerJson(refused: true, sources: const [])),
        ),
      );

      final answer = await service.ask('Thời tiết hôm nay thế nào?');

      expect(answer.refused, isTrue);
      expect(answer.sources, isEmpty);
    });

    test('câu hỏi rỗng / quá 2000 ký tự bị chặn trước khi gọi mạng', () async {
      await expectLater(
        service.ask('   '),
        throwsA(
          isA<AssistantException>().having(
            (e) => e.code,
            'code',
            'VALIDATION_ERROR',
          ),
        ),
      );
      await expectLater(
        service.ask('a' * 2001),
        throwsA(isA<AssistantException>()),
      );
      expect(recorder.requests, isEmpty);
    });
  });

  group('lịch sử hội thoại', () {
    test('GET /api/assistant/conversations', () async {
      adapter.onGet(
        '/api/assistant/conversations',
        (server) => server.reply(
          200,
          apiOk([
            {
              'id': 9,
              'userId': 5,
              'title': 'Làm sao để gửi hàng qua tủ?',
              'messageCount': 4,
              'createdAt': '2026-09-20T01:00:00',
              'updatedAt': '2026-09-20T02:00:00',
            },
          ]),
        ),
      );

      final items = await service.conversations();

      expect(recorder.last.path, '/api/assistant/conversations');
      expect(items, hasLength(1));
      expect(items.single.id, 9);
      expect(items.single.title, 'Làm sao để gửi hàng qua tủ?');
      expect(items.single.messageCount, 4);
    });

    test('GET /api/assistant/conversations/{id} đọc tin nhắn', () async {
      adapter.onGet(
        '/api/assistant/conversations/9',
        (server) => server.reply(
          200,
          apiOk({
            'conversation': {
              'id': 9,
              'userId': 5,
              'title': 'Gửi hàng',
              'messageCount': 2,
              'createdAt': '2026-09-20T01:00:00',
              'updatedAt': '2026-09-20T01:00:05',
            },
            'messages': [
              {
                'id': 1,
                'role': 'USER',
                'content': 'Làm sao để gửi hàng qua tủ?',
                'refused': false,
                'sources': [],
                'topScore': null,
                'createdAt': '2026-09-20T01:00:00',
              },
              {
                'id': 2,
                'role': 'ASSISTANT',
                'content': 'Bạn chọn tủ…',
                'refused': false,
                'sources': [
                  {
                    'documentId': 3,
                    'documentTitle': 'Hướng dẫn gửi hàng',
                    'chunkId': 11,
                    'heading': 'Bước 1',
                    'citedText': 'Chọn tủ gần bạn nhất.',
                  },
                ],
                'topScore': 0.82,
                'createdAt': '2026-09-20T01:00:05',
              },
            ],
          }),
        ),
      );

      final detail = await service.conversation(9);

      expect(recorder.last.path, '/api/assistant/conversations/9');
      expect(detail.conversation.id, 9);
      expect(detail.messages, hasLength(2));
      expect(detail.messages.first.role, AssistantRole.user);
      expect(detail.messages.last.role, AssistantRole.assistant);
      expect(detail.messages.last.sources.single.chunkId, 11);
    });

    test('DELETE /api/assistant/conversations/{id}', () async {
      adapter.onDelete(
        '/api/assistant/conversations/9',
        (server) => server.reply(200, apiOk(null)),
      );

      await service.deleteConversation(9);

      expect(recorder.last.method, 'DELETE');
      expect(recorder.last.path, '/api/assistant/conversations/9');
    });
  });

  group('ánh xạ lỗi', () {
    Future<AssistantException> askError() async {
      try {
        await service.ask('Câu hỏi');
      } on AssistantException catch (e) {
        return e;
      }
      fail('ask() phải ném AssistantException');
    }

    test('429 ASSISTANT_RATE_LIMITED: giữ code và message máy chủ', () async {
      adapter.onPost(
        '/api/assistant/ask',
        (server) => server.reply(
          429,
          _apiErrorBody(
            'ASSISTANT_RATE_LIMITED',
            'Bạn đã hỏi 20 câu trong một giờ qua, vui lòng thử lại sau',
          ),
        ),
      );

      final e = await askError();

      expect(e.code, 'ASSISTANT_RATE_LIMITED');
      expect(e.statusCode, 429);
      expect(e.isRateLimited, isTrue);
      expect(
        e.message,
        'Bạn đã hỏi 20 câu trong một giờ qua, vui lòng thử lại sau',
      );
    });

    for (final (code, message) in [
      ('ASSISTANT_DISABLED', 'Trợ lý hỏi đáp đang tạm tắt'),
      (
        'ASSISTANT_NOT_CONFIGURED',
        'Trợ lý hỏi đáp chưa được cấu hình trên máy chủ',
      ),
      (
        'ASSISTANT_UNAVAILABLE',
        'Trợ lý đang bận hoặc gặp sự cố, vui lòng thử lại sau',
      ),
    ]) {
      test('503 $code: hiện message của máy chủ', () async {
        adapter.onPost(
          '/api/assistant/ask',
          (server) => server.reply(503, _apiErrorBody(code, message)),
        );

        final e = await askError();

        expect(e.code, code);
        expect(e.statusCode, 503);
        expect(e.message, message);
      });
    }

    test('404 NOT_FOUND (hội thoại người khác): tiếng Việt', () async {
      adapter.onPost(
        '/api/assistant/ask',
        (server) => server.reply(
          404,
          _apiErrorBody('NOT_FOUND', 'Conversation not found: 7'),
        ),
      );

      final e = await askError();

      expect(e.isNotFound, isTrue);
      expect(e.message, contains('Không tìm thấy cuộc hội thoại'));
    });

    test('503 gateway (không theo ApiResponse): theo mã HTTP', () async {
      adapter.onPost(
        '/api/assistant/ask',
        (server) => server.reply(503, {
          'status': 503,
          'error': 'Service Unavailable',
          'path': '/api/assistant/ask',
        }),
      );

      final e = await askError();

      expect(e.code, isNull);
      expect(
        e.message,
        'Trợ lý đang bận hoặc gặp sự cố, vui lòng thử lại sau.',
      );
    });

    test('hết thời gian chờ trả lời', () async {
      adapter.onPost(
        '/api/assistant/ask',
        (server) => server.throws(
          0,
          DioException(
            requestOptions: RequestOptions(path: '/api/assistant/ask'),
            type: DioExceptionType.receiveTimeout,
          ),
        ),
      );

      final e = await askError();

      expect(e.code, 'TIMEOUT');
      expect(e.message, 'Trợ lý phản hồi quá lâu, vui lòng thử lại.');
    });

    test('status() lỗi cũng được đổi thành AssistantException', () async {
      adapter.onGet(
        '/api/assistant/status',
        (server) => server.reply(500, {'message': 'boom'}),
      );

      await expectLater(
        service.status(),
        throwsA(
          isA<AssistantException>().having(
            (e) => e.message,
            'message',
            'Máy chủ gặp lỗi, vui lòng thử lại sau.',
          ),
        ),
      );
    });
  });

  test('AssistantStatus so sánh theo giá trị', () {
    expect(
      const AssistantStatus(enabled: true, configured: true),
      const AssistantStatus(enabled: true, configured: true),
    );
  });
}
