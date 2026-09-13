import 'dart:async';
import 'package:smart_laundry_locker/core/routing/app_router.dart';
import 'package:smart_laundry_locker/core/theme/shadcn_theme.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:smart_laundry_locker/core/services/token_service.dart';
import 'package:smart_laundry_locker/features/qr_login/presentation/providers/qr_login_provider.dart';
import 'package:smart_laundry_locker/shared/widgets/unauthenticated_placeholder.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:provider/provider.dart';

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
        unawaited(_scannerController.start());
      case AppLifecycleState.inactive:
        unawaited(_scannerController.stop());
    }
  }

  void _onDetect(BarcodeCapture capture) async {
    if (_isProcessing) return;

    final barcodes = capture.barcodes;
    if (barcodes.isNotEmpty) {
      final code = barcodes.first.rawValue;
      if (code != null && code.length > 30) {
        if (!mounted) return;
        setState(() {
          _isProcessing = true;
        });

        SmartDialog.showLoading<void>(msg: 'Đang xác thực...');

        final provider = context.read<QrLoginProvider>();
        final success = await provider.confirmQrLogin(code);

        SmartDialog.dismiss<void>();

        if (success) {
          SmartDialog.showToast('Đăng nhập trên Kiosk thành công!');
          if (mounted) context.pop();
        } else {
          SmartDialog.showToast('Đăng nhập thất bại: ${provider.error}');
          if (mounted) {
            setState(() {
              _isProcessing = false;
            });
          }
        }
      }
    }
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
                onPressed: () => context.pop(),
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
              'Quét mã QR Kiosk',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            centerTitle: true,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => context.pop(),
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
                onPressed: () => context.go(AppRouter.home),
              ),
            ],
          ),
          body: Stack(
            children: [
              MobileScanner(
                controller: _scannerController,
                onDetect: _onDetect,
                errorBuilder: (context, error) {
                  return Center(
                    child: Text(
                      'Lỗi Camera: ${error.errorCode}',
                      style: const TextStyle(color: Colors.red),
                    ),
                  );
                },
              ),
              // Overlay layer for QR scanning frame
              Positioned.fill(
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
            ],
          ),
        );
      },
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
