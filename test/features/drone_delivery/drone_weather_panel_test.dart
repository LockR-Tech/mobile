import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_laundry_locker/features/drone_delivery/presentation/widgets/drone_weather_panel.dart';

Map<String, dynamic> _weather(
  String status, {
  String? provider = 'MET_NORWAY',
}) => {
  'safe': status == 'SAFE',
  'status': status,
  'message': status == 'UNSAFE'
      ? 'Không thể đặt chuyến bay: có mưa hoặc dông trên tuyến trong 30 phút tới.'
      : status == 'UNAVAILABLE'
      ? 'Không thể xác nhận dự báo thời tiết tuyến bay. Vui lòng thử lại sau.'
      : 'Dự báo tuyến bay an toàn trong 30 phút tới.',
  'checkedAt': '2026-10-23T06:00:00Z',
  'maxWindSpeedKmh': 18.0,
  'maxWindGustKmh': 27.0,
  'maxPrecipitationMm': status == 'UNSAFE' ? 1.2 : 0.0,
  'provider': provider,
  'temperatureC': 27.5,
  'condition': status == 'UNSAFE' ? 'Mưa rào' : 'Có mây',
};

void main() {
  Future<void> pump(WidgetTester tester, Widget child) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: SingleChildScrollView(child: child)),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets(
    'thẻ tuyến bay hiện tủ bay → tủ nhận, điều kiện và nguồn dự báo',
    (tester) async {
      final calls = <int>[];
      await pump(
        tester,
        DroneRouteWeatherCard(
          orderId: 21,
          load: (id) async {
            calls.add(id);
            return {
              'orderId': id,
              'sourceLockerName': 'Tủ Quận 1',
              'destinationLockerName': 'Tủ Quận 3',
              'weather': _weather('SAFE'),
            };
          },
        ),
      );

      expect(calls, [21]);
      expect(find.text('Tủ Quận 1 → Tủ Quận 3'), findsOneWidget);
      expect(find.text('Bay được'), findsOneWidget);
      expect(
        find.textContaining('Có mây · 28°C · Gió 18 km/h · Giật 27 km/h'),
        findsOneWidget,
      );
      expect(find.textContaining('nguồn MET Norway'), findsOneWidget);

      await tester.tap(
        find.byKey(const ValueKey('drone-route-weather-refresh')),
      );
      await tester.pumpAndSettle();
      expect(calls, [21, 21]);
    },
  );

  testWidgets('trời mưa: báo không an toàn kèm lý do', (tester) async {
    await pump(
      tester,
      DroneRouteWeatherCard(
        orderId: 5,
        load: (_) async => {'weather': _weather('UNSAFE')},
      ),
    );

    expect(find.text('Không an toàn để bay'), findsOneWidget);
    expect(find.textContaining('có mưa hoặc dông'), findsOneWidget);
  });

  testWidgets('danh sách tủ: đếm tủ không bay được và mở ra xem từng tủ', (
    tester,
  ) async {
    await pump(
      tester,
      DroneLockerWeatherList(
        load: () async => [
          {'lockerId': 1, 'name': 'Tủ A', 'weather': _weather('SAFE')},
          {
            'lockerId': 2,
            'name': 'Tủ B',
            'weather': _weather('UNAVAILABLE', provider: null),
          },
        ],
      ),
    );

    expect(
      find.text('1/2 tủ đang không bay được hoặc chưa có dự báo'),
      findsOneWidget,
    );
    expect(find.text('Tủ A'), findsNothing);

    await tester.tap(find.text('Thời tiết tại các tủ drone'));
    await tester.pumpAndSettle();
    expect(find.text('Tủ A'), findsOneWidget);
    expect(find.text('Tủ B'), findsOneWidget);
    expect(find.text('Chưa có dự báo'), findsOneWidget);
  });
}
