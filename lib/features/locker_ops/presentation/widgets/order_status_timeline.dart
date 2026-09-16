import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:smart_laundry_locker/features/locker_ops/data/locker_ops_service.dart';
import 'package:smart_laundry_locker/features/locker_ops/presentation/widgets/ops_widgets.dart';

/// Lịch sử chuyển trạng thái của một đơn, lấy từ `GET /api/orders/{id}/timeline`.
///
/// Chỉ hiển thị những gì ĐÃ xảy ra, không vẽ sẵn "các bước lẽ ra phải có": mỗi
/// loại đơn (gửi hàng, thuê ô, giao drone) đi một đường khác nhau nên một khung
/// bước cố định sẽ sai với phần lớn đơn.
///
/// Tự tải khi mở và cho bấm thử lại khi lỗi — người dùng mở bảng chi tiết là để
/// xem đơn, không nên vì một lần mạng chập mà mất luôn phần còn lại của bảng.
class OrderStatusTimeline extends StatefulWidget {
  const OrderStatusTimeline({super.key, required this.orderId, this.service});

  final int orderId;
  final LockerOpsService? service;

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
    final note = event['note']?.toString();
    final color = statusColor(newStatus);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cột chấm + đường nối.
          Column(
            children: [
              Container(
                width: 11,
                height: 11,
                margin: const EdgeInsets.only(top: 4),
                decoration: BoxDecoration(
                  color: isLatest ? color : color.withValues(alpha: 0.30),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: color.withValues(alpha: isLatest ? 0.35 : 0.20),
                    width: 3,
                  ),
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(width: 2, color: opsBorder),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          statusLabel(newStatus),
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: isLatest
                                ? FontWeight.w800
                                : FontWeight.w700,
                            color: isLatest ? opsDark : const Color(0xFF475569),
                          ),
                        ),
                      ),
                      Text(
                        // Giờ:phút:giây theo giờ máy, cùng định dạng với các
                        // mốc thời gian khác trong app.
                        fmtDateTime(event['createdAt']),
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: opsMutedText,
                          fontFeatures: [FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
                  ),
                  // Trạng thái trước đó giúp đọc được đơn đã đi qua đường nào,
                  // nhất là khi có bước bị bỏ qua.
                  if (oldStatus != null && oldStatus.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 1),
                      child: Text(
                        'Từ ${statusLabel(oldStatus)}',
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: opsMutedText,
                        ),
                      ),
                    ),
                  if (note != null && note.trim().isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 3),
                      child: Text(
                        note.trim(),
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF475569),
                          height: 1.35,
                        ),
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
