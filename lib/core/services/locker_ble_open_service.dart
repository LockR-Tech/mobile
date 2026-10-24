import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:smart_laundry_locker/core/services/locker_ble_service.dart';

/// Các bước khi mở ô qua Bluetooth — trang thử hiện tiến trình theo bước.
enum BleOpenStep { scanning, connecting, sending, waiting }

/// Mã mở ô backend cấp (`POST /api/iot/ble-test/lockers/{id}/boxes/{n}/token`).
class BleOpenTicket {
  const BleOpenTicket({
    required this.token,
    required this.nonce,
    required this.deviceName,
    required this.lockerCode,
    required this.lockerId,
    required this.boxNumber,
    required this.serviceUuid,
    required this.openCharUuid,
    required this.resultCharUuid,
    this.boxStatus,
  });

  final List<int> token;
  final String nonce;
  final String deviceName;
  final String lockerCode;
  final int lockerId;
  final int boxNumber;
  final String serviceUuid;
  final String openCharUuid;
  final String resultCharUuid;
  final String? boxStatus;

  factory BleOpenTicket.fromJson(Map<String, dynamic> json) {
    final raw = (json['token'] as String? ?? '').trim();
    return BleOpenTicket(
      token: base64Url.decode(base64Url.normalize(raw)),
      nonce: (json['nonce'] as String? ?? '').toLowerCase(),
      deviceName: json['deviceName'] as String? ?? '',
      lockerCode: json['lockerCode'] as String? ?? '',
      lockerId: (json['lockerId'] as num?)?.toInt() ?? 0,
      boxNumber: (json['boxNumber'] as num?)?.toInt() ?? 0,
      serviceUuid: json['serviceUuid'] as String? ?? '',
      openCharUuid: json['openCharUuid'] as String? ?? '',
      resultCharUuid: json['resultCharUuid'] as String? ?? '',
      boxStatus: json['boxStatus'] as String?,
    );
  }
}

/// Kết quả một lần mở. [error] là mã Pi trả (BAD_SIGNATURE, EXPIRED, REPLAYED…) hoặc mã phía app
/// (NOT_FOUND, CONNECT_FAILED, NO_SERVICE, TIMEOUT, BLUETOOTH_OFF, PERMISSION_DENIED, UNSUPPORTED).
class BleOpenOutcome {
  const BleOpenOutcome.ok(this.boxNumber) : error = null;
  const BleOpenOutcome.failed(this.error, {this.boxNumber});

  final int? boxNumber;
  final String? error;

  bool get isOk => error == null;

  String get message => isOk ? 'Đã mở ô ${boxNumber ?? ''}'.trim() : errorText(error);

  static String errorText(String? code) => switch (code) {
        'NOT_FOUND' => 'Không thấy tủ qua Bluetooth. Hãy đứng sát tủ (dưới 2 m) rồi thử lại.',
        'CONNECT_FAILED' => 'Không kết nối được Bluetooth với tủ. Thử lại sau vài giây.',
        'NO_SERVICE' => 'Tủ chưa bật chức năng mở ô qua Bluetooth (bộ điều khiển cần cập nhật).',
        'TIMEOUT' => 'Tủ không trả lời. Kiểm tra ô đã mở chưa rồi thử lại.',
        'BLUETOOTH_OFF' => 'Bluetooth của điện thoại đang tắt.',
        'PERMISSION_DENIED' => 'App chưa được cấp quyền Bluetooth.',
        'UNSUPPORTED' => 'Thiết bị này không hỗ trợ Bluetooth (chỉ dùng được trên app Android/iOS).',
        'BAD_SIGNATURE' || 'BAD_FORMAT' || 'BAD_VERSION' => 'Tủ không chấp nhận mã mở ô.',
        'EXPIRED' || 'BAD_EXPIRY' => 'Mã mở ô đã hết hạn. Bấm mở lại để lấy mã mới.',
        'REPLAYED' => 'Mã này đã dùng rồi. Bấm mở lại để lấy mã mới.',
        'WRONG_LOCKER' => 'Bạn đang kết nối nhầm tủ.',
        'NO_KEY' => 'Tủ chưa tải được khoá kiểm mã từ máy chủ (cần có mạng một lần).',
        'NOT_CONFIGURED' => 'Tủ chưa được gán trên hệ thống.',
        'INVALID_SLOT' => 'Ô này không có khoá điện nối vào bộ điều khiển.',
        _ => 'Mở ô không thành công${code == null ? '' : ' ($code)'}.',
      };
}

/// Mở ô bằng cách ghi mã cho Pi qua BLE GATT (F3-G11, docs/01-overview/ble-open-contract.md).
class LockerBleOpenService {
  LockerBleOpenService._();
  static final LockerBleOpenService instance = LockerBleOpenService._();

  /// Pi trả JSON `{"nonce","result","box","error"}`; trả `null` nếu không phải kết quả của [nonce].
  @visibleForTesting
  static BleOpenOutcome? parseResult(List<int> value, String nonce) {
    try {
      final decoded = jsonDecode(utf8.decode(value));
      if (decoded is! Map) return null;
      final replyNonce = (decoded['nonce'] as String?)?.toLowerCase();
      if (replyNonce != nonce.toLowerCase()) return null;
      final box = (decoded['box'] as num?)?.toInt();
      if (decoded['result'] == 'OK') return BleOpenOutcome.ok(box);
      return BleOpenOutcome.failed(decoded['error'] as String? ?? 'OPEN_FAILED', boxNumber: box);
    } catch (_) {
      return null;
    }
  }

  Future<BleOpenOutcome> open(
    BleOpenTicket ticket, {
    void Function(BleOpenStep step)? onStep,
    Duration scanTimeout = const Duration(seconds: 10),
    Duration resultTimeout = const Duration(seconds: 15),
  }) async {
    if (kIsWeb) return const BleOpenOutcome.failed('UNSUPPORTED');
    if (!await FlutterBluePlus.isSupported) return const BleOpenOutcome.failed('UNSUPPORTED');
    if (!await LockerBleService.instance.requestPermissions()) {
      return const BleOpenOutcome.failed('PERMISSION_DENIED');
    }
    if (!await _ensureAdapterOn()) return const BleOpenOutcome.failed('BLUETOOTH_OFF');

    onStep?.call(BleOpenStep.scanning);
    await LockerBleService.instance.stopScan();
    final device = await _find(ticket, scanTimeout);
    if (device == null) return const BleOpenOutcome.failed('NOT_FOUND');

    StreamSubscription<List<int>>? sub;
    try {
      onStep?.call(BleOpenStep.connecting);
      try {
        await device.connect(timeout: const Duration(seconds: 12));
      } catch (e) {
        debugPrint('[LockerBleOpen] connect failed: $e');
        return const BleOpenOutcome.failed('CONNECT_FAILED');
      }
      // Mã 91 byte phải nằm gọn trong một lần ghi: Pi không ghép "long write".
      if (!kIsWeb && Platform.isAndroid && device.mtuNow < 100) {
        try {
          await device.requestMtu(247);
        } catch (_) {}
      }
      final services = await device.discoverServices();
      final service = services.where((s) => s.uuid == Guid(ticket.serviceUuid)).firstOrNull;
      final openChar =
          service?.characteristics.where((c) => c.uuid == Guid(ticket.openCharUuid)).firstOrNull;
      final resultChar =
          service?.characteristics.where((c) => c.uuid == Guid(ticket.resultCharUuid)).firstOrNull;
      if (openChar == null || resultChar == null) return const BleOpenOutcome.failed('NO_SERVICE');

      final completer = Completer<BleOpenOutcome>();
      sub = resultChar.onValueReceived.listen((value) {
        final outcome = parseResult(value, ticket.nonce);
        if (outcome != null && !completer.isCompleted) completer.complete(outcome);
      });
      await resultChar.setNotifyValue(true);

      onStep?.call(BleOpenStep.sending);
      await openChar.write(ticket.token, withoutResponse: false);

      onStep?.call(BleOpenStep.waiting);
      try {
        return await completer.future.timeout(resultTimeout);
      } on TimeoutException {
        // Lỡ mất thông báo: đọc lại kết quả lần cuối.
        try {
          final outcome = parseResult(await resultChar.read(), ticket.nonce);
          if (outcome != null) return outcome;
        } catch (_) {}
        return const BleOpenOutcome.failed('TIMEOUT');
      }
    } catch (e) {
      debugPrint('[LockerBleOpen] open failed: $e');
      return const BleOpenOutcome.failed('CONNECT_FAILED');
    } finally {
      await sub?.cancel();
      try {
        await device.disconnect();
      } catch (_) {}
    }
  }

  Future<bool> _ensureAdapterOn() async {
    if (await LockerBleService.instance.isBluetoothAvailable()) return true;
    if (!kIsWeb && Platform.isAndroid) {
      try {
        await FlutterBluePlus.turnOn(timeout: 15);
        return await LockerBleService.instance.isBluetoothAvailable();
      } catch (_) {}
    }
    return false;
  }

  /// Quét tìm Pi theo service UUID hoặc tên `LOCKR_<mã tủ>`; lấy thiết bị đầu tiên khớp.
  Future<BluetoothDevice?> _find(BleOpenTicket ticket, Duration timeout) async {
    final completer = Completer<BluetoothDevice?>();
    final serviceGuid = Guid(ticket.serviceUuid);
    final sub = FlutterBluePlus.onScanResults.listen((results) {
      for (final r in results) {
        final adv = r.advertisementData;
        final byService = adv.serviceUuids.contains(serviceGuid);
        final byName = adv.advName == ticket.deviceName ||
            r.device.platformName == ticket.deviceName ||
            LockerBleService.isDeviceMatchingLocker(
              advertisementName: adv.advName,
              platformName: r.device.platformName,
              expectedLockerCode: ticket.lockerCode,
              expectedLockerId: ticket.lockerId,
            );
        if ((byService || byName) && !completer.isCompleted) {
          completer.complete(r.device);
          return;
        }
      }
    });
    try {
      await FlutterBluePlus.startScan(timeout: timeout, androidUsesFineLocation: false);
      return await completer.future.timeout(timeout, onTimeout: () => null);
    } catch (e) {
      debugPrint('[LockerBleOpen] scan failed: $e');
      return null;
    } finally {
      await sub.cancel();
      try {
        await FlutterBluePlus.stopScan();
      } catch (_) {}
    }
  }
}
