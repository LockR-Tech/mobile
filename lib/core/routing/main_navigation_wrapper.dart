import 'dart:async';

import 'package:provider/provider.dart';
import 'package:smart_laundry_locker/core/routing/app_router.dart';
import 'package:smart_laundry_locker/features/profile/presentation/post_login_prompts.dart';
import 'package:smart_laundry_locker/features/profile/presentation/providers/profile_provider.dart';
import 'package:smart_laundry_locker/core/services/app_initial_tab_service.dart';

import 'package:smart_laundry_locker/shared/icons/custom_icon.dart'
    show CustomIcons;
import 'package:smart_laundry_locker/features/auth/presentation/widgets/auth_bottom_sheet.dart';
import 'package:smart_laundry_locker/core/services/token_service.dart';
import 'package:smart_laundry_locker/shared/shared.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:smart_laundry_locker/core/l10n/l10n.dart';

class MainNavigationWrapper extends StatefulWidget {
  final StatefulNavigationShell? navigationShell;
  final Widget? child;

  const MainNavigationWrapper({
    super.key,
    this.navigationShell,
    this.child,
  }) : assert(navigationShell != null || child != null);

  @override
  State<MainNavigationWrapper> createState() => _MainNavigationWrapperState();
}

class _MainNavigationWrapperState extends State<MainNavigationWrapper> {
  final ValueNotifier<bool> _navVisibleNotifier = ValueNotifier<bool>(true);

  void _onScroll(ScrollNotification notification) {
    if (notification is ScrollUpdateNotification) {
      final delta = notification.scrollDelta ?? 0;
      // Always show when at top
      if (notification.metrics.pixels <= 10) {
        if (!_navVisibleNotifier.value) _navVisibleNotifier.value = true;
        return;
      }
      if (delta > 4 && _navVisibleNotifier.value) {
        _navVisibleNotifier.value = false;
      } else if (delta < -4 && !_navVisibleNotifier.value) {
        _navVisibleNotifier.value = true;
      }
    } else if (notification is ScrollEndNotification) {
      if (notification.metrics.pixels <= 10 && !_navVisibleNotifier.value) {
        _navVisibleNotifier.value = true;
      }
    }
  }

  @override
  void dispose() {
    _navVisibleNotifier.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkInitialAuth();
      _applyPendingInitialTab();
      _runPostLoginPrompts();
    });
  }

  /// Mở app khi đã đăng nhập sẵn: vẫn hỏi Điều khoản dịch vụ nếu chưa đồng ý và nhắc bổ sung thông tin
  /// theo hạn (cùng luồng với lúc vừa đăng nhập; mỗi tài khoản một lần mỗi lần mở app).
  Future<void> _runPostLoginPrompts() async {
    if (!await TokenService.hasToken() || !mounted) return;
    unawaited(PostLoginPrompts.run(context.read<ProfileProvider>()));
  }

  Future<void> _checkInitialAuth() async {
    if (kDebugMode) {
      return;
    }
    final hasToken = await TokenService.hasToken();
    if (!hasToken && mounted) {
      AuthBottomSheet.show(context, isLogin: true);
    }
  }

  Future<void> _applyPendingInitialTab() async {
    final initialTabIndex = await AppInitialTabService.getAndResetInitialTab();
    if (!mounted || initialTabIndex == 0) return;

    if (widget.navigationShell != null) {
      switch (initialTabIndex) {
        case 1:
          widget.navigationShell!.goBranch(1);
          break;
        case 3:
          widget.navigationShell!.goBranch(2);
          break;
        case 4:
          widget.navigationShell!.goBranch(3);
          break;
        default:
          break;
      }
      return;
    }

    switch (initialTabIndex) {
      case 1:
        context.go(AppRouter.lockers);
        break;
      case 3:
        context.go(AppRouter.orders);
        break;
      case 4:
        context.go(AppRouter.profile);
        break;
      default:
        break;
    }
  }

  int _calculateSelectedIndex(BuildContext context) {
    if (widget.navigationShell != null) {
      return switch (widget.navigationShell!.currentIndex) {
        0 => 0,
        1 => 1,
        2 => 3,
        3 => 4,
        _ => 0,
      };
    }
    final String location = GoRouterState.of(context).uri.path;
    if (location.startsWith(AppRouter.home)) return 0;
    if (location.startsWith(AppRouter.lockers)) return 1;
    if (location.startsWith(AppRouter.assistant)) return 2;
    if (location.startsWith(AppRouter.orders)) return 3;
    if (location.startsWith(AppRouter.profile)) return 4;
    return 0;
  }

  void _onItemTapped(int index) {
    if (widget.navigationShell != null) {
      final branch = switch (index) {
        0 => 0,
        1 => 1,
        3 => 2,
        4 => 3,
        _ => null,
      };
      // Bấm lại tab đang mở: đóng các trang đẩy chồng bằng Navigator.push (chi tiết
      // đơn…) — goBranch(initialLocation) chỉ đặt lại đường dẫn, không gỡ chúng.
      if (branch != null && branch == widget.navigationShell!.currentIndex) {
        AppRouter.shellBranchNavigatorKeys[branch].currentState
            ?.popUntil((route) => route.isFirst);
      }
      switch (index) {
        case 0:
          widget.navigationShell!.goBranch(
            0,
            initialLocation: 0 == widget.navigationShell!.currentIndex,
          );
          break;
        case 1:
          widget.navigationShell!.goBranch(
            1,
            initialLocation: 1 == widget.navigationShell!.currentIndex,
          );
          break;
        case 2:
          context.push(AppRouter.assistant);
          break;
        case 3:
          widget.navigationShell!.goBranch(
            2,
            initialLocation: 2 == widget.navigationShell!.currentIndex,
          );
          break;
        case 4:
          widget.navigationShell!.goBranch(
            3,
            initialLocation: 3 == widget.navigationShell!.currentIndex,
          );
          break;
      }
      return;
    }
    switch (index) {
      case 0:
        context.go(AppRouter.home);
        break;
      case 1:
        context.go(AppRouter.lockers);
        break;
      case 2:
        context.push(AppRouter.assistant);
        break;
      case 3:
        context.go(AppRouter.orders);
        break;
      case 4:
        context.go(AppRouter.profile);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: NotificationListener<ScrollNotification>(
        onNotification: (n) {
          _onScroll(n);
          return false;
        },
        child: RepaintBoundary(child: widget.navigationShell ?? widget.child!),
      ),
      bottomNavigationBar: ValueListenableBuilder<bool>(
        valueListenable: _navVisibleNotifier,
        builder: (context, navVisible, child) {
          return AnimatedSlide(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeInOut,
            offset: navVisible ? Offset.zero : const Offset(0, 1),
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 220),
              opacity: navVisible ? 1.0 : 0.0,
              child: child!,
            ),
          );
        },
        child: RepaintBoundary(
          child: CustomBottomNavigationBar(
            currentIndex: _calculateSelectedIndex(context),
            onTap: _onItemTapped,
            items: [
              NavigationItem(
                icon: LucideIcons.house,
                activeIcon: LucideIcons.house,
                label: context.l10n.navHome,
                route: AppRouter.home,
              ),
              NavigationItem(
                icon: CustomIcons.drawer,
                activeIcon: CustomIcons.drawer,
                label: context.l10n.navLockers,
                route: AppRouter.lockers,
              ),
              NavigationItem(
                icon: (Color color, double size) => AppLottie(
                  AppLottieAssets.chatbox,
                  width: size,
                  height: size,
                  fit: BoxFit.contain,
                ),
                activeIcon: (Color color, double size) => AppLottie(
                  AppLottieAssets.chatbox,
                  width: size,
                  height: size,
                  fit: BoxFit.contain,
                ),
                label: context.l10n.navAssistant,
                route: AppRouter.assistant,
                isProminent: true,
              ),
              NavigationItem(
                icon: CustomIcons.package,
                activeIcon: CustomIcons.package,
                label: context.l10n.navOrders,
                route: AppRouter.orders,
              ),
              NavigationItem(
                icon: LucideIcons.user,
                activeIcon: LucideIcons.user,
                label: context.l10n.navProfile,
                route: AppRouter.profile,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
