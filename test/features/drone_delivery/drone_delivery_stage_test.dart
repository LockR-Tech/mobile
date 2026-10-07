import 'package:flutter_test/flutter_test.dart';
import 'package:smart_laundry_locker/core/config/business_config.dart';
import 'package:smart_laundry_locker/features/drone_delivery/domain/entities/drone_delivery_stage.dart';
import 'package:smart_laundry_locker/features/drone_delivery/domain/entities/drone_labels.dart';
import 'package:smart_laundry_locker/features/drone_delivery/domain/entities/drone_delivery_status.dart';
import 'package:smart_laundry_locker/features/drone_delivery/presentation/widgets/drone_order_cancel.dart';

void main() {
  test('parses production drone delivery stages', () {
    expect(
      DroneDeliveryStage.fromRaw('AWAITING_DISPATCH'),
      DroneDeliveryStage.awaitingDispatch,
    );
    expect(
      DroneDeliveryStage.fromRaw('ACCEPTED'),
      DroneDeliveryStage.accepted,
    );
    expect(
      DroneDeliveryStage.fromRaw('LAUNCHING'),
      DroneDeliveryStage.launching,
    );
    expect(
      DroneDeliveryStage.fromRaw('DEPARTED'),
      DroneDeliveryStage.departed,
    );
    expect(
      DroneDeliveryStage.fromRaw('EN_ROUTE'),
      DroneDeliveryStage.enRoute,
    );
    expect(
      DroneDeliveryStage.fromRaw('READY_FOR_PICKUP'),
      DroneDeliveryStage.readyForPickup,
    );
  });

  test('khách chỉ huỷ được khi đội bay chưa tiếp nhận; đã trả tiền thì hoàn về ví', () {
    const waiting = DroneDeliveryStatus(status: 'AWAITING_DISPATCH');
    const paid = DroneDeliveryStatus(
      status: 'AWAITING_DISPATCH',
      paymentStatus: 'PAID',
      totalPrice: 15000,
    );
    expect(waiting.canCustomerCancel, isTrue);
    expect(paid.canCustomerCancel, isTrue);
    for (final stage in ['ACCEPTED', 'LAUNCHING', 'EN_ROUTE', 'READY_FOR_PICKUP', 'CANCELED']) {
      expect(DroneDeliveryStatus(status: stage).canCustomerCancel, isFalse);
    }

    String note(DroneDeliveryStatus s) =>
        droneCancelRefundNote(isPaid: s.isPaid, totalPrice: s.totalPrice);
    expect(note(waiting), contains('không phát sinh phí'));
    expect(note(paid), contains('15.000đ'));
    expect(note(paid), contains('hoàn bằng chuyển khoản'));
  });

  test('cân lệch: đơn đã nạp hàng mà nợ phụ thu thì khách phải trả phần chênh', () {
    const owing = DroneDeliveryStatus(
      status: 'ACCEPTED',
      paymentStatus: 'UNPAID',
      totalPrice: 24000,
      weightSurcharge: 9000,
      amountDue: 9000,
    );
    expect(owing.needsSurchargePayment, isTrue);
    expect(owing.needsPaymentBeforeDispatch, isFalse);
    expect(owing.payableAmount, 9000);
    expect(owing.canCustomerCancel, isFalse);

    const settled = DroneDeliveryStatus(
      status: 'ACCEPTED',
      paymentStatus: 'PAID',
      totalPrice: 24000,
      weightSurcharge: 9000,
      amountDue: 0,
    );
    expect(settled.needsSurchargePayment, isFalse);
  });

  test('bảng giá drone theo khối lượng và mã niêm phong hệ thống cấp', () {
    final config = BusinessConfig.fromPublicMaps(
      order: {'app.order.drone-weight-step-fee': 3000},
    );
    expect(config.droneDeliveryFeeFor(500), 15000);
    expect(config.droneDeliveryFeeFor(501), 18000);
    expect(config.droneDeliveryFeeFor(1200), 24000);
    expect(
      config.droneWeightSurcharge(
        declaredGrams: 500,
        actualGrams: 1200,
        currentTotal: 15000,
      ),
      9000,
    );
    expect(
      config.droneWeightSurcharge(
        declaredGrams: 500,
        actualGrams: 550,
        currentTotal: 15000,
      ),
      0,
    );
    // Server chưa có bảng giá theo khối lượng ⇒ giá đồng nhất, không thu thêm.
    expect(BusinessConfig.fromPublicMaps().droneDeliveryFeeFor(3000), 15000);

    expect(droneWeightShortLabel(750), '750 g');
    expect(droneWeightShortLabel(1000), '1 kg');
    expect(droneWeightShortLabel(1500), '1,5 kg');
    expect(
      generateDroneSealCode(now: DateTime(2026, 10, 4)),
      matches(RegExp(r'^NP-261004-[A-Z2-9]{6}$')),
    );
  });

  test('keeps production stages in timeline order', () {
    expect(DroneDeliveryStage.awaitingDispatch.order, lessThan(DroneDeliveryStage.accepted.order));
    expect(DroneDeliveryStage.accepted.order, lessThan(DroneDeliveryStage.launching.order));
    expect(DroneDeliveryStage.launching.order, lessThan(DroneDeliveryStage.departed.order));
    expect(DroneDeliveryStage.departed.order, lessThan(DroneDeliveryStage.enRoute.order));
    expect(DroneDeliveryStage.enRoute.order, lessThan(DroneDeliveryStage.approaching.order));
    expect(DroneDeliveryStage.approaching.order, lessThan(DroneDeliveryStage.arrived.order));
    expect(DroneDeliveryStage.arrived.order, lessThan(DroneDeliveryStage.readyForPickup.order));
  });
}
