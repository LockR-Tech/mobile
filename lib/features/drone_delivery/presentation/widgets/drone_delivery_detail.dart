import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:smart_laundry_locker/core/config/business_config.dart';
import 'package:smart_laundry_locker/core/config/business_config_service.dart';
import 'package:smart_laundry_locker/core/routing/app_router.dart';
import 'package:smart_laundry_locker/core/theme/shadcn_theme.dart';
import 'package:smart_laundry_locker/core/utils/app_date_time.dart';
import 'package:smart_laundry_locker/features/drone_delivery/domain/entities/drone_booking.dart';
import 'package:smart_laundry_locker/features/drone_delivery/domain/entities/drone_delivery_stage.dart';
import 'package:smart_laundry_locker/features/drone_delivery/domain/entities/drone_delivery_status.dart';
import 'package:smart_laundry_locker/features/drone_delivery/domain/entities/drone_labels.dart';
import 'package:smart_laundry_locker/features/drone_delivery/domain/entities/drone_parcel.dart';
import 'package:smart_laundry_locker/features/drone_delivery/presentation/widgets/drone_coordinates_line.dart';
import 'package:smart_laundry_locker/features/drone_delivery/presentation/widgets/drone_delivery_timeline.dart';
import 'package:smart_laundry_locker/features/drone_delivery/presentation/widgets/drone_order_cancel.dart';
import 'package:smart_laundry_locker/features/drone_delivery/domain/entities/drone_route_geometry.dart';
import 'package:smart_laundry_locker/features/drone_delivery/presentation/widgets/drone_route_map_card.dart';
import 'package:smart_laundry_locker/features/locker_ops/presentation/utils/business_rules_text.dart';
import 'package:smart_laundry_locker/features/locker_ops/presentation/utils/locker_maps.dart';
import 'package:smart_laundry_locker/features/locker_ops/presentation/widgets/ops_widgets.dart';
import 'package:smart_laundry_locker/core/l10n/l10n.dart';

/// Thời điểm thực tế từng mốc timeline đã đạt, suy từ nhật ký hành trình.
///
/// Nhật ký xếp mới nhất trước nên duyệt ngược để lấy LẦN ĐẦU đạt mỗi mốc — ví dụ
/// mốc ACCEPTED có hai dòng (tiếp nhận, rồi xác nhận nạp hàng), giờ hiển thị là
/// giờ tiếp nhận.
Map<DroneDeliveryStage, DateTime> droneStageTimes(DroneDeliveryStatus status) {
  final times = <DroneDeliveryStage, DateTime>{};
  for (final event in status.journeyEvents.reversed) {
    final stage = DroneDeliveryStage.fromRaw(event.toStage);
    final at = event.occurredAt;
    // DROP_REPORTED không thuộc luồng giao bình thường nhưng vẫn phải giữ giờ
    // để timeline hiển thị đúng lúc đội bay báo sự cố.
    if ((stage.order < 0 && !stage.isIncident) ||
        at == null ||
        event.isPickupCodeSent) {
      continue;
    }
    times.putIfAbsent(stage, () => at);
  }
  final createdAt = status.createdAt;
  if (createdAt != null) {
    times.putIfAbsent(DroneDeliveryStage.awaitingDispatch, () => createdAt);
  }
  return times;
}

/// Mốc nhật ký LẦN ĐẦU đạt mỗi chặng, chỉ những mốc có toạ độ — để timeline hiện kiện ở đâu lúc đó.
Map<DroneDeliveryStage, DroneJourneyEvent> droneStageLocations(
  DroneDeliveryStatus status,
) {
  final firstEvents = <DroneDeliveryStage, DroneJourneyEvent>{};
  for (final event in status.journeyEvents.reversed) {
    if (event.occurredAt == null || event.isPickupCodeSent) continue;
    firstEvents.putIfAbsent(DroneDeliveryStage.fromRaw(event.toStage), () => event);
  }
  firstEvents.removeWhere((_, event) => !event.hasLocation);
  return firstEvents;
}

/// Mốc phụ gắn vào từng chặng của timeline — trước đây nằm trong thẻ "Mốc thời
/// gian" riêng, giờ hiện ngay dưới chặng mà chúng thuộc về.
Map<DroneDeliveryStage, List<DroneTimelineDetail>> droneStepDetails(
  DroneDeliveryStatus status,
) {
  final codeEvent = status.pickupCodeEvent;
  final reachedPickup =
      status.depositedAt != null ||
      status.stage == DroneDeliveryStage.readyForPickup ||
      status.stage == DroneDeliveryStage.completed;
  return {
    DroneDeliveryStage.awaitingDispatch: [
      DroneTimelineDetail(L10n.current.ddTlPayment, status.paidAt),
      // Đơn cũ: người gửi tự mang kiện ra ô gửi.
      if (status.pickup == null)
        DroneTimelineDetail(L10n.current.ddTlParcelDropped, status.parcelDroppedAt),
    ],
    if (status.pickup != null)
      DroneDeliveryStage.pickedUp: [
        DroneTimelineDetail(
          L10n.current.ddTlHomePickup,
          status.pickup!.pickedUpAt,
        ),
      ],
    DroneDeliveryStage.accepted: [
      DroneTimelineDetail(L10n.current.ddTlLoaded, status.loadedAt),
      DroneTimelineDetail(L10n.current.ddTlReady, status.readyToLaunchAt),
    ],
    if (reachedPickup)
      DroneDeliveryStage.readyForPickup: [
        DroneTimelineDetail(
          L10n.current.ddTlCodeSent,
          codeEvent?.occurredAt,
          note: codeEvent?.note,
        ),
        DroneTimelineDetail(L10n.current.ddTlPickupDeadline, status.pickupDeadline),
        DroneTimelineDetail(L10n.current.ddTlReceived, status.completedAt),
      ],
  };
}

/// Lần đầu đơn rơi vào trạng thái kết thúc không thành công (huỷ/quá hạn/lỗi).
DateTime? _endedAt(DroneDeliveryStatus status) => switch (status.stage) {
  DroneDeliveryStage.canceled =>
    status.firstReachedAt('CANCELED') ?? status.updatedAt,
  DroneDeliveryStage.expired =>
    status.firstReachedAt('EXPIRED') ?? status.updatedAt,
  DroneDeliveryStage.failed =>
    status.firstReachedAt('FAILED') ?? status.updatedAt,
  _ => null,
};

/// Toàn bộ thông tin một chuyến giao drone: chặng hiện tại, bản đồ lộ trình A → B,
/// timeline có giờ từng chặng, hồ sơ nạp hàng và nhật ký hành trình (mới nhất trước).
///
/// Dùng chung cho khách (màn theo dõi) và điều phối viên (chi tiết nhiệm vụ) để
/// hai bên luôn nhìn cùng một bộ dữ liệu. Trả về `Column`, nơi dùng tự bọc scroll.
class DroneDeliveryDetail extends StatelessWidget {
  const DroneDeliveryDetail({
    super.key,
    required this.status,
    this.forOperator = false,
    this.viewerIsBooker = true,
    this.beforeRoute = const [],
    this.onPay,
    this.onCancel,
    this.onConfirmDrop,
    this.onDeclineSurcharge,
    this.isSender = true,
  });

  final DroneDeliveryStatus status;

  /// Người đang xem là người đặt đơn. Người nhận có tài khoản cũng xem được hành trình
  /// nhưng không thanh toán, huỷ hay thấy mã lấy hàng thay người gửi.
  final bool isSender;

  /// Người gửi xác nhận đã bỏ kiện vào ô drone ở tủ gửi.
  final VoidCallback? onConfirmDrop;

  /// Khách từ chối trả phụ thu cân lệch (huỷ đơn, hoàn phần đã trả).
  final VoidCallback? onDeclineSurcharge;

  /// Khách bấm thanh toán ngay trên thẻ nhắc đơn chưa trả tiền.
  final VoidCallback? onPay;

  /// Khách huỷ đơn khi đội bay chưa tiếp nhận.
  final VoidCallback? onCancel;

  /// Điều phối viên thấy thêm liên hệ người gửi/người nhận.
  final bool forOperator;

  /// Khách đang xem là người đặt đơn. Người nhận chỉ xem: lời nhắc trả phí /
  /// bỏ kiện nói về người gửi, không có nút thao tác.
  final bool viewerIsBooker;

  /// Widget chèn ngay dưới thẻ tiêu đề (vd nút mở live map của khách).
  final List<Widget> beforeRoute;

  @override
  Widget build(BuildContext context) {
    final stage = status.stage;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _HeaderCard(status: status),
        if (stage.isDelayed || stage.isFailure) ...[
          const SizedBox(height: 16),
          _StatusBanner(status: status),
        ],
        if (status.block != null && !stage.isFailure) ...[
          const SizedBox(height: 16),
          _BlockBanner(status: status, forOperator: forOperator),
        ],
        if (status.needsPaymentBeforeDispatch ||
            status.needsSurchargePayment) ...[
          const SizedBox(height: 16),
          _UnpaidBanner(
            status: status,
            forOperator: forOperator,
            // [viewerIsBooker] và [isSender] cùng nghĩa: thiếu một trong hai
            // là người nhận — chỉ xem, không có nút thanh toán.
            viewerIsBooker: viewerIsBooker && isSender,
            onPay: onPay,
            onDeclineSurcharge: onDeclineSurcharge,
          ),
        ],
        if (status.pickup != null && !stage.isFailure) ...[
          const SizedBox(height: 16),
          _PickupCard(
            status: status,
            forOperator: forOperator,
            isSender: isSender,
          ),
        ],
        if (status.needsParcelDrop) ...[
          const SizedBox(height: 16),
          _DropBanner(
            status: status,
            forOperator: forOperator,
            viewerIsBooker: viewerIsBooker && isSender,
            onConfirmDrop: onConfirmDrop,
          ),
        ],
        if (status.parcelReturnPending == true ||
            status.parcelReturnedAt != null) ...[
          const SizedBox(height: 16),
          _ParcelReturnBanner(status: status, forOperator: forOperator),
        ],
        ...beforeRoute,
        if (!stage.isTerminal && !stage.isIncident) ...[
          const SizedBox(height: 16),
          _StorageDeadlineCard(status: status, forOperator: forOperator),
        ],
        const SizedBox(height: 16),
        DroneRouteMapCard(status: status, forOperator: forOperator),
        const SizedBox(height: 16),
        _RouteCard(status: status, forOperator: forOperator),
        const SizedBox(height: 16),
        _Card(
          title: context.l10n.ddProgress,
          icon: LucideIcons.listChecks,
          child: DroneDeliveryTimeline(
            stage: stage,
            stageTimes: droneStageTimes(status),
            stepDetails: droneStepDetails(status),
            stageLocations: droneStageLocations(status),
            steps: DroneDeliveryStage.timelineFor(
              homePickup: status.pickup != null,
            ),
          ),
        ),
        if (!forOperator &&
            isSender &&
            onCancel != null &&
            status.canCustomerCancel) ...[
          const SizedBox(height: 16),
          _CancelCard(status: status, onCancel: onCancel!),
        ],
        const SizedBox(height: 16),
        _OrderCard(status: status),
        const SizedBox(height: 16),
        _PeopleCard(status: status, forOperator: forOperator),
        const SizedBox(height: 16),
        _MissionCard(status: status),
        const SizedBox(height: 16),
        _JourneyCard(events: status.journeyEvents),
      ],
    );
  }
}

String? _etaText(int? minutes) => minutes == null ? null : L10n.current.minutesShort(minutes);

/// Tiêu đề + mô tả của thẻ đầu trang. Câu mặc định theo chặng sai ở vài trường hợp (test 2026-10-29):
/// đơn đóng sau khi drone đã bay (rơi kiện) bị ghi "dừng trước khi drone cất cánh", đơn chưa trả tiền
/// ghi "đang tìm kỹ thuật viên", đơn đã nạp xong vẫn ghi "đang nạp hàng".
({String title, String body}) _headerText(DroneDeliveryStatus status) {
  final stage = status.stage;
  if (stage == DroneDeliveryStage.canceled && status.launchingAt != null) {
    return (
      title: L10n.current.ddClosedTitle,
      body: L10n.current.ddClosedBody,
    );
  }
  if (stage == DroneDeliveryStage.awaitingDispatch && !status.isPaid) {
    return (
      title: L10n.current.ddAwaitingPaymentTitle,
      body: L10n.current.ddAwaitingPaymentBody,
    );
  }
  // Không lấy hàng tận nhà (đơn giao lại sau sự cố, đơn gửi tại tủ): kiện đã nằm ở kho / trạm, không
  // còn "tìm kỹ thuật viên gần bạn" (test 2026-10-29, đơn giao lại #144).
  if (stage == DroneDeliveryStage.awaitingDispatch && status.pickup == null) {
    return (
      title: L10n.current.ddAwaitingTeamTitle,
      body: L10n.current.ddAwaitingTeamBody,
    );
  }
  if (stage == DroneDeliveryStage.accepted &&
      (status.missionStatus ?? '').toUpperCase() == 'READY_TO_LAUNCH') {
    return (
      title: L10n.current.ddTlReady,
      body: L10n.current.ddReadyBody,
    );
  }
  return (title: stage.title, body: stage.body(_etaText(status.etaMinutes)));
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({required this.status});

  final DroneDeliveryStatus status;

  @override
  Widget build(BuildContext context) {
    final stage = status.stage;
    final changedAt = status.stageChangedAt;
    final text = _headerText(status);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AISLShadcnTheme.navyPrimary, AISLShadcnTheme.navyAccent],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.16),
                  shape: BoxShape.circle,
                ),
                child: Icon(stage.icon, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      text.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      text.body,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 13,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Wrap thay vì Row: các chip có thể vượt bề rộng card trên màn hẹp
          // hoặc mã đơn/drone dài — wrap xuống dòng thay vì tràn.
          Wrap(
            spacing: 10,
            runSpacing: 8,
            children: [
              if ((status.orderCode ?? '').isNotEmpty)
                _InfoChip(
                  icon: LucideIcons.package,
                  label: context.l10n.commonOrderCode('${status.orderCode}'),
                ),
              if ((status.droneCode ?? '').isNotEmpty)
                _InfoChip(
                  icon: LucideIcons.planeTakeoff,
                  label: status.droneCode!,
                ),
              // ETA chỉ có nghĩa khi drone đang bay (server trả null trước khi phóng).
              if (status.etaMinutes != null && stage.isInFlight)
                _InfoChip(
                  icon: LucideIcons.clock,
                  label: context.l10n.ddAboutMinutesLeft('${status.etaMinutes}'),
                ),
              if (changedAt != null)
                _InfoChip(
                  icon: LucideIcons.history,
                  label: context.l10n.ddSince(formatDateTimeVn(changedAt)),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Thời hạn lưu trữ, cùng một nội dung cho người gửi, người nhận và điều phối viên.
/// Trước khi hàng vào ô chỉ báo số giờ vì hạn tính từ lúc drone thả hàng.
class _StorageDeadlineCard extends StatelessWidget {
  const _StorageDeadlineCard({required this.status, required this.forOperator});

  final DroneDeliveryStatus status;
  final bool forOperator;

  /// Số giờ thật của đơn này: admin đổi cấu hình sau khi hàng vào ô không làm đổi hạn đã chốt.
  int _storedHours(DateTime deadline, BusinessConfig config) {
    final depositedAt = status.depositedAt;
    return depositedAt == null
        ? config.dronePickupHoursLimit
        : (deadline.difference(depositedAt).inMinutes / 60).round();
  }

  @override
  Widget build(BuildContext context) {
    final config = BusinessConfigService.instance.current;
    final deadline = status.pickupDeadline;
    final overdue = deadline != null && DateTime.now().isAfter(deadline);
    final color = overdue
        ? const Color(0xFFB91C1C)
        : deadline != null
        ? const Color(0xFFB45309)
        : const Color(0xFF4F46E5);
    final String message;
    if (deadline == null) {
      message = dronePickupPolicyText(config);
    } else if (overdue) {
      message =
          context.l10n.ddOverdueAt(formatDeadlineVn(deadline), overtimePolicyText(config));
    } else if (forOperator) {
      message =
          context.l10n.ddPickupDeadline(formatDeadlineVn(deadline), _storedHours(deadline, config));
    } else {
      message =
          '${droneStoredUntilText(_storedHours(deadline, config), deadline)} '
          '${overtimePolicyText(config)}';
    }
    return Container(
      key: const ValueKey('drone-storage-deadline'),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(LucideIcons.clock, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: color,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBanner extends StatelessWidget {
  const _StatusBanner({required this.status});

  final DroneDeliveryStatus status;

  @override
  Widget build(BuildContext context) {
    final stage = status.stage;
    final color = stage.color; // amber cho delayed, đỏ cho failed/huỷ/quá hạn
    final failure = status.failure;
    final reason = failure == null
        ? droneCancelReasonLabel(status.cancelReason)
        : failure.reasonLabel ?? droneFailureReasonLabel(failure.reason);
    final endedAt = failure?.at ?? _endedAt(status);
    // Kiện đã rời tay người gửi thì có dòng riêng ở thẻ "kiện chờ trả".
    final parcelCollected =
        status.parcelReturnPending == true || status.parcelReturnedAt != null;
    // Đơn không giao được: đội bay/khách huỷ trước khi bay, hoặc chuyến bay thất bại.
    final stopped =
        stage == DroneDeliveryStage.canceled ||
        stage == DroneDeliveryStage.failed;
    // Đơn đóng sau khi drone đã khởi phóng (vd. rơi kiện rồi giao lại / bồi thường):
    // không phải "dừng trước khi cất cánh", và tiền xử lý theo phương án sự cố.
    final closedAfterFlight =
        stage == DroneDeliveryStage.canceled && status.launchingAt != null;
    // Chưa trả tiền thì hệ thống chưa mời KTV: không ghi "đang tìm kỹ thuật viên".
    final awaitingPayment =
        stage == DroneDeliveryStage.awaitingDispatch && !status.isPaid;
    final lines = <String>[
      closedAfterFlight
          ? context.l10n.ddFlightIncompleteClosed
          : awaitingPayment
          ? context.l10n.ddUnpaidSearch
          : stage.body(_etaText(status.etaMinutes)),
      if (endedAt != null) context.l10n.ddAt(formatDateTimeVn(endedAt)),
      if (stopped && reason != null) context.l10n.ddReason(reason),
      if (stopped && status.cancelNote != null) context.l10n.ddNoteValue('${status.cancelNote}'),
      if (failure?.ticketId != null) context.l10n.ddTicket('${failure!.ticketId}'),
      if (stage == DroneDeliveryStage.failed && !parcelCollected)
        context.l10n.ddParcelWithSender,
      if (stopped &&
          (status.paymentStatus ?? '').toUpperCase() == 'REFUND_PENDING')
        context.l10n.ddRefundRecorded,
      if (stopped && (status.paymentStatus ?? '').toUpperCase() == 'REFUNDED')
        context.l10n.ddRefundDone,
      if (stopped && status.isPaid && closedAfterFlight)
        context.l10n.ddRefundByIncident
      else if (stopped && status.isPaid)
        context.l10n.ddRefundNotRecorded,
    ];
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(stage.icon, color: color, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              lines.join('\n'),
              style: TextStyle(
                color: color,
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Quy tắc: đội bay chỉ tiếp nhận đơn đã thanh toán. Khách thanh toán ngay trên
/// thẻ này, điều phối viên thấy lý do chưa tiếp nhận được.
class _UnpaidBanner extends StatelessWidget {
  const _UnpaidBanner({
    required this.status,
    required this.forOperator,
    this.viewerIsBooker = true,
    this.onPay,
    this.onDeclineSurcharge,
  });

  final DroneDeliveryStatus status;
  final bool forOperator;
  final bool viewerIsBooker;
  final VoidCallback? onPay;
  final VoidCallback? onDeclineSurcharge;

  /// Đơn nợ phần phí chênh vì đội bay cân kiện nặng hơn khai báo.
  String _surchargeText() {
    final amount = fmtPrice(status.payableAmount ?? status.weightSurcharge);
    final weights =
        L10n.current.ddWeightOver(
      droneWeightLabel(status.payloadWeightGrams),
      droneWeightLabel(status.expectedWeightGrams),
    );
    if (forOperator) {
      return '$weights ${L10n.current.ddSurchargeOperator(amount)}';
    }
    if (!viewerIsBooker) {
      return '$weights ${L10n.current.ddSurchargeReceiver(amount)}';
    }
    return '$weights ${L10n.current.ddSurchargeSender(amount)}';
  }

  @override
  Widget build(BuildContext context) {
    const color = Color(0xFFB45309);
    final surcharge = status.needsSurchargePayment;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF3C7),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFCD34D)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(LucideIcons.creditCard, color: color, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  surcharge
                      ? _surchargeText()
                      : forOperator
                      ? context.l10n.ddUnpaidOperator
                      : !viewerIsBooker
                      ? context.l10n.ddUnpaidReceiver
                      : context.l10n.ddUnpaidSender,
                  style: const TextStyle(
                    color: color,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
          // Chỉ người đặt đơn trả tiền; người nhận chỉ xem lời nhắc.
          if (!forOperator && viewerIsBooker && onPay != null) ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(backgroundColor: color),
                onPressed: onPay,
                icon: const Icon(LucideIcons.wallet, size: 18),
                label: Text(
                  surcharge ? context.l10n.ddPaySurcharge : context.l10n.ddPayNow,
                ),
              ),
            ),
          ],
          if (!forOperator &&
              viewerIsBooker &&
              surcharge &&
              onDeclineSurcharge != null)
            SizedBox(
              width: double.infinity,
              child: TextButton(
                key: const ValueKey('drone-decline-surcharge'),
                style: TextButton.styleFrom(foregroundColor: color),
                onPressed: onDeclineSurcharge,
                child: Text(context.l10n.ddDeclineSurcharge),
              ),
            ),
        ],
      ),
    );
  }
}

/// Đơn đã thanh toán nhưng đang không phục vụ được (tạm dừng bay, phiếu sự cố trên
/// drone/tủ/bãi đáp…): lý do, phiếu liên quan, và bao giờ đơn tự kết thúc + hoàn tiền.
class _BlockBanner extends StatelessWidget {
  const _BlockBanner({required this.status, required this.forOperator});

  final DroneDeliveryStatus status;
  final bool forOperator;

  @override
  Widget build(BuildContext context) {
    const color = Color(0xFFB45309);
    final block = status.block!;
    final label = block.reasonLabel ?? droneFailureReasonLabel(block.reason);
    final lines = <String>[
      context.l10n.ddIncidentLabel(label),
      if (block.note != null) block.note!,
      if (block.ticketId != null) context.l10n.ddTicket('${block.ticketId}'),
      if (block.at != null) context.l10n.ddFromTime(formatDateTimeVn(block.at)),
      if (block.autoCloseAt != null)
        forOperator
            ? context.l10n.ddAutoCloseOperator(formatDateTimeVn(block.autoCloseAt))
              : context.l10n.ddAutoCloseCustomer(formatDateTimeVn(block.autoCloseAt))
      else
        forOperator
            ? context.l10n.ddChangePlan
            : context.l10n.ddTeamHandling,
    ];
    return Container(
      key: const ValueKey('drone-block-banner'),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF3C7),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFCD34D)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(LucideIcons.triangleAlert, color: color, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              lines.join('\n'),
              style: const TextStyle(
                color: color,
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Lấy hàng tận nhà: đang tìm kỹ thuật viên, ai đang tới, mã lấy hàng người gửi đọc cho
/// kỹ thuật viên, và điểm lấy hàng.
class _PickupCard extends StatelessWidget {
  const _PickupCard({
    required this.status,
    required this.forOperator,
    required this.isSender,
  });

  final DroneDeliveryStatus status;
  final bool forOperator;
  final bool isSender;

  String _headline(DronePickupInfo pickup) {
    if (pickup.isPickedUp) {
      return L10n.current.ddPickedUp(
        pickup.pickedUpAt == null
            ? ''
            : L10n.current.ddPickedUpAt(formatDateTimeVn(pickup.pickedUpAt)),
      );
    }
    if (pickup.isAccepted) {
      final who = pickup.technicianName ?? L10n.current.ddTechnician;
      return forOperator ? L10n.current.ddYouHeadingToPickup : L10n.current.ddTechHeadingToPickup(who);
    }
    if (pickup.isOffered || pickup.isSearching) {
      return forOperator
          ? L10n.current.ddYouAreInvited
          : L10n.current.ddSearchingTech;
    }
    return status.isPaid
        ? L10n.current.ddAwaitingDispatchPickup
        : L10n.current.ddTechAfterPayment;
  }

  @override
  Widget build(BuildContext context) {
    final pickup = status.pickup!;
    final code = pickup.pickupCode;
    final showCode =
        !forOperator && isSender && code != null && !pickup.isPickedUp;
    return _Card(
      title: context.l10n.ddHomePickup,
      icon: LucideIcons.house,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _headline(pickup),
            key: const ValueKey('drone-pickup-headline'),
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5),
          ),
          if (showCode) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
              decoration: BoxDecoration(
                color: const Color(0xFFEEF2FF),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Text(
                    context.l10n.ddPickupCode,
                    style: TextStyle(fontSize: 12, color: Color(0xFF4F46E5)),
                  ),
                  const SizedBox(height: 4),
                  SelectableText(
                    code,
                    key: const ValueKey('drone-pickup-code'),
                    style: const TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 6,
                      color: Color(0xFF312E81),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    context.l10n.ddPickupCodeHint,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: Color(0xFF4F46E5)),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          _Rows([
            (context.l10n.ddPickupPoint, pickup.address ?? '—'),
            if (pickup.note != null) (context.l10n.ddDirections, pickup.note!),
            if (pickup.technicianName != null &&
                (pickup.isAccepted || pickup.isPickedUp))
              (context.l10n.ddTechnician, pickup.technicianName!),
            if (!forOperator &&
                pickup.technicianPhone != null &&
                (pickup.isAccepted || pickup.isPickedUp))
              (context.l10n.ddTechPhone, pickup.technicianPhone!),
            if (pickup.isAccepted && pickup.technicianDistanceMeters != null)
              (
                context.l10n.ddDistanceAtAccept,
                droneDistanceLabel(pickup.technicianDistanceMeters),
              ),
            if (pickup.distanceToSourceLockerMeters != null)
              (
                context.l10n.ddPickupToSource,
                droneDistanceLabel(pickup.distanceToSourceLockerMeters),
              ),
            if (pickup.technicianNote != null)
              (context.l10n.ddPickupNote, pickup.technicianNote!),
          ]),
          if (pickup.pickupPhotoUrl case final photoUrl?) ...[
            const SizedBox(height: 12),
            Text(
              context.l10n.ddPickupPhoto,
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            InkWell(
              key: const ValueKey('drone-pickup-photo-thumbnail'),
              onTap: () => showDialog<void>(
                context: context,
                builder: (dialogContext) => Dialog(
                  backgroundColor: Colors.black,
                  insetPadding: const EdgeInsets.all(16),
                  child: Stack(
                    children: [
                      InteractiveViewer(
                        child: Center(
                          child: Image.network(
                            photoUrl,
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) => Padding(
                              padding: EdgeInsets.all(24),
                              child: Text(
                                context.l10n.attachmentLoadFailed,
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: IconButton(
                          onPressed: () => Navigator.pop(dialogContext),
                          icon: const Icon(Icons.close, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              borderRadius: BorderRadius.circular(10),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(
                  photoUrl,
                  key: const ValueKey('drone-pickup-photo-image'),
                  width: 88,
                  height: 88,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 88,
                    height: 88,
                    color: const Color(0xFFE2E8F0),
                    alignment: Alignment.center,
                    child: const Icon(Icons.broken_image_outlined),
                  ),
                ),
              ),
            ),
            if (pickup.pickupPhotoCapturedAt != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  context.l10n.ddPhotoTakenAt(formatDateTimeVn(pickup.pickupPhotoCapturedAt)),
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF64748B),
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

/// Đơn đã trả tiền nhưng ô gửi còn rỗng: nhắc người gửi bỏ kiện và xác nhận, vì đội
/// bay chỉ tiếp nhận đơn đã có kiện.
class _DropBanner extends StatelessWidget {
  const _DropBanner({
    required this.status,
    required this.forOperator,
    this.viewerIsBooker = true,
    this.onConfirmDrop,
  });

  final DroneDeliveryStatus status;
  final bool forOperator;
  final bool viewerIsBooker;
  final VoidCallback? onConfirmDrop;

  @override
  Widget build(BuildContext context) {
    const color = Color(0xFF1E5A8A);
    final box = status.sourceBoxNumber;
    final where = box == null
        ? context.l10n.ddDroneBoxAtSource
        : context.l10n.ddDroneBoxNumberAtSource(box);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFE0F2FE),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF7DD3FC)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(LucideIcons.packagePlus, color: color, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  forOperator
                      ? context.l10n.ddSenderNotDroppedOperator(where)
                      : !viewerIsBooker
                      ? context.l10n.ddWaitingSenderDrop(where)
            : context.l10n.ddDropThenConfirm(where),
                  style: const TextStyle(
                    color: color,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
          if (!forOperator && onConfirmDrop != null) ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                key: const ValueKey('drone-confirm-drop'),
                style: FilledButton.styleFrom(backgroundColor: color),
                onPressed: onConfirmDrop,
                icon: const Icon(LucideIcons.packageCheck, size: 18),
                label: Text(context.l10n.ddIDropped),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Đơn không giao được mà kiện đã vào hệ thống: kiện đang ở đâu, đã trả cho người gửi chưa.
class _ParcelReturnBanner extends StatelessWidget {
  const _ParcelReturnBanner({required this.status, required this.forOperator});

  final DroneDeliveryStatus status;
  final bool forOperator;

  @override
  Widget build(BuildContext context) {
    final returned = status.parcelReturnedAt != null;
    final color = returned ? const Color(0xFF16A34A) : const Color(0xFFB45309);
    final inSourceBox =
        (status.parcelHeldAt ?? '').toUpperCase() == 'SOURCE_BOX';
    final String text;
    if (returned) {
      text =
          '${context.l10n.ddParcelReturnedAt(formatDateTimeVn(status.parcelReturnedAt))}'
          '${status.parcelReturnNote == null ? '' : ' ${context.l10n.ddNoteValue('${status.parcelReturnNote}')}'}';
    } else if (forOperator) {
      text = inSourceBox
          ? context.l10n.ddParcelInBoxOperator
          : context.l10n.ddParcelWithTeamOperator;
    } else {
      text = inSourceBox
          ? context.l10n.ddParcelInBoxCustomer
          : context.l10n.ddParcelHeldByTech(
              status.pickup?.address == null
                  ? context.l10n.ddToSender
                  : context.l10n.ddAtAddress('${status.pickup!.address}'),
            );
    }
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            returned ? LucideIcons.packageCheck : LucideIcons.packageOpen,
            color: color,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: color,
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Quy tắc: người đặt huỷ được tới khi đội bay tiếp nhận; đơn đã trả tiền thì hệ
/// thống ghi yêu cầu hoàn tiền, admin chuyển khoản về tài khoản ngân hàng của khách.
class _CancelCard extends StatelessWidget {
  const _CancelCard({required this.status, required this.onCancel});

  final DroneDeliveryStatus status;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    const danger = Color(0xFFDC2626);
    return _Card(
      title: context.l10n.ddCancelOrder,
      icon: LucideIcons.circleX,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${context.l10n.ddCancelAllowed} '
              '${droneCancelRefundNote(isPaid: status.isPaid, totalPrice: status.totalPrice)}',
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF475569),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: danger,
                side: const BorderSide(color: danger),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onPressed: onCancel,
              icon: const Icon(LucideIcons.circleX, size: 18),
              label: Text(context.l10n.ddCancelOrder),
            ),
          ),
        ],
      ),
    );
  }
}

class _RouteCard extends StatelessWidget {
  const _RouteCard({required this.status, this.forOperator = false});

  final DroneDeliveryStatus status;

  /// KTV/đội bay xem: được chỉ đường tới drone ở tủ bay; khách không đi tới tủ bay (KTV lấy kiện tận
  /// nhà) nên không hiện nút đó, và nhãn tủ nhận nói theo người đọc.
  final bool forOperator;

  @override
  Widget build(BuildContext context) {
    final box = status.reservedBoxNumber;
    final sentAt = status.sentAt;
    final depositedAt = status.depositedAt;
    final code = status.pickupCodeEvent;
    return _Card(
      title: context.l10n.ddRoute,
      icon: LucideIcons.route,
      child: Column(
        children: [
          _RoutePoint(
            label: context.l10n.ddSystemPickedStation,
            point: status.sourceLocker,
            fallbackId: status.sourceLockerId,
            color: const Color(0xFF0F766E),
            extras: [
              if (status.pickup == null && status.sourceBoxNumber != null)
                context.l10n.ddLegacyBox('${status.sourceBoxNumber}'),
              context.l10n.ddSentAt(formatDateTimeVn(sentAt, empty: context.l10n.ddNotSentYet)),
            ],
            directionsLabel: forOperator ? context.l10n.ddDirectionsToDrone : null,
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: Container(
              width: 2,
              height: 20,
              margin: const EdgeInsets.only(left: 5, top: 6, bottom: 6),
              color: const Color(0xFFCBD5E1),
            ),
          ),
          _RoutePoint(
            label: forOperator
                ? context.l10n.ddReceiverLockerOperator
                : context.l10n.ddReceiverLockerCustomer,
            point: status.destinationLocker,
            fallbackId: status.destinationLockerId,
            color: AISLShadcnTheme.navyAccent,
            extras: [
              if (box != null) context.l10n.ddReceiveBox(box),
              context.l10n.ddDepositedAt(formatDateTimeVn(depositedAt, empty: context.l10n.ddNotArrived)),
              if (code?.occurredAt != null)
                context.l10n.ddCodeSentAt(formatDateTimeVn(code!.occurredAt)),
              context.l10n.ddReceivedAt(
            formatDateTimeVn(status.completedAt, empty: context.l10n.ddNotReceived),
          ),
            ],
            directionsLabel: context.l10n.ddDirectionsToReceiver,
            primary: true,
          ),
        ],
      ),
    );
  }
}

class _RoutePoint extends StatelessWidget {
  const _RoutePoint({
    required this.label,
    required this.point,
    required this.fallbackId,
    required this.color,
    required this.directionsLabel,
    this.extras = const [],
    this.primary = false,
  });

  final String label;
  final DroneLockerPoint? point;
  final int? fallbackId;
  final Color color;

  /// null ⇒ không có nút chỉ đường.
  final String? directionsLabel;
  final List<String> extras;
  final bool primary;

  /// Có toạ độ ⇒ mở bản đồ chỉ đường trong app; chỉ có địa chỉ ⇒ mở ứng dụng
  /// bản đồ của máy. Nút luôn bấm được: thiếu cả hai thì báo rõ lý do thay vì
  /// im lặng (nút bị khoá trước đây trông như không bấm được).
  Future<void> _openDirections(BuildContext context) async {
    final target = point;
    final messenger = ScaffoldMessenger.of(context);
    if (target == null || !target.canNavigate) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(context.l10n.ddLockerNoAddress),
        ),
      );
      return;
    }
    if (target.hasCoordinates) {
      context.push(
        AppRouter.directions,
        extra: <String, dynamic>{
          'lat': target.latitude,
          'lng': target.longitude,
          'title': target.displayName,
          'subtitle': target.address,
        },
      );
      return;
    }
    final result = await openLockerDirectionsResult(address: target.address);
    if (result != DirectionsResult.opened) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(L10n.current.ddCantOpenMaps),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final target = point;
    final name =
        target?.displayName ??
        (fallbackId == null ? context.l10n.commonUndetermined : context.l10n.lockerHash('$fallbackId'));
    final address = (target?.address ?? '').trim();
    final button = primary
        ? FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: AISLShadcnTheme.navyPrimary,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            onPressed: () => _openDirections(context),
            icon: const Icon(LucideIcons.navigation, size: 18),
            label: Text(directionsLabel ?? ''),
          )
        : OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: AISLShadcnTheme.navyPrimary,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            onPressed: () => _openDirections(context),
            icon: const Icon(LucideIcons.navigation, size: 18),
            label: Text(directionsLabel ?? ''),
          );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 12,
              height: 12,
              margin: const EdgeInsets.only(top: 4),
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF64748B),
                    ),
                  ),
                  Text(
                    name,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  if (address.isNotEmpty)
                    Text(
                      address,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  for (final extra in extras)
                    Text(
                      extra,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AISLShadcnTheme.navyAccent,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
        if (directionsLabel != null) ...[
          const SizedBox(height: 10),
          SizedBox(width: double.infinity, child: button),
        ],
      ],
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({required this.status});

  final DroneDeliveryStatus status;

  @override
  Widget build(BuildContext context) {
    final box = status.reservedBoxNumber;
    return _Card(
      title: context.l10n.ddOrderInfo,
      icon: LucideIcons.package,
      child: _Rows([
        (context.l10n.ddOrderCode, status.orderCode ?? '—'),
        (
          context.l10n.ddOrderStatus,
          // Kiện đã rơi: đơn vẫn AWAITING_DISPATCH tới khi khách chọn phương án,
          // không được ghi "Đang giao bằng drone".
          status.stage == DroneDeliveryStage.dropReported &&
                  (status.orderStatus ?? '').toUpperCase() == 'AWAITING_DISPATCH'
              ? context.l10n.ddPausedDrop
              : droneOrderStatusLabel(status.orderStatus),
        ),
        (context.l10n.ddTlPayment, dronePaymentStatusLabel(status.paymentStatus)),
        // Phí gốc, rồi từng khoản giảm, rồi số tiền thực trả — không hiện số sau
        // khi trừ điểm dưới nhãn "Phí giao drone".
        (
          context.l10n.ddDroneFee,
          (status.originalPrice ?? 0) > 0
              ? fmtPrice(status.originalPrice)
              : status.totalPrice == null
              ? '—'
              : fmtPrice(status.totalPrice),
        ),
        if ((status.weightSurcharge ?? 0) > 0)
          (context.l10n.ddWeightSurcharge, fmtPrice(status.weightSurcharge)),
        if ((status.discount ?? 0) > 0)
          (
            status.promotionCode == null || status.promotionCode!.isEmpty
                ? context.l10n.commonDiscountCode
                : context.l10n.ddDiscountCodeValue('${status.promotionCode}'),
            '-${fmtPrice(status.discount)}',
          ),
        if ((status.pointsDiscount ?? 0) > 0)
          (
            context.l10n.ddUsePoints(fmtPrice(status.pointsUsed ?? 0).replaceAll('đ', '')),
            '-${fmtPrice(status.pointsDiscount)}',
          ),
        if ((status.originalPrice ?? 0) > 0 &&
            status.totalPrice != null &&
            status.totalPrice != status.originalPrice)
          (context.l10n.ddAmountPaid, fmtPrice(status.totalPrice)),
        if (status.paymentMethod != null)
          (context.l10n.ddMethod, dronePaymentMethodLabel(status.paymentMethod)),
        if (status.paymentReference != null)
          (context.l10n.ddPaymentRef, status.paymentReference!),
        if (status.paymentTransactionId != null)
          (context.l10n.ordTransactionId, status.paymentTransactionId!),
        if (status.paidAt != null)
          (context.l10n.ordPaidAt, formatDateTimeVn(status.paidAt)),
        (
          context.l10n.recvReceivingLocker,
          status.destinationLocker?.displayName ??
              (status.destinationLockerId == null
                  ? context.l10n.commonUndetermined
                  : context.l10n.lockerHash('${status.destinationLockerId}')),
        ),
        (context.l10n.ddBoxAtLocker, box == null ? context.l10n.ordBoxNotAssigned : context.l10n.boxNumberLabel(box)),
        (context.l10n.ddDeclaredWeight, droneWeightLabel(status.expectedWeightGrams)),
        if (status.parcelCategory != null)
          (context.l10n.parcelCategory, droneParcelCategoryLabel(status.parcelCategory)),
        if (droneParcelSizeLabel(
              status.parcelLengthCm,
              status.parcelWidthCm,
              status.parcelHeightCm,
            ) !=
            null)
          (
            context.l10n.ddParcelSize,
            droneParcelSizeLabel(
              status.parcelLengthCm,
              status.parcelWidthCm,
              status.parcelHeightCm,
            )!,
          ),
        if (status.declaredValue != null)
          (context.l10n.parcelDeclaredValue, fmtPrice(status.declaredValue)),
        if (status.fragile == true) (context.l10n.ddCaution, context.l10n.parcelFragile),
        // Lấy hàng tận nhà: mốc này là lúc KTV nhận kiện, không có bước bỏ vào ô gửi.
        if (status.parcelDroppedAt != null)
          (
            status.pickup == null ? context.l10n.ddDroppedAtLabel : context.l10n.ddTechReceivedAt,
            formatDateTimeVn(status.parcelDroppedAt),
          ),
        if (status.routeDistanceMeters != null)
          (
            context.l10n.ordFlightDistance,
            status.routeDistanceMeters! < 1000
                ? '${status.routeDistanceMeters} m'
                : '${(status.routeDistanceMeters! / 1000).toStringAsFixed(1)} km',
          ),
        (context.l10n.ddParcelDescription, status.description ?? context.l10n.ddNoDescription),
        (context.l10n.ddFlightMode, droneFulfillmentModeLabel(status.fulfillmentMode)),
      ]),
    );
  }
}

class _PeopleCard extends StatelessWidget {
  const _PeopleCard({required this.status, required this.forOperator});

  final DroneDeliveryStatus status;
  final bool forOperator;

  @override
  Widget build(BuildContext context) {
    return _Card(
      title: context.l10n.ddPeople,
      icon: LucideIcons.users,
      child: _Rows([
        (context.l10n.recvSender, status.senderName ?? status.customerName ?? '—'),
        (context.l10n.recvSenderPhone, status.senderPhone ?? status.customerPhone ?? '—'),
        if (status.senderEmail != null)
          (context.l10n.recvSenderEmail, status.senderEmail!),
        (context.l10n.ordRecipient, status.receiverName ?? status.customerName ?? '—'),
        (context.l10n.recvRecipientPhone, status.receiverPhone ?? status.customerPhone ?? '—'),
        if (status.receiverEmail != null)
          (context.l10n.ordRecipientEmail, status.receiverEmail!),
        (
          context.l10n.ddDroneTech,
          status.assignedByName ??
              status.pickup?.technicianName ??
              (status.assignedByUserId == null
                  ? context.l10n.ddNoTechYet
                  : context.l10n.ddTechAccepted),
        ),
        (
          context.l10n.ddLoader,
          status.loadedByName ??
              (status.loadedByUserId == null ? context.l10n.ddNotLoaded : context.l10n.ddLoaded),
        ),
      ]),
    );
  }
}

class _MissionCard extends StatelessWidget {
  const _MissionCard({required this.status});

  final DroneDeliveryStatus status;

  static String _check(bool? value) =>
      value == null ? L10n.current.ddNotChecked : (value ? L10n.current.ddPass : L10n.current.ddFail);

  @override
  Widget build(BuildContext context) {
    return _Card(
      title: context.l10n.ddMissionRecord,
      icon: LucideIcons.clipboardList,
      child: _Rows([
        (
          context.l10n.ddMissionCode,
          status.deliveryId == null ? context.l10n.msNotInit : '#${status.deliveryId}',
        ),
        ('Drone', status.droneCode ?? context.l10n.ddNotAssigned),
        (context.l10n.ddMissionStatus, droneMissionStatusLabel(status.missionStatus)),
        // Một chuỗi "vĩ độ, kinh độ" để copy dán thẳng vào Google Maps; thẻ hành trình phía trên
        // có bản bấm mở bản đồ và cập nhật trực tiếp.
        (
          context.l10n.ddDronePosition,
          status.currentLatitude != null && status.currentLongitude != null
              ? droneCoordinateLabel(
                  status.currentLatitude!,
                  status.currentLongitude!,
                )
              : context.l10n.ddNoData,
        ),
        (context.l10n.ddActualWeight, droneWeightLabel(status.payloadWeightGrams)),
        (context.l10n.ddSealCode, status.sealCode ?? context.l10n.ddNotSealed),
        (context.l10n.ddParcelMatched, _check(status.parcelMatched)),
        (context.l10n.ddPayloadSecured, _check(status.payloadSecured)),
        (context.l10n.ddCompartmentLocked, _check(status.compartmentLocked)),
        if (status.loadingNote != null)
          (context.l10n.ddLoadingNote, status.loadingNote!),
      ]),
    );
  }
}

class _JourneyCard extends StatelessWidget {
  const _JourneyCard({required this.events});

  final List<DroneJourneyEvent> events;

  /// Tiêu đề một dòng nhật ký. Xác nhận nạp hàng được ghi là ACCEPTED → ACCEPTED
  /// nên cần tên riêng, nếu không sẽ trùng với dòng "Đội bay đã tiếp nhận".
  static String _title(DroneJourneyEvent event) {
    final from = (event.fromStage ?? '').toUpperCase();
    final to = event.toStage.toUpperCase();
    if (from == 'ACCEPTED' && to == 'ACCEPTED') return L10n.current.ddEvLoaded;
    if (event.isPickupCodeSent) return L10n.current.ddEvCodeSent;
    if (from.isEmpty && to == 'AWAITING_DISPATCH') return L10n.current.ddEvCreated;
    return DroneDeliveryStage.fromRaw(to).title;
  }

  @override
  Widget build(BuildContext context) {
    return _Card(
      title: context.l10n.ddJourneyLog,
      icon: LucideIcons.history,
      child: events.isEmpty
          ? Text(
              context.l10n.ddNoJourney,
              style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
            )
          : Column(
              children: [
                for (var i = 0; i < events.length; i++) ...[
                  _JourneyRow(
                    event: events[i],
                    title: _title(events[i]),
                    latest: i == 0,
                  ),
                  if (i != events.length - 1) const Divider(height: 22),
                ],
              ],
            ),
    );
  }
}

class _JourneyRow extends StatelessWidget {
  const _JourneyRow({
    required this.event,
    required this.title,
    required this.latest,
  });

  final DroneJourneyEvent event;
  final String title;
  final bool latest;

  @override
  Widget build(BuildContext context) {
    final stage = DroneDeliveryStage.fromRaw(event.toStage);
    final actor =
        event.actorName ??
        (event.actorUserId == null ? context.l10n.ddSystem : context.l10n.ddLockrStaff);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(stage.icon, size: 18, color: stage.color),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                  if (latest) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDCFCE7),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        context.l10n.ddNewest,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF15803D),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              if ((event.note ?? '').isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    event.note!,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF475569),
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  '${formatDateTimeVn(event.occurredAt)} · $actor',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF94A3B8),
                  ),
                ),
              ),
              if (event.hasLocation)
                JourneyLocationLine(
                  latitude: event.latitude!,
                  longitude: event.longitude!,
                  source: event.locationSource,
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.title, required this.icon, required this.child});

  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: const Color(0xFFE2E8F0)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: AISLShadcnTheme.navyPrimary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        child,
      ],
    ),
  );
}

/// Danh sách dòng nhãn – giá trị, ngăn bằng đường kẻ mảnh.
class _Rows extends StatelessWidget {
  const _Rows(this.rows);

  final List<(String, String)> rows;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      for (var i = 0; i < rows.length; i++) ...[
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 132,
              child: Text(
                rows[i].$1,
                style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
              ),
            ),
            Expanded(
              child: Text(
                rows[i].$2,
                textAlign: TextAlign.right,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        if (i != rows.length - 1) const Divider(height: 18),
      ],
    ],
  );
}
