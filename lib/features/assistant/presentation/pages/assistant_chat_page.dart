import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:smart_laundry_locker/core/routing/app_router.dart';
import 'package:smart_laundry_locker/core/services/token_service.dart';
import 'package:smart_laundry_locker/shared/widgets/user_ui_kit.dart';

import '../../data/assistant_service.dart';
import '../../data/models/assistant_models.dart';
import '../providers/assistant_availability.dart';
import '../providers/assistant_chat_controller.dart';
import '../widgets/assistant_intro.dart';
import '../widgets/assistant_message_bubble.dart';

/// Màn "Trợ lý hỏi đáp" (mọi vai trò): hỏi bằng tiếng Việt, trợ lý trả lời từ
/// tài liệu chính thức của Lock.R kèm nguồn trích dẫn.
class AssistantChatPage extends StatefulWidget {
  const AssistantChatPage({
    super.key,
    this.service,
    this.availability,
    this.roles,
    this.initialConversationId,
  });

  final AssistantService? service;

  /// Mặc định [AssistantAvailability.instance].
  final AssistantAvailability? availability;

  /// Vai trò để chọn câu hỏi gợi ý; null ⇒ đọc từ JWT.
  final List<String>? roles;

  /// Mở sẵn một hội thoại cũ để hỏi tiếp.
  final int? initialConversationId;

  @override
  State<AssistantChatPage> createState() => _AssistantChatPageState();
}

class _AssistantChatPageState extends State<AssistantChatPage> {
  late final AssistantChatController _chat = AssistantChatController(
    service: widget.service ?? AssistantService(),
  );
  late final AssistantAvailability _availability =
      widget.availability ?? AssistantAvailability.instance;
  final TextEditingController _input = TextEditingController();
  final FocusNode _inputFocus = FocusNode();
  AssistantAudience _audience = AssistantAudience.customer;

  @override
  void initState() {
    super.initState();
    _availability.refresh(force: true);
    final roles = widget.roles;
    if (roles != null) {
      _audience = assistantAudienceForRoles(roles);
    } else {
      _loadAudience();
    }
    final initialId = widget.initialConversationId;
    if (initialId != null) _chat.openConversation(initialId);
  }

  Future<void> _loadAudience() async {
    final roles = await TokenService.getCurrentRoles();
    if (!mounted) return;
    setState(() => _audience = assistantAudienceForRoles(roles));
  }

  @override
  void dispose() {
    _chat.dispose();
    _input.dispose();
    _inputFocus.dispose();
    super.dispose();
  }

  Future<void> _send([String? example]) async {
    final question = (example ?? _input.text).trim();
    if (question.isEmpty || _chat.busy) return;
    if (example == null) _input.clear();
    await _chat.send(question);
  }

  void _startNew() {
    _chat.startNew();
    _inputFocus.requestFocus();
  }

  Future<void> _openHistory() async {
    final result = await context.push<AssistantHistoryResult>(
      AppRouter.assistantHistory,
    );
    if (!mounted || result == null) return;
    await _chat.applyHistoryResult(result);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.pageBg,
      body: Column(
        children: [
          BrandHeroHeader(
            eyebrow: 'LOCK.R • TRỢ LÝ',
            title: 'Trợ lý hỏi đáp',
            subtitle: 'Trả lời từ tài liệu chính thức, có trích nguồn',
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Tooltip(
                  message: 'Lịch sử hỏi đáp',
                  child: BrandCircleIconButton(
                    icon: LucideIcons.history,
                    onTap: _openHistory,
                  ),
                ),
                const SizedBox(width: 8),
                Tooltip(
                  message: 'Cuộc hội thoại mới',
                  child: BrandCircleIconButton(
                    icon: LucideIcons.squarePen,
                    onTap: _startNew,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListenableBuilder(
              listenable: Listenable.merge([_chat, _availability]),
              builder: (context, _) => Column(
                children: [
                  Expanded(child: _buildBody()),
                  _buildBottom(_availability.value),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Chưa biết trạng thái (lỗi mạng…) vẫn cho hỏi — máy chủ sẽ báo lỗi cụ thể.
  bool get _canAsk => _availability.value?.canAsk ?? true;

  Widget _buildBody() {
    if (_chat.loadingConversation) {
      return const Center(
        child: CircularProgressIndicator(color: AislBrand.navy),
      );
    }
    final loadError = _chat.loadError;
    if (loadError != null) {
      return _LoadErrorView(
        message: loadError,
        onRetry: _chat.reloadConversation,
        onNew: _startNew,
      );
    }
    if (_chat.isEmpty) {
      return AssistantIntro(
        audience: _audience,
        onExampleTap: _canAsk ? _send : null,
      );
    }

    final error = _chat.error;
    final entries = <Widget>[
      for (final message in _chat.messages)
        message.isUser
            ? AssistantUserBubble(message: message)
            : AssistantAnswerBubble(message: message),
      if (_chat.sending) const AssistantTypingIndicator(),
      if (error != null && !_chat.sending)
        AssistantErrorCard(
          message: error.message,
          onRetry: _chat.canRetry && _canAsk ? _chat.retry : null,
        ),
    ];
    // Danh sách đảo ngược: tin mới nhất nằm sát ô nhập và tự hiện khi thêm tin.
    return ListView.builder(
      reverse: true,
      padding: const EdgeInsets.fromLTRB(14, 16, 14, 12),
      itemCount: entries.length,
      itemBuilder: (context, index) => Padding(
        padding: const EdgeInsets.only(top: 12),
        child: entries[entries.length - 1 - index],
      ),
    );
  }

  Widget _buildBottom(AssistantStatus? status) {
    if (status != null && !status.enabled) {
      return const _StatusNotice(
        icon: LucideIcons.powerOff,
        title: 'Trợ lý đang tạm tắt',
        body: 'Tính năng hỏi đáp đang được tạm tắt. Bạn vui lòng quay lại sau.',
      );
    }
    if (status != null && !status.configured) {
      return const _StatusNotice(
        icon: LucideIcons.construction,
        title: 'Trợ lý chưa sẵn sàng',
        body:
            'Trợ lý hỏi đáp chưa được cấu hình xong. Bạn vui lòng quay lại sau '
            'hoặc liên hệ bộ phận hỗ trợ Lock.R.',
      );
    }
    return _Composer(
      controller: _input,
      focusNode: _inputFocus,
      enabled: !_chat.busy,
      sending: _chat.sending,
      onSend: _send,
    );
  }
}

class _Composer extends StatelessWidget {
  const _Composer({
    required this.controller,
    required this.focusNode,
    required this.enabled,
    required this.sending,
    required this.onSend,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool enabled;
  final bool sending;
  final VoidCallback onSend;

  /// Chỉ hiện bộ đếm khi gần chạm giới hạn.
  static const _counterFrom = AssistantService.maxQuestionLength - 200;

  static Widget? _buildCounter(
    BuildContext context, {
    required int currentLength,
    required bool isFocused,
    required int? maxLength,
  }) {
    if (currentLength < _counterFrom) return null;
    return Text(
      '$currentLength/$maxLength',
      style: const TextStyle(fontSize: 11),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.cardBg,
        border: Border(top: BorderSide(color: context.borderColor)),
      ),
      padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
      child: SafeArea(
        top: false,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: TextField(
                key: const Key('assistant-input'),
                controller: controller,
                focusNode: focusNode,
                enabled: enabled,
                minLines: 1,
                maxLines: 5,
                maxLength: AssistantService.maxQuestionLength,
                maxLengthEnforcement: MaxLengthEnforcement.enforced,
                keyboardType: TextInputType.multiline,
                textCapitalization: TextCapitalization.sentences,
                style: TextStyle(fontSize: 14.5, color: context.textPrimary),
                buildCounter: _buildCounter,
                decoration: InputDecoration(
                  hintText: sending
                      ? 'Đang chờ trợ lý trả lời…'
                      : 'Nhập câu hỏi của bạn…',
                  hintStyle: TextStyle(color: context.textMuted),
                  isDense: true,
                  filled: true,
                  fillColor: context.surfaceBg,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 11,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(22),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            ValueListenableBuilder<TextEditingValue>(
              valueListenable: controller,
              builder: (context, value, _) {
                final canSend = enabled && value.text.trim().isNotEmpty;
                return IconButton.filled(
                  key: const Key('assistant-send'),
                  tooltip: 'Gửi câu hỏi',
                  onPressed: canSend ? onSend : null,
                  style: IconButton.styleFrom(
                    backgroundColor: AislBrand.navy,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: context.surfaceBg,
                    disabledForegroundColor: context.textMuted,
                  ),
                  icon: const Icon(LucideIcons.sendHorizontal, size: 20),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// Thay ô nhập khi trợ lý đang tắt hoặc chưa cấu hình.
class _StatusNotice extends StatelessWidget {
  const _StatusNotice({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: context.cardBg,
        border: Border(top: BorderSide(color: context.borderColor)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: SafeArea(
        top: false,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 20, color: context.textMuted),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: context.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    body,
                    style: TextStyle(
                      fontSize: 12.5,
                      height: 1.4,
                      color: context.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoadErrorView extends StatelessWidget {
  const _LoadErrorView({
    required this.message,
    required this.onRetry,
    required this.onNew,
  });

  final String message;
  final VoidCallback onRetry;
  final VoidCallback onNew;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(LucideIcons.circleAlert, size: 36, color: context.textMuted),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: context.textPrimary),
            ),
            const SizedBox(height: 16),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.icon(
                  onPressed: onRetry,
                  style: FilledButton.styleFrom(
                    backgroundColor: AislBrand.navy,
                  ),
                  icon: const Icon(LucideIcons.refreshCw, size: 16),
                  label: const Text('Thử lại'),
                ),
                OutlinedButton(
                  onPressed: onNew,
                  child: const Text('Cuộc hội thoại mới'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
