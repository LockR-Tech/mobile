import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:smart_laundry_locker/features/profile/domain/account_reminders.dart';
import 'package:smart_laundry_locker/core/l10n/l10n.dart';

enum ProfileReminderChoice { update, later }

/// Nhắc bổ sung email / số điện thoại còn thiếu. "Cập nhật ngay" mở màn sửa hồ sơ; "Để sau" nhắc lại sau
/// [reminderSnooze].
class ProfileReminderSheet extends StatelessWidget {
  const ProfileReminderSheet({super.key, required this.missing});

  final List<String> missing;

  static Future<ProfileReminderChoice> show(BuildContext context, List<String> missing) async {
    final choice = await showModalBottomSheet<ProfileReminderChoice>(
      context: context,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => ProfileReminderSheet(missing: missing),
    );
    return choice ?? ProfileReminderChoice.later;
  }

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    return Padding(
      key: const ValueKey('profile-reminder-sheet'),
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(LucideIcons.userPen, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  context.l10n.reminderTitle,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            context.l10n.reminderBody(missingContactSentence(missing)),
            style: TextStyle(fontSize: 14, height: 1.45, color: muted),
          ),
          const SizedBox(height: 18),
          FilledButton(
            key: const ValueKey('profile-reminder-update'),
            onPressed: () => Navigator.of(context).pop(ProfileReminderChoice.update),
            child: Text(context.l10n.commonUpdateNow),
          ),
          const SizedBox(height: 6),
          TextButton(
            key: const ValueKey('profile-reminder-later'),
            onPressed: () => Navigator.of(context).pop(ProfileReminderChoice.later),
            child: Text(context.l10n.reminderLater(reminderSnooze.inDays)),
          ),
        ],
      ),
    );
  }
}
