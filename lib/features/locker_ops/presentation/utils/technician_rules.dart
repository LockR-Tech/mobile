/// Quy tắc hiển thị thuần (không gọi mạng) dùng chung cho màn KTV tủ / KTV drone,
/// tách riêng để kiểm thử được.
library;

import 'package:smart_laundry_locker/core/l10n/l10n.dart';

int? _int(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse('${value ?? ''}');
}

double? _double(dynamic value) {
  if (value is double) return value;
  if (value is num) return value.toDouble();
  return double.tryParse('${value ?? ''}');
}

/// Vai trò KTV drone (ưu tiên KTV tủ nếu tài khoản có cả hai).
bool isDroneTechnicianRoles(List<String> roles) {
  bool has(String role) => roles.contains(role) || roles.contains('ROLE_$role');
  return has('DRONE_TECHNICIAN') && !has('LOCKER_TECHNICIAN');
}

/// Nhãn ngắn của vai trò KTV.
String technicianRoleLabel({required bool drone}) =>
    drone ? L10n.current.techUiRoleDrone : L10n.current.techUiRoleLocker;

/// Quy tắc nút "Gia hạn SLA" của một phiếu (CONTRACTS §4): chỉ KTV đang được
/// giao phiếu IN_PROGRESS; tối đa `slaExtensionsMax` lần (server trả kèm phiếu).
class SlaExtensionPolicy {
  const SlaExtensionPolicy({
    required this.assignedToMe,
    required this.inProgress,
    this.used,
    this.max,
  });

  factory SlaExtensionPolicy.fromReport(
    Map<String, dynamic> report, {
    String? myUserId,
  }) {
    final assignee = report['assignedToUserId']?.toString();
    return SlaExtensionPolicy(
      assignedToMe:
          myUserId != null && myUserId.isNotEmpty && assignee == myUserId,
      inProgress: report['status']?.toString() == 'IN_PROGRESS',
      used: _int(report['slaExtensionsUsed']),
      max: _int(report['slaExtensionsMax']),
    );
  }

  final bool assignedToMe;
  final bool inProgress;

  /// Số lần đã tự gia hạn; `null` khi máy chủ chưa trả trường này.
  final int? used;

  /// Số lần tối đa admin cho phép; `null` khi máy chủ chưa trả trường này.
  final int? max;

  /// Nút có hiện không: phiếu của mình, đang xử lý, admin không tắt (max = 0).
  bool get visible => assignedToMe && inProgress && (max == null || max! > 0);

  bool get limitReached => max != null && (used ?? 0) >= max!;

  bool get canExtend => visible && !limitReached;

  /// "Đã gia hạn 1/2"; `null` khi chưa biết giới hạn.
  String? get usageLabel => max == null
      ? null
      : L10n.current.techUiSlaExtensionUsage(used ?? 0, max!);

  /// Nhãn nút theo trạng thái.
  String get buttonLabel => limitReached
      ? L10n.current.techUiSlaExtensionLimit(used ?? 0, max!)
      : L10n.current.techUiExtendSla;
}

/// Giới hạn tự gia hạn SLA admin cấu hình (`GET /api/settings/locker/public`).
class SlaExtensionLimits {
  const SlaExtensionLimits({this.maxExtensions, this.maxHoursPerExtension});

  factory SlaExtensionLimits.fromSettings(Map<String, dynamic>? settings) {
    if (settings == null) return const SlaExtensionLimits();
    final maxExt = _int(settings['app.maintenance.sla-max-extensions']);
    final maxHours = _int(settings['app.maintenance.sla-max-hours-per-extension']);
    return SlaExtensionLimits(
      maxExtensions: maxExt != null && maxExt >= 0 ? maxExt : null,
      maxHoursPerExtension: maxHours != null && maxHours > 0 ? maxHours : null,
    );
  }

  /// `null` khi chưa đọc được cấu hình.
  final int? maxExtensions;
  final int? maxHoursPerExtension;

  /// Các lựa chọn giờ gia hạn hiển thị: lọc theo trần mỗi lần (nếu biết) và
  /// luôn có đúng mức trần để KTV chọn được tối đa.
  List<int> hourOptions([List<int> presets = const [2, 4, 8, 12, 24]]) {
    final cap = maxHoursPerExtension;
    if (cap == null) return presets;
    final options = presets.where((h) => h <= cap).toList();
    if (!options.contains(cap)) options.add(cap);
    options.sort();
    return options;
  }
}

/// Trạng thái chế tài SLA do server tính (`my-performance`). Không tự suy mức
/// chế tài từ số phiếu trễ ở máy — ngưỡng do admin cấu hình phía server.
class TechnicianSlaStatus {
  const TechnicianSlaStatus({
    this.level,
    this.reason,
    this.overdue,
    this.inProgress,
    this.resolved,
    this.totalAssigned,
  });

  factory TechnicianSlaStatus.fromPerformance(Map<String, dynamic>? perf) {
    if (perf == null || perf.isEmpty) return const TechnicianSlaStatus();
    final level = perf['penaltyLevel']?.toString().trim().toUpperCase();
    final reason = perf['penaltyReason']?.toString().trim();
    return TechnicianSlaStatus(
      level: level == null || level.isEmpty ? null : level,
      reason: reason == null || reason.isEmpty ? null : reason,
      overdue: _int(perf['overdue']),
      inProgress: _int(perf['inProgress']),
      resolved: _int(perf['resolved']),
      totalAssigned: _int(perf['totalAssigned']),
    );
  }

  /// NORMAL / WARNING / RESTRICTED / SUSPENDED; `null` khi chưa tải được.
  final String? level;
  final String? reason;
  final int? overdue;
  final int? inProgress;
  final int? resolved;
  final int? totalAssigned;

  bool get known => level != null;

  /// Mức chặn nhận việc mới (RESTRICTED / SUSPENDED).
  bool get blocksNewWork => level == 'RESTRICTED' || level == 'SUSPENDED';

  String get label => switch (level) {
    'SUSPENDED' => L10n.current.techUiSlaSuspended,
    'RESTRICTED' => L10n.current.techUiSlaRestricted,
    'WARNING' => L10n.current.techUiSlaWarning,
    'NORMAL' => L10n.current.techUiSlaNormal,
    null => L10n.current.techUiSlaNotLoaded,
    _ => level!,
  };
}

/// "4.5/5 (12 lượt)"; `null` khi chưa có lượt đánh giá nào hoặc chưa tải được
/// (nơi gọi hiện "Chưa có đánh giá").
String? ratingSummary(Map<String, dynamic>? rating) {
  if (rating == null) return null;
  final count = _int(rating['count'] ?? rating['ratingCount']) ?? 0;
  if (count <= 0) return null;
  final avg = _double(rating['average'] ?? rating['averageRating']);
  if (avg == null) return null;
  return L10n.current.techUiRatingSummary(avg.toStringAsFixed(1), count);
}

/// Số phiếu còn mở (chưa RESOLVED) — dùng cho nhãn tab "Sự cố (N)".
int openReportCount(Iterable<Map<String, dynamic>> reports) =>
    reports.where((r) => r['status']?.toString() != 'RESOLVED').length;

/// Ô có đồ / đang giữ chỗ cho đơn ⇒ không được đề nghị "mở thử ô sau sửa".
bool cellHoldsOrder({String? cellStatus, bool hasActiveOrder = false}) {
  final status = cellStatus?.toUpperCase();
  return hasActiveOrder || status == 'OCCUPIED' || status == 'RESERVED';
}

/// Kiểm tra dữ liệu bắt buộc theo phương án xử lý sự cố ô; `null` = hợp lệ.
String? validateBoxIncidentInput({
  required String action,
  int? selectedBoxId,
  int? targetBoxId,
  String? customerOtp,
  String? sealNumber,
}) {
  if (selectedBoxId == null) return L10n.current.techUiSelectIncidentBox;
  switch (action) {
    case 'RELOCATE':
      if (targetBoxId == null) {
        return L10n.current.techUiSelectTargetBox;
      }
    case 'HANDOVER':
      // order-service nhận PIN 6 số hoặc mã QR của đơn.
      final code = (customerOtp ?? '').trim();
      if (code.isEmpty) {
        return L10n.current.techUiEnterHandoverCode;
      }
      if (RegExp(r'^\d+$').hasMatch(code) && code.length != 6) {
        return L10n.current.techUiPinSixDigits;
      }
    case 'HUB_ESCROW':
      if ((sealNumber ?? '').trim().isEmpty) {
        return L10n.current.techUiEnterSealCode;
      }
  }
  return null;
}

/// "Tủ A · CAB-01" cho thiết bị IoT; `null` khi server không trả tên/mã tủ.
String? deviceLockerLabel(Map<String, dynamic> device) {
  final name = device['lockerName']?.toString().trim() ?? '';
  final code = device['lockerCode']?.toString().trim() ?? '';
  if (name.isEmpty && code.isEmpty) {
    final id = _int(device['lockerId']);
    return id == null ? null : L10n.current.lockerHash(id);
  }
  if (name.isEmpty) return code;
  if (code.isEmpty) return name;
  return '$name · $code';
}
