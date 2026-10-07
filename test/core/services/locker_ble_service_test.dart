import 'package:flutter_test/flutter_test.dart';
import 'package:smart_laundry_locker/core/services/locker_ble_service.dart';

void main() {
  group('LockerBleService - isDeviceMatchingLocker', () {
    const expectedCode = 'CAB-TU01';
    const expectedId = 7;

    test('matches exact locker code in broadcast name (LOCKR_CAB-TU01)', () {
      final matched = LockerBleService.isDeviceMatchingLocker(
        advertisementName: 'LOCKR_CAB-TU01',
        platformName: '',
        expectedLockerCode: expectedCode,
        expectedLockerId: expectedId,
      );
      expect(matched, isTrue);
    });

    test('matches normalized locker code without hyphen (LOCKR_CABTU01)', () {
      final matched = LockerBleService.isDeviceMatchingLocker(
        advertisementName: 'LOCKR_CABTU01',
        platformName: '',
        expectedLockerCode: expectedCode,
        expectedLockerId: expectedId,
      );
      expect(matched, isTrue);
    });

    test('matches platformName when advertisementName is empty', () {
      final matched = LockerBleService.isDeviceMatchingLocker(
        advertisementName: '',
        platformName: 'LOCKR_CAB-TU01',
        expectedLockerCode: expectedCode,
        expectedLockerId: expectedId,
      );
      expect(matched, isTrue);
    });

    test('matches locker by ID with prefix (LOCKR_7)', () {
      final matched = LockerBleService.isDeviceMatchingLocker(
        advertisementName: 'LOCKR_7',
        platformName: '',
        expectedLockerCode: expectedCode,
        expectedLockerId: expectedId,
      );
      expect(matched, isTrue);
    });

    test('matches locker by suffix code (LOCKR_TU01)', () {
      final matched = LockerBleService.isDeviceMatchingLocker(
        advertisementName: 'LOCKR_TU01',
        platformName: '',
        expectedLockerCode: expectedCode,
        expectedLockerId: expectedId,
      );
      expect(matched, isTrue);
    });

    test('matches direct code without prefix (CAB-TU01)', () {
      final matched = LockerBleService.isDeviceMatchingLocker(
        advertisementName: 'CAB-TU01',
        platformName: '',
        expectedLockerCode: expectedCode,
        expectedLockerId: expectedId,
      );
      expect(matched, isTrue);
    });

    test('rejects unrelated bluetooth device (JBL Flip 6)', () {
      final matched = LockerBleService.isDeviceMatchingLocker(
        advertisementName: 'JBL Flip 6',
        platformName: '',
        expectedLockerCode: expectedCode,
        expectedLockerId: expectedId,
      );
      expect(matched, isFalse);
    });

    test('rejects different locker (LOCKR_CAB-HN02)', () {
      final matched = LockerBleService.isDeviceMatchingLocker(
        advertisementName: 'LOCKR_CAB-HN02',
        platformName: '',
        expectedLockerCode: expectedCode,
        expectedLockerId: expectedId,
      );
      expect(matched, isFalse);
    });

    test('rejects empty inputs gracefully', () {
      final matched = LockerBleService.isDeviceMatchingLocker(
        advertisementName: '',
        platformName: '',
        expectedLockerCode: expectedCode,
        expectedLockerId: expectedId,
      );
      expect(matched, isFalse);
    });
  });

  group('LockerBleService - estimateDistance & Proximity', () {
    test('estimates 1m distance at -59 dBm', () {
      final dist = LockerBleService.estimateDistance(-59, txPower: -59);
      expect(dist, closeTo(1.0, 0.15));
    });

    test('returns negative distance for 0 rssi', () {
      final dist = LockerBleService.estimateDistance(0);
      expect(dist, equals(-1.0));
    });

    test('formats proximity text accurately', () {
      const near = LockerBleDetectionResult(
        isNearby: true,
        rssi: -60,
        estimatedDistanceMeters: 0.8,
        deviceName: 'LOCKR_CAB-TU01',
        deviceId: 'AA:BB:CC:DD:EE:FF',
      );
      expect(near.proximityText, contains('Rất gần'));

      const mid = LockerBleDetectionResult(
        isNearby: true,
        rssi: -72,
        estimatedDistanceMeters: 1.8,
        deviceName: 'LOCKR_CAB-TU01',
        deviceId: 'AA:BB:CC:DD:EE:FF',
      );
      expect(mid.proximityText, contains('Gần tủ'));
    });

    test('creates simulated result successfully', () {
      final sim = LockerBleService.createSimulatedResult(
        lockerCode: 'CAB-TU01',
      );
      expect(sim.isNearby, isTrue);
      expect(sim.isSimulated, isTrue);
      expect(sim.deviceName, equals('LOCKR_CAB-TU01'));
    });
  });
}
