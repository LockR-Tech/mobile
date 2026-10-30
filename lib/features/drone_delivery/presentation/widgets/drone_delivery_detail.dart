import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:smart_laundry_locker/core/routing/app_router.dart';
import 'package:smart_laundry_locker/core/theme/shadcn_theme.dart';
import 'package:smart_laundry_locker/core/utils/app_date_time.dart';
import 'package:smart_laundry_locker/features/drone_delivery/domain/entities/drone_booking.dart';
import 'package:smart_laundry_locker/features/drone_delivery/domain/entities/drone_delivery_stage.dart';
import 'package:smart_laundry_locker/features/drone_delivery/domain/entities/drone_delivery_status.dart';
import 'package:smart_laundry_locker/features/drone_delivery/domain/entities/drone_labels.dart';
import 'package:smart_laundry_locker/features/drone_delivery/domain/entities/drone_parcel.dart';
import 'package:smart_laundry_locker/features/drone_delivery/presentation/widgets/drone_delivery_timeline.dart';
import 'package:smart_laundry_locker/features/drone_delivery/presentation/widgets/drone_order_cancel.dart';
import 'package:smart_laundry_locker/features/drone_delivery/presentation/widgets/drone_route_map_card.dart';
import 'package:smart_laundry_locker/features/locker_ops/presentation/utils/locker_maps.dart';
import 'package:smart_laundry_locker/features/locker_ops/presentation/widgets/ops_widgets.dart';

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
      DroneTimelineDetail('Thanh toán', status.paidAt),
      // Đơn cũ: người gửi tự mang kiện ra ô gửi.
      if (status.pickup == null)
        DroneTimelineDetail('Bỏ kiện vào ô gửi', status.parcelDroppedAt),
    ],
    if (status.pickup != null)
      DroneDeliveryStage.pickedUp: [
        DroneTimelineDetail(
          'Lấy hàng tại nhà người gửi',
          status.pickup!.pickedUpAt,
        ),
      ],
    DroneDeliveryStage.accepted: [
      DroneTimelineDetail('Nạp hàng lên drone', status.loadedAt),
      DroneTimelineDetail('Sẵn sàng phóng', status.readyToLaunchAt),
    ],
    if (reachedPickup)
      DroneDeliveryStage.readyForPickup: [
        DroneTimelineDetail(
          'Gửi mã cho người nhận',
          codeEvent?.occurredAt,
          note: codeEvent?.note,
        ),
        DroneTimelineDetail('Hạn nhận hàng', status.pickupDeadline),
        DroneTimelineDetail('Người nhận lấy hàng', status.completedAt),
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
        const SizedBox(height: 16),
        DroneRouteMapCard(status: status, forOperator: forOperator),
        const SizedBox(height: 16),
        _RouteCard(status: status, forOperator: forOperator),
        const SizedBox(height: 16),
        _Card(
          title: 'Tiến trình giao hàng',
          icon: LucideIcons.listChecks,
          child: DroneDeliveryTimeline(
            stage: stage,
            stageTimes: droneStageTimes(status),
            stepDetails: droneStepDetails(status),
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

String? _etaText(int? minutes) => minutes == null ? null : '$minutes phút';

/// Tiêu đề + mô tả của thẻ đầu trang. Câu mặc định theo chặng sai ở vài trường hợp (test 2026-10-29):
/// đơn đóng sau khi drone đã bay (rơi kiện) bị ghi "dừng trước khi drone cất cánh", đơn chưa trả tiền
/// ghi "đang tìm kỹ thuật viên", đơn đã nạp xong vẫn ghi "đang nạp hàng".
({String title, String body}) _headerText(DroneDeliveryStatus status) {
  final stage = status.stage;
  if (stage == DroneDeliveryStage.canceled && status.launchingAt != null) {
    return (
      title: 'Đơn drone đã đóng',
      body: 'Chuyến bay không hoàn tất nên đơn này đã đóng; phương án xử lý '
          'xem ở phần sự cố của đơn.',
    );
  }
  if (stage == DroneDeliveryStage.awaitingDispatch && !status.isPaid) {
    return (
      title: 'Chờ thanh toán',
      body: 'Thanh toán xong hệ thống mới tìm kỹ thuật viên drone tới lấy hàng',
    );
  }
  // Không lấy hàng tận nhà (đơn giao lại sau sự cố, đơn gửi tại tủ): kiện đã nằm ở kho / trạm, không
  // còn "tìm kỹ thuật viên gần bạn" (test 2026-10-29, đơn giao lại #144).
  if (stage == DroneDeliveryStage.awaitingDispatch && status.pickup == null) {
    return (
      title: 'Chờ đội bay tiếp nhận',
      body: 'Kiện đã sẵn sàng tại trạm Lock.R, chờ kỹ thuật viên drone nạp hàng và phóng',
    );
  }
  if (stage == DroneDeliveryStage.accepted &&
      (status.missionStatus ?? '').toUpperCase() == 'READY_TO_LAUNCH') {
    return (
      title: 'Sẵn sàng phóng',
      body: 'Kiện đã được nạp và niêm phong trên drone, chờ đội bay phóng',
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
                  label: 'Đơn ${status.orderCode}',
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
                  label: 'Còn khoảng ${status.etaMinutes} phút',
                ),
              if (changedAt != null)
                _InfoChip(
                  icon: LucideIcons.history,
                  label: 'Từ ${formatDateTimeVn(changedAt)}',
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
          ? 'Chuyến bay không hoàn tất nên đơn này đã đóng. Phương án xử lý '
                '(giao lại hoặc bồi thường) xem ở phần sự cố của đơn.'
          : awaitingPayment
          ? 'Đơn chưa thanh toán. Thanh toán xong hệ thống mới bắt đầu tìm '
                'kỹ thuật viên drone tới lấy hàng.'
          : stage.body(_etaText(status.etaMinutes)),
      if (endedAt != null) 'Lúc: ${formatDateTimeVn(endedAt)}',
      if (stopped && reason != null) 'Lý do: $reason',
      if (stopped && status.cancelNote != null) 'Ghi chú: ${status.cancelNote}',
      if (failure?.ticketId != null) 'Phiếu sự cố: #${failure!.ticketId}',
      if (stage == DroneDeliveryStage.failed && !parcelCollected)
        'Kiện hàng chưa được lấy, vẫn ở chỗ người gửi.',
      if (stopped &&
          (status.paymentStatus ?? '').toUpperCase() == 'REFUND_PENDING')
        'Yêu cầu hoàn tiền đã được ghi nhận. Admin sẽ chuyển khoản về tài '
            'khoản ngân hàng của người đặt.',
      if (stopped && (status.paymentStatus ?? '').toUpperCase() == 'REFUNDED')
        'Tiền đã được chuyển khoản hoàn cho người đặt.',
      if (stopped && status.isPaid && closedAfterFlight)
        'Khoản đã trả được xử lý theo phương án sự cố: giao lại miễn phí '
            'hoặc bồi thường chuyển khoản về tài khoản ngân hàng đã liên kết.'
      else if (stopped && status.isPaid)
        'Chưa ghi nhận được yêu cầu hoàn tiền — vui lòng liên hệ hỗ trợ.',
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
        'Kiện cân thực tế ${droneWeightLabel(status.payloadWeightGrams)}, nặng hơn '
        'mức ${droneWeightLabel(status.expectedWeightGrams)} đã khai báo.';
    if (forOperator) {
      return '$weights Chờ khách trả thêm $amount rồi mới phóng được.';
    }
    if (!viewerIsBooker) {
      return '$weights Đang chờ người gửi trả thêm $amount để drone cất cánh.';
    }
    return '$weights Bạn cần trả thêm $amount để drone cất cánh. Không đồng ý thì '
        'bạn có thể huỷ đơn: phần đã trả được hoàn và đội bay trả lại kiện.';
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
                      ? 'Khách chưa thanh toán. Chỉ tiếp nhận được sau khi đơn đã thanh toán.'
                      : !viewerIsBooker
                      ? 'Người gửi chưa thanh toán đơn. Đội bay tiếp nhận sau khi người gửi thanh toán.'
                      : 'Đơn chưa thanh toán. Đội bay chỉ tiếp nhận sau khi bạn thanh toán.',
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
                  surcharge ? 'Trả thêm phí chênh' : 'Thanh toán ngay',
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
                child: const Text('Không đồng ý · huỷ đơn và nhận hoàn tiền'),
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
      'Đơn đang gặp sự cố: $label',
      if (block.note != null) block.note!,
      if (block.ticketId != null) 'Phiếu sự cố: #${block.ticketId}',
      if (block.at != null) 'Từ lúc: ${formatDateTimeVn(block.at)}',
      if (block.autoCloseAt != null)
        forOperator
            ? 'Chưa khắc phục trước ${formatDateTimeVn(block.autoCloseAt)} thì đơn '
                  'tự kết thúc "giao không hoàn tất" và hoàn tiền cho khách.'
            : 'Nếu chưa khắc phục được trước ${formatDateTimeVn(block.autoCloseAt)}, '
                  'đơn sẽ kết thúc và bạn được hoàn tiền.'
      else
        forOperator
            ? 'Đổi phương án hoặc xác nhận giao không hoàn tất.'
            : 'Đội bay đang xử lý.',
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
      return 'Đã lấy hàng${pickup.pickedUpAt == null ? '' : ' lúc ${formatDateTimeVn(pickup.pickedUpAt)}'}';
    }
    if (pickup.isAccepted) {
      final who = pickup.technicianName ?? 'Kỹ thuật viên';
      return forOperator ? 'Bạn đang tới lấy hàng' : '$who đang tới lấy hàng';
    }
    if (pickup.isOffered || pickup.isSearching) {
      return forOperator
          ? 'Bạn được mời lấy hàng'
          : 'Đang tìm kỹ thuật viên drone gần bạn nhất';
    }
    return status.isPaid
        ? 'Chờ điều phối lấy hàng'
        : 'Kỹ thuật viên sẽ tới lấy hàng sau khi đơn được thanh toán';
  }

  @override
  Widget build(BuildContext context) {
    final pickup = status.pickup!;
    final code = pickup.pickupCode;
    final showCode =
        !forOperator && isSender && code != null && !pickup.isPickedUp;
    return _Card(
      title: 'Lấy hàng tận nhà',
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
                  const Text(
                    'Mã lấy hàng',
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
                  const Text(
                    'Đọc mã này cho kỹ thuật viên khi giao kiện. Không gửi mã cho '
                    'người khác.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: Color(0xFF4F46E5)),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          _Rows([
            ('Điểm lấy hàng', pickup.address ?? '—'),
            if (pickup.note != null) ('Chỉ dẫn', pickup.note!),
            if (pickup.technicianName != null &&
                (pickup.isAccepted || pickup.isPickedUp))
              ('Kỹ thuật viên', pickup.technicianName!),
            if (!forOperator &&
                pickup.technicianPhone != null &&
                (pickup.isAccepted || pickup.isPickedUp))
              ('SĐT kỹ thuật viên', pickup.technicianPhone!),
            if (pickup.isAccepted && pickup.technicianDistanceMeters != null)
              (
                'Cách điểm lấy lúc nhận việc',
                droneDistanceLabel(pickup.technicianDistanceMeters),
              ),
            if (pickup.distanceToSourceLockerMeters != null)
              (
                'Điểm lấy hàng → tủ gửi',
                droneDistanceLabel(pickup.distanceToSourceLockerMeters),
              ),
            if (pickup.technicianNote != null)
              ('Ghi chú lúc lấy hàng', pickup.technicianNote!),
          ]),
          if (pickup.pickupPhotoUrl case final photoUrl?) ...[
            const SizedBox(height: 12),
            const Text(
              'Ảnh kiện lúc lấy hàng',
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
                            errorBuilder: (_, __, ___) => const Padding(
                              padding: EdgeInsets.all(24),
                              child: Text(
                                'Không tải được ảnh',
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
                  'Chụp lúc ${formatDateTimeVn(pickup.pickupPhotoCapturedAt)}',
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
    final where = box == null ? 'ô drone ở tủ gửi' : 'ô drone số $box ở tủ gửi';
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
                      ? 'Người gửi chưa xác nhận bỏ kiện vào $where. Chỉ tiếp nhận '
                            'được sau khi kiện đã nằm trong ô.'
                      : !viewerIsBooker
                      ? 'Đang chờ người gửi bỏ kiện vào $where.'
                      : 'Bỏ kiện vào $where rồi xác nhận bên dưới. Đội bay chỉ tiếp '
                            'nhận đơn sau khi bạn xác nhận.',
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
                label: const Text('Tôi đã bỏ kiện vào ô'),
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
          'Kiện đã được trả lại cho người gửi lúc '
          '${formatDateTimeVn(status.parcelReturnedAt)}.'
          '${status.parcelReturnNote == null ? '' : ' Ghi chú: ${status.parcelReturnNote}'}';
    } else if (forOperator) {
      text = inSourceBox
          ? 'Kiện còn trong ô gửi. Lấy kiện ra, trả cho người gửi rồi xác nhận đã trả.'
          : 'Kiện đang do đội bay giữ. Trả cho người gửi rồi xác nhận đã trả.';
    } else {
      text = inSourceBox
          ? 'Kiện của bạn còn trong ô gửi. Đội bay sẽ liên hệ để trả lại kiện.'
          : 'Kiện đang do kỹ thuật viên giữ và sẽ được mang trả lại'
                '${status.pickup?.address == null ? ' cho người gửi' : ' tại ${status.pickup!.address}'}.';
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
      title: 'Huỷ đơn',
      icon: LucideIcons.circleX,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Bạn huỷ được đơn khi đội bay chưa tiếp nhận. '
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
              label: const Text('Huỷ đơn'),
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
      title: 'Lộ trình giao hàng',
      icon: LucideIcons.route,
      child: Column(
        children: [
          _RoutePoint(
            label: 'Tủ bay do hệ thống chọn (KTV nạp kiện trực tiếp lên drone)',
            point: status.sourceLocker,
            fallbackId: status.sourceLockerId,
            color: const Color(0xFF0F766E),
            extras: [
              if (status.pickup == null && status.sourceBoxNumber != null)
                'Đơn cũ: kiện từng được gửi vào ô số ${status.sourceBoxNumber}',
              'Gửi đi lúc: ${formatDateTimeVn(sentAt, empty: 'Chưa gửi')}',
            ],
            directionsLabel: forOperator ? 'Chỉ đường tới drone tại tủ bay' : null,
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
                ? 'Tủ nhận khách đã chọn (người nhận lấy hàng)'
                : 'Tủ nhận bạn đã chọn (người nhận lấy hàng)',
            point: status.destinationLocker,
            fallbackId: status.destinationLockerId,
            color: AISLShadcnTheme.navyAccent,
            extras: [
              if (box != null) 'Ô nhận số $box',
              'Hàng vào tủ lúc: ${formatDateTimeVn(depositedAt, empty: 'Chưa tới')}',
              if (code?.occurredAt != null)
                'Gửi mã cho người nhận lúc: ${formatDateTimeVn(code!.occurredAt)}',
              'Người nhận lấy hàng lúc: '
                  '${formatDateTimeVn(status.completedAt, empty: 'Chưa nhận')}',
            ],
            directionsLabel: 'Chỉ đường tới tủ nhận',
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
        const SnackBar(
          content: Text('Tủ này chưa có địa chỉ hoặc toạ độ để chỉ đường.'),
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
        const SnackBar(
          content: Text('Không mở được ứng dụng bản đồ trên thiết bị.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final target = point;
    final name =
        target?.displayName ??
        (fallbackId == null ? 'Chưa xác định' : 'Tủ #$fallbackId');
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
      title: 'Thông tin đơn hàng',
      icon: LucideIcons.package,
      child: _Rows([
        ('Mã đơn', status.orderCode ?? '—'),
        (
          'Trạng thái đơn',
          // Kiện đã rơi: đơn vẫn AWAITING_DISPATCH tới khi khách chọn phương án,
          // không được ghi "Đang giao bằng drone".
          status.stage == DroneDeliveryStage.dropReported &&
                  (status.orderStatus ?? '').toUpperCase() == 'AWAITING_DISPATCH'
              ? 'Tạm dừng do sự cố rơi kiện'
              : droneOrderStatusLabel(status.orderStatus),
        ),
        ('Thanh toán', dronePaymentStatusLabel(status.paymentStatus)),
        // Phí gốc, rồi từng khoản giảm, rồi số tiền thực trả — không hiện số sau
        // khi trừ điểm dưới nhãn "Phí giao drone".
        (
          'Phí giao drone',
          (status.originalPrice ?? 0) > 0
              ? fmtPrice(status.originalPrice)
              : status.totalPrice == null
              ? '—'
              : fmtPrice(status.totalPrice),
        ),
        if ((status.weightSurcharge ?? 0) > 0)
          ('Trong đó thu thêm do cân lệch', fmtPrice(status.weightSurcharge)),
        if ((status.discount ?? 0) > 0)
          (
            status.promotionCode == null || status.promotionCode!.isEmpty
                ? 'Mã giảm giá'
                : 'Mã giảm giá ${status.promotionCode}',
            '-${fmtPrice(status.discount)}',
          ),
        if ((status.pointsDiscount ?? 0) > 0)
          (
            'Dùng ${fmtPrice(status.pointsUsed ?? 0).replaceAll('đ', '')} điểm',
            '-${fmtPrice(status.pointsDiscount)}',
          ),
        if ((status.originalPrice ?? 0) > 0 &&
            status.totalPrice != null &&
            status.totalPrice != status.originalPrice)
          ('Số tiền thanh toán', fmtPrice(status.totalPrice)),
        if (status.paymentMethod != null)
          ('Phương thức', dronePaymentMethodLabel(status.paymentMethod)),
        if (status.paymentReference != null)
          ('Mã thanh toán', status.paymentReference!),
        if (status.paymentTransactionId != null)
          ('Mã giao dịch', status.paymentTransactionId!),
        if (status.paidAt != null)
          ('Thanh toán lúc', formatDateTimeVn(status.paidAt)),
        (
          'Tủ nhận',
          status.destinationLocker?.displayName ??
              (status.destinationLockerId == null
                  ? 'Chưa xác định'
                  : 'Tủ #${status.destinationLockerId}'),
        ),
        ('Ô nhận tại tủ', box == null ? 'Chưa gán ô' : 'Ô số $box'),
        ('Khối lượng khai báo', droneWeightLabel(status.expectedWeightGrams)),
        if (status.parcelCategory != null)
          ('Loại hàng', droneParcelCategoryLabel(status.parcelCategory)),
        if (droneParcelSizeLabel(
              status.parcelLengthCm,
              status.parcelWidthCm,
              status.parcelHeightCm,
            ) !=
            null)
          (
            'Kích thước kiện',
            droneParcelSizeLabel(
              status.parcelLengthCm,
              status.parcelWidthCm,
              status.parcelHeightCm,
            )!,
          ),
        if (status.declaredValue != null)
          ('Giá trị khai báo', fmtPrice(status.declaredValue)),
        if (status.fragile == true) ('Lưu ý', 'Hàng dễ vỡ'),
        // Lấy hàng tận nhà: mốc này là lúc KTV nhận kiện, không có bước bỏ vào ô gửi.
        if (status.parcelDroppedAt != null)
          (
            status.pickup == null ? 'Bỏ kiện vào ô gửi lúc' : 'KTV nhận kiện lúc',
            formatDateTimeVn(status.parcelDroppedAt),
          ),
        if (status.routeDistanceMeters != null)
          (
            'Quãng đường bay',
            status.routeDistanceMeters! < 1000
                ? '${status.routeDistanceMeters} m'
                : '${(status.routeDistanceMeters! / 1000).toStringAsFixed(1)} km',
          ),
        ('Mô tả kiện hàng', status.description ?? 'Không có mô tả'),
        ('Hình thức bay', droneFulfillmentModeLabel(status.fulfillmentMode)),
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
      title: 'Người liên quan',
      icon: LucideIcons.users,
      child: _Rows([
        ('Người gửi', status.senderName ?? status.customerName ?? '—'),
        ('SĐT người gửi', status.senderPhone ?? status.customerPhone ?? '—'),
        if (status.senderEmail != null)
          ('Email người gửi', status.senderEmail!),
        ('Người nhận', status.receiverName ?? status.customerName ?? '—'),
        ('SĐT người nhận', status.receiverPhone ?? status.customerPhone ?? '—'),
        if (status.receiverEmail != null)
          ('Email người nhận', status.receiverEmail!),
        (
          'Kỹ thuật viên drone',
          status.assignedByName ??
              status.pickup?.technicianName ??
              (status.assignedByUserId == null
                  ? 'Chưa có người nhận việc'
                  : 'Đã nhận việc'),
        ),
        (
          'Người nạp hàng',
          status.loadedByName ??
              (status.loadedByUserId == null ? 'Chưa nạp hàng' : 'Đã nạp'),
        ),
      ]),
    );
  }
}

class _MissionCard extends StatelessWidget {
  const _MissionCard({required this.status});

  final DroneDeliveryStatus status;

  static String _check(bool? value) =>
      value == null ? 'Chưa kiểm' : (value ? 'Đạt' : 'Không đạt');

  @override
  Widget build(BuildContext context) {
    return _Card(
      title: 'Nhiệm vụ bay & hồ sơ nạp hàng',
      icon: LucideIcons.clipboardList,
      child: _Rows([
        (
          'Mã nhiệm vụ',
          status.deliveryId == null ? 'Chưa khởi tạo' : '#${status.deliveryId}',
        ),
        ('Drone', status.droneCode ?? 'Chưa phân công'),
        ('Trạng thái nhiệm vụ', droneMissionStatusLabel(status.missionStatus)),
        (
          'Vĩ độ hiện tại',
          status.currentLatitude?.toStringAsFixed(6) ?? 'Chưa có dữ liệu',
        ),
        (
          'Kinh độ hiện tại',
          status.currentLongitude?.toStringAsFixed(6) ?? 'Chưa có dữ liệu',
        ),
        ('Khối lượng thực tế', droneWeightLabel(status.payloadWeightGrams)),
        ('Mã niêm phong', status.sealCode ?? 'Chưa niêm phong'),
        ('Đúng kiện, đúng đơn', _check(status.parcelMatched)),
        ('Kiện đã cố định', _check(status.payloadSecured)),
        ('Khoang hàng đã khoá', _check(status.compartmentLocked)),
        if (status.loadingNote != null)
          ('Ghi chú nạp hàng', status.loadingNote!),
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
    if (from == 'ACCEPTED' && to == 'ACCEPTED') return 'Đã nạp hàng lên drone';
    if (event.isPickupCodeSent) return 'Gửi mã nhận hàng cho người nhận';
    if (from.isEmpty && to == 'AWAITING_DISPATCH') return 'Đơn drone được tạo';
    return DroneDeliveryStage.fromRaw(to).title;
  }

  @override
  Widget build(BuildContext context) {
    return _Card(
      title: 'Nhật ký hành trình · mới nhất trước',
      icon: LucideIcons.history,
      child: events.isEmpty
          ? const Text(
              'Chưa có mốc hành trình nào.',
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
        (event.actorUserId == null ? 'Hệ thống' : 'Nhân viên Lock.R');
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
                      child: const Text(
                        'Mới nhất',
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
