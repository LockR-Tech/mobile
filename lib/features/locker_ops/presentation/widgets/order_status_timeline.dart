import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:smart_laundry_locker/features/locker_ops/data/locker_ops_service.dart';
import 'package:smart_laundry_locker/features/locker_ops/presentation/widgets/ops_widgets.dart';
import 'package:smart_laundry_locker/features/locker_ops/presentation/widgets/order_detail_widgets.dart';

/// Lịch sử chuyển trạng thái của một đơn, lấy từ `GET /api/orders/{id}/timeline`.
///
/// Chỉ hiển thị những gì ĐÃ xảy ra, không vẽ sẵn "các bước lẽ ra phải có": mỗi
/// loại đơn (gửi hàng, thuê ô, giao drone) đi một đường khác nhau nên một khung
/// bước cố định sẽ sai với phần lớn đơn.
///
/// Tự tải khi mở và cho bấm thử lại khi lỗi — người dùng mở bảng chi tiết là để
/// xem đơn, không nên vì một lần mạng chập mà mất luôn phần còn lại của bảng.
class OrderStatusTimeline extends StatefulWidget {
  const OrderStatusTimeline({
    super.key,
    required this.orderId,
    this.service,
    this.refreshToken,
  });

  final int orderId;
  final LockerOpsService? service;

  /// Đổi giá trị (vd. bản đơn vừa tải lại) ⇒ tải lại lịch sử. Trước đây nút
  /// "Tải lại" của bảng chi tiết không làm mới khối này (test 2026-10-29).
  final Object? refreshToken;

  @override
  State<OrderStatusTimeline> createState() => _OrderStatusTimelineState();
}

class _OrderStatusTimelineState extends State<OrderStatusTimeline> {
  late final LockerOpsService _service = widget.service ?? LockerOpsService();

  List<Map<String, dynamic>>? _events;
  bool _loading = true;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant OrderStatusTimeline oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.orderId != widget.orderId ||
        !identical(oldWidget.refreshToken, widget.refreshToken)) {
      _load();
    }
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _failed = false;
    });
    try {
      final events = await _service.orderTimeline(widget.orderId);
      if (!mounted) return;
      setState(() {
        _events = events;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _failed = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Icon(LucideIcons.history, size: 16, color: opsMutedText),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'Lịch sử trạng thái',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: opsDark,
                ),
              ),
            ),
            if (!_loading)
              IconButton(
                onPressed: _load,
                icon: const Icon(LucideIcons.refreshCw, size: 15),
                color: opsMutedText,
                visualDensity: VisualDensity.compact,
                tooltip: 'Tải lại',
              ),
          ],
        ),
        const SizedBox(height: 4),
        if (_loading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 18),
            child: Center(
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          )
        else if (_failed)
          _TimelineMessage(
            text: 'Không tải được lịch sử trạng thái.',
            onRetry: _load,
          )
        else if ((_events ?? const []).isEmpty)
          const _TimelineMessage(text: 'Chưa có chuyển trạng thái nào.')
        else
          _TimelineList(events: _events!),
      ],
    );
  }
}

class _TimelineMessage extends StatelessWidget {
  const _TimelineMessage({required this.text, this.onRetry});

  final String text;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 12.5, color: opsMutedText),
            ),
          ),
          if (onRetry != null)
            TextButton(onPressed: onRetry, child: const Text('Thử lại')),
        ],
      ),
    );
  }
}

class _TimelineList extends StatelessWidget {
  const _TimelineList({required this.events});

  final List<Map<String, dynamic>> events;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < events.length; i++)
          _TimelineTile(
            event: events[i],
            isLast: i == events.length - 1,
            isLatest: i == events.length - 1,
          ),
      ],
    );
  }
}

class _TimelineTile extends StatelessWidget {
  const _TimelineTile({
    required this.event,
    required this.isLast,
    required this.isLatest,
  });

  final Map<String, dynamic> event;
  final bool isLast;
  final bool isLatest;

  @override
  Widget build(BuildContext context) {
    final newStatus = event['newStatus']?.toString();
    final oldStatus = event['oldStatus']?.toString();
    return OrderTimelineTile(
      title: statusLabel(newStatus),
      // Giờ:phút:giây theo giờ máy, cùng định dạng với các mốc thời gian khác.
      time: fmtDateTime(event['createdAt']),
      color: statusColor(newStatus),
      isLast: isLast,
      isLatest: isLatest,
      // Trạng thái trước đó giúp đọc được đơn đã đi qua đường nào, nhất là khi
      // có bước bị bỏ qua.
      subtitle: oldStatus != null && oldStatus.isNotEmpty
          ? 'Từ ${statusLabel(oldStatus)}'
          : null,
      note: event['note']?.toString(),
    );
  }
}
