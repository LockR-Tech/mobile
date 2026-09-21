import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_laundry_locker/features/assistant/data/assistant_service.dart';
import 'package:smart_laundry_locker/features/assistant/data/models/assistant_models.dart';
import 'package:smart_laundry_locker/features/assistant/presentation/providers/assistant_availability.dart';

import '../../helpers/test_helpers.dart';

/// Một lần gọi `ask()` mà [FakeAssistantService] ghi lại.
class AskCall {
  AskCall(this.question, this.conversationId);

  final String question;
  final int? conversationId;
}

/// Service giả cho test màn hình: trả lời theo hàng đợi [answers]
/// (AssistantAnswer, AssistantException hoặc Completer để giữ trạng thái chờ).
class FakeAssistantService extends AssistantService {
  FakeAssistantService({
    this.currentStatus = const AssistantStatus(enabled: true, configured: true),
  }) : super(dio: createMockDio().dio);

  AssistantStatus currentStatus;
  AssistantException? statusError;
  final List<Object> answers = [];
  final List<AskCall> askCalls = [];
  List<AssistantConversation> conversationList = [];
  final Map<int, AssistantConversationDetail> details = {};
  final List<int> deletedIds = [];
  AssistantException? deleteError;

  @override
  Future<AssistantStatus> status() async {
    final error = statusError;
    if (error != null) throw error;
    return currentStatus;
  }

  @override
  Future<AssistantAnswer> ask(String question, {int? conversationId}) async {
    askCalls.add(AskCall(question, conversationId));
    if (answers.isEmpty) throw StateError('Không còn câu trả lời giả');
    final next = answers.removeAt(0);
    if (next is Completer<AssistantAnswer>) return next.future;
    if (next is AssistantException) throw next;
    return next as AssistantAnswer;
  }

  @override
  Future<List<AssistantConversation>> conversations() async =>
      List.of(conversationList);

  @override
  Future<AssistantConversationDetail> conversation(int id) async {
    final detail = details[id];
    if (detail == null) {
      throw const AssistantException(
        'Không tìm thấy cuộc hội thoại này, có thể nó đã bị xoá.',
        code: 'NOT_FOUND',
        statusCode: 404,
      );
    }
    return detail;
  }

  @override
  Future<void> deleteConversation(int id) async {
    final error = deleteError;
    if (error != null) throw error;
    deletedIds.add(id);
    conversationList = conversationList.where((c) => c.id != id).toList();
  }
}

AssistantAnswer fakeAnswer({
  int conversationId = 7,
  String answer = 'Bạn chọn tủ gần nhất, chọn ô trống rồi bấm Gửi hàng.',
  bool refused = false,
  List<AssistantSource>? sources,
}) => AssistantAnswer(
  conversationId: conversationId,
  messageId: 100,
  answer: answer,
  refused: refused,
  sources:
      sources ??
      const [
        AssistantSource(
          documentId: 3,
          documentTitle: 'Hướng dẫn gửi hàng',
          chunkId: 11,
          heading: 'Bước 1: Chọn tủ',
          citedText: 'Mở ứng dụng và chọn tủ gần bạn nhất trên bản đồ.',
        ),
        AssistantSource(
          documentId: 4,
          documentTitle: 'Câu hỏi thường gặp',
          chunkId: 12,
          citedText: 'Bạn có thể thanh toán bằng ví Lock.R hoặc VNPay.',
        ),
      ],
);

/// Màn hình cỡ điện thoại (400 × 900 logic) cho test widget.
void usePhoneScreen(WidgetTester tester) {
  tester.view.physicalSize = const Size(1200, 2700);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.reset);
}

/// Trạng thái trợ lý đã biết sẵn, không gọi mạng, coi như đã đăng nhập.
AssistantAvailability fakeAvailability(FakeAssistantService service) =>
    AssistantAvailability(
      serviceFactory: () => service,
      isSignedIn: () => true,
    );
