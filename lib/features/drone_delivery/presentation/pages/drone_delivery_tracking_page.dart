import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:smart_laundry_locker/core/config/business_config_service.dart';
import 'package:smart_laundry_locker/core/routing/app_router.dart';
import 'package:smart_laundry_locker/core/services/token_service.dart';
import 'package:smart_laundry_locker/core/theme/shadcn_theme.dart';
import 'package:smart_laundry_locker/features/drone_delivery/domain/entities/drone_delivery_stage.dart';
import 'package:smart_laundry_locker/features/drone_delivery/domain/entities/drone_delivery_status.dart';
import 'package:smart_laundry_locker/features/drone_delivery/domain/entities/drone_viewer.dart';
import 'package:smart_laundry_locker/features/drone_delivery/presentation/drone_error_messages.dart';
import 'package:smart_laundry_locker/features/drone_delivery/presentation/drone_live_map.dart';
import 'package:smart_laundry_locker/features/drone_delivery/presentation/providers/drone_delivery_providers.dart';
import 'package:smart_laundry_locker/features/drone_delivery/presentation/widgets/drone_approaching_sheet.dart';
import 'package:smart_laundry_locker/features/drone_delivery/presentation/widgets/drone_delivery_detail.dart';
import 'package:smart_laundry_locker/features/drone_delivery/presentation/widgets/drone_order_cancel.dart';
import 'package:smart_laundry_locker/features/drone_delivery/presentation/widgets/drone_order_payment.dart';
import 'package:smart_laundry_locker/features/drone_delivery/presentation/widgets/drone_pickup_sheet.dart';
import 'package:smart_laundry_locker/features/locker_ops/data/locker_ops_service.dart';
import 'package:smart_laundry_locker/features/maintenance/presentation/widgets/customer_drone_incident_card.dart';

/// Màn theo dõi đơn giao bằng drone cho khách (người đặt hoặc người nhận):
/// timeline tự làm mới, bản đồ hành trình, thao tác theo vai trò người xem.
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

  /// Id tài khoản đang xem (từ JWT) — phân biệt người đặt / người nhận.
  int? _currentUserId;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
  }

  Future<void> _loadCurrentUser() async {
    final id = int.tryParse(await TokenService.getUserId() ?? '');
    if (mounted && id != _currentUserId) setState(() => _currentUserId = id);
  }

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
          try {
            await ref.read(
              droneDeliveryStatusProvider(widget.orderId).future,
            );
          } catch (_) {
            // Lỗi đã hiện trên màn (đang thử lại); không ném ra khỏi kéo làm mới.
          }
        },
        // Lỗi một lần poll mà đã có dữ liệu: giữ màn cũ, chỉ báo "đang thử lại".
        child: asyncStatus.when(
          skipError: true,
          loading: () => const _CenteredScroll(child: CircularProgressIndicator()),
          error: (err, _) => _CenteredScroll(
            child: _ErrorState(
              message: err is DroneStatusLoadException
                  ? err.message
                  : 'Vui lòng kiểm tra kết nối và thử lại.',
              onRetry: () =>
                  ref.invalidate(droneDeliveryStatusProvider(widget.orderId)),
            ),
          ),
          data: (status) {
            final role = droneViewerRole(status, _currentUserId);
            final actions = DroneCustomerActions.of(status, role);
            return _TrackingBody(
              status: status,
              orderId: widget.orderId,
              reconnecting: asyncStatus.hasError,
              viewerIsBooker: role == DroneViewerRole.booker,
              pickup: actions.pickup,
              onPay: actions.canPay ? () => _pay(status) : null,
              onCancel: actions.canCancel ? () => _cancel(status) : null,
              onConfirmDrop:
                  actions.canConfirmDrop ? () => _confirmDrop(status) : null,
              onDeclineSurcharge: actions.canDeclineSurcharge
                  ? () => _declineSurcharge(status)
                  : null,
              onPickup: () => _pickup(actions.pickup),
            );
          },
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
      message = droneCustomerErrorMessage(error);
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
      message = droneCustomerErrorMessage(error);
    } finally {
      _paying = false;
    }
    if (!mounted) return;
    ref.invalidate(droneDeliveryStatusProvider(widget.orderId));
    messenger.showSnackBar(SnackBar(content: Text(message)));
  }

  /// "Nhận hàng" ở chặng sẵn sàng nhận: người đặt ⇒ chi tiết đơn trong "Đơn
  /// hàng" (mã PIN, mở ô); người nhận ⇒ mã PIN trong hàng chờ nhận.
  void _pickup(DronePickupAction action) {
    final orderId = int.tryParse(widget.orderId);
    switch (action) {
      case DronePickupAction.bookerOrder:
      case DronePickupAction.bookerOrderForOther:
        context.push(
          Uri(
            path: AppRouter.myLockerOrders,
            queryParameters: {'orderId': widget.orderId},
          ).toString(),
        );
      case DronePickupAction.receiverPin:
        if (orderId != null) showDronePickupSheet(context, orderId: orderId);
      case DronePickupAction.none:
        break;
    }
  }

  static String? _etaText(int? minutes) =>
      (minutes == null) ? null : '$minutes phút';
}

class _TrackingBody extends StatelessWidget {
  final DroneDeliveryStatus status;
  final String orderId;
  final bool reconnecting;
  final bool viewerIsBooker;
  final DronePickupAction pickup;
  final VoidCallback? onPay;
  final VoidCallback? onCancel;
  final VoidCallback? onConfirmDrop;
  final VoidCallback? onDeclineSurcharge;
  final VoidCallback onPickup;

  const _TrackingBody({
    required this.status,
    required this.orderId,
    required this.reconnecting,
    required this.viewerIsBooker,
    required this.pickup,
    required this.onPay,
    required this.onCancel,
    required this.onConfirmDrop,
    required this.onDeclineSurcharge,
    required this.onPickup,
  });

  @override
  Widget build(BuildContext context) {
    final canTrackOnMap = droneLiveMapAvailable(status);
    final simulated = droneIsSimulated(status);
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(20),
      children: [
        _LiveIndicator(reconnecting: reconnecting),
        const SizedBox(height: 12),
        if (int.tryParse(orderId) case final parsed?)
          CustomerDroneIncidentCard(
            orderId: parsed,
            // Chặng đổi (vd. vừa báo rơi kiện) ⇒ tải lại thẻ sự cố.
            refreshKey: status.status,
            expectIncident: status.stage.isIncident,
          ),
        DroneDeliveryDetail(
          status: status,
          viewerIsBooker: viewerIsBooker,
          onPay: onPay,
          onCancel: onCancel,
          onConfirmDrop: onConfirmDrop,
          onDeclineSurcharge: onDeclineSurcharge,
          isSender: viewerIsBooker,
          beforeRoute: [
            if (pickup != DronePickupAction.none) ...[
              const SizedBox(height: 16),
              _PickupCard(action: pickup, onPickup: onPickup),
            ],
            if (canTrackOnMap) ...[
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
                  label: Text(
                    simulated
                        ? 'Theo dõi trên bản đồ (mô phỏng)'
                        : 'Theo dõi trên bản đồ',
                  ),
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

/// Thẻ "Nhận hàng" ở chặng sẵn sàng nhận.
class _PickupCard extends StatelessWidget {
  const _PickupCard({required this.action, required this.onPickup});

  final DronePickupAction action;
  final VoidCallback onPickup;

  @override
  Widget build(BuildContext context) {
    final forOther = action == DronePickupAction.bookerOrderForOther;
    const color = Color(0xFF15803D);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFBBF7D0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            forOther
                ? 'Kiện đã vào tủ nhận. Mã mở ô đã được gửi cho người nhận.'
                : 'Kiện đã vào tủ nhận. Mở mã PIN để lấy hàng tại tủ.',
            style: const TextStyle(
              color: color,
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 10),
          FilledButton.icon(
            key: const ValueKey('drone-pickup'),
            style: FilledButton.styleFrom(backgroundColor: color),
            onPressed: onPickup,
            icon: const Icon(LucideIcons.packageCheck, size: 18),
            label: Text(forOther ? 'Xem chi tiết đơn' : 'Nhận hàng'),
          ),
        ],
      ),
    );
  }
}

/// Báo cho người xem biết màn hình tự cập nhật — không cần kéo để tải lại. Một
/// lần tải lỗi thì báo đang thử lại (dữ liệu trên màn là lần tải gần nhất).
class _LiveIndicator extends StatelessWidget {
  const _LiveIndicator({this.reconnecting = false});

  final bool reconnecting;

  @override
  Widget build(BuildContext context) {
    final color =
        reconnecting ? const Color(0xFFD97706) : const Color(0xFF16A34A);
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            reconnecting
                ? 'Mất kết nối · đang thử lại, thông tin bên dưới là lần cập nhật gần nhất'
                : 'Đang cập nhật trực tiếp · trạng thái tự làm mới khi có thay đổi',
            style: TextStyle(
              fontSize: 12,
              color: reconnecting ? color : const Color(0xFF64748B),
            ),
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
