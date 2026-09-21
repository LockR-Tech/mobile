import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:smart_laundry_locker/core/services/locker_ble_service.dart';
import 'package:smart_laundry_locker/features/locker_ops/presentation/widgets/locker_qr_scanner_dialog.dart';
import 'package:smart_laundry_locker/features/locker_ops/presentation/widgets/ops_widgets.dart';

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
/// 1. Bluetooth BLE (Proximity 1-chạm kèm chế độ mô phỏng Demo)
/// 2. Quét mã QR dán trên thân tủ
/// 3. Mã PIN / OTP nhập trực tiếp trên màn hình Kiosk
class LockerUnlockModal extends StatefulWidget {
  final String lockerName;
  final String lockerCode;
  final int lockerId;
  final int boxId;
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
    required this.boxId,
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
    required int boxId,
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
    });

    final res = await LockerBleService.instance.scanForLocker(
      expectedLockerCode: widget.lockerCode,
      expectedLockerId: widget.lockerId,
      timeout: const Duration(seconds: 3),
    );

    if (!mounted) return;
    setState(() {
      _isBleScanning = false;
      _bleResult = res;
      if (res == null) {
        _bleError = 'Chưa phát hiện sóng Bluetooth của tủ gần đây.';
      }
    });
  }

  void _triggerSimulationMode() {
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
                      'Mở ${widget.boxLabel}',
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
                          'Đơn thuê đã quá hạn. Đã ghi nhận xử lý phí quá giờ — mời bạn lấy đồ và đóng tủ để hoàn tất trả tủ.',
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
              child: const Row(
                children: [
                  Icon(LucideIcons.triangleAlert, color: Color(0xFFD97706), size: 16),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Mở ô sẽ kết thúc kỳ thuê và giải phóng ô tủ. Vui lòng lấy hết đồ.',
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
                  label: 'Quét QR',
                ),
                _buildTabItem(
                  index: 2,
                  icon: LucideIcons.keyRound,
                  label: 'Mã PIN',
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
                const Text(
                  'Đang quét sóng Bluetooth của tủ...',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5, color: opsDark),
                ),
                const SizedBox(height: 4),
                Text(
                  'Vui lòng đứng cách tủ ${widget.lockerName} dưới 2m',
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
                              const Flexible(
                                child: Text(
                                  'Đã kết nối Bluetooth tủ',
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
                                  child: const Text(
                                    'Mô phỏng RPi',
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
                            'Khoảng cách: ${result.proximityText} • Tín hiệu ${result.rssi} dBm',
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
              widget.isRentalReturning ? 'Mở ${widget.boxLabel} & Trả tủ' : 'Mở ${widget.boxLabel} ngay (1-chạm)',
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
                  _bleError ?? 'Không tìm thấy sóng Bluetooth của tủ',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5, color: opsDark),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Đảm bảo điện thoại đã bật Bluetooth hoặc dùng Quét mã QR thay thế.',
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
                  label: const Text('Quét lại', style: TextStyle(fontSize: 13)),
                  onPressed: _startBleScan,
                ),
              ),
              const SizedBox(width: 10),
              // NÚT MÔ PHỎNG RPi DÀNH CHO DEMO KHI CHƯA GẮN PHẦN CỨNG
              Expanded(
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF6366F1),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(LucideIcons.sparkles, size: 16),
                  label: const Text('Mô phỏng RPi', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                  onPressed: _triggerSimulationMode,
                ),
              ),
            ],
          ),
        ],

        if (result != null && result.isNearby) ...[
          const SizedBox(height: 8),
          Center(
            child: TextButton.icon(
              icon: const Icon(LucideIcons.refreshCw, size: 14),
              label: const Text('Dò sóng lại', style: TextStyle(fontSize: 12.5)),
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
                    const Text(
                      'Xác thực qua tem QR trên tủ',
                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5, color: Color(0xFF92400E)),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Dùng camera điện thoại quét mã QR dán trên thân tủ ${widget.lockerName} để mở ${widget.boxLabel}.',
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
          label: const Text('Bật Camera quét tem QR', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
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
              const Text(
                'MÃ PIN MỞ TRÊN MÀN HÌNH KIOSK',
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
                  _copiedPin ? 'Đã sao chép mã' : 'Sao chép mã PIN',
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
              const Text('Hướng dẫn mở tại màn hình Kiosk:', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: opsDark)),
              const SizedBox(height: 6),
              _buildStepItem('1', 'Đến trước màn hình cảm ứng của ${widget.lockerName}.'),
              _buildStepItem('2', 'Chọn nút "Mở tủ" hoặc "Nhận đồ".'),
              _buildStepItem('3', 'Nhập mã PIN ${widget.pinCode} để cửa ${widget.boxLabel} bung chốt.'),
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
