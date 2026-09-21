import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:smart_laundry_locker/shared/widgets/user_ui_kit.dart';

import '../../data/models/assistant_models.dart';
import 'assistant_sources.dart';

double _maxBubbleWidth(BuildContext context) =>
    MediaQuery.sizeOf(context).width * 0.8;

/// Câu hỏi của người dùng — bên phải.
class AssistantUserBubble extends StatelessWidget {
  const AssistantUserBubble({super.key, required this.message});

  final AssistantMessage message;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: _maxBubbleWidth(context)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: const BoxDecoration(
                color: AislBrand.navy,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(18),
                  topRight: Radius.circular(18),
                  bottomLeft: Radius.circular(18),
                  bottomRight: Radius.circular(4),
                ),
              ),
              child: Text(
                message.content,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14.5,
                  height: 1.4,
                ),
              ),
            ),
            if (message.failed)
              const Padding(
                padding: EdgeInsets.only(top: 4, right: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      LucideIcons.circleAlert,
                      size: 12,
                      color: Color(0xFFDC2626),
                    ),
                    SizedBox(width: 4),
                    Text(
                      'Chưa gửi được',
                      style: TextStyle(fontSize: 11, color: Color(0xFFDC2626)),
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

/// Câu trả lời của trợ lý — bên trái, kèm "Nguồn (n)". Câu bị từ chối
/// (tài liệu chưa đề cập) hiện như một ghi chú trung tính, không có nguồn.
class AssistantAnswerBubble extends StatelessWidget {
  const AssistantAnswerBubble({super.key, required this.message});

  final AssistantMessage message;

  @override
  Widget build(BuildContext context) {
    final refused = message.refused;
    final showSources = !refused && message.sources.isNotEmpty;
    final background = refused ? context.surfaceBg : context.cardBg;
    return _AssistantRow(
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
        decoration: BoxDecoration(
          color: background,
          border: Border.all(color: context.borderColor),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(4),
            topRight: Radius.circular(18),
            bottomLeft: Radius.circular(18),
            bottomRight: Radius.circular(18),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (refused) ...[
              Row(
                children: [
                  Icon(LucideIcons.info, size: 14, color: context.textMuted),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      'Chưa có trong tài liệu',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: context.textMuted,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
            ],
            MarkdownBody(
              data: message.content,
              styleSheet: _markdownStyle(context, muted: refused),
            ),
            if (showSources) ...[
              const SizedBox(height: 8),
              AssistantSourcesSection(sources: message.sources),
            ],
          ],
        ),
      ),
    );
  }

  static MarkdownStyleSheet _markdownStyle(
    BuildContext context, {
    required bool muted,
  }) {
    final color = muted ? context.textMuted : context.textPrimary;
    final body = TextStyle(fontSize: 14.5, height: 1.45, color: color);
    return MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
      p: body,
      listBullet: body,
      strong: body.copyWith(fontWeight: FontWeight.w700),
      em: body.copyWith(fontStyle: FontStyle.italic),
      h1: body.copyWith(fontSize: 17, fontWeight: FontWeight.w800),
      h2: body.copyWith(fontSize: 16, fontWeight: FontWeight.w800),
      h3: body.copyWith(fontSize: 15, fontWeight: FontWeight.w700),
      blockSpacing: 8,
    );
  }
}

/// "Đang tìm trong tài liệu…" khi chờ câu trả lời.
class AssistantTypingIndicator extends StatelessWidget {
  const AssistantTypingIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return _AssistantRow(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          color: context.cardBg,
          border: Border.all(color: context.borderColor),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AislBrand.blue,
              ),
            ),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                'Đang tìm trong tài liệu…',
                style: TextStyle(
                  fontSize: 13,
                  fontStyle: FontStyle.italic,
                  color: context.textMuted,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Lỗi của lần hỏi gần nhất, kèm nút "Thử lại".
class AssistantErrorCard extends StatelessWidget {
  const AssistantErrorCard({super.key, required this.message, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFFEA580C);
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 6, 10),
      decoration: BoxDecoration(
        color: context.isDark
            ? accent.withValues(alpha: 0.14)
            : const Color(0xFFFFF7ED),
        border: Border.all(color: accent.withValues(alpha: 0.35)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(LucideIcons.circleAlert, size: 18, color: accent),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: 13,
                height: 1.4,
                color: context.textPrimary,
              ),
            ),
          ),
          if (onRetry != null)
            TextButton.icon(
              onPressed: onRetry,
              style: TextButton.styleFrom(foregroundColor: accent),
              icon: const Icon(LucideIcons.refreshCw, size: 15),
              label: const Text('Thử lại'),
            ),
        ],
      ),
    );
  }
}

/// Hàng tin nhắn phía trợ lý: avatar + nội dung, chừa lề phải.
class _AssistantRow extends StatelessWidget {
  const _AssistantRow({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AssistantAvatar(),
        const SizedBox(width: 8),
        Flexible(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: _maxBubbleWidth(context)),
            child: child,
          ),
        ),
        const SizedBox(width: 24),
      ],
    );
  }
}

class AssistantAvatar extends StatelessWidget {
  const AssistantAvatar({super.key, this.size = 30});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: AislBrand.brandGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Icon(LucideIcons.bot, size: size * 0.55, color: Colors.white),
    );
  }
}
