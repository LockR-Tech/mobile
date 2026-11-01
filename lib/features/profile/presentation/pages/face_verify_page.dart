import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:smart_laundry_locker/core/config/feature_flags.dart';
import 'package:smart_laundry_locker/core/network/api_client.dart';
import 'package:smart_laundry_locker/core/routing/app_router.dart';
import 'package:smart_laundry_locker/core/theme/shadcn_theme.dart';
import 'package:smart_laundry_locker/features/auth/presentation/providers/auth_injection.dart';
import 'package:smart_laundry_locker/features/auth/presentation/providers/login_provider.dart';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:smart_laundry_locker/core/l10n/l10n.dart';

/// Đăng nhập bằng khuôn mặt (chỉ khi `FeatureFlags.faceRecognitionEnabled`).
///
/// Tab "Web (QR)" cũ (xác nhận đăng nhập web qua `/api/auth/qr-login/confirm`)
/// đã bỏ: đăng nhập kiosk bằng QR nằm ở nút quét QR trên trang chủ.
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

  bool _isVerifying = true;
  String? _errorMessage;
  bool _hasTriggeredCapture = false;

  static const double _scanBorderRadius = 28;

  static const double _scanWidthFactor = 0.86;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loginProvider = AuthInjection.provideLoginProvider(ApiClient());
    _loginProvider.addListener(_onLoginStateChanged);

    _scanController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);

    // Backend chưa có AI service ⇒ không mở camera, chỉ báo chưa hỗ trợ.
    if (FeatureFlags.faceRecognitionEnabled) {
      unawaited(_initializeAndVerify());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _loginProvider.removeListener(_onLoginStateChanged);
    _loginProvider.dispose();
    _scanController.dispose();
    unawaited(_disposeCameraController());
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached) {
      unawaited(_disposeCameraController());
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

    if (_loginProvider.isLoading) return;

    if (_loginProvider.isSuccess) {
      SmartDialog.showToast(context.l10n.fvSuccess);
      await Future<void>.delayed(const Duration(milliseconds: 300));
      if (mounted) await AppRouter.goRoleHome(context);
      return;
    }

    if (_loginProvider.isFaceMatched && _loginProvider.matchedUserId != null) {
      SmartDialog.showToast(
        context.l10n.fvMatched('${_loginProvider.matchedUserId}'),
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
        throw Exception(L10n.current.frNoCamera);
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
      setState(() {
        _cameraController = controller;
      });

      await Future<void>.delayed(const Duration(milliseconds: 800));
      if (!mounted || _hasTriggeredCapture) return;

      _hasTriggeredCapture = true;
      final imageBytes = await _captureFrameBytes(controller);
      await _loginProvider.loginWithFace(imageBytes: imageBytes);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isVerifying = false;
        _errorMessage = context.l10n.fvFailedRetry;
      });
      await _showVerifyFailedDialog(
        context.l10n.fvCameraError,
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
          title: Text(
            context.l10n.fvFailed,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: Colors.black87,
            ),
          ),
          content: Text(
            message ?? context.l10n.authFaceMismatch,
            style: const TextStyle(color: Colors.black87),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _initializeAndVerify();
              },
              child: Text(
                context.l10n.commonRetry,
                style: TextStyle(color: AISLShadcnTheme.navyPrimary),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(this.context).pop(false);
              },
              child: Text(
                context.l10n.fvUsePassword,
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
                  Text(
                    context.l10n.fvVerifying,
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
                    context.l10n.fvLookStraight,
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
        title: Text(
          context.l10n.authFaceLogin,
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: FeatureFlags.faceRecognitionEnabled
          ? _buildFaceBody(padding)
          : Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      context.l10n.fvNotSupported,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () => AppRouter.backOrHome(context),
                      child: Text(
                        context.l10n.commonBack,
                        style: TextStyle(color: AISLShadcnTheme.navyPrimary),
                      ),
                    ),
                  ],
                ),
              ),
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
