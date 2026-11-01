import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:smart_laundry_locker/shared/widgets/user_ui_kit.dart';

import '../../data/models/assistant_models.dart';
import '../../../../shared/shared.dart';
import 'assistant_sources.dart';
import 'package:smart_laundry_locker/core/l10n/l10n.dart';

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
              Padding(
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
                      context.l10n.aiNotSent,
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
                      context.l10n.aiNotInDocs,
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

/// Ba chấm nhấp nhô lần lượt trong bong bóng trợ lý khi chờ câu trả lời (giống
/// "đang soạn tin" của ứng dụng chat). Đọc màn hình vẫn nghe "Trợ lý đang trả lời".
class AssistantTypingIndicator extends StatefulWidget {
  const AssistantTypingIndicator({super.key});

  static String get semanticsLabel => L10n.current.aiTyping;

  @override
  State<AssistantTypingIndicator> createState() =>
      _AssistantTypingIndicatorState();
}

class _AssistantTypingIndicatorState extends State<AssistantTypingIndicator>
    with SingleTickerProviderStateMixin {
  static const _period = Duration(milliseconds: 1200);
  static const _dotSize = 8.0;
  static const _lift = 6.0;

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: _period,
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Mỗi chấm nảy trong 40 % chu kỳ, chấm sau trễ 15 % so với chấm trước.
  double _offset(int index) {
    final t = (_controller.value - index * 0.15) % 1.0;
    if (t > 0.4) return 0;
    return -_lift * Curves.easeInOut.transform(1 - (t / 0.2 - 1).abs());
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    return _AssistantRow(
      child: Semantics(
        label: AssistantTypingIndicator.semanticsLabel,
        liveRegion: true,
        child: Container(
          key: const ValueKey('assistant-typing-dots'),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
          decoration: BoxDecoration(
            color: context.cardBg,
            border: Border.all(color: context.borderColor),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(4),
              topRight: Radius.circular(18),
              bottomLeft: Radius.circular(18),
              bottomRight: Radius.circular(18),
            ),
          ),
          child: ExcludeSemantics(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, _) => Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (var i = 0; i < 3; i++) ...[
                    if (i > 0) const SizedBox(width: 5),
                    Transform.translate(
                      offset: Offset(0, reduceMotion ? 0 : _offset(i)),
                      child: Container(
                        width: _dotSize,
                        height: _dotSize,
                        decoration: BoxDecoration(
                          color: AislBrand.blue.withValues(
                            alpha: reduceMotion
                                ? 0.6
                                : 0.45 + 0.55 * (-_offset(i) / _lift),
                          ),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
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
              label: Text(context.l10n.commonRetry),
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
    return SizedBox(
      width: size,
      height: size,
      child: const AppLottie(
        AppLottieAssets.chatbox,
        fit: BoxFit.contain,
      ),
    );
  }
}
