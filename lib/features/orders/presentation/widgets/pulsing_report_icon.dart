import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class PulsingReportIcon extends StatefulWidget {
  final VoidCallback onPressed;

  const PulsingReportIcon({super.key, required this.onPressed});

  @override
  State<PulsingReportIcon> createState() => _PulsingReportIconState();
}

class _PulsingReportIconState extends State<PulsingReportIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.3,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(scale: _scaleAnimation.value, child: child);
      },
      child: IconButton(
        icon: const Icon(
          LucideIcons.triangleAlert,
          color: Colors.red,
          size: 24,
        ),
        onPressed: widget.onPressed,
        tooltip: 'Báo cáo sự cố',
      ),
    );
  }
}
