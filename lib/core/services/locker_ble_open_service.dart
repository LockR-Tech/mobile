import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:smart_laundry_locker/core/services/locker_ble_service.dart';
import 'package:smart_laundry_locker/core/l10n/l10n.dart';

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

/// Kết quả một lần mở. [error] là mã Pi trả (BAD_SIGNATURE, EXPIRED, REPLAYED, HARDWARE_ERROR…) hoặc
/// mã phía app (NOT_FOUND, NOT_FOUND_LOCATION_OFF, CONNECT_FAILED, NO_SERVICE, MTU_TOO_SMALL,
/// WRITE_FAILED, DISCONNECTED, TIMEOUT, BLUETOOTH_OFF, PERMISSION_DENIED, UNSUPPORTED).
class BleOpenOutcome {
  const BleOpenOutcome.ok(this.boxNumber) : error = null;
  const BleOpenOutcome.failed(this.error, {this.boxNumber});

  final int? boxNumber;
  final String? error;

  bool get isOk => error == null;

  String get message => isOk ? L10n.current.bleOpenedBox(boxNumber ?? '').trim() : errorText(error);

  static String errorText(String? code) => switch (code) {
        'NOT_FOUND' => L10n.current.bleNotFound,
        'NOT_FOUND_LOCATION_OFF' => L10n.current.bleNotFoundLocationOff,
        'CONNECT_FAILED' => L10n.current.bleConnectFailed,
        'NO_SERVICE' => L10n.current.bleNoService,
        'MTU_TOO_SMALL' => L10n.current.bleMtuTooSmall,
        'WRITE_FAILED' => L10n.current.bleWriteFailed,
        'DISCONNECTED' => L10n.current.bleDisconnected,
        'TIMEOUT' => L10n.current.bleTimeout,
        'HARDWARE_ERROR' => L10n.current.bleHardwareError,
        'BLUETOOTH_OFF' => L10n.current.bleOff,
        'PERMISSION_DENIED' => L10n.current.blePermissionDenied,
        'UNSUPPORTED' => L10n.current.bleUnsupported,
        'BAD_SIGNATURE' || 'BAD_FORMAT' || 'BAD_VERSION' => L10n.current.bleBadCode,
        'EXPIRED' || 'BAD_EXPIRY' => L10n.current.bleExpired,
        'REPLAYED' => L10n.current.bleReplayed,
        'WRONG_LOCKER' => L10n.current.bleWrongLocker,
        'NO_KEY' => L10n.current.bleNoKey,
        'NOT_CONFIGURED' => L10n.current.bleNotConfigured,
        'INVALID_SLOT' => L10n.current.bleInvalidSlot,
        _ => L10n.current.bleOpenFailed(code == null ? '' : ' ($code)'),
      };
}

/// Thiết bị quét được khớp với tủ cần mở tới đâu — càng đứng trước càng chắc.
enum BleMatch { exactName, fuzzyName, serviceOnly }

/// Mở ô bằng cách ghi mã cho Pi qua BLE GATT (F3-G11, docs/01-overview/ble-open-contract.md).
class LockerBleOpenService {
  LockerBleOpenService._();
  static final LockerBleOpenService instance = LockerBleOpenService._();

  /// Thấy thiết bị chưa khớp đúng tên thì chờ thêm chừng này để gói scan response (chứa tên) tới
  /// và để so RSSI khi có nhiều tủ.
  static const _settleDelay = Duration(milliseconds: 1500);

  /// Android hay trả lỗi GATT 133 ở lần kết nối đầu ngay sau khi quét.
  static const _connectAttempts = 3;

  /// Pi đặt tên `LOCKR_<mã tủ>`; tủ giả trên Windows không đặt được tên nên chỉ có service UUID.
  @visibleForTesting
  static BleMatch? matchLevel({
    required String advName,
    required String platformName,
    required List<Guid> serviceUuids,
    required BleOpenTicket ticket,
  }) {
    if (ticket.deviceName.isNotEmpty && (advName == ticket.deviceName || platformName == ticket.deviceName)) {
      return BleMatch.exactName;
    }
    if (LockerBleService.isDeviceMatchingLocker(
      advertisementName: advName,
      platformName: platformName,
      expectedLockerCode: ticket.lockerCode,
      expectedLockerId: ticket.lockerId,
    )) {
      return BleMatch.fuzzyName;
    }
    if (ticket.serviceUuid.isNotEmpty && serviceUuids.contains(Guid(ticket.serviceUuid))) {
      return BleMatch.serviceOnly;
    }
    return null;
  }

  /// Chọn thiết bị khớp chắc nhất; cùng mức thì lấy tín hiệu mạnh nhất (tủ người dùng đứng trước).
  @visibleForTesting
  static T? pickBest<T>(Iterable<({T device, BleMatch match, int rssi})> candidates) {
    ({T device, BleMatch match, int rssi})? best;
    for (final c in candidates) {
      if (best == null ||
          c.match.index < best.match.index ||
          (c.match == best.match && c.rssi > best.rssi)) {
        best = c;
      }
    }
    return best?.device;
  }

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
    final found = await _find(ticket, scanTimeout);
    final device = found.device;
    if (device == null) {
      if (found.error != null) return BleOpenOutcome.failed(found.error);
      return BleOpenOutcome.failed(await _locationOff() ? 'NOT_FOUND_LOCATION_OFF' : 'NOT_FOUND');
    }

    StreamSubscription<List<int>>? valueSub;
    StreamSubscription<BluetoothConnectionState>? stateSub;
    Timer? poll;
    try {
      onStep?.call(BleOpenStep.connecting);
      if (!await _connect(device)) return const BleOpenOutcome.failed('CONNECT_FAILED');

      // Mã 91 byte phải nằm gọn trong một lần ghi: Pi không ghép "long write". Android đã xin MTU 512
      // lúc kết nối; có máy chỉ nhận mức thấp hơn nên xin lại một lần.
      final needed = ticket.token.length + 3;
      if (!kIsWeb && Platform.isAndroid && device.mtuNow < needed) {
        try {
          await device.requestMtu(247);
        } catch (e) {
          debugPrint('[LockerBleOpen] requestMtu failed: $e');
        }
      }
      if (device.mtuNow < needed) {
        debugPrint('[LockerBleOpen] MTU ${device.mtuNow} < $needed');
        return const BleOpenOutcome.failed('MTU_TOO_SMALL');
      }

      var chars = await _characteristics(device, ticket);
      if (chars == null && !kIsWeb && Platform.isAndroid) {
        // Android nhớ bảng GATT cũ của địa chỉ này (Pi vừa cập nhật / đổi dịch vụ): xoá rồi tìm lại.
        try {
          await device.clearGattCache();
          chars = await _characteristics(device, ticket);
        } catch (e) {
          debugPrint('[LockerBleOpen] clearGattCache failed: $e');
        }
      }
      if (chars == null) return const BleOpenOutcome.failed('NO_SERVICE');
      final (openChar, resultChar) = chars;

      final completer = Completer<BleOpenOutcome>();
      void finish(BleOpenOutcome outcome) {
        if (!completer.isCompleted) completer.complete(outcome);
      }

      valueSub = resultChar.onValueReceived.listen((value) {
        final outcome = parseResult(value, ticket.nonce);
        if (outcome != null) finish(outcome);
      });
      var notifying = true;
      try {
        await resultChar.setNotifyValue(true);
      } catch (e) {
        // Không bật được notify thì đọc RESULT định kỳ sau khi ghi.
        debugPrint('[LockerBleOpen] setNotifyValue failed: $e');
        notifying = false;
      }

      onStep?.call(BleOpenStep.sending);
      try {
        await openChar.write(ticket.token, withoutResponse: false);
      } catch (e) {
        debugPrint('[LockerBleOpen] write failed: $e');
        return BleOpenOutcome.failed(device.isConnected ? 'WRITE_FAILED' : 'DISCONNECTED');
      }

      onStep?.call(BleOpenStep.waiting);
      // Mất kết nối sau khi đã gửi mã: tủ có thể đã mở — báo riêng để người dùng kiểm tra ô.
      stateSub = device.connectionState.listen((s) {
        if (s == BluetoothConnectionState.disconnected) finish(const BleOpenOutcome.failed('DISCONNECTED'));
      });
      if (!notifying) {
        poll = Timer.periodic(const Duration(milliseconds: 800), (_) async {
          try {
            final outcome = parseResult(await resultChar.read(), ticket.nonce);
            if (outcome != null) finish(outcome);
          } catch (_) {}
        });
      }
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
      poll?.cancel();
      await stateSub?.cancel();
      await valueSub?.cancel();
      try {
        await device.disconnect();
      } catch (_) {}
    }
  }

  Future<bool> _connect(BluetoothDevice device) async {
    for (var attempt = 1; attempt <= _connectAttempts; attempt++) {
      try {
        await device.connect(timeout: const Duration(seconds: 10));
        return true;
      } catch (e) {
        debugPrint('[LockerBleOpen] connect attempt $attempt failed: $e');
        try {
          await device.disconnect();
        } catch (_) {}
        if (attempt < _connectAttempts) await Future<void>.delayed(const Duration(milliseconds: 700));
      }
    }
    return false;
  }

  Future<(BluetoothCharacteristic, BluetoothCharacteristic)?> _characteristics(
      BluetoothDevice device, BleOpenTicket ticket) async {
    final services = await device.discoverServices();
    final service = services.where((s) => s.uuid == Guid(ticket.serviceUuid)).firstOrNull;
    final openChar = service?.characteristics.where((c) => c.uuid == Guid(ticket.openCharUuid)).firstOrNull;
    final resultChar = service?.characteristics.where((c) => c.uuid == Guid(ticket.resultCharUuid)).firstOrNull;
    if (openChar == null || resultChar == null) return null;
    return (openChar, resultChar);
  }

  /// Android 11 trở xuống không trả kết quả quét khi tắt Vị trí (Android 12+ thì không cần).
  Future<bool> _locationOff() async {
    if (kIsWeb || !Platform.isAndroid) return false;
    try {
      return await Permission.location.serviceStatus == ServiceStatus.disabled;
    } catch (_) {
      return false;
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

  /// Quét tìm Pi theo tên `LOCKR_<mã tủ>` hoặc service UUID. Đúng tên thì dừng ngay; chỉ khớp một
  /// phần thì chờ [_settleDelay] rồi chọn thiết bị chắc nhất, gần nhất ([pickBest]).
  Future<({BluetoothDevice? device, String? error})> _find(BleOpenTicket ticket, Duration timeout) async {
    final candidates = <DeviceIdentifier, ({BluetoothDevice device, BleMatch match, int rssi})>{};
    final done = Completer<void>();
    Timer? settle;
    void finish() {
      if (!done.isCompleted) done.complete();
    }

    final sub = FlutterBluePlus.onScanResults.listen((results) {
      for (final r in results) {
        final match = matchLevel(
          advName: r.advertisementData.advName,
          platformName: r.device.platformName,
          serviceUuids: r.advertisementData.serviceUuids,
          ticket: ticket,
        );
        if (match == null) continue;
        candidates[r.device.remoteId] = (device: r.device, match: match, rssi: r.rssi);
        if (match == BleMatch.exactName) {
          finish();
        } else {
          settle ??= Timer(_settleDelay, finish);
        }
      }
    });
    try {
      // Không để FBP chặn quét khi tắt Vị trí: Android 12+ (BLUETOOTH_SCAN neverForLocation) không cần.
      await FlutterBluePlus.startScan(
        timeout: timeout,
        androidUsesFineLocation: false,
        androidCheckLocationServices: false,
      );
      await done.future.timeout(timeout, onTimeout: () {});
    } catch (e) {
      debugPrint('[LockerBleOpen] scan failed: $e');
      // Android 11 trở xuống: FBP xin ACCESS_FINE_LOCATION lúc quét, bị từ chối thì báo quyền.
      if (candidates.isEmpty) {
        return (device: null, error: '$e'.contains('Permission') ? 'PERMISSION_DENIED' : null);
      }
    } finally {
      settle?.cancel();
      await sub.cancel();
      try {
        await FlutterBluePlus.stopScan();
      } catch (_) {}
    }
    final best = pickBest(candidates.values);
    if (best != null) {
      final c = candidates[best.remoteId]!;
      debugPrint('[LockerBleOpen] chọn ${best.remoteId} (${c.match.name}, ${c.rssi} dBm) / ${candidates.length} ứng viên');
    }
    return (device: best, error: null);
  }
}
