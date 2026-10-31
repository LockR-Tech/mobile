import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_laundry_locker/core/routing/app_router.dart';
import 'package:smart_laundry_locker/core/routing/role_routes.dart';
import 'package:smart_laundry_locker/core/services/session_service.dart';
import 'package:smart_laundry_locker/core/services/token_service.dart';
import 'package:smart_laundry_locker/features/auth/presentation/widgets/complete_profile_dialog.dart';
import 'package:smart_laundry_locker/features/profile/domain/account_reminders.dart';
import 'package:smart_laundry_locker/features/profile/domain/profile_completion.dart';
import 'package:smart_laundry_locker/features/profile/presentation/providers/profile_provider.dart';
import 'package:smart_laundry_locker/features/profile/presentation/widgets/profile_reminder_sheet.dart';
import 'package:smart_laundry_locker/features/profile/presentation/widgets/terms_consent_dialog.dart';

/// Lời nhắc của khách sau khi đăng nhập (và khi mở app đã đăng nhập sẵn), lần lượt:
/// 1. chưa đồng ý Điều khoản dịch vụ ⇒ hộp thoại bắt buộc ([TermsConsentDialog]);
/// 2. tên còn mặc định "User" (đăng nhập SĐT lần đầu) ⇒ "Hoàn tất đăng ký" ([CompleteProfileDialog]);
/// 3. còn thiếu email / số điện thoại ⇒ nhắc bổ sung, "Để sau" nhắc lại theo hạn ([ProfileReminderSheet]).
///
/// KTV và admin không qua bước này. Mỗi tài khoản chạy một lần cho mỗi lần mở app.
class PostLoginPrompts {
  PostLoginPrompts._();

  static bool _running = false;
  static String? _doneForUser;

  @visibleForTesting
  static void resetForTest() {
    _running = false;
    _doneForUser = null;
  }

  static String _snoozeKey(String userId) => 'profile_reminder_until_$userId';

  static Future<void> run(ProfileProvider profileProvider) async {
    if (_running) return;
    _running = true;
    try {
      if (!TokenService.authState.value) return;
      final roles = await TokenService.getCurrentRoles();
      if (primaryRole(roles) != AppRole.customer) return;

      if (!profileProvider.hasServerProfile) await profileProvider.loadProfile();
      final profile = profileProvider.profile;
      if (!profileProvider.hasServerProfile || profile == null) return;
      if (_doneForUser == profile.id) return;

      // Chờ trang chủ dựng xong để hộp thoại không bám vào route đăng nhập cũ.
      await WidgetsBinding.instance.endOfFrame;

      if (needsTermsConsent(profile)) {
        final ctx = AppRouter.navigatorKey.currentContext;
        if (ctx == null || !ctx.mounted) return;
        final accepted = await TermsConsentDialog.show(
          ctx,
          profileProvider: profileProvider,
          onSignOut: () => _signOut(profileProvider),
        );
        if (!accepted) return;
      }

      if (needsProfileCompletion(profileProvider.profile)) {
        await CompleteProfileDialog.maybeShow(profileProvider);
      }

      await _remindMissingContact(profileProvider);
      _doneForUser = profile.id;
    } finally {
      _running = false;
    }
  }

  static Future<void> _remindMissingContact(ProfileProvider profileProvider) async {
    final profile = profileProvider.profile;
    final missing = missingContactFields(profile);
    if (profile == null || missing.isEmpty) return;

    final prefs = SharedPreferencesAsync();
    final key = _snoozeKey(profile.id);
    DateTime? until;
    try {
      final millis = await prefs.getInt(key);
      until = millis == null ? null : DateTime.fromMillisecondsSinceEpoch(millis);
    } catch (_) {
      until = null;
    }
    final now = DateTime.now();
    if (!reminderDue(until, now)) return;

    final ctx = AppRouter.navigatorKey.currentContext;
    if (ctx == null || !ctx.mounted) return;
    final choice = await ProfileReminderSheet.show(ctx, missing);
    final snooze = choice == ProfileReminderChoice.update ? reminderSnoozeAfterOpen : reminderSnooze;
    try {
      await prefs.setInt(key, now.add(snooze).millisecondsSinceEpoch);
    } catch (_) {
      // Không lưu được mốc hoãn ⇒ lần mở app sau nhắc lại, không sao.
    }
    if (choice == ProfileReminderChoice.update) {
      final c = AppRouter.navigatorKey.currentContext;
      if (c != null && c.mounted) await c.push(AppRouter.editProfile, extra: profileProvider.profile);
    }
  }

  static Future<void> _signOut(ProfileProvider profileProvider) async {
    await SessionService.logout();
    profileProvider.reset();
    _doneForUser = null;
    final c = AppRouter.navigatorKey.currentContext;
    if (c != null && c.mounted) c.go(AppRouter.onboarding);
  }
}
