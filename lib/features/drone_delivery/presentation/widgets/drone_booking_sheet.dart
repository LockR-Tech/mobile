import 'package:flutter/material.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:latlong2/latlong.dart';
import 'package:smart_laundry_locker/core/config/business_config_provider.dart';
import 'package:smart_laundry_locker/features/drone_delivery/domain/entities/drone_labels.dart';
import 'package:smart_laundry_locker/features/drone_delivery/domain/entities/drone_parcel.dart';
import 'package:smart_laundry_locker/features/drone_delivery/presentation/widgets/drone_order_payment.dart';
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
      required DroneParcelDeclaration parcel,
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
    this.freeDroneCells,
    this.payOrder,
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

  /// Số ô DRONE còn trống của một tủ nhận; null = không tra được.
  final Future<int?> Function(int lockerId)? freeDroneCells;

  /// Thanh toán đơn vừa tạo; mặc định mở bảng thanh toán thật.
  final DroneOrderPayer? payOrder;
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
  final _lengthController = TextEditingController();
  final _widthController = TextEditingController();
  final _heightController = TextEditingController();
  final _valueController = TextEditingController();
  String _category = 'OTHER';
  bool _fragile = false;

  /// Người gửi cam kết kiện không chứa hàng cấm bay — bắt buộc trước khi tạo đơn.
  bool _declared = false;
  bool _submitting = false;
  bool _loadingDestinations = true;
  List<Map<String, dynamic>> _destinations = const [];
  Map<int, int> _freeCells = const {};
  Map<String, dynamic>? _pendingOrder;
  int? _destinationLockerId;
  int? _weightGrams;

  /// Mức khối lượng đang chọn; chưa chọn thì lấy mức nhỏ nhất đủ chứa khối lượng
  /// mặc định admin cấu hình.
  int get _selectedWeight {
    final choices = businessConfig.droneWeightChoices;
    final picked = _weightGrams;
    if (picked != null && choices.contains(picked)) return picked;
    return choices.firstWhere(
      (grams) => grams >= businessConfig.droneDefaultParcelWeightGrams,
      orElse: () => choices.last,
    );
  }

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
      final freeCells = await _loadFreeCells(destinations);
      final pendingOrder = freeCells.values.any((free) => free == 0)
          ? await _loadPendingUnpaidOrder()
          : null;
      if (!mounted) return;
      setState(() {
        _destinations = destinations;
        _freeCells = freeCells;
        _pendingOrder = pendingOrder;
        // Ưu tiên tủ còn ô nhận; giữ lựa chọn cũ nếu tủ đó vẫn nhận được.
        final current = _destinationLockerId;
        final keep =
            current != null &&
            freeCells[current] != 0 &&
            destinations.any((locker) => _asInt(locker['id']) == current);
        if (!keep) {
          final open = destinations.where(
            (locker) => freeCells[_asInt(locker['id'])] != 0,
          );
          final pick = open.isNotEmpty
              ? open.first
              : (destinations.isEmpty ? null : destinations.first);
          _destinationLockerId = pick == null ? null : _asInt(pick['id']);
        }
      });
    } catch (_) {
      if (mounted) setState(() => _destinations = const []);
    } finally {
      if (mounted) setState(() => _loadingDestinations = false);
    }
  }

  /// Số ô DRONE còn trống ở từng tủ nhận; thiếu khoá = không tra được (vẫn cho
  /// chọn, server là nơi quyết định cuối). Danh sách tủ do nơi gọi truyền sẵn thì
  /// chỉ tra khi nơi gọi cũng truyền [DroneBookingSheet.freeDroneCells].
  Future<Map<int, int>> _loadFreeCells(
    List<Map<String, dynamic>> destinations,
  ) async {
    final lookup =
        widget.freeDroneCells ??
        (widget.destinationLockers == null ? _freeDroneCellsFromLayout : null);
    if (lookup == null) return const {};
    final result = <int, int>{};
    await Future.wait(
      destinations.map((locker) async {
        final id = _asInt(locker['id'])!;
        try {
          final free = await lookup(id);
          if (free != null) result[id] = free;
        } catch (_) {}
      }),
    );
    return result;
  }

  static Future<int?> _freeDroneCellsFromLayout(int lockerId) async {
    final layout = await LockerOpsService().layout(lockerId);
    final cells = layout['cells'];
    if (cells is! List) return null;
    return cells
        .whereType<Map>()
        .where(
          (cell) =>
              '${cell['cellType']}'.toUpperCase() == 'DRONE' &&
              '${cell['status']}'.toUpperCase() == 'AVAILABLE',
        )
        .length;
  }

  /// Đơn drone của chính khách đang chờ thanh toán — đơn này vẫn giữ ô drone ở cả
  /// hai tủ, thường là lý do tủ nhận báo hết ô.
  Future<Map<String, dynamic>?> _loadPendingUnpaidOrder() async {
    if (widget.destinationLockers != null) return null;
    try {
      final orders = await LockerOpsService().myOrders();
      for (final order in orders) {
        if ('${order['type']}'.toUpperCase() == 'DRONE_DELIVERY' &&
            '${order['status']}'.toUpperCase() == 'AWAITING_DISPATCH' &&
            '${order['paymentStatus']}'.toUpperCase() != 'PAID' &&
            _asInt(order['id']) != null) {
          return order;
        }
      }
    } catch (_) {}
    return null;
  }

  bool get _destinationFull =>
      _destinationLockerId != null && _freeCells[_destinationLockerId] == 0;

  void _openPendingOrder() {
    final orderId = _asInt(_pendingOrder?['id']);
    if (orderId == null) return;
    // Màn gọi đưa khách tới màn theo dõi của đơn — nơi thanh toán được ngay.
    Navigator.pop(context);
    widget.onBooked?.call(orderId);
  }

  static int? _asInt(dynamic value) =>
      value is num ? value.toInt() : int.tryParse('$value');

  @override
  void dispose() {
    _descController.dispose();
    _receiverPhoneController.dispose();
    _receiverNameController.dispose();
    _receiverEmailController.dispose();
    _lengthController.dispose();
    _widthController.dispose();
    _heightController.dispose();
    _valueController.dispose();
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
    final parcel = _readParcel();
    if (parcel == null) return;
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
    if (_destinationFull) {
      _showMessage(_destinationFullMessage());
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
            required parcel,
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
              parcel: parcel.toJson(),
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
        parcelWeightGrams: _selectedWeight,
        parcel: parcel,
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
      SmartDialog.dismiss<void>(status: SmartStatus.loading);
      // Đội bay chỉ tiếp nhận đơn đã thanh toán ⇒ mở thanh toán ngay khi đơn vừa
      // tạo. Khách đóng bảng thanh toán thì vẫn tới màn theo dõi, nơi trả tiếp được.
      final message = await _payCreatedOrder(orderId, response);

      if (!mounted) return;
      // Đóng sheet trước rồi mới báo cho màn gọi, để màn gọi điều hướng được.
      Navigator.pop(context, response);
      widget.onBooked?.call(orderId);
      _showMessage(message);
    } catch (error) {
      // Ô gửi hỏng có mã riêng, nên BOX_NOT_AVAILABLE ở đây là tủ NHẬN hết ô drone
      // (có người vừa giữ mất) — báo đúng tủ và nạp lại số ô trống.
      if (LockerOpsService.errorCode(error) == 'BOX_NOT_AVAILABLE') {
        _showMessage(_destinationFullMessage());
        _loadDestinations();
      } else {
        _showMessage(LockerOpsService.errorMessage(error));
      }
    } finally {
      SmartDialog.dismiss<void>();
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  /// Đọc phần khai báo kiện; báo lỗi và trả null khi chưa hợp lệ. Server kiểm lại
  /// đúng các quy tắc này (`validateDroneParcelDeclaration`).
  DroneParcelDeclaration? _readParcel() {
    final sizeTexts = [
      _lengthController.text.trim(),
      _widthController.text.trim(),
      _heightController.text.trim(),
    ];
    List<int>? size;
    if (sizeTexts.any((text) => text.isNotEmpty)) {
      final parsed = sizeTexts.map(int.tryParse).toList();
      if (parsed.any((value) => value == null || value <= 0)) {
        _showMessage('Nhập đủ dài, rộng, cao của kiện (cm) hoặc bỏ trống cả ba');
        return null;
      }
      size = parsed.cast<int>();
      final bay = businessConfig.droneMaxParcelSizeCm;
      if (!droneParcelFits(size, bay)) {
        _showMessage(
          'Kiện không lọt khoang drone (tối đa ${bay[0]} × ${bay[1]} × ${bay[2]} cm)',
        );
        return null;
      }
    }
    int? declaredValue;
    final valueText = _valueController.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (valueText.isNotEmpty) {
      declaredValue = int.tryParse(valueText);
      if (declaredValue == null ||
          declaredValue > businessConfig.droneMaxDeclaredValue) {
        _showMessage(
          'Drone chỉ nhận kiện có giá trị tới '
          '${fmtPrice(businessConfig.droneMaxDeclaredValue)}',
        );
        return null;
      }
    }
    if (!_declared) {
      _showMessage('Bạn cần cam kết kiện không chứa hàng cấm bay');
      return null;
    }
    return DroneParcelDeclaration(
      category: _category,
      lengthCm: size?[0],
      widthCm: size?[1],
      heightCm: size?[2],
      declaredValue: declaredValue,
      fragile: _fragile,
      prohibitedItemsDeclared: true,
    );
  }

  InputDecoration _parcelInput(String label, {String? suffix}) =>
      InputDecoration(
        labelText: label,
        suffixText: suffix,
        isDense: true,
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
      );

  /// Loại hàng, kích thước, giá trị khai báo và cờ dễ vỡ.
  List<Widget> _parcelFields() {
    final bay = businessConfig.droneMaxParcelSizeCm;
    return [
      const Text('Loại hàng', style: TextStyle(fontWeight: FontWeight.w700)),
      const SizedBox(height: 8),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final entry in droneParcelCategories.entries)
            ChoiceChip(
              key: ValueKey('drone-category-${entry.key}'),
              label: Text(entry.value),
              selected: entry.key == _category,
              onSelected: (_) => setState(() => _category = entry.key),
            ),
        ],
      ),
      const SizedBox(height: 12),
      Row(
        children: [
          Expanded(
            child: TextField(
              key: const ValueKey('drone-parcel-length'),
              controller: _lengthController,
              keyboardType: TextInputType.number,
              decoration: _parcelInput('Dài', suffix: 'cm'),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              key: const ValueKey('drone-parcel-width'),
              controller: _widthController,
              keyboardType: TextInputType.number,
              decoration: _parcelInput('Rộng', suffix: 'cm'),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              key: const ValueKey('drone-parcel-height'),
              controller: _heightController,
              keyboardType: TextInputType.number,
              decoration: _parcelInput('Cao', suffix: 'cm'),
            ),
          ),
        ],
      ),
      const SizedBox(height: 6),
      Text(
        'Kích thước tuỳ chọn. Khoang drone tối đa ${bay[0]} × ${bay[1]} × ${bay[2]} cm.',
        style: const TextStyle(fontSize: 12, color: Colors.grey),
      ),
      const SizedBox(height: 10),
      TextField(
        key: const ValueKey('drone-parcel-value'),
        controller: _valueController,
        keyboardType: TextInputType.number,
        decoration: _parcelInput(
          'Giá trị khai báo (tuỳ chọn)',
          suffix: 'đ',
        ),
      ),
      const SizedBox(height: 6),
      Text(
        'Căn cứ bồi thường nếu kiện hư hỏng, thất lạc. Tối đa '
        '${fmtPrice(businessConfig.droneMaxDeclaredValue)}.',
        style: const TextStyle(fontSize: 12, color: Colors.grey),
      ),
      // Sheet tự vẽ nền trắng bằng Container nên không dùng ListTile (cần Material).
      Row(
        children: [
          const Expanded(child: Text('Hàng dễ vỡ')),
          Switch(
            key: const ValueKey('drone-parcel-fragile'),
            value: _fragile,
            onChanged: (value) => setState(() => _fragile = value),
          ),
        ],
      ),
      const SizedBox(height: 4),
    ];
  }

  Future<String> _payCreatedOrder(
    int orderId,
    Map<String, dynamic> response,
  ) async {
    final due = orderAmountDue(response);
    try {
      final outcome = await (widget.payOrder ?? payDroneOrder)(
        context,
        orderId: orderId,
        total: due > 0
            ? due
            : businessConfig.droneDeliveryFeeFor(_selectedWeight).toDouble(),
      );
      return droneOrderPaymentMessage(outcome);
    } catch (error) {
      return 'Đã tạo đơn drone nhưng chưa thanh toán được: '
          '${LockerOpsService.errorMessage(error)}';
    }
  }

  String _destinationFullMessage() =>
      '${_destinationName() ?? 'Tủ nhận'} đã hết ô drone trống để nhận hàng. '
      'Hãy chọn tủ nhận khác hoặc thử lại sau.';

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
              isExpanded: true,
              items: _destinations.map((locker) {
                final id = _asInt(locker['id'])!;
                final name = locker['name'] ?? locker['code'] ?? 'Tủ #$id';
                final free = _freeCells[id];
                final suffix = switch (free) {
                  null => '',
                  0 => ' · hết ô nhận',
                  _ => ' · còn $free ô drone',
                };
                return DropdownMenuItem<int>(
                  value: id,
                  // Tủ hết ô nhận vẫn hiện để khách biết lý do, nhưng không chọn được.
                  enabled: free != 0,
                  child: Text(
                    '$name$suffix',
                    overflow: TextOverflow.ellipsis,
                    style: free == 0 ? const TextStyle(color: Colors.grey) : null,
                  ),
                );
              }).toList(),
              onChanged: _loadingDestinations
                  ? null
                  : (value) => setState(() => _destinationLockerId = value),
            ),
            const SizedBox(height: 12),
            if (_destinationFull) ...[
              _DestinationFullNotice(
                message: _destinationFullMessage(),
                pendingOrderCode: _pendingOrder?['orderCode']?.toString(),
                onOpenPendingOrder:
                    _pendingOrder == null || widget.onBooked == null
                    ? null
                    : _openPendingOrder,
              ),
              const SizedBox(height: 12),
            ],

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
                      'Tạo đơn xong bạn thanh toán ngay, bỏ kiện vào ô drone này rồi đội bay sẽ nạp '
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

            ..._parcelFields(),

            // Khối lượng khai báo — quyết định phí; đội bay cân lại khi nạp hàng.
            const Text(
              'Khối lượng kiện hàng',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final grams in businessConfig.droneWeightChoices)
                  ChoiceChip(
                    key: ValueKey('drone-weight-$grams'),
                    label: Text(droneWeightShortLabel(grams)),
                    selected: grams == _selectedWeight,
                    onSelected: (_) => setState(() => _weightGrams = grams),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Chọn mức bằng hoặc lớn hơn khối lượng thật. Đội bay cân lại khi nạp '
              'hàng: nặng hơn mức đã chọn quá '
              '${businessConfig.droneWeightToleranceGrams} g thì bạn trả thêm phần '
              'phí chênh trước khi drone bay; nhẹ hơn không hoàn lại.',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 12),

            // Fee row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Phí giao drone:',
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
                    fmtPrice(
                      businessConfig.droneDeliveryFeeFor(_selectedWeight),
                    ),
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
            if (businessConfig.droneUnpaidCancelMinutes > 0) ...[
              const SizedBox(height: 4),
              Text(
                'Đơn chưa thanh toán sau ${businessConfig.droneUnpaidCancelMinutes} '
                'phút sẽ tự huỷ và nhả ô.',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Checkbox(
                  key: const ValueKey('drone-prohibited-declaration'),
                  value: _declared,
                  onChanged: (value) =>
                      setState(() => _declared = value ?? false),
                ),
                Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => setState(() => _declared = !_declared),
                    child: const Padding(
                      padding: EdgeInsets.only(top: 12),
                      child: Text(
                        'Tôi cam kết kiện không chứa hàng cấm bay: pin rời, chất '
                        'lỏng, chất dễ cháy nổ, hàng cấm theo pháp luật.',
                        style: TextStyle(fontSize: 12.5),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            if (businessConfig.droneFlightsSuspended) ...[
              const SizedBox(height: 4),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFFCD34D)),
                ),
                child: const Text(
                  'Dịch vụ giao drone đang tạm dừng (thời tiết hoặc sự cố vận '
                  'hành). Vui lòng thử lại sau.',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: Color(0xFFB45309),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 12),

            // Confirm button
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed:
                    _submitting ||
                        _loadingDestinations ||
                        _destinationFull ||
                        businessConfig.droneFlightsSuspended
                    ? null
                    : _confirm,
                style: FilledButton.styleFrom(
                  backgroundColor: opsPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                icon: const Icon(Icons.send_rounded, size: 18),
                label: const Text(
                  'Tạo đơn và thanh toán',
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

/// Báo trước khi khách điền form: tủ nhận hết ô drone thì chưa tạo đơn được.
class _DestinationFullNotice extends StatelessWidget {
  const _DestinationFullNotice({
    required this.message,
    this.pendingOrderCode,
    this.onOpenPendingOrder,
  });

  final String message;
  final String? pendingOrderCode;
  final VoidCallback? onOpenPendingOrder;

  @override
  Widget build(BuildContext context) {
    const color = Color(0xFFB45309);
    final onOpen = onOpenPendingOrder;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF3C7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFCD34D)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            onOpen == null
                ? message
                : '$message\nĐơn ${pendingOrderCode ?? 'drone'} của bạn chưa thanh '
                      'toán và đang giữ ô drone.',
            style: const TextStyle(
              color: color,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              height: 1.4,
            ),
          ),
          if (onOpen != null) ...[
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                style: FilledButton.styleFrom(backgroundColor: color),
                onPressed: onOpen,
                child: const Text('Mở đơn đang chờ thanh toán'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
