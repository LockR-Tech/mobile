import 'package:flutter/material.dart';
import 'package:smart_laundry_locker/core/utils/app_date_time.dart';
import 'package:smart_laundry_locker/features/drone_delivery/domain/entities/drone_delivery_stage.dart';
import 'package:smart_laundry_locker/features/drone_delivery/domain/entities/drone_labels.dart';

/// Một mốc phụ hiện dưới một chặng của timeline (vd "Thanh toán" dưới chặng chờ
/// tiếp nhận, "Người nhận lấy hàng" dưới chặng hàng vào ô).
class DroneTimelineDetail {
  const DroneTimelineDetail(this.label, this.at, {this.note});

  final String label;
  final DateTime? at;

  /// Dòng giải thích thêm, vd kênh đã gửi mã cho người nhận.
  final String? note;
}

/// Timeline dọc cho toàn bộ vòng đời giao drone theo order-based contract.
///
/// Mỗi chặng đã đạt hiện giờ đạt ngay trên tiêu đề, thời gian chuyển từ chặng
/// trước, và các mốc phụ của chặng đó — thay cho thẻ "Mốc thời gian" riêng.
class DroneDeliveryTimeline extends StatelessWidget {
  final DroneDeliveryStage stage;

  /// Thời điểm thực tế từng mốc đã đạt (lấy từ nhật ký hành trình). Mốc chưa
  /// tới thì không có trong map và không hiện giờ.
  final Map<DroneDeliveryStage, DateTime> stageTimes;

  /// Mốc phụ theo chặng; mốc chưa có giờ hiện "Chưa diễn ra".
  final Map<DroneDeliveryStage, List<DroneTimelineDetail>> stepDetails;

  /// Mốc "bây giờ" để tính đã ở chặng hiện tại bao lâu; null ⇒ `DateTime.now()`.
  final DateTime? now;

  const DroneDeliveryTimeline({
    super.key,
    required this.stage,
    this.stageTimes = const {},
    this.stepDetails = const {},
    this.now,
  });

  int get _activeIndex {
    if (stage.order >= 0) return stage.order;
    // Đã nhận hàng: mọi mốc đều xong.
    if (stage == DroneDeliveryStage.completed) {
      return DroneDeliveryStage.timeline.length;
    }
    // Huỷ/quá hạn/lỗi: dừng ở mốc xa nhất đã thực sự đạt, không tô xanh các
    // mốc chưa hề xảy ra.
    if (stage.isFailure && stageTimes.isNotEmpty) {
      var reached = 0;
      for (final step in stageTimes.keys) {
        if (step.order > reached) reached = step.order;
      }
      return reached;
    }
    if (stage.isDelayed) return DroneDeliveryStage.enRoute.order;
    if (stage.isFailure) return DroneDeliveryStage.readyForPickup.order;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    const steps = DroneDeliveryStage.timeline;
    final active = _activeIndex;
    final rows = <Widget>[];
    DateTime? previousAt;
    for (int i = 0; i < steps.length; i++) {
      final state = _stateFor(i, active);
      final reachedAt = state == _NodeState.pending ? null : stageTimes[steps[i]];
      // Chặng hiện tại còn đang diễn ra: đếm từ lúc vào chặng tới giờ. Chặng cuối
      // (hàng vào ô) là nơi chờ người nhận, không phải một chặng bay.
      final ongoing =
          state == _NodeState.current &&
          reachedAt != null &&
          !stage.isFailure &&
          steps[i] != DroneDeliveryStage.readyForPickup;
      rows.add(
        _TimelineRow(
          step: steps[i],
          isFirst: i == 0,
          isLast: i == steps.length - 1,
          state: state,
          reachedAt: reachedAt,
          sincePrevious: reachedAt != null && previousAt != null
              ? reachedAt.difference(previousAt)
              : null,
          inStageFor: ongoing ? (now ?? DateTime.now()).difference(reachedAt) : null,
          details: stepDetails[steps[i]] ?? const [],
          // Màu cảnh báo chỉ áp cho mốc active khi delayed/failed.
          overrideColor: (i == active && (stage.isDelayed || stage.isFailure))
              ? stage.color
              : null,
        ),
      );
      if (reachedAt != null) previousAt = reachedAt;
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: rows);
  }

  _NodeState _stateFor(int index, int active) {
    if (index < active) return _NodeState.done;
    if (index == active) {
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
  final DateTime? reachedAt;
  final Duration? sincePrevious;
  final Duration? inStageFor;
  final List<DroneTimelineDetail> details;
  final Color? overrideColor;

  const _TimelineRow({
    required this.step,
    required this.isFirst,
    required this.isLast,
    required this.state,
    this.reachedAt,
    this.sincePrevious,
    this.inStageFor,
    this.details = const [],
    this.overrideColor,
  });

  static const Color _navySecondary = Color(0xFF12355B);
  static const Color _green = Color(0xFF16A34A);
  static const Color _red = Color(0xFFDC2626);
  static const Color _gray = Color(0xFFCBD5E1);
  static const Color _timeBlue = Color(0xFF1E5A8A);

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
    final pending = state == _NodeState.pending;
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
                      : (pending ? _gray : color),
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
          // Nội dung mốc: giờ đạt nằm TRÊN tiêu đề để quét dọc timeline là thấy ngay.
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (reachedAt != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 2),
                      child: Text(
                        formatDateTimeVn(reachedAt),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: _timeBlue,
                        ),
                      ),
                    ),
                  Text(
                    step.title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: _isActive ? FontWeight.w800 : FontWeight.w600,
                      color: pending ? Colors.grey : const Color(0xFF0A2342),
                    ),
                  ),
                  if (sincePrevious != null || inStageFor != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 3),
                      child: Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          if (sincePrevious != null)
                            _Pill(
                              text:
                                  'Chuyển sau ${droneDurationLabel(sincePrevious!)}',
                              color: const Color(0xFF475569),
                            ),
                          if (inStageFor != null)
                            _Pill(
                              text:
                                  'Đã ở chặng này ${droneDurationLabel(inStageFor!)}',
                              color: _navySecondary,
                            ),
                        ],
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
                  for (final detail in details) _DetailLine(detail: detail),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(6),
    ),
    child: Text(
      text,
      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color),
    ),
  );
}

class _DetailLine extends StatelessWidget {
  const _DetailLine({required this.detail});

  final DroneTimelineDetail detail;

  @override
  Widget build(BuildContext context) {
    final at = detail.at;
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: '${detail.label}: ',
                  style: const TextStyle(color: Color(0xFF64748B)),
                ),
                TextSpan(
                  text: formatDateTimeVn(at, empty: 'Chưa diễn ra'),
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: at == null
                        ? const Color(0xFF94A3B8)
                        : const Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
            style: const TextStyle(fontSize: 12),
          ),
          if ((detail.note ?? '').isNotEmpty)
            Text(
              detail.note!,
              style: const TextStyle(fontSize: 11.5, color: Color(0xFF475569)),
            ),
        ],
      ),
    );
  }
}
