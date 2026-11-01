import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:smart_laundry_locker/core/presentation/pages/qr_scanner_page.dart'
    show QrScannerOverlayShape;
import 'package:smart_laundry_locker/core/theme/shadcn_theme.dart';
import 'package:smart_laundry_locker/shared/widgets/controller_disposer.dart';
import 'package:smart_laundry_locker/core/l10n/l10n.dart';

/// Nội dung quét được (hoặc gõ tay) có đúng là tủ [expectedId] / [expectedCode]
/// không. So khớp CHÍNH XÁC, không dùng `contains` — "LOC-1" không được khớp
/// "LOC-12", tủ 1 không được khớp tủ 17.
///
/// Nhận các dạng:
/// - Tem QR của admin: JSON `{"type":"LOCKER_BOX","lockerId":7,"lockerCode":"CAB-TU01",…}`.
///   Có `lockerId` thì id phải đúng (kèm `lockerCode` thì mã cũng phải đúng).
/// - Liên kết `lockr://…?lockerId=7`, `https://…/lockers/7`.
/// - Chuỗi trần: mã tủ (không phân biệt hoa thường) hoặc id tủ.
bool lockerQrMatches(
  String raw, {
  required String expectedCode,
  int? expectedId,
}) {
  final text = raw.trim();
  if (text.isEmpty) return false;
  final code = expectedCode.trim().toUpperCase();

  bool codeEq(Object? v) =>
      code.isNotEmpty && v != null && '$v'.trim().toUpperCase() == code;
  bool idEq(Object? v) =>
      expectedId != null && v != null && int.tryParse('$v'.trim()) == expectedId;

  if (text.startsWith('{')) {
    try {
      final decoded = jsonDecode(text);
      if (decoded is! Map) return false;
      final id = decoded['lockerId'];
      final c = decoded['lockerCode'] ?? decoded['code'];
      if (id != null && expectedId != null) {
        return idEq(id) && (c == null || code.isEmpty || codeEq(c));
      }
      return codeEq(c);
    } catch (_) {
      return false;
    }
  }

  final uri = Uri.tryParse(text);
  const linkSchemes = {'http', 'https', 'lockr'};
  if (uri != null && linkSchemes.contains(uri.scheme.toLowerCase())) {
    final qId = uri.queryParameters['lockerId'];
    if (qId != null) return idEq(qId);
    final qCode = uri.queryParameters['lockerCode'] ?? uri.queryParameters['code'];
    if (qCode != null) return codeEq(qCode);
    final segments = uri.pathSegments;
    final i = segments.indexWhere(
      (seg) => seg.toLowerCase() == 'lockers' || seg.toLowerCase() == 'locker',
    );
    if (i >= 0 && i + 1 < segments.length) {
      return idEq(segments[i + 1]) || codeEq(segments[i + 1]);
    }
    return false;
  }

  return codeEq(text) || idEq(text);
}

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

  bool _matchesLocker(String raw) => lockerQrMatches(
    raw,
    expectedCode: widget.expectedLockerCode,
    expectedId: widget.expectedLockerId,
  );

  /// Không dùng được camera (hỏng, thiếu sáng, chưa cấp quyền): gõ mã tủ in
  /// trên thân tủ.
  Future<void> _enterCodeManually() async {
    final ctrl = TextEditingController();
    String? error;
    final matched = await showDialog<bool>(
      context: context,
      builder: (ctx) => ControllerDisposer(
        controllers: [ctrl],
        child: StatefulBuilder(
          builder: (ctx, setLocal) {
            void submit() {
              if (_matchesLocker(ctrl.text)) {
                Navigator.pop(ctx, true);
              } else {
                setLocal(
                  () => error = ctrl.text.trim().isEmpty
                      ? context.l10n.qrEnterLockerCode
                      : context.l10n.qrLockerCodeMismatch(widget.lockerName ?? context.l10n.qrThisLocker),
                );
              }
            }

            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              title: Text(context.l10n.qrEnterLockerCodeTitle),
              content: TextField(
                controller: ctrl,
                autofocus: true,
                textCapitalization: TextCapitalization.characters,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => submit(),
                decoration: InputDecoration(
                  hintText: context.l10n.qrLockerCodeHint,
                  errorText: error,
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: Text(context.l10n.commonCancel),
                ),
                FilledButton(onPressed: submit, child: Text(context.l10n.commonConfirm)),
              ],
            );
          },
        ),
      ),
    );
    if (matched == true && mounted) {
      HapticFeedback.mediumImpact();
      Navigator.of(context).pop(true);
    }
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
            context.l10n.qrCodeMismatch(widget.lockerName ?? context.l10n.qrThisLocker);
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
    final lockerLabel = widget.lockerName ?? context.l10n.ordLockrLocker;
    final boxLabel = widget.boxLabel ?? context.l10n.qrLockerBoxGeneric;

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
                        context.l10n.qrScanToOpen(boxLabel),
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
                        context.l10n.qrLockerCodeValue('${widget.expectedLockerCode}'),
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        context.l10n.qrPointCamera,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white60,
                          fontSize: 12,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextButton.icon(
                        onPressed: _isProcessing ? null : _enterCodeManually,
                        icon: const Icon(
                          LucideIcons.keyboard,
                          size: 16,
                          color: Colors.white,
                        ),
                        label: Text(
                          context.l10n.qrCantScan,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                          ),
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
