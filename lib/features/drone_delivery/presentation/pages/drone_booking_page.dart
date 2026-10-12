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
import 'package:smart_laundry_locker/features/locker_ops/presentation/widgets/ops_widgets.dart';
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

typedef PickupLocationPicker =
    Future<PickupLocation?> Function(
      BuildContext context,
      PickupLocation? current,
    );

Future<PickupLocation?> _pushLocationPicker(
  BuildContext context,
  PickupLocation? current,
) => Navigator.of(context).push<PickupLocation>(
  MaterialPageRoute(
    builder: (_) => PickupLocationPickerPage(initial: current),
  ),
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
    this.createOrder,
    this.payOrder,
    this.pickLocation = _pushLocationPicker,
    this.onBooked,
    this.showMessage,
  });

  /// Tủ khách đang xem khi bấm "giao drone" — chọn sẵn làm tủ nhận.
  final int? initialDestinationLockerId;

  /// Ô DRONE khách đã chạm ở tủ nhận.
  final int? preferredBoxId;

  /// Liên hệ người gửi điền sẵn; null thì lấy từ hồ sơ đang đăng nhập.
  final DroneContact? initialSender;
  final List<Map<String, dynamic>>? destinationLockers;
  final DroneQuoteLoader? loadQuote;
  final DroneOrderCreator? createOrder;
  final DroneOrderPayer? payOrder;
  final PickupLocationPicker pickLocation;
  final ValueChanged<int>? onBooked;
  final ValueChanged<String>? showMessage;

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
  bool _loadingDestinations = true;
  int? _destinationLockerId;
  int? _weightGrams;
  String? _category;
  bool _fragile = false;
  bool _declared = false;
  bool _submitting = false;

  DroneQuote? _quote;
  String? _quoteProblem;
  bool _quoting = false;
  int _quoteRequest = 0;

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
      final all =
          widget.destinationLockers ?? await LockerOpsService().lockers();
      final destinations = all
          .where(
            (locker) =>
                _asInt(locker['id']) != null &&
                locker['landingPad'] == true &&
                '${locker['status']}'.toUpperCase() == 'ACTIVE',
          )
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
      _refreshQuote();
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
            await LockerOpsService().quoteDroneDelivery(
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
        _quote = quote;
        _quoting = false;
      });
    } catch (error) {
      if (!mounted || request != _quoteRequest) return;
      setState(() {
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
    final sender = _readContact('người gửi', _senderName, _senderPhone, _senderEmail);
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
    final category = _category;
    if (category == null) {
      _showMessage('Chọn loại hàng');
      return null;
    }

    final sizeTexts = [_length.text.trim(), _width.text.trim(), _height.text.trim()];
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
      preferredBoxId: destination == widget.initialDestinationLockerId
          ? widget.preferredBoxId
          : null,
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
          (request, key) => LockerOpsService().createDroneDeliveryOrder(
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
      final message = await _payCreatedOrder(orderId, response);
      if (!mounted) return;
      widget.onBooked?.call(orderId);
      _showMessage(message);
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

  // ------------------------------------------------------------------ UI

  @override
  Widget build(BuildContext context) {
    final suspended = businessConfig.droneFlightsSuspended;
    final fee = _quote?.fee ?? businessConfig.droneDeliveryFeeFor(_selectedWeight);
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
                'kiện, mang về tủ gần bạn rồi phóng drone tới tủ nhận. Người nhận '
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
                    child: Text(
                      '${locker['name'] ?? locker['code'] ?? 'Tủ #${locker['id']}'}',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
              onChanged: _loadingDestinations
                  ? null
                  : (value) {
                      setState(() => _destinationLockerId = value);
                      _refreshQuote();
                    },
            ),
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
            const Text('Loại hàng *', style: TextStyle(fontWeight: FontWeight.w700)),
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
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Checkbox(
                key: const ValueKey('drone-prohibited-declaration'),
                value: _declared,
                onChanged: (value) => setState(() => _declared = value ?? false),
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
            onPressed: _submitting || suspended || _quoteProblem != null
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
              'Tạo đơn và thanh toán ${fmtPrice(fee)}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
          ),
        ],
      ),
    );
  }

  Widget _section(String title, IconData icon, List<Widget> children) => Padding(
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
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
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
              pickup == null ? Icons.add_location_alt_outlined : Icons.location_on,
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
          'Drone cất cánh tại ${quote.sourceLockerName}',
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
          'tới tủ gửi · drone bay ${droneDistanceLabel(quote.routeDistanceMeters)} '
          'tới tủ nhận',
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
      ],
    );
  }
}
