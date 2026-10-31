import 'package:smart_laundry_locker/core/utils/app_date_time.dart';

/// Một mốc đã xảy ra của đơn — `OrderMilestone` của order-service: `milestones`
/// trong `OrderResponse` (Đơn của tôi) và `timeline` trong chi tiết đơn phía
/// người nhận. Nhãn tiếng Việt do server dựng, app hiện thẳng.
class OrderMilestone {
  const OrderMilestone({
    required this.label,
    this.code,
    this.occurredAt,
    this.latitude,
    this.longitude,
    this.locationSource,
  });

  /// CREATED, PAID, DROP_OPENED, PARCEL_DROPPED, STORED, DELEGATED, BLOCKED,
  /// FAILED, EXPIRED, PARCEL_RETURNED, CANCELED, COMPLETED — hoặc chặng drone
  /// khi dùng cho hành trình.
  final String? code;
  final String label;
  final DateTime? occurredAt;

  /// Kiện ở đâu lúc đạt mốc — chỉ có ở hành trình drone (xem `DroneJourneyStep`).
  final double? latitude;
  final double? longitude;
  final String? locationSource;

  static OrderMilestone? tryParse(dynamic raw) {
    if (raw is! Map) return null;
    final label = '${raw['label'] ?? ''}'.trim();
    if (label.isEmpty) return null;
    final code = '${raw['code'] ?? ''}'.trim().toUpperCase();
    return OrderMilestone(
      label: label,
      code: code.isEmpty ? null : code,
      occurredAt: parseServerDateTime(raw['occurredAt']),
    );
  }

  /// Bỏ phần tử hỏng thay vì làm hỏng cả danh sách; server cũ không có trường
  /// này ⇒ danh sách rỗng.
  static List<OrderMilestone> listFrom(dynamic raw) {
    if (raw is! List) return const [];
    return raw.map(tryParse).whereType<OrderMilestone>().toList(growable: false);
  }
}

/// Khai báo kiện hàng của đơn — `OrderParcelView` của order-service (`parcel`
/// trong `OrderResponse` và chi tiết đơn phía người nhận). Mọi trường tuỳ chọn.
class OrderParcel {
  const OrderParcel({
    this.description,
    this.weightGrams,
    this.actualWeight,
    this.weightUnit,
    this.lengthCm,
    this.widthCm,
    this.heightCm,
    this.category,
    this.declaredValue,
    this.fragile,
    this.prohibitedItemsDeclaredAt,
  });

  final String? description;

  /// Cân nặng khai báo của đơn drone (gram).
  final int? weightGrams;

  /// Cân nặng ước tính của đơn tủ, theo [weightUnit].
  final num? actualWeight;
  final String? weightUnit;
  final int? lengthCm;
  final int? widthCm;
  final int? heightCm;
  final String? category;
  final num? declaredValue;
  final bool? fragile;
  final DateTime? prohibitedItemsDeclaredAt;

  static OrderParcel? tryParse(dynamic raw) {
    if (raw is! Map) return null;
    final parcel = OrderParcel(
      description: _text(raw['description']),
      weightGrams: _int(raw['weightGrams']),
      actualWeight: _num(raw['actualWeight']),
      weightUnit: _text(raw['weightUnit']),
      lengthCm: _int(raw['lengthCm']),
      widthCm: _int(raw['widthCm']),
      heightCm: _int(raw['heightCm']),
      category: _text(raw['category']),
      declaredValue: _num(raw['declaredValue']),
      fragile: raw['fragile'] is bool ? raw['fragile'] as bool : null,
      prohibitedItemsDeclaredAt: parseServerDateTime(
        raw['prohibitedItemsDeclaredAt'],
      ),
    );
    return parcel.isEmpty ? null : parcel;
  }

  bool get isEmpty =>
      description == null &&
      weightGrams == null &&
      actualWeight == null &&
      lengthCm == null &&
      widthCm == null &&
      heightCm == null &&
      category == null &&
      declaredValue == null &&
      fragile == null &&
      prohibitedItemsDeclaredAt == null;
}

int? _int(dynamic v) {
  if (v is int) return v;
  if (v is num) return v.toInt();
  return int.tryParse('${v ?? ''}');
}

num? _num(dynamic v) {
  if (v is num) return v;
  return num.tryParse('${v ?? ''}');
}

String? _text(dynamic v) {
  if (v == null) return null;
  final s = '$v'.trim();
  return s.isEmpty ? null : s;
}
