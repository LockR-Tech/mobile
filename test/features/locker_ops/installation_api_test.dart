import 'package:flutter_test/flutter_test.dart';
import 'package:smart_laundry_locker/features/locker_ops/data/installation_api.dart';

void main() {
  group('parseControllerMac — mã QR kiosk / MAC gõ tay', () {
    test('mã QR kiosk LOCKR-PI:<MAC>', () {
      expect(parseControllerMac('LOCKR-PI:AA:BB:CC:DD:EE:FF'), 'AA:BB:CC:DD:EE:FF');
      expect(parseControllerMac('  lockr-pi:aa:bb:cc:dd:ee:0f '), 'AA:BB:CC:DD:EE:0F');
    });

    test('MAC trần các kiểu viết', () {
      expect(parseControllerMac('aabbccddeeff'), 'AA:BB:CC:DD:EE:FF');
      expect(parseControllerMac('AA-BB-CC-DD-EE-FF'), 'AA:BB:CC:DD:EE:FF');
    });

    test('không phải MAC ⇒ null (tem QR ô, link, chuỗi lạ)', () {
      expect(parseControllerMac('{"type":"LOCKER_BOX","lockerId":7}'), isNull);
      expect(parseControllerMac('LOCKR-PI:'), isNull);
      expect(parseControllerMac('AA:BB:CC:DD:EE'), isNull);
      expect(parseControllerMac('GG:BB:CC:DD:EE:FF'), isNull);
    });
  });

  group('Installation.fromJson', () {
    final json = <String, dynamic>{
      'id': 5,
      'lockerId': 7,
      'lockerCode': 'TU-07',
      'lockerName': 'Tủ Vinhomes',
      'status': 'IN_PROGRESS',
      'scheduledAt': '2026-11-10T08:00:00',
      'controllerMac': 'AA:BB:CC:DD:EE:FF',
      'controllerOnline': true,
      'iotAvailable': true,
      'readyToSubmit': false,
      'missing': ['cần ít nhất 2 ảnh hiện trường (đang có 0)'],
      'checks': [
        {
          'item': 'BOX_TEST',
          'label': 'Mở thử từng ô',
          'status': 'PENDING',
          'auto': true,
          'photoRequired': false,
          'notApplicableAllowed': false,
          'verifiedBy': 'SYSTEM',
          'detail': [
            {'boxId': 71, 'boxNumber': 1, 'status': 'PASSED', 'command': 'SUCCESS'},
            {'boxId': 72, 'boxNumber': 2, 'status': 'PENDING'},
          ],
          'photoCount': 0,
        },
        {
          'item': 'MOUNTING',
          'label': 'Lắp khung',
          'status': 'PASSED',
          'auto': false,
          'photoRequired': true,
          'notApplicableAllowed': false,
          'detail': null,
          'photoCount': 1,
        },
      ],
      'photos': [
        {'id': 900, 'item': 'MOUNTING', 'url': 'https://res.cloudinary.com/x/m.jpg'},
        {'id': 901, 'item': null, 'url': 'https://res.cloudinary.com/x/s.jpg'},
      ],
    };

    test('đọc hồ sơ, bước và kết quả mở thử từng ô', () {
      final installation = Installation.fromJson(json);

      expect(installation.displayName, 'Tủ Vinhomes');
      expect(installation.editable, isTrue);
      expect(installation.controllerOnline, isTrue);
      expect(installation.doneCount, 1);
      expect(installation.scheduledAt, DateTime(2026, 11, 10, 8));
      final boxTest = installation.check('BOX_TEST')!;
      expect(boxTest.auto, isTrue);
      expect(boxTest.boxes.map((b) => b.boxNumber), [1, 2]);
      expect(boxTest.boxes.first.status, InstallationCheckStatus.passed);
      expect(installation.check('MOUNTING')!.done, isTrue);
    });

    test('ảnh tách theo bước và ảnh hiện trường', () {
      final installation = Installation.fromJson(json);

      expect(installation.photosOf('MOUNTING').map((p) => p.id), [900]);
      expect(installation.photosOf(null).map((p) => p.id), [901]);
    });

    test('scheduledAt giữ nguyên giờ Việt Nam, mốc server tự ghi đổi từ UTC sang giờ máy', () {
      final installation = Installation.fromJson({
        ...json,
        'scheduledAt': '2026-11-12T09:00:00',
        'checks': [
          {
            'item': 'MOUNTING',
            'label': 'Lắp khung',
            'status': 'PASSED',
            'auto': false,
            'photoRequired': true,
            'notApplicableAllowed': false,
            'checkedAt': '2026-11-11T16:25:00',
          },
        ],
      });
      final candidate = ControllerCandidate.fromJson(const {
        'macAddress': '02:4C:52:00:00:02',
        'online': true,
        'lastSeenAt': '2026-11-11T16:11:00',
      });

      expect(installation.scheduledAt, DateTime(2026, 11, 12, 9));
      expect(installation.check('MOUNTING')!.checkedAt, DateTime.utc(2026, 11, 11, 16, 25).toLocal());
      expect(candidate.lastSeenAt, DateTime.utc(2026, 11, 11, 16, 11).toLocal());
    });

    test('thiếu trường không làm vỡ màn hình', () {
      final installation = Installation.fromJson(const {'id': 1, 'lockerId': 2});

      expect(installation.status, InstallationStatus.scheduled);
      expect(installation.checks, isEmpty);
      expect(installation.iotAvailable, isTrue);
      expect(installation.displayName, '#2');
    });
  });
}
