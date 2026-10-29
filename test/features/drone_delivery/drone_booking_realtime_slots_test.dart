import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_laundry_locker/features/drone_delivery/domain/entities/drone_booking.dart';
import 'package:smart_laundry_locker/features/drone_delivery/infrastructure/services/locker_availability_socket_service.dart';
import 'package:smart_laundry_locker/features/drone_delivery/presentation/pages/drone_booking_page.dart';

const _lockers = [
  {
    'id': 5,
    'name': 'Locker B',
    'landingPad': true,
    'status': 'ACTIVE',
    'latitude': 10.8,
    'longitude': 106.7,
  },
  {
    'id': 6,
    'name': 'Locker C',
    'landingPad': true,
    'status': 'ACTIVE',
    'latitude': 10.8,
    'longitude': 106.7,
  },
];

Map<String, dynamic> _box(int id, int number) => {
  'id': id,
  'boxNumber': number,
  'cellType': 'DRONE',
  'status': 'AVAILABLE',
};

void main() {
  late Map<int, List<Map<String, dynamic>>> free;
  late StreamController<int> changes;
  late List<String> messages;
  late List<int> loads;

  setUp(() {
    free = {
      5: [_box(9001, 1), _box(9002, 2)],
      6: [],
    };
    changes = StreamController<int>.broadcast();
    messages = [];
    loads = [];
  });

  tearDown(() => changes.close());

  Future<void> pump(
    WidgetTester tester, {
    Duration refresh = const Duration(minutes: 5),
    bool realtime = true,
  }) async {
    tester.view.physicalSize = const Size(1200, 5000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        home: DroneBookingPage(
          initialDestinationLockerId: 5,
          preferredBoxId: 9001,
          initialSender: const DroneContact(
            name: 'Nguyễn Văn Gửi',
            phone: '0901000111',
            email: 'gui@gmail.com',
          ),
          destinationLockers: _lockers,
          loadDroneSlots: (lockerId) async {
            loads.add(lockerId);
            return List.of(free[lockerId] ?? const []);
          },
          loadQuote:
              ({
                required destinationLockerId,
                required pickupLatitude,
                required pickupLongitude,
                required parcelWeightGrams,
              }) async => throw UnimplementedError(),
          showMessage: messages.add,
          availabilityChanges: realtime ? changes.stream : null,
          slotRefreshInterval: refresh,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  String availability(WidgetTester tester) => tester
      .widget<Text>(
        find.byKey(const ValueKey('drone-destination-availability')),
      )
      .data!;

  /// Mục tủ chỉ được dựng khi mở danh sách tủ nhận: mở, đọc, rồi đóng lại.
  Future<bool> lockerOptionShows(WidgetTester tester, String text) async {
    await tester.tap(find.byKey(const ValueKey('drone-destination-locker')));
    await tester.pumpAndSettle();
    final shown = find.textContaining(text).evaluate().isNotEmpty;
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    return shown;
  }

  testWidgets(
    'ô đang chọn vừa bị người khác giữ: cập nhật ngay, bỏ chọn và báo',
    (tester) async {
      await pump(tester);
      expect(availability(tester), 'Ô nhận drone còn trống: 2');
      expect(find.text('Ô số 1'), findsWidgets);

      // Đơn khác vừa giữ ô số 1 của tủ đang chọn.
      free[5] = [_box(9002, 2)];
      changes.add(5);
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();

      expect(availability(tester), 'Ô nhận drone còn trống: 1');
      expect(messages, [
        'Ô số 1 vừa được người khác giữ. Hãy chọn ô drone khác.',
      ]);
      expect(find.text('Ô số 1'), findsNothing);
      // Chỉ tải lại đúng tủ vừa đổi.
      expect(loads.where((id) => id == 6), hasLength(1));
    },
  );

  testWidgets('tủ hết ô vừa có đơn lấy xong: hiện lại ô trống ngay', (
    tester,
  ) async {
    await pump(tester);
    expect(
      await lockerOptionShows(tester, 'Locker C · Hết ô drone trống'),
      isTrue,
    );

    free[6] = [_box(9101, 4)];
    // Một đơn đổi nhiều ô gửi nhiều báo liền nhau: chỉ tải lại một lần.
    changes
      ..add(6)
      ..add(6)
      ..add(6);
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();

    expect(
      await lockerOptionShows(tester, 'Locker C · 1 ô drone trống'),
      isTrue,
    );
    expect(loads.where((id) => id == 6), hasLength(2));
    expect(messages, isEmpty);
  });

  testWidgets('socket rớt: vẫn tự tải lại ô trống theo chu kỳ', (tester) async {
    await pump(tester, refresh: const Duration(seconds: 20), realtime: false);

    free[5] = [_box(9002, 2)];
    await tester.pump(const Duration(seconds: 21));
    await tester.pumpAndSettle();

    expect(availability(tester), 'Ô nhận drone còn trống: 1');
    expect(messages.single, contains('Ô số 1 vừa được người khác giữ'));
  });

  test('đọc mã tủ từ khung STOMP', () {
    expect(
      LockerAvailabilitySocketService.parseLockerId(
        '{"lockerId":7,"timestamp":"2026-10-24T15:00:00"}',
      ),
      7,
    );
    expect(LockerAvailabilitySocketService.parseLockerId('{"x":1}'), isNull);
    expect(
      LockerAvailabilitySocketService.parseLockerId('không phải json'),
      isNull,
    );
  });
}
