import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_laundry_locker/features/locker_ops/data/locker_ops_service.dart';
import 'package:smart_laundry_locker/features/locker_ops/presentation/widgets/technician_shift_card.dart';

import '../../helpers/test_helpers.dart';

class _FakePresenceService extends LockerOpsService {
  _FakePresenceService({
    required this.presenceData,
  }) : super(dio: createMockDio().dio);

  final Map<String, dynamic> presenceData;

  @override
  Future<Map<String, dynamic>> getTechnicianPresence() async => presenceData;
}

void main() {
  testWidgets('TechnicianShiftCard does not overflow when on duty with shift duration', (tester) async {
    // 360 x 800 standard mobile screen size
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final fakeService = _FakePresenceService(
      presenceData: {
        'onDuty': true,
        'latitude': 10.4315,
        'longitude': 106.4029,
        'accuracyM': 12.0,
        'shiftStartedAt': DateTime.now().subtract(const Duration(minutes: 8)).toIso8601String(),
        'lastLocatedAt': DateTime.now().subtract(const Duration(minutes: 2)).toIso8601String(),
      },
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: TechnicianShiftCard(
              service: fakeService,
              isDrone: true,
              margin: EdgeInsets.zero,
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('ĐANG TRONG CA'), findsOneWidget);
    expect(find.text('Hết ca'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('TechnicianShiftCard does not overflow with long shift duration on narrow width (320px)', (tester) async {
    tester.view.physicalSize = const Size(320, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final fakeService = _FakePresenceService(
      presenceData: {
        'onDuty': true,
        'latitude': 10.4315,
        'longitude': 106.4029,
        'accuracyM': 12.0,
        'shiftStartedAt': DateTime.now().subtract(const Duration(hours: 3, minutes: 45)).toIso8601String(),
        'lastLocatedAt': DateTime.now().subtract(const Duration(minutes: 1)).toIso8601String(),
      },
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: TechnicianShiftCard(
              service: fakeService,
              isDrone: true,
              margin: EdgeInsets.zero,
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('ĐANG TRONG CA'), findsOneWidget);
    expect(find.text('Hết ca'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
