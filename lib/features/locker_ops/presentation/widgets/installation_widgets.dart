import 'package:flutter/material.dart';
import 'package:smart_laundry_locker/core/l10n/l10n.dart';
import 'package:smart_laundry_locker/features/locker_ops/data/installation_api.dart';

String formatInstallationTime(DateTime? time) {
  if (time == null) return '—';
  String two(int v) => v.toString().padLeft(2, '0');
  return '${two(time.hour)}:${two(time.minute)} ${two(time.day)}/${two(time.month)}/${time.year}';
}

String installationStatusLabel(BuildContext context, String status) {
  final l10n = context.l10n;
  return switch (status) {
    InstallationStatus.scheduled => l10n.instStatusScheduled,
    InstallationStatus.inProgress => l10n.instStatusInProgress,
    InstallationStatus.submitted => l10n.instStatusSubmitted,
    InstallationStatus.approved => l10n.instStatusApproved,
    InstallationStatus.cancelled => l10n.instStatusCancelled,
    _ => status,
  };
}

class InstallationStatusChip extends StatelessWidget {
  const InstallationStatusChip({super.key, required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      InstallationStatus.scheduled => const Color(0xFF0284C7),
      InstallationStatus.inProgress => const Color(0xFF4F46E5),
      InstallationStatus.submitted => const Color(0xFFD97706),
      InstallationStatus.approved => const Color(0xFF059669),
      _ => const Color(0xFF64748B),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(installationStatusLabel(context, status),
          style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: color)),
    );
  }
}

class InstallationNotice extends StatelessWidget {
  const InstallationNotice({super.key, required this.icon, required this.color, required this.text});

  final IconData icon;
  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: TextStyle(fontSize: 13, color: color, height: 1.35))),
        ],
      ),
    );
  }
}

/// Màu + biểu tượng của một trạng thái bước nghiệm thu.
({Color color, IconData icon}) installationCheckStyle(String status) => switch (status) {
  InstallationCheckStatus.passed => (color: const Color(0xFF059669), icon: Icons.check_circle),
  InstallationCheckStatus.failed => (color: const Color(0xFFDC2626), icon: Icons.cancel),
  InstallationCheckStatus.notApplicable => (color: const Color(0xFF64748B), icon: Icons.remove_circle_outline),
  _ => (color: const Color(0xFF94A3B8), icon: Icons.radio_button_unchecked),
};

String installationCheckStatusLabel(BuildContext context, String status) {
  final l10n = context.l10n;
  return switch (status) {
    InstallationCheckStatus.passed => l10n.instCheckPassed,
    InstallationCheckStatus.failed => l10n.instCheckFailed,
    InstallationCheckStatus.notApplicable => l10n.instCheckNotApplicable,
    _ => l10n.instCheckPending,
  };
}
