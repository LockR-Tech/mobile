import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:smart_laundry_locker/shared/widgets/user_ui_kit.dart';

import 'assistant_message_bubble.dart';

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
      return const [
        'Kiểm tra định kỳ không đạt thì xử lý thế nào?',
        'Ô tủ báo lỗi cửa thì cần kiểm tra những gì?',
        'Quy trình xử lý phiếu sự cố ra sao?',
        'Thiết bị IoT của tủ mất kết nối thì làm gì?',
      ];
    case AssistantAudience.droneTechnician:
      return const [
        'Quy trình tiếp nhận và phóng đơn drone ra sao?',
        'Khi nào được huỷ nhiệm vụ trước khi bay?',
        'Kiểm tra định kỳ không đạt thì xử lý thế nào?',
        'Bãi đáp drone báo lỗi thì làm gì?',
      ];
    case AssistantAudience.customer:
      return const [
        'Làm sao để gửi hàng qua tủ?',
        'Tôi thanh toán bằng những cách nào?',
        'Hết giờ thuê ô thì làm sao?',
        'Không mở được ô tủ thì phải làm gì?',
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
        ? 'quy trình vận hành, hướng dẫn kỹ thuật, chính sách'
        : 'hướng dẫn sử dụng, chính sách, câu hỏi thường gặp';
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
      children: [
        const Center(child: AssistantAvatar(size: 64)),
        const SizedBox(height: 14),
        Text(
          'Xin chào! Mình là trợ lý Lock.R',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.w800,
            color: context.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Mình trả lời dựa trên tài liệu chính thức của Lock.R ($docs) '
          'và luôn ghi rõ nguồn trích dẫn. Nếu tài liệu chưa đề cập, mình sẽ '
          'nói rõ để bạn liên hệ bộ phận hỗ trợ.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13.5,
            height: 1.5,
            color: context.textMuted,
          ),
        ),
        const SizedBox(height: 16),
        const Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: [
            _FeaturePill(
              icon: LucideIcons.bookOpenText,
              label: 'Tài liệu chính thức',
            ),
            _FeaturePill(icon: LucideIcons.quote, label: 'Có trích nguồn'),
          ],
        ),
        const SizedBox(height: 24),
        Text(
          'Bạn có thể hỏi',
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
