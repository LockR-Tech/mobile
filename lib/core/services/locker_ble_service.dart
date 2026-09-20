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

  /// Kiểm tra và xin quyền Bluetooth
  Future<bool> requestPermissions() async {
    try {
      if (Platform.isAndroid) {
        final scanStatus = await Permission.bluetoothScan.request();
        final connectStatus = await Permission.bluetoothConnect.request();
        final locationStatus = await Permission.locationWhenInUse.request();
        return (scanStatus.isGranted || scanStatus.isLimited) &&
            (connectStatus.isGranted || connectStatus.isLimited) &&
            (locationStatus.isGranted || locationStatus.isLimited);
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
      final state = await FlutterBluePlus.adapterState.first;
      return state == BluetoothAdapterState.on;
    } catch (e) {
      debugPrint('[LockerBleService] isBluetoothAvailable check failed: $e');
      return false;
    }
  }

  /// Quét tìm tủ theo mã tủ (lockerCode / lockerId)
  /// [expectedLockerCode]: Mã tủ (vd: HCM01, LOCKR_HCM01, ...)
  /// [expectedLockerId]: ID tủ (vd: 1, 2)
  /// [timeout]: Thời gian tối đa quét (mặc định 3.5 giây)
  /// [rssiThreshold]: Ngưỡng RSSI coi là "đang đứng trước tủ" (mặc định >= -75 dBm ~ cự ly < 2m)
  Future<LockerBleDetectionResult?> scanForLocker({
    required String expectedLockerCode,
    int? expectedLockerId,
    Duration timeout = const Duration(milliseconds: 3500),
    int rssiThreshold = -78,
  }) async {
    // 1. Kiểm tra phần cứng Bluetooth
    final available = await isBluetoothAvailable();
    if (!available) {
      final permOk = await requestPermissions();
      if (!permOk) return null;
    }

    final completer = Completer<LockerBleDetectionResult?>();
    final normalizedCode = expectedLockerCode.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '').toUpperCase();
    final idString = expectedLockerId?.toString() ?? '';

    await stopScan();
    _isScanning = true;

    try {
      await FlutterBluePlus.startScan(
        timeout: timeout,
        androidUsesFineLocation: false,
      );

      _scanSubscription = FlutterBluePlus.scanResults.listen((results) {
        for (final r in results) {
          final advName = r.advertisementData.advName.toUpperCase();
          final devName = r.device.platformName.toUpperCase();
          final combined = '$advName $devName';

          // Match theo tên BLE hoặc Manufacturer/Service data
          bool isMatch = false;
          if (normalizedCode.isNotEmpty && combined.contains(normalizedCode)) {
            isMatch = true;
          } else if (combined.contains('LOCKR') || combined.contains('LOCKER')) {
            if (idString.isNotEmpty && combined.contains(idString)) {
              isMatch = true;
            } else if (normalizedCode.isNotEmpty && combined.contains(normalizedCode)) {
              isMatch = true;
            }
          }

          if (isMatch) {
            final dist = estimateDistance(r.rssi);
            final isNear = r.rssi >= rssiThreshold;
            if (!completer.isCompleted) {
              completer.complete(LockerBleDetectionResult(
                isNearby: isNear,
                rssi: r.rssi,
                estimatedDistanceMeters: math.max(0.4, dist),
                deviceName: devName.isNotEmpty ? devName : advName,
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
  /// Cho phép người dùng hoặc giảng viên test ngay mà không cần phần cứng RPi
  static LockerBleDetectionResult createSimulatedResult({
    required String lockerCode,
    String? lockerName,
  }) {
    return LockerBleDetectionResult(
      isNearby: true,
      rssi: -62, // Tín hiệu mạnh, khoảng cách ~ 1.1m
      estimatedDistanceMeters: 1.1,
      deviceName: 'LOCKR_${lockerCode.isNotEmpty ? lockerCode : "SIM"}',
      deviceId: 'SIM:00:AA:BB:CC:DD',
      isSimulated: true,
    );
  }
}
