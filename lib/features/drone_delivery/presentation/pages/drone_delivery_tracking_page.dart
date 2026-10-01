import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:smart_laundry_locker/core/config/feature_flags.dart';
import 'package:smart_laundry_locker/core/routing/app_router.dart';
import 'package:smart_laundry_locker/core/theme/shadcn_theme.dart';
import 'package:smart_laundry_locker/features/drone_delivery/domain/entities/drone_delivery_stage.dart';
import 'package:smart_laundry_locker/features/drone_delivery/domain/entities/drone_delivery_status.dart';
import 'package:smart_laundry_locker/features/drone_delivery/presentation/providers/drone_delivery_providers.dart';
import 'package:smart_laundry_locker/features/drone_delivery/presentation/widgets/drone_approaching_sheet.dart';
import 'package:smart_laundry_locker/features/drone_delivery/presentation/widgets/drone_delivery_detail.dart';

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
          data: (status) =>
              _TrackingBody(status: status, orderId: widget.orderId),
        ),
      ),
    );
  }

  static String? _etaText(int? minutes) =>
      (minutes == null) ? null : '$minutes phút';
}

class _TrackingBody extends StatelessWidget {
  final DroneDeliveryStatus status;
  final String orderId;

  const _TrackingBody({required this.status, required this.orderId});

  /// Chỉ mời xem live map khi drone đang trên đường và
  /// cờ Phase 2 bật. Các mốc arrived/delivered/failed không cần bản đồ nữa.
  bool get _canTrackOnMap =>
      FeatureFlags.droneLiveMapEnabled &&
      // Chỉ đơn DEMO có nguồn vị trí; đơn drone thật mở bản đồ sẽ không có tín hiệu.
      (status.fulfillmentMode ?? '').toUpperCase() == 'DEMO' &&
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
        DroneDeliveryDetail(
          status: status,
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
