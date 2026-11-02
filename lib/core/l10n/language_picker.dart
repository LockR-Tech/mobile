import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:smart_laundry_locker/core/l10n/l10n.dart';
import 'package:smart_laundry_locker/core/l10n/locale_provider.dart';
import 'package:smart_laundry_locker/core/services/app_restart_service.dart';

/// Mở sheet chọn ngôn ngữ; chọn ngôn ngữ khác thì lưu lại rồi dựng lại app để
/// mọi màn (kể cả nhãn dựng ngoài widget) đọc lại bản dịch mới.
///
/// Dùng chung cho Hồ sơ khách hàng và Hồ sơ kỹ thuật viên.
Future<void> pickAppLanguage(BuildContext context) async {
  final selected = await showModalBottomSheet<Locale>(
    context: context,
    useRootNavigator: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) =>
        LanguagePickerSheet(current: LocaleProvider.instance.locale),
  );
  if (selected == null || !context.mounted) return;
  if (selected.languageCode == LocaleProvider.instance.locale.languageCode) {
    return;
  }
  await LocaleProvider.instance.setLocale(selected);
  if (context.mounted) RestartableApp.restartApp(context);
}

/// Sheet chọn Tiếng Việt / English; đóng sheet trả về [Locale] được chọn.
class LanguagePickerSheet extends StatelessWidget {
  const LanguagePickerSheet({required this.current, super.key});

  final Locale current;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF0A2342) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final mutedColor = isDark
        ? const Color(0xFF94A3B8)
        : const Color(0xFF64748B);

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: mutedColor.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Text(
            context.l10n.profileLanguage,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: textColor,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            context.l10n.profileLanguageSheetSubtitle,
            style: TextStyle(fontSize: 13, color: mutedColor),
          ),
          const SizedBox(height: 20),
          _LanguageOption(
            icon: LucideIcons.languages,
            label: context.l10n.languageVietnamese,
            description: context.l10n.profileLanguageViDescription,
            selected: current.languageCode == L10n.vi.languageCode,
            onTap: () => Navigator.pop(context, L10n.vi),
          ),
          const SizedBox(height: 10),
          _LanguageOption(
            icon: LucideIcons.globe,
            label: context.l10n.languageEnglish,
            description: context.l10n.profileLanguageEnDescription,
            selected: current.languageCode == L10n.en.languageCode,
            onTap: () => Navigator.pop(context, L10n.en),
          ),
        ],
      ),
    );
  }
}

/// Một lựa chọn trong sheet — cùng kiểu với lựa chọn giao diện sáng/tối ở Hồ sơ.
class _LanguageOption extends StatelessWidget {
  const _LanguageOption({
    required this.icon,
    required this.label,
    required this.description,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String description;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const navy = Color(0xFF003D5B);
    final selectedBg = navy.withValues(alpha: isDark ? 0.35 : 0.08);
    final borderColor = selected
        ? navy.withValues(alpha: isDark ? 0.7 : 0.4)
        : (isDark ? const Color(0xFF1E4976) : const Color(0xFFE2E8F0));
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final mutedColor = isDark
        ? const Color(0xFF94A3B8)
        : const Color(0xFF64748B);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: selected ? selectedBg : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor, width: selected ? 1.5 : 1),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: selected
                    ? navy.withValues(alpha: 0.12)
                    : (isDark
                          ? const Color(0xFF0D2B4A)
                          : const Color(0xFFF0F4F8)),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 20, color: selected ? navy : mutedColor),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: textColor,
                    ),
                  ),
                  Text(
                    description,
                    style: TextStyle(fontSize: 12, color: mutedColor),
                  ),
                ],
              ),
            ),
            if (selected)
              const Icon(LucideIcons.circleCheck, size: 20, color: navy),
          ],
        ),
      ),
    );
  }
}
