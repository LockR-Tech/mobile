import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Artificial horizon (attitude indicator) HUD element. Draws a sky/ground
/// sphere rotated by [roll] and pitched by [pitch] (both radians), with a fixed
/// aircraft reference and a pitch ladder — the same readout a pilot uses to fly
/// the drone by instruments.
class AttitudeIndicator extends StatelessWidget {
  const AttitudeIndicator({
    required this.roll,
    required this.pitch,
    this.size = 200,
    super.key,
  });

  final double roll;
  final double pitch;
  final double size;

  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: CustomPaint(
        size: Size.square(size),
        painter: _AttitudePainter(roll: roll, pitch: pitch),
      ),
    );
  }
}

class _AttitudePainter extends CustomPainter {
  _AttitudePainter({required this.roll, required this.pitch});

  final double roll;
  final double pitch;

  static const _sky = Color(0xFF3A7BD5);
  static const _ground = Color(0xFF8A5A2B);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    const pxPerDeg = 3.2;
    final pitchDeg = pitch * 180 / math.pi;

    canvas.save();
    canvas.clipRect(Offset.zero & size);
    canvas.translate(center.dx, center.dy);
    canvas.rotate(-roll);
    canvas.translate(0, pitchDeg * pxPerDeg);

    final big = radius * 4;
    // Sky and ground halves.
    canvas.drawRect(
      Rect.fromLTRB(-big, -big, big, 0),
      Paint()..color = _sky,
    );
    canvas.drawRect(
      Rect.fromLTRB(-big, 0, big, big),
      Paint()..color = _ground,
    );
    // Horizon line.
    canvas.drawLine(
      Offset(-big, 0),
      Offset(big, 0),
      Paint()
        ..color = Colors.white
        ..strokeWidth = 2,
    );

    // Pitch ladder every 10°.
    final ladder = Paint()
      ..color = Colors.white70
      ..strokeWidth = 1.5;
    for (var deg = -30; deg <= 30; deg += 10) {
      if (deg == 0) continue;
      final y = -deg * pxPerDeg;
      final half = deg.abs() == 10 ? 24.0 : 16.0;
      canvas.drawLine(Offset(-half, y), Offset(half, y), ladder);
      _label(canvas, '${deg.abs()}', Offset(-half - 18, y));
      _label(canvas, '${deg.abs()}', Offset(half + 4, y));
    }
    canvas.restore();

    // Fixed roll arc + ticks.
    final arcPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - 6),
      math.pi + math.pi / 6,
      math.pi * 2 / 3,
      false,
      arcPaint,
    );
    for (final t in [-60, -45, -30, -15, 0, 15, 30, 45, 60]) {
      final a = -math.pi / 2 + t * math.pi / 180;
      final r1 = radius - 6;
      final r2 = radius - (t % 30 == 0 ? 16 : 11);
      canvas.drawLine(
        center + Offset(math.cos(a) * r1, math.sin(a) * r1),
        center + Offset(math.cos(a) * r2, math.sin(a) * r2),
        arcPaint,
      );
    }

    // Roll pointer (triangle) rotated by current roll.
    final pointer = Paint()..color = const Color(0xFFFFC107);
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(-roll);
    final path = Path()
      ..moveTo(0, -radius + 6)
      ..lineTo(-7, -radius + 20)
      ..lineTo(7, -radius + 20)
      ..close();
    canvas.drawPath(path, pointer);
    canvas.restore();

    // Fixed aircraft reference (wings + dot).
    final ac = Paint()
      ..color = const Color(0xFFFFC107)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(center + const Offset(-40, 0), center + const Offset(-14, 0), ac);
    canvas.drawLine(center + const Offset(14, 0), center + const Offset(40, 0), ac);
    canvas.drawCircle(center, 3, ac);
  }

  void _label(Canvas canvas, String text, Offset at) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(color: Colors.white, fontSize: 9),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, at - Offset(0, tp.height / 2));
  }

  @override
  bool shouldRepaint(_AttitudePainter old) =>
      old.roll != roll || old.pitch != pitch;
}
