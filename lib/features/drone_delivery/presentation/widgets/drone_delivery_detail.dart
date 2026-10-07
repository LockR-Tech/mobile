import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:smart_laundry_locker/core/routing/app_router.dart';
import 'package:smart_laundry_locker/core/theme/shadcn_theme.dart';
import 'package:smart_laundry_locker/core/utils/app_date_time.dart';
import 'package:smart_laundry_locker/features/drone_delivery/domain/entities/drone_delivery_stage.dart';
import 'package:smart_laundry_locker/features/drone_delivery/domain/entities/drone_delivery_status.dart';
import 'package:smart_laundry_locker/features/drone_delivery/domain/entities/drone_labels.dart';
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
    if (stage.order < 0 || at == null || event.isPickupCodeSent) continue;
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
  DroneDeliveryStage.failed => status.firstReachedAt('FAILED') ?? status.updatedAt,
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
    this.beforeRoute = const [],
    this.onPay,
    this.onCancel,
  });

  final DroneDeliveryStatus status;

  /// Khách bấm thanh toán ngay trên thẻ nhắc đơn chưa trả tiền.
  final VoidCallback? onPay;

  /// Khách huỷ đơn khi đội bay chưa tiếp nhận.
  final VoidCallback? onCancel;

  /// Điều phối viên thấy thêm liên hệ người gửi/người nhận.
  final bool forOperator;

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
        if (status.needsPaymentBeforeDispatch || status.needsSurchargePayment) ...[
          const SizedBox(height: 16),
          _UnpaidBanner(status: status, forOperator: forOperator, onPay: onPay),
        ],
        ...beforeRoute,
        const SizedBox(height: 16),
        DroneRouteMapCard(status: status),
        const SizedBox(height: 16),
        _RouteCard(status: status),
        const SizedBox(height: 16),
        _Card(
          title: 'Tiến trình giao hàng',
          icon: LucideIcons.listChecks,
          child: DroneDeliveryTimeline(
            stage: stage,
            stageTimes: droneStageTimes(status),
            stepDetails: droneStepDetails(status),
          ),
        ),
        if (!forOperator && onCancel != null && status.canCustomerCancel) ...[
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

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({required this.status});

  final DroneDeliveryStatus status;

  @override
  Widget build(BuildContext context) {
    final stage = status.stage;
    final changedAt = status.stageChangedAt;
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
                      stage.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      stage.body(_etaText(status.etaMinutes)),
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
              if (status.etaMinutes != null &&
                  !stage.isTerminal &&
                  stage.order >= 0)
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
    final reason = droneCancelReasonLabel(status.cancelReason);
    final endedAt = _endedAt(status);
    final lines = <String>[
      stage.body(_etaText(status.etaMinutes)),
      if (endedAt != null) 'Lúc: ${formatDateTimeVn(endedAt)}',
      if (stage == DroneDeliveryStage.canceled && reason != null)
        'Lý do: $reason',
      if (stage == DroneDeliveryStage.canceled && status.cancelNote != null)
        'Ghi chú: ${status.cancelNote}',
      if (stage == DroneDeliveryStage.canceled &&
          (status.paymentStatus ?? '').toUpperCase() == 'REFUND_PENDING')
        'Yêu cầu hoàn tiền đã được ghi nhận. Admin sẽ chuyển khoản về tài '
            'khoản ngân hàng của người đặt.',
      if (stage == DroneDeliveryStage.canceled &&
          (status.paymentStatus ?? '').toUpperCase() == 'REFUNDED')
        'Tiền đã được chuyển khoản hoàn cho người đặt.',
      if (stage == DroneDeliveryStage.canceled && status.isPaid)
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
    this.onPay,
  });

  final DroneDeliveryStatus status;
  final bool forOperator;
  final VoidCallback? onPay;

  /// Đơn nợ phần phí chênh vì đội bay cân kiện nặng hơn khai báo.
  String _surchargeText() {
    final amount = fmtPrice(status.payableAmount ?? status.weightSurcharge);
    final weights =
        'Kiện cân thực tế ${droneWeightLabel(status.payloadWeightGrams)}, nặng hơn '
        'mức ${droneWeightLabel(status.expectedWeightGrams)} đã khai báo.';
    return forOperator
        ? '$weights Chờ khách trả thêm $amount rồi mới phóng được.'
        : '$weights Bạn cần trả thêm $amount để drone cất cánh. Không đồng ý thì '
              'liên hệ đội bay để huỷ đơn và nhận hoàn tiền.';
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
          if (!forOperator && onPay != null) ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(backgroundColor: color),
                onPressed: onPay,
                icon: const Icon(LucideIcons.wallet, size: 18),
                label: Text(surcharge ? 'Trả thêm phí chênh' : 'Thanh toán ngay'),
              ),
            ),
          ],
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
  const _RouteCard({required this.status});

  final DroneDeliveryStatus status;

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
            label: 'Tủ gửi · Locker A (nơi drone cất cánh)',
            point: status.sourceLocker,
            fallbackId: status.sourceLockerId,
            color: const Color(0xFF0F766E),
            extras: [
              if (status.sourceBoxNumber != null)
                'Bỏ kiện vào ô drone số ${status.sourceBoxNumber}',
              'Gửi đi lúc: ${formatDateTimeVn(sentAt, empty: 'Chưa gửi')}',
            ],
            directionsLabel: 'Chỉ đường tới tủ gửi',
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
            label: 'Tủ nhận · Locker B (nơi lấy hàng)',
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
  final String directionsLabel;
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
            label: Text(directionsLabel),
          )
        : OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: AISLShadcnTheme.navyPrimary,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            onPressed: () => _openDirections(context),
            icon: const Icon(LucideIcons.navigation, size: 18),
            label: Text(directionsLabel),
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
        const SizedBox(height: 10),
        SizedBox(width: double.infinity, child: button),
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
        ('Trạng thái đơn', droneOrderStatusLabel(status.orderStatus)),
        ('Thanh toán', dronePaymentStatusLabel(status.paymentStatus)),
        (
          'Phí giao drone',
          status.totalPrice == null ? '—' : fmtPrice(status.totalPrice),
        ),
        if ((status.weightSurcharge ?? 0) > 0)
          ('Trong đó thu thêm do cân lệch', fmtPrice(status.weightSurcharge)),
        if (status.paymentMethod != null)
          ('Phương thức', dronePaymentMethodLabel(status.paymentMethod)),
        if (status.paymentReference != null)
          ('Mã thanh toán', status.paymentReference!),
        if (status.paymentTransactionId != null)
          ('Mã giao dịch', status.paymentTransactionId!),
        if (status.paidAt != null)
          ('Thanh toán lúc', formatDateTimeVn(status.paidAt)),
        ('Ô nhận tại tủ đích', box == null ? '—' : 'Ô số $box'),
        ('Khối lượng khai báo', droneWeightLabel(status.expectedWeightGrams)),
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
        ('Người gửi', status.customerName ?? '—'),
        if (forOperator) ('SĐT người gửi', status.customerPhone ?? '—'),
        ('Người nhận', status.receiverName ?? status.customerName ?? '—'),
        if (forOperator)
          (
            'SĐT người nhận',
            status.receiverPhone ?? status.customerPhone ?? '—',
          ),
        (
          'Điều phối viên',
          status.assignedByName ??
              (status.assignedByUserId == null
                  ? 'Chưa có người tiếp nhận'
                  : 'Đã tiếp nhận'),
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
        ('Khối lượng thực tế', droneWeightLabel(status.payloadWeightGrams)),
        ('Mã niêm phong', status.sealCode ?? 'Chưa niêm phong'),
        ('Đúng kiện, đúng đơn', _check(status.parcelMatched)),
        ('Kiện đã cố định', _check(status.payloadSecured)),
        ('Khoang hàng đã khoá', _check(status.compartmentLocked)),
        if (status.loadingNote != null) ('Ghi chú nạp hàng', status.loadingNote!),
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
    final actor = event.actorName ??
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
