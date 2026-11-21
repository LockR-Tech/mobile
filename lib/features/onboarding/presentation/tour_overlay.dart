import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:smart_laundry_locker/core/l10n/l10n.dart';

import '../domain/tour_engine.dart';
import '../domain/tour_models.dart';
import 'tour_anchor.dart';

/// Lớp khoanh của hướng dẫn lần đầu (F3-G13): nền tối có khoét lỗ quanh phần tử, viền nổi, ô chú thích tự đổi phía
/// khi thiếu chỗ, tự cuộn tới phần tử, tự chuyển trang (`mobileRoute`), mở menu ngăn kéo (`openNav`).
/// Không thấy phần tử: bước `optional` bỏ qua lặng lẽ, bước thường hiện giữa màn hình kèm câu báo.
class TourOverlay extends StatefulWidget {
  const TourOverlay({
    super.key,
    required this.groups,
    required this.text,
    required this.onGroupDone,
    required this.onClose,
    this.navigate,
    this.findTimeout = const Duration(milliseconds: 1800),
  });

  final List<TourGroup> groups;
  final String Function(String key) text;
  final void Function(TourGroup group) onGroupDone;

  /// completed = đi hết mọi nhóm; false = đóng giữa chừng.
  final void Function(bool completed) onClose;
  final void Function(String route)? navigate;
  final Duration findTimeout;

  @override
  State<TourOverlay> createState() => _TourOverlayState();
}

enum _Phase { searching, show, center, missing }

class _TourOverlayState extends State<TourOverlay> {
  late final List<(TourGroup, List<TourStep>)> _plan = [
    for (final g in widget.groups)
      if (g.stepsFor('mobile').isNotEmpty) (g, g.stepsFor('mobile')),
  ];
  int _gi = 0;
  int _si = 0;
  int _dir = 1;
  int _token = 0;
  _Phase _phase = _Phase.searching;
  Rect? _rect;
  Timer? _track;
  final FocusNode _focus = FocusNode(debugLabel: 'tour-overlay');

  TourStep? get _step => _plan.isEmpty ? null : _plan[_gi].$2[_si];
  bool get _isFirst => _gi == 0 && _si == 0;

  @override
  void initState() {
    super.initState();
    if (_plan.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) => widget.onClose(true));
    } else {
      _enterStep();
    }
  }

  @override
  void dispose() {
    _token++;
    _track?.cancel();
    _focus.dispose();
    super.dispose();
  }

  void _next() {
    final steps = _plan[_gi].$2;
    if (_si + 1 < steps.length) {
      _go(_gi, _si + 1, 1);
      return;
    }
    widget.onGroupDone(_plan[_gi].$1);
    if (_gi + 1 < _plan.length) {
      _go(_gi + 1, 0, 1);
    } else {
      _token++;
      widget.onClose(true);
    }
  }

  void _prev() {
    if (_si > 0) {
      _go(_gi, _si - 1, -1);
    } else if (_gi > 0) {
      _go(_gi - 1, _plan[_gi - 1].$2.length - 1, -1);
    }
  }

  void _close() {
    _token++;
    widget.onClose(false);
  }

  void _go(int gi, int si, int dir) {
    setState(() {
      _gi = gi;
      _si = si;
      _dir = dir;
    });
    _enterStep();
  }

  Future<void> _enterStep() async {
    final token = ++_token;
    final step = _step!;
    _track?.cancel();
    setState(() {
      _phase = _Phase.searching;
      _rect = null;
    });
    if (step.mobileRoute != null) widget.navigate?.call(step.mobileRoute!);
    if (step.openNav) TourNav.openDrawer();
    final anchor = step.anchor;
    if (anchor == null) {
      setState(() => _phase = _Phase.center);
      _focus.requestFocus();
      return;
    }
    // Đếm lần thử (mỗi lần 100 ms) thay vì đồng hồ thật: đúng cả trong widget test (thời gian giả lập).
    final maxTries = (widget.findTimeout.inMilliseconds / 100).ceil();
    var tries = 0;
    while (mounted && token == _token) {
      if (TourAnchorRegistry.find(anchor) != null) {
        final ctx = TourAnchorRegistry.contextOf(anchor);
        if (ctx != null && ctx.mounted) {
          try {
            await Scrollable.ensureVisible(ctx, alignment: 0.5, duration: const Duration(milliseconds: 250));
          } catch (_) {
            // Không nằm trong vùng cuộn: giữ nguyên vị trí.
          }
        }
        if (!mounted || token != _token) return;
        _measure(anchor);
        setState(() => _phase = _Phase.show);
        _focus.requestFocus();
        _track = Timer.periodic(const Duration(milliseconds: 200), (_) => _measure(anchor));
        return;
      }
      if (++tries > maxTries) {
        if (resolveStep(step, false) == 'skip') {
          if (_dir == -1 && !_isFirst) {
            _prev();
          } else {
            _next();
          }
        } else {
          setState(() => _phase = _Phase.missing);
          _focus.requestFocus();
        }
        return;
      }
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }
  }

  void _measure(String anchor) {
    final ro = TourAnchorRegistry.find(anchor);
    if (ro == null || !mounted) return;
    final overlayBox = context.findRenderObject() as RenderBox?;
    final origin = ro.localToGlobal(Offset.zero, ancestor: overlayBox);
    final rect = (origin & ro.size).inflate(6);
    if (rect != _rect) setState(() => _rect = rect);
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent e) {
    if (e is! KeyDownEvent) return KeyEventResult.ignored;
    if (e.logicalKey == LogicalKeyboardKey.escape) {
      _close();
    } else if (e.logicalKey == LogicalKeyboardKey.arrowRight) {
      _next();
    } else if (e.logicalKey == LogicalKeyboardKey.arrowLeft) {
      _prev();
    } else {
      return KeyEventResult.ignored;
    }
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    final step = _step;
    if (step == null) return const SizedBox.shrink();
    final group = _plan[_gi].$1;
    final steps = _plan[_gi].$2;
    final l10n = context.l10n;
    final lastOfAll = _gi == _plan.length - 1 && _si == steps.length - 1;
    final lastOfGroup = _si == steps.length - 1;
    final theme = Theme.of(context);
    final hole = _phase == _Phase.show ? _rect : null;

    final card = Material(
      key: const ValueKey('tour-card'),
      color: theme.colorScheme.surface,
      elevation: 12,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.text('groups.${group.id}.title').toUpperCase(),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.text('steps.${step.id}.title'),
                          key: const ValueKey('tour-step-title'),
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
                ),
                IconButton(
                  key: const ValueKey('tour-close'),
                  tooltip: l10n.tourClose,
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.close_rounded, size: 20),
                  onPressed: _close,
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Text(
                widget.text('steps.${step.id}.body'),
                style: TextStyle(fontSize: 14, height: 1.4, color: theme.colorScheme.onSurfaceVariant),
              ),
            ),
            if (_phase == _Phase.missing)
              Container(
                key: const ValueKey('tour-missing'),
                margin: const EdgeInsets.only(top: 10, right: 8),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(l10n.tourMissing, style: const TextStyle(fontSize: 12.5, color: Color(0xFFB45309))),
              ),
            const SizedBox(height: 10),
            Text(
              l10n.tourProgress(_si + 1, steps.length, _gi + 1, _plan.length),
              style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 6),
            // Màn hẹp + nhãn dài ("Sang nhóm tiếp"): nút co lại, chữ xuống dòng thay vì tràn.
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Flexible(
                  child: TextButton(
                    key: const ValueKey('tour-prev'),
                    onPressed: _isFirst ? null : _prev,
                    child: Text(l10n.tourPrev, textAlign: TextAlign.center),
                  ),
                ),
                const SizedBox(width: 4),
                Flexible(
                  child: FilledButton(
                    key: const ValueKey('tour-next'),
                    onPressed: _next,
                    child: Text(
                      lastOfAll ? l10n.tourDone : (lastOfGroup ? l10n.tourNextGroup : l10n.tourNext),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
            ),
          ],
        ),
      ),
    );

    return Focus(
      focusNode: _focus,
      autofocus: true,
      onKeyEvent: _onKey,
      child: Stack(
        children: [
          // Chặn bấm vào trang phía sau.
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {},
              child: CustomPaint(painter: _SpotlightPainter(hole, theme.colorScheme.primary)),
            ),
          ),
          if (_phase != _Phase.searching)
            Positioned.fill(
              child: SafeArea(
                child: CustomSingleChildLayout(
                  delegate: _TipLayout(target: hole, placement: step.placement, inset: MediaQuery.paddingOf(context)),
                  child: card,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _SpotlightPainter extends CustomPainter {
  _SpotlightPainter(this.hole, this.ring);

  final Rect? hole;
  final Color ring;

  @override
  void paint(Canvas canvas, Size size) {
    final dim = Paint()..color = Colors.black.withValues(alpha: 0.55);
    final full = Path()..addRect(Offset.zero & size);
    final h = hole;
    if (h == null) {
      canvas.drawPath(full, dim);
      return;
    }
    final rr = RRect.fromRectAndRadius(h, const Radius.circular(12));
    canvas.drawPath(Path.combine(PathOperation.difference, full, Path()..addRRect(rr)), dim);
    canvas.drawRRect(
      rr,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..color = ring,
    );
  }

  @override
  bool shouldRepaint(_SpotlightPainter old) => old.hole != hole || old.ring != ring;
}

/// Đặt ô chú thích cạnh phần tử theo phía mong muốn; thiếu chỗ thì đổi phía, không tràn mép màn hình.
/// `target` theo toạ độ toàn màn hình; ô nằm trong SafeArea nên trừ phần `inset` (tai thỏ, thanh điều hướng).
class _TipLayout extends SingleChildLayoutDelegate {
  _TipLayout({required this.target, required this.placement, required this.inset});

  final Rect? target;
  final String placement;
  final EdgeInsets inset;
  static const _gap = 12.0;
  static const _pad = 12.0;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints c) =>
      BoxConstraints(maxWidth: math.min(360, c.maxWidth - _pad * 2), maxHeight: c.maxHeight - _pad * 2);

  @override
  Offset getPositionForChild(Size size, Size child) {
    final t = target?.shift(Offset(-inset.left, -inset.top));
    if (t == null) return Offset((size.width - child.width) / 2, (size.height - child.height) / 2);
    final below = size.height - t.bottom - _gap - _pad;
    final above = t.top - _gap - _pad;
    final right = size.width - t.right - _gap - _pad;
    final left = t.left - _gap - _pad;
    var side = placement == 'auto' ? 'bottom' : placement;
    if (side == 'right' && child.width > right) side = 'bottom';
    if (side == 'left' && child.width > left) side = 'bottom';
    if (side == 'bottom' && child.height > below && above > below) side = 'top';
    if (side == 'top' && child.height > above && below > above) side = 'bottom';
    double x;
    double y;
    switch (side) {
      case 'right':
        x = t.right + _gap;
        y = t.center.dy - child.height / 2;
      case 'left':
        x = t.left - _gap - child.width;
        y = t.center.dy - child.height / 2;
      case 'top':
        x = t.center.dx - child.width / 2;
        y = t.top - _gap - child.height;
      default:
        x = t.center.dx - child.width / 2;
        y = t.bottom + _gap;
    }
    final maxX = math.max(_pad, size.width - child.width - _pad);
    final maxY = math.max(_pad, size.height - child.height - _pad);
    return Offset(x.clamp(_pad, maxX), y.clamp(_pad, maxY));
  }

  @override
  bool shouldRelayout(_TipLayout old) =>
      old.target != target || old.placement != placement || old.inset != inset;
}
