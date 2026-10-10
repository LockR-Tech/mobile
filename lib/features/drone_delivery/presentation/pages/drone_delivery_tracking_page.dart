import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:smart_laundry_locker/core/config/business_config_service.dart';
import 'package:smart_laundry_locker/core/config/feature_flags.dart';
import 'package:smart_laundry_locker/core/routing/app_router.dart';
import 'package:smart_laundry_locker/core/theme/shadcn_theme.dart';
import 'package:smart_laundry_locker/features/drone_delivery/domain/entities/drone_delivery_stage.dart';
import 'package:smart_laundry_locker/features/drone_delivery/domain/entities/drone_delivery_status.dart';
import 'package:smart_laundry_locker/features/drone_delivery/presentation/providers/drone_delivery_providers.dart';
import 'package:smart_laundry_locker/features/drone_delivery/presentation/widgets/drone_approaching_sheet.dart';
import 'package:smart_laundry_locker/features/drone_delivery/presentation/widgets/drone_delivery_detail.dart';
import 'package:smart_laundry_locker/features/drone_delivery/presentation/widgets/drone_order_cancel.dart';
import 'package:smart_laundry_locker/features/drone_delivery/presentation/widgets/drone_order_payment.dart';
import 'package:smart_laundry_locker/features/locker_ops/data/locker_ops_service.dart';
import 'package:smart_laundry_locker/features/maintenance/presentation/widgets/customer_drone_incident_card.dart';

/// Trang cho NGƯỜI NHẬN theo dõi đơn giao bằng drone (Phase 1: timeline theo
/// push notification, CHƯA có live map).
class DroneDeliveryTrackingPage extends ConsumerStatefulWidget {
  final String orderId;

  const DroneDeliveryTrackingPage({super.key, required this.orderId});

  @override
  ConsumerState<DroneDeliveryTrackingPage> createState() =>
      _DroneDeliveryTrackingPageState();
}

class _DroneDeliveryTrackingPageState
    extends ConsumerState<DroneDeliveryTrackingPage> {
  DroneDeliveryStage? _lastApproachingShown;
  bool _paying = false;
  bool _canceling = false;
  bool _confirming = false;

  @override
  Widget build(BuildContext context) {
    final asyncStatus = ref.watch(
      droneDeliveryStatusProvider(widget.orderId),
    );

    // Khi drone chuyển sang `approaching` → nhắc người nhận ra nhận (một lần).
    ref.listen<AsyncValue<DroneDeliveryStatus>>(
      droneDeliveryStatusProvider(widget.orderId),
      (previous, next) {
        final status = next.value;
        if (status == null) return;
        if (status.stage == DroneDeliveryStage.approaching &&
            _lastApproachingShown != DroneDeliveryStage.approaching) {
          _lastApproachingShown = DroneDeliveryStage.approaching;
          DroneApproachingSheet.show(
            context,
            etaText: _etaText(status.etaMinutes),
            droneCode: status.droneCode,
          );
        }
      },
    );

    return Scaffold(
      backgroundColor: AISLShadcnTheme.navySurface,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: AISLShadcnTheme.navyPrimary),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(AppRouter.orders);
            }
          },
        ),
        title: const Text(
          'Theo dõi giao drone',
          style: TextStyle(
            color: AISLShadcnTheme.navyPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
      ),
      body: RefreshIndicator(
        color: AISLShadcnTheme.navyPrimary,
        onRefresh: () async {
          ref.invalidate(droneDeliveryStatusProvider(widget.orderId));
          await ref.read(
            droneDeliveryStatusProvider(widget.orderId).future,
          );
        },
        child: asyncStatus.when(
          loading: () => const _CenteredScroll(child: CircularProgressIndicator()),
          error: (err, _) => _CenteredScroll(
            child: _ErrorState(
              message: err.toString(),
              onRetry: () =>
                  ref.invalidate(droneDeliveryStatusProvider(widget.orderId)),
            ),
          ),
          data: (status) => _TrackingBody(
            status: status,
            orderId: widget.orderId,
            onPay: () => _pay(status),
            onCancel: () => _cancel(status),
            onConfirmDrop: () => _confirmDrop(status),
            onDeclineSurcharge: () => _declineSurcharge(status),
          ),
        ),
      ),
    );
  }

  /// Người đặt huỷ đơn khi đội bay chưa tiếp nhận; server ghi yêu cầu hoàn tiền
  /// (admin chuyển khoản) nếu đơn đã thanh toán.
  Future<void> _cancel(DroneDeliveryStatus status) async {
    final orderId = int.tryParse(widget.orderId);
    if (_canceling || orderId == null) return;
    final messenger = ScaffoldMessenger.of(context);
    _canceling = true;
    final String? message;
    try {
      message = await confirmAndCancelDroneOrder(
        context,
        orderId: orderId,
        orderCode: status.orderCode,
        isPaid: status.isPaid,
        totalPrice: status.totalPrice,
      );
    } finally {
      _canceling = false;
    }
    if (message == null || !mounted) return;
    ref.invalidate(droneDeliveryStatusProvider(widget.orderId));
    messenger.showSnackBar(SnackBar(content: Text(message)));
  }

  /// Người gửi xác nhận đã bỏ kiện vào ô gửi — điều kiện để đội bay tiếp nhận.
  Future<void> _confirmDrop(DroneDeliveryStatus status) async {
    final box = status.sourceBoxNumber;
    await _confirmThen(
      title: 'Xác nhận đã bỏ kiện',
      body:
          'Bạn đã bỏ kiện vào ${box == null ? 'ô drone ở tủ gửi' : 'ô drone số $box ở tủ gửi'} '
          'và đóng cửa ô? Đội bay sẽ tới nạp hàng sau khi bạn xác nhận.',
      confirmLabel: 'Đã bỏ kiện',
      action: (orderId) => LockerOpsService().confirmDroneParcelDrop(orderId),
      done: 'Đã ghi nhận. Đội bay sẽ tiếp nhận đơn của bạn.',
    );
  }

  /// Khách không đồng ý phụ thu cân lệch: huỷ đơn, hoàn phần đã trả, đội bay trả kiện.
  Future<void> _declineSurcharge(DroneDeliveryStatus status) async {
    await _confirmThen(
      title: 'Huỷ đơn vì không đồng ý phụ thu',
      body:
          'Đơn ${status.orderCode ?? ''} sẽ bị huỷ. Phần bạn đã trả được ghi yêu cầu hoàn '
          'tiền và đội bay sẽ liên hệ để trả lại kiện. Không hoàn tác được.',
      confirmLabel: 'Huỷ đơn',
      action: (orderId) => LockerOpsService().declineDroneSurcharge(orderId),
      done: 'Đã huỷ đơn. Đội bay sẽ trả lại kiện cho bạn.',
    );
  }

  Future<void> _confirmThen({
    required String title,
    required String body,
    required String confirmLabel,
    required Future<Object?> Function(int orderId) action,
    required String done,
  }) async {
    final orderId = int.tryParse(widget.orderId);
    if (_confirming || orderId == null) return;
    final messenger = ScaffoldMessenger.of(context);
    _confirming = true;
    String? message;
    try {
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(title),
          content: Text(body),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Chưa'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(confirmLabel),
            ),
          ],
        ),
      );
      if (ok != true) return;
      await action(orderId);
      message = done;
    } catch (error) {
      message = LockerOpsService.errorMessage(error);
    } finally {
      _confirming = false;
    }
    if (!mounted) return;
    ref.invalidate(droneDeliveryStatusProvider(widget.orderId));
    messenger.showSnackBar(SnackBar(content: Text(message)));
  }

  /// Thanh toán ngay trên màn theo dõi, không bắt khách sang danh sách đơn.
  Future<void> _pay(DroneDeliveryStatus status) async {
    final orderId = int.tryParse(widget.orderId);
    if (_paying || orderId == null) return;
    _paying = true;
    final messenger = ScaffoldMessenger.of(context);
    String message;
    try {
      final outcome = await payDroneOrder(
        context,
        orderId: orderId,
        total:
            status.payableAmount ??
            BusinessConfigService.instance.current.droneDeliveryFee.toDouble(),
      );
      message = droneOrderPaymentMessage(outcome);
    } catch (error) {
      message = LockerOpsService.errorMessage(error);
    } finally {
      _paying = false;
    }
    if (!mounted) return;
    ref.invalidate(droneDeliveryStatusProvider(widget.orderId));
    messenger.showSnackBar(SnackBar(content: Text(message)));
  }

  static String? _etaText(int? minutes) =>
      (minutes == null) ? null : '$minutes phút';
}

class _TrackingBody extends StatelessWidget {
  final DroneDeliveryStatus status;
  final String orderId;
  final VoidCallback onPay;
  final VoidCallback onCancel;
  final VoidCallback onConfirmDrop;
  final VoidCallback onDeclineSurcharge;

  const _TrackingBody({
    required this.status,
    required this.orderId,
    required this.onPay,
    required this.onCancel,
    required this.onConfirmDrop,
    required this.onDeclineSurcharge,
  });

  /// Chỉ mời xem live map khi drone đang trên đường và
  /// cờ Phase 2 bật. Các mốc arrived/delivered/failed không cần bản đồ nữa.
  bool get _canTrackOnMap =>
      FeatureFlags.droneLiveMapEnabled &&
      // Cần nguồn vị trí: đơn DEMO (vị trí nội suy) hoặc drone thật còn gửi telemetry.
      // Server cũ chưa trả `liveTracking` thì chỉ đơn DEMO có bản đồ.
      (status.liveTracking ??
          (status.fulfillmentMode ?? '').toUpperCase() == 'DEMO') &&
      (status.stage == DroneDeliveryStage.departed ||
          status.stage == DroneDeliveryStage.enRoute ||
          status.stage == DroneDeliveryStage.approaching);

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(20),
      children: [
        const _LiveIndicator(),
        const SizedBox(height: 12),
        if (int.tryParse(orderId) case final parsed?)
          CustomerDroneIncidentCard(orderId: parsed),
        DroneDeliveryDetail(
          status: status,
          onPay: onPay,
          onCancel: onCancel,
          onConfirmDrop: onConfirmDrop,
          onDeclineSurcharge: onDeclineSurcharge,
          beforeRoute: [
            if (_canTrackOnMap) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: AISLShadcnTheme.navyPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: () =>
                      context.push(AppRouter.droneLiveMap, extra: orderId),
                  icon: const Icon(LucideIcons.map, size: 18),
                  label: const Text('Theo dõi trên bản đồ'),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}

/// Báo cho người xem biết màn hình tự cập nhật — không cần kéo để tải lại.
class _LiveIndicator extends StatelessWidget {
  const _LiveIndicator();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: const BoxDecoration(
            color: Color(0xFF16A34A),
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        const Expanded(
          child: Text(
            'Đang cập nhật trực tiếp · trạng thái tự làm mới khi có thay đổi',
            style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
          ),
        ),
      ],
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(LucideIcons.circleAlert, color: Color(0xFFDC2626), size: 56),
        const SizedBox(height: 16),
        const Text(
          'Không tải được trạng thái giao hàng',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AISLShadcnTheme.navyPrimary,
          ),
        ),
        const SizedBox(height: 6),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[600], fontSize: 13),
          ),
        ),
        const SizedBox(height: 20),
        TextButton.icon(
          onPressed: onRetry,
          icon: const Icon(LucideIcons.refreshCw, size: 16),
          label: const Text('Thử lại'),
        ),
      ],
    );
  }
}

/// Bọc nội dung vào scroll để `RefreshIndicator` kéo được cả khi loading/error.
class _CenteredScroll extends StatelessWidget {
  final Widget child;

  const _CenteredScroll({required this.child});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 80),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
