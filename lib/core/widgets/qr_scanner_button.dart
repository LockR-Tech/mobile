import 'dart:math' as math;
import 'package:smart_laundry_locker/core/theme/shadcn_theme.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

class QrScannerButton extends StatefulWidget {
  final VoidCallback onTap;
  final bool isActive;

  const QrScannerButton({
    super.key,
    required this.onTap,
    this.isActive = false,
  });

  @override
  State<QrScannerButton> createState() => _QrScannerButtonState();
}

class _QrScannerButtonState extends State<QrScannerButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  late final Animation<double> _scanLineScale;
  late final Animation<double> _qrCodeScale;
  late final Animation<double> _rotation;
  late final Animation<double> _slide;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat();

    // 2s pause (weight 40 = 2s/5s), 0.5s transition (weight 10 = 0.5s/5s)
    _scanLineScale = TweenSequence<double>([
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 10),
      TweenSequenceItem(tween: ConstantTween(0.0), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 10),
    ]).animate(_controller);

    _qrCodeScale = TweenSequence<double>([
      TweenSequenceItem(tween: ConstantTween(0.0), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 10),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 10),
    ]).animate(_controller);

    _rotation = TweenSequence<double>([
      TweenSequenceItem(tween: ConstantTween(0.0), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 10),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 2.0), weight: 10),
    ]).animate(_controller);

    // Slide animation going up and down over the button vertically over the 2s active windows
    _slide = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 20),
      TweenSequenceItem(tween: ConstantTween(0.0), weight: 10), // transition
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 20),
      TweenSequenceItem(tween: ConstantTween(0.0), weight: 10), // transition
    ]).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return SizedBox(
            width: 84,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AISLShadcnTheme.navyPrimary,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AISLShadcnTheme.navyPrimary.withOpacity(0.35),
                        blurRadius: 10,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Transform.rotate(
                          angle: _rotation.value * 2 * math.pi,
                          child: Transform.scale(
                            scale: _scanLineScale.value,
                            child: const Icon(
                              LucideIcons.scanLine,
                              color: Colors.white,
                              size: 30,
                            ),
                          ),
                        ),
                        Transform.rotate(
                          angle: _rotation.value * 2 * math.pi,
                          child: Transform.scale(
                            scale: _qrCodeScale.value,
                            child: const Icon(
                              LucideIcons.qrCode,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                        ),
                        Positioned(
                          top: (56 + 2) * _slide.value - 2,
                          left: 0,
                          right: 0,
                          child: Container(
                            height: 2,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.8),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.white.withOpacity(0.5),
                                  blurRadius: 4,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'QR',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: widget.isActive
                        ? FontWeight.w700
                        : FontWeight.w600,
                    color: widget.isActive
                        ? AISLShadcnTheme.navyPrimary
                        : AISLShadcnTheme
                              .lightTheme
                              .colorScheme
                              .mutedForeground,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
