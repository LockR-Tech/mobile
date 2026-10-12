import 'package:flutter/material.dart';
import 'package:smart_laundry_locker/features/drone_delivery/domain/entities/drone_booking.dart';
import 'package:smart_laundry_locker/features/drone_delivery/domain/entities/drone_delivery_stage.dart';
import 'package:smart_laundry_locker/features/locker_ops/data/locker_ops_service.dart';

/// Các đơn drone mà một phiếu sự cố đang chặn hoặc đã làm "giao không hoàn tất" — để kỹ
/// thuật viên xử lý phiếu biết sự cố này đang giữ chân đơn nào và cần gấp tới đâu.
///
/// Không có đơn nào thì không vẽ gì, để hồ sơ phiếu không dài thêm vô ích.
class DroneOrdersByTicket extends StatefulWidget {
  const DroneOrdersByTicket({
    super.key,
    required this.ticketId,
    required this.service,
    this.lockerTechnician = false,
  });

  final int ticketId;
  final LockerOpsService service;

  /// Phiếu tủ/bãi đáp do KTV tủ xử lý đi qua tuyến riêng của vai trò đó.
  final bool lockerTechnician;

  @override
  State<DroneOrdersByTicket> createState() => _DroneOrdersByTicketState();
}

class _DroneOrdersByTicketState extends State<DroneOrdersByTicket> {
  List<Map<String, dynamic>> _orders = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final orders = await widget.service.droneOrdersByTicket(
        widget.ticketId,
        lockerTechnician: widget.lockerTechnician,
      );
      if (mounted) setState(() => _orders = orders);
    } catch (_) {
      // Backend cũ chưa có liên kết phiếu ↔ đơn: bỏ qua, hồ sơ phiếu vẫn dùng được.
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_orders.isEmpty) return const SizedBox.shrink();
    return Container(
      key: const ValueKey('drone-orders-by-ticket'),
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF3C7),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFCD34D)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Đơn drone bị phiếu này ảnh hưởng (${_orders.length})',
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              color: Color(0xFFB45309),
            ),
          ),
          const SizedBox(height: 6),
          for (final order in _orders) _row(order),
        ],
      ),
    );
  }

  Widget _row(Map<String, dynamic> order) {
    final failure = order['failure'];
    final block = order['block'];
    final stage = DroneDeliveryStage.fromRaw(
      '${order['status']}'.toUpperCase() == 'CANCELED' &&
              '${order['deliveryStage']}'.toUpperCase() == 'FAILED'
          ? 'FAILED'
          : order['deliveryStage']?.toString(),
    );
    final String state;
    if (failure is Map) {
      state =
          'Đã giao không hoàn tất · '
          '${failure['reasonLabel'] ?? droneFailureReasonLabel('${failure['reason']}')}';
    } else if (block is Map) {
      state =
          'Đang bị chặn (${stage.title.toLowerCase()}) · '
          '${block['reasonLabel'] ?? droneFailureReasonLabel('${block['reason']}')}';
    } else {
      state = stage.title;
    }
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Text(
        '${order['orderCode'] ?? 'Đơn #${order['orderId']}'} — $state',
        style: const TextStyle(fontSize: 12.5, color: Color(0xFF7C2D12)),
      ),
    );
  }
}
