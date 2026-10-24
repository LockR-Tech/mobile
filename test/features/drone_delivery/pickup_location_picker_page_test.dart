import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:smart_laundry_locker/features/drone_delivery/domain/entities/drone_booking.dart';
import 'package:smart_laundry_locker/features/drone_delivery/infrastructure/services/pickup_geocoder.dart';
import 'package:smart_laundry_locker/features/drone_delivery/presentation/pages/pickup_location_picker_page.dart';

class _FakeGeocoder extends PickupGeocoder {
  String? reverse = '12 Nguyễn Huệ, Quận 1, TP.HCM';
  List<PickupLocation> found = const [];
  final searched = <String>[];

  @override
  Future<String?> addressOf(double latitude, double longitude) async => reverse;

  @override
  Future<List<PickupLocation>> search(String query) async {
    searched.add(query);
    return found;
  }
}

void main() {
  late _FakeGeocoder geocoder;
  PickupLocation? picked;

  setUp(() {
    geocoder = _FakeGeocoder();
    picked = null;
  });

  Future<void> pump(
    WidgetTester tester, {
    (LatLng?, String?) position = (const LatLng(10.7, 106.7), null),
    PickupLocation? initial,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () async {
                  picked = await Navigator.of(context).push<PickupLocation>(
                    MaterialPageRoute(
                      builder: (_) => PickupLocationPickerPage(
                        initial: initial,
                        geocoder: geocoder,
                        readPosition: () async => position,
                        showMap: false,
                      ),
                    ),
                  );
                },
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  testWidgets('mở lần đầu lấy luôn vị trí hiện tại và tra địa chỉ của nó', (
    tester,
  ) async {
    await pump(tester);

    expect(
      tester
          .widget<TextField>(find.byKey(const ValueKey('pickup-address')))
          .controller!
          .text,
      '12 Nguyễn Huệ, Quận 1, TP.HCM',
    );
    await tester.tap(find.byKey(const ValueKey('pickup-confirm')));
    await tester.pumpAndSettle();

    expect(picked!.latitude, 10.7);
    expect(picked!.longitude, 106.7);
    expect(picked!.address, '12 Nguyễn Huệ, Quận 1, TP.HCM');
  });

  testWidgets('GPS tắt: báo lý do, người gửi tìm địa chỉ rồi chọn kết quả', (
    tester,
  ) async {
    geocoder.found = const [
      PickupLocation(
        latitude: 10.78,
        longitude: 106.69,
        address: '45 Lê Lợi, Quận 1',
      ),
    ];
    await pump(
      tester,
      position: (null, 'Dịch vụ vị trí đang tắt. Vui lòng bật GPS.'),
    );

    expect(
      find.text('Dịch vụ vị trí đang tắt. Vui lòng bật GPS.'),
      findsOneWidget,
    );
    // Chưa có điểm nào thì chưa xác nhận được.
    await tester.tap(find.byKey(const ValueKey('pickup-confirm')));
    await tester.pumpAndSettle();
    expect(find.text('Chưa chọn vị trí lấy hàng trên bản đồ.'), findsOneWidget);
    expect(picked, isNull);

    // Gõ tới đâu gợi ý tới đó, không cần nút Tìm.
    await tester.enterText(find.byKey(const ValueKey('pickup-search')), '45');
    await tester.pump(const Duration(milliseconds: 500));
    expect(geocoder.searched, isEmpty);
    await tester.enterText(
      find.byKey(const ValueKey('pickup-search')),
      '45 Lê',
    );
    await tester.pump(const Duration(milliseconds: 100));
    await tester.enterText(
      find.byKey(const ValueKey('pickup-search')),
      '45 Lê Lợi',
    );
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();
    // Gõ liên tục chỉ tra một lần với chữ cuối cùng.
    expect(geocoder.searched, ['45 Lê Lợi']);
    expect(
      find.textContaining('10.78000, 106.69000 · chạm để xem ghim'),
      findsOneWidget,
    );
    await tester.tap(find.text('45 Lê Lợi, Quận 1'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('pickup-confirm')));
    await tester.pumpAndSettle();

    expect(picked!.latitude, 10.78);
    expect(picked!.address, '45 Lê Lợi, Quận 1');
  });

  testWidgets(
    'không tra được địa chỉ thì người gửi tự nhập; địa chỉ là bắt buộc',
    (tester) async {
      geocoder.reverse = null;
      await pump(tester);

      expect(find.textContaining('Chưa tra được địa chỉ'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('pickup-confirm')));
      await tester.pumpAndSettle();
      expect(find.textContaining('Nhập địa chỉ lấy hàng'), findsOneWidget);
      expect(picked, isNull);

      await tester.enterText(
        find.byKey(const ValueKey('pickup-address')),
        'Hẻm 3, số 7 Trần Hưng Đạo',
      );
      await tester.tap(find.byKey(const ValueKey('pickup-confirm')));
      await tester.pumpAndSettle();

      expect(picked!.address, 'Hẻm 3, số 7 Trần Hưng Đạo');
      expect(picked!.latitude, 10.7);
    },
  );

  testWidgets(
    'mở lại với điểm đã chọn thì giữ điểm đó, không tự nhảy về vị trí hiện tại',
    (tester) async {
      await pump(
        tester,
        position: (const LatLng(1, 2), null),
        initial: const PickupLocation(
          latitude: 10.75,
          longitude: 106.65,
          address: 'Nhà bạn A',
        ),
      );
      await tester.tap(find.byKey(const ValueKey('pickup-confirm')));
      await tester.pumpAndSettle();

      expect(picked!.latitude, 10.75);
      expect(picked!.address, 'Nhà bạn A');
    },
  );
}
