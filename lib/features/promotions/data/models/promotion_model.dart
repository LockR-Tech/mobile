import 'package:intl/intl.dart';
import 'package:smart_laundry_locker/core/utils/app_date_time.dart';

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
    );
  }

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
    if (endAt == null) return 'Không giới hạn';
    final diff = endAt!.difference(DateTime.now());
    if (diff.isNegative) return 'Đã hết hạn';
    if (diff.inDays > 1) return 'Còn ${diff.inDays} ngày';
    if (diff.inHours > 0) return 'Còn ${diff.inHours} giờ';
    return 'Còn ${diff.inMinutes} phút';
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
    return 'Đơn tối thiểu ${f.format(minOrderAmount)}đ';
  }
}
