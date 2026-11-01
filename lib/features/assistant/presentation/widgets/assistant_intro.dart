import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:smart_laundry_locker/shared/widgets/user_ui_kit.dart';

import 'assistant_message_bubble.dart';
import 'package:smart_laundry_locker/core/l10n/l10n.dart';

/// Nhóm người hỏi — chỉ để chọn câu hỏi gợi ý. Tài liệu được dùng để trả lời
/// do backend lọc theo vai trò trong JWT.
enum AssistantAudience { customer, lockerTechnician, droneTechnician }

AssistantAudience assistantAudienceForRoles(List<String> roles) {
  final upper = roles.map((r) => r.toUpperCase()).toList();
  if (upper.any((r) => r.endsWith('LOCKER_TECHNICIAN'))) {
    return AssistantAudience.lockerTechnician;
  }
  if (upper.any((r) => r.endsWith('DRONE_TECHNICIAN'))) {
    return AssistantAudience.droneTechnician;
  }
  return AssistantAudience.customer;
}

List<String> assistantExampleQuestions(AssistantAudience audience) {
  switch (audience) {
    case AssistantAudience.lockerTechnician:
      return [
        L10n.current.aiQTechInspection,
        L10n.current.aiQTechDoor,
        L10n.current.aiQTechTicket,
        L10n.current.aiQTechIot,
      ];
    case AssistantAudience.droneTechnician:
      return [
        L10n.current.aiQDroneLaunch,
        L10n.current.aiQDroneCancel,
        L10n.current.aiQTechInspection,
        L10n.current.aiQDronePad,
      ];
    case AssistantAudience.customer:
      return [
        L10n.current.aiQSend,
        L10n.current.aiQPay,
        L10n.current.aiQRentEnd,
        L10n.current.aiQCantOpen,
      ];
  }
}

/// Màn giới thiệu khi chưa có tin nhắn: trợ lý trả lời từ tài liệu chính thức
/// của Lock.R, có trích nguồn, kèm câu hỏi gợi ý chạm để hỏi ngay.
class AssistantIntro extends StatelessWidget {
  const AssistantIntro({super.key, required this.audience, this.onExampleTap});

  final AssistantAudience audience;

  /// null ⇒ gợi ý chỉ để đọc (trợ lý chưa sẵn sàng).
  final ValueChanged<String>? onExampleTap;

  @override
  Widget build(BuildContext context) {
    final isTechnician = audience != AssistantAudience.customer;
    final docs = isTechnician
        ? context.l10n.aiDocsStaff
        : context.l10n.aiDocsCustomer;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
      children: [
        const Center(child: AssistantAvatar(size: 64)),
        const SizedBox(height: 14),
        Text(
          context.l10n.aiHello,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.w800,
            color: context.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          context.l10n.aiIntro(docs),
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13.5,
            height: 1.5,
            color: context.textMuted,
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: [
            _FeaturePill(
              icon: LucideIcons.bookOpenText,
              label: context.l10n.aiOfficialDocs,
            ),
            _FeaturePill(icon: LucideIcons.quote, label: context.l10n.aiWithSources),
          ],
        ),
        const SizedBox(height: 24),
        Text(
          context.l10n.aiYouCanAsk,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: context.textMuted,
          ),
        ),
        const SizedBox(height: 8),
        for (final question in assistantExampleQuestions(audience))
          _ExampleQuestion(
            question: question,
            onTap: onExampleTap == null ? null : () => onExampleTap!(question),
          ),
      ],
    );
  }
}

class _FeaturePill extends StatelessWidget {
  const _FeaturePill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: context.surfaceBg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: AislBrand.blue),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: context.textPrimary),
          ),
        ],
      ),
    );
  }
}

class _ExampleQuestion extends StatelessWidget {
  const _ExampleQuestion({required this.question, this.onTap});

  final String question;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: context.cardBg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: context.borderColor),
        ),
        child: InkWell(
          onTap: onTap,
          customBorder: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                const Icon(
                  LucideIcons.messageCircleQuestion,
                  size: 18,
                  color: AislBrand.blue,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    question,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: context.textPrimary,
                    ),
                  ),
                ),
                if (onTap != null)
                  Icon(
                    LucideIcons.arrowUpRight,
                    size: 16,
                    color: context.textMuted,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
