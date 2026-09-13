import 'package:flutter/material.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:latlong2/latlong.dart';
import 'package:smart_laundry_locker/features/locker_ops/data/locker_ops_service.dart';

typedef DroneOrderCreator = Future<Map<String, dynamic>> Function({
  required int destinationLockerId,
  required int? preferredBoxId,
  required String? description,
  required int parcelWeightGrams,
  required String paymentMethod,
  required String idempotencyKey,
});

class DroneBookingSheet extends StatefulWidget {
  const DroneBookingSheet({
    super.key,
    required this.cell,
    required this.lockerName,
    required this.origin,
    this.lockerId,
    this.createOrder,
    this.onBooked,
    this.showMessage,
  });

  final Map<String, dynamic> cell;
  final String lockerName;
  final LatLng origin;

  /// Id tủ để gửi yêu cầu lên backend (hàng đợi điều phối của đội bay).
  /// Null thì không thể tạo order drone thật.
  final int? lockerId;

  final DroneOrderCreator? createOrder;
  final ValueChanged<int>? onBooked;
  final ValueChanged<String>? showMessage;

  @override
  State<DroneBookingSheet> createState() => _DroneBookingSheetState();
}

class _DroneBookingSheetState extends State<DroneBookingSheet> {
  final _descController = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _descController.dispose();
    super.dispose();
  }

  Future<void> _confirm() async {
    if (_submitting) return;

    final description = _descController.text.trim().isEmpty
        ? null
        : _descController.text.trim();
    final lockerId = widget.lockerId;
    if (lockerId == null) {
      _showMessage('Không xác định được tủ đích để tạo đơn drone');
      return;
    }
    final rawBoxId = widget.cell['id'];
    final preferredBoxId = rawBoxId is int ? rawBoxId : int.tryParse('$rawBoxId');
    if (preferredBoxId == null) {
      _showMessage('Không xác định được ô drone để giữ chỗ');
      return;
    }

    setState(() => _submitting = true);
    SmartDialog.showLoading<void>(msg: 'Đang tạo đơn drone...');

    try {
      final createOrder = widget.createOrder ??
          ({
            required destinationLockerId,
            required preferredBoxId,
            required description,
            required parcelWeightGrams,
            required paymentMethod,
            required idempotencyKey,
          }) {
            return LockerOpsService().createDroneDeliveryOrder(
              destinationLockerId: destinationLockerId,
              preferredBoxId: preferredBoxId,
              description: description,
              parcelWeightGrams: parcelWeightGrams,
              paymentMethod: paymentMethod,
              idempotencyKey: idempotencyKey,
            );
          };

      final response = await createOrder(
        destinationLockerId: lockerId,
        preferredBoxId: preferredBoxId,
        description: description,
        parcelWeightGrams: 1200,
        paymentMethod: 'CASH',
        idempotencyKey: 'drone-$lockerId-$preferredBoxId-${DateTime.now().microsecondsSinceEpoch}',
      );
      final rawOrderId = response['orderId'];
      final orderId = rawOrderId is int ? rawOrderId : int.tryParse('$rawOrderId');
      if (orderId == null) {
        throw StateError('Backend did not return a valid orderId');
      }

      widget.onBooked?.call(orderId);
      if (!mounted) return;
      Navigator.pop(context, response);
      _showMessage('Đã tạo đơn drone #$orderId');
    } catch (error) {
      _showMessage(LockerOpsService.errorMessage(error));
    } finally {
      SmartDialog.dismiss<void>();
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  void _showMessage(String message) {
    final showMessage = widget.showMessage;
    if (showMessage != null) {
      showMessage(message);
      return;
    }
    SmartDialog.showToast(message);
  }

  @override
  Widget build(BuildContext context) {
    final boxNumber = (widget.cell['boxNumber'] as int?) ?? 0;
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(20, 12, 20, 20 + bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF6366F1).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.flight,
                  color: Color(0xFF6366F1),
                  size: 26,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Đặt ô Drone',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  Text(
                    'Ô #$boxNumber · ${widget.lockerName}',
                    style: const TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Info banner
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFEEF2FF),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFF6366F1).withValues(alpha: 0.3),
              ),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline, color: Color(0xFF6366F1), size: 16),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Drone sẽ được quản lý điều phối và bay tới ô tủ để thả hàng. '
                    'Bạn có thể theo dõi tiến trình theo thời gian thực.',
                    style: TextStyle(fontSize: 12, color: Color(0xFF4F46E5)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Description input
          TextField(
            controller: _descController,
            maxLines: 2,
            decoration: InputDecoration(
              hintText: 'Mô tả hàng hóa (tùy chọn)',
              filled: true,
              fillColor: Colors.grey.shade50,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
              contentPadding: const EdgeInsets.all(14),
            ),
          ),
          const SizedBox(height: 12),

          // Fee row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Phí dịch vụ:', style: TextStyle(color: Colors.grey)),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  '15.000đ',
                  style: TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Confirm button
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _submitting ? null : _confirm,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              icon: const Icon(Icons.send_rounded, size: 18),
              label: const Text(
                'Xác nhận đặt ô Drone',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
