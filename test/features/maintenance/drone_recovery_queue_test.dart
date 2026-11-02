import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_laundry_locker/core/l10n/l10n.dart';
import 'package:image_picker/image_picker.dart';
import 'package:smart_laundry_locker/core/media/photo_picker_controller.dart';
import 'package:smart_laundry_locker/features/locker_ops/data/locker_ops_service.dart';
import 'package:smart_laundry_locker/features/maintenance/presentation/widgets/drone_recovery_queue.dart';

import '../../helpers/test_helpers.dart';

void main() {
  group('buildRecoveryEvidence (K17)', () {
    const uploaded = [
      {
        'publicId': 'lockr/recovery/a',
        'version': 1,
        'signature': 's1',
        'format': 'jpg',
        'caption': 'Bằng chứng thu hồi kiện',
        // Trường thừa từ attachment JSON không được lọt vào `media`.
        'capturedAt': '2026-10-12T08:00:00',
      },
      {
        'publicId': 'lockr/recovery/b',
        'version': 2,
        'signature': 's2',
      },
    ];

    test('capturedAt = giờ chụp từng ảnh; GPS ưu tiên toạ độ của ảnh', () {
      final shotA = DateTime.utc(2026, 10, 12, 1, 2, 3);
      final shotB = DateTime.utc(2026, 10, 12, 1, 5, 0);
      final photoA = PendingPhoto(XFile('a.jpg'), capturedAt: shotA)
        ..latitude = 10.5
        ..longitude = 106.7;
      final photoB = PendingPhoto(XFile('b.jpg'), capturedAt: shotB);

      final evidence = buildRecoveryEvidence(
        uploaded,
        [photoA, photoB],
        latitude: 10.0,
        longitude: 106.0,
        gpsAccuracyM: 12,
      );

      expect(evidence, hasLength(2));
      expect(evidence[0]['capturedAt'], shotA.toIso8601String());
      expect(evidence[0]['latitude'], 10.5);
      expect(evidence[0].containsKey('gpsAccuracyM'), isFalse);
      expect(evidence[0]['media'], {
        'publicId': 'lockr/recovery/a',
        'version': 1,
        'signature': 's1',
        'format': 'jpg',
      });
      expect(evidence[1]['capturedAt'], shotB.toIso8601String());
      expect(evidence[1]['latitude'], 10.0);
      expect(evidence[1]['gpsAccuracyM'], 12);
    });

    test('không có GPS ⇒ không gửi toạ độ giả', () {
      final evidence = buildRecoveryEvidence(
        uploaded.sublist(0, 1),
        [PendingPhoto(XFile('a.jpg'))],
      );

      expect(evidence.single.containsKey('latitude'), isFalse);
      expect(evidence.single.containsKey('longitude'), isFalse);
    });
  });

  testWidgets('lỗi tải ⇒ banner lỗi + Thử lại, không hiện "chưa có nhiệm vụ"',
      (tester) async {
    var refreshed = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DroneRecoveryQueue(
            items: const [],
            service: LockerOpsService(dio: createMockDio().dio),
            onRefresh: () async => refreshed++,
            error: 'Lỗi kết nối máy chủ',
          ),
        ),
      ),
    );

    expect(find.textContaining('Không tải được nhiệm vụ thu hồi'), findsOneWidget);
    expect(find.text('Chưa có nhiệm vụ thu hồi kiện'), findsNothing);

    await tester.tap(find.text('Thử lại'));
    expect(refreshed, 1);
  });

  testWidgets('tiếng Anh: hàng đợi thu hồi trống và nút thử lại', (tester) async {
    L10n.load(L10n.en);
    addTearDown(() => L10n.load(L10n.vi));
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DroneRecoveryQueue(
            items: const [],
            service: LockerOpsService(dio: createMockDio().dio),
            onRefresh: () async {},
          ),
        ),
      ),
    );

    expect(find.text('No parcel recovery tasks yet'), findsOneWidget);
    expect(find.text('Chưa có nhiệm vụ thu hồi kiện'), findsNothing);
  });
}

