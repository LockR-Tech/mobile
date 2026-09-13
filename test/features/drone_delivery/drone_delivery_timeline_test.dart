import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_laundry_locker/features/drone_delivery/domain/entities/drone_delivery_stage.dart';
import 'package:smart_laundry_locker/features/drone_delivery/presentation/widgets/drone_delivery_timeline.dart';

void main() {
  testWidgets('renders the production-shaped delivery timeline', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: DroneDeliveryTimeline(stage: DroneDeliveryStage.enRoute),
          ),
        ),
      ),
    );

    expect(find.text('Chờ đội bay tiếp nhận'), findsOneWidget);
    expect(find.text('Đội bay đã tiếp nhận'), findsOneWidget);
    expect(find.text('Drone đã rời trạm'), findsOneWidget);
    expect(find.text('Drone đang trên đường'), findsOneWidget);
    expect(find.text('Sẵn sàng nhận hàng'), findsOneWidget);
  });
}
