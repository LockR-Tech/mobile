import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:smart_laundry_locker/features/locker_ops/data/locker_ops_service.dart';
import 'package:smart_laundry_locker/features/locker_ops/presentation/widgets/ops_widgets.dart';
import 'package:smart_laundry_locker/shared/widgets/controller_disposer.dart';
import 'package:smart_laundry_locker/core/l10n/l10n.dart';

/// Loại khiếu nại gửi lên `POST /api/orders/{id}/complaint` (server lưu viết hoa,
/// không giới hạn danh sách) kèm nhãn hiển thị.
Map<String, String> get orderComplaintTypes => <String, String>{
  'DAMAGED': L10n.current.fbDamaged,
  'MISSING': L10n.current.fbMissing,
  'LOCKER': L10n.current.fbLocker,
  'PAYMENT': L10n.current.fbPayment,
  'SERVICE': L10n.current.fbService,
  'OTHER': L10n.current.enumOther,
};

String orderComplaintTypeLabel(String? type) =>
    orderComplaintTypes[(type ?? '').toUpperCase()] ?? L10n.current.enumOther;

String orderComplaintStatusLabel(String? status) =>
    switch ((status ?? '').toUpperCase()) {
      'OPEN' || 'PENDING' || 'NEW' => L10n.current.fbStPending,
      'IN_PROGRESS' || 'PROCESSING' => L10n.current.fbStProcessing,
      'RESOLVED' || 'CLOSED' => L10n.current.fbStResolved,
      'REJECTED' => L10n.current.fbStRejected,
      _ => L10n.current.fbStRecorded,
    };

/// "Đánh giá / Khiếu nại" trong chi tiết đơn: đánh giá chỉ cho đơn hoàn tất,
/// khiếu nại cho đơn hoàn tất hoặc đã huỷ. Lỗi tải không chặn chi tiết đơn.
class OrderFeedbackSection extends StatefulWidget {
  const OrderFeedbackSection({
    super.key,
    required this.orderId,
    required this.status,
    this.service,
  });

  final int orderId;
  final String status;
  final LockerOpsService? service;

  static bool appliesTo(String status) {
    final s = status.toUpperCase();
    return s == 'COMPLETED' || s == 'CANCELED';
  }

  @override
  State<OrderFeedbackSection> createState() => _OrderFeedbackSectionState();
}

class _OrderFeedbackSectionState extends State<OrderFeedbackSection> {
  late final LockerOpsService _service = widget.service ?? LockerOpsService();
  Map<String, dynamic>? _rating;
  List<Map<String, dynamic>> _complaints = const [];
  bool _loading = true;
  bool _unavailable = false;
  String? _error;

  bool get _canRate => widget.status.toUpperCase() == 'COMPLETED';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    Map<String, dynamic>? rating;
    var complaints = const <Map<String, dynamic>>[];
    var unavailable = false;
    String? error;
    if (_canRate) {
      try {
        rating = await _service.orderRating(widget.orderId);
      } catch (e) {
        if (LockerOpsService.isEndpointUnavailable(e)) {
          unavailable = true;
        } else {
          error = LockerOpsService.errorMessage(e);
        }
      }
    }
    try {
      final mine = await _service.myOrderComplaints();
      complaints = mine
          .where((c) => '${c['orderId']}' == '${widget.orderId}')
          .toList(growable: false);
    } catch (e) {
      if (LockerOpsService.isEndpointUnavailable(e)) {
        unavailable = true;
      } else {
        error ??= LockerOpsService.errorMessage(e);
      }
    }
    if (!mounted) return;
    setState(() {
      _rating = rating;
      _complaints = complaints;
      _unavailable = unavailable;
      _error = error;
      _loading = false;
    });
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _rate() async {
    final current = _rating;
    var stars = (current?['rating'] as num?)?.toInt() ?? 5;
    final commentCtrl = TextEditingController(
      text: current?['comment']?.toString() ?? '',
    );
    var sending = false;
    String? error;
    final done = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => ControllerDisposer(
        controllers: [commentCtrl],
        child: StatefulBuilder(
          builder: (ctx, setLocal) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            title: Text(context.l10n.fbRateOrder),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (var i = 1; i <= 5; i++)
                      IconButton(
                        tooltip: '$i sao',
                        onPressed: sending
                            ? null
                            : () => setLocal(() => stars = i),
                        icon: Icon(
                          i <= stars
                              ? Icons.star_rounded
                              : Icons.star_outline_rounded,
                          color: const Color(0xFFF59E0B),
                          size: 30,
                        ),
                      ),
                  ],
                ),
                TextField(
                  controller: commentCtrl,
                  enabled: !sending,
                  maxLines: 3,
                  maxLength: 500,
                  decoration: InputDecoration(
                    hintText: context.l10n.fbRateHint,
                  ),
                ),
                if (error != null)
                  Text(
                    error!,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFFDC2626),
                    ),
                  ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: sending ? null : () => Navigator.pop(ctx, false),
                child: Text(context.l10n.commonCancel),
              ),
              FilledButton(
                onPressed: sending
                    ? null
                    : () async {
                        setLocal(() {
                          sending = true;
                          error = null;
                        });
                        try {
                          await _service.rateOrder(
                            widget.orderId,
                            stars,
                            comment: commentCtrl.text,
                          );
                          if (ctx.mounted) Navigator.pop(ctx, true);
                        } catch (e) {
                          setLocal(() {
                            sending = false;
                            error = LockerOpsService.isEndpointUnavailable(e)
                                ? context.l10n.fbRateNotSupported
                                : LockerOpsService.errorMessage(e);
                          });
                        }
                      },
                child: Text(sending ? context.l10n.commonSending : context.l10n.urdSendRating),
              ),
            ],
          ),
        ),
      ),
    );
    if (done == true) {
      _snack(L10n.current.fbThanks);
      await _load();
    }
  }

  Future<void> _complain() async {
    var type = 'OTHER';
    final descCtrl = TextEditingController();
    var sending = false;
    String? error;
    final done = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => ControllerDisposer(
        controllers: [descCtrl],
        child: StatefulBuilder(
          builder: (ctx, setLocal) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            title: Text(context.l10n.fbComplain),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: type,
                    decoration: InputDecoration(labelText: context.l10n.fbIssue),
                    items: [
                      for (final e in orderComplaintTypes.entries)
                        DropdownMenuItem(value: e.key, child: Text(e.value)),
                    ],
                    onChanged: sending
                        ? null
                        : (v) => setLocal(() => type = v ?? 'OTHER'),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: descCtrl,
                    enabled: !sending,
                    maxLines: 4,
                    maxLength: 1000,
                    decoration: InputDecoration(
                      hintText: context.l10n.fbIssueHint,
                    ),
                  ),
                  if (error != null)
                    Text(
                      error!,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFFDC2626),
                      ),
                    ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: sending ? null : () => Navigator.pop(ctx, false),
                child: Text(context.l10n.commonCancel),
              ),
              FilledButton(
                onPressed: sending
                    ? null
                    : () async {
                        if (descCtrl.text.trim().isEmpty) {
                          setLocal(() => error = context.l10n.fbDescribe);
                          return;
                        }
                        setLocal(() {
                          sending = true;
                          error = null;
                        });
                        try {
                          await _service.complainOrder(
                            widget.orderId,
                            description: descCtrl.text,
                            type: type,
                          );
                          if (ctx.mounted) Navigator.pop(ctx, true);
                        } catch (e) {
                          setLocal(() {
                            sending = false;
                            error = LockerOpsService.isEndpointUnavailable(e)
                                ? context.l10n.fbComplainNotSupported
                                : LockerOpsService.errorMessage(e);
                          });
                        }
                      },
                child: Text(sending ? context.l10n.commonSending : context.l10n.fbComplain),
              ),
            ],
          ),
        ),
      ),
    );
    if (done == true) {
      _snack(L10n.current.fbComplaintSent);
      await _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final rating = _rating;
    final stars = (rating?['rating'] as num?)?.toInt() ?? 0;
    final comment = rating?['comment']?.toString().trim();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Divider(height: 1, color: opsBorder),
        const SizedBox(height: 12),
        OpsSectionLabel(
          _canRate ? context.l10n.fbRateAndComplain : context.l10n.fbComplaint,
          icon: LucideIcons.messageSquare,
        ),
        if (_loading)
          const Padding(
            padding: EdgeInsets.all(12),
            child: Center(
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          )
        else ...[
          if (_canRate && rating != null)
            Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: opsSurface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: opsBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      for (var i = 1; i <= 5; i++)
                        Icon(
                          i <= stars
                              ? Icons.star_rounded
                              : Icons.star_outline_rounded,
                          size: 20,
                          color: const Color(0xFFF59E0B),
                        ),
                      const Spacer(),
                      TextButton(
                        onPressed: _rate,
                        child: Text(context.l10n.fbEditRating),
                      ),
                    ],
                  ),
                  if (comment != null && comment.isNotEmpty)
                    Text(
                      comment,
                      style: const TextStyle(fontSize: 13, color: opsDark),
                    ),
                ],
              ),
            )
          else if (_canRate && !_unavailable)
            OpsSheetAction(
              label: context.l10n.fbRateOrder,
              icon: LucideIcons.star,
              onTap: _rate,
            ),
          for (final c in _complaints)
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBEB),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFDE68A)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          orderComplaintTypeLabel(c['type']?.toString()),
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            color: Color(0xFF92400E),
                          ),
                        ),
                      ),
                      Text(
                        orderComplaintStatusLabel(c['status']?.toString()),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFB45309),
                        ),
                      ),
                    ],
                  ),
                  if ('${c['description'] ?? ''}'.trim().isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      '${c['description']}'.trim(),
                      style: const TextStyle(fontSize: 12.5, color: opsDark),
                    ),
                  ],
                  if (c['createdAt'] != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      context.l10n.fbSentAt(fmtDateTime(c['createdAt'])),
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: opsMutedText,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          if (!_unavailable)
            OpsSheetAction(
              label: context.l10n.fbComplain,
              icon: LucideIcons.messageSquareWarning,
              onTap: _complain,
            ),
          if (_unavailable)
            Text(
              context.l10n.fbNotSupported,
              style: TextStyle(fontSize: 12, color: opsMutedText),
            )
          else if (_error != null)
            Row(
              children: [
                Expanded(
                  child: Text(
                    _error!,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFFDC2626),
                    ),
                  ),
                ),
                TextButton(onPressed: _load, child: Text(context.l10n.commonRetry)),
              ],
            ),
        ],
      ],
    );
  }
}
