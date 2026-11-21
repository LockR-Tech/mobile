import 'package:flutter/material.dart';
import 'package:smart_laundry_locker/core/l10n/l10n.dart';

import '../domain/tour_engine.dart';
import '../domain/tour_models.dart';

/// Lựa chọn ở hộp chào / hộp "Có hướng dẫn mới".
enum TourChoice { skip, skipForever, start, choose }

typedef TourText = String Function(String key);

/// Lần đầu: `Chào <tên>` với Bỏ qua / Bỏ qua vĩnh viễn / Xem hướng dẫn (+ tự chọn nhóm).
Future<TourChoice> showWelcomeDialog(
  BuildContext context, {
  required String name,
  required List<TourGroup> groups,
  required TourText text,
}) async {
  final l10n = context.l10n;
  final choice = await showDialog<TourChoice>(
    context: context,
    builder: (ctx) => AlertDialog(
      key: const ValueKey('tour-welcome'),
      icon: Icon(Icons.auto_awesome_rounded, color: Theme.of(ctx).colorScheme.primary),
      title: Text(l10n.tourWelcomeTitle(name)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.tourWelcomeBody(groups.length)),
          const SizedBox(height: 12),
          for (var i = 0; i < groups.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text('${i + 1}. ${text('groups.${groups[i].id}.title')}'),
            ),
          TextButton(
            style: TextButton.styleFrom(padding: EdgeInsets.zero),
            onPressed: () => Navigator.of(ctx).pop(TourChoice.choose),
            child: Text(l10n.tourChoose),
          ),
        ],
      ),
      actionsOverflowButtonSpacing: 4,
      actions: [
        TextButton(onPressed: () => Navigator.of(ctx).pop(TourChoice.skipForever), child: Text(l10n.tourSkipForever)),
        OutlinedButton(onPressed: () => Navigator.of(ctx).pop(TourChoice.skip), child: Text(l10n.tourSkip)),
        FilledButton(
          autofocus: true,
          onPressed: () => Navigator.of(ctx).pop(TourChoice.start),
          child: Text(l10n.tourStart),
        ),
      ],
    ),
  );
  return choice ?? TourChoice.skip;
}

/// Đã xem trước đó: chỉ liệt kê nhóm mới hoặc vừa tăng phiên bản.
Future<TourChoice> showWhatsNewDialog(
  BuildContext context, {
  required List<TourGroup> groups,
  required Map<String, int> seen,
  required TourText text,
}) async {
  final l10n = context.l10n;
  final choice = await showDialog<TourChoice>(
    context: context,
    builder: (ctx) => AlertDialog(
      key: const ValueKey('tour-whats-new'),
      title: Text(l10n.tourWhatsNewTitle),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.tourWhatsNewBody(groups.length)),
            const SizedBox(height: 8),
            for (final g in groups) _GroupTile(group: g, status: groupStatus(g, seen), text: text),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(ctx).pop(TourChoice.skipForever), child: Text(l10n.tourSkipForever)),
        OutlinedButton(onPressed: () => Navigator.of(ctx).pop(TourChoice.skip), child: Text(l10n.tourLater)),
        FilledButton(
          autofocus: true,
          onPressed: () => Navigator.of(ctx).pop(TourChoice.start),
          child: Text(l10n.tourStartNew),
        ),
      ],
    ),
  );
  return choice ?? TourChoice.skip;
}

class _StatusChip extends StatelessWidget {
  const _StatusChip(this.status);

  final String status;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final (label, bg, fg) = switch (status) {
      'new' => (l10n.tourStatusNew, scheme.primary, scheme.onPrimary),
      'updated' => (l10n.tourStatusUpdated, scheme.secondaryContainer, scheme.onSecondaryContainer),
      _ => (l10n.tourStatusSeen, scheme.surfaceContainerHighest, scheme.onSurfaceVariant),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: fg)),
    );
  }
}

class _GroupTile extends StatelessWidget {
  const _GroupTile({required this.group, required this.status, required this.text, this.trailing, this.leading});

  final TourGroup group;
  final String status;
  final TourText text;
  final Widget? trailing;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (leading != null) leading!,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(text('groups.${group.id}.title'), style: const TextStyle(fontWeight: FontWeight.w600)),
                    _StatusChip(status),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  text('groups.${group.id}.summary'),
                  style: TextStyle(fontSize: 12.5, color: Theme.of(context).colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

/// Danh sách hướng dẫn (nút "Hướng dẫn", Tài khoản) — luôn mở được, kể cả khi đã bỏ qua vĩnh viễn.
/// Trả về nhóm cần chạy (rỗng = đóng).
Future<List<TourGroup>> showGuidePicker(
  BuildContext context, {
  required List<TourGroup> groups,
  required Map<String, int> seen,
  required bool autoShow,
  required Future<void> Function(bool value) onAutoShowChange,
  required TourText text,
  String platform = 'mobile',
}) async {
  final result = await showModalBottomSheet<List<TourGroup>>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (ctx) => _GuidePicker(
      groups: groups,
      seen: seen,
      autoShow: autoShow,
      onAutoShowChange: onAutoShowChange,
      text: text,
      platform: platform,
    ),
  );
  return result ?? const [];
}

class _GuidePicker extends StatefulWidget {
  const _GuidePicker({
    required this.groups,
    required this.seen,
    required this.autoShow,
    required this.onAutoShowChange,
    required this.text,
    required this.platform,
  });

  final List<TourGroup> groups;
  final Map<String, int> seen;
  final bool autoShow;
  final Future<void> Function(bool value) onAutoShowChange;
  final TourText text;
  final String platform;

  @override
  State<_GuidePicker> createState() => _GuidePickerState();
}

class _GuidePickerState extends State<_GuidePicker> {
  final Set<String> _selected = {};
  late bool _autoShow = widget.autoShow;

  bool _runnable(TourGroup g) => g.stepsFor(widget.platform).isNotEmpty;

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
    final sections = [
      for (final role in tourRoles)
        (role, widget.groups.where((g) => g.roles.first == role).toList()),
    ].where((s) => s.$2.isNotEmpty).toList();
    final pending = widget.groups.where((g) => _runnable(g) && groupStatus(g, widget.seen) != 'seen').toList();
    return DraggableScrollableSheet(
      key: const ValueKey('tour-picker'),
      expand: false,
      initialChildSize: 0.75,
      maxChildSize: 0.95,
      builder: (context, scroll) => Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.tourPickerTitle, style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 4),
                Text(l10n.tourPickerDescription, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              controller: scroll,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                for (final (role, groups) in sections) ...[
                  if (sections.length > 1)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(8, 12, 8, 4),
                      child: Text(
                        _roleLabel(role).toUpperCase(),
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  for (final g in groups)
                    _GroupTile(
                      group: g,
                      status: groupStatus(g, widget.seen),
                      text: widget.text,
                      leading: _runnable(g)
                          ? Checkbox(
                              value: _selected.contains(g.id),
                              onChanged: (v) =>
                                  setState(() => v == true ? _selected.add(g.id) : _selected.remove(g.id)),
                            )
                          : const SizedBox(width: 48),
                      trailing: _runnable(g)
                          ? TextButton(
                              onPressed: () => Navigator.of(context).pop([g]),
                              child: Text(l10n.tourView),
                            )
                          : Padding(
                              padding: const EdgeInsets.only(top: 8, right: 8),
                              child: Text(l10n.tourOnlyOnWeb, style: const TextStyle(fontSize: 12)),
                            ),
                    ),
                ],
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
              child: Column(
                children: [
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(l10n.tourAutoShow, style: const TextStyle(fontSize: 14)),
                    value: _autoShow,
                    onChanged: (v) {
                      setState(() => _autoShow = v);
                      widget.onAutoShowChange(v);
                    },
                  ),
                  Row(
                    children: [
                      if (pending.isNotEmpty)
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.of(context).pop(pending),
                            child: Text(l10n.tourViewNew(pending.length)),
                          ),
                        ),
                      if (pending.isNotEmpty) const SizedBox(width: 8),
                      Expanded(
                        child: FilledButton(
                          onPressed: _selected.isEmpty
                              ? null
                              : () => Navigator.of(context)
                                  .pop(widget.groups.where((g) => _selected.contains(g.id)).toList()),
                          child: Text(l10n.tourViewSelected(_selected.length)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
