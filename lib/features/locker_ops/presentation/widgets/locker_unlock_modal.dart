import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:permission_handler/permission_handler.dart' show openAppSettings;
import 'package:smart_laundry_locker/core/services/locker_ble_service.dart';
import 'package:smart_laundry_locker/features/locker_ops/presentation/widgets/locker_qr_scanner_dialog.dart';
import 'package:smart_laundry_locker/features/locker_ops/presentation/widgets/ops_widgets.dart';
import 'package:smart_laundry_locker/core/l10n/l10n.dart';

/// Kết quả người dùng chọn hành động từ Modal mở tủ
enum LockerUnlockActionType {
  openViaBle,
  openViaQr,
  viewPinOnly,
}

class LockerUnlockActionResult {
  final LockerUnlockActionType type;
  final bool isSimulated;

  const LockerUnlockActionResult({
    required this.type,
    this.isSimulated = false,
  });
}

/// Modal hiện đại hỗ trợ 3 phương thức mở tủ:
/// 1. Bluetooth BLE (Proximity 1-chạm; chế độ mô phỏng chỉ có ở bản debug)
/// 2. Quét mã QR dán trên thân tủ
/// 3. Mã PIN / OTP nhập trực tiếp trên màn hình Kiosk
class LockerUnlockModal extends StatefulWidget {
  final String lockerName;
  final String lockerCode;
  final int lockerId;

  /// Ô cần mở; có thể chưa biết khi mở bằng mã (server tự tra ô theo mã).
  final int? boxId;
  final String boxLabel;
  final String pinCode;
  final bool isRentalReturning;
  final bool isOverdue;
  final String? overdueNotice;

  const LockerUnlockModal({
    super.key,
    required this.lockerName,
    required this.lockerCode,
    required this.lockerId,
    this.boxId,
    required this.boxLabel,
    required this.pinCode,
    this.isRentalReturning = false,
    this.isOverdue = false,
    this.overdueNotice,
  });

  static Future<LockerUnlockActionResult?> show(
    BuildContext context, {
    required String lockerName,
    required String lockerCode,
    required int lockerId,
    int? boxId,
    required String boxLabel,
    required String pinCode,
    bool isRentalReturning = false,
    bool isOverdue = false,
    String? overdueNotice,
  }) {
    return showModalBottomSheet<LockerUnlockActionResult>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => LockerUnlockModal(
        lockerName: lockerName,
        lockerCode: lockerCode,
        lockerId: lockerId,
        boxId: boxId,
        boxLabel: boxLabel,
        pinCode: pinCode,
        isRentalReturning: isRentalReturning,
        isOverdue: isOverdue,
        overdueNotice: overdueNotice,
      ),
    );
  }

  @override
  State<LockerUnlockModal> createState() => _LockerUnlockModalState();
}

class _LockerUnlockModalState extends State<LockerUnlockModal> with SingleTickerProviderStateMixin {
  int _selectedTab = 0; // 0: Bluetooth, 1: Quét QR, 2: Mã PIN Kiosk

  // BLE State
  bool _isBleScanning = false;
  LockerBleDetectionResult? _bleResult;
  String? _bleError;
  // Quyền Bluetooth bị chặn hẳn: chỉ mở lại được trong Cài đặt của máy.
  bool _blePermissionBlocked = false;

  // PIN copy feedback
  bool _copiedPin = false;

  @override
  void initState() {
    super.initState();
    _startBleScan();
  }

  @override
  void dispose() {
    LockerBleService.instance.stopScan();
    super.dispose();
  }

  Future<void> _startBleScan() async {
    if (!mounted) return;
    setState(() {
      _isBleScanning = true;
      _bleError = null;
      _blePermissionBlocked = false;
    });

    final problem = await LockerBleService.instance.readinessProblem();
    if (!mounted) return;
    if (problem != null) {
      setState(() {
        _isBleScanning = false;
        _bleResult = null;
        _blePermissionBlocked = problem == 'PERMISSION_BLOCKED';
        _bleError = switch (problem) {
          'PERMISSION_BLOCKED' =>
            context.l10n.unlockBlePermissionBlocked,
          'PERMISSION_DENIED' =>
            context.l10n.unlockBlePermissionDenied,
          'BLUETOOTH_OFF' =>
            context.l10n.unlockBleOff,
          _ => context.l10n.unlockBleUnsupported,
        };
      });
      return;
    }

    final res = await LockerBleService.instance.scanForLocker(
      expectedLockerCode: widget.lockerCode,
      expectedLockerId: widget.lockerId,
      timeout: const Duration(seconds: 4),
    );

    if (!mounted) return;
    setState(() {
      _isBleScanning = false;
      _bleResult = res;
      if (res == null) {
        _bleError = context.l10n.unlockNoSignal;
      }
    });
  }

  /// Giả lập phát hiện tủ — chỉ để thử trên bản debug khi chưa có phần cứng;
  /// bản phát hành không có nút này.
  void _triggerSimulationMode() {
    if (!kDebugMode) return;
    setState(() {
      _isBleScanning = false;
      _bleError = null;
      _bleResult = LockerBleService.createSimulatedResult(
        lockerCode: widget.lockerCode,
        lockerName: widget.lockerName,
      );
    });
  }

  Future<void> _openViaQr() async {
    final scannedOk = await LockerQrScannerDialog.show(
      context,
      expectedLockerCode: widget.lockerCode,
      expectedLockerId: widget.lockerId,
      lockerName: widget.lockerName,
      boxLabel: widget.boxLabel,
    );

    if (scannedOk == true && mounted) {
      Navigator.pop(
        context,
        const LockerUnlockActionResult(type: LockerUnlockActionType.openViaQr),
      );
    }
  }

  void _copyPin() {
    Clipboard.setData(ClipboardData(text: widget.pinCode));
    setState(() => _copiedPin = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _copiedPin = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
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
          // Drag handle
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

          // Header
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: opsPrimary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Image.asset(
                  'assets/images/mobile_pay_3d.png',
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => const Icon(
                    LucideIcons.smartphone,
                    color: opsPrimary,
                    size: 26,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.l10n.unlockOpenBox(widget.boxLabel),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: opsDark,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.lockerName,
                      style: const TextStyle(
                        fontSize: 13,
                        color: opsMutedText,
                        fontWeight: FontWeight.w500,
                      ),
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
          ),

          if (widget.isOverdue) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFFECACA)),
              ),
              child: Row(
                children: [
                  const Icon(LucideIcons.clockAlert, size: 16, color: Color(0xFFDC2626)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.overdueNotice ??
                          context.l10n.unlockOverdueRental,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF991B1B),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          if (widget.isRentalReturning) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFFDE68A)),
              ),
              child: Row(
                children: [
                  Icon(LucideIcons.triangleAlert, color: Color(0xFFD97706), size: 16),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      context.l10n.unlockEndsRental,
                      style: TextStyle(fontSize: 12, color: Color(0xFF92400E), fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 18),

          // Segmented Tabs: 3 Methods
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: opsSurface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: opsBorder),
            ),
            child: Row(
              children: [
                _buildTabItem(
                  index: 0,
                  icon: LucideIcons.bluetooth,
                  label: 'Bluetooth',
                ),
                _buildTabItem(
                  index: 1,
                  icon: LucideIcons.scanLine,
                  label: context.l10n.unlockScanQr,
                ),
                _buildTabItem(
                  index: 2,
                  icon: LucideIcons.keyRound,
                  label: context.l10n.unlockPin,
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Tab Content Area
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            child: _buildCurrentTabContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildTabItem({
    required int index,
    required IconData icon,
    required String label,
  }) {
    final isSelected = _selectedTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() => _selectedTab = index);
          if (index == 0 && _bleResult == null && !_isBleScanning) {
            _startBleScan();
          }
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 2),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    )
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 15,
                color: isSelected ? opsPrimary : opsMutedText,
              ),
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected ? opsDark : opsMutedText,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentTabContent() {
    switch (_selectedTab) {
      case 0:
        return _buildBluetoothTab();
      case 1:
        return _buildQrTab();
      case 2:
      default:
        return _buildPinTab();
    }
  }

  // -------------------------------------------------------------
  // TAB 1: BLUETOOTH BLE
  // -------------------------------------------------------------
  Widget _buildBluetoothTab() {
    final result = _bleResult;

    return Column(
      key: const ValueKey(0),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_isBleScanning) ...[
          Container(
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
                  context.l10n.unlockScanning,
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5, color: opsDark),
                ),
                const SizedBox(height: 4),
                Text(
                  context.l10n.unlockStandClose(widget.lockerName),
                  style: const TextStyle(fontSize: 12.5, color: opsMutedText),
                ),
              ],
            ),
          ),
        ] else if (result != null && result.isNearby) ...[
          // ĐÃ PHÁT HIỆN TỦ GẦN (HOẶC MÔ PHỎNG)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF0FDF4),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFBBF7D0)),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDCFCE7),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(LucideIcons.bluetooth, color: Color(0xFF16A34A), size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  context.l10n.unlockConnected,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 14.5,
                                    color: Color(0xFF15803D),
                                  ),
                                ),
                              ),
                              if (result.isSimulated) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFEF3C7),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    context.l10n.unlockSimulateRpi,
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFFB45309),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            context.l10n.unlockDistanceSignal(result.proximityText, result.rssi),
                            style: const TextStyle(fontSize: 12, color: Color(0xFF166534)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.1, end: 0),
          const SizedBox(height: 16),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF16A34A),
              padding: const EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            icon: const Icon(LucideIcons.doorOpen, size: 22),
            label: Text(
              widget.isRentalReturning ? context.l10n.unlockOpenAndReturn(widget.boxLabel) : context.l10n.unlockOpenNow(widget.boxLabel),
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15.5),
            ),
            onPressed: () {
              Navigator.pop(
                context,
                LockerUnlockActionResult(
                  type: LockerUnlockActionType.openViaBle,
                  isSimulated: result.isSimulated,
                ),
              );
            },
          ),
        ] else ...[
          // KHÔNG TÌM THẤY BLUETOOTH
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: opsSurface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: opsBorder),
            ),
            child: Column(
              children: [
                const Icon(LucideIcons.bluetoothOff, color: opsMutedText, size: 30),
                const SizedBox(height: 10),
                Text(
                  _bleError ?? context.l10n.unlockNotFound,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5, color: opsDark),
                ),
                const SizedBox(height: 4),
                Text(
                  context.l10n.unlockEnsureBluetooth,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: opsMutedText),
                ),
              ],
            ),
          ),
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
                  label: Text(context.l10n.unlockScanAgain, style: TextStyle(fontSize: 13)),
                  onPressed: _startBleScan,
                ),
              ),
              if (_blePermissionBlocked) ...[
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(LucideIcons.settings, size: 16),
                    label: Text(context.l10n.commonOpenSettings, style: TextStyle(fontSize: 13)),
                    onPressed: openAppSettings,
                  ),
                ),
              ],
              // Nút mô phỏng chỉ có ở bản debug (thử khi chưa gắn phần cứng).
              if (kDebugMode) ...[
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF6366F1),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(LucideIcons.sparkles, size: 16),
                    label: Text(context.l10n.unlockSimulateRpi, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                    onPressed: _triggerSimulationMode,
                  ),
                ),
              ],
            ],
          ),
        ],

        if (result != null && result.isNearby) ...[
          const SizedBox(height: 8),
          Center(
            child: TextButton.icon(
              icon: const Icon(LucideIcons.refreshCw, size: 14),
              label: Text(context.l10n.unlockRescan, style: TextStyle(fontSize: 12.5)),
              onPressed: _startBleScan,
            ),
          ),
        ],
      ],
    );
  }

  // -------------------------------------------------------------
  // TAB 2: QUÉT MÃ QR TRÊN THÂN TỦ
  // -------------------------------------------------------------
  Widget _buildQrTab() {
    return Column(
      key: const ValueKey(1),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: const Color(0xFFFEF3C7),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFFDE68A)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(LucideIcons.scanLine, color: Color(0xFFD97706), size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.l10n.unlockQrTitle,
                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5, color: Color(0xFF92400E)),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      context.l10n.unlockQrBody(widget.lockerName, widget.boxLabel),
                      style: const TextStyle(fontSize: 12.5, color: Color(0xFFB45309)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          style: FilledButton.styleFrom(
            backgroundColor: opsPrimary,
            padding: const EdgeInsets.symmetric(vertical: 15),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          icon: const Icon(LucideIcons.camera, size: 20),
          label: Text(context.l10n.unlockStartCamera, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
          onPressed: _openViaQr,
        ),
      ],
    );
  }

  // -------------------------------------------------------------
  // TAB 3: MÃ PIN / OTP NHẬP TRÊN KIOSK
  // -------------------------------------------------------------
  Widget _buildPinTab() {
    final pinDigits = widget.pinCode.trim().split('');

    return Column(
      key: const ValueKey(2),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
          decoration: BoxDecoration(
            color: opsSurface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: opsBorder),
          ),
          child: Column(
            children: [
              Text(
                context.l10n.unlockKioskPinUpper,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                  color: opsMutedText,
                ),
              ),
              const SizedBox(height: 14),

              // PIN Digit boxes
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: pinDigits.map((d) {
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: 44,
                      height: 52,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: opsPrimary, width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: opsPrimary.withValues(alpha: 0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        d,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: opsDark,
                          fontFamily: 'monospace',
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),

              const SizedBox(height: 14),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                icon: Icon(
                  _copiedPin ? LucideIcons.check : LucideIcons.copy,
                  size: 15,
                  color: _copiedPin ? const Color(0xFF16A34A) : opsDark,
                ),
                label: Text(
                  _copiedPin ? context.l10n.unlockCodeCopied : context.l10n.unlockCopyPin,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: _copiedPin ? const Color(0xFF16A34A) : opsDark,
                  ),
                ),
                onPressed: _copyPin,
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Hướng dẫn 3 bước
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: opsBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(context.l10n.unlockKioskGuide, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: opsDark)),
              const SizedBox(height: 6),
              _buildStepItem('1', context.l10n.unlockKioskStep1(widget.lockerName)),
              _buildStepItem('2', context.l10n.unlockKioskStep2),
              _buildStepItem('3', context.l10n.unlockKioskStep3(widget.pinCode, widget.boxLabel)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStepItem(String num, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              color: opsPrimary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              num,
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: opsPrimary),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 12.5, color: opsMutedText, height: 1.3),
            ),
          ),
        ],
      ),
    );
  }
}
