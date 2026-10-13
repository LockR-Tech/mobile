import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:smart_laundry_locker/core/routing/app_router.dart';
import 'package:smart_laundry_locker/features/drone_delivery/domain/entities/drone_delivery_stage.dart';
import 'package:smart_laundry_locker/features/locker_ops/data/locker_ops_service.dart';
import 'package:smart_laundry_locker/features/locker_ops/data/order_milestone.dart';
import 'package:smart_laundry_locker/features/locker_ops/data/receiver_order.dart';
import 'package:smart_laundry_locker/features/locker_ops/data/receiver_order_detail.dart';
import 'package:smart_laundry_locker/features/locker_ops/presentation/widgets/ops_widgets.dart';
import 'package:smart_laundry_locker/features/locker_ops/presentation/widgets/order_detail_widgets.dart';
import 'package:smart_laundry_locker/features/locker_ops/presentation/widgets/receiver_order_card.dart';

/// Chi tiết một đơn phía người nhận ("Hàng chờ nhận") hoặc người lấy hộ ("Đơn
/// ủy quyền"): mã lấy hàng, người gửi, người nhận/ủy quyền, tủ & ô, kiện hàng,
/// thời gian, hành trình drone và sự cố.
///
/// Mở ngay bằng bản ghi của danh sách rồi tải bản đầy đủ từ
/// `GET /api/orders/incoming/{id}` (hoặc `/delegated-to-me/{id}`). Tải lỗi thì
/// vẫn hiện phần đã có, kèm thông báo và nút thử lại; kéo xuống để tải lại.
class ReceiverOrderDetailPage extends StatefulWidget {
  const ReceiverOrderDetailPage({
    super.key,
    required this.order,
    this.service,
    this.delegatedView = false,
  });

  final ReceiverOrder order;
  final LockerOpsService? service;

  /// Mở từ "Đơn ủy quyền" (mình là người lấy hộ).
  final bool delegatedView;

  static Future<void> open(
    BuildContext context, {
    required ReceiverOrder order,
    LockerOpsService? service,
    bool delegatedView = false,
  }) => Navigator.of(context).push<void>(
    MaterialPageRoute<void>(
      builder: (_) => ReceiverOrderDetailPage(
        order: order,
        service: service,
        delegatedView: delegatedView,
      ),
    ),
  );

  @override
  State<ReceiverOrderDetailPage> createState() =>
      _ReceiverOrderDetailPageState();
}

class _ReceiverOrderDetailPageState extends State<ReceiverOrderDetailPage> {
  late final LockerOpsService _service = widget.service ?? LockerOpsService();
  late ReceiverOrderDetail _detail = ReceiverOrderDetail.fromOrder(
    widget.order,
  );
  bool _loading = true;
  String? _error;

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
    try {
      final raw = await _service.receiverOrderDetail(
        widget.order.id,
        delegated: widget.delegatedView,
      );
      final parsed = ReceiverOrderDetail.tryParse(raw);
      if (!mounted) return;
      setState(() {
        if (parsed == null) {
          _error = 'Không đọc được chi tiết đơn. Vui lòng thử lại.';
        } else {
          _detail = parsed;
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = _errorText(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  static String _errorText(Object e) {
    if (e is DioException &&
        e.response?.statusCode == 404 &&
        LockerOpsService.errorCode(e) == 'NOT_FOUND') {
      return 'Đơn không còn trong danh sách của bạn (có thể đã được ủy quyền '
          'cho người khác). Đang hiện thông tin đã lưu.';
    }
    if (LockerOpsService.isEndpointUnavailable(e)) {
      return 'Máy chủ chưa hỗ trợ xem chi tiết đầy đủ — đang hiện thông tin '
          'tóm tắt.';
    }
    return LockerOpsService.errorMessage(e);
  }

  Future<void> _unlock() async {
    final opened = await openReceiverOrderBox(
      context,
      service: _service,
      order: _detail.order,
    );
    if (opened && mounted) await _load();
  }

  void _trackDrone() {
    final router = GoRouter.maybeOf(context);
    if (router == null) return;
    Navigator.of(context).pop();
    router.go(AppRouter.droneDeliveryTracking, extra: '${_detail.order.id}');
  }

  @override
  Widget build(BuildContext context) {
    final delegate = _detail.loaded
        ? _detail.isDelegateView
        : widget.delegatedView;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: opsDark,
        surfaceTintColor: Colors.white,
        elevation: 0,
        title: Text(
          delegate ? 'Chi tiết đơn lấy hộ' : 'Chi tiết đơn nhận',
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
        ),
        actions: [
          IconButton(
            onPressed: _loading ? null : _load,
            icon: const Icon(LucideIcons.refreshCw, size: 18),
            tooltip: 'Tải lại',
          ),
        ],
        bottom: _loading
            ? const PreferredSize(
                preferredSize: Size.fromHeight(2),
                child: LinearProgressIndicator(minHeight: 2),
              )
            : null,
      ),
      body: RefreshIndicator(
        color: opsDark,
        onRefresh: _load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
          children: [
            if (_error != null) ...[
              _ErrorBanner(text: _error!, onRetry: _load),
              const SizedBox(height: 14),
            ],
            _Header(detail: _detail, delegate: delegate),
            const SizedBox(height: 18),
            ..._sections(delegate),
          ],
        ),
      ),
    );
  }

  List<Widget> _sections(bool delegate) {
    final d = _detail;
    final o = d.order;
    final finished = o.isFinished || o.status == 'EXPIRED';
    final hasLocation =
        (o.lockerLatitude != null && o.lockerLongitude != null) ||
        (o.lockerAddress ?? '').isNotEmpty;
    final ownerTitle = delegate ? 'Người ủy quyền' : 'Người gửi';

    return [
      // 2. Mã lấy hàng + thao tác của thẻ.
      OrderDetailSection(
        title: 'Mã lấy hàng',
        icon: LucideIcons.keyRound,
        footer: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _pickupCodeBlock(delegate),
            const SizedBox(height: 12),
            if (o.canUnlockWithCode)
              OpsSheetAction(
                label: 'Mở ${o.boxLabel} lấy hàng',
                icon: LucideIcons.doorOpen,
                primary: true,
                onTap: _unlock,
              ),
            if (hasLocation && !finished)
              OpsSheetAction(
                label: 'Chỉ đường tới tủ',
                icon: LucideIcons.map,
                onTap: () => openReceiverOrderDirections(context, o),
              ),
            if (d.droneTrackingAvailable)
              OpsSheetAction(
                label: 'Theo dõi drone',
                icon: LucideIcons.navigation,
                onTap: _trackDrone,
              ),
          ],
        ),
      ),

      // 3. Người gửi / người ủy quyền.
      OrderDetailSection(
        title: ownerTitle,
        icon: LucideIcons.user,
        rows: [
          if ((o.senderName ?? '').isNotEmpty)
            OpsInfoRow(
              icon: LucideIcons.user,
              label: 'Họ tên',
              value: o.senderName!,
            ),
          if (d.senderPhone != null)
            OrderContactRow(
              icon: LucideIcons.phone,
              label: 'SĐT người gửi',
              value: d.senderPhone!,
              phone: true,
            ),
          if (d.senderEmail != null)
            OrderContactRow(
              icon: LucideIcons.mail,
              label: 'Email người gửi',
              value: d.senderEmail!,
            ),
        ],
      ),

      // 4. Người nhận & ủy quyền.
      OrderDetailSection(
        title: 'Người nhận',
        icon: LucideIcons.userCheck,
        rows: [
          if ((o.receiverName ?? '').isNotEmpty)
            OpsInfoRow(
              icon: LucideIcons.userCheck,
              label: 'Tên người nhận',
              value: o.receiverName!,
            ),
          if ((o.receiverPhone ?? '').isNotEmpty)
            OrderContactRow(
              icon: LucideIcons.phone,
              label: 'SĐT người nhận',
              value: o.receiverPhone!,
              phone: true,
            ),
          if (d.receiverEmail != null)
            OrderContactRow(
              icon: LucideIcons.mail,
              label: 'Email người nhận',
              value: d.receiverEmail!,
            ),
          if (d.deliveryAddress != null)
            OpsInfoRow(
              icon: LucideIcons.truck,
              label: 'Địa chỉ giao',
              value: d.deliveryAddress!,
            ),
          if (delegate) ...[
            OpsInfoRow(
              icon: LucideIcons.userPlus,
              label: 'Người lấy hộ',
              value: (o.delegateName ?? '').isNotEmpty
                  ? '${o.delegateName} (bạn)'
                  : 'Bạn',
            ),
            if (d.delegatePhone != null)
              OpsInfoRow(
                icon: LucideIcons.smartphone,
                label: 'SĐT lấy hộ',
                value: d.delegatePhone!,
              ),
            if ((o.delegateNote ?? '').isNotEmpty)
              OpsInfoRow(
                icon: LucideIcons.stickyNote,
                label: 'Lời nhắn',
                value: o.delegateNote!,
              ),
          ] else if (o.delegated)
            const OpsInfoRow(
              icon: LucideIcons.userPlus,
              label: 'Ủy quyền',
              value: 'Chủ đơn đã ủy quyền người khác lấy hộ',
              valueColor: Color(0xFF7C3AED),
            ),
          if (o.delegatedAt != null)
            OpsInfoRow(
              icon: LucideIcons.clock,
              label: 'Ủy quyền lúc',
              value: fmtDateTime(o.delegatedAt),
            ),
        ],
      ),

      // 5. Tủ & ô.
      OrderDetailSection(
        title: 'Tủ & ô',
        icon: LucideIcons.warehouse,
        rows: [
          OpsInfoRow(
            icon: LucideIcons.warehouse,
            label: d.isDrone ? 'Tủ nhận' : 'Tủ',
            value: o.lockerName ?? 'Tủ Lock.R',
          ),
          if ((o.lockerCode ?? '').isNotEmpty)
            OpsInfoRow(
              icon: LucideIcons.hash,
              label: 'Mã tủ',
              value: o.lockerCode!,
            ),
          if ((o.lockerAddress ?? '').isNotEmpty)
            OpsInfoRow(
              icon: LucideIcons.mapPin,
              label: 'Địa điểm',
              value: o.lockerAddress!,
            ),
          if (o.boxNumber != null)
            OpsInfoRow(
              icon: LucideIcons.grid3x3,
              label: 'Ô',
              value: 'Ô số ${o.boxNumber}',
            ),
          if (d.boxSize != null)
            OpsInfoRow(
              icon: LucideIcons.box,
              label: 'Kích cỡ ô',
              value: boxSizeLabel(d.boxSize),
            ),
          if (d.boxType != null)
            OpsInfoRow(
              icon: LucideIcons.layoutGrid,
              label: 'Loại ô',
              value: boxTypeLabel(d.boxType),
            ),
          if (d.sourceLockerName != null || d.sourceLockerCode != null)
            OpsInfoRow(
              icon: LucideIcons.planeTakeoff,
              label: 'Gửi từ tủ',
              value: [
                d.sourceLockerName ?? 'Tủ Lock.R',
                if (d.sourceLockerCode != null) '(${d.sourceLockerCode})',
              ].join(' '),
            ),
          if (d.sourceLockerAddress != null)
            OpsInfoRow(
              icon: LucideIcons.mapPinned,
              label: 'Địa chỉ tủ gửi',
              value: d.sourceLockerAddress!,
            ),
          if (d.routeDistanceMeters != null)
            OpsInfoRow(
              icon: LucideIcons.route,
              label: 'Quãng đường bay',
              value: fmtDistanceMeters(d.routeDistanceMeters!),
            ),
        ],
      ),

      // 6. Kiện hàng.
      OrderDetailSection(
        title: 'Kiện hàng',
        icon: LucideIcons.package,
        rows: [
          ...orderParcelRows(d.parcel),
          if (d.customerNote != null)
            OpsInfoRow(
              icon: LucideIcons.stickyNote,
              label: 'Ghi chú người gửi',
              value: d.customerNote!,
            ),
        ],
      ),

      // 7. Thời gian.
      OrderDetailSection(
        title: 'Thời gian',
        icon: LucideIcons.clock,
        rows: [
          if (o.pickupDeadline != null)
            OpsInfoRow(
              icon: LucideIcons.clock,
              label: 'Hạn lấy',
              value: fmtDateTime(o.pickupDeadline),
              valueColor: o.overdue && !finished
                  ? const Color(0xFFDC2626)
                  : null,
            ),
          if (o.pickupDeadline != null && !finished)
            OpsInfoRow(
              icon: LucideIcons.hourglass,
              label: o.overdue ? 'Đã quá hạn' : 'Còn lại',
              value: fmtRemaining(o.pickupDeadline)
                  .replaceFirst('Còn ', '')
                  .replaceFirst('Quá hạn ', ''),
              valueColor: o.overdue
                  ? const Color(0xFFDC2626)
                  : const Color(0xFF15803D),
            ),
          if (d.intendedReceiveAt != null)
            OpsInfoRow(
              icon: LucideIcons.calendarClock,
              label: 'Dự kiến lấy',
              value: fmtDateTime(d.intendedReceiveAt),
            ),
          if (d.rentalDurationHours != null)
            OpsInfoRow(
              icon: LucideIcons.timer,
              label: 'Thời gian thuê',
              value: '${d.rentalDurationHours} giờ',
            ),
          if (o.createdAt != null)
            OpsInfoRow(
              icon: LucideIcons.calendar,
              label: 'Tạo đơn lúc',
              value: fmtDateTime(o.createdAt),
            ),
          if (o.paymentStatus != null)
            OpsInfoRow(
              icon: LucideIcons.wallet,
              label: 'Thanh toán',
              value: _paymentLabel(o.paymentStatus!),
            ),
          if (d.paidAt != null)
            OpsInfoRow(
              icon: LucideIcons.receiptText,
              label: 'Thanh toán lúc',
              value: fmtDateTime(d.paidAt),
            ),
          if (o.completedAt != null)
            OpsInfoRow(
              icon: LucideIcons.circleCheck,
              label: 'Hoàn tất lúc',
              value: fmtDateTime(o.completedAt),
              valueColor: const Color(0xFF15803D),
            ),
          if (d.updatedAt != null)
            OpsInfoRow(
              icon: LucideIcons.refreshCw,
              label: 'Cập nhật lần cuối',
              value: fmtDateTime(d.updatedAt),
            ),
        ],
      ),
      OrderDetailSection(
        title: 'Dòng thời gian',
        icon: LucideIcons.history,
        footer: d.timeline.isEmpty
            ? null
            : OrderMilestoneTimeline(milestones: d.timeline),
      ),

      // 8. Drone.
      if (d.isDrone)
        OrderDetailSection(
          title: 'Hành trình drone',
          icon: LucideIcons.plane,
          rows: [
            if ((o.deliveryStage ?? '').isNotEmpty)
              OpsInfoRow(
                icon: DroneDeliveryStage.fromRaw(o.deliveryStage).icon,
                label: 'Chặng hiện tại',
                value: DroneDeliveryStage.fromRaw(o.deliveryStage).title,
              ),
            if (d.etaMinutes != null)
              OpsInfoRow(
                icon: LucideIcons.timer,
                label: 'Dự kiến tới tủ',
                value: d.etaMinutes == 0
                    ? 'Đã tới'
                    : 'Khoảng ${d.etaMinutes} phút',
              ),
          ],
          footer: d.journey.isEmpty
              ? null
              : OrderMilestoneTimeline(
                  milestones: [
                    for (final step in d.journey)
                      OrderMilestone(
                        code: step.toStage,
                        label: DroneDeliveryStage.fromRaw(step.toStage).title,
                        occurredAt: step.at,
                      ),
                  ],
                  colorOf: (code) => DroneDeliveryStage.fromRaw(code).color,
                ),
        ),

      // 9. Sự cố / giao không hoàn tất.
      OrderDetailSection(
        title: 'Sự cố',
        icon: LucideIcons.triangleAlert,
        rows: [
          if (d.deliveryBlockReasonLabel != null)
            OpsInfoRow(
              icon: LucideIcons.circlePause,
              label: 'Đang tạm dừng',
              value: d.deliveryBlockReasonLabel!,
              valueColor: const Color(0xFFEA580C),
            ),
          if (d.deliveryBlockedAt != null)
            OpsInfoRow(
              icon: LucideIcons.clock,
              label: 'Tạm dừng lúc',
              value: fmtDateTime(d.deliveryBlockedAt),
            ),
          if (d.failureReasonLabel != null)
            OpsInfoRow(
              icon: LucideIcons.circleX,
              label: 'Giao không hoàn tất',
              value: d.failureReasonLabel!,
              valueColor: const Color(0xFFDC2626),
            ),
          if (d.failedAt != null)
            OpsInfoRow(
              icon: LucideIcons.clock,
              label: 'Ghi nhận lúc',
              value: fmtDateTime(d.failedAt),
            ),
          if (d.parcelReturnedAt != null)
            OpsInfoRow(
              icon: LucideIcons.undo2,
              label: 'Đã trả kiện cho người gửi',
              value: fmtDateTime(d.parcelReturnedAt),
            ),
        ],
      ),
    ];
  }

  Widget _pickupCodeBlock(bool delegate) {
    final o = _detail.order;
    if (!delegate && o.delegated && !o.isFinished) {
      return const OpsBanner(
        tone: OpsBannerTone.info,
        icon: LucideIcons.userCheck,
        text:
            'Chủ đơn đã ủy quyền người khác lấy hộ nên mã lấy hàng không còn '
            'hiện ở đây.',
      );
    }
    if (o.isActive && (o.pickupPin ?? '').isNotEmpty) {
      return Column(
        children: [
          AccessCredentials(
            pin: o.pickupPin,
            qrToken: o.qrToken,
            showQr: (o.qrToken ?? '').isNotEmpty,
            caption: 'Nhập PIN hoặc quét QR tại tủ, hoặc mở ô ngay trên app',
          ),
          if (o.overdue) ...[
            const SizedBox(height: 10),
            const OpsBanner(
              tone: OpsBannerTone.danger,
              icon: LucideIcons.triangleAlert,
              text: 'Đơn đã quá hạn lấy — có thể phát sinh phí quá giờ.',
            ),
          ],
        ],
      );
    }
    return switch (o.status) {
      'COMPLETED' => OpsBanner(
        tone: OpsBannerTone.success,
        icon: LucideIcons.circleCheck,
        text: o.completedAt == null
            ? 'Đơn đã hoàn tất — hàng đã được lấy.'
            : 'Đơn đã hoàn tất — hàng đã được lấy lúc '
                  '${fmtDateTime(o.completedAt)}.',
      ),
      'CANCELED' || 'CANCELLED' => const OpsBanner(
        tone: OpsBannerTone.warning,
        icon: LucideIcons.circleX,
        text: 'Đơn đã hủy nên không còn mã lấy hàng.',
      ),
      'EXPIRED' => const OpsBanner(
        tone: OpsBannerTone.danger,
        icon: LucideIcons.triangleAlert,
        text:
            'Đơn đã quá hạn lấy, ô đã được thu hồi. Vui lòng liên hệ người gửi '
            'hoặc hỗ trợ Lock.R.',
      ),
      _ => OpsBanner(
        tone: OpsBannerTone.info,
        icon: LucideIcons.hourglass,
        text: _notReadyText(),
      ),
    };
  }

  String _notReadyText() {
    final o = _detail.order;
    if (_detail.isDrone) {
      final stage = DroneDeliveryStage.fromRaw(o.deliveryStage);
      return '${stage.title}. Mã lấy hàng sẽ hiện khi drone đã đặt kiện vào '
          'ô tủ nhận.';
    }
    if (o.status == 'INITIALIZED') {
      return 'Người gửi chưa bỏ hàng vào ô. Mã lấy hàng sẽ hiện khi hàng đã '
          'nằm trong ô.';
    }
    return 'Hàng chưa sẵn sàng. Mã lấy hàng sẽ hiện khi hàng đã nằm trong ô.';
  }

  static String _paymentLabel(String status) => switch (status) {
    'PAID' => 'Người gửi đã thanh toán',
    'REFUND_PENDING' => 'Đang hoàn tiền cho người gửi',
    'REFUNDED' => 'Đã hoàn tiền cho người gửi',
    _ => 'Người gửi chưa thanh toán',
  };
}

class _Header extends StatelessWidget {
  const _Header({required this.detail, required this.delegate});

  final ReceiverOrderDetail detail;
  final bool delegate;

  @override
  Widget build(BuildContext context) {
    final o = detail.order;
    final status = detail.isDrone && (o.deliveryStage ?? '').isNotEmpty
        ? o.deliveryStage
        : o.status;
    final code = (o.orderCode ?? '').isEmpty ? '#${o.id}' : o.orderCode!;
    final finished = o.isFinished || o.status == 'EXPIRED';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: statusColor(status).withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                detail.isDrone ? LucideIcons.plane : typeIcon(o.type),
                color: statusColor(status),
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    typeLabel(o.type).isEmpty ? 'Đơn hàng' : typeLabel(o.type),
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                      color: opsDark,
                    ),
                  ),
                  const SizedBox(height: 2),
                  InkWell(
                    borderRadius: BorderRadius.circular(6),
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: code));
                      ScaffoldMessenger.maybeOf(context)
                        ?..hideCurrentSnackBar()
                        ..showSnackBar(
                          const SnackBar(content: Text('Đã sao chép mã đơn')),
                        );
                    },
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            o.displayCode,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: opsMutedText,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          LucideIcons.copy,
                          size: 13,
                          color: opsMutedText,
                          semanticLabel: 'Sao chép mã đơn',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            StatusChip(status),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          delegate
              ? 'Bạn được ủy quyền lấy hộ đơn này.'
              : 'Bạn là người nhận của đơn này.',
          style: const TextStyle(fontSize: 12.5, color: opsMutedText),
        ),
        if (o.overdue && !finished) ...[
          const SizedBox(height: 10),
          OpsBanner(
            tone: OpsBannerTone.danger,
            icon: LucideIcons.clockAlert,
            text:
                'Đơn đã quá hạn lấy '
                '${fmtOverdueDuration(o.pickupDeadline)}'
                ' — lấy hàng sớm để tránh phí quá giờ.',
          ),
        ],
      ],
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.text, required this.onRetry});

  final String text;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        OpsBanner(
          tone: OpsBannerTone.warning,
          icon: LucideIcons.cloudOff,
          text: text,
        ),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: onRetry,
            icon: const Icon(LucideIcons.refreshCw, size: 15),
            label: const Text('Thử lại'),
          ),
        ),
      ],
    );
  }
}
