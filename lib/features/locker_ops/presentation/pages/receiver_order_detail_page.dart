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
import 'package:smart_laundry_locker/shared/widgets/app_lottie.dart';
import 'package:smart_laundry_locker/core/l10n/l10n.dart';

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
          _error = context.l10n.recvLoadFailed;
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
      return L10n.current.recvNotInList;
    }
    if (LockerOpsService.isEndpointUnavailable(e)) {
      return L10n.current.recvSummaryOnly;
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

  bool _sendingEmail = false;

  /// "Gửi lại qua email": thông tin đơn (và mã mở tủ khi hàng đã vào tủ) tới email tài khoản của mình.
  Future<void> _resendEmail() async {
    if (_sendingEmail) return;
    setState(() => _sendingEmail = true);
    final messenger = ScaffoldMessenger.maybeOf(context);
    try {
      final result = await _service.resendReceiverEmail(
        _detail.order.id,
        delegated: _detail.loaded ? _detail.isDelegateView : widget.delegatedView,
      );
      final masked = result['maskedEmail']?.toString();
      final withCode = result['includesPickupCode'] == true;
      messenger
        ?..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              L10n.current.recvEmailSent(
                withCode ? L10n.current.recvWithCode : '',
                masked ?? L10n.current.recvYourEmail,
              ),
            ),
          ),
        );
    } catch (e) {
      if (!mounted) return;
      if (LockerOpsService.errorCode(e) == 'RECEIVER_EMAIL_MISSING') {
        await _askAddEmail();
      } else {
        messenger
          ?..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(LockerOpsService.errorMessage(e))));
      }
    } finally {
      if (mounted) setState(() => _sendingEmail = false);
    }
  }

  Future<void> _askAddEmail() async {
    final add = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.l10n.recvNoEmail),
        content: Text(
          context.l10n.recvNoEmailBody,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: Text(context.l10n.commonLater)),
          FilledButton(onPressed: () => Navigator.of(ctx).pop(true), child: Text(context.l10n.recvAddEmail)),
        ],
      ),
    );
    if (add == true && mounted) await context.push(AppRouter.editProfile);
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
          delegate ? context.l10n.recvDelegateDetail : context.l10n.recvDetail,
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
        ),
        actions: [
          IconButton(
            onPressed: _loading ? null : _load,
            icon: const Icon(LucideIcons.refreshCw, size: 18),
            tooltip: context.l10n.commonReload,
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
    final ownerTitle = delegate ? context.l10n.recvDelegator : context.l10n.recvSender;

    return [
      // 2. Mã lấy hàng + thao tác của thẻ.
      OrderDetailSection(
        title: context.l10n.recvPickupCode,
        icon: LucideIcons.keyRound,
        footer: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _pickupCodeBlock(delegate),
            const SizedBox(height: 12),
            if (o.canUnlockWithCode)
              OpsSheetAction(
                label: context.l10n.recvOpenBoxPickup(o.boxLabel),
                icon: LucideIcons.doorOpen,
                primary: true,
                onTap: _unlock,
              ),
            if (hasLocation && !finished)
              OpsSheetAction(
                label: context.l10n.ordDirectionsToLocker,
                icon: LucideIcons.map,
                onTap: () => openReceiverOrderDirections(context, o),
              ),
            if (d.droneTrackingAvailable)
              OpsSheetAction(
                label: finished ? context.l10n.ordReviewDroneJourney : context.l10n.recvTrackDrone,
                icon: LucideIcons.navigation,
                onTap: _trackDrone,
              ),
            if (!finished)
              OpsSheetAction(
                key: const ValueKey('receiver-resend-email'),
                label: _sendingEmail ? context.l10n.recvSendingEmail : context.l10n.recvResendEmail,
                icon: LucideIcons.mail,
                onTap: _resendEmail,
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
              label: context.l10n.commonFullNameShort,
              value: o.senderName!,
            ),
          if (d.senderPhone != null)
            OrderContactRow(
              icon: LucideIcons.phone,
              label: context.l10n.recvSenderPhone,
              value: d.senderPhone!,
              phone: true,
            ),
          if (d.senderEmail != null)
            OrderContactRow(
              icon: LucideIcons.mail,
              label: context.l10n.recvSenderEmail,
              value: d.senderEmail!,
            ),
        ],
      ),

      // 4. Người nhận & ủy quyền.
      OrderDetailSection(
        title: context.l10n.ordRecipient,
        icon: LucideIcons.userCheck,
        rows: [
          if ((o.receiverName ?? '').isNotEmpty)
            OpsInfoRow(
              icon: LucideIcons.userCheck,
              label: context.l10n.recvRecipientName,
              value: o.receiverName!,
            ),
          if ((o.receiverPhone ?? '').isNotEmpty)
            OrderContactRow(
              icon: LucideIcons.phone,
              label: context.l10n.recvRecipientPhone,
              value: o.receiverPhone!,
              phone: true,
            ),
          if (d.receiverEmail != null)
            OrderContactRow(
              icon: LucideIcons.mail,
              label: context.l10n.ordRecipientEmail,
              value: d.receiverEmail!,
            ),
          if (d.deliveryAddress != null)
            OpsInfoRow(
              icon: LucideIcons.truck,
              label: context.l10n.ordDeliveryAddress,
              value: d.deliveryAddress!,
            ),
          if (delegate) ...[
            OpsInfoRow(
              icon: LucideIcons.userPlus,
              label: context.l10n.recvDelegatePerson,
              value: (o.delegateName ?? '').isNotEmpty
                  ? context.l10n.recvYouSuffix('${o.delegateName}')
                  : context.l10n.recvYou,
            ),
            if (d.delegatePhone != null)
              OpsInfoRow(
                icon: LucideIcons.smartphone,
                label: context.l10n.recvDelegatePhone,
                value: d.delegatePhone!,
              ),
            if ((o.delegateNote ?? '').isNotEmpty)
              OpsInfoRow(
                icon: LucideIcons.stickyNote,
                label: context.l10n.commonMessage,
                value: o.delegateNote!,
              ),
          ] else if (o.delegated)
            OpsInfoRow(
              icon: LucideIcons.userPlus,
              label: context.l10n.recvDelegation,
              value: context.l10n.recvOwnerDelegated,
              valueColor: Color(0xFF7C3AED),
            ),
          if (o.delegatedAt != null)
            OpsInfoRow(
              icon: LucideIcons.clock,
              label: context.l10n.ordDelegatedAt,
              value: fmtDateTime(o.delegatedAt),
            ),
        ],
      ),

      // 5. Tủ & ô.
      OrderDetailSection(
        title: context.l10n.recvLockerAndBox,
        icon: LucideIcons.warehouse,
        rows: [
          OpsInfoRow(
            icon: LucideIcons.warehouse,
            label: d.isDrone ? context.l10n.recvReceivingLocker : context.l10n.commonLocker,
            value: o.lockerName ?? context.l10n.ordLockrLocker,
          ),
          if ((o.lockerCode ?? '').isNotEmpty)
            OpsInfoRow(
              icon: LucideIcons.hash,
              label: context.l10n.recvLockerCode,
              value: o.lockerCode!,
            ),
          if ((o.lockerAddress ?? '').isNotEmpty)
            OpsInfoRow(
              icon: LucideIcons.mapPin,
              label: context.l10n.ordPlace,
              value: o.lockerAddress!,
            ),
          if (o.boxNumber != null)
            OpsInfoRow(
              icon: LucideIcons.grid3x3,
              label: context.l10n.commonBox,
              value: context.l10n.boxNumberLabel('${o.boxNumber}'),
            ),
          if (d.boxSize != null)
            OpsInfoRow(
              icon: LucideIcons.box,
              label: context.l10n.recvBoxSize,
              value: boxSizeLabel(d.boxSize),
            ),
          if (d.boxType != null)
            OpsInfoRow(
              icon: LucideIcons.layoutGrid,
              label: context.l10n.commonBoxType,
              value: boxTypeLabel(d.boxType),
            ),
          if (d.sourceLockerName != null || d.sourceLockerCode != null)
            OpsInfoRow(
              icon: LucideIcons.planeTakeoff,
              label: context.l10n.ordFromLocker,
              value: [
                d.sourceLockerName ?? context.l10n.ordLockrLocker,
                if (d.sourceLockerCode != null) '(${d.sourceLockerCode})',
              ].join(' '),
            ),
          if (d.sourceLockerAddress != null)
            OpsInfoRow(
              icon: LucideIcons.mapPinned,
              label: context.l10n.recvSourceAddress,
              value: d.sourceLockerAddress!,
            ),
          if (d.routeDistanceMeters != null)
            OpsInfoRow(
              icon: LucideIcons.route,
              label: context.l10n.ordFlightDistance,
              value: fmtDistanceMeters(d.routeDistanceMeters!),
            ),
        ],
      ),

      // 6. Kiện hàng.
      OrderDetailSection(
        title: context.l10n.ordParcel,
        icon: LucideIcons.package,
        rows: [
          ...orderParcelRows(d.parcel),
          if (d.customerNote != null)
            OpsInfoRow(
              icon: LucideIcons.stickyNote,
              label: context.l10n.recvSenderNote,
              value: d.customerNote!,
            ),
        ],
      ),

      // 7. Thời gian.
      OrderDetailSection(
        title: context.l10n.commonTime,
        icon: LucideIcons.clock,
        rows: [
          if (o.pickupDeadline != null)
            OpsInfoRow(
              icon: LucideIcons.clock,
              label: context.l10n.recvPickupDeadline,
              value: fmtDateTime(o.pickupDeadline),
              valueColor: o.overdue && !finished
                  ? const Color(0xFFDC2626)
                  : null,
            ),
          if (o.pickupDeadline != null && !finished)
            OpsInfoRow(
              icon: LucideIcons.hourglass,
              label: o.overdue ? context.l10n.ordOverdue : context.l10n.recvTimeLeft,
              value: fmtDeadlineDistance(o.pickupDeadline),
              valueColor: o.overdue
                  ? const Color(0xFFDC2626)
                  : const Color(0xFF15803D),
            ),
          if (d.intendedReceiveAt != null)
            OpsInfoRow(
              icon: LucideIcons.calendarClock,
              label: context.l10n.recvExpectedPickup,
              value: fmtDateTime(d.intendedReceiveAt),
            ),
          if (d.rentalDurationHours != null)
            OpsInfoRow(
              icon: LucideIcons.timer,
              label: context.l10n.ordRentalDuration,
              value: context.l10n.hoursValue(d.rentalDurationHours!),
            ),
          if (o.createdAt != null)
            OpsInfoRow(
              icon: LucideIcons.calendar,
              label: context.l10n.recvCreatedAt,
              value: fmtDateTime(o.createdAt),
            ),
          if (o.paymentStatus != null)
            OpsInfoRow(
              icon: LucideIcons.wallet,
              label: context.l10n.commonPayment,
              value: _paymentLabel(o.paymentStatus!),
            ),
          if (d.paidAt != null)
            OpsInfoRow(
              icon: LucideIcons.receiptText,
              label: context.l10n.ordPaidAt,
              value: fmtDateTime(d.paidAt),
            ),
          if (o.completedAt != null)
            OpsInfoRow(
              icon: LucideIcons.circleCheck,
              label: context.l10n.recvCompletedAt,
              value: fmtDateTime(o.completedAt),
              valueColor: const Color(0xFF15803D),
            ),
          if (d.updatedAt != null)
            OpsInfoRow(
              icon: LucideIcons.refreshCw,
              label: context.l10n.recvUpdatedAt,
              value: fmtDateTime(d.updatedAt),
            ),
        ],
      ),
      OrderDetailSection(
        title: context.l10n.recvTimeline,
        icon: LucideIcons.history,
        footer: d.timeline.isEmpty
            ? null
            : OrderMilestoneTimeline(milestones: d.timeline),
      ),

      // 8. Drone.
      if (d.isDrone)
        OrderDetailSection(
          title: context.l10n.recvDroneJourney,
          icon: LucideIcons.plane,
          rows: [
            if ((o.deliveryStage ?? '').isNotEmpty)
              OpsInfoRow(
                icon: DroneDeliveryStage.fromRaw(o.deliveryStage).icon,
                label: context.l10n.recvCurrentStage,
                value: DroneDeliveryStage.fromRaw(o.deliveryStage).title,
              ),
            if (d.etaMinutes != null)
              OpsInfoRow(
                icon: LucideIcons.timer,
                label: context.l10n.recvEta,
                value: d.etaMinutes == 0
                    ? context.l10n.recvArrived
                    : context.l10n.recvAboutMinutes('${d.etaMinutes}'),
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
                        latitude: step.latitude,
                        longitude: step.longitude,
                        locationSource: step.locationSource,
                      ),
                  ],
                  colorOf: (code) => DroneDeliveryStage.fromRaw(code).color,
                ),
        ),

      // 9. Sự cố / giao không hoàn tất.
      OrderDetailSection(
        title: context.l10n.recvIncident,
        icon: LucideIcons.triangleAlert,
        rows: [
          if (d.deliveryBlockReasonLabel != null)
            OpsInfoRow(
              icon: LucideIcons.circlePause,
              label: context.l10n.ordPaused,
              value: d.deliveryBlockReasonLabel!,
              valueColor: const Color(0xFFEA580C),
            ),
          if (d.deliveryBlockedAt != null)
            OpsInfoRow(
              icon: LucideIcons.clock,
              label: context.l10n.ordPausedAt,
              value: fmtDateTime(d.deliveryBlockedAt),
            ),
          if (d.failureReasonLabel != null)
            OpsInfoRow(
              icon: LucideIcons.circleX,
              label: context.l10n.ordDeliveryIncomplete,
              value: d.failureReasonLabel!,
              valueColor: const Color(0xFFDC2626),
            ),
          if (d.failedAt != null)
            OpsInfoRow(
              icon: LucideIcons.clock,
              label: context.l10n.ordRecordedAt,
              value: fmtDateTime(d.failedAt),
            ),
          if (d.parcelReturnedAt != null)
            OpsInfoRow(
              icon: LucideIcons.undo2,
              label: context.l10n.recvParcelReturnedToSender,
              value: fmtDateTime(d.parcelReturnedAt),
            ),
        ],
      ),
    ];
  }

  Widget _pickupCodeBlock(bool delegate) {
    final o = _detail.order;
    if (!delegate && o.delegated && !o.isFinished) {
      return OpsBanner(
        tone: OpsBannerTone.info,
        icon: LucideIcons.userCheck,
        text:
            context.l10n.recvCodeMovedToDelegate,
      );
    }
    if (o.isActive && (o.pickupPin ?? '').isNotEmpty) {
      return Column(
        children: [
          AccessCredentials(
            pin: o.pickupPin,
            qrToken: o.qrToken,
            showQr: (o.qrToken ?? '').isNotEmpty,
            caption: context.l10n.recvCredCaption,
          ),
          if (o.overdue) ...[
            const SizedBox(height: 10),
            OpsBanner(
              tone: OpsBannerTone.danger,
              icon: LucideIcons.triangleAlert,
              text: context.l10n.recvOverdueMayCharge,
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
            ? context.l10n.recvCompleted
            : context.l10n.recvCompletedAtTime(fmtDateTime(o.completedAt)),
      ),
      'CANCELED' || 'CANCELLED' => OpsBanner(
        tone: OpsBannerTone.warning,
        icon: LucideIcons.circleX,
        text: L10n.current.recvCancelled,
      ),
      'EXPIRED' => OpsBanner(
        tone: OpsBannerTone.danger,
        icon: LucideIcons.triangleAlert,
        text: L10n.current.recvExpired,
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
      return context.l10n.recvDroneNotReady(stage.title);
    }
    if (o.status == 'INITIALIZED') {
      return context.l10n.recvSenderNotDropped;
    }
    return context.l10n.recvNotReady;
  }

  static String _paymentLabel(String status) => switch (status) {
    'PAID' => L10n.current.recvSenderPaid,
    'REFUND_PENDING' => L10n.current.recvRefundingSender,
    'REFUNDED' => L10n.current.recvSenderRefunded,
    _ => L10n.current.recvSenderUnpaid,
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
                border: Border.all(
                  color: statusColor(status).withValues(alpha: 0.18),
                  width: 1,
                ),
              ),
              padding: const EdgeInsets.all(4),
              child: AppLottie(
                detail.isDrone
                    ? AppLottieAssets.airplaneBox
                    : AppLottieAssets.box,
                fallback: (context) => Icon(
                  detail.isDrone ? LucideIcons.plane : typeIcon(o.type),
                  color: statusColor(status),
                  size: 24,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    typeLabel(o.type).isEmpty ? context.l10n.commonOrder : typeLabel(o.type),
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
                          SnackBar(content: Text(context.l10n.recvOrderCodeCopied)),
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
                        Icon(
                          LucideIcons.copy,
                          size: 13,
                          color: opsMutedText,
                          semanticLabel: context.l10n.recvCopyOrderCode,
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
              ? context.l10n.recvYouAreDelegate
              : context.l10n.recvYouAreRecipient,
          style: const TextStyle(fontSize: 12.5, color: opsMutedText),
        ),
        if (o.overdue && !finished) ...[
          const SizedBox(height: 10),
          OpsBanner(
            tone: OpsBannerTone.danger,
            icon: LucideIcons.clockAlert,
            text:
                context.l10n.recvOverdueBy(fmtOverdueDuration(o.pickupDeadline)),
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
            label: Text(context.l10n.commonRetry),
          ),
        ),
      ],
    );
  }
}
