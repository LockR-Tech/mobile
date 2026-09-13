import 'dart:async';
import 'dart:math' as math;

import 'package:smart_laundry_locker/core/network/api_client.dart';
import 'package:smart_laundry_locker/core/theme/shadcn_theme.dart';
import 'package:smart_laundry_locker/features/auth/presentation/providers/auth_injection.dart';
import 'package:smart_laundry_locker/features/auth/presentation/providers/face_registration_provider.dart';
import 'package:smart_laundry_locker/features/profile/presentation/providers/profile_provider.dart';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class FaceRegistrationPage extends StatefulWidget {
  const FaceRegistrationPage({super.key});

  @override
  State<FaceRegistrationPage> createState() => _FaceRegistrationPageState();
}

class _FaceRegistrationPageState extends State<FaceRegistrationPage>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  CameraController? _cameraController;
  late final FaceRegistrationProvider _registrationProvider;
  late final AnimationController _scanController;

  bool _isCapturing = false;
  String? _errorMessage;

  static const double _scanBorderRadius = 28;
  static const double _scanWidthFactor = 0.86;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _registrationProvider = AuthInjection.provideFaceRegistrationProvider(
      ApiClient(),
    );
    _registrationProvider.addListener(_onStateChanged);

    _scanController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);

    unawaited(_initializeCamera());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _registrationProvider.removeListener(_onStateChanged);
    _registrationProvider.dispose();
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
    } else if (state == AppLifecycleState.resumed) {
      unawaited(_initializeCamera());
    }
  }

  Future<void> _disposeCameraController() async {
    final controller = _cameraController;
    _cameraController = null;
    if (controller != null) {
      await controller.dispose();
    }
  }

  Future<void> _onStateChanged() async {
    if (!mounted) return;

    if (_registrationProvider.isLoading) return;

    if (_registrationProvider.isSuccess) {
      SmartDialog.showToast('Đăng ký khuôn mặt thành công');
      // Refresh profile to update registration status
      if (mounted) {
        final profileProvider = context.read<ProfileProvider>();
        unawaited(profileProvider.loadProfile());
      }
      await Future<void>.delayed(const Duration(milliseconds: 500));
      if (mounted) context.pop();
      return;
    }

    if (_registrationProvider.error != null) {
      setState(() {
        _isCapturing = false;
        _errorMessage = _registrationProvider.error;
      });
      await _showDialog(
        title: 'Đăng ký thất bại',
        message: _registrationProvider.error!,
        isError: true,
      );
    }
  }

  Future<void> _initializeCamera() async {
    if (!mounted) return;
    setState(() {
      _errorMessage = null;
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
      setState(() {
        _cameraController = controller;
      });
      // Pre-load sounds or other assets if needed
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage =
            'Không thể mở camera. Vui lòng kiểm tra quyền truy cập.';
      });
    }
  }

  Future<void> _captureAndRegister() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized)
      return;
    if (_isCapturing) return;

    setState(() {
      _isCapturing = true;
      _errorMessage = null;
    });

    _registrationProvider.clearSamples();

    try {
      final profileProvider = context.read<ProfileProvider>();
      final userId = profileProvider.profile?.id;

      if (userId == null) {
        throw Exception('Không tìm thấy thông tin người dùng');
      }

      for (int i = 0; i < FaceRegistrationProvider.requiredSamples; i++) {
        if (!mounted) return;

        // Visual feedback for each capture?
        // FlutterSmartDialog or simple update
        final XFile file = await _cameraController!.takePicture();
        final bytes = await file.readAsBytes();

        _registrationProvider.addSample(bytes);

        // UI already updates via listener/notifyListeners
        await Future<void>.delayed(const Duration(milliseconds: 300));
      }

      // Step 2: Register
      if (mounted) {
        await _registrationProvider.registerFace(userId: userId);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isCapturing = false;
        _errorMessage = 'Lỗi trong quá trình chụp ảnh và đăng ký: $e';
      });
    }
  }

  Future<void> _showDialog({
    required String title,
    required String message,
    bool isError = false,
  }) async {
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Đóng',
                style: TextStyle(
                  color: isError ? Colors.red : AISLShadcnTheme.navyPrimary,
                ),
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
          'Đăng ký khuôn mặt',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: _buildBody(padding),
    );
  }

  Widget _buildBody(EdgeInsets padding) {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return const Center(
        child: CircularProgressIndicator(
          strokeWidth: 3,
          valueColor: AlwaysStoppedAnimation<Color>(
            AISLShadcnTheme.navyPrimary,
          ),
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

        return Stack(
          fit: StackFit.expand,
          children: [
            // Camera Preview
            if (preview != null)
              Positioned.fill(
                child: FittedBox(
                  fit: BoxFit.cover,
                  child: SizedBox(
                    width: preview.height,
                    height: preview.width,
                    child: CameraPreview(_cameraController!),
                  ),
                ),
              )
            else
              Positioned.fill(child: CameraPreview(_cameraController!)),

            // Dim Background
            CustomPaint(
              size: Size(constraints.maxWidth, constraints.maxHeight),
              painter: _ScannerDimOverlayPainter(
                holeRect: g.holeRect,
                borderRadius: _scanBorderRadius,
                overlayColor: Colors.transparent,
              ),
            ),

            // Scan Animation
            Positioned(
              left: g.holeRect.left,
              top: g.holeRect.top,
              width: g.scanSize,
              height: g.scanSize,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(_scanBorderRadius),
                child: Stack(
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

            // Scan Border
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
                  ),
                ),
              ),
            ),

            // Instructions and Action
            Positioned(
              left: 24,
              right: 24,
              bottom: 40 + padding.bottom,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Lấy mẫu khuôn mặt',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Giữ điện thoại thẳng trước mặt và nhấn nút bên dưới để bắt đầu đăng ký.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                  const SizedBox(height: 32),
                  if (_isCapturing || _registrationProvider.isLoading)
                    Column(
                      children: [
                        CircularProgressIndicator(
                          value: _isCapturing
                              ? _registrationProvider.sampleCount /
                                    FaceRegistrationProvider.requiredSamples
                              : null,
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            AISLShadcnTheme.navyPrimary,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _isCapturing
                              ? 'Đang chụp ảnh: ${_registrationProvider.sampleCount}/${FaceRegistrationProvider.requiredSamples}'
                              : 'Đang xử lý đăng ký...',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    )
                  else
                    ElevatedButton(
                      onPressed: _captureAndRegister,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AISLShadcnTheme.navyPrimary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 48,
                          vertical: 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: const Text(
                        'Bắt đầu quét',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      _errorMessage!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.redAccent,
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
}

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
