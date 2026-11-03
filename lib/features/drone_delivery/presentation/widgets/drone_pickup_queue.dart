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
import 'package:smart_laundry_locker/core/l10n/l10n.dart';

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
  // Chặn do thời tiết tuyến / trạm dừng bay ⇒ lý do "thời tiết" của danh sách.
  final initial = switch (initialReason) {
    'WEATHER_UNSAFE' || 'WEATHER_UNAVAILABLE' || 'STATION_SUSPENDED' => 'WEATHER',
    _ => initialReason,
  };
  // Chỉ chọn sẵn lý do đang chặn đơn; không thì để KTV tự chọn, tránh bấm nhầm
  // xác nhận với lý do đầu danh sách.
  (String, String, bool)? selected = reasons
      .where((reason) => reason.$1 == initial)
      .firstOrNull;
  String? reasonProblem;
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
                      selected: selected?.$1 == reason.$1,
                      onSelected: (_) => setLocal(() {
                        selected = reason;
                        reasonProblem = null;
                      }),
                    ),
                ],
              ),
              if (reasonProblem != null) ...[
                const SizedBox(height: 6),
                Text(
                  reasonProblem!,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFFB91C1C),
                  ),
                ),
              ],
              const SizedBox(height: 12),
              TextField(
                key: const ValueKey('drone-reason-note'),
                controller: noteController,
                minLines: 2,
                maxLines: 4,
                decoration: InputDecoration(
                  labelText: selected?.$3 == true
                      ? context.l10n.dtNoteRequired
                      : context.l10n.dtNoteOptional,
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
            child: Text(context.l10n.commonBack),
          ),
          FilledButton(
            key: const ValueKey('drone-reason-confirm'),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
            ),
            onPressed: () {
              final note = noteController.text.trim();
              final reason = selected;
              if (reason == null) {
                setLocal(() => reasonProblem = context.l10n.dtPickReason);
                return;
              }
              if (reason.$3 && note.isEmpty) {
                setLocal(() => problem = context.l10n.dtPqNoteRequiredForReason);
                return;
              }
              Navigator.pop(ctx, (reason.$1, note.isEmpty ? null : note));
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
            problem ?? L10n.current.dtPqNeedLocation,
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
            ? L10n.current.dtPqOnDuty
            : L10n.current.dtPqOffDuty,
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

  /// Từ chối là mất lời mời và không được mời lại đơn này một thời gian, nên hỏi lại
  /// trước (test 2026-11-02: bấm "Từ chối" một lần là mất lời mời ngay).
  Future<void> _declineOffer(Map<String, dynamic> order, int orderId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.l10n.dtPqDeclineTitle),
        content: Text(
          context.l10n.dtPqDeclineBody('${order['orderCode'] ?? '#$orderId'}'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(context.l10n.commonBack),
          ),
          FilledButton(
            key: const ValueKey('drone-pickup-decline-confirm'),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(context.l10n.dtPqDecline),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await _act(
      () => widget.service.declineDronePickup(orderId),
      L10n.current.dtPqDeclined,
    );
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
    // Lỗi gắn vào đúng chỗ phải sửa; gửi server ngay trong hộp thoại để nhập sai mã
    // không làm mất ảnh / dấu kiểm đã có.
    String? codeProblem;
    String? matchProblem;
    String? photoProblem;
    String? submitProblem;
    var submitting = false;
    Map<String, dynamic>? uploadedPhoto;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(context.l10n.dtPqConfirmPickupTitle),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Lỗi máy chủ (vd. DRONE_PICKUP_TOO_FAR) đặt trên cùng: trước đây nằm dưới ô
                // ghi chú, bị bàn phím che nên bấm "Đã lấy hàng" như không phản ứng (test 2026-10-29).
                if (submitProblem != null) ...[
                  _DialogError(submitProblem!),
                  const SizedBox(height: 8),
                ],
                Text(
                  context.l10n.dtPqDeclaredParcelAsk(_parcelSummary(order)),
                  style: const TextStyle(fontSize: 13),
                ),
                const SizedBox(height: 12),
                TextField(
                  key: const ValueKey('drone-pickup-code-input'),
                  controller: codeController,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  decoration: InputDecoration(
                    labelText: context.l10n.dtPqPickupCode,
                    errorText: codeProblem,
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
                      onChanged: submitting
                          ? null
                          : (value) => setLocal(() {
                              matched = value ?? false;
                              matchProblem = null;
                            }),
                    ),
                    Expanded(
                      // Bấm vào chữ cũng tick được (ô vuông nhỏ, dễ bấm trượt).
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: submitting
                            ? null
                            : () => setLocal(() {
                                matched = !matched;
                                matchProblem = null;
                              }),
                        child: Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Text(
                            context.l10n.dtPqParcelMatches,
                            style: const TextStyle(fontSize: 12.5),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                if (matchProblem != null) _DialogError(matchProblem!),
                const SizedBox(height: 8),
                PhotoPickerField(
                  controller: photos,
                  showAddTile: false,
                  helperText: context.l10n.dtPqPhotoRequired,
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
                        setLocal(() => photoProblem = null);
                      } catch (_) {
                        setLocal(
                          () => photoProblem =
                              L10n.current.dtPqCameraFailed,
                        );
                      }
                    },
                    icon: const Icon(Icons.camera_alt_outlined),
                    label: Text(context.l10n.dtPqTakePhoto),
                  ),
                if (photoProblem != null)
                  _DialogError(photoProblem!)
                else if (photos.isEmpty)
                  Text(
                    context.l10n.dtPqPhotoHint,
                    style: const TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                TextField(
                  controller: noteController,
                  decoration: InputDecoration(
                    labelText: context.l10n.dtNoteOptional,
                    isDense: true,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: submitting ? null : () => Navigator.pop(ctx, false),
              child: Text(context.l10n.commonNotYet),
            ),
            FilledButton(
              key: const ValueKey('drone-pickup-confirm'),
              onPressed: submitting
                  ? null
                  : () async {
                      final code = codeController.text.trim();
                      setLocal(() {
                        codeProblem = RegExp(r'^\d{6}$').hasMatch(code)
                            ? null
                            : context.l10n.dtPqEnterSixDigits;
                        matchProblem = matched
                            ? null
                            : context.l10n.dtPqConfirmMatchOrFail;
                        photoProblem = photos.isEmpty
                            ? context.l10n.dtPqNeedPhoto
                            : null;
                        submitProblem = null;
                      });
                      if (codeProblem != null ||
                          matchProblem != null ||
                          photoProblem != null) {
                        return;
                      }
                      setLocal(() => submitting = true);
                      try {
                        // Ảnh đã tải lên ở lần thử trước thì dùng lại, không tải lại.
                        uploadedPhoto ??= (await photos.uploadAll(
                          caption: 'Ảnh kiện lúc kỹ thuật viên lấy hàng',
                        )).firstOrNull;
                        if (uploadedPhoto == null) {
                          setLocal(
                            () => photoProblem =
                                L10n.current.dtPqUploadFailed,
                          );
                          return;
                        }
                        Future<void> submit() => widget.service.confirmDronePickup(
                          orderId,
                          pickupCode: code,
                          pickupPhoto: uploadedPhoto!,
                          note: noteController.text,
                        );
                        try {
                          await submit();
                        } catch (error) {
                          // Vị trí ca trực đã cũ: lấy GPS ngay rồi thử lại một lần, giữ nguyên mã, ảnh
                          // và dấu kiểm. Trước đây KTV phải đóng hộp, bấm "Cập nhật lại GPS" rồi nhập
                          // lại từ đầu (test 2026-10-29).
                          if (LockerOpsService.errorCode(error) !=
                              'DRONE_PICKUP_LOCATION_STALE') {
                            rethrow;
                          }
                          final (position, problem) = await widget.readPosition();
                          if (position == null) {
                            throw problem ??
                                L10n.current.dtPqNoGps;
                          }
                          _applyPresence(
                            await widget.service.updateDroneTechnicianPresence(
                              latitude: position.latitude,
                              longitude: position.longitude,
                            ),
                          );
                          await submit();
                        }
                        if (ctx.mounted) Navigator.pop(ctx, true);
                      } catch (error) {
                        final message = error is String
                            ? error
                            : LockerOpsService.errorMessage(error);
                        final errorCode = error is String
                            ? null
                            : LockerOpsService.errorCode(error);
                        setLocal(() {
                          if (errorCode == 'DRONE_PICKUP_CODE_INVALID') {
                            codeProblem = message;
                          } else if (errorCode ==
                              'DRONE_PICKUP_PARCEL_NOT_VERIFIED') {
                            matchProblem = message;
                          } else {
                            submitProblem = message;
                          }
                        });
                        // Hạ bàn phím để thấy lỗi.
                        if (ctx.mounted) FocusScope.of(ctx).unfocus();
                      } finally {
                        if (ctx.mounted) setLocal(() => submitting = false);
                      }
                    },
              child: submitting
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(context.l10n.dtPqPickedUp),
            ),
          ],
        ),
      ),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      photos.dispose();
      codeController.dispose();
      noteController.dispose();
    });
    if (confirmed != true) return;
    // Server đã nhận trong hộp thoại; chỉ còn báo và tải lại.
    await _act(
      () async => null,
      L10n.current.dtPqPickedUpDone,
    );
  }

  Future<void> _failPickup(Map<String, dynamic> order) async {
    final orderId = _asInt(order['orderId']);
    if (orderId == null) return;
    final result = await showDroneReasonDialog(
      context,
      title: context.l10n.dtPqFailPickupTitle,
      intro: context.l10n.dtPqFailPickupIntro,
      reasons: dronePickupFailureReasons,
      confirmLabel: context.l10n.commonConfirm,
    );
    if (result == null) return;
    await _act(
      () => widget.service.failDronePickup(
        orderId,
        reason: result.$1,
        note: result.$2,
      ),
      L10n.current.dtPqFailPickupDone,
    );
  }

  Future<void> _failDelivery(Map<String, dynamic> order) async {
    final orderId = _asInt(order['orderId']);
    if (orderId == null) return;
    final block = order['block'];
    final result = await showDroneReasonDialog(
      context,
      title: context.l10n.dtFailDelivery,
      intro: context.l10n.dtFailDeliveryIntro,
      reasons: droneDeliveryFailureReasons,
      confirmLabel: context.l10n.commonConfirm,
      initialReason: block is Map ? '${block['reason']}' : null,
    );
    if (result == null) return;
    await _act(
      () => widget.service.failDroneOrder(
        orderId,
        reason: result.$1,
        note: result.$2,
      ),
      L10n.current.dtFailedDeliveryDone,
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
      if (order['fragile'] == true) L10n.current.dtFragileUpper,
    ];
    return parts.join(' · ');
  }

  String _countdown(Map<String, dynamic> pickup) {
    final expiresAt = parseServerDateTime(pickup['offerExpiresAt']);
    if (expiresAt == null) return '';
    final left = expiresAt.difference(DateTime.now());
    if (left.isNegative) return context.l10n.dtPqExpired;
    final minutes = left.inMinutes;
    final seconds = left.inSeconds % 60;
    return context.l10n.dtPqTimeLeft('$minutes:${seconds.toString().padLeft(2, '0')}');
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
            context.l10n.dtPqSecOffers(offered.length),
            icon: Icons.notifications_active_outlined,
          ),
          for (final order in offered) _offerCard(order),
        ],
        if (accepted.isNotEmpty) ...[
          const SizedBox(height: 12),
          OpsSectionLabel(
            context.l10n.dtPqSecAccepted(accepted.length),
            icon: Icons.directions_bike_outlined,
          ),
          for (final order in accepted) _acceptedCard(order),
        ],
        if (carrying.isNotEmpty) ...[
          const SizedBox(height: 12),
          OpsSectionLabel(
            context.l10n.dtPqSecCarrying(carrying.length),
            icon: Icons.inventory_2_outlined,
          ),
          for (final order in carrying) _carryingCard(order),
        ],
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _dutyCard() {
    // Lời mời đang chờ cũng làm server tính KTV là "bận": báo đúng là có lời mời,
    // không ghi "đang bận" ngay trên lời mời đó. Chưa vào ca mà có lời mời = điều
    // phối viên giao thẳng.
    final offers = _offered.length;
    final subtitle = offers > 0
        ? (_onDuty
              ? context.l10n.dtPqOffersWaiting(offers)
              : context.l10n.dtPqOffersWaitingDirect(offers))
        : !_onDuty
        ? context.l10n.dtPqTurnOnHint
        : _busy
        ? context.l10n.dtPqBusy
        : _locationAt == null
        ? context.l10n.dtPqFree
        : context.l10n.dtPqFreeWithLocation(formatDateTimeVn(_locationAt));
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
                  _onDuty ? context.l10n.dtPqOnDutyTitle : context.l10n.dtPqOffDutyTitle,
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
                '${order['orderCode'] ?? context.l10n.dtOrderNumber('$orderId')}',
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
                  context.l10n.dtBlockedBy(
                        '${block['reasonLabel'] ?? droneFailureReasonLabel('${block['reason']}')}',
                      ) +
                      (block['ticketId'] == null
                          ? ''
                          : context.l10n.dtBlockedTicket('${block['ticketId']}')),
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
        _line(context.l10n.dtPqPickupAt('${pickup['address'] ?? '—'}')),
        _line(
          context.l10n.dtPqDistanceParcel(
            droneDistanceLabel(_asInt(pickup['technicianDistanceMeters'])),
            _parcelSummary(order),
          ),
        ),
        _line(context.l10n.dtPqReplyIn(_countdown(pickup))),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                key: ValueKey('drone-pickup-decline-$orderId'),
                onPressed: _acting || orderId == null
                    ? null
                    : () => _declineOffer(order, orderId),
                child: Text(context.l10n.dtPqDecline),
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
                        context.l10n.dtPqAccepted,
                      ),
                child: Text(context.l10n.dtPqAcceptPickup),
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
        _line(context.l10n.dtPqPickupAt('${pickup['address'] ?? '—'}')),
        if (senderLine.isNotEmpty) _line(context.l10n.dtSender(senderLine)),
        if (pickup['note'] != null) _line(context.l10n.dtPqInstructions('${pickup['note']}')),
        _line(context.l10n.dtPqDeclaredParcel(_parcelSummary(order))),
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
              label: Text(context.l10n.dtPqDirections),
            ),
            FilledButton.icon(
              key: ValueKey('drone-pickup-done-$orderId'),
              onPressed: _acting ? null : () => _confirmPickup(order),
              icon: const Icon(Icons.inventory_2_outlined, size: 16),
              label: Text(context.l10n.dtPqPickedUp),
            ),
            OutlinedButton(
              key: ValueKey('drone-pickup-fail-$orderId'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFDC2626),
              ),
              onPressed: _acting ? null : () => _failPickup(order),
              child: Text(context.l10n.dtPqCantPickUp),
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
        ? '${source['name'] ?? source['code'] ?? context.l10n.dtSendingLocker}'
        : context.l10n.dtPqSendingLockerNumber('${order['sourceLockerId'] ?? '?'}');
    final sourceAddress = source is Map ? source['address']?.toString() : null;
    return _card(
      order: order,
      accent: const Color(0xFF16A34A),
      children: [
        _line(context.l10n.dtPqBringToDrone(sourceName)),
        if (sourceAddress != null && sourceAddress.isNotEmpty)
          _line(sourceAddress),
        _line(context.l10n.dtParcel(_parcelSummary(order))),
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
                label: Text(context.l10n.dtPqDirectionsToDrone),
              ),
            FilledButton.icon(
              key: ValueKey('drone-assign-drone-$orderId'),
              onPressed: _acting ? null : () => widget.onAssignDrone(order),
              icon: const Icon(Icons.flight, size: 16),
              label: Text(context.l10n.dtAssignDrone),
            ),
            OutlinedButton(
              key: ValueKey('drone-delivery-fail-$orderId'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFDC2626),
              ),
              onPressed: _acting ? null : () => _failDelivery(order),
              child: Text(context.l10n.dtFailDelivery),
            ),
          ],
        ),
      ],
    );
  }
}

/// Dòng lỗi đỏ ngay dưới phần cần sửa trong hộp thoại.
class _DialogError extends StatelessWidget {
  const _DialogError(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 4),
    child: Text(
      text,
      style: const TextStyle(fontSize: 12, color: Color(0xFFB91C1C)),
    ),
  );
}
