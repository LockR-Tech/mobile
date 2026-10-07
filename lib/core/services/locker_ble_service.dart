import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';

/// Kết quả phát hiện tín hiệu Bluetooth của tủ
class LockerBleDetectionResult {
  final bool isNearby;
  final int rssi;
  final double estimatedDistanceMeters;
  final String deviceName;
  final String deviceId;
  final bool isSimulated;

  const LockerBleDetectionResult({
    required this.isNearby,
    required this.rssi,
    required this.estimatedDistanceMeters,
    required this.deviceName,
    required this.deviceId,
    this.isSimulated = false,
  });

  String get proximityText {
    if (estimatedDistanceMeters <= 1.0) return 'Rất gần (~${estimatedDistanceMeters.toStringAsFixed(1)}m)';
    if (estimatedDistanceMeters <= 2.5) return 'Gần tủ (~${estimatedDistanceMeters.toStringAsFixed(1)}m)';
    return 'Cách tủ ~${estimatedDistanceMeters.toStringAsFixed(1)}m';
  }
}

/// Dịch vụ quét BLE Beacon / Proximity cho Smart Locker
class LockerBleService {
  LockerBleService._();
  static final LockerBleService instance = LockerBleService._();

  StreamSubscription<List<ScanResult>>? _scanSubscription;
  bool _isScanning = false;
  bool get isScanning => _isScanning;

  /// Ước tính khoảng cách từ RSSI (Log-distance path loss model)
  /// txPower chuẩn thường là -59 dBm tại cự ly 1m.
  static double estimateDistance(int rssi, {int txPower = -59}) {
    if (rssi == 0) return -1.0;
    final ratio = rssi * 1.0 / txPower;
    if (ratio < 1.0) {
      return math.pow(ratio, 10).toDouble();
    } else {
      return (0.89976) * math.pow(ratio, 7.7095) + 0.111;
    }
  }

  /// Kiểm tra thiết bị BLE quét được có khớp với tủ mục tiêu không
  /// Hỗ trợ cả mã tủ nguyên bản có dấu gạch ngang (CAB-TU01), mã chuẩn hóa (CABTU01),
  /// tiền tố LOCKR/LOCKER, và so khớp theo lockerId (vd LOCKR_7).
  static bool isDeviceMatchingLocker({
    required String advertisementName,
    required String platformName,
    required String expectedLockerCode,
    int? expectedLockerId,
  }) {
    final advUpper = advertisementName.toUpperCase().trim();
    final devUpper = platformName.toUpperCase().trim();
    final combined = '$advUpper $devUpper'.trim();
    if (combined.isEmpty) return false;

    final cleanCombined = combined.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');
    final expectedUpper = expectedLockerCode.toUpperCase().trim();
    final cleanExpected = expectedUpper.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');
    final idString = expectedLockerId?.toString().trim() ?? '';

    // 1. Khớp chính xác cả chuỗi mã tủ trong tên quét (vd: "CAB-TU01" trong "LOCKR_CAB-TU01")
    if (expectedUpper.isNotEmpty && combined.contains(expectedUpper)) {
      return true;
    }

    // 2. Khớp mã tủ đã làm sạch ký tự phân tách (vd: "CABTU01" trong "LOCKRCABTU01")
    if (cleanExpected.isNotEmpty && cleanCombined.contains(cleanExpected)) {
      return true;
    }

    // 3. Khớp tiền tố LOCKR / LOCKER kèm theo ID tủ số (vd: "LOCKR_7" hoặc "LOCKR-7")
    if ((cleanCombined.contains('LOCKR') || cleanCombined.contains('LOCKER')) &&
        idString.isNotEmpty &&
        (combined.contains(idString) || cleanCombined.contains(idString))) {
      return true;
    }

    // 4. Khớp phần hậu tố số hiệu tủ (vd: mã tủ "CAB-TU01" khớp với beacon "LOCKR_TU01" hay "TU01")
    if (cleanExpected.length >= 4) {
      final suffix = cleanExpected.substring(cleanExpected.length - 4);
      if (cleanCombined.contains(suffix)) {
        return true;
      }
    }

    return false;
  }

  /// Kiểm tra và xin quyền Bluetooth
  Future<bool> requestPermissions() async {
    try {
      if (Platform.isAndroid) {
        final scanStatus = await Permission.bluetoothScan.request();
        final connectStatus = await Permission.bluetoothConnect.request();
        // Cố gắng xin thêm Location nếu chưa có, nhưng không ép buộc fail nếu bị từ chối
        // do Manifest đã dùng android:usesPermissionFlags="neverForLocation"
        if (!await Permission.locationWhenInUse.isGranted) {
          try {
            await Permission.locationWhenInUse.request();
          } catch (_) {}
        }
        return (scanStatus.isGranted || scanStatus.isLimited) &&
            (connectStatus.isGranted || connectStatus.isLimited);
      } else if (Platform.isIOS) {
        final btStatus = await Permission.bluetooth.request();
        return btStatus.isGranted || btStatus.isLimited;
      }
      return true;
    } catch (e) {
      debugPrint('[LockerBleService] Error requesting permission: $e');
      return false;
    }
  }

  /// Kiểm tra Bluetooth phần cứng có khả dụng và đã bật chưa
  Future<bool> isBluetoothAvailable() async {
    try {
      final supported = await FlutterBluePlus.isSupported;
      if (!supported) return false;
      final state = await FlutterBluePlus.adapterState.first.timeout(
        const Duration(seconds: 2),
        onTimeout: () => BluetoothAdapterState.unknown,
      );
      return state == BluetoothAdapterState.on;
    } catch (e) {
      debugPrint('[LockerBleService] isBluetoothAvailable check failed: $e');
      return false;
    }
  }

  /// Quét tìm tủ theo mã tủ (lockerCode / lockerId)
  /// [expectedLockerCode]: Mã tủ (vd: CAB-TU01, HCM01, LOCKR_CAB-TU01, ...)
  /// [expectedLockerId]: ID tủ (vd: 7, 1)
  /// [timeout]: Thời gian tối đa quét (mặc định 4.0 giây)
  /// [rssiThreshold]: Ngưỡng RSSI coi là "đang đứng trước tủ" (mặc định >= -78 dBm ~ cự ly < 2m)
  Future<LockerBleDetectionResult?> scanForLocker({
    required String expectedLockerCode,
    int? expectedLockerId,
    Duration timeout = const Duration(milliseconds: 4000),
    int rssiThreshold = -78,
  }) async {
    // 1. Kiểm tra phần cứng Bluetooth & xin quyền nếu cần
    final available = await isBluetoothAvailable();
    if (!available) {
      final permOk = await requestPermissions();
      if (!permOk) return null;
    } else {
      if (Platform.isAndroid && !await Permission.bluetoothScan.isGranted) {
        final permOk = await requestPermissions();
        if (!permOk) return null;
      }
    }

    final completer = Completer<LockerBleDetectionResult?>();

    await stopScan();
    _isScanning = true;

    try {
      await FlutterBluePlus.startScan(
        timeout: timeout,
        androidUsesFineLocation: false,
      );

      _scanSubscription = FlutterBluePlus.scanResults.listen((results) {
        for (final r in results) {
          final isMatch = isDeviceMatchingLocker(
            advertisementName: r.advertisementData.advName,
            platformName: r.device.platformName,
            expectedLockerCode: expectedLockerCode,
            expectedLockerId: expectedLockerId,
          );

          if (isMatch) {
            final dist = estimateDistance(r.rssi);
            final isNear = r.rssi >= rssiThreshold;
            if (!completer.isCompleted) {
              final dName = r.device.platformName.isNotEmpty
                  ? r.device.platformName
                  : (r.advertisementData.advName.isNotEmpty
                      ? r.advertisementData.advName
                      : 'LOCKR_${expectedLockerCode.isNotEmpty ? expectedLockerCode : "CAB"}');
              completer.complete(LockerBleDetectionResult(
                isNearby: isNear,
                rssi: r.rssi,
                estimatedDistanceMeters: math.max(0.4, dist),
                deviceName: dName,
                deviceId: r.device.remoteId.str,
                isSimulated: false,
              ));
            }
            break;
          }
        }
      });

      // Hết timeout mà không thấy
      Future.delayed(timeout, () {
        if (!completer.isCompleted) {
          completer.complete(null);
        }
        stopScan();
      });
    } catch (e) {
      debugPrint('[LockerBleService] Scan error: $e');
      if (!completer.isCompleted) completer.complete(null);
      await stopScan();
    }

    return completer.future;
  }

  /// Dừng quét
  Future<void> stopScan() async {
    try {
      _isScanning = false;
      await _scanSubscription?.cancel();
      _scanSubscription = null;
      if (FlutterBluePlus.isScanningNow) {
        await FlutterBluePlus.stopScan();
      }
    } catch (_) {}
  }

  /// TẠO KẾT QUẢ MÔ PHỎNG (SIMULATION / DEMO MODE)
  /// Cho phép người dùng test mở tủ 1-chạm khi chưa đứng gần tủ thật
  static LockerBleDetectionResult createSimulatedResult({
    required String lockerCode,
    String? lockerName,
  }) {
    final code = lockerCode.isNotEmpty ? lockerCode : "CAB-TU01";
    return LockerBleDetectionResult(
      isNearby: true,
      rssi: -62, // Tín hiệu mạnh, khoảng cách ~ 1.1m
      estimatedDistanceMeters: 1.1,
      deviceName: 'LOCKR_$code',
      deviceId: 'SIM:00:AA:BB:CC:DD',
      isSimulated: true,
    );
  }
}
