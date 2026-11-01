import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:smart_laundry_locker/core/routing/app_router.dart';
import 'package:smart_laundry_locker/core/theme/shadcn_theme.dart';
import 'package:smart_laundry_locker/core/utils/app_date_time.dart';
import 'package:smart_laundry_locker/features/drone_delivery/infrastructure/data_sources/drone_pickup_remote_datasource.dart';
import 'package:smart_laundry_locker/core/l10n/l10n.dart';

/// Sheet "Nhận hàng" cho NGƯỜI NHẬN đơn drone: mã PIN mở ô lấy từ hàng chờ
/// nhận (`GET /api/orders/incoming`), tủ/ô nhận, hạn lấy và chỉ đường.
Future<void> showDronePickupSheet(
  BuildContext context, {
  required int orderId,
  DronePickupRemoteDataSource? dataSource,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _DronePickupSheet(
      orderId: orderId,
      dataSource: dataSource ?? DronePickupRemoteDataSource(),
    ),
  );
}

class _DronePickupSheet extends StatefulWidget {
  const _DronePickupSheet({required this.orderId, required this.dataSource});

  final int orderId;
  final DronePickupRemoteDataSource dataSource;

  @override
  State<_DronePickupSheet> createState() => _DronePickupSheetState();
}

class _DronePickupSheetState extends State<_DronePickupSheet> {
  DronePickupInfo? _info;
  bool _loading = true;
  bool _notFound = false;
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
      _notFound = false;
    });
    try {
      final info = await widget.dataSource.findIncoming(widget.orderId);
      if (!mounted) return;
      setState(() {
        _info = info;
        _notFound = info == null;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error is DronePickupException
            ? error.message
            : L10n.current.psLoadFailed;
        _loading = false;
      });
    }
  }

  void _openDirections(DronePickupInfo info) {
    Navigator.pop(context);
    context.push(
      AppRouter.directions,
      extra: <String, dynamic>{
        'lat': info.lockerLatitude,
        'lng': info.lockerLongitude,
        'title': info.lockerName ?? context.l10n.psReceivingLocker,
        'subtitle': info.lockerAddress,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        MediaQuery.of(context).padding.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            context.l10n.dtPickup,
            style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 14),
          _buildBody(),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 28),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_error != null) {
      return _Message(
        icon: LucideIcons.circleAlert,
        color: const Color(0xFFDC2626),
        text: _error!,
        onRetry: _load,
      );
    }
    final info = _info;
    if (_notFound || info == null) {
      return _Message(
        icon: LucideIcons.packageSearch,
        color: Color(0xFF64748B),
        text:
            context.l10n.psNotInQueue,
      );
    }
    if (info.delegated) {
      return _Message(
        icon: LucideIcons.userCheck,
        color: AISLShadcnTheme.navyPrimary,
        text:
            context.l10n.psDelegated(info.delegateName ?? context.l10n.psSomeoneElse),
      );
    }
    final pin = info.pickupPin;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (pin == null || !info.readyForPickup)
          _Message(
            icon: LucideIcons.clock,
            color: Color(0xFFB45309),
            text: context.l10n.psNotReady,
          )
        else
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: const Color(0xFFF0FDF4),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFBBF7D0)),
            ),
            child: Column(
              children: [
                Text(
                  context.l10n.psPin,
                  style: TextStyle(fontSize: 12, color: Color(0xFF15803D)),
                ),
                const SizedBox(height: 4),
                SelectableText(
                  pin,
                  key: const ValueKey('drone-pickup-pin'),
                  style: const TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 6,
                    fontFamily: 'monospace',
                    color: Color(0xFF14532D),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  context.l10n.psEnterAtKiosk,
                  style: TextStyle(fontSize: 12, color: Color(0xFF15803D)),
                ),
              ],
            ),
          ),
        const SizedBox(height: 14),
        _Row(context.l10n.recvReceivingLocker, info.lockerName ?? context.l10n.lockerHash(info.lockerId ?? '?')),
        if (info.lockerAddress != null) _Row(context.l10n.commonAddress, info.lockerAddress!),
        if (info.boxNumber != null) _Row(context.l10n.psReceiveBox, context.l10n.boxNumberLabel('${info.boxNumber}')),
        if (info.pickupDeadline != null)
          _Row(context.l10n.psPickupBefore, formatDeadlineVn(info.pickupDeadline)),
        if (info.senderName != null) _Row(context.l10n.recvSender, info.senderName!),
        if (info.hasCoordinates) ...[
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => _openDirections(info),
            icon: const Icon(LucideIcons.navigation, size: 18),
            label: Text(context.l10n.ddDirectionsToReceiver),
          ),
        ],
      ],
    );
  }
}

class _Row extends StatelessWidget {
  const _Row(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 110,
          child: Text(
            label,
            style: const TextStyle(fontSize: 12.5, color: Color(0xFF64748B)),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
          ),
        ),
      ],
    ),
  );
}

class _Message extends StatelessWidget {
  const _Message({
    required this.icon,
    required this.color,
    required this.text,
    this.onRetry,
  });

  final IconData icon;
  final Color color;
  final String text;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 22),
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
        if (onRetry != null)
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: onRetry,
              icon: const Icon(LucideIcons.refreshCw, size: 16),
              label: Text(context.l10n.commonRetry),
            ),
          ),
      ],
    ),
  );
}
