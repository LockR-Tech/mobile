import 'dart:ui';

import 'package:flutter/material.dart';
import 'user_ui_kit.dart';

/// Builder function for custom icons
typedef IconBuilder = Widget Function(Color color, double size);

/// Floating glass bottom navigation bar: frosted-glass pill with no labels,
/// a raised gradient QR action in the center, and a navy active icon.
class CustomBottomNavigationBar extends StatelessWidget {
  final int currentIndex;
  final void Function(int) onTap;
  final List<NavigationItem> items;

  const CustomBottomNavigationBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: SizedBox(
          height: 64,
          child: Stack(
            children: [
              // Background layer: blur + decoration (non-interactive)
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(26),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.30),
                        borderRadius: BorderRadius.circular(26),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.55),
                          width: 1.2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.10),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              // Interactive layer: buttons on top (receives all touches)
              Positioned.fill(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: items.asMap().entries.map((entry) {
                    final index = entry.key;
                    final item = entry.value;
                    final isActive = currentIndex == index;
                    if (item.isProminent) {
                      return _buildProminent(item, index);
                    }
                    return _buildItem(item, index, isActive);
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildItem(NavigationItem item, int index, bool isActive) {
    final color = isActive ? AislBrand.navy : const Color(0xFF9CA3AF);
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onTap(index),
        child: Center(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: BoxDecoration(
              color: isActive
                  ? Colors.white.withValues(alpha: 0.35)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(16),
            ),
            child: _buildIcon(isActive ? item.activeIcon : item.icon, color),
          ),
        ),
      ),
    );
  }

  Widget _buildProminent(NavigationItem item, int index) {
    return Expanded(
      child: Center(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => onTap(index),
          child: Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                border: Border.all(
                  color: const Color(0xFFE2E8F0),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.10),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Center(
                child: _buildIcon(item.icon, AislBrand.navy, size: 25),
              ),
            ),
          ),
        ),
      );
  }

  Widget _buildIcon(dynamic icon, Color color, {double size = 22}) {
    if (icon is IconData) {
      return Icon(icon, size: size, color: color);
    } else if (icon is IconBuilder) {
      return icon(color, size);
    }
    return SizedBox(width: size, height: size);
  }
}

/// Navigation item model for custom bottom navigation
class NavigationItem {
  final dynamic icon; // IconData or IconBuilder
  final dynamic activeIcon; // IconData or IconBuilder
  final String label;
  final String route;
  final bool isProminent;

  const NavigationItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.route,
    this.isProminent = false,
  }) : assert(
         (icon is IconData || icon is IconBuilder) &&
             (activeIcon is IconData || activeIcon is IconBuilder),
         'icon and activeIcon must be either IconData or IconData',
       );
}
