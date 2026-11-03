import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_laundry_locker/core/services/app_event_bus.dart';
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
  String? lastSearch;

  @override
  LockerState get state => _state;

  @override
  Future<void> getLocations({String? search, bool refresh = false}) async {
    lastSearch = search;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  setUp(() {
    DioClient.instance.init(baseUrl: kTestBaseUrl);
    TokenService.authState.value = true;
  });

  testWidgets('LockerPage hiển thị nút X xoá tìm kiếm và tự reset khi chuyển tab', (
    tester,
  ) async {
    final mockLocations = [
      const LockerLocation(
        id: '1',
        name: 'Tủ demo 1',
        address: 'Địa chỉ 1',
        latitude: 10.84,
        longitude: 106.83,
        storeName: 'Kiosk A',
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

    final searchField = find.byType(TextField);
    expect(searchField, findsOneWidget);

    // Ban đầu chưa gõ thì không có nút X
    expect(find.byKey(const ValueKey('locker_search_clear_button')), findsNothing);

    // Gõ chữ "de" vào ô tìm kiếm
    await tester.enterText(searchField, 'de');
    await tester.pumpAndSettle();

    // Hiện nút X
    final clearBtn = find.byKey(const ValueKey('locker_search_clear_button'));
    expect(clearBtn, findsOneWidget);
    expect(fakeProvider.lastSearch, 'de');

    // Bấm nút X để xoá
    await tester.tap(clearBtn);
    await tester.pumpAndSettle();

    // Ô tìm kiếm đã sạch và nút X ẩn đi
    expect(find.text('de'), findsNothing);
    expect(find.byKey(const ValueKey('locker_search_clear_button')), findsNothing);
    expect(fakeProvider.lastSearch, '');

    // Nhập lại "de" và giả lập chuyển tab khác (bấm qua trang khác)
    await tester.enterText(searchField, 'de');
    await tester.pumpAndSettle();
    expect(find.text('de'), findsOneWidget);

    // Phát sự kiện chuyển tab (vd sang tab Trang chủ hoặc Đơn hàng)
    AppEventBus.instance.emit(
      const NavigationTabSelectedEvent(tabIndex: 0, branchIndex: 0),
    );
    await tester.pumpAndSettle();

    // Khi sự kiện chuyển tab diễn ra, chữ "de" đã tự động được xoá
    expect(find.text('de'), findsNothing);
    expect(fakeProvider.lastSearch, '');
  });
}
