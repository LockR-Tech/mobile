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
              // Background layer: iPhone Liquid Glass (blur + multi-stop refraction gradient + specular highlight)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      // Ambient deep shadow
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.12),
                        blurRadius: 28,
                        offset: const Offset(0, 10),
                        spreadRadius: -2,
                      ),
                      // Upper ambient bounce
                      BoxShadow(
                        color: Colors.white.withValues(alpha: 0.40),
                        blurRadius: 10,
                        offset: const Offset(0, -1),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(28),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
                      child: Container(
                        decoration: BoxDecoration(
                          // High-luminance frosted liquid gradient
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Colors.white.withValues(alpha: 0.75),
                              Colors.white.withValues(alpha: 0.45),
                              Colors.white.withValues(alpha: 0.28),
                            ],
                            stops: const [0.0, 0.45, 1.0],
                          ),
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.85),
                            width: 1.3,
                          ),
                        ),
                        child: Stack(
                          children: [
                            // 1px specular light gleam on top edge like iPhone curved glass
                            Positioned(
                              top: 0,
                              left: 20,
                              right: 20,
                              height: 1.0,
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.transparent,
                                      Colors.white.withValues(alpha: 0.95),
                                      Colors.transparent,
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
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
    final color = isActive ? AislBrand.navy : const Color(0xFF64748B);
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onTap(index),
        child: Center(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: isActive
                  ? Colors.white.withValues(alpha: 0.65)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(18),
              border: isActive
                  ? Border.all(
                      color: Colors.white.withValues(alpha: 0.90),
                      width: 1.0,
                    )
                  : null,
              boxShadow: isActive
                  ? [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ]
                  : null,
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
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white,
                  Color(0xFFF8FAFC),
                ],
              ),
              border: Border.all(
                color: Colors.white,
                width: 2.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
                BoxShadow(
                  color: Colors.white.withValues(alpha: 0.90),
                  blurRadius: 6,
                  offset: const Offset(0, -1),
                ),
              ],
            ),
            child: Center(
              child: _buildIcon(item.icon, AislBrand.navy, size: 24),
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
