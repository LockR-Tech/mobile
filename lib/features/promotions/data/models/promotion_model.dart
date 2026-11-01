import 'package:intl/intl.dart';
import 'package:smart_laundry_locker/core/utils/app_date_time.dart';
import 'package:smart_laundry_locker/core/l10n/l10n.dart';

class PromotionModel {
  final int id;
  final String code;
  final String name;
  final String? description;
  final String? imageUrl;
  final String discountType;
  final double discountValue;
  final double? maxDiscountAmount;
  final double? minOrderAmount;
  final String status;
  final DateTime? startAt;
  final DateTime? endAt;

  /// Tủ duy nhất được dùng mã (null = toàn hệ thống). Server trả kèm
  /// `lockerCode`/`lockerName` để hiện `Áp dụng tại: <tên tủ>`.
  final int? lockerId;
  final String? lockerCode;
  final String? lockerName;

  const PromotionModel({
    required this.id,
    required this.code,
    required this.name,
    this.description,
    this.imageUrl,
    required this.discountType,
    required this.discountValue,
    this.maxDiscountAmount,
    this.minOrderAmount,
    required this.status,
    this.startAt,
    this.endAt,
    this.lockerId,
    this.lockerCode,
    this.lockerName,
  });

  factory PromotionModel.fromJson(Map<String, dynamic> json) {
    return PromotionModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      code: json['code'] as String? ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String?,
      imageUrl: json['imageUrl'] as String?,
      discountType: json['discountType'] as String? ?? 'FIXED_AMOUNT',
      discountValue: (json['discountValue'] as num?)?.toDouble() ?? 0.0,
      maxDiscountAmount: (json['maxDiscountAmount'] as num?)?.toDouble(),
      minOrderAmount: (json['minOrderAmount'] as num?)?.toDouble(),
      status: json['status'] as String? ?? 'ACTIVE',
      // Backend trả LocalDateTime trần (UTC) ⇒ đọc bằng hàm chung, nếu không
      // hạn ưu đãi lệch 7 tiếng.
      startAt: parseServerDateTime(json['startAt']),
      endAt: parseServerDateTime(json['endAt']),
      lockerId: promotionLockerId(json['lockerId']),
      lockerCode: _text(json['lockerCode']),
      lockerName: _text(json['lockerName']),
    );
  }

  /// Mã chỉ dùng được ở một tủ.
  bool get isLockerScoped => lockerId != null;

  /// Tên tủ được dùng mã; `null` = toàn hệ thống.
  String? get lockerDisplayName => promotionLockerDisplayName(
    lockerId: lockerId,
    lockerName: lockerName,
    lockerCode: lockerCode,
  );

  /// `Áp dụng tại: Tủ A` hoặc `Toàn hệ thống`.
  String get scopeLabel => promotionScopeLabel(
    lockerId: lockerId,
    lockerName: lockerName,
    lockerCode: lockerCode,
  );

  /// Dùng được ở tủ [currentLockerId]: mã toàn hệ thống, hoặc mã của đúng tủ
  /// đó. Chưa chọn tủ ⇒ chỉ mã toàn hệ thống.
  bool usableAt(int? currentLockerId) =>
      lockerId == null || (currentLockerId != null && lockerId == currentLockerId);

  bool get hasImage => (imageUrl ?? '').trim().isNotEmpty;

  /// Ảnh do admin tải lên; rỗng khi không có (UI tự vẽ nền gradient). Không
  /// còn lấy ảnh ngẫu nhiên từ picsum — ảnh đó không liên quan tới ưu đãi.
  String get effectiveImageUrl => hasImage ? imageUrl!.trim() : '';

  String get discountLabel {
    if (discountType == 'PERCENTAGE') return '-${discountValue.toInt()}%';
    final f = NumberFormat('#,###', 'vi_VN');
    return '-${f.format(discountValue)}đ';
  }

  String get shortDiscountLabel {
    if (discountType == 'PERCENTAGE') return '${discountValue.toInt()}%';
    final v = discountValue >= 1000 ? '${(discountValue / 1000).toInt()}K' : discountValue.toInt().toString();
    return '$v' 'đ';
  }

  String get expiryLabel {
    if (endAt == null) return L10n.current.promoUnlimited;
    final diff = endAt!.difference(DateTime.now());
    if (diff.isNegative) return L10n.current.promoExpired;
    if (diff.inDays > 1) return L10n.current.promoDaysLeft(diff.inDays);
    if (diff.inHours > 0) return L10n.current.promoHoursLeft(diff.inHours);
    return L10n.current.promoMinutesLeft(diff.inMinutes);
  }

  bool get isExpired {
    if (endAt == null) return false;
    return endAt!.isBefore(DateTime.now());
  }

  bool get isExpiringSoon {
    if (endAt == null) return false;
    return endAt!.difference(DateTime.now()).inHours <= 24;
  }

  String? get minOrderLabel {
    if (minOrderAmount == null || minOrderAmount == 0) return null;
    final f = NumberFormat('#,###', 'vi_VN');
    return L10n.current.promoMinOrder('${f.format(minOrderAmount)}đ');
  }
}

/// `lockerId` của khuyến mãi; 0/âm/rác ⇒ null (toàn hệ thống).
int? promotionLockerId(dynamic raw) {
  final id = raw is num ? raw.toInt() : int.tryParse('${raw ?? ''}');
  return id != null && id > 0 ? id : null;
}

/// Tên tủ duy nhất được dùng mã (thiếu tên thì mã tủ, rồi `Tủ #id`); `null`
/// khi mã dùng toàn hệ thống.
String? promotionLockerDisplayName({
  int? lockerId,
  String? lockerName,
  String? lockerCode,
}) {
  if (lockerId == null) return null;
  return _text(lockerName) ?? _text(lockerCode) ?? L10n.current.lockerHash(lockerId);
}

/// Nhãn phạm vi áp dụng của một mã: `Toàn hệ thống` hoặc
/// `Áp dụng tại: <tên tủ>`.
String promotionScopeLabel({
  int? lockerId,
  String? lockerName,
  String? lockerCode,
}) {
  final name = promotionLockerDisplayName(
    lockerId: lockerId,
    lockerName: lockerName,
    lockerCode: lockerCode,
  );
  return name == null ? L10n.current.promoSystemWide : L10n.current.promoAppliesAt(name);
}

String? _text(dynamic raw) {
  final value = raw?.toString().trim();
  return value == null || value.isEmpty ? null : value;
}
