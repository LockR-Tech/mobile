import 'package:dio/dio.dart';
import 'package:smart_laundry_locker/core/network/dio_client.dart';
import 'package:smart_laundry_locker/core/utils/app_date_time.dart';

/// Lắp đặt & nghiệm thu tủ (F3-G12) — hồ sơ do admin lập, KTV tủ làm checklist.
///
/// Tủ đi qua PLANNED → INSTALLING → COMMISSIONING → ACTIVE. Các bước máy kiểm được (mạng, gán bộ điều
/// khiển, cấu hình phần cứng, mở thử ô, nắp) do backend tự xác nhận từ dữ liệu tủ; KTV chỉ xác nhận bước
/// làm tay (kèm ảnh nếu bắt buộc).
abstract final class InstallationStatus {
  static const scheduled = 'SCHEDULED';
  static const inProgress = 'IN_PROGRESS';
  static const submitted = 'SUBMITTED';
  static const approved = 'APPROVED';
  static const cancelled = 'CANCELLED';
}

abstract final class InstallationCheckStatus {
  static const pending = 'PENDING';
  static const passed = 'PASSED';
  static const failed = 'FAILED';
  static const notApplicable = 'NOT_APPLICABLE';
}

/// Tiền tố mã QR kiosk hiện khi Pi chưa gán tủ (`LOCKR-PI:<MAC>`).
const controllerPairingPrefix = 'LOCKR-PI:';

final _macPattern = RegExp(r'^[0-9A-F]{2}([:-]?[0-9A-F]{2}){5}$');

/// MAC trong mã QR kiosk / gõ tay ⇒ dạng `AA:BB:CC:DD:EE:FF`; `null` nếu không phải MAC.
String? parseControllerMac(String raw) {
  var value = raw.trim().toUpperCase();
  if (value.startsWith(controllerPairingPrefix)) {
    value = value.substring(controllerPairingPrefix.length).trim();
  }
  if (!_macPattern.hasMatch(value)) return null;
  final hex = value.replaceAll(RegExp('[:-]'), '');
  return [for (var i = 0; i < 12; i += 2) hex.substring(i, i + 2)].join(':');
}

/// Mốc server tự ghi (`LocalDateTime.now()` trên container UTC) ⇒ chuỗi trần là UTC, đổi sang giờ máy.
DateTime? _time(Object? value) => parseServerDateTime(value);

/// Lịch lắp do admin nhập theo giờ Việt Nam và server giữ nguyên ⇒ đọc như giờ máy, không đổi múi.
DateTime? _localTime(Object? value) =>
    value is String && value.isNotEmpty ? DateTime.tryParse(value) : null;

int? _int(Object? value) => value is num ? value.toInt() : int.tryParse('${value ?? ''}');

String? _str(Object? value) {
  final text = value?.toString().trim();
  return text == null || text.isEmpty ? null : text;
}

class InstallationBoxResult {
  const InstallationBoxResult({
    required this.boxId,
    required this.boxNumber,
    required this.status,
    this.command,
    this.message,
    this.testedAt,
  });

  final int boxId;
  final int boxNumber;
  final String status;
  final String? command;
  final String? message;
  final DateTime? testedAt;

  factory InstallationBoxResult.fromJson(Map<String, dynamic> json) => InstallationBoxResult(
    boxId: _int(json['boxId']) ?? 0,
    boxNumber: _int(json['boxNumber']) ?? 0,
    status: _str(json['status']) ?? InstallationCheckStatus.pending,
    command: _str(json['command']),
    message: _str(json['message']),
    testedAt: _time(json['testedAt']),
  );
}

class InstallationCheck {
  const InstallationCheck({
    required this.item,
    required this.label,
    required this.status,
    required this.auto,
    required this.photoRequired,
    required this.notApplicableAllowed,
    this.verifiedBy,
    this.note,
    this.boxes = const [],
    this.checkedAt,
    this.photoCount = 0,
  });

  final String item;
  final String label;
  final String status;

  /// Hệ thống tự xác nhận từ dữ liệu tủ (KTV không tích tay được).
  final bool auto;
  final bool photoRequired;
  final bool notApplicableAllowed;
  final String? verifiedBy;
  final String? note;

  /// BOX_TEST: kết quả mở thử từng ô.
  final List<InstallationBoxResult> boxes;
  final DateTime? checkedAt;
  final int photoCount;

  bool get done => status == InstallationCheckStatus.passed || status == InstallationCheckStatus.notApplicable;

  factory InstallationCheck.fromJson(Map<String, dynamic> json) {
    final detail = json['detail'];
    return InstallationCheck(
      item: _str(json['item']) ?? '',
      label: _str(json['label']) ?? _str(json['item']) ?? '',
      status: _str(json['status']) ?? InstallationCheckStatus.pending,
      auto: json['auto'] == true,
      photoRequired: json['photoRequired'] == true,
      notApplicableAllowed: json['notApplicableAllowed'] == true,
      verifiedBy: _str(json['verifiedBy']),
      note: _str(json['note']),
      boxes: detail is List
          ? detail.whereType<Map>().map((e) => InstallationBoxResult.fromJson(Map<String, dynamic>.from(e))).toList()
          : const [],
      checkedAt: _time(json['checkedAt']),
      photoCount: _int(json['photoCount']) ?? 0,
    );
  }
}

class InstallationPhoto {
  const InstallationPhoto({
    required this.id,
    required this.url,
    this.item,
    this.thumbnailUrl,
    this.caption,
    this.uploadedByUserId,
  });

  final int id;
  final String url;

  /// `null` = ảnh hiện trường chung.
  final String? item;
  final String? thumbnailUrl;
  final String? caption;
  final int? uploadedByUserId;

  factory InstallationPhoto.fromJson(Map<String, dynamic> json) => InstallationPhoto(
    id: _int(json['id']) ?? 0,
    url: _str(json['url']) ?? '',
    item: _str(json['item']),
    thumbnailUrl: _str(json['thumbnailUrl']),
    caption: _str(json['caption']),
    uploadedByUserId: _int(json['uploadedByUserId']),
  );
}

class Installation {
  const Installation({
    required this.id,
    required this.lockerId,
    required this.status,
    this.lockerCode,
    this.lockerName,
    this.lockerStatus,
    this.scheduledAt,
    this.siteContactName,
    this.siteContactPhone,
    this.powerSource,
    this.networkType,
    this.networkNote,
    this.cabinetModel,
    this.cabinetSerial,
    this.notes,
    this.returnReason,
    this.controllerMac,
    this.controllerOnline,
    this.iotAvailable = true,
    this.readyToSubmit = false,
    this.missing = const [],
    this.checks = const [],
    this.photos = const [],
  });

  final int id;
  final int lockerId;
  final String status;
  final String? lockerCode;
  final String? lockerName;
  final String? lockerStatus;
  final DateTime? scheduledAt;
  final String? siteContactName;
  final String? siteContactPhone;
  final String? powerSource;
  final String? networkType;
  final String? networkNote;
  final String? cabinetModel;
  final String? cabinetSerial;
  final String? notes;
  final String? returnReason;
  final String? controllerMac;
  final bool? controllerOnline;
  final bool iotAvailable;
  final bool readyToSubmit;
  final List<String> missing;
  final List<InstallationCheck> checks;
  final List<InstallationPhoto> photos;

  String get displayName => lockerName ?? lockerCode ?? '#$lockerId';
  int get doneCount => checks.where((c) => c.done).length;
  bool get editable => status == InstallationStatus.inProgress;

  InstallationCheck? check(String item) {
    for (final c in checks) {
      if (c.item == item) return c;
    }
    return null;
  }

  List<InstallationPhoto> photosOf(String? item) => photos.where((p) => p.item == item).toList();

  factory Installation.fromJson(Map<String, dynamic> json) {
    List<Map<String, dynamic>> maps(Object? raw) =>
        raw is List ? raw.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList() : const [];
    return Installation(
      id: _int(json['id']) ?? 0,
      lockerId: _int(json['lockerId']) ?? 0,
      status: _str(json['status']) ?? InstallationStatus.scheduled,
      lockerCode: _str(json['lockerCode']),
      lockerName: _str(json['lockerName']),
      lockerStatus: _str(json['lockerStatus']),
      scheduledAt: _localTime(json['scheduledAt']),
      siteContactName: _str(json['siteContactName']),
      siteContactPhone: _str(json['siteContactPhone']),
      powerSource: _str(json['powerSource']),
      networkType: _str(json['networkType']),
      networkNote: _str(json['networkNote']),
      cabinetModel: _str(json['cabinetModel']),
      cabinetSerial: _str(json['cabinetSerial']),
      notes: _str(json['notes']),
      returnReason: _str(json['returnReason']),
      controllerMac: _str(json['controllerMac']),
      controllerOnline: json['controllerOnline'] is bool ? json['controllerOnline'] as bool : null,
      iotAvailable: json['iotAvailable'] != false,
      readyToSubmit: json['readyToSubmit'] == true,
      missing: (json['missing'] is List ? json['missing'] as List : const []).map((e) => '$e').toList(),
      checks: maps(json['checks']).map(InstallationCheck.fromJson).toList(),
      photos: maps(json['photos']).map(InstallationPhoto.fromJson).toList(),
    );
  }
}

/// Bộ điều khiển (Pi) đang online chưa gán tủ — chọn khi không quét được QR kiosk.
class ControllerCandidate {
  const ControllerCandidate({required this.macAddress, this.lockerId, this.online = false, this.lastSeenAt});

  final String macAddress;
  final int? lockerId;
  final bool online;
  final DateTime? lastSeenAt;

  factory ControllerCandidate.fromJson(Map<String, dynamic> json) => ControllerCandidate(
    macAddress: _str(json['macAddress']) ?? '',
    lockerId: _int(json['lockerId']),
    online: json['online'] == true,
    lastSeenAt: _time(json['lastSeenAt']),
  );
}

class InstallationApi {
  InstallationApi({Dio? dio}) : _dio = dio ?? DioClient.instance.dio;

  final Dio _dio;

  static const _base = '/api/locker-technician/installations';

  Installation _one(Response<dynamic> res) {
    final data = res.data is Map ? (res.data as Map)['data'] : null;
    return Installation.fromJson(data is Map ? Map<String, dynamic>.from(data) : const {});
  }

  Future<List<Installation>> mine() async {
    final res = await _dio.get<dynamic>(_base);
    final data = res.data is Map ? (res.data as Map)['data'] : null;
    if (data is! List) return const [];
    return data.whereType<Map>().map((e) => Installation.fromJson(Map<String, dynamic>.from(e))).toList();
  }

  /// Đọc lại hồ sơ; server cập nhật các bước tự động từ dữ liệu tủ.
  Future<Installation> detail(int id) async => _one(await _dio.get<dynamic>('$_base/$id'));

  Future<Installation> start(int id) async => _one(await _dio.post<dynamic>('$_base/$id/start'));

  /// [status]: PASSED, FAILED, NOT_APPLICABLE hoặc PENDING (bỏ xác nhận).
  Future<Installation> updateCheck(int id, String item, String status, {String? note}) async => _one(
    await _dio.put<dynamic>('$_base/$id/checks/$item', data: {'status': status, 'note': note}),
  );

  /// [item] = bước nghiệm thu, `null` = ảnh hiện trường chung. [photos] là ReportAttachmentRequest (JSON).
  Future<Installation> addPhotos(int id, String? item, List<Map<String, dynamic>> photos) async => _one(
    await _dio.post<dynamic>('$_base/$id/photos', data: {'item': item, 'photos': photos}),
  );

  Future<Installation> deletePhoto(int id, int photoId) async =>
      _one(await _dio.delete<dynamic>('$_base/$id/photos/$photoId'));

  Future<Installation> submit(int id) async => _one(await _dio.post<dynamic>('$_base/$id/submit'));

  // ---- Điều khiển tủ (iot-service, KTV phụ trách tủ) ----

  Future<List<ControllerCandidate>> controllerCandidates(int lockerId) async {
    final res = await _dio.get<dynamic>('/api/locker-technician/cabinet/$lockerId/controller/candidates');
    final data = res.data is Map ? (res.data as Map)['data'] : null;
    if (data is! List) return const [];
    return data.whereType<Map>().map((e) => ControllerCandidate.fromJson(Map<String, dynamic>.from(e))).toList();
  }

  /// Gán Pi vào tủ theo mã QR kiosk / MAC ⇒ Pi cài sơ đồ ô và mở thử từng ô.
  Future<void> bindController(int lockerId, String macOrQr) =>
      _dio.post<dynamic>('/api/locker-technician/cabinet/$lockerId/controller', data: {'macAddress': macOrQr});

  /// Mở thử một ô; trả `{accepted, status, message}` của tủ.
  Future<Map<String, dynamic>> openBox(int lockerId, int boxId) async {
    final res = await _dio.post<dynamic>('/api/locker-technician/cabinet/$lockerId/boxes/$boxId/open');
    final data = res.data is Map ? (res.data as Map)['data'] : null;
    return data is Map ? Map<String, dynamic>.from(data) : const {};
  }

  /// Nắp trục 1: [action] = open | close.
  Future<Map<String, dynamic>> lid(int lockerId, String action) async {
    final res = await _dio.post<dynamic>('/api/locker-technician/cabinet/$lockerId/lid/1/$action');
    final data = res.data is Map ? (res.data as Map)['data'] : null;
    return data is Map ? Map<String, dynamic>.from(data) : const {};
  }
}
