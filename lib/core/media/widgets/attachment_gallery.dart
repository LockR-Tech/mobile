import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:smart_laundry_locker/core/media/report_attachment.dart';

const _defaultAccent = Color(0xFF1E5A8A);
const _mutedText = Color(0xFF64748B);

String _fmtDateTime(DateTime d) {
  String two(int n) => n.toString().padLeft(2, '0');
  return '${two(d.hour)}:${two(d.minute)} ${two(d.day)}/${two(d.month)}/${d.year}';
}

/// Dải thumbnail ngang (dùng `thumbnailUrl`), chạm ⇒ xem lớn bằng `url`.
class AttachmentStrip extends StatelessWidget {
  const AttachmentStrip({
    super.key,
    required this.attachments,
    this.size = 72,
    this.borderColor = const Color(0xFFE2E8F0),
    this.viewerTitle,
  });

  final List<ReportAttachment> attachments;
  final double size;
  final Color borderColor;
  final String? viewerTitle;

  @override
  Widget build(BuildContext context) {
    if (attachments.isEmpty) return const SizedBox.shrink();
    // SingleChildScrollView + Row: dùng được cả trong AlertDialog (intrinsic).
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        spacing: 8,
        children: [
          for (var index = 0; index < attachments.length; index++)
            _thumb(context, index),
        ],
      ),
    );
  }

  Widget _thumb(BuildContext context, int index) {
    final a = attachments[index];
    final time = a.capturedAt ?? a.createdAt;
    return GestureDetector(
      onTap: () => showAttachmentViewer(
        context,
        attachments,
        initialIndex: index,
        title: viewerTitle,
      ),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: borderColor),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(9),
          child: Stack(
            fit: StackFit.expand,
            children: [
              CachedNetworkImage(
                imageUrl: a.previewUrl,
                fit: BoxFit.cover,
                memCacheWidth: (size * 3).round(),
                placeholder: (_, _) => const Center(
                  child: SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
                errorWidget: (_, _, _) => const Center(
                  child: Icon(
                    Icons.broken_image_outlined,
                    size: 22,
                    color: _mutedText,
                  ),
                ),
              ),
              if (time != null)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 1.5),
                    color: Colors.black.withValues(alpha: 0.75),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.access_time,
                          size: 8,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 2),
                        Flexible(
                          child: Text(
                            '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')} ${time.day.toString().padLeft(2, '0')}/${time.month.toString().padLeft(2, '0')}',
                            style: const TextStyle(
                              fontSize: 7.5,
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Ảnh phiếu nhóm theo stage, mỗi nhóm một tiêu đề + [AttachmentStrip].
class AttachmentStageGallery extends StatelessWidget {
  const AttachmentStageGallery({
    super.key,
    required this.attachments,
    this.stages = ReportStage.ordered,
    this.labels = const {},
    this.accentColor = _defaultAccent,
    this.thumbSize = 64,
  });

  final List<ReportAttachment> attachments;

  /// Chỉ hiện các stage này, theo thứ tự này.
  final List<String> stages;

  /// Ghi đè nhãn mặc định của [ReportStage.label].
  final Map<String, String> labels;
  final Color accentColor;
  final double thumbSize;

  @override
  Widget build(BuildContext context) {
    final groups = ReportAttachment.groupByStage(attachments);
    final visible = [
      for (final stage in stages)
        if (groups[stage] != null) MapEntry(stage, groups[stage]!),
    ];
    if (visible.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final entry in visible) ...[
          Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 6),
            child: Row(
              children: [
                Icon(
                  _stageIcon(entry.key),
                  size: 14,
                  color: _stageColor(entry.key, accentColor),
                ),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    '${labels[entry.key] ?? ReportStage.label(entry.key)} '
                    '(${entry.value.length})',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: _stageColor(entry.key, accentColor),
                    ),
                  ),
                ),
              ],
            ),
          ),
          AttachmentStrip(
            attachments: entry.value,
            size: thumbSize,
            viewerTitle: labels[entry.key] ?? ReportStage.label(entry.key),
          ),
        ],
      ],
    );
  }

  static IconData _stageIcon(String stage) => switch (stage) {
    ReportStage.report => Icons.report_outlined,
    ReportStage.inspection => Icons.fact_check_outlined,
    ReportStage.progress => Icons.build_outlined,
    ReportStage.resolution => Icons.verified_outlined,
    _ => Icons.photo_library_outlined,
  };

  static Color _stageColor(String stage, Color accent) => switch (stage) {
    ReportStage.report => const Color(0xFFE11D48),
    ReportStage.inspection => const Color(0xFFD97706),
    ReportStage.resolution => const Color(0xFF16A34A),
    _ => accent,
  };
}

/// Xem ảnh toàn màn hình (vuốt qua lại, phóng to), kèm stage/chú thích/thời gian.
Future<void> showAttachmentViewer(
  BuildContext context,
  List<ReportAttachment> attachments, {
  int initialIndex = 0,
  String? title,
}) {
  if (attachments.isEmpty) return Future.value();
  return showDialog<void>(
    context: context,
    useRootNavigator: true,
    builder: (_) => _AttachmentViewer(
      attachments: attachments,
      initialIndex: initialIndex.clamp(0, attachments.length - 1),
      title: title,
    ),
  );
}

class _AttachmentViewer extends StatefulWidget {
  const _AttachmentViewer({
    required this.attachments,
    required this.initialIndex,
    this.title,
  });

  final List<ReportAttachment> attachments;
  final int initialIndex;
  final String? title;

  @override
  State<_AttachmentViewer> createState() => _AttachmentViewerState();
}

class _AttachmentViewerState extends State<_AttachmentViewer> {
  late final PageController _pages = PageController(
    initialPage: widget.initialIndex,
  );
  late int _index = widget.initialIndex;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final current = widget.attachments[_index];
    final time = current.capturedAt ?? current.createdAt;
    final details = [
      if (current.caption != null && current.caption!.trim().isNotEmpty)
        current.caption!.trim(),
      if (time != null)
        '${current.capturedAt != null ? 'Chụp lúc' : 'Tải lên lúc'} ${_fmtDateTime(time)}',
      if (current.hasLocation)
        'Vị trí ${current.latitude!.toStringAsFixed(5)}, ${current.longitude!.toStringAsFixed(5)}',
    ];

    return Dialog.fullscreen(
      backgroundColor: Colors.black,
      child: SafeArea(
        child: Stack(
          children: [
            PageView.builder(
              controller: _pages,
              itemCount: widget.attachments.length,
              onPageChanged: (i) => setState(() => _index = i),
              itemBuilder: (_, i) => InteractiveViewer(
                maxScale: 5,
                child: Center(
                  child: CachedNetworkImage(
                    imageUrl: widget.attachments[i].url,
                    fit: BoxFit.contain,
                    placeholder: (_, _) => const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    ),
                    errorWidget: (_, _, _) => const Center(
                      child: Text(
                        'Không tải được ảnh',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 8, 4, 8),
                color: Colors.black54,
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${widget.title ?? ReportStage.label(current.stage)}'
                        '${widget.attachments.length > 1 ? ' · ${_index + 1}/${widget.attachments.length}' : ''}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      tooltip: 'Đóng',
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
            ),
            if (details.isNotEmpty)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
                  color: Colors.black54,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (final line in details)
                        Text(
                          line,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12.5,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
