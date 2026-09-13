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
  final Widget child;

  const MainNavigationWrapper({super.key, required this.child});

  @override
  State<MainNavigationWrapper> createState() => _MainNavigationWrapperState();
}

class _MainNavigationWrapperState extends State<MainNavigationWrapper> {
  bool _navVisible = true;

  void _onScroll(ScrollNotification notification) {
    if (notification is ScrollUpdateNotification) {
      final delta = notification.scrollDelta ?? 0;
      // Always show when at top
      if (notification.metrics.pixels <= 10) {
        if (!_navVisible) setState(() => _navVisible = true);
        return;
      }
      if (delta > 4 && _navVisible) {
        setState(() => _navVisible = false);
      } else if (delta < -4 && !_navVisible) {
        setState(() => _navVisible = true);
      }
    } else if (notification is ScrollEndNotification) {
      if (notification.metrics.pixels <= 10 && !_navVisible) {
        setState(() => _navVisible = true);
      }
    }
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
    final String location = GoRouterState.of(context).uri.path;
    if (location.startsWith(AppRouter.home)) return 0;
    if (location.startsWith(AppRouter.lockers)) return 1;
    if (location.startsWith(AppRouter.orders)) return 3;
    if (location.startsWith(AppRouter.profile)) return 4;
    return 0;
  }

  void _onItemTapped(int index) {
    switch (index) {
      case 0:
        context.go(AppRouter.home);
        break;
      case 1:
        context.go(AppRouter.lockers);
        break;
      case 2:
        context.push(AppRouter.qrScan);
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
        child: widget.child,
      ),
      bottomNavigationBar: AnimatedSlide(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeInOut,
        offset: _navVisible ? Offset.zero : const Offset(0, 1),
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 220),
          opacity: _navVisible ? 1.0 : 0.0,
          child: CustomBottomNavigationBar(
        currentIndex: _calculateSelectedIndex(context),
        onTap: _onItemTapped,
        items: const [
          NavigationItem(
            icon: LucideIcons.house,
            activeIcon: LucideIcons.house,
            label: 'Trang chủ',
            route: AppRouter.home,
          ),
          NavigationItem(
            icon: CustomIcons.drawer,
            activeIcon: CustomIcons.drawer,
            label: 'Tủ',
            route: AppRouter.lockers,
          ),
          NavigationItem(
            icon: LucideIcons.scanLine,
            activeIcon: LucideIcons.scanLine,
            label: 'Quét QR',
            route: AppRouter.qrScan,
            isProminent: true,
          ),
          NavigationItem(
            icon: CustomIcons.package,
            activeIcon: CustomIcons.package,
            label: 'Đơn hàng',
            route: AppRouter.orders,
          ),
          NavigationItem(
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
