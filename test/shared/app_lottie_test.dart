import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lottie/lottie.dart';
import 'package:smart_laundry_locker/shared/widgets/app_lottie.dart';

/// Mọi asset Lottie được UI tham chiếu qua [AppLottieAssets].
const _assets = <String, String>{
  'box': AppLottieAssets.box,
  'airplaneBox': AppLottieAssets.airplaneBox,
  'cuaHang': AppLottieAssets.cuaHang,
  'thueTu': AppLottieAssets.thueTu,
  'donTu': AppLottieAssets.donTu,
  'uuDai': AppLottieAssets.uuDai,
  'baoSuCo': AppLottieAssets.baoSuCo,
  'baoCao': AppLottieAssets.baoCao,
  'napVi': AppLottieAssets.napVi,
  'daThanhToan': AppLottieAssets.daThanhToan,
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AppLottieAssets', () {
    _assets.forEach((name, path) {
      test('$name có trong bundle và parse được', () async {
        final bytes = await rootBundle.load(path);
        final composition = await LottieComposition.fromBytes(
          bytes.buffer.asUint8List(),
        );

        expect(composition.duration, isNotNull);
        // Bộ icon là ảnh 3D nhúng base64 trong file Lottie -> phải có image asset.
        expect(composition.images, isNotEmpty, reason: path);
        expect(
          composition.images.values.first.fileName,
          startsWith('data:image/'),
          reason: path,
        );
      });
    });

    test('ảnh nhúng giải mã được bằng codec của engine', () async {
      final bytes = await rootBundle.load(AppLottieAssets.box);
      final composition = await LottieComposition.fromBytes(
        bytes.buffer.asUint8List(),
      );

      final dataUri = composition.images.values.first.fileName;
      final buffer = await ui.ImmutableBuffer.fromUint8List(
        Uri.parse(dataUri).data!.contentAsBytes(),
      );
      final descriptor = await ui.ImageDescriptor.encoded(buffer);
      final frame = await (await descriptor.instantiateCodec()).getNextFrame();

      expect(frame.image.width, greaterThan(0));
      expect(frame.image.height, greaterThan(0));
    });
  });

  testWidgets('AppLottie dựng được và giữ đúng kích thước khung', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Center(
          child: SizedBox(
            width: 200,
            height: 180,
            child: AppLottie(AppLottieAssets.box),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(tester.getSize(find.byType(AppLottie)), const Size(200, 180));
  });
}
