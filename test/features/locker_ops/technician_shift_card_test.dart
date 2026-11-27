import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_laundry_locker/core/l10n/l10n.dart';
import 'package:smart_laundry_locker/features/locker_ops/data/locker_ops_service.dart';
import 'package:smart_laundry_locker/features/locker_ops/presentation/widgets/technician_shift_card.dart';

import '../../helpers/test_helpers.dart';

class _FakePresenceService extends LockerOpsService {
  _FakePresenceService({
    required this.presenceData,
    this.pickupOn = true,
    this.pickupOffError,
  }) : super(dio: createMockDio().dio);

  final Map<String, dynamic> presenceData;
  bool pickupOn;

  /// Server từ chối tắt nhận việc (vd KTV còn việc lấy hàng đã nhận).
  final Object? pickupOffError;

  final calls = <String>[];

  @override
  Future<Map<String, dynamic>> droneTechnicianPresence() async => {'onDuty': pickupOn};

  @override
  Future<Map<String, dynamic>> getTechnicianPresence() async => presenceData;

  @override
  Future<Map<String, dynamic>> updateTechnicianPresence({
    required bool onDuty,
    double? latitude,
    double? longitude,
    double? accuracyM,
    double? headingDeg,
    double? speedMs,
    double? altitudeM,
    int? batteryLevel,
    String? deviceInfo,
  }) async {
    calls.add('shift onDuty=$onDuty');
    return {'onDuty': onDuty};
  }

  @override
  Future<Map<String, dynamic>> updateDroneTechnicianPresence({
    bool? onDuty,
    double? latitude,
    double? longitude,
  }) async {
    calls.add('pickup onDuty=$onDuty');
    if (onDuty == false && pickupOffError != null) throw pickupOffError!;
    pickupOn = onDuty ?? pickupOn;
    return {'onDuty': pickupOn};
  }
}

void main() {
  testWidgets('KTV drone hết ca: thôi nhận việc lấy hàng trước rồi mới hết ca', (
    tester,
  ) async {
    final fakeService = _FakePresenceService(presenceData: {'onDuty': true});
    final changes = <bool>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TechnicianShiftCard(
            service: fakeService,
            isDrone: true,
            onPresenceChanged: (data) => changes.add(data['onDuty'] == true),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Hết ca'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Kết thúc ca'));
    await tester.pumpAndSettle();

    expect(fakeService.calls, ['pickup onDuty=false', 'shift onDuty=false']);
    expect(changes.last, isFalse);
  });

  testWidgets('KTV drone còn việc lấy hàng đã nhận: server từ chối thì ca giữ nguyên', (
    tester,
  ) async {
    final fakeService = _FakePresenceService(
      presenceData: {'onDuty': true},
      pickupOffError: Exception('Finish or report the pickup you accepted before going off duty'),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TechnicianShiftCard(service: fakeService, isDrone: true),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Hết ca'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Kết thúc ca'));
    await tester.pumpAndSettle();

    expect(fakeService.calls, ['pickup onDuty=false']);
    expect(find.text('ĐANG TRONG CA'), findsOneWidget);
    await tester.pump(const Duration(seconds: 4));
  });

  testWidgets('KTV drone đang trong ca mà nhận việc lấy hàng đang tắt: mở thẻ là bật lại cho khớp', (
    tester,
  ) async {
    final fakeService = _FakePresenceService(
      presenceData: {'onDuty': true, 'latitude': 10.84, 'longitude': 106.81},
      pickupOn: false,
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TechnicianShiftCard(service: fakeService, isDrone: true),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(fakeService.calls, ['pickup onDuty=true']);
    expect(fakeService.pickupOn, isTrue);
  });


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

  testWidgets('tiếng Anh: thẻ ca trực hiện chữ tiếng Anh và không tràn ở 320px', (tester) async {
    L10n.load(L10n.en);
    addTearDown(() => L10n.load(L10n.vi));
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
              isDrone: false,
              margin: EdgeInsets.zero,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('ON SHIFT'), findsOneWidget);
    expect(find.text('End shift'), findsOneWidget);
    expect(find.text('ĐANG TRONG CA'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}

