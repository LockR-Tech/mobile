import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:permission_handler/permission_handler.dart' show openAppSettings;
import 'package:smart_laundry_locker/core/l10n/l10n.dart';
import 'package:smart_laundry_locker/core/services/app_event_bus.dart';
import 'package:smart_laundry_locker/core/services/locker_ble_open_service.dart';
import 'package:smart_laundry_locker/features/locker_ops/data/locker_ops_service.dart';
import 'package:smart_laundry_locker/features/locker_ops/presentation/widgets/locker_qr_scanner_dialog.dart';
import 'package:smart_laundry_locker/features/locker_ops/presentation/widgets/ops_widgets.dart';

/// Ghi mã cho Pi qua BLE — mặc định là [LockerBleOpenService]; test thay bằng hàm giả.
typedef BleOpener = Future<BleOpenOutcome> Function(
  BleOpenTicket ticket,
  void Function(BleOpenStep step) onStep,
);

/// Quét tem QR dán trên tủ; `true` = đúng tủ. Mặc định là [LockerQrScannerDialog].
typedef LockerQrScan = Future<bool?> Function(BuildContext context);

/// Mở ô theo ĐƠN qua Bluetooth (F3-G11): xin mã của đơn ⇒ ghi thẳng cho Pi.
/// Server chỉ coi là "đã mở" khi Pi báo về (kèm nonce), nên app làm mới đơn ngay và thêm một lần
/// sau [lateRefreshDelay].
class OrderBleOpen {
  OrderBleOpen._();

  /// Thay đường BLE thật trong test widget của các màn có nút "Mở ô".
  @visibleForTesting
  static BleOpener? debugOpener;

  static const lateRefreshDelay = Duration(seconds: 2);

  static BleOpener get defaultOpener =>
      debugOpener ?? (ticket, onStep) => LockerBleOpenService.instance.open(ticket, onStep: onStep);

  static String stepLabel(BleOpenStep step) => switch (step) {
        BleOpenStep.scanning => L10n.current.btScanning,
        BleOpenStep.connecting => L10n.current.btConnecting,
        BleOpenStep.sending => L10n.current.btSending,
        BleOpenStep.waiting => L10n.current.btWaiting,
      };

  /// Lỗi xin mã là lỗi nghiệp vụ (đơn chưa thanh toán, hết hạn thuê, không đúng người…): mở bằng
  /// mã ở kiosk hay quét QR cũng sẽ bị chặn y hệt nên không gợi ý cách khác. Mất mạng / máy chủ
  /// chưa có API thì vẫn cho chọn cách khác.
  static bool isBlockingTokenError(Object error) {
    if (LockerOpsService.isEndpointUnavailable(error)) return false;
    final code = LockerOpsService.errorCode(error);
    return code != null && code.isNotEmpty;
  }

  /// Làm mới ngay rồi thêm một lần sau [lateRefreshDelay] (chờ Pi báo về server) và phát
  /// [OrderChangedEvent] cho các màn khác đang nghe.
  static Future<void> refreshAfterOpen({
    required int orderId,
    Future<void> Function()? reload,
  }) async {
    if (reload != null) await reload();
    unawaited(Future<void>.delayed(lateRefreshDelay, () async {
      AppEventBus.instance.emit(OrderChangedEvent(orderId: '$orderId'));
      if (reload != null) await reload();
    }));
  }
}

/// Ô đã mở bằng cách nào.
enum OrderOpenMethod {
  /// Ô ĐÃ mở qua Bluetooth — bên gọi chỉ cần báo và làm mới đơn.
  bluetooth,

  /// Khách đã quét đúng tem QR trên tủ — bên gọi mở từ xa qua Internet (`/api/iot/unlock…`).
  lockerQr,
}

class OrderOpenResult {
  const OrderOpenResult(this.method, {this.boxNumber});

  final OrderOpenMethod method;

  /// Số ô Pi báo đã mở ([OrderOpenMethod.bluetooth]).
  final int? boxNumber;
}

/// Bảng mở ô của MỘT đơn — sau nút "Mở ô" duy nhất của mỗi màn. Mở ra là thử Bluetooth thật
/// ngay (hiện từng bước), không hỏi trước. Chỉ khi Bluetooth không được mới cho chọn:
/// "Quét mã QR" (tem trên tủ ⇒ mở từ xa) hoặc "Dùng mã OTP" (PIN + mã QR của đơn cho kiosk),
/// kèm "Thử lại Bluetooth".
///
/// Trả `null` khi khách đóng bảng mà chưa mở (kể cả khi chỉ xem mã OTP để dùng ở kiosk).
class OrderOpenSheet extends StatefulWidget {
  const OrderOpenSheet({
    super.key,
    required this.orderId,
    required this.lockerName,
    required this.lockerCode,
    required this.lockerId,
    required this.boxLabel,
    this.pin,
    this.qrToken,
    this.isRentalReturning = false,
    this.isOverdue = false,
    this.overdueNotice,
    this.service,
    this.opener,
    this.scanQr,
  });

  final int orderId;
  final String lockerName;
  final String lockerCode;
  final int lockerId;
  final String boxLabel;
  final String? pin;
  final String? qrToken;
  final bool isRentalReturning;
  final bool isOverdue;
  final String? overdueNotice;

  /// Cho test thay API / BLE / máy quét.
  final LockerOpsService? service;
  final BleOpener? opener;
  final LockerQrScan? scanQr;

  static Future<OrderOpenResult?> show(
    BuildContext context, {
    required int orderId,
    required String lockerName,
    required String lockerCode,
    required int lockerId,
    required String boxLabel,
    String? pin,
    String? qrToken,
    bool isRentalReturning = false,
    bool isOverdue = false,
    String? overdueNotice,
    LockerOpsService? service,
    BleOpener? opener,
    LockerQrScan? scanQr,
  }) {
    return showModalBottomSheet<OrderOpenResult>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => OrderOpenSheet(
        orderId: orderId,
        lockerName: lockerName,
        lockerCode: lockerCode,
        lockerId: lockerId,
        boxLabel: boxLabel,
        pin: pin,
        qrToken: qrToken,
        isRentalReturning: isRentalReturning,
        isOverdue: isOverdue,
        overdueNotice: overdueNotice,
        service: service,
        opener: opener,
        scanQr: scanQr,
      ),
    );
  }

  @override
  State<OrderOpenSheet> createState() => _OrderOpenSheetState();
}

class _OrderOpenSheetState extends State<OrderOpenSheet> {
  late final LockerOpsService _service = widget.service ?? LockerOpsService();

  /// Lượt thử hiện tại — kết quả của lượt cũ (khách bấm thử lại) bị bỏ qua.
  int _attempt = 0;
  bool _running = true;
  String _stepText = L10n.current.btFetchingCode;
  String? _failure;
  String? _failureCode;
  bool _blocking = false;
  bool _showOtp = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _start();
    });
  }

  Future<void> _start() async {
    final attempt = ++_attempt;
    bool current() => mounted && attempt == _attempt;
    setState(() {
      _running = true;
      _stepText = L10n.current.btFetchingCode;
      _failure = null;
      _failureCode = null;
      _blocking = false;
      _showOtp = false;
    });

    final BleOpenTicket ticket;
    try {
      ticket = BleOpenTicket.fromJson(await _service.bleOrderToken(widget.orderId));
    } catch (e) {
      if (!current()) return;
      setState(() {
        _running = false;
        _failure = LockerOpsService.errorMessage(e);
        _blocking = OrderBleOpen.isBlockingTokenError(e);
      });
      return;
    }

    BleOpenOutcome outcome;
    try {
      final opener = widget.opener ?? OrderBleOpen.defaultOpener;
      outcome = await opener(ticket, (step) {
        if (current()) setState(() => _stepText = OrderBleOpen.stepLabel(step));
      });
    } catch (e) {
      debugPrint('[OrderOpenSheet] open failed: $e');
      outcome = const BleOpenOutcome.failed('UNSUPPORTED');
    }
    if (!mounted || attempt != _attempt) return;
    if (outcome.isOk) {
      Navigator.pop(
        context,
        OrderOpenResult(OrderOpenMethod.bluetooth, boxNumber: outcome.boxNumber ?? ticket.boxNumber),
      );
      return;
    }
    setState(() {
      _running = false;
      _failure = outcome.message;
      _failureCode = outcome.error;
    });
  }

  Future<void> _scanLockerQr() async {
    final scan = widget.scanQr ??
        (ctx) => LockerQrScannerDialog.show(
              ctx,
              expectedLockerCode: widget.lockerCode,
              expectedLockerId: widget.lockerId,
              lockerName: widget.lockerName,
              boxLabel: widget.boxLabel,
            );
    final ok = await scan(context);
    if (ok == true && mounted) {
      Navigator.pop(context, const OrderOpenResult(OrderOpenMethod.lockerQr));
    }
  }

  bool get _isAndroid => !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
  bool get _isIos => !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        left: 20,
        right: 20,
        top: 12,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          _header(),
          if (widget.isOverdue) ...[
            const SizedBox(height: 10),
            OpsBanner(
              tone: OpsBannerTone.danger,
              icon: LucideIcons.clockAlert,
              text: widget.overdueNotice ?? context.l10n.unlockOverdueRental,
            ),
          ],
          if (widget.isRentalReturning) ...[
            const SizedBox(height: 10),
            OpsBanner(
              tone: OpsBannerTone.warning,
              icon: LucideIcons.triangleAlert,
              text: context.l10n.unlockEndsRental,
            ),
          ],
          const SizedBox(height: 18),
          if (_running) _progress() else _fallback(),
        ],
      ),
    );
  }

  Widget _header() {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: opsPrimary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(LucideIcons.doorOpen, color: opsPrimary, size: 24),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.l10n.unlockOpenBox(widget.boxLabel),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: opsDark),
              ),
              const SizedBox(height: 2),
              Text(
                widget.lockerName,
                style: const TextStyle(fontSize: 13, color: opsMutedText, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(LucideIcons.x, color: opsMutedText, size: 20),
          visualDensity: VisualDensity.compact,
        ),
      ],
    );
  }

  Widget _progress() {
    return Container(
      key: const ValueKey('order-ble-progress'),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: opsSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: opsBorder),
      ),
      child: Column(
        children: [
          const SizedBox(
            width: 42,
            height: 42,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(opsPrimary),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            _stepText,
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5, color: opsDark),
          ),
          const SizedBox(height: 4),
          Text(
            context.l10n.bleOrderIntro,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12.5, color: opsMutedText),
          ),
        ],
      ),
    );
  }

  Widget _fallback() {
    final code = _failureCode;
    final hasPin = (widget.pin ?? '').isNotEmpty;
    return Column(
      key: const ValueKey('order-ble-fallback'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        OpsBanner(
          tone: OpsBannerTone.danger,
          icon: LucideIcons.bluetoothOff,
          title: context.l10n.bleOrderNotOpened,
          text: _failure ?? '',
        ),
        if (code == 'BLUETOOTH_OFF' && _isIos) ...[
          const SizedBox(height: 8),
          Text(
            context.l10n.bleOrderTurnOnIos,
            style: const TextStyle(fontSize: 12.5, color: opsMutedText, height: 1.35),
          ),
        ],
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(LucideIcons.refreshCw, size: 16),
                label: Text(context.l10n.bleOrderRetry, style: const TextStyle(fontSize: 13)),
                onPressed: _start,
              ),
            ),
            // Android bật được Bluetooth từ app (LockerBleOpenService xin bật trước khi quét).
            if (code == 'BLUETOOTH_OFF' && _isAndroid) ...[
              const SizedBox(width: 10),
              Expanded(
                child: _smallFilled(context.l10n.bleOrderTurnOn, LucideIcons.bluetooth, _start),
              ),
            ],
            if (code == 'PERMISSION_DENIED') ...[
              const SizedBox(width: 10),
              Expanded(
                child: _smallFilled(context.l10n.commonOpenSettings, LucideIcons.settings, openAppSettings),
              ),
            ],
          ],
        ),
        if (!_blocking) ...[
          const SizedBox(height: 18),
          Text(
            context.l10n.bleOrderOtherWays,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: opsDark),
          ),
          const SizedBox(height: 10),
          _choice(
            key: const ValueKey('order-open-qr'),
            icon: LucideIcons.scanLine,
            title: context.l10n.bleOrderUseQr,
            body: context.l10n.bleOrderUseQrBody,
            onTap: _scanLockerQr,
          ),
          if (hasPin) ...[
            const SizedBox(height: 10),
            _choice(
              key: const ValueKey('order-open-otp'),
              icon: LucideIcons.keyRound,
              title: context.l10n.bleOrderUseOtp,
              body: context.l10n.bleOrderUseOtpBody,
              selected: _showOtp,
              onTap: () => setState(() => _showOtp = !_showOtp),
            ),
            if (_showOtp) ...[
              const SizedBox(height: 16),
              Center(
                child: AccessCredentials(
                  pin: widget.pin,
                  qrToken: widget.qrToken,
                  showQr: true,
                  showSuccessAnimation: false,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                context.l10n.bleOrderKioskBody,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12.5, color: opsMutedText, height: 1.35),
              ),
            ],
          ],
        ],
      ],
    );
  }

  Widget _smallFilled(String label, IconData icon, VoidCallback onPressed) {
    return FilledButton.icon(
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      icon: Icon(icon, size: 16),
      label: Text(label, style: const TextStyle(fontSize: 13)),
      onPressed: onPressed,
    );
  }

  Widget _choice({
    required Key key,
    required IconData icon,
    required String title,
    required String body,
    required VoidCallback onTap,
    bool selected = false,
  }) {
    return Material(
      key: key,
      color: selected ? opsPrimary.withValues(alpha: 0.06) : Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: selected ? opsPrimary : opsBorder, width: selected ? 1.5 : 1),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: opsPrimary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: opsPrimary, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5, color: opsDark),
                    ),
                    const SizedBox(height: 2),
                    Text(body, style: const TextStyle(fontSize: 12.5, color: opsMutedText, height: 1.3)),
                  ],
                ),
              ),
              const Icon(LucideIcons.chevronRight, color: opsMutedText, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}
