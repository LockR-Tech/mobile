/// Model của trợ lý hỏi đáp (assistant-service, `/api/assistant/**`).
/// Class Dart thuần, không cần build_runner.
library;

/// `GET /api/assistant/status`: `enabled` = admin bật tính năng,
/// `configured` = máy chủ đã có khoá mô hình để trả lời.
class AssistantStatus {
  const AssistantStatus({required this.enabled, required this.configured});

  factory AssistantStatus.fromJson(Map<String, dynamic> json) =>
      AssistantStatus(
        enabled: json['enabled'] == true,
        configured: json['configured'] == true,
      );

  final bool enabled;
  final bool configured;

  /// Được gửi câu hỏi: đang bật và đã cấu hình.
  bool get canAsk => enabled && configured;

  @override
  bool operator ==(Object other) =>
      other is AssistantStatus &&
      other.enabled == enabled &&
      other.configured == configured;

  @override
  int get hashCode => Object.hash(enabled, configured);
}

/// Đoạn tài liệu làm căn cứ cho câu trả lời; [citedText] là câu trích nguyên văn.
class AssistantSource {
  const AssistantSource({
    required this.documentId,
    required this.documentTitle,
    required this.chunkId,
    this.heading,
    required this.citedText,
  });

  factory AssistantSource.fromJson(Map<String, dynamic> json) =>
      AssistantSource(
        documentId: _int(json['documentId']) ?? 0,
        documentTitle: _text(json['documentTitle']) ?? 'Tài liệu',
        chunkId: _int(json['chunkId']) ?? 0,
        heading: _text(json['heading']),
        citedText: _text(json['citedText']) ?? '',
      );

  final int documentId;
  final String documentTitle;
  final int chunkId;
  final String? heading;
  final String citedText;
}

/// `POST /api/assistant/ask`.
class AssistantAnswer {
  const AssistantAnswer({
    required this.conversationId,
    required this.messageId,
    required this.answer,
    required this.refused,
    required this.sources,
    this.createdAt,
  });

  factory AssistantAnswer.fromJson(Map<String, dynamic> json) =>
      AssistantAnswer(
        conversationId: _int(json['conversationId']) ?? 0,
        messageId: _int(json['messageId']) ?? 0,
        answer: json['answer']?.toString() ?? '',
        refused: json['refused'] == true,
        sources: _sources(json['sources']),
        createdAt: parseServerTime(json['createdAt']),
      );

  final int conversationId;
  final int messageId;
  final String answer;

  /// Tài liệu chưa đề cập câu hỏi — [answer] đã giải thích, không có nguồn.
  final bool refused;
  final List<AssistantSource> sources;
  final DateTime? createdAt;
}

/// Một dòng trong `GET /api/assistant/conversations`.
class AssistantConversation {
  const AssistantConversation({
    required this.id,
    required this.title,
    required this.messageCount,
    this.createdAt,
    this.updatedAt,
  });

  factory AssistantConversation.fromJson(Map<String, dynamic> json) =>
      AssistantConversation(
        id: _int(json['id']) ?? 0,
        title: _text(json['title']) ?? 'Cuộc hội thoại',
        messageCount: _int(json['messageCount']) ?? 0,
        createdAt: parseServerTime(json['createdAt']),
        updatedAt: parseServerTime(json['updatedAt']),
      );

  final int id;
  final String title;
  final int messageCount;
  final DateTime? createdAt;
  final DateTime? updatedAt;
}

enum AssistantRole { user, assistant }

/// Tin nhắn trong khung chat — từ lịch sử (`messages[]`), từ câu trả lời mới,
/// hoặc câu hỏi vừa gõ (chưa có [id]).
class AssistantMessage {
  const AssistantMessage({
    this.id,
    required this.role,
    required this.content,
    this.refused = false,
    this.sources = const [],
    this.createdAt,
    this.failed = false,
  });

  factory AssistantMessage.question(String text) => AssistantMessage(
    role: AssistantRole.user,
    content: text,
    createdAt: DateTime.now(),
  );

  factory AssistantMessage.fromAnswer(AssistantAnswer answer) =>
      AssistantMessage(
        id: answer.messageId,
        role: AssistantRole.assistant,
        content: answer.answer,
        refused: answer.refused,
        sources: answer.sources,
        createdAt: answer.createdAt,
      );

  factory AssistantMessage.fromJson(Map<String, dynamic> json) =>
      AssistantMessage(
        id: _int(json['id']),
        role: '${json['role']}'.toUpperCase() == 'USER'
            ? AssistantRole.user
            : AssistantRole.assistant,
        content: json['content']?.toString() ?? '',
        refused: json['refused'] == true,
        sources: _sources(json['sources']),
        createdAt: parseServerTime(json['createdAt']),
      );

  final int? id;
  final AssistantRole role;
  final String content;
  final bool refused;
  final List<AssistantSource> sources;
  final DateTime? createdAt;

  /// Câu hỏi chưa gửi được (lỗi mạng, giới hạn lượt hỏi…).
  final bool failed;

  bool get isUser => role == AssistantRole.user;

  AssistantMessage copyWith({bool? failed}) => AssistantMessage(
    id: id,
    role: role,
    content: content,
    refused: refused,
    sources: sources,
    createdAt: createdAt,
    failed: failed ?? this.failed,
  );
}

/// `GET /api/assistant/conversations/{id}`.
class AssistantConversationDetail {
  const AssistantConversationDetail({
    required this.conversation,
    required this.messages,
  });

  factory AssistantConversationDetail.fromJson(Map<String, dynamic> json) {
    final conversation = json['conversation'];
    final messages = json['messages'];
    return AssistantConversationDetail(
      conversation: AssistantConversation.fromJson(
        conversation is Map
            ? Map<String, dynamic>.from(conversation)
            : const <String, dynamic>{},
      ),
      messages: messages is List
          ? messages
                .whereType<Map>()
                .map(
                  (m) =>
                      AssistantMessage.fromJson(Map<String, dynamic>.from(m)),
                )
                .toList(growable: false)
          : const [],
    );
  }

  final AssistantConversation conversation;
  final List<AssistantMessage> messages;
}

/// Thời gian `LocalDateTime` của backend (UTC, không kèm offset) → giờ máy.
DateTime? parseServerTime(dynamic value) {
  if (value == null) return null;
  var s = '$value'.trim();
  if (s.isEmpty) return null;
  if (s.contains('T')) {
    final time = s.split('T').last;
    final hasOffset =
        time.endsWith('Z') || time.contains('+') || time.contains('-');
    if (!hasOffset) s = '${s}Z';
  }
  return DateTime.tryParse(s)?.toLocal();
}

int? _int(dynamic value) =>
    value is num ? value.toInt() : int.tryParse('${value ?? ''}');

String? _text(dynamic value) {
  final s = value?.toString().trim();
  return (s == null || s.isEmpty) ? null : s;
}

List<AssistantSource> _sources(dynamic value) => value is List
    ? value
          .whereType<Map>()
          .map((s) => AssistantSource.fromJson(Map<String, dynamic>.from(s)))
          .toList(growable: false)
    : const [];
