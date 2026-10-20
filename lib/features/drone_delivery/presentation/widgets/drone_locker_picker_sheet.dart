import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:smart_laundry_locker/core/theme/shadcn_theme.dart';
import 'package:smart_laundry_locker/features/drone_delivery/domain/entities/drone_locker_availability.dart';
import 'package:smart_laundry_locker/features/locker_ops/data/locker_ops_service.dart';

/// Chọn tủ nhận drone. Tủ gửi và đường bay được hệ thống tự chọn sau khi KTV
/// lấy kiện tại nhà; khách chỉ cần chọn nơi người nhận sẽ lấy hàng.
Future<void> showDroneLockerPicker(
  BuildContext context, {
  LockerOpsService? service,
}) {
  return showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) => _DroneLockerPickerSheet(
      service: service ?? LockerOpsService(),
      onPick: (locker) {
        final lockerId = _asInt(locker['id']);
        Navigator.of(sheetContext).pop();
        if (lockerId != null) {
          context.pushNamed(
            'drone_booking',
            extra: {'destinationLockerId': lockerId},
          );
        }
      },
    ),
  );
}

int? _asInt(Object? v) => v is num ? v.toInt() : int.tryParse('$v');

class _DroneLockerPickerSheet extends StatefulWidget {
  const _DroneLockerPickerSheet({required this.service, required this.onPick});

  final LockerOpsService service;
  final ValueChanged<Map<String, dynamic>> onPick;

  @override
  State<_DroneLockerPickerSheet> createState() =>
      _DroneLockerPickerSheetState();
}

class _DroneLockerPickerSheetState extends State<_DroneLockerPickerSheet> {
  List<Map<String, dynamic>> _lockers = const [];
  final Map<int, int?> _availableDroneSlots = {};
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
      final all = await widget.service.lockers();
      if (!mounted) return;
      setState(() {
        // Tủ gửi drone = tủ có bãi đáp (ô drone nằm dưới bãi đáp).
        _lockers = all
            .where((l) => l['landingPad'] == true && _asInt(l['id']) != null)
            .toList(growable: false);
        _loading = false;
      });
      await Future.wait(
        _lockers.map((locker) async {
          final id = _asInt(locker['id']);
          if (id == null) return;
          try {
            final layout = await widget.service.layout(id);
            final cells = layout['cells'];
            final count = cells is List
                ? cells
                      .whereType<Map>()
                      .where(
                        (cell) =>
                            '${cell['cellType']}'.toUpperCase() == 'DRONE' &&
                            '${cell['status']}'.toUpperCase() == 'AVAILABLE',
                      )
                      .length
                : 0;
            if (mounted) setState(() => _availableDroneSlots[id] = count);
          } catch (_) {
            if (mounted) setState(() => _availableDroneSlots[id] = null);
          }
        }),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = LockerOpsService.errorMessage(e);
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        MediaQuery.of(context).padding.bottom + 16,
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
          const Text(
            'Gửi hàng bằng drone',
            style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          const Text(
            'Chọn tủ nhận hàng. Hệ thống tự chọn tủ bay và KTV đến lấy kiện tại nhà.',
            style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 14),
          Flexible(child: _buildBody()),
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
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Không tải được danh sách tủ: $_error',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xFFDC2626)),
          ),
          TextButton.icon(
            onPressed: _load,
            icon: const Icon(LucideIcons.refreshCw, size: 16),
            label: const Text('Thử lại'),
          ),
        ],
      );
    }
    if (_lockers.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Text(
          'Chưa có tủ nào có bãi đáp drone.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Color(0xFF64748B)),
        ),
      );
    }
    return ListView.separated(
      shrinkWrap: true,
      itemCount: _lockers.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, i) {
        final locker = _lockers[i];
        final reason = droneDestinationBlockReason(
          status: locker['status'],
          online: locker['online'],
          landingPadStatus: locker['landingPadStatus'],
        );
        final name = '${locker['name'] ?? locker['code'] ?? 'Tủ'}';
        final address = '${locker['address'] ?? ''}'.trim();
        final lockerId = _asInt(locker['id']);
        final slots = lockerId == null ? null : _availableDroneSlots[lockerId];
        final canReceive = slots != null && slots > 0;
        return Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: reason == null && canReceive
                ? () => widget.onPick(locker)
                : null,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.flight_takeoff_rounded,
                    color: reason == null && canReceive
                        ? const Color(0xFF4F46E5)
                        : const Color(0xFF94A3B8),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: reason == null && canReceive
                                ? AISLShadcnTheme.navyPrimary
                                : const Color(0xFF94A3B8),
                          ),
                        ),
                        if (address.isNotEmpty)
                          Text(
                            address,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        Text(
                          slots == null
                              ? 'Đang kiểm tra ô drone nhận'
                              : 'Còn $slots ô drone nhận trống',
                          style: TextStyle(
                            fontSize: 12,
                            color: slots != null && slots > 0
                                ? const Color(0xFF15803D)
                                : const Color(0xFFDC2626),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (reason != null)
                          Text(
                            'Tạm không gửi drone: $reason',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFFB91C1C),
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (reason == null)
                    const Icon(
                      LucideIcons.chevronRight,
                      size: 18,
                      color: Color(0xFF94A3B8),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
