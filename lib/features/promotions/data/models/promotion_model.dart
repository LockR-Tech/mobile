import 'package:intl/intl.dart';

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
      startAt: json['startAt'] != null ? DateTime.tryParse(json['startAt'].toString()) : null,
      endAt: json['endAt'] != null ? DateTime.tryParse(json['endAt'].toString()) : null,
    );
  }

  /// Luôn trả về URL ảnh hợp lệ: backend imageUrl nếu có, fallback ảnh đẹp theo seed
  String get effectiveImageUrl {
    if (imageUrl != null && imageUrl!.isNotEmpty) return imageUrl!;
    return 'https://picsum.photos/seed/promo$id/600/400';
  }

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
