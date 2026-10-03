import 'package:flutter/material.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:latlong2/latlong.dart';
import 'package:smart_laundry_locker/core/config/business_config_provider.dart';
import 'package:smart_laundry_locker/shared/widgets/app_lottie.dart';
import 'package:smart_laundry_locker/features/locker_ops/data/locker_ops_service.dart';
import 'package:smart_laundry_locker/features/locker_ops/presentation/utils/business_rules_text.dart';
import 'package:smart_laundry_locker/features/locker_ops/presentation/widgets/ops_widgets.dart';

typedef DroneOrderCreator =
    Future<Map<String, dynamic>> Function({
      required int sourceLockerId,
      required int destinationLockerId,
      required int? sourceBoxId,
      required int? preferredBoxId,
      required String? receiverPhone,
      required String? receiverName,
      required String? receiverEmail,
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
    this.destinationLockers,
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
  final List<Map<String, dynamic>>? destinationLockers;

  @override
  State<DroneBookingSheet> createState() => _DroneBookingSheetState();
}

class _DroneBookingSheetState extends State<DroneBookingSheet>
    with BusinessConfigStateMixin {
  final _descController = TextEditingController();
  final _receiverPhoneController = TextEditingController();
  final _receiverNameController = TextEditingController();
  final _receiverEmailController = TextEditingController();
  bool _submitting = false;
  bool _loadingDestinations = true;
  List<Map<String, dynamic>> _destinations = const [];
  int? _destinationLockerId;

  @override
  void initState() {
    super.initState();
    _loadDestinations();
  }

  Future<void> _loadDestinations() async {
    try {
      final all =
          widget.destinationLockers ?? await LockerOpsService().lockers();
      final sourceId = widget.lockerId;
      final destinations = all
          .where((locker) {
            final id = _asInt(locker['id']);
            return id != null &&
                id != sourceId &&
                locker['landingPad'] == true &&
                '${locker['status']}'.toUpperCase() == 'ACTIVE';
          })
          .toList(growable: false);
      if (!mounted) return;
      setState(() {
        _destinations = destinations;
        _destinationLockerId = destinations.isEmpty
            ? null
            : _asInt(destinations.first['id']);
      });
    } catch (_) {
      if (mounted) setState(() => _destinations = const []);
    } finally {
      if (mounted) setState(() => _loadingDestinations = false);
    }
  }

  static int? _asInt(dynamic value) =>
      value is num ? value.toInt() : int.tryParse('$value');

  @override
  void dispose() {
    _descController.dispose();
    _receiverPhoneController.dispose();
    _receiverNameController.dispose();
    _receiverEmailController.dispose();
    super.dispose();
  }

  Future<void> _confirm() async {
    if (_submitting) return;

    final description = _descController.text.trim().isEmpty
        ? null
        : _descController.text.trim();
    // Bỏ trống số điện thoại ⇒ người đặt tự nhận hàng ở tủ nhận.
    final receiverPhone = _receiverPhoneController.text.replaceAll(' ', '');
    final receiverName = _receiverNameController.text.trim();
    if (receiverPhone.isNotEmpty &&
        !RegExp(r'^\+?[0-9]{9,15}$').hasMatch(receiverPhone)) {
      _showMessage('Số điện thoại người nhận không hợp lệ');
      return;
    }
    final receiverEmail = _receiverEmailController.text.trim();
    if (receiverEmail.isNotEmpty &&
        !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(receiverEmail)) {
      _showMessage('Email người nhận không hợp lệ');
      return;
    }
    final sourceLockerId = widget.lockerId;
    if (sourceLockerId == null) {
      _showMessage('Không xác định được tủ nguồn của drone');
      return;
    }
    final destinationLockerId = _destinationLockerId;
    if (destinationLockerId == null) {
      _showMessage('Chưa có tủ đích hoạt động và có bãi đáp drone');
      return;
    }

    setState(() => _submitting = true);
    SmartDialog.showLoading<void>(msg: 'Đang tạo đơn drone...');

    try {
      final createOrder =
          widget.createOrder ??
          ({
            required destinationLockerId,
            required sourceLockerId,
            required sourceBoxId,
            required preferredBoxId,
            required receiverPhone,
            required receiverName,
            required receiverEmail,
            required description,
            required parcelWeightGrams,
            required paymentMethod,
            required idempotencyKey,
          }) {
            return LockerOpsService().createDroneDeliveryOrder(
              sourceLockerId: sourceLockerId,
              destinationLockerId: destinationLockerId,
              sourceBoxId: sourceBoxId,
              preferredBoxId: preferredBoxId,
              receiverPhone: receiverPhone,
              receiverName: receiverName,
              receiverEmail: receiverEmail,
              description: description,
              parcelWeightGrams: parcelWeightGrams,
              paymentMethod: paymentMethod,
              idempotencyKey: idempotencyKey,
            );
          };

      final response = await createOrder(
        sourceLockerId: sourceLockerId,
        destinationLockerId: destinationLockerId,
        // Ô drone khách vừa chạm ở tủ gửi — nơi bỏ kiện chờ đội bay nạp lên drone.
        sourceBoxId: _asInt(widget.cell['id']),
        preferredBoxId: null,
        receiverPhone: receiverPhone.isEmpty ? null : receiverPhone,
        receiverName: receiverName.isEmpty ? null : receiverName,
        receiverEmail: receiverEmail.isEmpty ? null : receiverEmail,
        description: description,
        parcelWeightGrams: businessConfig.droneDefaultParcelWeightGrams,
        // Chỉ là phương thức dự kiến ghi trên đơn; tiền thu thật ở bước thanh
        // toán. App khách không còn tiền mặt tự xác nhận.
        paymentMethod: 'WALLET',
        idempotencyKey:
            'drone-$sourceLockerId-$destinationLockerId-${DateTime.now().microsecondsSinceEpoch}',
      );
      final rawOrderId = response['orderId'];
      final orderId = rawOrderId is int
          ? rawOrderId
          : int.tryParse('$rawOrderId');
      if (orderId == null) {
        throw StateError('Backend did not return a valid orderId');
      }

      if (!mounted) return;
      // Đóng sheet trước rồi mới báo cho màn gọi, để màn gọi điều hướng được.
      Navigator.pop(context, response);
      widget.onBooked?.call(orderId);
      _showMessage('Đã tạo đơn drone. Thanh toán để đội bay tiếp nhận.');
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
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(20, 12, 20, 20 + bottom),
      // Thêm ô người nhận nên sheet cao hơn màn hình nhỏ khi bàn phím mở.
      child: SingleChildScrollView(
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
                  width: 52,
                  height: 52,
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6366F1).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: AppLottie(
                    AppLottieAssets.airplaneBox,
                    fallback: (context) => const Icon(
                      Icons.flight_takeoff,
                      color: Color(0xFF6366F1),
                      size: 26,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Gửi hàng bằng Drone',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    Text(
                      'Trạm nguồn · ${widget.lockerName}',
                      style: const TextStyle(fontSize: 13, color: Colors.grey),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),

            DropdownButtonFormField<int>(
              key: const ValueKey('drone-destination-locker'),
              initialValue: _destinationLockerId,
              decoration: const InputDecoration(
                labelText: 'Tủ nhận (Locker B)',
                prefixIcon: Icon(Icons.location_on_outlined),
                border: OutlineInputBorder(),
              ),
              hint: Text(
                _loadingDestinations
                    ? 'Đang tải tủ nhận...'
                    : 'Chọn tủ nhận có bãi đáp',
              ),
              items: _destinations.map((locker) {
                final id = _asInt(locker['id'])!;
                final name = locker['name'] ?? locker['code'] ?? 'Tủ #$id';
                return DropdownMenuItem<int>(value: id, child: Text('$name'));
              }).toList(),
              onChanged: _loadingDestinations
                  ? null
                  : (value) => setState(() => _destinationLockerId = value),
            ),
            const SizedBox(height: 12),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Text(
                'Lộ trình: ${widget.lockerName} (Locker A) → '
                '${_destinationName() ?? 'chưa chọn Locker B'}',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
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
                      'Bỏ kiện vào ô drone này, thanh toán đơn rồi đội bay sẽ nạp '
                      'hàng và cho drone bay tới tủ nhận. Bạn theo dõi được từng '
                      'chặng theo thời gian thực.',
                      style: TextStyle(fontSize: 12, color: Color(0xFF4F46E5)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Người nhận (tuỳ chọn)
            TextField(
              key: const ValueKey('drone-receiver-phone'),
              controller: _receiverPhoneController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: 'SĐT người nhận (bỏ trống nếu bạn tự nhận)',
                prefixIcon: const Icon(Icons.phone_outlined),
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
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              key: const ValueKey('drone-receiver-name'),
              controller: _receiverNameController,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                labelText: 'Tên người nhận (tuỳ chọn)',
                prefixIcon: const Icon(Icons.person_outline),
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
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              key: const ValueKey('drone-receiver-email'),
              controller: _receiverEmailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: 'Email người nhận (tuỳ chọn)',
                prefixIcon: const Icon(Icons.email_outlined),
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
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Khi hàng vào tủ, người nhận được gửi mã mở ô qua email (email nhập ở '
              'trên, hoặc email tài khoản Lock.R của số này), qua app nếu số có tài '
              'khoản, qua SMS nếu chưa có.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 12),

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
                const Text(
                  'Phí dịch vụ:',
                  style: TextStyle(color: Colors.grey),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    fmtPrice(businessConfig.droneDeliveryFee),
                    style: const TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              dronePickupPolicyText(businessConfig),
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 20),

            // Confirm button
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _submitting ? null : _confirm,
                style: FilledButton.styleFrom(
                  backgroundColor: opsPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                icon: const Icon(Icons.send_rounded, size: 18),
                label: const Text(
                  'Tạo yêu cầu giao Drone',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String? _destinationName() {
    final id = _destinationLockerId;
    if (id == null) return null;
    for (final locker in _destinations) {
      if (_asInt(locker['id']) == id) {
        return (locker['name'] ?? locker['code'] ?? 'Tủ #$id').toString();
      }
    }
    return 'Tủ #$id';
  }
}
