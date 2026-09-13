import 'package:flutter/material.dart';
import 'package:smart_laundry_locker/features/drone_delivery/domain/entities/drone_delivery_stage.dart';

/// Timeline dọc cho toàn bộ vòng đời giao drone theo order-based contract.
class DroneDeliveryTimeline extends StatelessWidget {
  final DroneDeliveryStage stage;

  const DroneDeliveryTimeline({super.key, required this.stage});

  int get _activeIndex {
    if (stage.order >= 0) return stage.order;
    if (stage.isDelayed) return DroneDeliveryStage.enRoute.order;
    if (stage.isFailure) return DroneDeliveryStage.readyForPickup.order;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    const steps = DroneDeliveryStage.timeline;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (int i = 0; i < steps.length; i++)
          _TimelineRow(
            step: steps[i],
            isFirst: i == 0,
            isLast: i == steps.length - 1,
            state: _stateFor(i),
            // Màu cảnh báo chỉ áp cho mốc active khi delayed/failed.
            overrideColor: (i == _activeIndex && (stage.isDelayed || stage.isFailure))
                ? stage.color
                : null,
          ),
      ],
    );
  }

  _NodeState _stateFor(int index) {
    if (index < _activeIndex) return _NodeState.done;
    if (index == _activeIndex) {
      return stage.isFailure ? _NodeState.failed : _NodeState.current;
    }
    return _NodeState.pending;
  }
}

enum _NodeState { done, current, failed, pending }

class _TimelineRow extends StatelessWidget {
  final DroneDeliveryStage step;
  final bool isFirst;
  final bool isLast;
  final _NodeState state;
  final Color? overrideColor;

  const _TimelineRow({
    required this.step,
    required this.isFirst,
    required this.isLast,
    required this.state,
    this.overrideColor,
  });

  static const Color _navySecondary = Color(0xFF12355B);
  static const Color _green = Color(0xFF16A34A);
  static const Color _red = Color(0xFFDC2626);
  static const Color _gray = Color(0xFFCBD5E1);

  Color get _nodeColor {
    if (overrideColor != null) return overrideColor!;
    switch (state) {
      case _NodeState.done:
        return _green;
      case _NodeState.current:
        return _navySecondary;
      case _NodeState.failed:
        return _red;
      case _NodeState.pending:
        return _gray;
    }
  }

  bool get _isActive => state == _NodeState.current || state == _NodeState.failed;

  @override
  Widget build(BuildContext context) {
    final color = _nodeColor;
    final iconData = state == _NodeState.done
        ? Icons.check
        : (state == _NodeState.failed ? Icons.close : step.icon);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Cột đường nối + node
          Column(
            children: [
              Expanded(
                child: Container(
                  width: 2,
                  color: isFirst
                      ? Colors.transparent
                      : (state == _NodeState.pending ? _gray : color),
                ),
              ),
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: _isActive ? color : color.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                  border: Border.all(color: color, width: 2),
                ),
                child: Icon(
                  iconData,
                  size: 18,
                  color: _isActive ? Colors.white : color,
                ),
              ),
              Expanded(
                child: Container(
                  width: 2,
                  color: isLast
                      ? Colors.transparent
                      : (state == _NodeState.done ? color : _gray),
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
          // Nội dung mốc
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    step.title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: _isActive ? FontWeight.w800 : FontWeight.w600,
                      color: state == _NodeState.pending
                          ? Colors.grey
                          : const Color(0xFF0A2342),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    step.body(null),
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
