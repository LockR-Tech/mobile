import 'package:flutter_test/flutter_test.dart';
import 'package:smart_laundry_locker/features/locker_ops/data/device_restart_result.dart';
import 'package:smart_laundry_locker/features/locker_ops/presentation/utils/technician_rules.dart';

void main() {
  group('SlaExtensionPolicy (K7)', () {
    Map<String, dynamic> report({
      Object? assignee = 7,
      String status = 'IN_PROGRESS',
      Object? used,
      Object? max,
    }) => {
      'id': 42,
      'status': status,
      'assignedToUserId': assignee,
      'slaExtensionsUsed': ?used,
      'slaExtensionsMax': ?max,
    };

    test('chỉ hiện cho KTV đang được giao phiếu IN_PROGRESS', () {
      expect(SlaExtensionPolicy.fromReport(report(), myUserId: '7').visible, isTrue);
      expect(SlaExtensionPolicy.fromReport(report(), myUserId: '8').visible, isFalse);
      expect(
        SlaExtensionPolicy.fromReport(report(status: 'OPEN'), myUserId: '7').visible,
        isFalse,
      );
      expect(SlaExtensionPolicy.fromReport(report(), myUserId: null).visible, isFalse);
    });

    test('hiện "đã gia hạn x/2" và khoá khi hết lượt', () {
      final once = SlaExtensionPolicy.fromReport(report(used: 1, max: 2), myUserId: '7');
      expect(once.usageLabel, 'Đã gia hạn 1/2');
      expect(once.canExtend, isTrue);
      expect(once.buttonLabel, 'Gia hạn SLA');

      final full = SlaExtensionPolicy.fromReport(report(used: 2, max: 2), myUserId: '7');
      expect(full.limitReached, isTrue);
      expect(full.canExtend, isFalse);
      expect(full.buttonLabel, 'Hết lượt gia hạn (2/2)');
    });

    test('admin tắt tự gia hạn (max = 0) ⇒ ẩn nút', () {
      expect(
        SlaExtensionPolicy.fromReport(report(used: 0, max: 0), myUserId: '7').visible,
        isFalse,
      );
    });

    test('máy chủ cũ không trả số lượt ⇒ vẫn cho gửi, server quyết định', () {
      final policy = SlaExtensionPolicy.fromReport(report(), myUserId: '7');
      expect(policy.usageLabel, isNull);
      expect(policy.canExtend, isTrue);
    });
  });

  group('SlaExtensionLimits', () {
    test('đọc giới hạn từ cấu hình công khai và lọc lựa chọn giờ', () {
      final limits = SlaExtensionLimits.fromSettings({
        'app.maintenance.sla-max-extensions': 2,
        'app.maintenance.sla-max-hours-per-extension': '10',
      });
      expect(limits.maxExtensions, 2);
      expect(limits.maxHoursPerExtension, 10);
      expect(limits.hourOptions(), [2, 4, 8, 10]);
    });

    test('không đọc được ⇒ giữ lựa chọn mặc định', () {
      const limits = SlaExtensionLimits();
      expect(limits.hourOptions(), [2, 4, 8, 12, 24]);
      expect(SlaExtensionLimits.fromSettings(null).maxExtensions, isNull);
    });
  });

  group('TechnicianSlaStatus (K13)', () {
    test('dùng penaltyLevel/penaltyReason của server', () {
      final status = TechnicianSlaStatus.fromPerformance({
        'penaltyLevel': 'restricted',
        'penaltyReason': 'Hạn chế nhận việc: có 4 phiếu trễ hạn SLA.',
        'overdue': 4,
      });
      expect(status.level, 'RESTRICTED');
      expect(status.label, 'Hạn chế nhận việc');
      expect(status.blocksNewWork, isTrue);
      expect(status.overdue, 4);
      expect(status.reason, contains('4 phiếu'));
    });

    test('chưa tải được ⇒ không tự suy mức chế tài', () {
      const status = TechnicianSlaStatus();
      expect(status.known, isFalse);
      expect(status.label, 'Chưa tải được');
      expect(TechnicianSlaStatus.fromPerformance(null).level, isNull);
    });
  });

  group('ratingSummary (K14)', () {
    test('chưa có lượt đánh giá ⇒ null (hiện "Chưa có đánh giá")', () {
      expect(ratingSummary({'count': 0, 'average': 0.0}), isNull);
      expect(ratingSummary(null), isNull);
    });

    test('có lượt ⇒ điểm thật', () {
      expect(ratingSummary({'count': 3, 'average': 4.333}), '4.3/5 (3 lượt)');
      expect(ratingSummary({'ratingCount': 2, 'averageRating': 5}), '5.0/5 (2 lượt)');
    });
  });

  test('openReportCount không đếm phiếu RESOLVED (K14)', () {
    expect(
      openReportCount([
        {'status': 'OPEN'},
        {'status': 'IN_PROGRESS'},
        {'status': 'RESOLVED'},
      ]),
      2,
    );
  });

  test('cellHoldsOrder — chặn "Mở thử ô" khi ô giữ đơn (K3)', () {
    expect(cellHoldsOrder(cellStatus: 'occupied'), isTrue);
    expect(cellHoldsOrder(cellStatus: 'RESERVED'), isTrue);
    expect(cellHoldsOrder(cellStatus: 'FAULT', hasActiveOrder: true), isTrue);
    expect(cellHoldsOrder(cellStatus: 'FAULT'), isFalse);
  });

  group('validateBoxIncidentInput (K1)', () {
    test('HUB_ESCROW bắt buộc mã Seal (không tự sinh)', () {
      expect(
        validateBoxIncidentInput(action: 'HUB_ESCROW', selectedBoxId: 5, sealNumber: ' '),
        contains('Seal'),
      );
      expect(
        validateBoxIncidentInput(action: 'HUB_ESCROW', selectedBoxId: 5, sealNumber: 'S-1'),
        isNull,
      );
    });

    test('HANDOVER bắt buộc PIN 6 số hoặc mã QR', () {
      expect(
        validateBoxIncidentInput(action: 'HANDOVER', selectedBoxId: 5),
        contains('PIN 6 số'),
      );
      expect(
        validateBoxIncidentInput(action: 'HANDOVER', selectedBoxId: 5, customerOtp: '123'),
        contains('6 chữ số'),
      );
      expect(
        validateBoxIncidentInput(action: 'HANDOVER', selectedBoxId: 5, customerOtp: '123456'),
        isNull,
      );
      expect(
        validateBoxIncidentInput(action: 'HANDOVER', selectedBoxId: 5, customerOtp: 'qr-token-abc'),
        isNull,
      );
    });

    test('RELOCATE cần ô đích; thiếu ô sự cố luôn báo lỗi', () {
      expect(
        validateBoxIncidentInput(action: 'RELOCATE', selectedBoxId: 5),
        contains('ô trống'),
      );
      expect(validateBoxIncidentInput(action: 'QUICK_FIX'), contains('chọn ô'));
      expect(validateBoxIncidentInput(action: 'LOCK_ONLY', selectedBoxId: 5), isNull);
    });
  });

  test('deviceLockerLabel dùng lockerName/lockerCode server trả (K9)', () {
    expect(deviceLockerLabel({'lockerName': 'Tủ TU01', 'lockerCode': 'CAB-TU01'}),
        'Tủ TU01 · CAB-TU01');
    expect(deviceLockerLabel({'lockerCode': 'CAB-TU01'}), 'CAB-TU01');
    expect(deviceLockerLabel({'lockerId': 7}), 'Tủ #7');
    expect(deviceLockerLabel(<String, dynamic>{}), isNull);
  });

  test('isDroneTechnicianRoles (D3)', () {
    expect(isDroneTechnicianRoles(['DRONE_TECHNICIAN']), isTrue);
    expect(isDroneTechnicianRoles(['ROLE_DRONE_TECHNICIAN']), isTrue);
    expect(isDroneTechnicianRoles(['LOCKER_TECHNICIAN']), isFalse);
    expect(isDroneTechnicianRoles(['DRONE_TECHNICIAN', 'LOCKER_TECHNICIAN']), isFalse);
    expect(technicianRoleLabel(drone: true), 'KTV drone');
    expect(technicianRoleLabel(drone: false), 'KTV tủ');
  });

  test('DeviceRestartResult.fromResponse (K4)', () {
    final failed = DeviceRestartResult.fromResponse({
      'accepted': false,
      'status': 'failed',
      'message': 'Không gửi được lệnh khởi động lại tới tủ — vui lòng thử lại',
    });
    expect(failed.isAccepted, isFalse);
    expect(failed.status, 'FAILED');
    expect(failed.displayMessage, contains('Không gửi được'));
  });
}
