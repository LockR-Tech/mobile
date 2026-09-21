import 'package:flutter/foundation.dart';

import '../../data/assistant_service.dart';
import '../../data/models/assistant_models.dart';

/// Kết quả trả về từ màn Lịch sử: hội thoại cần mở và các hội thoại đã xoá.
class AssistantHistoryResult {
  const AssistantHistoryResult({
    this.openConversationId,
    this.deletedIds = const {},
  });

  final int? openConversationId;
  final Set<int> deletedIds;
}

/// Trạng thái một phiên chat với trợ lý: danh sách tin nhắn, hội thoại đang
/// mở (`conversationId` lấy từ câu trả lời đầu tiên), đang chờ trả lời, lỗi
/// gần nhất để thử lại.
class AssistantChatController extends ChangeNotifier {
  AssistantChatController({required AssistantService service})
    : _service = service;

  final AssistantService _service;

  List<AssistantMessage> _messages = const [];
  int? _conversationId;
  bool _sending = false;
  bool _loadingConversation = false;
  AssistantException? _error;
  String? _failedQuestion;
  int? _loadFailedId;
  String? _loadError;

  /// Tăng khi đổi/mở hội thoại để bỏ qua câu trả lời về muộn của phiên cũ.
  int _epoch = 0;
  bool _disposed = false;

  List<AssistantMessage> get messages => _messages;
  int? get conversationId => _conversationId;
  bool get sending => _sending;
  bool get loadingConversation => _loadingConversation;

  /// Lỗi của lần hỏi gần nhất (hiện kèm nút "Thử lại").
  AssistantException? get error => _error;
  bool get canRetry => _failedQuestion != null && !_sending;

  /// Lỗi khi tải một hội thoại cũ.
  String? get loadError => _loadError;

  bool get isEmpty =>
      _messages.isEmpty &&
      !_sending &&
      !_loadingConversation &&
      _loadError == null;

  /// Đang bận (chờ trả lời / tải hội thoại) hoặc hội thoại tải lỗi ⇒ khoá ô nhập.
  bool get busy => _sending || _loadingConversation || _loadError != null;

  Future<void> send(String raw) async {
    final question = raw.trim();
    if (question.isEmpty ||
        question.length > AssistantService.maxQuestionLength ||
        busy) {
      return;
    }
    _error = null;
    _failedQuestion = null;
    _messages = [..._messages, AssistantMessage.question(question)];
    await _ask(question);
  }

  Future<void> retry() async {
    final question = _failedQuestion;
    if (question == null || _sending) return;
    _error = null;
    _failedQuestion = null;
    _setLastQuestionFailed(false);
    await _ask(question);
  }

  Future<void> _ask(String question) async {
    final epoch = _epoch;
    _sending = true;
    _notify();
    try {
      final answer = await _service.ask(
        question,
        conversationId: _conversationId,
      );
      if (epoch != _epoch) return;
      _conversationId = answer.conversationId;
      _messages = [..._messages, AssistantMessage.fromAnswer(answer)];
    } on AssistantException catch (e) {
      if (epoch != _epoch) return;
      // Hội thoại đã bị xoá ở nơi khác ⇒ gửi lại sẽ mở hội thoại mới.
      if (e.isNotFound) _conversationId = null;
      _error = e;
      _failedQuestion = question;
      _setLastQuestionFailed(true);
    } finally {
      if (epoch == _epoch) {
        _sending = false;
        _notify();
      }
    }
  }

  void _setLastQuestionFailed(bool failed) {
    final index = _messages.lastIndexWhere((m) => m.isUser);
    if (index < 0) return;
    _messages = [
      for (var i = 0; i < _messages.length; i++)
        i == index ? _messages[i].copyWith(failed: failed) : _messages[i],
    ];
  }

  /// Mở một hội thoại cũ (từ màn Lịch sử) để xem và hỏi tiếp.
  Future<void> openConversation(int id) async {
    final epoch = _reset();
    _conversationId = id;
    _loadingConversation = true;
    _notify();
    try {
      final detail = await _service.conversation(id);
      if (epoch != _epoch) return;
      _conversationId = detail.conversation.id == 0
          ? id
          : detail.conversation.id;
      _messages = detail.messages;
    } on AssistantException catch (e) {
      if (epoch != _epoch) return;
      _conversationId = null;
      _loadFailedId = id;
      _loadError = e.message;
    } finally {
      if (epoch == _epoch) {
        _loadingConversation = false;
        _notify();
      }
    }
  }

  /// Tải lại hội thoại vừa tải lỗi.
  Future<void> reloadConversation() async {
    final id = _loadFailedId;
    if (id != null) await openConversation(id);
  }

  /// Bắt đầu hội thoại mới (câu hỏi kế tiếp gửi không kèm `conversationId`).
  void startNew() {
    _reset();
    _notify();
  }

  /// Áp kết quả từ màn Lịch sử.
  Future<void> applyHistoryResult(AssistantHistoryResult result) async {
    final open = result.openConversationId;
    if (open != null) {
      await openConversation(open);
    } else if (_conversationId != null &&
        result.deletedIds.contains(_conversationId)) {
      startNew();
    }
  }

  int _reset() {
    _epoch++;
    _messages = const [];
    _conversationId = null;
    _sending = false;
    _loadingConversation = false;
    _error = null;
    _failedQuestion = null;
    _loadError = null;
    _loadFailedId = null;
    return _epoch;
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _epoch++;
    super.dispose();
  }
}
