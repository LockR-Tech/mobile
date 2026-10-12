import 'package:flutter_test/flutter_test.dart';
import 'package:smart_laundry_locker/features/drone_delivery/domain/entities/drone_delivery_stage.dart';
import 'package:smart_laundry_locker/features/drone_delivery/domain/entities/drone_delivery_status.dart';
import 'package:smart_laundry_locker/features/drone_delivery/domain/entities/drone_incident_labels.dart';
import 'package:smart_laundry_locker/features/drone_delivery/domain/entities/drone_locker_availability.dart';
import 'package:smart_laundry_locker/features/drone_delivery/domain/entities/drone_viewer.dart';
import 'package:smart_laundry_locker/features/drone_delivery/infrastructure/models/drone_delivery_response.dart';
import 'package:smart_laundry_locker/features/drone_delivery/presentation/providers/drone_delivery_providers.dart';

void main() {
  group('thao tác theo vai trò người xem', () {
    const unpaid = DroneDeliveryStatus(
      status: 'AWAITING_DISPATCH',
      paymentStatus: 'UNPAID',
      userId: 10,
      receiverUserId: 20,
    );

    test('map userId / receiverUserId từ read model', () {
      final status = DroneDeliveryResponse.fromJson({
        'orderId': 5,
        'status': 'AWAITING_DISPATCH',
        'deliveryStage': 'AWAITING_DISPATCH',
        'userId': 10,
        'receiverUserId': 20,
      }).toEntity();
      expect(status.userId, 10);
      expect(status.receiverUserId, 20);
    });

    test('chỉ người đặt thấy trả phí / huỷ', () {
      expect(droneViewerRole(unpaid, 10), DroneViewerRole.booker);
      expect(droneViewerRole(unpaid, 20), DroneViewerRole.receiver);
      expect(droneViewerRole(unpaid, 99), DroneViewerRole.other);

      final booker = DroneCustomerActions.of(unpaid, DroneViewerRole.booker);
      expect(booker.canPay, isTrue);
      expect(booker.canCancel, isTrue);

      for (final role in [DroneViewerRole.receiver, DroneViewerRole.other]) {
        final actions = DroneCustomerActions.of(unpaid, role);
        expect(actions.canPay, isFalse, reason: '$role');
        expect(actions.canCancel, isFalse, reason: '$role');
        expect(actions.canConfirmDrop, isFalse, reason: '$role');
        expect(actions.canDeclineSurcharge, isFalse, reason: '$role');
      }
    });

    test('phụ thu cân lệch và xác nhận bỏ kiện chỉ dành cho người đặt', () {
      const owing = DroneDeliveryStatus(
        status: 'ACCEPTED',
        paymentStatus: 'UNPAID',
        weightSurcharge: 9000,
        userId: 10,
      );
      expect(DroneCustomerActions.of(owing, DroneViewerRole.booker).canDeclineSurcharge, isTrue);
      expect(DroneCustomerActions.of(owing, DroneViewerRole.receiver).canDeclineSurcharge, isFalse);

      const needsDrop = DroneDeliveryStatus(
        status: 'AWAITING_DISPATCH',
        paymentStatus: 'PAID',
        parcelReturnPending: false,
        userId: 10,
      );
      expect(DroneCustomerActions.of(needsDrop, DroneViewerRole.booker).canConfirmDrop, isTrue);
      expect(DroneCustomerActions.of(needsDrop, DroneViewerRole.receiver).canConfirmDrop, isFalse);
    });

    test('server cũ chưa trả userId ⇒ giữ hành vi cũ (coi là người đặt)', () {
      const legacy = DroneDeliveryStatus(status: 'AWAITING_DISPATCH');
      expect(droneViewerRole(legacy, 10), DroneViewerRole.booker);
      expect(droneViewerRole(legacy, null), DroneViewerRole.booker);
    });

    test('"Nhận hàng" ở READY_FOR_PICKUP: người đặt ⇒ chi tiết đơn, người nhận ⇒ PIN', () {
      const selfReceive = DroneDeliveryStatus(
        status: 'READY_FOR_PICKUP',
        userId: 10,
      );
      expect(
        DroneCustomerActions.of(selfReceive, DroneViewerRole.booker).pickup,
        DronePickupAction.bookerOrder,
      );

      const forOther = DroneDeliveryStatus(
        status: 'READY_FOR_PICKUP',
        userId: 10,
        receiverUserId: 20,
      );
      expect(
        DroneCustomerActions.of(forOther, DroneViewerRole.booker).pickup,
        DronePickupAction.bookerOrderForOther,
      );
      expect(
        DroneCustomerActions.of(forOther, DroneViewerRole.receiver).pickup,
        DronePickupAction.receiverPin,
      );
      expect(
        DroneCustomerActions.of(forOther, DroneViewerRole.other).pickup,
        DronePickupAction.none,
      );
      // Chưa tới tủ nhận thì không có nút.
      expect(
        DroneCustomerActions.of(unpaid, DroneViewerRole.receiver).pickup,
        DronePickupAction.none,
      );
    });
  });

  test('DROP_REPORTED có chặng riêng, không phải "Cập nhật đơn hàng"', () {
    final stage = DroneDeliveryStage.fromRaw('DROP_REPORTED');
    expect(stage, DroneDeliveryStage.dropReported);
    expect(stage.isIncident, isTrue);
    expect(stage.isTerminal, isFalse);
    expect(stage.title, isNot(DroneDeliveryStage.unknown.title));
    expect(stage.body(null), contains('rơi'));
  });

  test('nhãn sự cố tiếng Việt, mã lạ vẫn đọc được', () {
    expect(droneIncidentStatusLabel('AWAITING_CUSTOMER_RESPONSE'), 'Chờ bạn phản hồi phương án');
    expect(droneRecoveryStatusLabel('SEARCHING'), 'Đang tìm kiện');
    expect(droneParcelStatusLabel('RETURNED_TO_HUB'), 'Đã về kho Lock.R');
    expect(droneResolutionTypeLabel('FREE_REDELIVERY'), 'Giao lại miễn phí');
    expect(droneIncidentEventLabel('CUSTOMER_REQUEST_REVIEW'), 'Bạn yêu cầu xem xét lại');
    expect(droneIncidentEventLabel('RECOVERY_SEARCHING'), 'Cập nhật thu hồi kiện');
    expect(droneIncidentStatusLabel('SOME_NEW_STATE'), 'Some new state');
    expect(droneIncidentStatusLabel(null), '—');
  });

  test('tủ nhận theo trạng thái bãi đáp và kết nối', () {
    expect(droneDestinationBlockReason(status: 'ACTIVE'), isNull);
    expect(droneDestinationBlockReason(status: 'ACTIVE', landingPadStatus: 'OK', online: true), isNull);
    expect(droneDestinationBlockReason(status: 'ACTIVE', landingPadStatus: 'MAINTENANCE'), 'bãi đáp đang bảo trì');
    expect(droneDestinationBlockReason(status: 'ACTIVE', landingPadStatus: 'FAULT'), 'bãi đáp đang lỗi');
    expect(droneDestinationBlockReason(status: 'ACTIVE', online: false), 'mất kết nối');
    expect(droneDestinationBlockReason(status: 'MAINTENANCE'), 'đang bảo trì');
  });

  test('poll trạng thái giãn nhịp khi lỗi liên tiếp, tối đa 30 giây', () {
    expect(droneStatusPollDelay(0), const Duration(seconds: 3));
    expect(droneStatusPollDelay(1), const Duration(seconds: 3));
    expect(droneStatusPollDelay(2), const Duration(seconds: 6));
    expect(droneStatusPollDelay(3), const Duration(seconds: 12));
    expect(droneStatusPollDelay(10), const Duration(seconds: 30));
  });
}
