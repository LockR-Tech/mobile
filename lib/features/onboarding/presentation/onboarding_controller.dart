import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_laundry_locker/core/l10n/l10n.dart';
import 'package:smart_laundry_locker/core/routing/app_router.dart';
import 'package:smart_laundry_locker/core/routing/role_routes.dart';
import 'package:smart_laundry_locker/core/services/token_service.dart';

import '../data/onboarding_repository.dart';
import '../domain/tour_engine.dart';
import '../domain/tour_models.dart';
import 'guide_manual_page.dart';
import 'onboarding_dialogs.dart';
import 'tour_overlay.dart';

/// Hướng dẫn lần đầu trên màn hình cho app (F3-G13). Trạng thái "đã xem" / "bỏ qua vĩnh viễn" ở user-service,
/// dùng chung với web; "Bỏ qua" một lần và "đã tự mở" chỉ sống trong phiên đăng nhập (xoá khi đăng xuất).
class OnboardingController {
  OnboardingController._();

  static final OnboardingController instance = OnboardingController._();

  /// Thay được trong test.
  OnboardingRepository repository = OnboardingRepository();
  static const _skipKey = 'onboarding_skip_';
  static const _shownKey = 'onboarding_shown_';

  TourContent? _content;
  Map<String, Map<String, dynamic>> _texts = {};
  OnboardingState? _state;
  OverlayEntry? _entry;
  bool _busy = false;
  bool _listening = false;

  /// Chữ của tour theo ngôn ngữ đang chọn (thiếu thì lấy tiếng Việt, cuối cùng là chính khoá).
  String text(String key) {
    final lang = L10n.isEnglish ? 'en' : 'vi';
    final v = lookupText(_texts[lang], key) ?? lookupText(_texts['vi'], key);
    return v is String ? v : key;
  }

  void _listenAuth() {
    if (_listening) return;
    _listening = true;
    TokenService.authState.addListener(() {
      if (!TokenService.authState.value) unawaited(clearSession());
    });
  }

  /// Đăng xuất: lần đăng nhập sau hỏi lại.
  Future<void> clearSession() async {
    _state = null;
    _entry?.remove();
    _entry = null;
    try {
      final prefs = SharedPreferencesAsync();
      for (final key in await prefs.getKeys()) {
        if (key.startsWith(_skipKey) || key.startsWith(_shownKey)) await prefs.remove(key);
      }
    } catch (_) {
      // Không xoá được thì lần sau vẫn hỏi theo cờ cũ — chấp nhận.
    }
  }

  Future<bool> _ensureContent() async {
    try {
      _content ??= await repository.loadContent();
      if (_texts.isEmpty) _texts = await repository.loadTexts();
      return true;
    } catch (e) {
      debugPrint('Onboarding: không có nội dung hướng dẫn ($e)');
      return false;
    }
  }

  /// Vai trò dùng để TỰ MỞ trên app: vai trò chính (màn hình đang dùng), vì tài khoản nhiều vai trò chỉ thấy
  /// một trang chủ.
  Future<List<String>> _primaryRoles() async {
    final role = primaryRole(await TokenService.getCurrentRoles());
    return [
      switch (role) {
        AppRole.admin => 'ADMIN',
        AppRole.lockerTechnician => 'LOCKER_TECHNICIAN',
        AppRole.droneTechnician => 'DRONE_TECHNICIAN',
        AppRole.customer => 'CUSTOMER',
      },
    ];
  }

  /// Gọi khi đã ở trang chủ theo vai trò VÀ đã qua mọi bước bắt buộc (điều khoản, hoàn tất đăng ký…).
  /// Một lần mỗi phiên, chậm ~1 giây cho màn hình vẽ xong.
  Future<void> maybeAutoOpen() async {
    _listenAuth();
    if (_busy || _entry != null) return;
    _busy = true;
    try {
      await Future<void>.delayed(autoOpenDelay);
      if (!await TokenService.hasToken()) return;
      final uid = await TokenService.getUserId();
      if (uid == null || !await _ensureContent()) return;
      try {
        _state = await repository.getState();
      } catch (e) {
        debugPrint('Onboarding: không đọc được trạng thái ($e)');
        return;
      }
      final prefs = SharedPreferencesAsync();
      final decision = decideAutoOpen(
        signedIn: true,
        inWorkspace: true,
        mandatoryDone: true,
        autoShow: _state!.autoShow,
        sessionSkipped: await prefs.getBool('$_skipKey$uid') ?? false,
        shownThisSession: await prefs.getBool('$_shownKey$uid') ?? false,
        groups: ownGroups(_content!, await _primaryRoles(), 'mobile'),
        seen: _state!.seenGroups,
      );
      if (decision.kind == 'none') return;
      await prefs.setBool('$_shownKey$uid', true);
      final ctx = AppRouter.navigatorKey.currentContext;
      if (ctx == null || !ctx.mounted) return;
      final name = (await TokenService.getUserName())?.trim() ?? '';
      if (!ctx.mounted) return;
      final choice = decision.kind == 'welcome'
          ? await showWelcomeDialog(ctx, name: name, groups: decision.groups, text: text)
          : await showWhatsNewDialog(ctx, groups: decision.groups, seen: _state!.seenGroups, text: text);
      switch (choice) {
        case TourChoice.skip:
          await prefs.setBool('$_skipKey$uid', true);
        case TourChoice.skipForever:
          try {
            _state = await repository.setAutoShow(false);
          } catch (_) {}
        case TourChoice.start:
          start(decision.groups);
        case TourChoice.choose:
          _busy = false;
          await openGuide();
      }
    } finally {
      _busy = false;
    }
  }

  /// Nút "Hướng dẫn" và mục trong Tài khoản: danh sách nhóm (admin xem mọi vai trò), bật/tắt tự mở.
  Future<void> openGuide() async {
    _listenAuth();
    if (!await _ensureContent()) return;
    try {
      _state = await repository.getState();
    } catch (_) {
      // Chưa đọc được trạng thái: vẫn cho xem hướng dẫn.
    }
    final ctx = AppRouter.navigatorKey.currentContext;
    if (ctx == null || !ctx.mounted) return;
    final roles = normalizeRoles(await TokenService.getCurrentRoles());
    if (!ctx.mounted) return;
    final visible = browseGroups(_content!, roles);
    var manual = false;
    TourGroup? manualFocus;
    final groups = await showGuidePicker(
      ctx,
      groups: visible,
      seen: _state?.seenGroups ?? const {},
      autoShow: _state?.autoShow ?? true,
      text: text,
      onAutoShowChange: (v) async {
        try {
          _state = await repository.setAutoShow(v);
        } catch (_) {}
      },
      onOpenManual: (g) {
        manual = true;
        manualFocus = g;
      },
    );
    if (manual) {
      openManual(visible, focus: manualFocus?.id);
    } else if (groups.isNotEmpty) {
      start(groups);
    }
  }

  /// Trang HDSD: ảnh chụp có khoanh đỏ + giải thích từng số, cùng nguồn với hướng dẫn trên màn hình.
  void openManual(List<TourGroup> groups, {String? focus}) {
    final nav = AppRouter.navigatorKey.currentState;
    if (nav == null) return;
    unawaited(nav.push(MaterialPageRoute<void>(
      builder: (_) => GuideManualPage(
        groups: groups,
        text: text,
        repository: repository,
        seen: _state?.seenGroups ?? const {},
        focusGroup: focus,
        onRun: (g) => start([g]),
      ),
    )));
  }

  void start(List<TourGroup> groups) {
    groups = groups.where((g) => runnable(g, 'mobile')).toList();
    final overlay = AppRouter.navigatorKey.currentState?.overlay;
    if (overlay == null || groups.isEmpty) return;
    _entry?.remove();
    _entry = OverlayEntry(
      builder: (_) => TourOverlay(
        groups: groups,
        text: text,
        navigate: _navigate,
        resetModals: closeModals,
        onGroupDone: (g) async {
          try {
            _state = await repository.markSeen(g.id, g.version);
          } catch (e) {
            debugPrint('Onboarding: không ghi được đã xem ${g.id} ($e)');
          }
        },
        onClose: (_) {
          _entry?.remove();
          _entry = null;
        },
      ),
    );
    overlay.insert(_entry!);
  }

  /// Đóng bảng dưới / hộp thoại đang mở trên navigator gốc (không đụng các trang).
  static void closeModals() {
    AppRouter.navigatorKey.currentState?.popUntil((r) => r is! PopupRoute);
  }

  void _navigate(String route) {
    final router = AppRouter.router;
    final current = router.routerDelegate.currentConfiguration.uri.path;
    if (current != route) router.go(route);
  }
}
