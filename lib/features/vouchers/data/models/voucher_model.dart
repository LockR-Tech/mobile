/// Một voucher trong ví (promotion_claims + thông tin promotion đi kèm).
/// Backend trả: {id (claimId), promotionId, code, name, description,
/// discountType, discountValue, maxDiscountAmount, minOrderAmount, lockerId,
/// status (SAVED/USED/EXPIRED), savedAt, usedAt, startAt, endAt, ...}.
/// Giữ tên field cũ của UI (rewardType/campaignTitle...) để không phải sửa
/// các trang hiển thị.
class VoucherModel {
  final String id;
  final String code;
  final String status; // UNUSED, USED, EXPIRED (map từ SAVED/USED/EXPIRED)
  final DateTime? expiresAt;
  final double rewardValue;
  final String campaignId;
  final String campaignTitle;
  final String rewardType; // DISCOUNT_PERCENT | DISCOUNT_FIXED
  final String giftDescription;

  /// Mã chỉ áp dụng tại một tủ/kiosk cụ thể (null = toàn hệ thống).
  final int? lockerId;

  VoucherModel({
    required this.id,
    required this.code,
    required this.status,
    this.expiresAt,
    required this.rewardValue,
    required this.campaignId,
    required this.campaignTitle,
    required this.rewardType,
    required this.giftDescription,
    this.lockerId,
  });

  factory VoucherModel.fromJson(Map<String, dynamic> json) {
    final discountType =
        (json['discountType'] as String?)?.toUpperCase() ?? 'FIXED_AMOUNT';
    final rawStatus = (json['status'] as String?)?.toUpperCase() ?? 'SAVED';
    return VoucherModel(
      id: '${json['id'] ?? ''}',
      code: json['code'] as String? ?? '',
      status: rawStatus == 'SAVED' ? 'UNUSED' : rawStatus,
      expiresAt: json['endAt'] != null
          ? DateTime.tryParse(json['endAt'].toString())
          : null,
      rewardValue:
          double.tryParse((json['discountValue'] ?? 0).toString()) ?? 0.0,
      campaignId: '${json['promotionId'] ?? ''}',
      campaignTitle: json['name'] as String? ?? '',
      rewardType: discountType == 'PERCENTAGE'
          ? 'DISCOUNT_PERCENT'
          : 'DISCOUNT_FIXED',
      giftDescription: json['description'] as String? ?? '',
      lockerId: (json['lockerId'] as num?)?.toInt(),
    );
  }
}
