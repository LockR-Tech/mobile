import 'package:flutter/material.dart';
import 'package:smart_laundry_locker/core/l10n/l10n.dart';

import '../data/onboarding_repository.dart';
import '../domain/tour_engine.dart';
import '../domain/tour_models.dart';
import 'onboarding_dialogs.dart';

/// Trang Hướng dẫn sử dụng (HDSD) trong app — dựng từ CÙNG nguồn với hướng dẫn trên màn hình (F3-G13):
/// mỗi nhóm một câu tóm tắt, ảnh chụp thật có khoanh đỏ + số, mỗi số một dòng giải thích.
class GuideManualPage extends StatefulWidget {
  const GuideManualPage({
    super.key,
    required this.groups,
    required this.text,
    required this.repository,
    this.seen = const {},
    this.focusGroup,
    this.onRun,
    this.showImages = true,
  });

  final List<TourGroup> groups;
  final TourText text;
  final OnboardingRepository repository;
  final Map<String, int> seen;

  /// Cuộn tới nhóm này khi mở (từ nút "Xem HDSD" của một nhóm).
  final String? focusGroup;

  /// "Xem trên màn hình": đóng trang rồi chạy hướng dẫn của nhóm (chỉ nhóm có bước trên app).
  final void Function(TourGroup group)? onRun;

  /// Tắt trong widget test (ảnh tải từ mạng).
  final bool showImages;

  @override
  State<GuideManualPage> createState() => _GuideManualPageState();
}

class _GuideManualPageState extends State<GuideManualPage> {
  final Map<String, GlobalKey> _keys = {};
  final Map<String, Future<List<ManualMark>?>> _marks = {};

  @override
  void initState() {
    super.initState();
    for (final g in widget.groups) {
      _keys[g.id] = GlobalKey();
      _marks[g.id] = widget.repository.loadManualMarks(g.id);
    }
    final focus = widget.focusGroup;
    if (focus != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final ctx = _keys[focus]?.currentContext;
        if (ctx != null) Scrollable.ensureVisible(ctx, duration: const Duration(milliseconds: 300));
      });
    }
  }

  String _roleLabel(String role) {
    final l10n = context.l10n;
    return switch (role) {
      'ADMIN' => l10n.tourRoleAdmin,
      'LOCKER_TECHNICIAN' => l10n.tourRoleLockerTech,
      'DRONE_TECHNICIAN' => l10n.tourRoleDroneTech,
      _ => l10n.tourRoleCustomer,
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final sections = [
      for (final role in tourRoles) (role, widget.groups.where((g) => g.roles.first == role).toList()),
    ].where((s) => s.$2.isNotEmpty).toList();
    return Scaffold(
      key: const ValueKey('tour-manual'),
      appBar: AppBar(title: Text(l10n.tourManualTitle)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.tourManualSubtitle, style: theme.textTheme.bodySmall),
            for (final (role, groups) in sections) ...[
              if (sections.length > 1)
                Padding(
                  padding: const EdgeInsets.only(top: 20, bottom: 4),
                  child: Text(
                    _roleLabel(role).toUpperCase(),
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              for (final g in groups)
                _GroupManual(
                  key: _keys[g.id],
                  group: g,
                  text: widget.text,
                  status: groupStatus(g, widget.seen),
                  marks: _marks[g.id]!,
                  showImage: widget.showImages,
                  onRun: widget.onRun != null && g.stepsFor('mobile').isNotEmpty
                      ? () {
                          Navigator.of(context).pop();
                          widget.onRun!(g);
                        }
                      : null,
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _GroupManual extends StatelessWidget {
  const _GroupManual({
    super.key,
    required this.group,
    required this.text,
    required this.status,
    required this.marks,
    required this.showImage,
    this.onRun,
  });

  final TourGroup group;
  final TourText text;
  final String status;
  final Future<List<ManualMark>?> marks;
  final bool showImage;
  final VoidCallback? onRun;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final onWeb = group.steps.any((s) => s.platforms.contains('web'));
    final platform = onWeb ? 'web' : 'mobile';
    return Card(
      key: ValueKey('tour-manual-${group.id}'),
      margin: const EdgeInsets.only(top: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: FutureBuilder<List<ManualMark>?>(
          future: marks,
          builder: (context, snap) {
            final list = snap.data;
            final steps = {for (final s in group.steps) s.id: s};
            // Không có file toạ độ: đánh số theo thứ tự các bước có neo (ảnh cũng vẽ theo thứ tự đó).
            final numbered = list != null
                ? [
                    for (final m in list)
                      if (steps[m.stepId] != null) (m.n, steps[m.stepId]!),
                  ]
                : [
                    for (final (i, s) in group.stepsFor(platform).where((s) => s.anchor != null).indexed) (i + 1, s),
                  ];
            final intro = group.stepsFor(platform).where((s) => s.anchor == null);
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(text('groups.${group.id}.title'), style: theme.textTheme.titleMedium),
                    _Chip(onWeb ? l10n.tourManualOnWeb : l10n.tourManualOnApp, outlined: true),
                    if (status != 'seen') _Chip(status == 'new' ? l10n.tourStatusNew : l10n.tourStatusUpdated),
                  ],
                ),
                const SizedBox(height: 4),
                Text(text('groups.${group.id}.summary'), style: theme.textTheme.bodySmall),
                for (final s in intro)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(text('steps.${s.id}.body'), style: const TextStyle(fontSize: 13.5)),
                  ),
                if (showImage) ...[
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 520),
                      child: Image.network(
                        OnboardingRepository.manualImageUrl(group.id),
                        fit: BoxFit.contain,
                        errorBuilder: (_, _, _) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Text(l10n.tourManualNoImage, style: theme.textTheme.bodySmall),
                        ),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                for (final (n, s) in numbered)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          alignment: Alignment.center,
                          decoration: const BoxDecoration(color: Color(0xFFDC2626), shape: BoxShape.circle),
                          child: Text(
                            '$n',
                            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(text('steps.${s.id}.title'), style: const TextStyle(fontWeight: FontWeight.w600)),
                              Text(text('steps.${s.id}.body'), style: theme.textTheme.bodySmall),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                if (onRun != null)
                  Align(
                    alignment: Alignment.centerRight,
                    child: OutlinedButton.icon(
                      onPressed: onRun,
                      icon: const Icon(Icons.play_circle_outline_rounded, size: 18),
                      label: Text(l10n.tourManualRunOnScreen),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip(this.label, {this.outlined = false});

  final String label;
  final bool outlined;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: outlined ? null : scheme.primary,
        border: outlined ? Border.all(color: scheme.outlineVariant) : null,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 11, color: outlined ? scheme.onSurfaceVariant : scheme.onPrimary),
      ),
    );
  }
}
