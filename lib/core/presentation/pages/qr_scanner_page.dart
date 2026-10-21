import 'dart:async';
import 'package:smart_laundry_locker/core/routing/app_router.dart';
import 'package:smart_laundry_locker/core/theme/shadcn_theme.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:smart_laundry_locker/core/services/token_service.dart';
import 'package:smart_laundry_locker/features/qr_login/domain/kiosk_qr_payload.dart';
import 'package:smart_laundry_locker/features/qr_login/presentation/providers/qr_login_provider.dart';
import 'package:smart_laundry_locker/shared/widgets/unauthenticated_placeholder.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:provider/provider.dart';

/// Quét mã QR trên màn hình kiosk để đăng nhập tài khoản Lock.R tại tủ
/// (CONTRACTS §1): QR `lockr://kiosk-login?sid=&code=` ⇒ hỏi xác nhận ⇒ gửi
/// `confirmCode` lên server. Không dùng được camera thì nhập tay mã phiên + mã
/// xác nhận.
class QrScannerPage extends StatefulWidget {
  const QrScannerPage({super.key});

  @override
  State<QrScannerPage> createState() => _QrScannerPageState();
}

class _QrScannerPageState extends State<QrScannerPage>
    with WidgetsBindingObserver {
  final MobileScannerController _scannerController = MobileScannerController(
    autoStart: false,
  );
  bool _isProcessing = false;

  /// QR không hợp lệ: chỉ báo lại khi camera thấy mã khác, hoặc sau vài giây,
  /// để không bắn thông báo liên tục khi camera vẫn chĩa vào cùng một mã.
  String? _lastInvalidRaw;
  DateTime? _lastInvalidAt;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    TokenService.authState.addListener(_onAuthStateChanged);
    _onAuthStateChanged();
  }

  void _onAuthStateChanged() {
    if (TokenService.authState.value && mounted) {
      unawaited(_scannerController.start());
    } else {
      unawaited(_scannerController.stop());
    }
  }

  @override
  void dispose() {
    TokenService.authState.removeListener(_onAuthStateChanged);
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_scannerController.dispose());
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_scannerController.value.hasCameraPermission) {
      return;
    }

    switch (state) {
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
        return;
      case AppLifecycleState.resumed:
        if (!_isProcessing) unawaited(_scannerController.start());
      case AppLifecycleState.inactive:
        unawaited(_scannerController.stop());
    }
  }

  void _onDetect(BarcodeCapture capture) {
    if (_isProcessing) return;
    final raw = capture.barcodes.isEmpty ? null : capture.barcodes.first.rawValue;
    if (raw == null || raw.trim().isEmpty) return;

    final payload = KioskQrPayload.tryParse(raw);
    if (payload == null) {
      _reportInvalidQr(raw);
      return;
    }
    unawaited(_confirmAndLogin(payload));
  }

  void _reportInvalidQr(String raw) {
    final now = DateTime.now();
    final last = _lastInvalidAt;
    if (raw == _lastInvalidRaw &&
        last != null &&
        now.difference(last) < const Duration(seconds: 4)) {
      return;
    }
    _lastInvalidRaw = raw;
    _lastInvalidAt = now;
    SmartDialog.showToast(
      'Đây không phải mã đăng nhập kiosk Lock.R. Hãy quét mã QR đang hiện trên màn hình tủ.',
      displayTime: const Duration(seconds: 3),
    );
  }

  /// Hỏi lại khách trước khi đăng nhập — tránh vô tình đăng nhập hộ người khác
  /// khi quét nhầm mã trên một kiosk lạ.
  Future<void> _confirmAndLogin(KioskQrPayload payload) async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);
    unawaited(_scannerController.stop());

    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _KioskLoginConfirmSheet(payload: payload),
    );
    if (!mounted) return;
    if (ok != true) {
      _resumeScanning();
      return;
    }

    final provider = context.read<QrLoginProvider>();
    SmartDialog.showLoading<void>(msg: 'Đang xác nhận đăng nhập kiosk...');
    final result = await provider.confirmKioskLogin(payload);
    SmartDialog.dismiss<void>(status: SmartStatus.loading);
    if (!mounted) return;

    if (result != null) {
      final where = result.lockerName == null ? '' : ' tại ${result.lockerName}';
      SmartDialog.showToast('Đã đăng nhập trên kiosk$where');
      AppRouter.backOrHome(context);
      return;
    }

    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Chưa đăng nhập được kiosk'),
        content: Text(
          provider.error ?? 'Không xác nhận được đăng nhập kiosk. Vui lòng thử lại.',
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Đã hiểu'),
          ),
        ],
      ),
    );
    if (mounted) _resumeScanning();
  }

  void _resumeScanning() {
    setState(() => _isProcessing = false);
    if (TokenService.authState.value) unawaited(_scannerController.start());
  }

  Future<void> _openManualEntry() async {
    if (_isProcessing) return;
    final payload = await showModalBottomSheet<KioskQrPayload>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _ManualKioskCodeSheet(),
    );
    if (payload != null && mounted) await _confirmAndLogin(payload);
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: TokenService.authState,
      builder: (context, isLoggedIn, child) {
        if (!isLoggedIn) {
          return Scaffold(
            backgroundColor: Colors.white,
            appBar: AppBar(
              backgroundColor: Colors.white,
              elevation: 0,
              centerTitle: true,
              title: const Text(
                'Quét mã QR',
                style: TextStyle(
                  color: Colors.black87,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.black87),
                onPressed: () => AppRouter.backOrHome(context),
              ),
            ),
            body: const UnauthenticatedPlaceholder(
              message: 'Bạn cần đăng nhập để quét mã QR',
            ),
          );
        }

        return Scaffold(
          extendBodyBehindAppBar: true,
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: const Text(
              'Đăng nhập kiosk bằng QR',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            centerTitle: true,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => AppRouter.backOrHome(context),
            ),
            actions: [
              IconButton(
                icon: ValueListenableBuilder<MobileScannerState>(
                  valueListenable: _scannerController,
                  builder: (context, state, child) {
                    switch (state.torchState) {
                      case TorchState.off:
                        return const Icon(Icons.flash_off, color: Colors.grey);
                      case TorchState.on:
                        return const Icon(Icons.flash_on, color: Colors.yellow);
                      case TorchState.auto:
                        return const Icon(Icons.flash_auto, color: Colors.blue);
                      case TorchState.unavailable:
                        return const Icon(Icons.flash_off, color: Colors.red);
                    }
                  },
                ),
                onPressed: () => _scannerController.toggleTorch(),
              ),
              IconButton(
                icon: const Icon(LucideIcons.house, color: Colors.white),
                onPressed: () => AppRouter.goRoleHome(context),
              ),
            ],
          ),
          body: Stack(
            children: [
              MobileScanner(
                controller: _scannerController,
                onDetect: _onDetect,
                errorBuilder: (context, error) {
                  return _CameraErrorView(
                    error: error,
                    onManualEntry: _openManualEntry,
                  );
                },
              ),
              // Overlay layer for QR scanning frame
              Positioned.fill(
                child: IgnorePointer(
                  child: Container(
                    decoration: ShapeDecoration(
                      shape: QrScannerOverlayShape(
                        borderColor: AISLShadcnTheme.navyPrimary,
                        borderRadius: 12,
                        borderLength: 40,
                        borderWidth: 4,
                        cutOutSize: 280,
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 20,
                right: 20,
                bottom: MediaQuery.of(context).padding.bottom + 28,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Đưa khung vào mã QR trên màn hình kiosk. Bạn sẽ được hỏi lại trước khi đăng nhập.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white, fontSize: 13, height: 1.4),
                    ),
                    const SizedBox(height: 14),
                    OutlinedButton.icon(
                      key: const ValueKey('kiosk-qr-manual-entry'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white70),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 12,
                        ),
                      ),
                      onPressed: _isProcessing ? null : _openManualEntry,
                      icon: const Icon(LucideIcons.keyboard, size: 18),
                      label: const Text('Nhập mã thủ công'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _CameraErrorView extends StatelessWidget {
  const _CameraErrorView({required this.error, required this.onManualEntry});

  final MobileScannerException error;
  final VoidCallback onManualEntry;

  @override
  Widget build(BuildContext context) {
    final message = switch (error.errorCode) {
      MobileScannerErrorCode.permissionDenied =>
        'Ứng dụng chưa được cấp quyền camera. Hãy cấp quyền trong cài đặt máy hoặc nhập mã thủ công.',
      MobileScannerErrorCode.unsupported =>
        'Thiết bị không hỗ trợ quét mã bằng camera. Hãy nhập mã thủ công.',
      _ => 'Không mở được camera. Hãy thử lại hoặc nhập mã thủ công.',
    };
    return Container(
      color: Colors.black,
      alignment: Alignment.center,
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(LucideIcons.cameraOff, color: Colors.white70, size: 44),
          const SizedBox(height: 14),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.4),
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: onManualEntry,
            icon: const Icon(LucideIcons.keyboard, size: 18),
            label: const Text('Nhập mã thủ công'),
          ),
        ],
      ),
    );
  }
}

/// Sheet "Đăng nhập kiosk?" — hiện mã xác nhận để khách đối chiếu với màn hình tủ.
class _KioskLoginConfirmSheet extends StatelessWidget {
  const _KioskLoginConfirmSheet({required this.payload});

  final KioskQrPayload payload;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        MediaQuery.of(context).padding.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 18),
          const Icon(
            LucideIcons.monitorSmartphone,
            size: 40,
            color: AISLShadcnTheme.navyPrimary,
          ),
          const SizedBox(height: 12),
          const Text(
            'Đăng nhập kiosk?',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          const Text(
            'Tài khoản Lock.R của bạn sẽ được đăng nhập trên kiosk vừa hiện mã. '
            'Chỉ xác nhận khi bạn đang đứng trước kiosk đó.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13.5, color: Color(0xFF475569), height: 1.4),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                const Text(
                  'Mã xác nhận trên kiosk',
                  style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                ),
                const SizedBox(height: 4),
                Text(
                  payload.confirmCode,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 4,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          FilledButton(
            key: const ValueKey('kiosk-qr-confirm'),
            style: FilledButton.styleFrom(
              backgroundColor: AISLShadcnTheme.navyPrimary,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Đăng nhập kiosk'),
          ),
          const SizedBox(height: 6),
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Huỷ'),
          ),
        ],
      ),
    );
  }
}

/// Nhập tay mã phiên + mã xác nhận đang hiện trên kiosk (khi không dùng được camera).
class _ManualKioskCodeSheet extends StatefulWidget {
  const _ManualKioskCodeSheet();

  @override
  State<_ManualKioskCodeSheet> createState() => _ManualKioskCodeSheetState();
}

class _ManualKioskCodeSheetState extends State<_ManualKioskCodeSheet> {
  final _sidController = TextEditingController();
  final _codeController = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _sidController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  void _submit() {
    final payload = KioskQrPayload.fromParts(
      _sidController.text,
      _codeController.text,
    );
    if (payload == null) {
      setState(
        () => _error =
            'Mã chưa đúng. Kiểm tra lại mã phiên và mã xác nhận đang hiện trên kiosk.',
      );
      return;
    }
    Navigator.pop(context, payload);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        MediaQuery.of(context).viewInsets.bottom +
            MediaQuery.of(context).padding.bottom +
            20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Nhập mã đăng nhập kiosk',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            const Text(
              'Nhập mã phiên và mã xác nhận đang hiện dưới mã QR trên màn hình kiosk.',
              style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 14),
            TextField(
              key: const ValueKey('kiosk-qr-sid'),
              controller: _sidController,
              autocorrect: false,
              decoration: const InputDecoration(
                labelText: 'Mã phiên',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              key: const ValueKey('kiosk-qr-code'),
              controller: _codeController,
              autocorrect: false,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(
                labelText: 'Mã xác nhận',
                border: OutlineInputBorder(),
              ),
              onSubmitted: (_) => _submit(),
            ),
            if (_error != null) ...[
              const SizedBox(height: 10),
              Text(
                _error!,
                style: const TextStyle(color: Color(0xFFDC2626), fontSize: 12.5),
              ),
            ],
            const SizedBox(height: 16),
            FilledButton(
              key: const ValueKey('kiosk-qr-manual-submit'),
              style: FilledButton.styleFrom(
                backgroundColor: AISLShadcnTheme.navyPrimary,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: _submit,
              child: const Text('Tiếp tục'),
            ),
          ],
        ),
      ),
    );
  }
}

// Custom overlay shape for the QR scanner
class QrScannerOverlayShape extends ShapeBorder {
  /// Constructor
  const QrScannerOverlayShape({
    this.borderColor = Colors.red,
    this.borderWidth = 3.0,
    this.overlayColor = Colors.transparent,
    this.borderRadius = 0,
    this.borderLength = 40,
    this.cutOutSize = 250,
    this.cutOutBottomOffset = 0,
  });

  /// Border color
  final Color borderColor;

  /// Border width
  final double borderWidth;

  /// Overlay color
  final Color overlayColor;

  /// Border radius
  final double borderRadius;

  /// Border length
  final double borderLength;

  /// Cutout size
  final double cutOutSize;

  /// Cutout bottom offset
  final double cutOutBottomOffset;

  @override
  EdgeInsetsGeometry get dimensions => const EdgeInsets.all(10);

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) {
    return Path()
      ..fillType = PathFillType.evenOdd
      ..addPath(getOuterPath(rect), Offset.zero);
  }

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    Path getLeftTopPath(Rect rect) {
      return Path()
        ..moveTo(rect.left, rect.bottom)
        ..lineTo(rect.left, rect.top)
        ..lineTo(rect.right, rect.top);
    }

    return getLeftTopPath(rect)
      ..lineTo(rect.right, rect.bottom)
      ..lineTo(rect.left, rect.bottom)
      ..lineTo(rect.left, rect.top);
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    final width = rect.width;
    final height = rect.height;
    final cutOutWidth = cutOutSize;
    final cutOutHeight = cutOutSize;

    final backgroundPaint = Paint()
      ..color = overlayColor
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth;

    final boxPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.fill
      ..blendMode = BlendMode.dstOut;

    final cutOutRect = Rect.fromLTWH(
      rect.left + width / 2 - cutOutWidth / 2,
      rect.top + height / 2 - cutOutHeight / 2 - cutOutBottomOffset,
      cutOutWidth,
      cutOutHeight,
    );

    canvas
      ..saveLayer(rect, backgroundPaint)
      ..drawRect(rect, backgroundPaint)
      ..drawRRect(
        RRect.fromRectAndCorners(
          cutOutRect,
          topLeft: Radius.circular(borderRadius),
          topRight: Radius.circular(borderRadius),
          bottomLeft: Radius.circular(borderRadius),
          bottomRight: Radius.circular(borderRadius),
        ),
        boxPaint,
      )
      ..restore();

    final path = Path();

    // Top-left
    path.moveTo(cutOutRect.left, cutOutRect.top + borderLength);
    path.lineTo(cutOutRect.left, cutOutRect.top + borderRadius);
    path.arcToPoint(
      Offset(cutOutRect.left + borderRadius, cutOutRect.top),
      radius: Radius.circular(borderRadius),
    );
    path.lineTo(cutOutRect.left + borderLength, cutOutRect.top);

    // Top-right
    path.moveTo(cutOutRect.right - borderLength, cutOutRect.top);
    path.lineTo(cutOutRect.right - borderRadius, cutOutRect.top);
    path.arcToPoint(
      Offset(cutOutRect.right, cutOutRect.top + borderRadius),
      radius: Radius.circular(borderRadius),
    );
    path.lineTo(cutOutRect.right, cutOutRect.top + borderLength);

    // Bottom-right
    path.moveTo(cutOutRect.right, cutOutRect.bottom - borderLength);
    path.lineTo(cutOutRect.right, cutOutRect.bottom - borderRadius);
    path.arcToPoint(
      Offset(cutOutRect.right - borderRadius, cutOutRect.bottom),
      radius: Radius.circular(borderRadius),
    );
    path.lineTo(cutOutRect.right - borderLength, cutOutRect.bottom);

    // Bottom-left
    path.moveTo(cutOutRect.left + borderLength, cutOutRect.bottom);
    path.lineTo(cutOutRect.left + borderRadius, cutOutRect.bottom);
    path.arcToPoint(
      Offset(cutOutRect.left, cutOutRect.bottom - borderRadius),
      radius: Radius.circular(borderRadius),
    );
    path.lineTo(cutOutRect.left, cutOutRect.bottom - borderLength);

    canvas.drawPath(path, borderPaint);
  }

  @override
  ShapeBorder scale(double t) {
    return QrScannerOverlayShape(
      borderColor: borderColor,
      borderWidth: borderWidth,
      overlayColor: overlayColor,
    );
  }
}
