import 'dart:io';

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import 'package:smart_laundry_locker/core/media/media_upload.dart';
import 'package:smart_laundry_locker/core/media/photo_picker_controller.dart';
import 'package:smart_laundry_locker/core/media/widgets/photo_picker_field.dart';
import 'package:smart_laundry_locker/core/utils/app_date_time.dart';
import 'package:smart_laundry_locker/features/drone_delivery/domain/entities/drone_booking.dart';
import 'package:smart_laundry_locker/features/drone_delivery/domain/entities/drone_labels.dart';
import 'package:smart_laundry_locker/features/drone_delivery/domain/entities/drone_parcel.dart';
import 'package:smart_laundry_locker/features/drone_delivery/presentation/pages/pickup_location_picker_page.dart';
import 'package:smart_laundry_locker/features/locker_ops/data/locker_ops_service.dart';
import 'package:smart_laundry_locker/features/locker_ops/presentation/utils/locker_maps.dart';
import 'package:smart_laundry_locker/features/locker_ops/presentation/widgets/ops_widgets.dart';

/// Hỏi lý do (và ghi chú) cho một thao tác đóng việc: KTV không lấy được hàng, hoặc
/// điều phối viên xác nhận đơn giao không hoàn tất. [reasons] là (mã, nhãn, bắt buộc ghi chú).
Future<(String reason, String? note)?> showDroneReasonDialog(
  BuildContext context, {
  required String title,
  required String intro,
  required List<(String, String, bool)> reasons,
  required String confirmLabel,
  String? initialReason,
}) {
  final noteController = TextEditingController();
  var selected = reasons.firstWhere(
    (reason) => reason.$1 == initialReason,
    orElse: () => reasons.first,
  );
  String? problem;
  return showDialog<(String, String?)>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setLocal) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(title),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(intro, style: const TextStyle(fontSize: 13)),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final reason in reasons)
                    ChoiceChip(
                      key: ValueKey('drone-reason-${reason.$1}'),
                      label: Text(reason.$2),
                      selected: selected.$1 == reason.$1,
                      onSelected: (_) => setLocal(() => selected = reason),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                key: const ValueKey('drone-reason-note'),
                controller: noteController,
                minLines: 2,
                maxLines: 4,
                decoration: InputDecoration(
                  labelText: selected.$3
                      ? 'Ghi chú (bắt buộc)'
                      : 'Ghi chú (tùy chọn)',
                  errorText: problem,
                  isDense: true,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Quay lại'),
          ),
          FilledButton(
            key: const ValueKey('drone-reason-confirm'),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
            ),
            onPressed: () {
              final note = noteController.text.trim();
              if (selected.$3 && note.isEmpty) {
                setLocal(() => problem = 'Cần nhập ghi chú cho lý do này');
                return;
              }
              Navigator.pop(ctx, (selected.$1, note.isEmpty ? null : note));
            },
            child: Text(confirmLabel),
          ),
        ],
      ),
    ),
  );
}

/// Việc lấy hàng tận nhà của KTV drone: vào/ra ca, lời mời đang chờ trả lời, kiện đang
/// đi lấy, và kiện đã lấy đang được mang tới drone để nạp trực tiếp.
///
/// Hệ thống mời KTV đang trong ca, rảnh và gần người gửi nhất — nên vào ca phải kèm vị
/// trí, và app gửi lại vị trí định kỳ trong lúc đang trong ca.
class DronePickupQueue extends StatefulWidget {
  const DronePickupQueue({
    super.key,
    required this.service,
    required this.deliveries,
    required this.onChanged,
    required this.onOpenDetail,
    required this.onAssignDrone,
    this.readPosition = readDevicePosition,
    this.locationInterval = const Duration(seconds: 60),
  });

  final LockerOpsService service;

  /// Mọi đơn drone KTV này đang thấy (`/api/drone-technician/drone-orders`).
  final List<Map<String, dynamic>> deliveries;

  /// Nạp lại danh sách sau một thao tác.
  final Future<void> Function() onChanged;
  final ValueChanged<int> onOpenDetail;

  /// Kiện đã được lấy: KTV mang tới drone rảnh tại tủ bay rồi nạp trực tiếp.
  final ValueChanged<Map<String, dynamic>> onAssignDrone;
  final CurrentPositionReader readPosition;
  final Duration locationInterval;

  @override
  State<DronePickupQueue> createState() => _DronePickupQueueState();
}

class _DronePickupQueueState extends State<DronePickupQueue>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  bool _onDuty = false;
  bool _busy = false;
  DateTime? _locationAt;

  /// Server có luồng lấy hàng tận nhà và đã trả trạng thái ca của KTV này.
  bool _presenceKnown = false;
  bool _switching = false;
  bool _acting = false;
  Timer? _heartbeat;
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _loadPresence();
    // Lời mời có hạn trả lời: đếm ngược từng giây.
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && _offered.isNotEmpty) setState(() {});
    });
  }

  @override
  void dispose() {
    _heartbeat?.cancel();
    _ticker?.cancel();
    super.dispose();
  }

  static int? _asInt(dynamic value) =>
      value is num ? value.toInt() : int.tryParse('$value');

  static Map<String, dynamic>? _pickup(Map<String, dynamic> order) {
    final pickup = order['pickup'];
    return pickup is Map ? Map<String, dynamic>.from(pickup) : null;
  }

  static String _pickupStatus(Map<String, dynamic> order) =>
      '${_pickup(order)?['status'] ?? ''}'.toUpperCase();

  List<Map<String, dynamic>> get _offered => widget.deliveries
      .where((order) => _pickupStatus(order) == 'OFFERED')
      .toList(growable: false);

  List<Map<String, dynamic>> get _accepted => widget.deliveries
      .where((order) => _pickupStatus(order) == 'ACCEPTED')
      .toList(growable: false);

  /// Đã cầm kiện nhưng chưa gán drone.
  List<Map<String, dynamic>> get _carrying => widget.deliveries
      .where(
        (order) =>
            _pickupStatus(order) == 'PICKED_UP' &&
            '${order['deliveryStage']}'.toUpperCase() == 'PICKED_UP',
      )
      .toList(growable: false);

  Future<void> _loadPresence() async {
    try {
      _applyPresence(await widget.service.droneTechnicianPresence());
    } catch (_) {
      // Backend cũ chưa có lấy hàng tận nhà (hoặc mất mạng): chưa hiện thẻ vào ca, phần
      // còn lại của màn điều phối vẫn chạy.
    }
  }

  void _applyPresence(Map<String, dynamic> presence) {
    if (!mounted) return;
    setState(() {
      _presenceKnown = true;
      _onDuty = presence['onDuty'] == true;
      _busy = presence['busy'] == true;
      _locationAt = parseServerDateTime(presence['locationAt']);
    });
    _heartbeat?.cancel();
    if (_onDuty) {
      _heartbeat = Timer.periodic(
        widget.locationInterval,
        (_) => _sendLocation(),
      );
    }
  }

  /// Gửi lại vị trí trong lúc đang trong ca; mất GPS thì bỏ lượt, vị trí cũ sẽ tự hết
  /// hiệu lực ở server và KTV thôi được mời.
  Future<void> _sendLocation() async {
    final (position, _) = await widget.readPosition();
    if (position == null || !mounted) return;
    try {
      _applyPresence(
        await widget.service.updateDroneTechnicianPresence(
          latitude: position.latitude,
          longitude: position.longitude,
        ),
      );
    } catch (_) {
      // Lượt sau gửi lại.
    }
  }

  Future<void> _setDuty(bool onDuty) async {
    if (_switching) return;
    setState(() => _switching = true);
    try {
      LatLng? position;
      if (onDuty) {
        final (read, problem) = await widget.readPosition();
        if (read == null) {
          _toast(
            problem ?? 'Cần vị trí hiện tại để vào ca nhận việc lấy hàng.',
          );
          return;
        }
        position = read;
      }
      _applyPresence(
        await widget.service.updateDroneTechnicianPresence(
          onDuty: onDuty,
          latitude: position?.latitude,
          longitude: position?.longitude,
        ),
      );
      _toast(
        onDuty
            ? 'Đã vào ca. Bạn sẽ được mời khi có đơn gần bạn.'
            : 'Đã ra ca. Bạn sẽ không được mời lấy hàng.',
      );
      await widget.onChanged();
    } catch (error) {
      _toast(LockerOpsService.errorMessage(error));
    } finally {
      if (mounted) setState(() => _switching = false);
    }
  }

  void _toast(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _act(Future<Object?> Function() action, String done) async {
    if (_acting) return;
    setState(() => _acting = true);
    try {
      await action();
      _toast(done);
    } catch (error) {
      _toast(LockerOpsService.errorMessage(error));
    } finally {
      if (mounted) setState(() => _acting = false);
    }
    await widget.onChanged();
    await _loadPresence();
  }

  Future<void> _confirmPickup(Map<String, dynamic> order) async {
    final orderId = _asInt(order['orderId']);
    if (orderId == null) return;
    final codeController = TextEditingController();
    final noteController = TextEditingController();
    final photos = PhotoPickerController(
      maxPhotos: 1,
      purpose: MediaPurpose.dronePickup,
      captureLocation: false,
    );
    var matched = false;
    String? problem;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text('Xác nhận đã lấy hàng'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Kiện khai báo: ${_parcelSummary(order)}.\n'
                  'Nhờ người gửi đọc mã lấy hàng trong đơn của họ.',
                  style: const TextStyle(fontSize: 13),
                ),
                const SizedBox(height: 12),
                TextField(
                  key: const ValueKey('drone-pickup-code-input'),
                  controller: codeController,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  decoration: InputDecoration(
                    labelText: 'Mã lấy hàng (6 số)',
                    errorText: problem,
                    isDense: true,
                    border: const OutlineInputBorder(),
                  ),
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Checkbox(
                      key: const ValueKey('drone-pickup-matched'),
                      value: matched,
                      onChanged: (value) =>
                          setLocal(() => matched = value ?? false),
                    ),
                    const Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(top: 12),
                        child: Text(
                          'Kiện đúng khai báo (loại hàng, kích thước, khối lượng) và '
                          'không có hàng cấm bay.',
                          style: TextStyle(fontSize: 12.5),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                PhotoPickerField(
                  controller: photos,
                  showAddTile: false,
                  helperText: 'Ảnh kiện tại điểm lấy là bắt buộc.',
                  onPhotoTap: (photo) => showDialog<void>(
                    context: ctx,
                    builder: (dialogContext) => Dialog(
                      child: Stack(
                        children: [
                          InteractiveViewer(
                            child: Image.file(
                              File(photo.file.path),
                              fit: BoxFit.contain,
                            ),
                          ),
                          Positioned(
                            top: 0,
                            right: 0,
                            child: IconButton(
                              onPressed: () => Navigator.pop(dialogContext),
                              icon: const Icon(Icons.close),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                if (photos.isEmpty)
                  OutlinedButton.icon(
                    key: const ValueKey('drone-pickup-photo-camera'),
                    onPressed: () async {
                      try {
                        await photos.pick(ImageSource.camera);
                      } catch (_) {
                        setLocal(
                          () => problem =
                              'Không mở được máy ảnh. Kiểm tra quyền camera.',
                        );
                      }
                    },
                    icon: const Icon(Icons.camera_alt_outlined),
                    label: const Text('Chụp ảnh kiện'),
                  ),
                if (photos.isEmpty && problem == null)
                  const Text(
                    'Chụp rõ toàn bộ kiện trước khi xác nhận đã lấy.',
                    style: TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                TextField(
                  controller: noteController,
                  decoration: const InputDecoration(
                    labelText: 'Ghi chú (tùy chọn)',
                    isDense: true,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Chưa'),
            ),
            FilledButton(
              key: const ValueKey('drone-pickup-confirm'),
              onPressed: () {
                if (!RegExp(r'^\d{6}$').hasMatch(codeController.text.trim())) {
                  setLocal(() => problem = 'Nhập đủ 6 chữ số');
                  return;
                }
                if (!matched) {
                  setLocal(
                    () => problem =
                        'Cần xác nhận kiện đúng khai báo, hoặc báo không lấy được',
                  );
                  return;
                }
                if (photos.isEmpty) {
                  setLocal(
                    () => problem = 'Cần chụp ảnh kiện trước khi xác nhận',
                  );
                  return;
                }
                Navigator.pop(ctx, true);
              },
              child: const Text('Đã lấy hàng'),
            ),
          ],
        ),
      ),
    );
    if (confirmed != true) {
      photos.dispose();
      return;
    }
    try {
      final uploaded = await photos.uploadAll(
        caption: 'Ảnh kiện lúc kỹ thuật viên lấy hàng',
      );
      if (uploaded.isEmpty) {
        _toast('Cần chụp ảnh kiện trước khi xác nhận');
        return;
      }
      await _act(
        () => widget.service.confirmDronePickup(
          orderId,
          pickupCode: codeController.text,
          pickupPhoto: uploaded.single,
          note: noteController.text,
        ),
        'Đã lấy hàng và lưu ảnh kiện. Mang kiện tới drone được phân công và nạp trực tiếp; không bỏ vào ô tủ bay.',
      );
    } catch (error) {
      _toast(LockerOpsService.errorMessage(error));
    } finally {
      photos.dispose();
    }
  }

  Future<void> _failPickup(Map<String, dynamic> order) async {
    final orderId = _asInt(order['orderId']);
    if (orderId == null) return;
    final result = await showDroneReasonDialog(
      context,
      title: 'Không lấy được hàng',
      intro:
          'Đơn sẽ kết thúc "giao không hoàn tất" và người gửi được hoàn tiền. '
          'Không hoàn tác được.',
      reasons: dronePickupFailureReasons,
      confirmLabel: 'Xác nhận',
    );
    if (result == null) return;
    await _act(
      () => widget.service.failDronePickup(
        orderId,
        reason: result.$1,
        note: result.$2,
      ),
      'Đã báo không lấy được hàng · người gửi được hoàn tiền',
    );
  }

  Future<void> _failDelivery(Map<String, dynamic> order) async {
    final orderId = _asInt(order['orderId']);
    if (orderId == null) return;
    final block = order['block'];
    final result = await showDroneReasonDialog(
      context,
      title: 'Giao không hoàn tất',
      intro:
          'Đơn sẽ đóng lại, người gửi được hoàn tiền và bạn mang kiện trả lại '
          'người gửi. Không hoàn tác được.',
      reasons: droneDeliveryFailureReasons,
      confirmLabel: 'Xác nhận',
      initialReason: block is Map ? '${block['reason']}' : null,
    );
    if (result == null) return;
    await _act(
      () => widget.service.failDroneOrder(
        orderId,
        reason: result.$1,
        note: result.$2,
      ),
      'Đã đóng đơn · mang kiện trả lại người gửi',
    );
  }

  static String _parcelSummary(Map<String, dynamic> order) {
    final size = droneParcelSizeLabel(
      _asInt(order['parcelLengthCm']),
      _asInt(order['parcelWidthCm']),
      _asInt(order['parcelHeightCm']),
    );
    final parts = [
      if ('${order['parcelCategory'] ?? ''}'.isNotEmpty)
        droneParcelCategoryLabel('${order['parcelCategory']}'),
      droneWeightLabel(_asInt(order['parcelWeightGrams'])),
      ?size,
      if (order['fragile'] == true) 'DỄ VỠ',
    ];
    return parts.join(' · ');
  }

  String _countdown(Map<String, dynamic> pickup) {
    final expiresAt = parseServerDateTime(pickup['offerExpiresAt']);
    if (expiresAt == null) return '';
    final left = expiresAt.difference(DateTime.now());
    if (left.isNegative) return 'đã hết hạn';
    final minutes = left.inMinutes;
    final seconds = left.inSeconds % 60;
    return 'còn $minutes:${seconds.toString().padLeft(2, '0')}';
  }

  // ------------------------------------------------------------------ UI

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final offered = _offered;
    final accepted = _accepted;
    final carrying = _carrying;
    // Không có gì để hiện (server cũ, chưa có việc) thì không chiếm chỗ trên màn điều phối.
    if (!_presenceKnown &&
        offered.isEmpty &&
        accepted.isEmpty &&
        carrying.isEmpty) {
      return const SizedBox.shrink();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_presenceKnown) _dutyCard(),
        if (offered.isNotEmpty) ...[
          const SizedBox(height: 12),
          OpsSectionLabel(
            'Lời mời lấy hàng (${offered.length})',
            icon: Icons.notifications_active_outlined,
          ),
          for (final order in offered) _offerCard(order),
        ],
        if (accepted.isNotEmpty) ...[
          const SizedBox(height: 12),
          OpsSectionLabel(
            'Đang đi lấy hàng (${accepted.length})',
            icon: Icons.directions_bike_outlined,
          ),
          for (final order in accepted) _acceptedCard(order),
        ],
        if (carrying.isNotEmpty) ...[
          const SizedBox(height: 12),
          OpsSectionLabel(
            'Đã lấy hàng · chờ nạp trực tiếp lên drone (${carrying.length})',
            icon: Icons.inventory_2_outlined,
          ),
          for (final order in carrying) _carryingCard(order),
        ],
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _dutyCard() {
    final subtitle = !_onDuty
        ? 'Bật để nhận lời mời lấy hàng tận nhà gần bạn.'
        : _busy
        ? 'Đang trong ca · đang bận một việc nên chưa được mời thêm.'
        : 'Đang trong ca · rảnh, sẽ được mời khi có đơn gần bạn'
              '${_locationAt == null ? '' : ' · vị trí lúc ${formatDateTimeVn(_locationAt)}'}.';
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 8, 8, 8),
      decoration: BoxDecoration(
        color: _onDuty ? const Color(0xFFECFDF5) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _onDuty ? const Color(0xFF34D399) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Row(
        children: [
          Icon(
            _onDuty ? Icons.location_on : Icons.location_off_outlined,
            color: _onDuty ? const Color(0xFF059669) : Colors.black45,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _onDuty ? 'Đang nhận việc lấy hàng' : 'Chưa vào ca lấy hàng',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                ),
              ],
            ),
          ),
          Switch(
            key: const ValueKey('drone-duty-switch'),
            value: _onDuty,
            onChanged: _switching ? null : _setDuty,
          ),
        ],
      ),
    );
  }

  Widget _card({
    required Map<String, dynamic> order,
    required Color accent,
    required List<Widget> children,
  }) {
    final orderId = _asInt(order['orderId']);
    final block = order['block'];
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: orderId == null ? null : () => widget.onOpenDetail(orderId),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: accent.withValues(alpha: 0.45)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${order['orderCode'] ?? 'Đơn #$orderId'}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: opsDark,
                ),
              ),
              const SizedBox(height: 4),
              ...children,
              if (block is Map) ...[
                const SizedBox(height: 8),
                Text(
                  'Đang gặp sự cố: '
                  '${block['reasonLabel'] ?? droneFailureReasonLabel('${block['reason']}')}'
                  '${block['ticketId'] == null ? '' : ' · phiếu #${block['ticketId']}'}',
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: Color(0xFFB45309),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _line(String text) => Padding(
    padding: const EdgeInsets.only(top: 2),
    child: Text(
      text,
      style: const TextStyle(fontSize: 12.5, color: Colors.black87),
    ),
  );

  Widget _offerCard(Map<String, dynamic> order) {
    final orderId = _asInt(order['orderId']);
    final pickup = _pickup(order)!;
    return _card(
      order: order,
      accent: const Color(0xFF6366F1),
      children: [
        _line('Lấy tại: ${pickup['address'] ?? '—'}'),
        _line(
          'Cách bạn ${droneDistanceLabel(_asInt(pickup['technicianDistanceMeters']))}'
          ' · kiện ${_parcelSummary(order)}',
        ),
        _line('Trả lời ${_countdown(pickup)}'),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                key: ValueKey('drone-pickup-decline-$orderId'),
                onPressed: _acting || orderId == null
                    ? null
                    : () => _act(
                        () => widget.service.declineDronePickup(orderId),
                        'Đã từ chối · hệ thống mời người khác',
                      ),
                child: const Text('Từ chối'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: FilledButton(
                key: ValueKey('drone-pickup-accept-$orderId'),
                onPressed: _acting || orderId == null
                    ? null
                    : () => _act(
                        () => widget.service.acceptDronePickup(orderId),
                        'Đã nhận. Tới điểm lấy hàng và hỏi mã lấy hàng của người gửi.',
                      ),
                child: const Text('Nhận lấy hàng'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _acceptedCard(Map<String, dynamic> order) {
    final orderId = _asInt(order['orderId']);
    final pickup = _pickup(order)!;
    final sender = order['sender'];
    final senderLine = sender is Map
        ? [sender['name'], sender['phone']]
              .where((value) => value != null && '$value'.trim().isNotEmpty)
              .join(' · ')
        : '';
    return _card(
      order: order,
      accent: const Color(0xFFF59E0B),
      children: [
        _line('Lấy tại: ${pickup['address'] ?? '—'}'),
        if (senderLine.isNotEmpty) _line('Người gửi: $senderLine'),
        if (pickup['note'] != null) _line('Chỉ dẫn: ${pickup['note']}'),
        _line('Kiện khai báo: ${_parcelSummary(order)}'),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            OutlinedButton.icon(
              onPressed: () => openLockerDirections(
                latitude: (pickup['latitude'] as num?)?.toDouble(),
                longitude: (pickup['longitude'] as num?)?.toDouble(),
                address: pickup['address']?.toString(),
              ),
              icon: const Icon(Icons.directions, size: 16),
              label: const Text('Chỉ đường'),
            ),
            FilledButton.icon(
              key: ValueKey('drone-pickup-done-$orderId'),
              onPressed: _acting ? null : () => _confirmPickup(order),
              icon: const Icon(Icons.inventory_2_outlined, size: 16),
              label: const Text('Đã lấy hàng'),
            ),
            OutlinedButton(
              key: ValueKey('drone-pickup-fail-$orderId'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFDC2626),
              ),
              onPressed: _acting ? null : () => _failPickup(order),
              child: const Text('Không lấy được'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _carryingCard(Map<String, dynamic> order) {
    final orderId = _asInt(order['orderId']);
    final source = order['sourceLocker'];
    final sourceName = source is Map
        ? '${source['name'] ?? source['code'] ?? 'Tủ gửi'}'
        : 'Tủ gửi #${order['sourceLockerId'] ?? '?'}';
    final sourceAddress = source is Map ? source['address']?.toString() : null;
    return _card(
      order: order,
      accent: const Color(0xFF16A34A),
      children: [
        _line('Mang kiện tới drone tại: $sourceName'),
        if (sourceAddress != null && sourceAddress.isNotEmpty)
          _line(sourceAddress),
        _line('Kiện: ${_parcelSummary(order)}'),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            if (source is Map)
              OutlinedButton.icon(
                onPressed: () => openLockerDirections(
                  latitude: (source['latitude'] as num?)?.toDouble(),
                  longitude: (source['longitude'] as num?)?.toDouble(),
                  address: sourceAddress,
                ),
                icon: const Icon(Icons.directions, size: 16),
                label: const Text('Chỉ đường tới drone'),
              ),
            FilledButton.icon(
              key: ValueKey('drone-assign-drone-$orderId'),
              onPressed: _acting ? null : () => widget.onAssignDrone(order),
              icon: const Icon(Icons.flight, size: 16),
              label: const Text('Gán drone'),
            ),
            OutlinedButton(
              key: ValueKey('drone-delivery-fail-$orderId'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFDC2626),
              ),
              onPressed: _acting ? null : () => _failDelivery(order),
              child: const Text('Giao không hoàn tất'),
            ),
          ],
        ),
      ],
    );
  }
}
