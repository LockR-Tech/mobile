import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:smart_laundry_locker/core/network/api_client.dart';
import 'package:smart_laundry_locker/core/presentation/pages/qr_scanner_page.dart';
import 'package:smart_laundry_locker/core/routing/app_router.dart';
import 'package:smart_laundry_locker/core/services/token_service.dart';
import 'package:smart_laundry_locker/core/theme/shadcn_theme.dart';
import 'package:smart_laundry_locker/features/auth/presentation/providers/auth_injection.dart';
import 'package:smart_laundry_locker/features/auth/presentation/providers/login_provider.dart';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class FaceVerifyPage extends StatefulWidget {
  const FaceVerifyPage({super.key});

  @override
  State<FaceVerifyPage> createState() => _FaceVerifyPageState();
}

class _FaceVerifyPageState extends State<FaceVerifyPage>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  CameraController? _cameraController;
  late final LoginProvider _loginProvider;
  late final AnimationController _scanController;
  late final TabController _tabController;
  late final MobileScannerController _qrScannerController;

  bool _isVerifying = true;
  String? _errorMessage;
  bool _hasTriggeredCapture = false;

  bool _isQrProcessing = false;

  static const double _scanBorderRadius = 28;

  static const double _scanWidthFactor = 0.86;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loginProvider = AuthInjection.provideLoginProvider(ApiClient());
    _loginProvider.addListener(_onLoginStateChanged);

    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_onTabControllerTick);

    _qrScannerController = MobileScannerController(autoStart: false);

    _scanController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);

    unawaited(_initializeAndVerify());
  }

  void _onTabControllerTick() {
    if (_tabController.indexIsChanging) return;
    unawaited(_syncHardwareForTab(_tabController.index));
  }

  Future<void> _syncHardwareForTab(int index) async {
    if (index == 0) {
      await _qrScannerController.stop();
      await _initializeAndVerify();
    } else {
      await _disposeCameraController();
      if (TokenService.authState.value) {
        await _qrScannerController.start();
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _tabController.removeListener(_onTabControllerTick);
    _tabController.dispose();
    _loginProvider.removeListener(_onLoginStateChanged);
    _loginProvider.dispose();
    _scanController.dispose();
    unawaited(_qrScannerController.dispose());
    unawaited(_disposeCameraController());
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached) {
      unawaited(_disposeCameraController());
      unawaited(_qrScannerController.stop());
    }
  }

  Future<void> _disposeCameraController() async {
    final controller = _cameraController;
    _cameraController = null;
    if (controller != null) {
      await controller.dispose();
    }
  }

  Future<void> _onLoginStateChanged() async {
    if (!mounted) return;

    if (_loginProvider.isQrConfirmLoading) return;

    if (_loginProvider.qrConfirmSuccess == true) {
      _isQrProcessing = false;
      if (!mounted) return;
      SmartDialog.showToast('Xác nhận thành công');
      _loginProvider.clearQrLoginState();
      if (_tabController.index == 1) {
        await _qrScannerController.start();
      }
      return;
    }

    if (_loginProvider.qrError != null) {
      final err = _loginProvider.qrError!;
      _isQrProcessing = false;
      await _showQrErrorDialog(err);
      _loginProvider.clearQrLoginState();
      if (mounted && _tabController.index == 1) {
        await _qrScannerController.start();
      }
      return;
    }

    if (_loginProvider.isLoading) return;

    if (_loginProvider.isSuccess) {
      SmartDialog.showToast('Xác thực FaceID thành công');
      await Future<void>.delayed(const Duration(milliseconds: 300));
      if (mounted) context.go(AppRouter.home);
      return;
    }

    if (_loginProvider.isFaceMatched && _loginProvider.matchedUserId != null) {
      SmartDialog.showToast(
        'Nhận diện thành công ID: ${_loginProvider.matchedUserId}',
      );
      setState(() {
        _isVerifying = false;
        _errorMessage = null;
      });
      return;
    }

    if (_loginProvider.error != null) {
      setState(() {
        _isVerifying = false;
        _errorMessage = _loginProvider.error;
      });
      await _showVerifyFailedDialog(_loginProvider.error);
    }
  }

  Future<void> _showQrErrorDialog(String message) async {
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Không thể xác nhận',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Đóng',
                style: TextStyle(color: AISLShadcnTheme.navyPrimary),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _onQrDetected(BarcodeCapture capture) async {
    if (_isQrProcessing) return;
    final barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;
    final code = barcodes.first.rawValue;
    if (code == null || code.isEmpty) return;

    _isQrProcessing = true;
    await _qrScannerController.stop();
    if (!mounted) return;

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Đăng nhập trên trình duyệt',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          content: const Text('Bạn có muốn đăng nhập trên thiết bị này không?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Hủy', style: TextStyle(color: Colors.black87)),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text(
                'Xác nhận',
                style: TextStyle(color: AISLShadcnTheme.navyPrimary),
              ),
            ),
          ],
        );
      },
    );

    if (!mounted) return;

    if (confirmed != true) {
      _isQrProcessing = false;
      await _qrScannerController.start();
      return;
    }

    await _loginProvider.onQrScanned(code);
  }

  Future<void> _initializeAndVerify() async {
    if (!mounted) return;
    setState(() {
      _isVerifying = true;
      _errorMessage = null;
      _hasTriggeredCapture = false;
    });

    try {
      await _disposeCameraController();
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        throw Exception('Không tìm thấy camera trên thiết bị.');
      }
      final selected = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      final controller = CameraController(
        selected,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );
      await controller.initialize();
      if (!mounted) {
        await controller.dispose();
        return;
      }
      // User có thể đã chuyển sang tab QR khi camera đang init — không gán preview Face.
      if (_tabController.index != 0) {
        await controller.dispose();
        return;
      }
      setState(() {
        _cameraController = controller;
      });

      await Future<void>.delayed(const Duration(milliseconds: 800));
      if (!mounted || _hasTriggeredCapture || _tabController.index != 0) {
        if (_tabController.index != 0) {
          await _disposeCameraController();
        }
        return;
      }

      _hasTriggeredCapture = true;
      final imageBytes = await _captureFrameBytes(controller);
      await _loginProvider.loginWithFace(imageBytes: imageBytes);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isVerifying = false;
        _errorMessage = 'Không thể xác thực FaceID. Vui lòng thử lại.';
      });
      await _showVerifyFailedDialog(
        'Không thể mở camera hoặc chụp ảnh xác thực.',
      );
    }
  }

  Future<Uint8List> _captureFrameBytes(CameraController controller) async {
    final XFile file = await controller.takePicture();
    return file.readAsBytes();
  }

  Future<void> _showVerifyFailedDialog([String? message]) async {
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Xác thực thất bại',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: Colors.black87,
            ),
          ),
          content: Text(
            message ?? 'Khuôn mặt không khớp hoặc chưa được đăng ký',
            style: const TextStyle(color: Colors.black87),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _initializeAndVerify();
              },
              child: const Text(
                'Thử lại',
                style: TextStyle(color: AISLShadcnTheme.navyPrimary),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(this.context).pop(false);
              },
              child: const Text(
                'Dùng mật khẩu',
                style: TextStyle(color: Colors.black87),
              ),
            ),
          ],
        );
      },
    );
  }

  ({Rect holeRect, double scanSize}) _scanGeometry(
    Size screen,
    EdgeInsets padding,
  ) {
    final topInset = padding.top + kToolbarHeight + 8;
    final bottomReserve = 200.0 + padding.bottom + 24;
    final availH = math.max(120.0, screen.height - topInset - bottomReserve);

    final targetByWidth = screen.width * _scanWidthFactor;
    var scanSize = math.min(targetByWidth, availH - 8);
    scanSize = scanSize.clamp(200.0, targetByWidth);

    final left = (screen.width - scanSize) / 2;
    final top = topInset + (availH - scanSize) / 2;

    return (
      holeRect: Rect.fromLTWH(left, top, scanSize, scanSize),
      scanSize: scanSize,
    );
  }

  Widget _buildFaceBody(EdgeInsets padding) {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return const Center(
        child: CircularProgressIndicator(
          strokeWidth: 3,
          valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
        ),
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final g = _scanGeometry(
          Size(constraints.maxWidth, constraints.maxHeight),
          padding,
        );
        final preview = _cameraController!.value.previewSize;
        final cameraLayer = preview == null
            ? Positioned.fill(child: CameraPreview(_cameraController!))
            : Positioned.fill(
                child: FittedBox(
                  fit: BoxFit.cover,
                  child: SizedBox(
                    width: preview.height,
                    height: preview.width,
                    child: CameraPreview(_cameraController!),
                  ),
                ),
              );
        return Stack(
          fit: StackFit.expand,
          children: [
            cameraLayer,
            CustomPaint(
              size: Size(constraints.maxWidth, constraints.maxHeight),
              painter: _ScannerDimOverlayPainter(
                holeRect: g.holeRect,
                borderRadius: _scanBorderRadius,
                overlayColor: Colors.transparent,
              ),
            ),
            Positioned(
              left: g.holeRect.left,
              top: g.holeRect.top,
              width: g.scanSize,
              height: g.scanSize,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(_scanBorderRadius),
                child: Stack(
                  clipBehavior: Clip.hardEdge,
                  children: [
                    AnimatedBuilder(
                      animation: _scanController,
                      builder: (context, child) {
                        final t = _scanController.value;
                        final y = t * (g.scanSize - 6);
                        return Positioned(
                          left: 0,
                          right: 0,
                          top: y,
                          child: Container(
                            height: 4,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(2),
                              gradient: LinearGradient(
                                colors: [
                                  Colors.white.withOpacity(0.05),
                                  Colors.white,
                                  Colors.white.withOpacity(0.05),
                                ],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.white.withOpacity(0.45),
                                  blurRadius: 12,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              left: g.holeRect.left,
              top: g.holeRect.top,
              width: g.scanSize,
              height: g.scanSize,
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(_scanBorderRadius),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.95),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.white.withOpacity(0.25),
                        blurRadius: 16,
                        spreadRadius: 0,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              left: 24,
              right: 24,
              bottom: 24 + padding.bottom,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Đang xác thực...',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      shadows: [Shadow(color: Colors.black45, blurRadius: 8)],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Vui lòng nhìn thẳng vào camera và giữ yên điện thoại để hệ thống nhận diện khuôn mặt của bạn.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.white.withOpacity(0.92),
                      height: 1.45,
                      shadows: const [
                        Shadow(color: Colors.black54, blurRadius: 6),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (_isVerifying)
                    const SizedBox(
                      width: 28,
                      height: 28,
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Colors.white,
                        ),
                      ),
                    ),
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 10),
                    Text(
                      _errorMessage!,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.red.shade200,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildQrLoginBody(EdgeInsets padding) {
    return ValueListenableBuilder<bool>(
      valueListenable: TokenService.authState,
      builder: (context, isLoggedIn, _) {
        if (!isLoggedIn) {
          return Center(
            child: Padding(
              padding: EdgeInsets.all(24 + padding.bottom),
              child: const Text(
                'Bạn cần đăng nhập trên ứng dụng để xác nhận đăng nhập web bằng QR.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70, fontSize: 15),
              ),
            ),
          );
        }
        return Stack(
          fit: StackFit.expand,
          children: [
            MobileScanner(
              controller: _qrScannerController,
              onDetect: _onQrDetected,
            ),
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
            if (_loginProvider.isQrConfirmLoading)
              const Positioned.fill(
                child: ColoredBox(
                  color: Colors.black54,
                  child: Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AISLShadcnTheme.navyPrimary,
                      ),
                    ),
                  ),
                ),
              ),
            Positioned(
              left: 24,
              right: 24,
              bottom: 24 + padding.bottom,
              child: Text(
                'Đưa mã QR trên trình duyệt vào khung để quét.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.92),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  shadows: const [Shadow(color: Colors.black54, blurRadius: 6)],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final padding = MediaQuery.paddingOf(context);

    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        centerTitle: true,
        title: const Text(
          'Đăng nhập FaceID / Web',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AISLShadcnTheme.navyPrimary,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white54,
          tabs: const [
            Tab(text: 'Face ID'),
            Tab(text: 'Web (QR)'),
          ],
        ),
      ),
      body: AnimatedBuilder(
        animation: _tabController,
        builder: (context, _) {
          if (_tabController.index == 0) {
            return _buildFaceBody(padding);
          }
          return _buildQrLoginBody(padding);
        },
      ),
    );
  }
}

/// Phủ nền tối, trừ vùng ô quét bo góc.
class _ScannerDimOverlayPainter extends CustomPainter {
  _ScannerDimOverlayPainter({
    required this.holeRect,
    required this.borderRadius,
    required this.overlayColor,
  });

  final Rect holeRect;
  final double borderRadius;
  final Color overlayColor;

  @override
  void paint(Canvas canvas, Size size) {
    final full = Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    final hole = Path()
      ..addRRect(
        RRect.fromRectAndRadius(holeRect, Radius.circular(borderRadius)),
      );
    final overlay = Path.combine(PathOperation.difference, full, hole);
    canvas.drawPath(overlay, Paint()..color = overlayColor);
  }

  @override
  bool shouldRepaint(covariant _ScannerDimOverlayPainter oldDelegate) {
    return oldDelegate.holeRect != holeRect ||
        oldDelegate.borderRadius != borderRadius ||
        oldDelegate.overlayColor != overlayColor;
  }
}
