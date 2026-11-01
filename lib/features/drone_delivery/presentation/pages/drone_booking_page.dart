import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_laundry_locker/core/config/business_config_provider.dart';
import 'package:smart_laundry_locker/core/services/app_event_bus.dart';
import 'package:smart_laundry_locker/features/drone_delivery/domain/entities/drone_booking.dart';
import 'package:smart_laundry_locker/features/drone_delivery/domain/entities/drone_labels.dart';
import 'package:smart_laundry_locker/features/drone_delivery/domain/entities/drone_locker_availability.dart';
import 'package:smart_laundry_locker/features/drone_delivery/domain/entities/drone_route_geometry.dart';
import 'package:smart_laundry_locker/features/drone_delivery/domain/entities/drone_parcel.dart';
import 'package:smart_laundry_locker/features/drone_delivery/infrastructure/services/locker_availability_socket_service.dart';
import 'package:smart_laundry_locker/features/drone_delivery/presentation/pages/pickup_location_picker_page.dart';
import 'package:smart_laundry_locker/features/drone_delivery/presentation/widgets/drone_order_payment.dart';
import 'package:smart_laundry_locker/features/locker_ops/data/locker_ops_service.dart';
import 'package:smart_laundry_locker/features/locker_ops/presentation/utils/business_rules_text.dart';
import 'package:smart_laundry_locker/features/locker_ops/presentation/widgets/loyalty_redeem_toggle.dart';
import 'package:smart_laundry_locker/features/locker_ops/presentation/widgets/ops_widgets.dart';
import 'package:smart_laundry_locker/features/locker_ops/presentation/widgets/order_extras.dart';
import 'package:smart_laundry_locker/features/profile/presentation/providers/profile_provider.dart';
import 'package:smart_laundry_locker/core/l10n/l10n.dart';

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
    this.availabilityChanges,
    this.slotRefreshInterval = const Duration(seconds: 20),
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

  /// Mã tủ vừa đổi số ô trống (realtime). Null: nghe socket thật, trừ khi màn được dựng với
  /// danh sách tủ có sẵn (test) — khi đó không nghe gì.
  final Stream<int>? availabilityChanges;

  /// Dự phòng khi socket rớt: tự tải lại ô trống theo chu kỳ này.
  final Duration slotRefreshInterval;

  @override
  State<DroneBookingPage> createState() => _DroneBookingPageState();
}

class _DroneBookingPageState extends State<DroneBookingPage>
    with BusinessConfigStateMixin {
  // Số Việt Nam: 0 hoặc +84/84 rồi 9 chữ số (chữ số đầu khác 0) — khớp
  // CreateDroneDeliveryOrderRequest.PHONE ở order-service.
  static final _phonePattern = RegExp(r'^(?:0|\+?84)[1-9][0-9]{8}$');
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
  double? _customerLat;
  double? _customerLng;
  List<Map<String, dynamic>> _destinations = const [];
  final Map<int, int?> _availableDroneSlots = {};
  final Map<int, List<Map<String, dynamic>>> _availableDroneBoxes = {};
  bool _loadingDestinations = true;
  int? _destinationLockerId;
  int? _destinationBoxId;
  StreamSubscription<int>? _availabilitySub;
  StreamSubscription<AppEvent>? _catalogSub;
  Timer? _slotPoll;
  Timer? _slotDebounce;
  final Set<int> _pendingSlotRefresh = {};
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
    _loadCustomerPosition();
    _loadDestinations();
    _watchAvailability();
  }

  /// Ô trống đổi liên tục (người khác đặt, đơn lấy xong, huỷ…): nghe realtime theo tủ, kèm
  /// tải lại định kỳ phòng khi socket rớt.
  void _watchAvailability() {
    final changes =
        widget.availabilityChanges ??
        (widget.destinationLockers == null
            ? LockerAvailabilitySocketService.instance.watch()
            : null);
    _availabilitySub = changes?.listen(_onLockerAvailabilityChanged);
    if (widget.destinationLockers == null) {
      _catalogSub = AppEventBus.instance.events.listen((event) {
        if (mounted && event is CatalogChangedEvent && event.isLocker) {
          _loadDestinations();
        }
      });
    }
    _slotPoll = Timer.periodic(widget.slotRefreshInterval, (_) {
      // Socket thật đang nối thì báo đổi realtime đã đủ; chỉ tải định kỳ khi socket rớt.
      if (widget.availabilityChanges == null &&
          widget.destinationLockers == null &&
          LockerAvailabilitySocketService.instance.connected) {
        return;
      }
      _refreshDroneSlots();
    });
  }

  /// Gom các báo đổi dồn dập (một đơn đổi nhiều ô) rồi mới tải lại.
  void _onLockerAvailabilityChanged(int lockerId) {
    if (!_destinations.any((locker) => _asInt(locker['id']) == lockerId)) {
      return;
    }
    _pendingSlotRefresh.add(lockerId);
    _slotDebounce?.cancel();
    _slotDebounce = Timer(const Duration(milliseconds: 300), () {
      final ids = Set<int>.of(_pendingSlotRefresh);
      _pendingSlotRefresh.clear();
      _refreshDroneSlots(only: ids);
    });
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

  Future<void> _loadCustomerPosition() async {
    if (widget.destinationLockers != null) return;
    try {
      final (pos, _) = await readDevicePosition();
      if (!mounted || pos == null) return;
      setState(() {
        _customerLat = pos.latitude;
        _customerLng = pos.longitude;
        _destinations = sortLockersByCustomerDistance(
          _destinations,
          customerLatitude: _pickup?.latitude ?? _customerLat,
          customerLongitude: _pickup?.longitude ?? _customerLng,
        );
      });
    } catch (_) {}
  }

  Future<void> _loadDestinations() async {
    try {
      final all = widget.destinationLockers ?? await _ops.lockers();
      // Keep every locker returned by the system visible. Ineligible lockers
      // are rendered disabled below with the reason, instead of disappearing
      // from the customer's destination list.
      final destinations = sortLockersByCustomerDistance(
        all.where((locker) => _asInt(locker['id']) != null),
        customerLatitude: _pickup?.latitude ?? _customerLat,
        customerLongitude: _pickup?.longitude ?? _customerLng,
      );
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
      await _refreshDroneSlots();
      _refreshQuote();
    } catch (_) {
      if (mounted) setState(() => _destinations = const []);
    } finally {
      if (mounted) setState(() => _loadingDestinations = false);
    }
  }

  /// Tải lại ô DRONE trống của các tủ nhận được drone (hoặc chỉ [only]). Ô đang chọn vừa bị
  /// người khác giữ thì bỏ chọn và báo ngay, không để tới lúc bấm đặt mới biết.
  Future<void> _refreshDroneSlots({Set<int>? only}) async {
    final targetLockers = _destinations.where(
      (locker) => widget.loadDroneSlots != null
          ? _canReceiveDrone(locker)
          : locker['landingPad'] == true,
    );
    await Future.wait(
      targetLockers.map((locker) async {
        final id = _asInt(locker['id']);
        if (id == null || (only != null && !only.contains(id))) return;
        try {
          Map<String, dynamic>? fetchedLayout;
          final List<Map<String, dynamic>> boxes;
          if (widget.loadDroneSlots != null) {
            boxes = await widget.loadDroneSlots!(id);
          } else {
            fetchedLayout = await _ops.layout(id);
            boxes = _extractAvailableDroneBoxes(fetchedLayout);
          }
          if (!mounted) return;
          final lostBox =
              id == _destinationLockerId &&
                  _destinationBoxId != null &&
                  boxes.every((box) => _asInt(box['id']) != _destinationBoxId)
              ? _destinationBoxId
              : null;
          // Lần tải đầu (chưa từng thấy ô) chỉ bỏ chọn lặng lẽ; các lần sau mới là "vừa mất".
          final lostLabel =
              lostBox == null || !_availableDroneBoxes.containsKey(id)
              ? null
              : _boxLabel(id, lostBox);
          setState(() {
            if (fetchedLayout != null) {
              _destinations = [
                for (final item in _destinations)
                  if (_asInt(item['id']) == id)
                    {
                      ...item,
                      if (fetchedLayout['status'] != null)
                        'status': fetchedLayout['status'],
                      if (fetchedLayout['landingPad'] != null)
                        'landingPad': fetchedLayout['landingPad'],
                      if (fetchedLayout['landingPadStatus'] != null)
                        'landingPadStatus': fetchedLayout['landingPadStatus'],
                      if (fetchedLayout.containsKey('online'))
                        'online': fetchedLayout['online'],
                    }
                  else
                    item,
              ];
            }
            _availableDroneBoxes[id] = boxes;
            _availableDroneSlots[id] = boxes.length;
            if (lostBox != null) _destinationBoxId = null;
          });
          if (lostLabel != null) {
            _showMessage(
              context.l10n.dbBoxTaken(lostLabel),
            );
          }
        } catch (_) {
          if (mounted && !_availableDroneSlots.containsKey(id)) {
            setState(() => _availableDroneSlots[id] = null);
          }
        }
      }),
    );
  }

  /// Ô trước khi tải lại — để báo đúng số ô vừa mất.
  String _boxLabel(int lockerId, int boxId) {
    for (final box in _availableDroneBoxes[lockerId] ?? const []) {
      if (_asInt(box['id']) == boxId) {
        return context.l10n.boxNumberLabel(box['boxNumber'] ?? boxId);
      }
    }
    return context.l10n.dbYourBox;
  }

  static List<Map<String, dynamic>> _extractAvailableDroneBoxes(
    Map<String, dynamic> layout,
  ) {
    final cells = layout['cells'];
    return cells is List
        ? cells
              .whereType<Map>()
              .where(
                (cell) =>
                    cell['active'] != false &&
                    '${cell['cellType']}'.toUpperCase() == 'DRONE' &&
                    '${cell['status']}'.toUpperCase() == 'AVAILABLE',
              )
              .map((cell) => Map<String, dynamic>.from(cell))
              .toList(growable: false)
        : <Map<String, dynamic>>[];
  }

  static int? _asInt(dynamic value) =>
      value is num ? value.toInt() : int.tryParse('$value');

  static bool _canReceiveDrone(Map<String, dynamic> locker) {
    if (locker['online'] == false ||
        locker['landingPad'] != true ||
        '${locker['status']}'.toUpperCase() != 'ACTIVE' ||
        !_hasCoordinates(locker)) {
      return false;
    }
    final padStatus = locker['landingPadStatus'];
    if (padStatus == null) return true;
    final normalized = '$padStatus'.trim().toUpperCase();
    return normalized.isEmpty || normalized == 'OK';
  }

  /// Drone bay tới toạ độ tủ: tủ chưa nhập vị trí thì server từ chối báo giá, khoá luôn ở đây.
  static bool _hasCoordinates(Map<String, dynamic> locker) =>
      locker['latitude'] is num && locker['longitude'] is num;

  Map<String, dynamic>? get _selectedDestination {
    final id = _destinationLockerId;
    if (id == null) return null;
    for (final locker in _destinations) {
      if (_asInt(locker['id']) == id) return locker;
    }
    return null;
  }

  /// Gợi ý ô nhận: đang tải / tủ không nhận drone (kèm lý do) / hết ô / chọn ô.
  String _destinationBoxHint() {
    final locker = _selectedDestination;
    if (locker != null && !_canReceiveDrone(locker)) {
      return _destinationUnavailableReason(locker);
    }
    final slots = _availableDroneSlots[_destinationLockerId];
    if (slots == null) return context.l10n.dbCheckingBoxes;
    if (slots == 0) return context.l10n.dbNoFreeBoxes;
    return context.l10n.dbChooseBox;
  }

  String _destinationUnavailableReason(Map<String, dynamic> locker) {
    final distKm = lockerDistanceKmFrom(
      locker,
      _pickup?.latitude ?? _customerLat,
      _pickup?.longitude ?? _customerLng,
    );
    final distPrefix =
        distKm != null ? context.l10n.dbDistancePrefix(droneKmLabel(distKm)) : '';
    if (locker['online'] == false) {
      return '$distPrefix${context.l10n.commonDisconnected}';
    }
    final status = '${locker['status']}'.toUpperCase();
    if (status != 'ACTIVE') {
      return '$distPrefix${status == 'MAINTENANCE' ? 'Đang bảo trì' : 'Chưa hoạt động'}';
    }
    if (locker['landingPad'] != true) {
      return '$distPrefix${context.l10n.dbNoPad}';
    }
    final padStatus = '${locker['landingPadStatus'] ?? 'OK'}'.trim().toUpperCase();
    if (padStatus.isNotEmpty && padStatus != 'OK') {
      return '$distPrefix${padStatus == 'MAINTENANCE' ? 'Bãi đáp đang bảo trì' : 'Bãi đáp đang lỗi'}';
    }
    if (!_hasCoordinates(locker)) return context.l10n.dbNoCoordinates;
    final slots = _availableDroneSlots[_asInt(locker['id'])];
    if (slots == null) return '$distPrefix${context.l10n.dbCheckingBoxesShort}';
    if (slots == 0) return '$distPrefix${context.l10n.dbOutOfBoxes}';
    return '$distPrefix${context.l10n.dbFreeBoxes(slots)}';
  }

  @override
  void dispose() {
    _availabilitySub?.cancel();
    _catalogSub?.cancel();
    _slotPoll?.cancel();
    _slotDebounce?.cancel();
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
    setState(() {
      _pickup = picked;
      _destinations = sortLockersByCustomerDistance(
        _destinations,
        customerLatitude: picked.latitude,
        customerLongitude: picked.longitude,
      );
    });
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
      _showMessage(context.l10n.dbEnterName(who));
      return null;
    }
    if (!_phonePattern.hasMatch(cleanPhone)) {
      _showMessage(context.l10n.dbInvalidPhone(who));
      return null;
    }
    if (!_emailPattern.hasMatch(cleanEmail)) {
      _showMessage(context.l10n.dbInvalidEmail(who));
      return null;
    }
    return DroneContact(name: cleanName, phone: cleanPhone, email: cleanEmail);
  }

  /// Đọc và kiểm toàn bộ form theo đúng các quy tắc server áp (`DroneOrderBookingService`).
  DroneBookingRequest? _readRequest() {
    final pickup = _pickup;
    if (pickup == null) {
      _showMessage(context.l10n.dbChoosePickup);
      return null;
    }
    final sender = _readContact(
      context.l10n.dbWhoSender,
      _senderName,
      _senderPhone,
      _senderEmail,
    );
    if (sender == null) return null;
    final receiver = _readContact(
      context.l10n.dbWhoReceiver,
      _receiverName,
      _receiverPhone,
      _receiverEmail,
    );
    if (receiver == null) return null;
    final destination = _destinationLockerId;
    if (destination == null) {
      _showMessage(context.l10n.dbChooseReceiverLocker);
      return null;
    }
    final availableDroneSlots = _availableDroneSlots[destination];
    if (availableDroneSlots == null) {
      _showMessage(
        context.l10n.dbCheckingReceiverBoxes,
      );
      return null;
    }
    if (availableDroneSlots == 0) {
      _showMessage(context.l10n.dbReceiverFull);
      return null;
    }
    final destinationBox = _destinationBoxId;
    if (destinationBox == null ||
        !(_availableDroneBoxes[destination]?.any(
              (box) => _asInt(box['id']) == destinationBox,
            ) ??
            false)) {
      _showMessage(context.l10n.dbChooseReceiverBox);
      return null;
    }
    final category = _category;
    if (category == null) {
      _showMessage(context.l10n.dbChooseCategory);
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
          context.l10n.dbSizeAllOrNone,
        );
        return null;
      }
      size = parsed.cast<int>();
      final bay = businessConfig.droneMaxParcelSizeCm;
      if (!droneParcelFits(size, bay)) {
        _showMessage(
          context.l10n.dbTooLarge(bay[0], bay[1], bay[2]),
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
          context.l10n.dbMaxValue(fmtPrice(businessConfig.droneMaxDeclaredValue)),
        );
        return null;
      }
    }
    if (!_declared) {
      _showMessage(context.l10n.dbConfirmNoProhibited);
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
          ? context.l10n.dbPaidByVoucher
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
      return L10n.current.dbCreatedNotPaid(LockerOpsService.errorMessage(error));
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
      appBar: AppBar(title: Text(context.l10n.dbTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          _Notice(
            icon: Icons.info_outline,
            color: Color(0xFF4F46E5),
            background: Color(0xFFEEF2FF),
            text:
                context.l10n.dbIntro,
          ),
          if (suspended) ...[
            const SizedBox(height: 12),
            _Notice(
              icon: Icons.cloud_off_outlined,
              color: Color(0xFFB45309),
              background: Color(0xFFFEF3C7),
              text:
                  context.l10n.dbSuspended,
            ),
          ],
          _section(context.l10n.dbPickupAt, Icons.home_outlined, [
            _PickupTile(pickup: _pickup, onTap: _choosePickup),
            const SizedBox(height: 10),
            _field(
              'drone-pickup-note',
              _pickupNote,
              context.l10n.dbTechInstructions,
              hint: context.l10n.dbTechInstructionsHint,
              maxLines: 2,
            ),
          ]),
          _section(context.l10n.recvSender, Icons.person_outline, [
            _field('drone-sender-name', _senderName, context.l10n.dbSenderName),
            const SizedBox(height: 10),
            _field(
              'drone-sender-phone',
              _senderPhone,
              context.l10n.dbSenderPhone,
              keyboard: TextInputType.phone,
            ),
            const SizedBox(height: 10),
            _field(
              'drone-sender-email',
              _senderEmail,
              context.l10n.dbSenderEmail,
              keyboard: TextInputType.emailAddress,
            ),
          ]),
          _section(context.l10n.ordRecipient, Icons.person_pin_circle_outlined, [
            _field('drone-receiver-name', _receiverName, context.l10n.dbReceiverName),
            const SizedBox(height: 10),
            _field(
              'drone-receiver-phone',
              _receiverPhone,
              context.l10n.dbReceiverPhone,
              keyboard: TextInputType.phone,
            ),
            const SizedBox(height: 10),
            _field(
              'drone-receiver-email',
              _receiverEmail,
              context.l10n.dbReceiverEmail,
              keyboard: TextInputType.emailAddress,
            ),
            const SizedBox(height: 6),
            Text(
              context.l10n.dbEmailInfo,
              style: TextStyle(fontSize: 12, color: Colors.black54),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<int>(
              key: const ValueKey('drone-destination-locker'),
              initialValue: _destinationLockerId,
              isExpanded: true,
              decoration: InputDecoration(
                labelText: context.l10n.dbReceiverLockerField,
                prefixIcon: Icon(Icons.location_on_outlined),
                border: OutlineInputBorder(),
                filled: true,
                fillColor: Colors.white,
              ),
              hint: Text(
                _loadingDestinations
                    ? context.l10n.dbLoadingLockers
                    : _destinations.isEmpty
                    ? context.l10n.dbNoLockersInSystem
                    : context.l10n.dbChooseReceiverLocker,
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
                decoration: InputDecoration(
                  labelText: context.l10n.dbReceiverBoxField,
                  prefixIcon: Icon(Icons.grid_view_rounded),
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.white,
                ),
                hint: Text(_destinationBoxHint()),
                items: [
                  for (final box
                      in _availableDroneBoxes[_destinationLockerId] ?? const [])
                    if (_asInt(box['id']) != null)
                      DropdownMenuItem<int>(
                        value: _asInt(box['id']),
                        child: Text(context.l10n.boxNumberLabel(box['boxNumber'] ?? box['id'])),
                      ),
                ],
                onChanged: (value) => setState(() => _destinationBoxId = value),
              ),
            ],
            if (_selectedDestination case final locker?) ...[
              const SizedBox(height: 6),
              Text(
                _canReceiveDrone(locker)
                    ? context.l10n.dbFreeReceiverBoxes(
                          _availableDroneSlots[_destinationLockerId] ??
                              context.l10n.dbChecking,
                        )
                      : context.l10n.dbLockerCantReceive(
                          _destinationUnavailableReason(locker).toLowerCase(),
                        ),
                key: const ValueKey('drone-destination-availability'),
                style: TextStyle(
                  fontSize: 12,
                  color:
                      _canReceiveDrone(locker) &&
                          (_availableDroneSlots[_destinationLockerId] ?? 1) > 0
                      ? const Color(0xFF15803D)
                      : const Color(0xFFDC2626),
                ),
              ),
            ],
          ]),
          _section(context.l10n.ordParcel, Icons.inventory_2_outlined, [
            Text(
              context.l10n.dbWeightField(
                droneWeightShortLabel(businessConfig.droneMaxPayloadWeightGrams),
              ),
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
              context.l10n.dbWeightHint(businessConfig.droneWeightToleranceGrams),
              style: const TextStyle(fontSize: 12, color: Colors.black54),
            ),
            const SizedBox(height: 12),
            Text(
              context.l10n.dbCategoryField,
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
              context.l10n.dbDescriptionField,
              maxLines: 2,
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _field(
                    'drone-parcel-length',
                    _length,
                    context.l10n.dbLength,
                    suffix: 'cm',
                    keyboard: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _field(
                    'drone-parcel-width',
                    _width,
                    context.l10n.dbWidth,
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
              context.l10n.dbSizeHint(businessConfig.droneMaxParcelSizeCm.join(' × ')),
              style: const TextStyle(fontSize: 12, color: Colors.black54),
            ),
            const SizedBox(height: 10),
            _field(
              'drone-parcel-value',
              _value,
              context.l10n.dbDeclaredValueField,
              suffix: 'đ',
              keyboard: TextInputType.number,
            ),
            const SizedBox(height: 6),
            Text(
              context.l10n.dbDeclaredValueHint(fmtPrice(businessConfig.droneMaxDeclaredValue)),
              style: const TextStyle(fontSize: 12, color: Colors.black54),
            ),
            Row(
              children: [
                Expanded(child: Text(context.l10n.parcelFragile)),
                Switch(
                  key: const ValueKey('drone-parcel-fragile'),
                  value: _fragile,
                  onChanged: (value) => setState(() => _fragile = value),
                ),
              ],
            ),
          ]),
          _section(context.l10n.dbRouteAndFee, Icons.route_outlined, [
            _QuotePanel(
              quote: _quote,
              quoting: _quoting,
              problem: _quoteProblem,
              ready: _pickup != null && _destinationLockerId != null,
              fee: fee,
              onRefresh: _quoting ? null : _refreshQuote,
            ),
            const SizedBox(height: 8),
            Text(
              dronePickupPolicyText(businessConfig),
              style: const TextStyle(fontSize: 12, color: Colors.black54),
            ),
            if (businessConfig.droneUnpaidCancelMinutes > 0) ...[
              const SizedBox(height: 4),
              Text(
                context.l10n.dbAutoCancel(businessConfig.droneUnpaidCancelMinutes),
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
                  child: Padding(
                    padding: EdgeInsets.only(top: 12),
                    child: Text(
                      context.l10n.dbNoProhibitedCheckbox,
                      style: TextStyle(fontSize: 12.5),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      // Nút đặt đơn luôn ở đáy màn: không phải kéo hết form mới thấy.
      bottomNavigationBar: _StickyActionBar(
        child: FilledButton.icon(
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
                ? context.l10n.dbCreateAndPay(fmtPrice(_netFee))
                : context.l10n.dbCreateFree,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
        ),
      ),
    );
  }

  /// Mã giảm giá (theo tủ gửi) + điểm thưởng + tạm tính sau giảm.
  Widget _offersSection(DroneQuote quote) {
    final fee = _fee;
    return _section(context.l10n.commonOffers, Icons.local_offer_outlined, [
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
          context.l10n.dbLockerCodeOnly(quote.sourceLockerName),
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
          label: context.l10n.ddDroneFee,
          value: fmtPrice(fee),
        ),
        if (_discount > 0)
          OpsInfoRow(
            icon: Icons.local_offer_outlined,
            label: context.l10n.commonDiscountCode,
            value: _promoCode == null
                ? '-${fmtPrice(_discount)}'
                : '-${fmtPrice(_discount)} ($_promoCode)',
            valueColor: const Color(0xFF15803D),
          ),
        if (_pointsDiscount > 0)
          OpsInfoRow(
            icon: Icons.auto_awesome_outlined,
            label: context.l10n.commonRewardPoints,
            value: loyaltyPointsDiscountText(_pointsToUse, _pointsDiscount),
            valueColor: const Color(0xFF15803D),
          ),
        OpsInfoRow(
          key: const ValueKey('drone-net-fee'),
          icon: Icons.payments_outlined,
          label: context.l10n.commonSubtotal,
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
                  ? Text(
                      context.l10n.dbChoosePickupHint,
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
                          context.l10n.dbLatLngTap(
                    pickup.latitude.toStringAsFixed(5),
                    pickup.longitude.toStringAsFixed(5),
                  ),
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
    this.onRefresh,
  });

  final DroneQuote? quote;
  final bool quoting;
  final String? problem;
  final bool ready;
  final num fee;

  /// Hỏi lại server (lộ trình, phí, thời tiết) — dự báo 30 phút cũ dần theo thời gian.
  final VoidCallback? onRefresh;

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
      return Text(
        context.l10n.dbQuoteHint,
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
          Text(context.l10n.dbCalculatingRoute),
        ],
      );
    }
    return Column(
      key: const ValueKey('drone-quote'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.l10n.dbSystemStation(quote.sourceLockerName),
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        if (quote.sourceLockerAddress != null)
          Text(
            quote.sourceLockerAddress!,
            style: const TextStyle(fontSize: 12, color: Colors.black54),
          ),
        const SizedBox(height: 6),
        Text(
          context.l10n.dbRouteSummary(
              droneDistanceLabel(quote.pickupDistanceMeters),
              droneDistanceLabel(quote.routeDistanceMeters),
            ),
          style: const TextStyle(fontSize: 12.5),
        ),
        const SizedBox(height: 6),
        Text(
          context.l10n.dbFeeValue(fmtPrice(fee)),
          style: const TextStyle(
            color: Color(0xFF15803D),
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 10),
        _QuoteWeather(quote: quote, onRefresh: onRefresh),
      ],
    );
  }
}

/// Thời tiết 30 phút tới (thời gian giao dự kiến của một đơn) trên cả hành trình: nơi gửi →
/// tủ bay → tủ nhận. Mưa, dông, gió mạnh hoặc chưa có dự báo ⇒ không đặt được (server cũng chặn,
/// và kiểm tra lại lúc phóng drone).
class _QuoteWeather extends StatelessWidget {
  const _QuoteWeather({required this.quote, this.onRefresh});

  final DroneQuote quote;
  final VoidCallback? onRefresh;

  @override
  Widget build(BuildContext context) {
    final safe = quote.weatherSafe;
    final unavailable = quote.weatherStatus == 'UNAVAILABLE';
    final tone = safe
        ? const Color(0xFF166534)
        : unavailable
        ? const Color(0xFF475569)
        : const Color(0xFF9F1239);
    final facts = [
      if (quote.weatherCondition != null) quote.weatherCondition!,
      if (quote.weatherTemperatureC != null)
        '${quote.weatherTemperatureC!.toStringAsFixed(0)}°C',
      if (!unavailable) ...[
        context.l10n.dbWind(quote.weatherMaxWindKmh.toStringAsFixed(0)),
        context.l10n.dbGust(quote.weatherMaxGustKmh.toStringAsFixed(0)),
        context.l10n.dbRain(quote.weatherMaxPrecipitationMm.toStringAsFixed(1)),
      ],
    ];
    final footer = [
      if (quote.weatherCheckedAt != null)
        context.l10n.dbUpdatedAt(MaterialLocalizations.of(context).formatTimeOfDay(TimeOfDay.fromDateTime(quote.weatherCheckedAt!.toLocal()))),
      if (quote.weatherProviderLabel != null)
        context.l10n.dbSource('${quote.weatherProviderLabel}'),
    ];
    return Container(
      key: const ValueKey('drone-quote-weather'),
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 8, 4, 12),
      decoration: BoxDecoration(
        color: safe
            ? const Color(0xFFECFDF5)
            : unavailable
            ? const Color(0xFFF1F5F9)
            : const Color(0xFFFFF1F2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: tone.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                safe
                    ? Icons.wb_sunny_outlined
                    : unavailable
                    ? Icons.cloud_off_outlined
                    : Icons.thunderstorm_outlined,
                size: 18,
                color: tone,
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  safe
                      ? context.l10n.dbWeatherOk
                      : unavailable
                      ? context.l10n.dbWeatherUnknown
                      : context.l10n.dbWeatherSuspended,
                  style: TextStyle(fontWeight: FontWeight.w700, color: tone),
                ),
              ),
              IconButton(
                key: const ValueKey('drone-quote-weather-refresh'),
                tooltip: context.l10n.dbWeatherRefresh,
                visualDensity: VisualDensity.compact,
                onPressed: onRefresh,
                icon: const Icon(Icons.refresh, size: 20),
              ),
            ],
          ),
          Text(
            context.l10n.dbWeatherWindow(quote.weatherWindowMinutes, quote.sourceLockerName),
            style: const TextStyle(fontSize: 12, color: Color(0xFF475569)),
          ),
          if (facts.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                facts.join(' · '),
                style: const TextStyle(fontSize: 12.5),
              ),
            ),
          if (!safe)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                context.l10n.dbWeatherOnlyWhenSafe(quote.weatherMessage),
                style: TextStyle(fontSize: 12, color: tone),
              ),
            ),
          if (footer.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                footer.join(' · '),
                style: const TextStyle(fontSize: 11, color: Colors.black54),
              ),
            ),
        ],
      ),
    );
  }
}

/// Thanh thao tác cố định ở đáy màn (đặt đơn, thanh toán, huỷ…), nằm trên vùng thanh điều hướng
/// của máy và đẩy lên khi bàn phím mở.
class _StickyActionBar extends StatelessWidget {
  const _StickyActionBar({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: DecoratedBox(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
          boxShadow: [
            BoxShadow(
              color: Color(0x14000000),
              blurRadius: 12,
              offset: Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
            child: SizedBox(width: double.infinity, child: child),
          ),
        ),
      ),
    );
  }
}
