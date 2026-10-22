import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_laundry_locker/core/config/business_config_provider.dart';
import 'package:smart_laundry_locker/features/drone_delivery/domain/entities/drone_booking.dart';
import 'package:smart_laundry_locker/features/drone_delivery/domain/entities/drone_labels.dart';
import 'package:smart_laundry_locker/features/drone_delivery/domain/entities/drone_parcel.dart';
import 'package:smart_laundry_locker/features/drone_delivery/presentation/pages/pickup_location_picker_page.dart';
import 'package:smart_laundry_locker/features/drone_delivery/presentation/widgets/drone_order_payment.dart';
import 'package:smart_laundry_locker/features/locker_ops/data/locker_ops_service.dart';
import 'package:smart_laundry_locker/features/locker_ops/presentation/utils/business_rules_text.dart';
import 'package:smart_laundry_locker/features/locker_ops/presentation/widgets/loyalty_redeem_toggle.dart';
import 'package:smart_laundry_locker/features/locker_ops/presentation/widgets/ops_widgets.dart';
import 'package:smart_laundry_locker/features/locker_ops/presentation/widgets/order_extras.dart';
import 'package:smart_laundry_locker/features/profile/presentation/providers/profile_provider.dart';

typedef DroneOrderCreator =
    Future<Map<String, dynamic>> Function(
      DroneBookingRequest request,
      String idempotencyKey,
    );

typedef DroneQuoteLoader =
    Future<DroneQuote> Function({
      required int destinationLockerId,
      required double pickupLatitude,
      required double pickupLongitude,
      required int parcelWeightGrams,
    });

typedef DroneSlotLoader =
    Future<List<Map<String, dynamic>>> Function(int lockerId);

typedef PickupLocationPicker =
    Future<PickupLocation?> Function(
      BuildContext context,
      PickupLocation? current,
    );

Future<PickupLocation?> _pushLocationPicker(
  BuildContext context,
  PickupLocation? current,
) => Navigator.of(context).push<PickupLocation>(
  MaterialPageRoute(builder: (_) => PickupLocationPickerPage(initial: current)),
);

/// Đặt giao hàng bằng drone, lấy hàng tận nhà.
///
/// Người gửi chọn điểm lấy hàng (vị trí hiện tại hoặc ghim/tìm trên bản đồ), nhập liên
/// hệ của mình và của người nhận — tên, số điện thoại, email đều bắt buộc — chọn tủ nhận
/// và khai báo kiện. Hệ thống tự chọn tủ gần người gửi nhất làm nơi drone cất cánh; một
/// kỹ thuật viên drone tới lấy kiện sau khi đơn được thanh toán.
class DroneBookingPage extends StatefulWidget {
  const DroneBookingPage({
    super.key,
    this.initialDestinationLockerId,
    this.preferredBoxId,
    this.initialSender,
    this.destinationLockers,
    this.loadQuote,
    this.loadDroneSlots,
    this.createOrder,
    this.payOrder,
    this.pickLocation = _pushLocationPicker,
    this.onBooked,
    this.showMessage,
    this.service,
  });

  /// Tủ khách đang xem khi bấm "giao drone" — chọn sẵn làm tủ nhận.
  final int? initialDestinationLockerId;

  /// Ô DRONE khách đã chạm ở tủ nhận.
  final int? preferredBoxId;

  /// Liên hệ người gửi điền sẵn; null thì lấy từ hồ sơ đang đăng nhập.
  final DroneContact? initialSender;
  final List<Map<String, dynamic>>? destinationLockers;
  final DroneQuoteLoader? loadQuote;
  final DroneSlotLoader? loadDroneSlots;
  final DroneOrderCreator? createOrder;
  final DroneOrderPayer? payOrder;
  final PickupLocationPicker pickLocation;
  final ValueChanged<int>? onBooked;
  final ValueChanged<String>? showMessage;

  /// Client gọi API (tủ, báo giá, tạo đơn, mã giảm giá, điểm thưởng); null thì
  /// dựng mặc định khi cần.
  final LockerOpsService? service;

  @override
  State<DroneBookingPage> createState() => _DroneBookingPageState();
}

class _DroneBookingPageState extends State<DroneBookingPage>
    with BusinessConfigStateMixin {
  static final _phonePattern = RegExp(r'^\+?[0-9]{9,15}$');
  static final _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  final _senderName = TextEditingController();
  final _senderPhone = TextEditingController();
  final _senderEmail = TextEditingController();
  final _receiverName = TextEditingController();
  final _receiverPhone = TextEditingController();
  final _receiverEmail = TextEditingController();
  final _pickupNote = TextEditingController();
  final _description = TextEditingController();
  final _length = TextEditingController();
  final _width = TextEditingController();
  final _height = TextEditingController();
  final _value = TextEditingController();

  /// Một khoá cho cả lần mở form: bấm lại sau lỗi mạng không tạo đơn thứ hai.
  final String _idempotencyKey =
      'drone-${DateTime.now().microsecondsSinceEpoch}';

  PickupLocation? _pickup;
  List<Map<String, dynamic>> _destinations = const [];
  final Map<int, int?> _availableDroneSlots = {};
  final Map<int, List<Map<String, dynamic>>> _availableDroneBoxes = {};
  bool _loadingDestinations = true;
  int? _destinationLockerId;
  int? _destinationBoxId;
  int? _weightGrams;
  String? _category;
  bool _fragile = false;
  bool _declared = false;
  bool _submitting = false;

  DroneQuote? _quote;
  String? _quoteProblem;
  bool _quoting = false;
  int _quoteRequest = 0;

  /// Mã giảm giá đã áp (theo tủ gửi của báo giá) và điểm thưởng khách bật dùng.
  int _discount = 0;
  String? _promoCode;
  int _pointsToUse = 0;
  int _pointsDiscount = 0;

  LockerOpsService? _ownService;

  /// Dựng lười, chỉ khi thật sự gọi API (trong try) — màn mở độc lập vẫn chạy.
  LockerOpsService get _ops =>
      widget.service ?? (_ownService ??= LockerOpsService());

  /// Phí giao theo báo giá (hoặc bảng giá admin khi chưa có báo giá).
  int get _fee =>
      (_quote?.fee ?? businessConfig.droneDeliveryFeeFor(_selectedWeight))
          .round();

  /// Phí sau mã giảm giá — số tiền dùng để hỏi được dùng bao nhiêu điểm.
  int get _feeAfterVoucher => (_fee - _discount).clamp(0, _fee);

  /// Tạm tính sau mã giảm giá và điểm thưởng.
  int get _netFee =>
      (_feeAfterVoucher - _pointsDiscount).clamp(0, _feeAfterVoucher);

  /// Báo giá mất hoặc đổi tủ gửi ⇒ mã đã áp (kiểm theo tủ gửi cũ) và điểm phải
  /// chọn lại.
  void _resetOffersFor(DroneQuote? next) {
    final previous = _quote;
    if (next != null &&
        previous != null &&
        next.sourceLockerId == previous.sourceLockerId) {
      return;
    }
    _discount = 0;
    _promoCode = null;
    if (next == null) {
      _pointsToUse = 0;
      _pointsDiscount = 0;
    }
  }

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
    _destinationLockerId = widget.initialDestinationLockerId;
    _destinationBoxId = widget.preferredBoxId;
    _prefillSender();
    _loadDestinations();
  }

  /// Người gửi mặc định là chính tài khoản đang đặt; vẫn sửa được (gửi hộ người khác).
  void _prefillSender() {
    var sender = widget.initialSender;
    if (sender == null) {
      try {
        final profile = context.read<ProfileProvider>().profile;
        if (profile != null) {
          sender = DroneContact(
            name: profile.fullName,
            phone: profile.phoneNumber,
            email: profile.email,
          );
        }
      } catch (_) {
        // Không có ProfileProvider (màn mở độc lập): người gửi tự nhập.
      }
    }
    if (sender != null) {
      _senderName.text = sender.name;
      _senderPhone.text = sender.phone;
      _senderEmail.text = sender.email;
    }
  }

  Future<void> _loadDestinations() async {
    try {
      final all = widget.destinationLockers ?? await _ops.lockers();
      // Keep every locker returned by the system visible. Ineligible lockers
      // are rendered disabled below with the reason, instead of disappearing
      // from the customer's destination list.
      final destinations = all
          .where((locker) => _asInt(locker['id']) != null)
          .toList(growable: false);
      if (!mounted) return;
      setState(() {
        _destinations = destinations;
        final current = _destinationLockerId;
        if (current == null ||
            !destinations.any((locker) => _asInt(locker['id']) == current)) {
          _destinationLockerId = destinations.length == 1
              ? _asInt(destinations.first['id'])
              : null;
        }
      });
      await Future.wait(
        destinations.where(_canReceiveDrone).map((locker) async {
          final id = _asInt(locker['id']);
          if (id == null) return;
          try {
            final boxes =
                await (widget.loadDroneSlots ??
                    (lockerId) async {
                      final layout = await LockerOpsService().layout(lockerId);
                      final cells = layout['cells'];
                      return cells is List
                          ? cells
                                .whereType<Map>()
                                .where(
                                  (cell) =>
                                      '${cell['cellType']}'.toUpperCase() ==
                                          'DRONE' &&
                                      '${cell['status']}'.toUpperCase() ==
                                          'AVAILABLE',
                                )
                                .map((cell) => Map<String, dynamic>.from(cell))
                                .toList(growable: false)
                          : <Map<String, dynamic>>[];
                    })(id);
            if (mounted) {
              setState(() {
                _availableDroneBoxes[id] = boxes;
                _availableDroneSlots[id] = boxes.length;
              });
              if (id == _destinationLockerId &&
                  boxes.every(
                    (box) => _asInt(box['id']) != _destinationBoxId,
                  )) {
                setState(() => _destinationBoxId = null);
              }
            }
          } catch (_) {
            if (mounted) setState(() => _availableDroneSlots[id] = null);
          }
        }),
      );
      _refreshQuote();
    } catch (_) {
      if (mounted) setState(() => _destinations = const []);
    } finally {
      if (mounted) setState(() => _loadingDestinations = false);
    }
  }

  static int? _asInt(dynamic value) =>
      value is num ? value.toInt() : int.tryParse('$value');

  static bool _canReceiveDrone(Map<String, dynamic> locker) =>
      locker['landingPad'] == true &&
      '${locker['status']}'.toUpperCase() == 'ACTIVE';

  String _destinationUnavailableReason(Map<String, dynamic> locker) {
    final status = '${locker['status']}'.toUpperCase();
    if (status != 'ACTIVE') {
      return status == 'MAINTENANCE' ? 'Đang bảo trì' : 'Chưa hoạt động';
    }
    if (locker['landingPad'] != true) return 'Chưa có bãi đáp drone';
    final slots = _availableDroneSlots[_asInt(locker['id'])];
    if (slots == null) return 'Đang kiểm tra ô drone';
    if (slots == 0) return 'Hết ô drone trống';
    return '$slots ô drone trống';
  }

  @override
  void dispose() {
    for (final controller in [
      _senderName,
      _senderPhone,
      _senderEmail,
      _receiverName,
      _receiverPhone,
      _receiverEmail,
      _pickupNote,
      _description,
      _length,
      _width,
      _height,
      _value,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _choosePickup() async {
    final picked = await widget.pickLocation(context, _pickup);
    if (picked == null || !mounted) return;
    setState(() => _pickup = picked);
    _refreshQuote();
  }

  /// Hỏi server drone sẽ cất cánh ở tủ nào và phí bao nhiêu — cũng là nơi biết sớm điểm
  /// lấy hàng có nằm trong vùng phục vụ không, trước khi người gửi điền hết form.
  Future<void> _refreshQuote() async {
    final pickup = _pickup;
    final destination = _destinationLockerId;
    if (pickup == null || destination == null) {
      setState(() {
        _resetOffersFor(null);
        _quote = null;
        _quoteProblem = null;
      });
      return;
    }
    final request = ++_quoteRequest;
    setState(() {
      _quoting = true;
      _quoteProblem = null;
    });
    try {
      final loader =
          widget.loadQuote ??
          ({
            required destinationLockerId,
            required pickupLatitude,
            required pickupLongitude,
            required parcelWeightGrams,
          }) async => DroneQuote.fromJson(
            await _ops.quoteDroneDelivery(
              destinationLockerId: destinationLockerId,
              pickupLatitude: pickupLatitude,
              pickupLongitude: pickupLongitude,
              parcelWeightGrams: parcelWeightGrams,
            ),
          );
      final quote = await loader(
        destinationLockerId: destination,
        pickupLatitude: pickup.latitude,
        pickupLongitude: pickup.longitude,
        parcelWeightGrams: _selectedWeight,
      );
      if (!mounted || request != _quoteRequest) return;
      setState(() {
        _resetOffersFor(quote);
        _quote = quote;
        _quoting = false;
      });
    } catch (error) {
      if (!mounted || request != _quoteRequest) return;
      setState(() {
        _resetOffersFor(null);
        _quote = null;
        _quoting = false;
        _quoteProblem = LockerOpsService.errorMessage(error);
      });
    }
  }

  void _showMessage(String message) {
    final showMessage = widget.showMessage;
    if (showMessage != null) {
      showMessage(message);
      return;
    }
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  DroneContact? _readContact(
    String who,
    TextEditingController name,
    TextEditingController phone,
    TextEditingController email,
  ) {
    final cleanName = name.text.trim();
    final cleanPhone = phone.text.replaceAll(' ', '');
    final cleanEmail = email.text.trim();
    if (cleanName.isEmpty) {
      _showMessage('Nhập tên $who');
      return null;
    }
    if (!_phonePattern.hasMatch(cleanPhone)) {
      _showMessage('Số điện thoại $who không hợp lệ');
      return null;
    }
    if (!_emailPattern.hasMatch(cleanEmail)) {
      _showMessage('Email $who không hợp lệ');
      return null;
    }
    return DroneContact(name: cleanName, phone: cleanPhone, email: cleanEmail);
  }

  /// Đọc và kiểm toàn bộ form theo đúng các quy tắc server áp (`DroneOrderBookingService`).
  DroneBookingRequest? _readRequest() {
    final pickup = _pickup;
    if (pickup == null) {
      _showMessage('Chọn điểm lấy hàng');
      return null;
    }
    final sender = _readContact(
      'người gửi',
      _senderName,
      _senderPhone,
      _senderEmail,
    );
    if (sender == null) return null;
    final receiver = _readContact(
      'người nhận',
      _receiverName,
      _receiverPhone,
      _receiverEmail,
    );
    if (receiver == null) return null;
    final destination = _destinationLockerId;
    if (destination == null) {
      _showMessage('Chọn tủ nhận');
      return null;
    }
    final availableDroneSlots = _availableDroneSlots[destination];
    if (availableDroneSlots == null) {
      _showMessage(
        'Đang kiểm tra ô drone trống của tủ nhận, vui lòng chờ một chút',
      );
      return null;
    }
    if (availableDroneSlots == 0) {
      _showMessage('Tủ nhận này đã hết ô drone trống, hãy chọn tủ khác');
      return null;
    }
    final destinationBox = _destinationBoxId;
    if (destinationBox == null ||
        !(_availableDroneBoxes[destination]?.any(
              (box) => _asInt(box['id']) == destinationBox,
            ) ??
            false)) {
      _showMessage('Chọn ô drone nhận còn trống tại tủ nhận');
      return null;
    }
    final category = _category;
    if (category == null) {
      _showMessage('Chọn loại hàng');
      return null;
    }

    final sizeTexts = [
      _length.text.trim(),
      _width.text.trim(),
      _height.text.trim(),
    ];
    List<int>? size;
    if (sizeTexts.any((text) => text.isNotEmpty)) {
      final parsed = sizeTexts.map(int.tryParse).toList();
      if (parsed.any((value) => value == null || value <= 0)) {
        _showMessage(
          'Nhập đủ dài, rộng, cao của kiện (cm) hoặc bỏ trống cả ba',
        );
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
    final valueText = _value.text.replaceAll(RegExp(r'[^0-9]'), '');
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
    final note = _pickupNote.text.trim();
    final description = _description.text.trim();
    return DroneBookingRequest(
      destinationLockerId: destination,
      // Ô đã chạm chỉ có nghĩa khi tủ nhận vẫn là tủ khách mở form từ đó.
      preferredBoxId: destinationBox,
      pickup: pickup,
      pickupNote: note.isEmpty ? null : note,
      sender: sender,
      receiver: receiver,
      parcelWeightGrams: _selectedWeight,
      description: description.isEmpty ? null : description,
      parcel: DroneParcelDeclaration(
        category: category,
        lengthCm: size?[0],
        widthCm: size?[1],
        heightCm: size?[2],
        declaredValue: declaredValue,
        fragile: _fragile,
        prohibitedItemsDeclared: true,
      ),
      promotionCode: _promoCode,
      pointsToUse: _pointsToUse > 0 ? _pointsToUse : null,
    );
  }

  Future<void> _submit() async {
    if (_submitting) return;
    final request = _readRequest();
    if (request == null) return;
    setState(() => _submitting = true);
    try {
      final create =
          widget.createOrder ??
          (request, key) => _ops.createDroneDeliveryOrder(
            body: request.toJson(),
            idempotencyKey: key,
          );
      final response = await create(request, _idempotencyKey);
      final orderId = _asInt(response['orderId']);
      if (orderId == null) {
        throw StateError('Backend did not return a valid orderId');
      }
      if (!mounted) return;
      // Kỹ thuật viên chỉ được mời tới lấy hàng sau khi đơn đã thanh toán ⇒ mở thanh
      // toán ngay. Khách đóng bảng thanh toán thì vẫn tới màn theo dõi, nơi trả tiếp được.
      // Mã giảm giá + điểm trừ hết phí ⇒ server đã ghi PAID, bỏ qua bước SePay.
      final message = orderFullyCovered(response)
          ? 'Đơn đã được thanh toán bằng ưu đãi. Đội bay sẽ tiếp nhận đơn của bạn.'
          : await _payCreatedOrder(orderId, response);
      if (!mounted) return;
      widget.onBooked?.call(orderId);
      final notice = loyaltyRedeemSkippedNotice(
        request.pointsToUse ?? 0,
        response,
      );
      _showMessage(notice == null ? message : '$notice $message');
    } catch (error) {
      _showMessage(LockerOpsService.errorMessage(error));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
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
        // Server là nguồn đúng (`amountDue`/`totalPrice`); server cũ không trả
        // số tiền thì dùng tạm tính trên màn.
        total: due > 0 ? due : (_netFee > 0 ? _netFee : _fee).toDouble(),
      );
      return droneOrderPaymentMessage(outcome);
    } catch (error) {
      return 'Đã tạo đơn drone nhưng chưa thanh toán được: '
          '${LockerOpsService.errorMessage(error)}';
    }
  }

  // ------------------------------------------------------------------ UI

  @override
  Widget build(BuildContext context) {
    final suspended = businessConfig.droneFlightsSuspended;
    final fee =
        _quote?.fee ?? businessConfig.droneDeliveryFeeFor(_selectedWeight);
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FB),
      appBar: AppBar(title: const Text('Gửi hàng bằng drone')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          const _Notice(
            icon: Icons.info_outline,
            color: Color(0xFF4F46E5),
            background: Color(0xFFEEF2FF),
            text:
                'Đặt và thanh toán xong, kỹ thuật viên drone gần bạn nhất sẽ tới lấy '
                'kiện, mang tới drone tại tủ bay để nạp trực tiếp lên drone (không bỏ vào ô tủ), '
                'rồi drone bay tới ô nhận bạn đã chọn. Người nhận '
                'lấy hàng bằng mã mở ô gửi qua email.',
          ),
          if (suspended) ...[
            const SizedBox(height: 12),
            const _Notice(
              icon: Icons.cloud_off_outlined,
              color: Color(0xFFB45309),
              background: Color(0xFFFEF3C7),
              text:
                  'Dịch vụ giao drone đang tạm dừng (thời tiết hoặc sự cố vận hành). '
                  'Vui lòng thử lại sau.',
            ),
          ],
          _section('Lấy hàng tại', Icons.home_outlined, [
            _PickupTile(pickup: _pickup, onTap: _choosePickup),
            const SizedBox(height: 10),
            _field(
              'drone-pickup-note',
              _pickupNote,
              'Chỉ dẫn cho kỹ thuật viên (tuỳ chọn)',
              hint: 'Tầng, cổng, giờ có nhà…',
              maxLines: 2,
            ),
          ]),
          _section('Người gửi', Icons.person_outline, [
            _field('drone-sender-name', _senderName, 'Họ tên người gửi *'),
            const SizedBox(height: 10),
            _field(
              'drone-sender-phone',
              _senderPhone,
              'Số điện thoại người gửi *',
              keyboard: TextInputType.phone,
            ),
            const SizedBox(height: 10),
            _field(
              'drone-sender-email',
              _senderEmail,
              'Email người gửi *',
              keyboard: TextInputType.emailAddress,
            ),
          ]),
          _section('Người nhận', Icons.person_pin_circle_outlined, [
            _field('drone-receiver-name', _receiverName, 'Họ tên người nhận *'),
            const SizedBox(height: 10),
            _field(
              'drone-receiver-phone',
              _receiverPhone,
              'Số điện thoại người nhận *',
              keyboard: TextInputType.phone,
            ),
            const SizedBox(height: 10),
            _field(
              'drone-receiver-email',
              _receiverEmail,
              'Email người nhận *',
              keyboard: TextInputType.emailAddress,
            ),
            const SizedBox(height: 6),
            const Text(
              'Khi drone được phóng, người gửi và người nhận đều nhận email báo đơn. '
              'Khi hàng vào tủ, mã mở ô được gửi tới email người nhận.',
              style: TextStyle(fontSize: 12, color: Colors.black54),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<int>(
              key: const ValueKey('drone-destination-locker'),
              initialValue: _destinationLockerId,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Tủ nhận *',
                prefixIcon: Icon(Icons.location_on_outlined),
                border: OutlineInputBorder(),
                filled: true,
                fillColor: Colors.white,
              ),
              hint: Text(
                _loadingDestinations
                    ? 'Đang tải tủ nhận...'
                    : _destinations.isEmpty
                    ? 'Chưa có tủ nào có bãi đáp drone'
                    : 'Chọn tủ có bãi đáp drone',
              ),
              items: [
                for (final locker in _destinations)
                  DropdownMenuItem<int>(
                    value: _asInt(locker['id']),
                    enabled:
                        _canReceiveDrone(locker) &&
                        (_availableDroneSlots[_asInt(locker['id'])] ?? 0) > 0,
                    child: Text(
                      '${locker['name'] ?? locker['code'] ?? 'Tủ #${locker['id']}'} · '
                      '${_destinationUnavailableReason(locker)}',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
              onChanged: _loadingDestinations
                  ? null
                  : (value) {
                      setState(() {
                        _destinationLockerId = value;
                        _destinationBoxId = null;
                      });
                      _refreshQuote();
                    },
            ),
            if (_destinationLockerId != null) ...[
              const SizedBox(height: 10),
              DropdownButtonFormField<int>(
                key: const ValueKey('drone-destination-box'),
                initialValue: _destinationBoxId,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Ô drone nhận *',
                  prefixIcon: Icon(Icons.grid_view_rounded),
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.white,
                ),
                hint: Text(
                  (_availableDroneBoxes[_destinationLockerId] ?? const [])
                          .isEmpty
                      ? 'Không còn ô drone nhận trống'
                      : 'Chọn ô người nhận sẽ lấy hàng',
                ),
                items: [
                  for (final box
                      in _availableDroneBoxes[_destinationLockerId] ?? const [])
                    if (_asInt(box['id']) != null)
                      DropdownMenuItem<int>(
                        value: _asInt(box['id']),
                        child: Text('Ô số ${box['boxNumber'] ?? box['id']}'),
                      ),
                ],
                onChanged: (value) => setState(() => _destinationBoxId = value),
              ),
            ],
            if (_destinationLockerId != null) ...[
              const SizedBox(height: 6),
              Text(
                'Ô nhận drone còn trống: ${_availableDroneSlots[_destinationLockerId] ?? 'đang kiểm tra'}',
                key: const ValueKey('drone-destination-availability'),
                style: const TextStyle(fontSize: 12, color: Color(0xFF15803D)),
              ),
            ],
          ]),
          _section('Kiện hàng', Icons.inventory_2_outlined, [
            Text(
              'Khối lượng * (tối đa '
              '${droneWeightShortLabel(businessConfig.droneMaxPayloadWeightGrams)} một đơn)',
              style: const TextStyle(fontWeight: FontWeight.w700),
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
                    onSelected: (_) {
                      setState(() => _weightGrams = grams);
                      _refreshQuote();
                    },
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Chọn mức bằng hoặc lớn hơn khối lượng thật. Kỹ thuật viên cân lại khi '
              'nạp hàng: nặng hơn mức đã chọn quá '
              '${businessConfig.droneWeightToleranceGrams} g thì bạn trả thêm phần '
              'phí chênh trước khi drone bay; nhẹ hơn không hoàn lại.',
              style: const TextStyle(fontSize: 12, color: Colors.black54),
            ),
            const SizedBox(height: 12),
            const Text(
              'Loại hàng *',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
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
            _field(
              'drone-description',
              _description,
              'Mô tả hàng hoá (tuỳ chọn)',
              maxLines: 2,
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _field(
                    'drone-parcel-length',
                    _length,
                    'Dài',
                    suffix: 'cm',
                    keyboard: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _field(
                    'drone-parcel-width',
                    _width,
                    'Rộng',
                    suffix: 'cm',
                    keyboard: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _field(
                    'drone-parcel-height',
                    _height,
                    'Cao',
                    suffix: 'cm',
                    keyboard: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Kích thước tuỳ chọn. Khoang drone tối đa '
              '${businessConfig.droneMaxParcelSizeCm.join(' × ')} cm.',
              style: const TextStyle(fontSize: 12, color: Colors.black54),
            ),
            const SizedBox(height: 10),
            _field(
              'drone-parcel-value',
              _value,
              'Giá trị khai báo (tuỳ chọn)',
              suffix: 'đ',
              keyboard: TextInputType.number,
            ),
            const SizedBox(height: 6),
            Text(
              'Căn cứ bồi thường nếu kiện hư hỏng, thất lạc. Tối đa '
              '${fmtPrice(businessConfig.droneMaxDeclaredValue)}.',
              style: const TextStyle(fontSize: 12, color: Colors.black54),
            ),
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
          ]),
          _section('Lộ trình và phí', Icons.route_outlined, [
            _QuotePanel(
              quote: _quote,
              quoting: _quoting,
              problem: _quoteProblem,
              ready: _pickup != null && _destinationLockerId != null,
              fee: fee,
            ),
            const SizedBox(height: 8),
            Text(
              dronePickupPolicyText(businessConfig),
              style: const TextStyle(fontSize: 12, color: Colors.black54),
            ),
            if (businessConfig.droneUnpaidCancelMinutes > 0) ...[
              const SizedBox(height: 4),
              Text(
                'Đơn chưa thanh toán sau ${businessConfig.droneUnpaidCancelMinutes} '
                'phút sẽ tự huỷ.',
                style: const TextStyle(fontSize: 12, color: Colors.black54),
              ),
            ],
          ]),
          // Mã giảm giá kiểm theo tủ gửi ⇒ chỉ mở khi đã biết drone cất cánh ở đâu.
          if (_quote != null) _offersSection(_quote!),
          const SizedBox(height: 8),
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
                      'lỏng, chất dễ cháy nổ, hàng cấm theo pháp luật. *',
                      style: TextStyle(fontSize: 12.5),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            key: const ValueKey('drone-submit'),
            onPressed:
                _submitting ||
                    suspended ||
                    _quoteProblem != null ||
                    _quote?.weatherSafe == false
                ? null
                : _submit,
            style: FilledButton.styleFrom(
              backgroundColor: opsPrimary,
              padding: const EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            icon: _submitting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.send_rounded, size: 18),
            label: Text(
              _netFee > 0
                  ? 'Tạo đơn và thanh toán ${fmtPrice(_netFee)}'
                  : 'Tạo đơn (ưu đãi đã trừ hết phí)',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
          ),
        ],
      ),
    );
  }

  /// Mã giảm giá (theo tủ gửi) + điểm thưởng + tạm tính sau giảm.
  Widget _offersSection(DroneQuote quote) {
    final fee = _fee;
    return _section('Ưu đãi', Icons.local_offer_outlined, [
      if (businessConfig.maxVouchersPerOrder > 0) ...[
        PromoCodeField(
          // Đổi tủ gửi ⇒ ô mã làm lại từ đầu (mã cũ kiểm theo tủ cũ).
          key: ValueKey('drone-promo-${quote.sourceLockerId}'),
          orderTotal: fee,
          lockerId: quote.sourceLockerId,
          service: widget.service,
          onChanged: (discount, code) => setState(() {
            _discount = discount;
            _promoCode = code;
          }),
        ),
        const SizedBox(height: 6),
        Text(
          'Mã riêng của tủ chỉ dùng được khi drone cất cánh tại '
          '${quote.sourceLockerName}.',
          style: const TextStyle(fontSize: 12, color: Colors.black54),
        ),
        const SizedBox(height: 12),
      ],
      LoyaltyRedeemToggle(
        orderTotal: _feeAfterVoucher,
        service: widget.service,
        onChanged: (points, discount) => setState(() {
          _pointsToUse = points;
          _pointsDiscount = discount;
        }),
      ),
      if (_discount > 0 || _pointsDiscount > 0) ...[
        const SizedBox(height: 10),
        OpsInfoRow(
          icon: Icons.flight_takeoff,
          label: 'Phí giao drone',
          value: fmtPrice(fee),
        ),
        if (_discount > 0)
          OpsInfoRow(
            icon: Icons.local_offer_outlined,
            label: 'Mã giảm giá',
            value: _promoCode == null
                ? '-${fmtPrice(_discount)}'
                : '-${fmtPrice(_discount)} ($_promoCode)',
            valueColor: const Color(0xFF15803D),
          ),
        if (_pointsDiscount > 0)
          OpsInfoRow(
            icon: Icons.auto_awesome_outlined,
            label: 'Điểm thưởng',
            value: loyaltyPointsDiscountText(_pointsToUse, _pointsDiscount),
            valueColor: const Color(0xFF15803D),
          ),
        OpsInfoRow(
          key: const ValueKey('drone-net-fee'),
          icon: Icons.payments_outlined,
          label: 'Tạm tính',
          value: fmtPrice(_netFee),
          valueColor: opsDark,
        ),
      ],
    ]);
  }

  Widget _section(String title, IconData icon, List<Widget> children) =>
      Padding(
        padding: const EdgeInsets.only(top: 14),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, size: 18, color: opsPrimary),
                  const SizedBox(width: 8),
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ...children,
            ],
          ),
        ),
      );

  Widget _field(
    String key,
    TextEditingController controller,
    String label, {
    String? hint,
    String? suffix,
    TextInputType? keyboard,
    int maxLines = 1,
  }) => TextField(
    key: ValueKey(key),
    controller: controller,
    keyboardType: keyboard,
    maxLines: maxLines,
    decoration: InputDecoration(
      labelText: label,
      hintText: hint,
      suffixText: suffix,
      isDense: true,
      border: const OutlineInputBorder(),
    ),
  );
}

class _Notice extends StatelessWidget {
  const _Notice({
    required this.icon,
    required this.color,
    required this.background,
    required this.text,
  });

  final IconData icon;
  final Color color;
  final Color background;
  final String text;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: background,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(fontSize: 12.5, color: color, height: 1.35),
          ),
        ),
      ],
    ),
  );
}

/// Điểm lấy hàng đã chọn (hoặc lời mời chọn) — chạm để mở bản đồ.
class _PickupTile extends StatelessWidget {
  const _PickupTile({required this.pickup, required this.onTap});

  final PickupLocation? pickup;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final pickup = this.pickup;
    return InkWell(
      key: const ValueKey('drone-pickup-location'),
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: pickup == null ? const Color(0xFFDC2626) : opsPrimary,
          ),
        ),
        child: Row(
          children: [
            Icon(
              pickup == null
                  ? Icons.add_location_alt_outlined
                  : Icons.location_on,
              color: pickup == null ? const Color(0xFFDC2626) : opsPrimary,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: pickup == null
                  ? const Text(
                      'Chọn điểm lấy hàng * — dùng vị trí hiện tại hoặc tự nhập/ghim '
                      'trên bản đồ',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          pickup.address,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Vĩ độ ${pickup.latitude.toStringAsFixed(5)} · '
                          'kinh độ ${pickup.longitude.toStringAsFixed(5)} · chạm để đổi',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ),
            ),
            const Icon(Icons.chevron_right, color: Colors.black38),
          ],
        ),
      ),
    );
  }
}

/// Tủ gửi hệ thống chọn, quãng đường và phí — hoặc lý do chưa phục vụ được điểm này.
class _QuotePanel extends StatelessWidget {
  const _QuotePanel({
    required this.quote,
    required this.quoting,
    required this.problem,
    required this.ready,
    required this.fee,
  });

  final DroneQuote? quote;
  final bool quoting;
  final String? problem;
  final bool ready;
  final num fee;

  @override
  Widget build(BuildContext context) {
    final quote = this.quote;
    if (problem != null) {
      return Text(
        problem!,
        key: const ValueKey('drone-quote-problem'),
        style: const TextStyle(
          color: Color(0xFFDC2626),
          fontWeight: FontWeight.w600,
        ),
      );
    }
    if (!ready) {
      return const Text(
        'Chọn điểm lấy hàng và tủ nhận để xem tủ gửi, quãng đường và phí.',
        style: TextStyle(color: Colors.black54),
      );
    }
    if (quote == null) {
      return Row(
        children: [
          if (quoting)
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          const SizedBox(width: 8),
          const Text('Đang tính lộ trình…'),
        ],
      );
    }
    return Column(
      key: const ValueKey('drone-quote'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tủ bay do hệ thống chọn: ${quote.sourceLockerName}',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        if (quote.sourceLockerAddress != null)
          Text(
            quote.sourceLockerAddress!,
            style: const TextStyle(fontSize: 12, color: Colors.black54),
          ),
        const SizedBox(height: 6),
        Text(
          'Kỹ thuật viên mang kiện ${droneDistanceLabel(quote.pickupDistanceMeters)} '
          'tới drone ở tủ bay để nạp trực tiếp · drone bay '
          '${droneDistanceLabel(quote.routeDistanceMeters)} tới ô nhận tại tủ đích',
          style: const TextStyle(fontSize: 12.5),
        ),
        const SizedBox(height: 6),
        Text(
          'Phí giao drone: ${fmtPrice(fee)}',
          style: const TextStyle(
            color: Color(0xFF15803D),
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: quote.weatherSafe
                ? const Color(0xFFECFDF5)
                : const Color(0xFFFFF1F2),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: quote.weatherSafe
                  ? const Color(0xFF86EFAC)
                  : const Color(0xFFFDA4AF),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    quote.weatherSafe
                        ? Icons.wb_sunny_outlined
                        : Icons.thunderstorm_outlined,
                    size: 18,
                    color: quote.weatherSafe
                        ? const Color(0xFF15803D)
                        : const Color(0xFFBE123C),
                  ),
                  const SizedBox(width: 7),
                  Expanded(
                    child: Text(
                      quote.weatherSafe
                          ? 'Thời tiết tuyến bay: Đủ điều kiện'
                          : quote.weatherStatus == 'UNAVAILABLE'
                          ? 'Chưa xác nhận được thời tiết'
                          : 'Thời tiết tuyến bay: Tạm ngưng bay',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: quote.weatherSafe
                            ? const Color(0xFF166534)
                            : const Color(0xFF9F1239),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '${quote.weatherMessage} • Dự báo 30 phút dọc tuyến; '
                'gió tối đa ${quote.weatherMaxWindKmh.toStringAsFixed(0)} km/h, '
                'gió giật ${quote.weatherMaxGustKmh.toStringAsFixed(0)} km/h, '
                'mưa ${quote.weatherMaxPrecipitationMm.toStringAsFixed(1)} mm.',
                style: const TextStyle(fontSize: 12),
              ),
              if (quote.weatherCheckedAt != null)
                Text(
                  'Cập nhật ${MaterialLocalizations.of(context).formatTimeOfDay(TimeOfDay.fromDateTime(quote.weatherCheckedAt!.toLocal()))}',
                  style: const TextStyle(fontSize: 11, color: Colors.black54),
                ),
              const Text(
                'Nguồn dự báo: Open-Meteo (đã lấy mẫu dọc tuyến và áp ngưỡng bay Lock.R).',
                style: TextStyle(fontSize: 10, color: Colors.black54),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
