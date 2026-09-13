import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:smart_laundry_locker/core/theme/shadcn_theme.dart';

/// Marker drone trên live map: chấm tròn navy + icon máy bay xoay theo heading.
/// [headingDeg] = 0 là hướng Bắc; xoay theo chiều kim đồng hồ.
class DroneMarker extends StatelessWidget {
  final double headingDeg;
  final bool signalLost;

  const DroneMarker({
    super.key,
    required this.headingDeg,
    this.signalLost = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = signalLost
        ? const Color(0xFF94A3B8) // xám khi mất tín hiệu
        : AISLShadcnTheme.navyPrimary;
    return Transform.rotate(
      angle: headingDeg * math.pi / 180,
      child: Container(
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2.5),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.4),
              blurRadius: 8,
              spreadRadius: 1,
            ),
          ],
        ),
        padding: const EdgeInsets.all(7),
        child: const Icon(
          LucideIcons.navigation,
          color: Colors.white,
          size: 20,
        ),
      ),
    );
  }
}
