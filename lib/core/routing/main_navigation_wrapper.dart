import 'package:smart_laundry_locker/core/routing/app_router.dart';
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
    });
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
              const NavigationItem(
                icon: LucideIcons.house,
                activeIcon: LucideIcons.house,
                label: 'Trang chủ',
                route: AppRouter.home,
              ),
              const NavigationItem(
                icon: CustomIcons.drawer,
                activeIcon: CustomIcons.drawer,
                label: 'Tủ',
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
                label: 'Trợ lý AI',
                route: AppRouter.assistant,
                isProminent: true,
              ),
              const NavigationItem(
                icon: CustomIcons.package,
                activeIcon: CustomIcons.package,
                label: 'Đơn hàng',
                route: AppRouter.orders,
              ),
              const NavigationItem(
                icon: LucideIcons.user,
                activeIcon: LucideIcons.user,
                label: 'Hồ sơ',
                route: AppRouter.profile,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
