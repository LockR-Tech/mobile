import 'package:flutter_test/flutter_test.dart';
import 'package:smart_laundry_locker/features/drone_delivery/domain/entities/drone_incident_labels.dart';
import 'package:smart_laundry_locker/features/drone_delivery/domain/entities/drone_labels.dart';

void main() {
  test('kiện hỏng nói đúng mức KTV ghi, không gộp thành "Bị hư hỏng"', () {
    expect(droneParcelStateLabel('DAMAGED', 'MINOR_DAMAGE'), 'Hư hại nhẹ');
    expect(droneParcelStateLabel('RETURNED_TO_HUB', 'MINOR_DAMAGE'),
        'Đã về kho Lock.R · hư hại nhẹ');
    expect(droneParcelStateLabel('DAMAGED', null), 'Bị hư hỏng');
  });

  test('nhật ký sự cố không gán việc báo rơi cho đội bay và có nhãn thu hồi', () {
    expect(droneIncidentEventLabel('INCIDENT_REPORTED'),
        'Ghi nhận kiện rơi khỏi drone');
    expect(droneIncidentEventLabel('RECOVERY_ACCEPT'),
        'Nhân viên nhận việc thu hồi');
    expect(droneIncidentEventLabel('RECOVERY_START_SEARCHING'),
        'Nhân viên bắt đầu tìm kiện');
    expect(droneRecoveryStatusLabel('CLOSED'), 'Đã bàn giao kiện về kho');
  });

  test('nhiệm vụ dừng vì rơi kiện có nhãn tiếng Việt', () {
    expect(droneMissionStatusLabel('DROP_REPORTED'), 'Dừng do sự cố rơi kiện');
  });
}
