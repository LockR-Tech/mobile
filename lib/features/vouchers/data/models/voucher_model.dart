import 'package:smart_laundry_locker/core/utils/app_date_time.dart';
import 'package:smart_laundry_locker/features/promotions/data/models/promotion_model.dart';

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
  final String? lockerCode;
  final String? lockerName;

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
    this.lockerCode,
    this.lockerName,
  });

  factory VoucherModel.fromJson(Map<String, dynamic> json) {
    final discountType =
        (json['discountType'] as String?)?.toUpperCase() ?? 'FIXED_AMOUNT';
    final rawStatus = (json['status'] as String?)?.toUpperCase() ?? 'SAVED';
    return VoucherModel(
      id: '${json['id'] ?? ''}',
      code: json['code'] as String? ?? '',
      status: rawStatus == 'SAVED' ? 'UNUSED' : rawStatus,
      // LocalDateTime trần (UTC) ⇒ đọc bằng hàm chung để HSD không lệch 7 giờ.
      expiresAt: parseServerDateTime(json['endAt']),
      rewardValue:
          double.tryParse((json['discountValue'] ?? 0).toString()) ?? 0.0,
      campaignId: '${json['promotionId'] ?? ''}',
      campaignTitle: json['name'] as String? ?? '',
      rewardType: discountType == 'PERCENTAGE'
          ? 'DISCOUNT_PERCENT'
          : 'DISCOUNT_FIXED',
      giftDescription: json['description'] as String? ?? '',
      lockerId: promotionLockerId(json['lockerId']),
      lockerCode: json['lockerCode']?.toString(),
      lockerName: json['lockerName']?.toString(),
    );
  }

  /// `Áp dụng tại: Tủ A` hoặc `Toàn hệ thống`.
  String get scopeLabel => promotionScopeLabel(
    lockerId: lockerId,
    lockerName: lockerName,
    lockerCode: lockerCode,
  );
}
