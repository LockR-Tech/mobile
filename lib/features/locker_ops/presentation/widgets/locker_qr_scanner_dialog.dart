import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:smart_laundry_locker/core/presentation/pages/qr_scanner_page.dart'
    show QrScannerOverlayShape;
import 'package:smart_laundry_locker/core/theme/shadcn_theme.dart';

class LockerQrScannerDialog extends StatefulWidget {
  const LockerQrScannerDialog({
    super.key,
    required this.expectedLockerCode,
    this.expectedLockerId,
    this.lockerName,
    this.boxLabel,
  });

  final String expectedLockerCode;
  final int? expectedLockerId;
  final String? lockerName;
  final String? boxLabel;

  static Future<bool?> show(
    BuildContext context, {
    required String expectedLockerCode,
    int? expectedLockerId,
    String? lockerName,
    String? boxLabel,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useRootNavigator: true,
      builder: (ctx) => LockerQrScannerDialog(
        expectedLockerCode: expectedLockerCode,
        expectedLockerId: expectedLockerId,
        lockerName: lockerName,
        boxLabel: boxLabel,
      ),
    );
  }

  @override
  State<LockerQrScannerDialog> createState() => _LockerQrScannerDialogState();
}

class _LockerQrScannerDialogState extends State<LockerQrScannerDialog> {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    facing: CameraFacing.back,
    torchEnabled: false,
  );

  bool _isProcessing = false;
  String? _errorMessage;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool _matchesLocker(String raw) {
    final clean = raw.trim().toUpperCase();
    final targetCode = widget.expectedLockerCode.trim().toUpperCase();

    // 1. Khớp trực tiếp mã tủ (VD: "LOC-01-001" hoặc URL/JSON chứa "LOC-01-001")
    if (targetCode.isNotEmpty && clean.contains(targetCode)) {
      return true;
    }

    // 2. Khớp ID tủ nếu có (VD: "1", "lockerId=1", "/lockers/1", {"lockerId": 1})
    if (widget.expectedLockerId != null) {
      final idStr = '${widget.expectedLockerId}';
      if (clean == idStr ||
          clean.contains('LOCKERID=$idStr') ||
          clean.contains('LOCKERID:$idStr') ||
          clean.contains('LOCKERID":$idStr') ||
          clean.contains('LOCKERID": $idStr') ||
          clean.contains('LOCKER/$idStr') ||
          clean.contains('/LOCKERS/$idStr')) {
        return true;
      }
    }

    return false;
  }

  void _onDetect(BarcodeCapture capture) async {
    if (_isProcessing) return;

    final barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;
    final code = barcodes.first.rawValue;
    if (code == null || code.trim().isEmpty) return;

    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    if (_matchesLocker(code)) {
      HapticFeedback.mediumImpact();
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } else {
      HapticFeedback.vibrate();
      setState(() {
        _errorMessage =
            'Mã QR không khớp với ${widget.lockerName ?? 'tủ này'}.\nVui lòng quét đúng mã QR dán trên thân tủ.';
      });
      // Đợi 2.5s để người dùng đọc thông báo lỗi rồi cho phép quét lại
      await Future<void>.delayed(const Duration(milliseconds: 2500));
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _errorMessage = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final lockerLabel = widget.lockerName ?? 'Tủ Lock.R';
    final boxLabel = widget.boxLabel ?? 'ô tủ';

    return Container(
      height: size.height * 0.88,
      decoration: const BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Camera View
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
          ),

          // Dark overlay with transparent center cutout
          Positioned.fill(
            child: Container(
              decoration: ShapeDecoration(
                shape: QrScannerOverlayShape(
                  borderColor: AISLShadcnTheme.navyPrimary,
                  borderRadius: 16,
                  borderLength: 42,
                  borderWidth: 5,
                  cutOutSize: size.width * 0.72,
                ),
              ),
            ),
          ),

          // Header
          Positioned(
            top: 12,
            left: 16,
            right: 16,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.black45,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: IconButton(
                    icon: const Icon(LucideIcons.x, color: Colors.white, size: 20),
                    onPressed: () => Navigator.of(context).pop(false),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(LucideIcons.scanLine, color: Colors.white, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        'Quét mở $boxLabel',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.black45,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: ValueListenableBuilder<MobileScannerState>(
                    valueListenable: _controller,
                    builder: (context, state, _) {
                      final isTorchOn = state.torchState == TorchState.on;
                      return IconButton(
                        icon: Icon(
                          isTorchOn ? LucideIcons.flashlightOff : LucideIcons.flashlight,
                          color: isTorchOn ? Colors.amber : Colors.white,
                          size: 20,
                        ),
                        onPressed: () => _controller.toggleTorch(),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          // Instruction card at bottom
          Positioned(
            bottom: 24,
            left: 20,
            right: 20,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_errorMessage != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDC2626).withValues(alpha: 0.92),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        const Icon(LucideIcons.triangleAlert, color: Colors.white, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              height: 1.35,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.black87,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: Colors.white24, width: 1),
                  ),
                  child: Column(
                    children: [
                      Text(
                        lockerLabel,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Mã tủ: ${widget.expectedLockerCode}',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Hướng camera về phía tem mã QR dán trên mặt tủ để xác thực bạn đang đứng tại tủ.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white60,
                          fontSize: 12,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
