import 'package:smart_laundry_locker/core/utils/app_date_time.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:smart_laundry_locker/core/config/business_config_provider.dart';
import 'package:smart_laundry_locker/core/media/media.dart';
import 'package:smart_laundry_locker/core/routing/app_router.dart';
import 'package:smart_laundry_locker/shared/widgets/app_lottie.dart';
import 'package:smart_laundry_locker/features/locker_ops/data/locker_ops_service.dart';
import 'package:smart_laundry_locker/features/locker_ops/presentation/utils/business_rules_text.dart';
import 'package:smart_laundry_locker/features/locker_ops/presentation/utils/locker_maps.dart';
import 'package:smart_laundry_locker/features/locker_ops/presentation/widgets/locker_unlock_modal.dart';
import 'package:smart_laundry_locker/features/locker_ops/presentation/widgets/ops_widgets.dart';
import 'package:smart_laundry_locker/features/locker_ops/presentation/widgets/order_payment_sheet.dart';
import 'package:smart_laundry_locker/features/locker_ops/presentation/widgets/order_status_timeline.dart';
import 'package:smart_laundry_locker/shared/widgets/user_ui_kit.dart';

/// All locker orders of the signed-in customer, with the full action set gated
/// to the backend state machine: confirm drop, pickup/complete, delegate,
/// extend/end rental, report fault, cancel.
class MyLockerOrdersPage extends StatefulWidget {
  const MyLockerOrdersPage({super.key, this.service});

  final LockerOpsService? service;

  @override
  State<MyLockerOrdersPage> createState() => _MyLockerOrdersPageState();
}

class _MyLockerOrdersPageState extends State<MyLockerOrdersPage>
    with BusinessConfigStateMixin {
  late final LockerOpsService _service = widget.service ?? LockerOpsService();
  List<Map<String, dynamic>> _orders = [];
  Map<int, Map<int, int>> _lockerBoxesMap = {};

  /// Bản ghi tủ đầy đủ theo `lockerId` (tên, địa chỉ, toạ độ) — trang vẫn gọi
  /// `GET /api/lockers/{id}` sẵn, nên giữ cả bản ghi để bảng chi tiết hiện được
  /// địa điểm đặt tủ mà không phải gọi mạng thêm lần nữa.
  Map<int, Map<String, dynamic>> _lockersMap = {};
  Map<int, Map<String, dynamic>> _activeReportsByBox = {};
  bool _loading = true;
  String _typeFilter = 'ALL';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final orders = await _service.myOrders();
      final reports = await _service.myReports();

      // Fetch box layouts to display box numbers instead of box IDs
      final lockerIds = <int>{};
      for (final o in orders) {
        final origin = _asInt(o['lockerId']);
        if (origin != null) lockerIds.add(origin);
        final dest = _asInt(o['destinationLockerId']);
        if (dest != null) lockerIds.add(dest);
      }

      if (!mounted) return;

      final Map<int, Map<int, int>> lockerBoxesMap = {};
      final Map<int, Map<String, dynamic>> lockersMap = {};

      for (final lId in lockerIds) {
        try {
          final info = await _service.locker(lId);
          debugPrint('Locker $lId info: $info');
          lockersMap[lId] = info;
        } catch (e) {
          debugPrint('Locker $lId fetch error: $e');
        }

        try {
          final layout = await _service.layout(lId);
          debugPrint('Layout $lId info: $layout');
          final cells = layout['cells'] as List?;
          final map = <int, int>{};
          if (cells != null) {
            for (final c in cells) {
              final cId = _asInt(c['id']);
              final bNum = _asInt(c['boxNumber']);
              if (cId != null && bNum != null) {
                map[cId] = bNum;
              }
            }
          }
          lockerBoxesMap[lId] = map;
        } catch (e) {
          debugPrint('Layout $lId fetch error: $e');
        }
      }

      if (!mounted) return;
      setState(() {
        _lockerBoxesMap = lockerBoxesMap;
        _lockersMap = lockersMap;
        _activeReportsByBox = _activeReportsByBoxMap(reports);
        _orders = orders;
      });
    } catch (e) {
      _snack(LockerOpsService.errorMessage(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<Map<String, dynamic>> get _visible {
    return _orders.where((o) {
      final type = (o['type'] as String? ?? '').toUpperCase();
      return _typeFilter == 'ALL' || type == _typeFilter;
    }).toList();
  }

  Map<String, dynamic>? _activeReportForOrder(Map<String, dynamic> order) {
    final rawStatus = (order['status'] as String? ?? '').toUpperCase();
    final isPickup = rawStatus == 'STORING' || rawStatus == 'RETURNED';
    final boxId = isPickup
        ? _asInt(order['receiveBoxId'] ?? order['sendBoxId'])
        : _asInt(order['sendBoxId'] ?? order['receiveBoxId']);
    if (boxId == null) return null;
    return _activeReportsByBox[boxId];
  }

  /// Số ô in trên tủ, tra từ sơ đồ tủ đã tải. Dùng cho MỌI câu thông báo cho người
  /// dùng: `boxId` là mã nội bộ, nói "ô 701" thì người ta ra tủ không tìm thấy ô nào.
  String _boxLabelFor(Map<String, dynamic> order, int? boxId) {
    final rawStatus = (order['status'] as String? ?? '').toUpperCase();
    final isPickup = rawStatus == 'STORING' || rawStatus == 'RETURNED';
    final lockerId = isPickup
        ? _asInt(order['destinationLockerId'] ?? order['lockerId'])
        : _asInt(order['lockerId'] ?? order['destinationLockerId']);
    final number = (lockerId == null || boxId == null)
        ? null
        : _lockerBoxesMap[lockerId]?[boxId];
    return number == null ? 'ô này' : 'ô số $number';
  }

  static DateTime? _parseOrderDate(Map<String, dynamic> o) {
    final raw = o['createdAt'] ?? o['updatedAt'] ?? o['pickupDeadline'];
    if (raw == null) return null;
    return parseServerDateTime(raw);
  }

  static String _dateGroupLabel(DateTime d) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(d.year, d.month, d.day);
    final diff = today.difference(day).inDays;
    if (diff == 0) return 'Hôm nay';
    if (diff == 1) return 'Hôm qua';
    return '${d.day} tháng ${d.month}, ${d.year}';
  }

  /// Orders grouped by date label, sorted newest-first within each group.
  List<MapEntry<String, List<Map<String, dynamic>>>> get _groupedOrders {
    final sorted = List<Map<String, dynamic>>.from(_visible)
      ..sort((a, b) {
        final da = _parseOrderDate(a);
        final db = _parseOrderDate(b);
        if (da == null && db == null) return 0;
        if (da == null) return 1;
        if (db == null) return -1;
        return db.compareTo(da);
      });

    final map = <String, List<Map<String, dynamic>>>{};
    for (final o in sorted) {
      final d = _parseOrderDate(o);
      final key = d == null ? 'Không rõ ngày' : _dateGroupLabel(d);
      (map[key] ??= []).add(o);
    }
    return map.entries.toList();
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _runAction(
    Future<Map<String, dynamic>> Function() fn,
    String ok,
  ) async {
    try {
      await fn();
      _snack(ok);
      await _load();
    } catch (e) {
      _snack(LockerOpsService.errorMessage(e));
    }
  }

  Future<void> _extendDialog(int orderId) async {
    // Giới hạn gia hạn do admin cấu hình; làm mới nền để lần sau dùng giá trị
    // mới nhất mà không bắt người dùng chờ mạng.
    businessConfigService.refresh();
    final config = businessConfig;
    final maxHours = config.extendMaxHours;
    var hours = config.extendDefaultHours.clamp(1, maxHours).toDouble();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text('Gia hạn thuê'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Thêm ${hours.round()} giờ',
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                  color: opsDark,
                ),
              ),
              if (maxHours > 1)
                Slider(
                  value: hours,
                  min: 1,
                  max: maxHours.toDouble(),
                  divisions: maxHours - 1,
                  activeColor: opsPrimary,
                  label: '${hours.round()}h',
                  onChanged: (v) => setSheet(() => hours = v),
                ),
              Text(
                'Tối đa $maxHours giờ mỗi lần gia hạn',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12, color: opsMutedText),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Hủy'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Gia hạn'),
            ),
          ],
        ),
      ),
    );
    if (confirmed == true) {
      await _runAction(
        () => _service.extendRental(orderId, hours.round()),
        'Đã gia hạn ${hours.round()} giờ',
      );
    }
  }

  Future<void> _reportDialog({
    required int orderId,

    /// Nhãn ô cho người đọc (`ô số 4`), đã tra sẵn từ sơ đồ tủ.
    String boxLabel = 'ô này',
  }) async {
    final reasonCtrl = TextEditingController();
    // Ảnh hiện trường stage REPORT — tối đa theo cấu hình admin.
    final photos = PhotoPickerController(
      maxPhotos: businessConfig.reportPhotosPerRequestReporter,
    );
    // Trạng thái dialog giữ ngoài builder để không bị reset khi dialog rebuild
    // (vd. bàn phím bật lên).
    var uploading = false;
    String? dialogError;
    List<Map<String, dynamic>> attachments = const [];
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      // photos + reasonCtrl được huỷ khi dialog gỡ khỏi cây (sau hiệu ứng đóng).
      builder: (ctx) => ControllerDisposer(
        controllers: [photos, reasonCtrl],
        child: StatefulBuilder(
          builder: (ctx, setLocal) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: const Text('Báo ô lỗi'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: reasonCtrl,
                    maxLines: 3,
                    enabled: !uploading,
                    decoration: const InputDecoration(
                      hintText: 'Mô tả sự cố (ô không mở, kẹt cửa...)',
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Ảnh hiện trường (không bắt buộc, tối đa '
                    '${photos.maxPhotos})',
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: opsDark,
                    ),
                  ),
                  const SizedBox(height: 8),
                  PhotoPickerField(
                    controller: photos,
                    enabled: !uploading,
                    thumbSize: 64,
                    accentColor: AislBrand.navy,
                    helperText: 'Ảnh giúp đội bảo trì xử lý nhanh hơn.',
                  ),
                  if (dialogError != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      dialogError!,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFFDC2626),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: uploading ? null : () => Navigator.pop(ctx, false),
                child: const Text('Hủy'),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFDC2626),
                ),
                onPressed: uploading
                    ? null
                    : () async {
                        if (reasonCtrl.text.trim().isEmpty && photos.isEmpty) {
                          setLocal(
                            () => dialogError =
                                'Vui lòng mô tả sự cố hoặc đính kèm ảnh.',
                          );
                          return;
                        }
                        setLocal(() {
                          uploading = true;
                          dialogError = null;
                        });
                        try {
                          attachments = await photos.uploadAll();
                          if (ctx.mounted) Navigator.pop(ctx, true);
                        } catch (e) {
                          if (ctx.mounted) {
                            setLocal(() {
                              uploading = false;
                              dialogError = LockerOpsService.errorMessage(e);
                            });
                          }
                        }
                      },
                child: Text(uploading ? 'Đang tải ảnh...' : 'Gửi báo lỗi'),
              ),
            ],
          ),
        ),
      ),
    );
    final reason = reasonCtrl.text.trim();
    if (confirmed == true && (reason.isNotEmpty || attachments.isNotEmpty)) {
      try {
        await _service.reportOrderFault(
          orderId,
          reason.isNotEmpty ? reason : 'Ô tủ gặp sự cố (xem ảnh đính kèm)',
          attachments: attachments,
        );
        await _load();
        if (!mounted) return;
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(
                'Đã gửi báo lỗi cho $boxLabel — đội bảo trì sẽ xử lý',
              ),
              action: SnackBarAction(
                label: 'Xem',
                onPressed: () => context.push(AppRouter.myLockerReports),
              ),
            ),
          );
      } catch (e) {
        _snack(LockerOpsService.errorMessage(e));
      }
    }
  }

  Future<void> _showRentalCompletionGuide(Map<String, dynamic> order) async {
    final orderId = _asInt(order['id']);
    final pin = order['pinCode'] as String?;
    final qrToken = order['qrToken'] as String?;
    if (orderId == null) return;

    final boxId = _asInt(order['sendBoxId'] ?? order['receiveBoxId']);
    final boxLabel = _boxLabelFor(order, boxId);

    await showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (ctx) => SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Lấy đồ tại kiosk',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 18,
                color: opsDark,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Dùng mã này tại kiosk để mở ô, lấy đồ ra, rồi đóng cửa tủ lại trước khi xác nhận kết thúc thuê. Bạn cũng có thể bấm mở trực tiếp trên app nếu đang ở gần tủ.',
              style: TextStyle(fontSize: 14, color: opsMutedText, height: 1.45),
            ),
            const SizedBox(height: 16),
            OpsSheetAction(
              label: 'Mở $boxLabel trên điện thoại (GPS/QR)',
              icon: LucideIcons.doorOpen,
              primary: true,
              onTap: () {
                Navigator.pop(ctx);
                _openLockerFlow(order);
              },
            ),
            if ((pin != null && pin.isNotEmpty) ||
                (qrToken != null && qrToken.isNotEmpty)) ...[
              const SizedBox(height: 16),
              Center(
                child: AccessCredentials(pin: pin, qrToken: qrToken),
              ),
            ],
            const SizedBox(height: 16),
            OpsSheetAction(
              label: 'Đã lấy đồ và đóng tủ',
              icon: LucideIcons.circleCheck,
              primary: false,
              onTap: () {
                Navigator.pop(ctx);
                _runAction(
                  () => _service.endRental(orderId),
                  'Đã kết thúc kỳ thuê',
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Bản ghi tủ của đơn, `null` khi chưa tải được.
  Map<String, dynamic>? _lockerOf(Map<String, dynamic> order) {
    final rawStatus = (order['status'] as String? ?? '').toUpperCase();
    final isPickup = rawStatus == 'STORING' || rawStatus == 'RETURNED';
    final lockerId = isPickup
        ? _asInt(order['destinationLockerId'] ?? order['lockerId'])
        : _asInt(order['lockerId'] ?? order['destinationLockerId']);
    return _lockersMap[lockerId];
  }

  String? _lockerNameOf(Map<String, dynamic> order) =>
      _lockerOf(order)?['name']?.toString();

  Future<void> _openLockerDirections(Map<String, dynamic> order) async {
    final rawStatus = (order['status'] as String? ?? '').toUpperCase();
    final isPickup = rawStatus == 'STORING' || rawStatus == 'RETURNED';
    final lockerId = isPickup
        ? _asInt(order['destinationLockerId'] ?? order['lockerId'])
        : _asInt(order['lockerId'] ?? order['destinationLockerId']);
    if (lockerId == null) {
      _snack('Đơn chưa có thông tin tủ.');
      return;
    }
    try {
      // Dùng bản ghi đã tải nếu có; chỉ gọi mạng khi cache chưa có tủ này.
      final locker = _lockersMap[lockerId] ?? await _service.locker(lockerId);
      final result = await openLockerDirectionsResult(
        latitude: _asDouble(locker['latitude']),
        longitude: _asDouble(locker['longitude']),
        address: locker['address']?.toString(),
      );
      switch (result) {
        case DirectionsResult.opened:
          break;
        case DirectionsResult.noLocation:
          _snack('Tủ chưa có vị trí để chỉ đường.');
        case DirectionsResult.launchFailed:
          _snack('Không mở được ứng dụng bản đồ trên máy này.');
      }
    } catch (e) {
      _snack(LockerOpsService.errorMessage(e));
    }
  }

  /// Chọn phương thức rồi thanh toán; chỉ báo thành công khi server đã ghi
  /// nhận đơn PAID (bước bỏ hàng phụ thuộc vào trạng thái đó).
  Future<void> _payDialog(Map<String, dynamic> order) async {
    final orderId = _asInt(order['id']);
    if (orderId == null) return;
    // Thu phần còn thiếu, không thu lại phần khách đã trả (gia hạn/phí quá hạn).
    final total = orderAmountDue(order);

    // Làm mới nền danh sách phương thức admin bật (trong TTL thì không gọi mạng).
    businessConfigService.refresh();

    try {
      final outcome = await payOrderAndAwaitPaid(
        context,
        service: _service,
        orderId: orderId,
        total: total,
        enabledMethods: businessConfig.enabledPaymentMethods,
      );
      if (!mounted || outcome == OrderPaymentOutcome.cancelled) return;
      _snack(
        outcome == OrderPaymentOutcome.paid
            ? 'Thanh toán thành công'
            : 'Đang chờ xác nhận thanh toán — kéo xuống để làm mới sau ít phút.',
      );
      await _load();
    } catch (e) {
      _snack(LockerOpsService.errorMessage(e));
    }
  }

  /// Luồng thanh toán phí quá hạn để mở ô tủ (Pay-to-Unlock).
  Future<void> _payOvertimeFlow(Map<String, dynamic> order, num fee) async {
    final orderId = _asInt(order['id']);
    if (orderId == null) return;

    try {
      final assessed = await _service.assessOvertime(orderId);
      if (assessed.isNotEmpty) {
        order = assessed;
      }
    } catch (_) {}

    num balance = 0;
    try {
      balance = await _service.walletBalance();
    } catch (_) {}

    if (!mounted) return;

    final lockerName = _lockerNameOf(order) ?? 'Tủ Lock.R';
    final boxId = _asInt(order['receiveBoxId'] ?? order['sendBoxId']);
    final boxLabel = _boxLabelFor(order, boxId);
    final deadline = order['pickupDeadline'];
    final durationText = fmtOverdueDuration(deadline);
    final config = businessConfig;

    final paidAndOpen = await showModalBottomSheet<bool>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (ctx) => _PayOvertimeConfirmationSheet(
        order: order,
        fee: fee,
        walletBalance: balance,
        lockerName: lockerName,
        boxLabel: boxLabel,
        overdueDurationText:
            durationText.isNotEmpty ? durationText : 'Đã quá hạn',
        overtimeRate: config.pickupOvertimeFeePerHour,
        service: _service,
        enabledMethods: config.enabledPaymentMethods,
      ),
    );

    if (paidAndOpen == true && mounted) {
      _snack('Đã thanh toán phí quá giờ — chuẩn bị mở ô');
      await _load();
      if (mounted) {
        final updated = _orders.firstWhere(
          (o) => _asInt(o['id']) == orderId,
          orElse: () => order,
        );
        _openLockerFlow(updated);
      }
    }
  }

  /// Thực hiện mở khóa vật lý qua backend IoT
  Future<void> _doPhysicalUnlock(
    int lockerId,
    int boxId,
    String pin,
    String boxLabel,
    Map<String, dynamic> order,
  ) async {
    _snack('Đang gửi lệnh mở $boxLabel tới tủ...');
    try {
      final res = await _service.unlock(lockerId, boxId, pin);
      final accepted = res['accepted'] == true;
      final msg = res['message']?.toString();
      _snack(
        accepted
            ? 'Tủ đã mở $boxLabel — mời bạn thao tác rồi đóng cửa.'
            : 'Không mở được $boxLabel${msg != null && msg.isNotEmpty ? ': $msg' : ''}',
      );
      if (accepted) {
        await _load();
      }
    } catch (e) {
      _snack(LockerOpsService.errorMessage(e));
    }
  }

  /// Gửi lệnh mở ô của đơn xuống cabinet qua mô hình Hybrid (GPS Geofencing + Quét QR).
  Future<void> _openLockerFlow(Map<String, dynamic> order) async {
    final rawStatus = (order['status'] as String? ?? '').toUpperCase();
    final type = (order['type'] as String? ?? '').toUpperCase();
    final isRental = type == 'RENTAL';
    final isPickupPhase = rawStatus == 'STORING' || rawStatus == 'RETURNED';

    final lockerId = isPickupPhase
        ? _asInt(order['destinationLockerId'] ?? order['lockerId'])
        : _asInt(order['lockerId'] ?? order['destinationLockerId']);

    final boxId = isPickupPhase
        ? _asInt(order['receiveBoxId'] ?? order['sendBoxId'])
        : _asInt(order['sendBoxId'] ?? order['receiveBoxId']);

    final pin = order['pinCode'] as String?;
    if (lockerId == null || boxId == null || pin == null || pin.isEmpty) {
      _snack('Đơn chưa có thông tin ô/PIN để mở tủ.');
      return;
    }
    final boxLabel = _boxLabelFor(order, boxId);

    // Lấy thông tin tủ đầy đủ (mã tủ, tên)
    Map<String, dynamic>? locker = _lockersMap[lockerId];
    if (locker == null) {
      try {
        locker = await _service.locker(lockerId);
      } catch (_) {}
    }
    final lockerName = locker?['name']?.toString() ?? 'Tủ Lock.R';
    final lockerCode = locker?['code']?.toString() ?? '';

    if (!mounted) return;

    final deadline = order['pickupDeadline'];
    final overdue = isOverdue(deadline) &&
        rawStatus != 'COMPLETED' &&
        rawStatus != 'CANCELED';

    // Hiển thị Modal 3 phương thức mở tủ:
    // 1. Bluetooth BLE (Proximity 1-chạm kèm chế độ Mô phỏng RPi)
    // 2. Quét tem mã QR trên thân tủ
    // 3. Xem mã PIN / OTP nhập trực tiếp tại màn hình Kiosk
    final action = await LockerUnlockModal.show(
      context,
      lockerName: lockerName,
      lockerCode: lockerCode,
      lockerId: lockerId,
      boxId: boxId,
      boxLabel: boxLabel,
      pinCode: pin,
      isRentalReturning: isRental && rawStatus == 'STORING',
      isOverdue: overdue,
      overdueNotice: overdue
          ? 'Đơn thuê đã quá hạn. Đã ghi nhận xử lý phí quá giờ — mời bạn mở ô lấy đồ và đóng tủ để hoàn tất.'
          : null,
    );

    if (action == null || !mounted) return;

    if (action.type == LockerUnlockActionType.openViaBle ||
        action.type == LockerUnlockActionType.openViaQr) {
      await _doPhysicalUnlock(lockerId, boxId, pin, boxLabel, order);
    }
  }

  void _openDetail(Map<String, dynamic> order) {
    showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.78,
        maxChildSize: 0.95,
        builder: (ctx, controller) => SingleChildScrollView(
          controller: controller,
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
          child: _DetailSheet(
            order: order,
            faultReport: _activeReportForOrder(order),
            lockerName: _lockerNameOf(order),
            locker: _lockerOf(order),
            sendBoxNumber:
                _lockerBoxesMap[_asInt(order['lockerId'])]?[_asInt(
                  order['sendBoxId'],
                )],
            receiveBoxNumber:
                _lockerBoxesMap[_asInt(
                  order['destinationLockerId'] ?? order['lockerId'],
                )]?[_asInt(order['receiveBoxId'])],
            onReorder: (id) async {
              Navigator.pop(ctx);
              await _runAction(
                () => _service.reorder(id),
                'Đã tạo đơn mới — xem trong danh sách',
              );
            },
            onConfirmDrop: (id) async {
              Navigator.pop(ctx);
              await _runAction(
                () => _service.confirmDrop(id),
                'Đã xác nhận bỏ đồ',
              );
            },
            onComplete: (id) async {
              Navigator.pop(ctx);
              await _runAction(
                () => _service.completePickup(id),
                'Đã nhận đồ — đơn hoàn tất',
              );
            },
            onEndRental: (id) async {
              Navigator.pop(ctx);
              await _showRentalCompletionGuide(order);
            },
            onExtend: (id) async {
              Navigator.pop(ctx);
              await _extendDialog(id);
            },
            onReport: (boxId) async {
              Navigator.pop(ctx);
              final orderId = _asInt(order['id']);
              if (orderId == null) return;
              await _reportDialog(
                orderId: orderId,
                boxLabel: _boxLabelFor(order, boxId),
              );
            },
            onCancel: (id) async {
              Navigator.pop(ctx);
              await _runAction(() => _service.cancelOrder(id), 'Đã hủy đơn');
            },
            onDirections: () => _openLockerDirections(order),
            onPay: (_) async {
              Navigator.pop(ctx);
              await _payDialog(order);
            },
            onPayOvertime: (id, fee) async {
              Navigator.pop(ctx);
              await _payOvertimeFlow(order, fee);
            },
            onOpenLocker: () {
              Navigator.pop(ctx);
              _openLockerFlow(order);
            },
            onTrackDrone: (id) {
              Navigator.pop(ctx);
              context.go(AppRouter.droneDeliveryTracking, extra: '$id');
            },
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final groups = _groupedOrders;

    // Flatten groups into a mixed list of date-headers + order items
    final items = <_ListItem>[];
    for (final entry in groups) {
      items.add(_ListItem.header(entry.key));
      for (var i = 0; i < entry.value.length; i++) {
        items.add(_ListItem.order(entry.value[i]));
      }
    }

    return Scaffold(
      backgroundColor: context.pageBg,
      body: Column(
        children: [
          BrandHeroHeader(
            title: 'Đơn tủ',
            subtitle: 'Quản lý các đơn hàng của bạn',
            trailing: BrandCircleIconButton(
              icon: LucideIcons.refreshCw,
              onTap: _load,
              iconSize: 18,
            ),
          ),

          // ── Service type chips ───────────────────────────────────────────
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
            child: Row(
              children: [
                _TypeChip(
                  label: 'Tất cả',
                  count: _orders.length,
                  selected: _typeFilter == 'ALL',
                  onTap: () => setState(() => _typeFilter = 'ALL'),
                ),
                const SizedBox(width: 8),
                _TypeChip(
                  label: 'Thuê tủ',
                  selected: _typeFilter == 'RENTAL',
                  onTap: () => setState(() => _typeFilter = 'RENTAL'),
                ),
                const SizedBox(width: 8),
                _TypeChip(
                  label: 'Gửi hàng',
                  selected: _typeFilter == 'SEND',
                  onTap: () => setState(() => _typeFilter = 'SEND'),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // ── Grouped list ─────────────────────────────────────────────────
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(color: AislBrand.navy),
                  )
                : _visible.isEmpty
                ? OpsEmptyState(
                    icon: LucideIcons.packageOpen,
                    title: 'Chưa có đơn nào',
                    subtitle:
                        'Tạo đơn Gửi hàng hoặc Thuê tủ từ màn hình chính.',
                  )
                : RefreshIndicator(
                    color: AislBrand.navy,
                    onRefresh: _load,
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(0, 0, 0, 120),
                      itemCount: items.length,
                      itemBuilder: (ctx, i) {
                        final item = items[i];
                        if (item.isHeader) {
                          return Padding(
                            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                            child: Text(
                              item.header!,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: ctx.textMuted,
                                letterSpacing: 0.3,
                              ),
                            ),
                          );
                        }
                        final o = item.order!;
                        return Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                          child:
                              _OrderCard(
                                    order: o,
                                    faultReport: _activeReportForOrder(o),
                                    lockerName: _lockerNameOf(o),
                                    sendBoxNumber:
                                        _lockerBoxesMap[_asInt(
                                          o['lockerId'],
                                        )]?[_asInt(o['sendBoxId'])],
                                    receiveBoxNumber:
                                        _lockerBoxesMap[_asInt(
                                          o['lockerId'],
                                        )]?[_asInt(o['receiveBoxId'])],
                                    onTap: () => _openDetail(o),
                                  )
                                  .animate()
                                  .fadeIn(delay: (i * 30).ms, duration: 200.ms)
                                  .slideY(
                                    begin: 0.05,
                                    end: 0,
                                    delay: (i * 30).ms,
                                    duration: 200.ms,
                                    curve: Curves.easeOut,
                                  ),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

// ── List item discriminated union ─────────────────────────────────────────────

class _ListItem {
  const _ListItem._({this.header, this.order});
  factory _ListItem.header(String h) => _ListItem._(header: h);
  factory _ListItem.order(Map<String, dynamic> o) => _ListItem._(order: o);

  final String? header;
  final Map<String, dynamic>? order;
  bool get isHeader => header != null;
}

// ── Service type chip ─────────────────────────────────────────────────────────

class _TypeChip extends StatelessWidget {
  const _TypeChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.count,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final int? count;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? context.textPrimary : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? context.textPrimary : context.borderColor,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: selected
                    ? (context.isDark ? const Color(0xFF061A30) : Colors.white)
                    : context.textPrimary,
              ),
            ),
            if (count != null && count! > 0) ...[
              const SizedBox(width: 5),
              Text(
                '($count)',
                style: TextStyle(
                  fontSize: 12,
                  color: selected
                      ? (context.isDark
                                ? const Color(0xFF061A30)
                                : Colors.white)
                            .withValues(alpha: 0.7)
                      : context.textMuted,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Order card (Grab style) ───────────────────────────────────────────────────

bool _isDeliveryOrder(String? type) {
  final upper = (type ?? '').toUpperCase();
  return upper.contains('SEND') ||
      upper.contains('DRONE') ||
      upper.contains('DELIVERY') ||
      upper.contains('PARCEL');
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({
    required this.order,
    this.faultReport,
    this.lockerName,
    this.sendBoxNumber,
    this.receiveBoxNumber,
    required this.onTap,
  });

  final Map<String, dynamic> order;
  final Map<String, dynamic>? faultReport;
  final String? lockerName;
  final int? sendBoxNumber;
  final int? receiveBoxNumber;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final type = order['type'] as String?;
    final rawStatus = order['status'] as String?;
    final status = _displayStatus(order, rawStatus);
    final deadline = order['pickupDeadline'];
    final overdue =
        isOverdue(deadline) &&
        rawStatus != 'COMPLETED' &&
        rawStatus != 'CANCELED';
    final sColor = statusColor(status);
    final isDone = rawStatus == 'COMPLETED' || rawStatus == 'CANCELED';

    return Material(
      color: context.cardBg,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              clipBehavior: Clip.antiAlias,
              children: [
                // 3D asset nestled in bottom-right corner (matching sample image 2)
                Positioned(
                  bottom: -6,
                  right: -4,
                  child: IgnorePointer(
                    child: SizedBox(
                      width: 112,
                      height: 100,
                      child: AppLottie(
                        _isDeliveryOrder(type)
                            ? AppLottieAssets.airplaneBox
                            : AppLottieAssets.box,
                        alignment: Alignment.bottomRight,
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Order Code + Status Badge Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Text(
                              order['orderCode'] != null &&
                                      order['orderCode'].toString().isNotEmpty
                                  ? '#${order['orderCode']}'
                                  : '#ORD-${order['id'] ?? ''}',
                              style: TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w800,
                                color: context.textPrimary,
                                letterSpacing: -0.2,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 9,
                              vertical: 3.5,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  (isDone
                                          ? const Color(0xFF16A34A)
                                          : overdue
                                          ? const Color(0xFFDC2626)
                                          : sColor)
                                      .withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              statusLabel(status),
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                color: isDone
                                    ? const Color(0xFF16A34A)
                                    : overdue
                                    ? const Color(0xFFDC2626)
                                    : sColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      // Service type + deadline
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            typeLabel(type),
                            style: TextStyle(
                              fontSize: 12.5,
                              color: context.textMuted,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (deadline != null) ...[
                            Text(
                              '•',
                              style: TextStyle(
                                fontSize: 12,
                                color: context.textMuted,
                              ),
                            ),
                            Text(
                              'Hạn lấy: ${fmtDateTime(deadline)}',
                              style: TextStyle(
                                fontSize: 12,
                                color: overdue
                                    ? const Color(0xFFDC2626)
                                    : context.textMuted,
                                fontWeight: overdue
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Route: Tủ and Ô
                      Padding(
                        padding: const EdgeInsets.only(right: 90),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _RouteRow(
                              isOrigin: true,
                              text: lockerName ?? 'Chưa tra được tên tủ',
                            ),
                            const SizedBox(height: 8),
                            _RouteRow(
                              isOrigin: false,
                              text: _orderBoxLabel(
                                sendBoxNumber: sendBoxNumber,
                                receiveBoxNumber: receiveBoxNumber,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      // Price + action
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            fmtPrice(order['totalPrice']),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: context.textPrimary,
                            ),
                          ),
                          const SizedBox(width: 12),
                          GestureDetector(
                            onTap: onTap,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: context.borderColor,
                                  width: 1.5,
                                ),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                'Xem lại',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                  color: context.textPrimary,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            // Overdue banner
            if (overdue)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                color: const Color(0xFFFEF2F2),
                child: Row(
                  children: const [
                    Icon(
                      LucideIcons.triangleAlert,
                      size: 13,
                      color: Color(0xFFDC2626),
                    ),
                    SizedBox(width: 6),
                    Text(
                      'Đơn đã quá hạn — có thể phát sinh phí',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFDC2626),
                      ),
                    ),
                  ],
                ),
              )
            else
              const SizedBox(height: 0),
            if (faultReport != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                child: _FaultOrderBanner(
                  report: faultReport!,
                  boxLabel: _orderBoxLabel(
                    sendBoxNumber: sendBoxNumber,
                    receiveBoxNumber: receiveBoxNumber,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _RouteRow extends StatelessWidget {
  const _RouteRow({required this.isOrigin, required this.text});
  final bool isOrigin;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 16,
          child: Center(
            child: isOrigin
                ? Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFF9CA3AF),
                        width: 2,
                      ),
                    ),
                  )
                : Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: const Color(0xFF374151),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Color(0xFF1F2937),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _FaultOrderBanner extends StatelessWidget {
  const _FaultOrderBanner({required this.report, required this.boxLabel});

  final Map<String, dynamic> report;
  final String boxLabel;

  @override
  Widget build(BuildContext context) {
    final reason = (report['description'] as String?)?.trim();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFCA5A5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            LucideIcons.triangleAlert,
            size: 16,
            color: Color(0xFFDC2626),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$boxLabel đã được báo lỗi.',
                  style: const TextStyle(
                    fontSize: 12.5,
                    height: 1.35,
                    color: Color(0xFFDC2626),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Hãy hủy đơn này và đặt ô khác.',
                  style: const TextStyle(
                    fontSize: 12.5,
                    height: 1.35,
                    color: Color(0xFFDC2626),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (reason != null && reason.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Lý do: $reason',
                    style: const TextStyle(
                      fontSize: 12,
                      height: 1.35,
                      color: Color(0xFFDC2626),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

int? _asInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse('$value');
}

double? _asDouble(dynamic value) {
  if (value is double) return value;
  if (value is num) return value.toDouble();
  return double.tryParse('$value');
}

String _displayStatus(Map<String, dynamic> order, String? fallback) {
  final type = (order['type'] as String? ?? '').toUpperCase();
  if (type == 'DRONE_DELIVERY') {
    final deliveryStage = order['deliveryStage'] as String?;
    if (deliveryStage != null && deliveryStage.isNotEmpty) {
      return deliveryStage;
    }
  }
  return fallback ?? '';
}

/// BottomSheet xác nhận thanh toán phí quá giờ để mở tủ (Pay-to-Unlock).
class _PayOvertimeConfirmationSheet extends StatefulWidget {
  const _PayOvertimeConfirmationSheet({
    required this.order,
    required this.fee,
    required this.walletBalance,
    required this.lockerName,
    required this.boxLabel,
    required this.overdueDurationText,
    required this.overtimeRate,
    required this.service,
    required this.enabledMethods,
  });

  final Map<String, dynamic> order;
  final num fee;
  final num walletBalance;
  final String lockerName;
  final String boxLabel;
  final String overdueDurationText;
  final int overtimeRate;
  final LockerOpsService service;
  final List<String> enabledMethods;

  @override
  State<_PayOvertimeConfirmationSheet> createState() =>
      _PayOvertimeConfirmationSheetState();
}

class _PayOvertimeConfirmationSheetState
    extends State<_PayOvertimeConfirmationSheet> {
  bool _loading = false;
  String? _error;

  Future<void> _payWithWallet() async {
    final orderId = _asInt(widget.order['id']);
    if (orderId == null) return;
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      try {
        await widget.service.assessOvertime(orderId);
      } catch (_) {}
      await widget.service.checkout(orderId, 'WALLET');
      final paid = await widget.service.awaitOrderPaid(orderId);
      if (!mounted) return;
      if (paid) {
        Navigator.pop(context, true);
      } else {
        setState(() {
          _loading = false;
          _error =
              'Hệ thống đang xử lý thanh toán, vui lòng kiểm tra lại sau ít giây.';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = LockerOpsService.errorMessage(e);
      });
    }
  }

  Future<void> _payWithOtherMethods() async {
    final orderId = _asInt(widget.order['id']);
    if (orderId == null) return;

    try {
      await widget.service.assessOvertime(orderId);
    } catch (_) {}

    if (!mounted) return;

    final outcome = await payOrderAndAwaitPaid(
      context,
      service: widget.service,
      orderId: orderId,
      total: widget.fee.toDouble(),
      enabledMethods: widget.enabledMethods,
    );

    if (outcome == OrderPaymentOutcome.paid && mounted) {
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasEnoughWallet = widget.walletBalance >= widget.fee;
    final deadline = widget.order['pickupDeadline'];
    final config = BusinessConfigService.instance.current;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        left: 20,
        right: 20,
        top: 10,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFF97316).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  LucideIcons.circleAlert,
                  color: Color(0xFFEA580C),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Thanh toán phí quá giờ',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                        color: opsDark,
                      ),
                    ),
                    Text(
                      '${widget.lockerName} · ${widget.boxLabel}',
                      style: const TextStyle(fontSize: 13, color: opsMutedText),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Bảng kê chi phí
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: opsSurface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: opsBorder),
            ),
            child: Column(
              children: [
                _breakdownRow(
                  'Hạn trả ban đầu',
                  fmtDateTime(deadline),
                ),
                _breakdownRow(
                  'Thời điểm mở tủ',
                  fmtDateTime(DateTime.now()),
                ),
                _breakdownRow(
                  'Thời gian quá hạn',
                  widget.overdueDurationText,
                  valueColor: const Color(0xFFDC2626),
                ),
                _breakdownRow(
                  'Đơn giá quá giờ',
                  '${fmtPrice(widget.overtimeRate)}/giờ',
                ),
                if (config.pickupMaxOvertimePercent > 0 ||
                    config.pickupMaxOvertimeFee > 0)
                  _breakdownRow(
                    'Quy định mức trần',
                    [
                      if (config.pickupMaxOvertimeFee > 0)
                        'Tối đa ${fmtPrice(config.pickupMaxOvertimeFee)}',
                      if (config.pickupMaxOvertimePercent > 0)
                        '${config.pickupMaxOvertimePercent}% đơn',
                    ].join(' & '),
                  ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Divider(height: 1, color: opsBorder),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Tổng phí quá giờ:',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                        color: opsDark,
                      ),
                    ),
                    Text(
                      fmtPrice(widget.fee),
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 20,
                        color: Color(0xFFEA580C),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          // Số dư ví
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: hasEnoughWallet
                  ? const Color(0xFFF0FDF4)
                  : const Color(0xFFFEF2F2),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: hasEnoughWallet
                    ? const Color(0xFFBBF7D0)
                    : const Color(0xFFFECACA),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  LucideIcons.wallet,
                  size: 20,
                  color: hasEnoughWallet
                      ? const Color(0xFF16A34A)
                      : const Color(0xFFDC2626),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Số dư ví khả dụng: ${fmtPrice(widget.walletBalance)}',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: hasEnoughWallet
                              ? const Color(0xFF15803D)
                              : const Color(0xFF991B1B),
                        ),
                      ),
                      if (!hasEnoughWallet)
                        Text(
                          'Còn thiếu ${fmtPrice(widget.fee - widget.walletBalance)} để thanh toán nhanh qua ví',
                          style: const TextStyle(
                            fontSize: 11.5,
                            color: Color(0xFFB91C1C),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 10),
            Text(
              _error!,
              style: const TextStyle(fontSize: 12, color: Color(0xFFDC2626)),
              textAlign: TextAlign.center,
            ),
          ],
          const SizedBox(height: 18),
          if (hasEnoughWallet)
            FilledButton.icon(
              onPressed: _loading ? null : _payWithWallet,
              icon: _loading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(LucideIcons.doorOpen, size: 18),
              label: Text(
                _loading
                    ? 'Đang thanh toán & mở tủ...'
                    : 'Trừ ví ${fmtPrice(widget.fee)} & Mở tủ ngay',
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFEA580C),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            )
          else
            FilledButton.icon(
              onPressed: _loading ? null : _payWithOtherMethods,
              icon: const Icon(LucideIcons.creditCard, size: 18),
              label: Text(
                'Nạp tiền / Thanh toán ${fmtPrice(widget.fee)}',
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: opsPrimary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: _loading ? null : () => Navigator.pop(context, false),
            child: const Text('Để sau'),
          ),
        ],
      ),
    );
  }

  Widget _breakdownRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3.5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(fontSize: 12.5, color: opsMutedText)),
          Text(
            value,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: valueColor ?? opsDark,
            ),
          ),
        ],
      ),
    );
  }
}

Map<int, Map<String, dynamic>> _activeReportsByBoxMap(
  List<Map<String, dynamic>> reports,
) {
  final active = <int, Map<String, dynamic>>{};
  for (final report in reports) {
    final boxId = _asInt(report['boxId']);
    final status = (report['status'] as String? ?? '').toUpperCase();
    if (boxId == null || status == 'RESOLVED' || active.containsKey(boxId)) {
      continue;
    }
    active[boxId] = report;
  }
  return active;
}

/// `4`, `4 → 7`, hoặc `Chưa gán ô` — cho dòng "Ô" ở bảng chi tiết.
String _boxRouteLabel(int? sendBoxNumber, int? receiveBoxNumber) {
  if (sendBoxNumber == null && receiveBoxNumber == null) return 'Chưa gán ô';
  if (sendBoxNumber != null && receiveBoxNumber != null) {
    return '$sendBoxNumber → $receiveBoxNumber';
  }
  return '${sendBoxNumber ?? receiveBoxNumber}';
}

/// `Ô số 4`, hoặc `Ô này` khi chưa gán ô.
///
/// CHỈ dùng số ô in trên tủ. Trước đây thiếu số ô thì rơi về `boxId` — mã nội bộ của
/// bản ghi — nên màn hình hiện "Ô số 701" trong khi trên tủ không có ô nào số 701;
/// người dùng đi tìm sẽ không thấy. Nói chung chung còn hơn nói một con số sai.
String _orderBoxLabel({
  int? sendBoxNumber,
  int? receiveBoxNumber,
  bool isPickupPhase = false,
}) {
  final label = isPickupPhase
      ? (receiveBoxNumber ?? sendBoxNumber)
      : (sendBoxNumber ?? receiveBoxNumber);
  return label == null ? 'Ô này' : 'Ô số $label';
}

class _DetailSheet extends StatelessWidget {
  const _DetailSheet({
    required this.order,
    this.faultReport,
    this.lockerName,
    this.locker,
    this.sendBoxNumber,
    this.receiveBoxNumber,
    required this.onReorder,
    required this.onConfirmDrop,
    required this.onComplete,
    required this.onEndRental,
    required this.onExtend,
    required this.onReport,
    required this.onCancel,
    required this.onDirections,
    required this.onPay,
    required this.onPayOvertime,
    required this.onOpenLocker,
    required this.onTrackDrone,
  });

  final Map<String, dynamic> order;
  final Map<String, dynamic>? faultReport;
  final String? lockerName;

  /// Bản ghi tủ đầy đủ để hiện địa điểm; `null` khi chưa tải được.
  final Map<String, dynamic>? locker;
  final int? sendBoxNumber;
  final int? receiveBoxNumber;
  final void Function(int orderId) onReorder;
  final void Function(int orderId) onConfirmDrop;
  final void Function(int orderId) onComplete;
  final void Function(int orderId) onEndRental;
  final void Function(int orderId) onExtend;
  final void Function(int boxId) onReport;
  final void Function(int orderId) onCancel;
  final VoidCallback onDirections;
  final void Function(int orderId) onPay;
  final void Function(int orderId, num fee) onPayOvertime;
  final VoidCallback onOpenLocker;
  final void Function(int orderId) onTrackDrone;

  @override
  Widget build(BuildContext context) {
    final id = _asInt(order['id']) ?? 0;
    final rawStatus = order['status'] as String? ?? '';
    final status = _displayStatus(order, rawStatus);
    final type = (order['type'] as String? ?? '').toUpperCase();
    final isDroneDelivery = type == 'DRONE_DELIVERY';
    final isRental = type == 'RENTAL';
    final isPickupPhase = rawStatus == 'STORING' || rawStatus == 'RETURNED';
    final boxId = isPickupPhase
        ? _asInt(order['receiveBoxId'] ?? order['sendBoxId'])
        : _asInt(order['sendBoxId'] ?? order['receiveBoxId']);
    final deadline = order['pickupDeadline'];
    final overdue =
        isOverdue(deadline) && status != 'COMPLETED' && status != 'CANCELED';
    final extraFee = order['extraFee'];
    final hasExtra =
        extraFee != null &&
        (extraFee is num ? extraFee > 0 : num.tryParse('$extraFee') != null);
    final extraFeeNum =
        extraFee is num ? extraFee : num.tryParse('$extraFee') ?? 0;

    final paymentStatus = (order['paymentStatus'] as String? ?? 'UNPAID')
        .toUpperCase();
    final totalRaw = order['totalPrice'];
    final totalNum = totalRaw is num
        ? totalRaw
        : num.tryParse('$totalRaw') ?? 0;
    final canPay =
        paymentStatus != 'PAID' && totalNum > 0 && rawStatus != 'CANCELED';
    final canUsePickupActions = !isDroneDelivery || paymentStatus == 'PAID';
    final boxLabel = _orderBoxLabel(
      sendBoxNumber: sendBoxNumber,
      receiveBoxNumber: receiveBoxNumber,
      isPickupPhase: isPickupPhase,
    );
    final rawAddress = locker?['address']?.toString().trim();
    final lockerAddress = (rawAddress == null || rawAddress.isEmpty)
        ? null
        : rawAddress;

    // Backend order-service trả thêm 5 trường này từ bản vá OrderResponse (trước đây có
    // trên entity nhưng không trả về khách hàng) — receiverName/receiverPhone (SEND / uỷ
    // quyền lấy hộ), customerNote (ghi chú lúc tạo đơn), deliveryAddress (SEND giao tận
    // nơi), rentalDurationHours (RENTAL). Tất cả optional nên chỉ hiện dòng khi có giá trị.
    final receiverName = (order['receiverName'] as String?)?.trim();
    final receiverPhone = (order['receiverPhone'] as String?)?.trim();
    final receiverLabel = [
      if (receiverName != null && receiverName.isNotEmpty) receiverName,
      if (receiverPhone != null && receiverPhone.isNotEmpty) receiverPhone,
    ].join(' · ');
    final customerNote = (order['customerNote'] as String?)?.trim();
    final deliveryAddress = (order['deliveryAddress'] as String?)?.trim();
    final rentalHours = _asInt(order['rentalDurationHours']);
    final discountAmount = _asDouble(order['discount']) ?? 0;
    final promotionCode = (order['promotionCode'] as String?)?.trim();
    final createdAt = order['createdAt'];

    final config = BusinessConfigService.instance.current;
    final overtimeDurationText = fmtOverdueDuration(deadline);

    num calcOvertime() {
      final backendFee = _asDouble(order['pickupOvertimeFee']);
      if (backendFee != null && backendFee > 0) return backendFee;
      if (!overdue) return 0;
      final parsedD = parseDate(deadline);
      if (parsedD == null) return 0;
      final diffHours = DateTime.now().difference(parsedD).inHours;
      final raw = diffHours * config.pickupOvertimeFeePerHour;
      final maxPercent = config.pickupMaxOvertimePercent;
      final percentCap = maxPercent > 0 && totalNum > 0
          ? (totalNum * maxPercent / 100).round()
          : (config.pickupMaxOvertimeFee > 0
              ? config.pickupMaxOvertimeFee
              : raw);
      var fee = raw;
      if (config.pickupMaxOvertimeFee > 0 &&
          fee > config.pickupMaxOvertimeFee) {
        fee = config.pickupMaxOvertimeFee;
      }
      if (percentCap > 0 && fee > percentCap) {
        fee = percentCap;
      }
      return fee > 0 ? fee : 0;
    }

    final overtimeFee = calcOvertime();
    final isOvertimePaid = hasExtra &&
        paymentStatus == 'PAID' &&
        extraFeeNum >= overtimeFee &&
        overtimeFee > 0;
    final needsPayOvertime = overdue && !isOvertimePaid && overtimeFee > 0;

    final canDrop =
        rawStatus == 'INITIALIZED' &&
        (paymentStatus == 'PAID' ||
            totalNum <= 0 ||
            order['paymentRequired'] == false) &&
        boxId != null;

    final actions = <Widget>[
      if (isDroneDelivery &&
          rawStatus != 'COMPLETED' &&
          rawStatus != 'CANCELED')
        OpsSheetAction(
          label: 'Theo dõi giao drone',
          icon: LucideIcons.navigation,
          primary: true,
          onTap: () => onTrackDrone(id),
        ),
      if (canPay)
        OpsSheetAction(
          label: 'Thanh toán ${fmtPrice(orderAmountDue(order))}',
          icon: LucideIcons.creditCard,
          primary: true,
          onTap: () => onPay(id),
        ),
      if (rawStatus == 'COMPLETED' || rawStatus == 'CANCELED')
        OpsSheetAction(
          label: 'Đặt lại đơn',
          icon: LucideIcons.repeat,
          primary: true,
          onTap: () => onReorder(id),
        ),
      if (canDrop)
        OpsSheetAction(
          label: 'Mở $boxLabel để bỏ đồ',
          icon: LucideIcons.doorOpen,
          primary: true,
          onTap: onOpenLocker,
        ),
      if (rawStatus == 'INITIALIZED')
        OpsSheetAction(
          label: 'Tôi đã bỏ đồ vào ô',
          icon: LucideIcons.packageCheck,
          primary: !canDrop,
          onTap: () => onConfirmDrop(id),
        ),
      if (canUsePickupActions &&
          (rawStatus == 'RETURNED' ||
              (rawStatus == 'STORING' && !isRental))) ...[
        if (needsPayOvertime)
          OpsSheetAction(
            label: 'Thanh toán phí quá giờ (${fmtPrice(overtimeFee)}) & Mở ô',
            icon: LucideIcons.creditCard,
            primary: true,
            onTap: () => onPayOvertime(id, overtimeFee),
          )
        else
          OpsSheetAction(
            label: 'Mở $boxLabel để lấy đồ',
            icon: LucideIcons.doorOpen,
            primary: true,
            onTap: onOpenLocker,
          ),
        OpsSheetAction(
          label: 'Tôi đã lấy đồ — hoàn tất',
          icon: LucideIcons.circleCheck,
          primary: false,
          onTap: () => onComplete(id),
        ),
      ],
      if (isRental && rawStatus == 'STORING') ...[
        if (needsPayOvertime)
          OpsSheetAction(
            label: 'Thanh toán phí quá giờ (${fmtPrice(overtimeFee)}) & Mở ô',
            icon: LucideIcons.creditCard,
            primary: true,
            onTap: () => onPayOvertime(id, overtimeFee),
          )
        else
          OpsSheetAction(
            label: 'Mở $boxLabel để trả tủ & lấy đồ',
            icon: LucideIcons.doorOpen,
            primary: true,
            onTap: onOpenLocker,
          ),
        OpsSheetAction(
          label: 'Gia hạn thuê',
          icon: LucideIcons.timer,
          onTap: () => onExtend(id),
        ),
        OpsSheetAction(
          label: 'Kết thúc thuê & lấy đồ',
          icon: LucideIcons.logOut,
          onTap: () => onEndRental(id),
        ),
      ],
      // "Ủy quyền người khác lấy hộ" đã gỡ theo yêu cầu nghiệp vụ — người nhận
      // lấy hàng bằng mã PIN, không cần uỷ quyền thêm một lớp nữa.
      if (boxId != null && rawStatus != 'COMPLETED' && rawStatus != 'CANCELED')
        OpsSheetAction(
          label: 'Báo ô lỗi',
          icon: LucideIcons.triangleAlert,
          onTap: () => onReport(boxId),
        ),
      if (rawStatus == 'INITIALIZED')
        OpsSheetAction(
          label: 'Hủy đơn',
          icon: LucideIcons.circleX,
          danger: true,
          onTap: () => onCancel(id),
        ),
      OpsSheetAction(
        label: 'Chỉ đường tới tủ',
        icon: LucideIcons.map,
        onTap: onDirections,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (faultReport != null) ...[
          _FaultOrderBanner(report: faultReport!, boxLabel: boxLabel),
          const SizedBox(height: 12),
        ],
        Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: statusColor(status).withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: statusColor(status).withValues(alpha: 0.18),
                  width: 1,
                ),
              ),
              padding: const EdgeInsets.all(4),
              child: AppLottie(
                _isDeliveryOrder(order['type'] as String?)
                    ? AppLottieAssets.airplaneBox
                    : AppLottieAssets.box,
                fallback: (context) => Icon(
                  typeIcon(order['type'] as String?),
                  color: statusColor(status),
                  size: 24,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    typeLabel(order['type'] as String?),
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                      color: opsDark,
                    ),
                  ),
                  Text(
                    '${order['orderCode'] ?? ''}',
                    style: const TextStyle(fontSize: 12, color: opsMutedText),
                  ),
                ],
              ),
            ),
            StatusChip(status),
          ],
        ),
        const SizedBox(height: 16),
        if (overdue)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: OpsBanner(
              tone: isOvertimePaid ? OpsBannerTone.info : OpsBannerTone.danger,
              icon: isOvertimePaid
                  ? LucideIcons.circleCheck
                  : LucideIcons.triangleAlert,
              text: isOvertimePaid
                  ? 'Đơn quá hạn đã thanh toán phí quá giờ. Mời bạn mở ô để lấy đồ và hoàn tất trả tủ.'
                  : 'Đơn đã quá hạn lấy — cần thanh toán phí quá giờ để mở tủ. '
                      '${overtimePolicyText(config)}',
            ),
          ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: opsSurface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: opsBorder),
          ),
          child: Column(
            children: [
              OpsInfoRow(
                icon: LucideIcons.warehouse,
                label: 'Tủ',
                value: lockerName ?? 'Chưa tra được tên tủ',
              ),
              // Địa chỉ nơi đặt tủ — người nhận cần biết đi đâu, không chỉ tủ tên gì.
              if (lockerAddress != null)
                OpsInfoRow(
                  icon: LucideIcons.mapPin,
                  label: 'Địa điểm',
                  value: lockerAddress,
                ),
              // Chỉ hiện SỐ Ô in trên tủ. Trước đây thiếu số ô thì rơi về `sendBoxId`
              // — mã nội bộ — nên màn hình chỉ một con số không có trên tủ thật.
              OpsInfoRow(
                icon: LucideIcons.grid3x3,
                label: 'Ô',
                value: _boxRouteLabel(sendBoxNumber, receiveBoxNumber),
              ),
              if (createdAt != null)
                OpsInfoRow(
                  icon: LucideIcons.calendar,
                  label: 'Ngày đặt',
                  value: fmtDateTime(createdAt),
                ),
              if (isRental && rentalHours != null)
                OpsInfoRow(
                  icon: LucideIcons.timer,
                  label: 'Thời gian thuê',
                  value: '$rentalHours giờ',
                ),
              if (deadline != null)
                OpsInfoRow(
                  icon: LucideIcons.clock,
                  label: 'Hạn ban đầu',
                  value: fmtDateTime(deadline),
                ),
              if (overdue) ...[
                OpsInfoRow(
                  icon: LucideIcons.clockAlert,
                  label: 'Thời gian quá hạn',
                  value: overtimeDurationText.isNotEmpty
                      ? overtimeDurationText
                      : 'Đã quá hạn',
                  valueColor: const Color(0xFFDC2626),
                ),
                OpsInfoRow(
                  icon: LucideIcons.receiptText,
                  label: 'Đơn giá quá giờ',
                  value: '${fmtPrice(config.pickupOvertimeFeePerHour)}/giờ',
                ),
                if (config.pickupMaxOvertimePercent > 0 ||
                    config.pickupMaxOvertimeFee > 0)
                  OpsInfoRow(
                    icon: LucideIcons.shieldAlert,
                    label: 'Quy định trần',
                    value: [
                      if (config.pickupMaxOvertimeFee > 0)
                        'Tối đa ${fmtPrice(config.pickupMaxOvertimeFee)}',
                      if (config.pickupMaxOvertimePercent > 0)
                        '${config.pickupMaxOvertimePercent}% đơn',
                    ].join(' & '),
                  ),
                OpsInfoRow(
                  icon: LucideIcons.circleAlert,
                  label: 'Phí quá giờ tạm tính',
                  value: fmtPrice(overtimeFee),
                  valueColor: const Color(0xFFEA580C),
                ),
                OpsInfoRow(
                  icon: LucideIcons.badgeAlert,
                  label: 'Trạng thái phạt',
                  value: isOvertimePaid ? 'Đã thanh toán' : 'Chưa thanh toán',
                  valueColor: isOvertimePaid
                      ? const Color(0xFF15803D)
                      : const Color(0xFFDC2626),
                ),
                if (needsPayOvertime)
                  OpsInfoRow(
                    icon: LucideIcons.circleDollarSign,
                    label: 'Cần nộp để mở ô',
                    value: fmtPrice(overtimeFee),
                    valueColor: const Color(0xFFDC2626),
                  ),
              ],
              if (receiverLabel.isNotEmpty)
                OpsInfoRow(
                  icon: LucideIcons.userCheck,
                  label: 'Người nhận',
                  value: receiverLabel,
                ),
              if (deliveryAddress != null && deliveryAddress.isNotEmpty)
                OpsInfoRow(
                  icon: LucideIcons.truck,
                  label: 'Địa chỉ giao',
                  value: deliveryAddress,
                ),
              if (hasExtra)
                OpsInfoRow(
                  icon: LucideIcons.circlePlus,
                  label: 'Phí phát sinh',
                  value: fmtPrice(extraFee),
                  valueColor: const Color(0xFFB45309),
                ),
              if (discountAmount > 0)
                OpsInfoRow(
                  icon: LucideIcons.badgePercent,
                  label: 'Giảm giá',
                  value: promotionCode != null && promotionCode.isNotEmpty
                      ? '-${fmtPrice(discountAmount)} ($promotionCode)'
                      : '-${fmtPrice(discountAmount)}',
                  valueColor: const Color(0xFF15803D),
                ),
              OpsInfoRow(
                icon: LucideIcons.wallet,
                label: 'Tổng tiền',
                value: fmtPrice(order['totalPrice']),
                valueColor: opsDark,
              ),
              // Gia hạn / phí quá hạn cộng vào tổng nhưng phần cũ đã trả rồi,
              // nên tách rõ đã trả bao nhiêu và còn thiếu bao nhiêu.
              if (orderAmountDue(order) > 0 &&
                  (_asDouble(order['paidAmount']) ?? 0) > 0) ...[
                OpsInfoRow(
                  icon: LucideIcons.receiptText,
                  label: 'Đã thanh toán',
                  value: fmtPrice(order['paidAmount']),
                  valueColor: const Color(0xFF15803D),
                ),
                OpsInfoRow(
                  icon: LucideIcons.circleDollarSign,
                  label: 'Còn phải trả',
                  value: fmtPrice(orderAmountDue(order)),
                  valueColor: const Color(0xFFB45309),
                ),
              ],
              OpsInfoRow(
                icon: LucideIcons.checkCheck,
                label: 'Thanh toán',
                value: switch (paymentStatus) {
                  'PAID' => 'Đã thanh toán',
                  'REFUNDED' => 'Đã hoàn tiền',
                  _ => 'Chưa thanh toán',
                },
                valueColor: paymentStatus == 'PAID'
                    ? const Color(0xFF15803D)
                    : (paymentStatus == 'REFUNDED'
                          ? const Color(0xFF64748B)
                          : const Color(0xFFB45309)),
              ),
              // Hình thức thanh toán + mã giao dịch lấy từ payment-service.
              _PaymentTraceRows(orderId: _asInt(order['id'])),
              if (customerNote != null && customerNote.isNotEmpty)
                OpsInfoRow(
                  icon: LucideIcons.stickyNote,
                  label: 'Ghi chú',
                  value: customerNote,
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (order['pinCode'] != null && canUsePickupActions)
          Center(
            child: AccessCredentials(
              pin: order['pinCode'] as String?,
              qrToken: order['qrToken'] as String?,
            ),
          ),
        const SizedBox(height: 16),
        ...actions,
        const SizedBox(height: 20),
        const Divider(height: 1, color: opsBorder),
        const SizedBox(height: 12),
        OrderStatusTimeline(orderId: id),
        const SizedBox(height: 8),
      ],
    );
  }
}


/// Hình thức thanh toán + mã giao dịch của đơn.
///
/// `OrderResponse` không mang thông tin này (nằm ở payment-service), nên chi
/// tiết đơn của khách trước đây chỉ có "Đã/Chưa thanh toán" mà không biết trả
/// bằng gì và mã giao dịch nào để đối soát.
class _PaymentTraceRows extends StatefulWidget {
  const _PaymentTraceRows({required this.orderId});

  final int? orderId;

  @override
  State<_PaymentTraceRows> createState() => _PaymentTraceRowsState();
}

class _PaymentTraceRowsState extends State<_PaymentTraceRows> {
  late Future<List<Map<String, dynamic>>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<Map<String, dynamic>>> _load() async {
    final id = widget.orderId;
    if (id == null) return const [];
    try {
      return await LockerOpsService().paymentsByOrder(id);
    } catch (_) {
      // Chi tiết đơn vẫn phải mở được khi payment-service lỗi.
      return const [];
    }
  }

  static String _methodLabel(String? method) => switch (method?.toUpperCase()) {
    'WALLET' => 'Ví Lock.R',
    'SEPAY' => 'Chuyển khoản (SePay)',
    'VNPAY' => 'VNPay',
    'MOMO' => 'MoMo',
    'CASH' => 'Tiền mặt',
    null => '—',
    final other => other,
  };

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _future,
      builder: (context, snapshot) {
        final payments = snapshot.data ?? const <Map<String, dynamic>>[];
        // Chỉ hiện giao dịch đã hoàn tất — giao dịch PENDING/FAILED không phải
        // thứ khách dùng để đối soát.
        final done = payments
            .where((p) => '${p['status']}'.toUpperCase() == 'COMPLETED')
            .toList();
        if (done.isEmpty) return const SizedBox.shrink();

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final p in done) ...[
              OpsInfoRow(
                icon: LucideIcons.creditCard,
                label: 'Hình thức thanh toán',
                value: _methodLabel(p['method'] as String?),
              ),
              OpsInfoRow(
                icon: LucideIcons.hash,
                label: 'Mã giao dịch',
                value: _transactionCode(p),
              ),
              if (p['amount'] != null)
                OpsInfoRow(
                  icon: LucideIcons.banknote,
                  label: 'Số tiền đã trả',
                  value: fmtPrice(p['amount']),
                  valueColor: const Color(0xFF15803D),
                ),
              if (p['createdAt'] != null)
                OpsInfoRow(
                  icon: LucideIcons.calendarCheck,
                  label: 'Thời gian thanh toán',
                  value: fmtDateTime(p['createdAt']),
                ),
            ],
          ],
        );
      },
    );
  }

  static String _transactionCode(Map<String, dynamic> payment) {
    for (final key in ['referenceTransactionId', 'referenceId', 'id']) {
      final value = payment[key];
      if (value != null && '$value'.trim().isNotEmpty) return '$value';
    }
    return '—';
  }
}
