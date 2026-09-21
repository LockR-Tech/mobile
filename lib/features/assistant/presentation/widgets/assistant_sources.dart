import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:smart_laundry_locker/shared/widgets/user_ui_kit.dart';

import '../../data/models/assistant_models.dart';

/// Mục "Nguồn (n)" thu gọn dưới câu trả lời; mở ra thấy tên tài liệu, mục và
/// câu được trích. Chạm một nguồn để xem nguyên văn trong bottom sheet.
class AssistantSourcesSection extends StatefulWidget {
  const AssistantSourcesSection({super.key, required this.sources});

  final List<AssistantSource> sources;

  @override
  State<AssistantSourcesSection> createState() =>
      _AssistantSourcesSectionState();
}

class _AssistantSourcesSectionState extends State<AssistantSourcesSection> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final accent = context.isDark ? AislBrand.cyan : AislBrand.blue;
    return Container(
      padding: const EdgeInsets.only(top: 4),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: context.borderColor)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  Icon(LucideIcons.bookOpenText, size: 15, color: accent),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Nguồn (${widget.sources.length})',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: accent,
                      ),
                    ),
                  ),
                  Icon(
                    _expanded ? LucideIcons.chevronUp : LucideIcons.chevronDown,
                    size: 16,
                    color: accent,
                  ),
                ],
              ),
            ),
          ),
          if (_expanded)
            for (var i = 0; i < widget.sources.length; i++)
              _SourceTile(index: i + 1, source: widget.sources[i]),
        ],
      ),
    );
  }
}

class _SourceTile extends StatelessWidget {
  const _SourceTile({required this.index, required this.source});

  final int index;
  final AssistantSource source;

  @override
  Widget build(BuildContext context) {
    final heading = source.heading;
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Material(
        color: context.surfaceBg,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () => showAssistantSourceSheet(context, source),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 9),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$index. ${source.documentTitle}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: context.textPrimary,
                  ),
                ),
                if (heading != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    heading,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 11.5, color: context.textMuted),
                  ),
                ],
                if (source.citedText.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    '“${source.citedText}”',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.35,
                      fontStyle: FontStyle.italic,
                      color: context.textMuted,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Bottom sheet hiện nguyên văn đoạn trích của một nguồn.
Future<void> showAssistantSourceSheet(
  BuildContext context,
  AssistantSource source,
) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: context.cardBg,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (sheetContext) {
      final heading = source.heading;
      final cited = source.citedText;
      return SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(sheetContext).height * 0.8,
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'TRÍCH DẪN NGUỒN',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                    color: sheetContext.textMuted,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  source.documentTitle,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: sheetContext.textPrimary,
                  ),
                ),
                if (heading != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    heading,
                    style: TextStyle(
                      fontSize: 13,
                      color: sheetContext.textMuted,
                    ),
                  ),
                ],
                const SizedBox(height: 14),
                // Viền trái không đều ⇒ bo góc bằng ClipRRect (BoxDecoration
                // không cho borderRadius đi cùng border không đồng nhất).
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                    decoration: BoxDecoration(
                      color: sheetContext.surfaceBg,
                      border: const Border(
                        left: BorderSide(color: AislBrand.blue, width: 3),
                      ),
                    ),
                    child: SelectableText(
                      cited.isEmpty ? 'Không có đoạn trích.' : cited,
                      style: TextStyle(
                        fontSize: 14.5,
                        height: 1.5,
                        color: sheetContext.textPrimary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Trích nguyên văn từ tài liệu chính thức của Lock.R.',
                  style: TextStyle(fontSize: 12, color: sheetContext.textMuted),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}
