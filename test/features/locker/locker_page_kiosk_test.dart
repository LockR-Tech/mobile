import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_laundry_locker/core/services/token_service.dart';
import 'package:smart_laundry_locker/features/locker/domain/entities/locker_location.dart';
import 'package:smart_laundry_locker/features/locker/presentation/pages/locker_page.dart';
import 'package:smart_laundry_locker/features/locker/presentation/providers/locker_provider.dart';
import 'package:smart_laundry_locker/features/locker/presentation/providers/locker_providers.dart';

import 'package:smart_laundry_locker/core/network/dio_client.dart';
import '../../helpers/test_helpers.dart';

class _FakeLockerProvider extends ChangeNotifier implements LockerProvider {
  _FakeLockerProvider(this._state);

  final LockerState _state;

  @override
  LockerState get state => _state;

  @override
  Future<void> getLocations({String? search, bool refresh = false}) async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  setUp(() {
    DioClient.instance.init(baseUrl: kTestBaseUrl);
    TokenService.authState.value = true;
  });

  testWidgets('LockerPage phân loại theo Kiosk và có các badge bộ lọc Kiosk', (
    tester,
  ) async {
    final mockLocations = [
      const LockerLocation(
        id: '1',
        name: 'Tủ Vinhomes Grand Park S5.02',
        address: 'Sảnh block S5.02, Vinhomes Grand Park',
        latitude: 10.84,
        longitude: 106.83,
        storeName: 'Vinhomes Grand Park',
      ),
      const LockerLocation(
        id: '2',
        name: 'Tủ demo capstone 3x3 + vali',
        address: 'FPT University HCMC',
        latitude: 10.84,
        longitude: 106.84,
        storeName: 'FPT University HCMC',
      ),
      const LockerLocation(
        id: '3',
        name: 'Locker2309',
        address: 'FPT University HCMC',
        latitude: 10.84,
        longitude: 106.84,
        storeName: 'FPT University HCMC',
      ),
      const LockerLocation(
        id: '4',
        name: 'Tủ Landmark 81',
        address: '720A Điện Biên Phủ',
        latitude: 10.79,
        longitude: 106.72,
        storeName: 'LockR Landmark 81',
      ),
    ];

    final fakeProvider = _FakeLockerProvider(
      LockerState(locations: mockLocations),
    );

    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 2.5;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          lockerNotifierProvider.overrideWith((ref) => fakeProvider),
        ],
        child: const MaterialApp(
          home: LockerPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify Kiosk filter chips are rendered
    expect(find.text('Tất cả'), findsOneWidget);
    expect(find.text('FPT University HCMC'), findsWidgets);
    expect(find.text('Vinhomes Grand Park'), findsWidgets);
    expect(find.text('LockR Landmark 81'), findsWidgets);

    // Verify Kiosk section headers in the list
    expect(find.text('Kiosk: FPT University HCMC'), findsWidgets);
    expect(find.text('Kiosk: Vinhomes Grand Park'), findsWidgets);
    expect(find.text('Kiosk: LockR Landmark 81'), findsWidgets);

    // Verify all 4 locker cards are present initially
    expect(find.text('Tủ Vinhomes Grand Park S5.02'), findsOneWidget);
    expect(find.text('Tủ demo capstone 3x3 + vali'), findsOneWidget);
    expect(find.text('Locker2309'), findsOneWidget);
    expect(find.text('Tủ Landmark 81'), findsOneWidget);

    // Tap on 'FPT University HCMC' filter chip (first one in horizontal chip row)
    await tester.ensureVisible(find.text('FPT University HCMC').first);
    await tester.tap(find.text('FPT University HCMC').first);
    await tester.pumpAndSettle();

    // Only FPT University HCMC lockers should be shown
    expect(find.text('Tủ demo capstone 3x3 + vali'), findsOneWidget);
    expect(find.text('Locker2309'), findsOneWidget);
    expect(find.text('Tủ Vinhomes Grand Park S5.02'), findsNothing);
    expect(find.text('Tủ Landmark 81'), findsNothing);

    // Tap on 'Tất cả' chip
    await tester.ensureVisible(find.text('Tất cả'));
    await tester.tap(find.text('Tất cả'));
    await tester.pumpAndSettle();

    // All lockers are visible again
    expect(find.text('Tủ Vinhomes Grand Park S5.02'), findsOneWidget);
    expect(find.text('Tủ demo capstone 3x3 + vali'), findsOneWidget);
    expect(find.text('Locker2309'), findsOneWidget);
    expect(find.text('Tủ Landmark 81'), findsOneWidget);
  });
}
