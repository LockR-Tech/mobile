import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

/// Hiệu ứng nhẹ cho trang chủ. Luật chung để máy yếu không giật:
/// * mỗi hiệu ứng chỉ vẽ lại phần của nó (bọc `RepaintBoundary`), không dựng lại cây widget mỗi khung;
/// * ticker tự dừng khi trang bị che hoặc ở tab khác (`TickerMode`) và khi bật "Giảm chuyển động"
///   (`MediaQuery.disableAnimations`).

/// Dãy thẻ ngang tự trôi liên tục, nối vòng vô tận. Chạm/kéo ⇒ dừng để người dùng tự lướt,
/// thả tay [resumeAfter] thì trôi tiếp. Dãy ngắn hơn màn hình ⇒ đứng yên như danh sách thường.
class AutoScrollStrip extends StatefulWidget {
  const AutoScrollStrip({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    required this.itemWidth,
    required this.height,
    this.spacing = 14,
    this.padding = const EdgeInsets.symmetric(horizontal: 20),
    this.speed = 26,
    this.resumeAfter = const Duration(seconds: 3),
  });

  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;
  final double itemWidth;
  final double height;
  final double spacing;
  final EdgeInsets padding;

  /// Tốc độ trôi, điểm ảnh logic mỗi giây.
  final double speed;
  final Duration resumeAfter;

  @override
  State<AutoScrollStrip> createState() => _AutoScrollStripState();
}

class _AutoScrollStripState extends State<AutoScrollStrip>
    with SingleTickerProviderStateMixin {
  final ScrollController _controller = ScrollController();
  late final Ticker _ticker = createTicker(_onTick);
  Duration _last = Duration.zero;

  /// Mốc (theo đồng hồ ticker) được trôi lại sau khi thả tay; `Duration.zero` = đang chờ tick kế tiếp đặt mốc.
  Duration? _holdUntil;
  bool _touching = false;

  @override
  void dispose() {
    _ticker.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _onTick(Duration elapsed) {
    final dt =
        (elapsed - _last).inMicroseconds / Duration.microsecondsPerSecond;
    _last = elapsed;
    if (_touching || !_controller.hasClients) return;
    final hold = _holdUntil;
    if (hold != null) {
      if (hold == Duration.zero) {
        _holdUntil = elapsed + widget.resumeAfter;
        return;
      }
      if (elapsed < hold) return;
      _holdUntil = null;
    }
    // Bỏ qua khung bị trễ lớn (vừa quay lại từ tab khác) để không nhảy cóc.
    if (dt <= 0 || dt > 0.1) return;
    final position = _controller.position;
    if (position.isScrollingNotifier.value) return;
    _controller.jumpTo(position.pixels + widget.speed * dt);
  }

  void _syncTicker(bool shouldRun) {
    if (shouldRun && !_ticker.isActive) {
      _last = Duration.zero;
      _holdUntil = null; // mốc cũ tính theo đồng hồ của lần chạy trước
      _ticker.start();
    } else if (!shouldRun && _ticker.isActive) {
      _ticker.stop();
    }
  }

  void _hold() => _holdUntil = Duration.zero;

  @override
  Widget build(BuildContext context) {
    final n = widget.itemCount;
    final extent = widget.itemWidth + widget.spacing;
    return SizedBox(
      height: widget.height,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final contentWidth =
              n * extent - widget.spacing + widget.padding.horizontal;
          final loop = n > 1 && contentWidth > constraints.maxWidth;
          final animate = loop && !MediaQuery.disableAnimationsOf(context);
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _syncTicker(animate);
          });
          return Listener(
            onPointerDown: (_) => _touching = true,
            onPointerUp: (_) {
              _touching = false;
              _hold();
            },
            onPointerCancel: (_) {
              _touching = false;
              _hold();
            },
            child: ListView.builder(
              controller: _controller,
              scrollDirection: Axis.horizontal,
              padding: widget.padding,
              // Vòng lặp: danh sách không có cuối, phần tử thứ i là thẻ i % n.
              itemCount: loop ? null : n,
              itemExtent: extent,
              itemBuilder: (context, i) => Padding(
                padding: EdgeInsets.only(right: widget.spacing),
                child: RepaintBoundary(
                  child: widget.itemBuilder(context, i % n),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Nhấn giữ ⇒ thẻ co nhẹ lại, thả ra bật về. Chỉ chạy khi có ngón tay chạm.
class PressScale extends StatefulWidget {
  const PressScale({super.key, required this.child, this.scale = 0.96});

  final Widget child;
  final double scale;

  @override
  State<PressScale> createState() => _PressScaleState();
}

class _PressScaleState extends State<PressScale> {
  bool _down = false;

  void _set(bool down) {
    if (_down != down) setState(() => _down = down);
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => _set(true),
      onPointerUp: (_) => _set(false),
      onPointerCancel: (_) => _set(false),
      // Kéo ngang để lướt dãy thẻ thì thôi co.
      onPointerMove: (e) {
        if (e.delta.distanceSquared > 4) _set(false);
      },
      child: AnimatedScale(
        scale: _down ? widget.scale : 1,
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}

/// Khối chờ tải có vệt sáng chạy ngang (thay cho khối xám đứng yên).
class ShimmerBox extends StatefulWidget {
  const ShimmerBox({
    super.key,
    this.width,
    required this.height,
    this.radius = 20,
    this.baseColor,
  });

  final double? width;
  final double height;
  final double radius;
  final Color? baseColor;

  @override
  State<ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<ShimmerBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1300),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _c.stop();
    } else if (!_c.isAnimating) {
      _c.repeat();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final base =
        widget.baseColor ??
        (dark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0));
    final glow = dark ? const Color(0xFF334155) : const Color(0xFFF8FAFC);
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) {
          final t =
              _c.value * 3 -
              1; // -1 → 2: vệt sáng đi từ ngoài trái qua hết bên phải
          return Container(
            width: widget.width,
            height: widget.height,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(widget.radius),
              gradient: LinearGradient(
                begin: Alignment(t - 1, -0.3),
                end: Alignment(t + 1, 0.3),
                colors: [base, glow, base],
                stops: const [0.35, 0.5, 0.65],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Vệt sáng chéo lướt qua [child] theo chu kỳ (lướt [sweep] rồi nghỉ). Chỉ lớp vệt sáng vẽ lại,
/// ảnh bên dưới giữ nguyên trong layer riêng.
class ShineSweep extends StatefulWidget {
  const ShineSweep({
    super.key,
    required this.child,
    required this.borderRadius,
    this.sweep = const Duration(milliseconds: 1400),
    this.pause = const Duration(milliseconds: 3600),
  });

  final Widget child;
  final BorderRadius borderRadius;
  final Duration sweep;
  final Duration pause;

  @override
  State<ShineSweep> createState() => _ShineSweepState();
}

class _ShineSweepState extends State<ShineSweep>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: widget.sweep + widget.pause,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _c.stop();
    } else if (!_c.isAnimating) {
      _c.repeat();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sweepShare =
        widget.sweep.inMilliseconds /
        (widget.sweep + widget.pause).inMilliseconds;
    return Stack(
      fit: StackFit.passthrough,
      children: [
        RepaintBoundary(child: widget.child),
        Positioned.fill(
          child: IgnorePointer(
            child: RepaintBoundary(
              child: ClipRRect(
                borderRadius: widget.borderRadius,
                child: AnimatedBuilder(
                  animation: _c,
                  builder: (context, _) {
                    final p = _c.value / sweepShare;
                    if (p >= 1) return const SizedBox.expand();
                    final x = Curves.easeInOut.transform(p) * 3.2 - 1.6;
                    return DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment(x - 0.6, -1),
                          end: Alignment(x + 0.6, 1),
                          colors: [
                            Colors.white.withValues(alpha: 0),
                            Colors.white.withValues(alpha: 0.24),
                            Colors.white.withValues(alpha: 0),
                          ],
                          stops: const [0.3, 0.5, 0.7],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
