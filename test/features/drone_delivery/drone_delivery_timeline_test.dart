import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_laundry_locker/features/drone_delivery/domain/entities/drone_delivery_stage.dart';
import 'package:smart_laundry_locker/features/drone_delivery/presentation/widgets/drone_delivery_timeline.dart';

void main() {
  testWidgets('renders the production-shaped delivery timeline', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: DroneDeliveryTimeline(stage: DroneDeliveryStage.enRoute),
          ),
        ),
      ),
    );

    // Đơn lấy hàng tận nhà: chờ KTV nhận → KTV tới lấy → mang về tủ → nạp → bay.
    expect(find.text('Chờ kỹ thuật viên nhận lấy hàng'), findsOneWidget);
    expect(find.text('Kỹ thuật viên đang tới lấy hàng'), findsOneWidget);
    expect(find.text('Đã lấy hàng, đang mang tới drone'), findsOneWidget);
    expect(find.text('Đang nạp hàng lên drone'), findsOneWidget);
    expect(find.text('Drone đã rời trạm'), findsOneWidget);
    expect(find.text('Drone đang trên đường'), findsOneWidget);
    expect(find.text('Sẵn sàng nhận hàng'), findsOneWidget);
  });

  testWidgets('shows when each reached stage happened', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: DroneDeliveryTimeline(
              stage: DroneDeliveryStage.canceled,
              // Đơn cũ (khách tự mang kiện ra tủ) không có hai chặng lấy hàng tận nhà.
              steps: DroneDeliveryStage.timelineFor(homePickup: false),
              stageTimes: {
                DroneDeliveryStage.awaitingDispatch: DateTime(
                  2026,
                  10,
                  1,
                  9,
                  5,
                  7,
                ),
                DroneDeliveryStage.accepted: DateTime(2026, 10, 1, 9, 30),
              },
            ),
          ),
        ),
      ),
    );

    expect(find.text('09:05:07 01/10/2026'), findsOneWidget);
    expect(find.text('09:30:00 01/10/2026'), findsOneWidget);
    // Huỷ sau khi tiếp nhận: dừng ở mốc đó, các mốc bay chưa hề diễn ra.
    expect(find.byIcon(Icons.close), findsOneWidget);
    expect(find.byIcon(Icons.check), findsOneWidget);
    // Thời gian chuyển giữa hai chặng đã đạt.
    expect(find.text('Chuyển sau 24 phút 53 giây'), findsOneWidget);
  });

  testWidgets(
    'shows how long the current stage has run and its sub-milestones',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: DroneDeliveryTimeline(
                stage: DroneDeliveryStage.accepted,
                now: DateTime(2026, 10, 1, 9, 40),
                stageTimes: {
                  DroneDeliveryStage.awaitingDispatch: DateTime(
                    2026,
                    10,
                    1,
                    9,
                    0,
                  ),
                  DroneDeliveryStage.accepted: DateTime(2026, 10, 1, 9, 30),
                },
                stepDetails: {
                  DroneDeliveryStage.accepted: [
                    DroneTimelineDetail(
                      'Nạp hàng lên drone',
                      DateTime(2026, 10, 1, 9, 35),
                    ),
                    const DroneTimelineDetail('Sẵn sàng phóng', null),
                  ],
                },
              ),
            ),
          ),
        ),
      );

      expect(find.text('Đã ở chặng này 10 phút'), findsOneWidget);
      expect(find.text('Chuyển sau 30 phút'), findsOneWidget);
      expect(
        find.text(
          'Nạp hàng lên drone: 09:35:00 01/10/2026',
          findRichText: true,
        ),
        findsOneWidget,
      );
      expect(
        find.text('Sẵn sàng phóng: Chưa diễn ra', findRichText: true),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'inserts a parcel-drop incident and leaves later stages pending',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: DroneDeliveryTimeline(
                stage: DroneDeliveryStage.dropReported,
                steps: DroneDeliveryStage.timelineFor(homePickup: false),
                stageTimes: {
                  DroneDeliveryStage.awaitingDispatch: DateTime(
                    2026,
                    10,
                    14,
                    9,
                  ),
                  DroneDeliveryStage.accepted: DateTime(2026, 10, 14, 9, 10),
                  DroneDeliveryStage.departed: DateTime(2026, 10, 14, 9, 20),
                  DroneDeliveryStage.dropReported: DateTime(
                    2026,
                    10,
                    14,
                    9,
                    25,
                  ),
                },
              ),
            ),
          ),
        ),
      );

      expect(find.text('Kiện hàng gặp sự cố rơi'), findsOneWidget);
      expect(find.text('09:25:00 14/10/2026'), findsOneWidget);
      // Mốc sau sự cố không được hiển thị như đã giao thành công.
      final pickupText = tester.widget<Text>(find.text('Sẵn sàng nhận hàng'));
      expect(pickupText.style?.color, Colors.grey);
    },
  );
}
