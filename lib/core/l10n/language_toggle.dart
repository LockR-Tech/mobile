import 'package:flutter/material.dart';
import 'package:smart_laundry_locker/core/l10n/l10n.dart';
import 'package:smart_laundry_locker/core/l10n/locale_provider.dart';
import 'package:smart_laundry_locker/core/services/app_restart_service.dart';

/// Nút gạt VI | EN cho màn chưa đăng nhập (khách nước ngoài cần đổi ngôn ngữ
/// trước khi vào được Hồ sơ). Dùng trên nền tối.
class LanguageToggle extends StatelessWidget {
  const LanguageToggle({super.key});

  Future<void> _select(BuildContext context, Locale locale) async {
    if (locale.languageCode == L10n.locale.languageCode) return;
    await LocaleProvider.instance.setLocale(locale);
    if (context.mounted) RestartableApp.restartApp(context);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _option(context, L10n.vi, 'VI'),
          _option(context, L10n.en, 'EN'),
        ],
      ),
    );
  }

  Widget _option(BuildContext context, Locale locale, String label) {
    final selected = locale.languageCode == L10n.locale.languageCode;
    return Semantics(
      button: true,
      selected: selected,
      label: locale == L10n.vi
          ? context.l10n.languageVietnamese
          : context.l10n.languageEnglish,
      child: GestureDetector(
        onTap: () => _select(context, locale),
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: selected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
              color: selected ? const Color(0xFF003D5B) : Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}
