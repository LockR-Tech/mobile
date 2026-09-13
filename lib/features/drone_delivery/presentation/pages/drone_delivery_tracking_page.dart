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
import 'package:smart_laundry_locker/features/drone_delivery/presentation/widgets/drone_delivery_timeline.dart';

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
      (status.stage == DroneDeliveryStage.departed ||
          status.stage == DroneDeliveryStage.enRoute ||
          status.stage == DroneDeliveryStage.approaching);

  @override
  Widget build(BuildContext context) {
    final stage = status.stage;
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(20),
      children: [
        _HeaderCard(status: status),
        if (stage.isDelayed || stage.isFailure) ...[
          const SizedBox(height: 16),
          _StatusBanner(stage: stage, etaMinutes: status.etaMinutes),
        ],
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
                  context.go(AppRouter.droneLiveMap, extra: orderId),
              icon: const Icon(LucideIcons.map, size: 18),
              label: const Text('Theo dõi trên bản đồ'),
            ),
          ),
        ],
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: DroneDeliveryTimeline(stage: stage),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}

class _HeaderCard extends StatelessWidget {
  final DroneDeliveryStatus status;

  const _HeaderCard({required this.status});

  @override
  Widget build(BuildContext context) {
    final stage = status.stage;
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
          // Wrap thay vì Row: 3 chip (đơn/drone/ETA) có thể vượt bề rộng card
          // trên màn hẹp hoặc mã đơn/drone dài — wrap xuống dòng thay vì tràn.
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
              if (status.etaMinutes != null && !stage.isTerminal)
                _InfoChip(
                  icon: LucideIcons.clock,
                  label: 'ETA ${status.etaMinutes} phút',
                ),
            ],
          ),
        ],
      ),
    );
  }

  static String? _etaText(int? minutes) =>
      (minutes == null) ? null : '$minutes phút';
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({required this.icon, required this.label});

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
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBanner extends StatelessWidget {
  final DroneDeliveryStage stage;
  final int? etaMinutes;

  const _StatusBanner({required this.stage, this.etaMinutes});

  @override
  Widget build(BuildContext context) {
    final color = stage.color; // amber cho delayed, đỏ cho failed
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Icon(stage.icon, color: color, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              stage.body(etaMinutes == null ? null : '$etaMinutes phút'),
              style: TextStyle(
                color: color,
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
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
