import 'package:smart_laundry_locker/core/config/business_config.dart';
import 'package:smart_laundry_locker/features/locker_ops/presentation/widgets/ops_widgets.dart';

/// Chuỗi hiển thị dựng từ [BusinessConfig] (giá trị admin cấu hình).
/// Chỉ để xem — server luôn tự tính tiền.

/// `5.000đ/giờ`.
String hourlyRateLabel(int rate) => '${fmtPrice(rate)}/giờ';

/// `Phí quá giờ 500đ/giờ (tối đa 50.000đ và 50% giá trị đơn).`
String overtimePolicyText(BusinessConfig config) {
  if (config.pickupOvertimeFeePerHour <= 0) {
    return 'Không tính phí quá giờ.';
  }
  final caps = <String>[
    if (config.pickupMaxOvertimeFee > 0) fmtPrice(config.pickupMaxOvertimeFee),
    if (config.pickupMaxOvertimePercent > 0)
      '${config.pickupMaxOvertimePercent}% giá trị đơn',
  ];
  final capText = caps.isEmpty ? '' : ' (tối đa ${caps.join(' và ')})';
  return 'Phí quá giờ ${hourlyRateLabel(config.pickupOvertimeFeePerHour)}'
      '$capText.';
}

/// Hạn lấy hàng của đơn gửi qua tủ + chính sách phí quá giờ.
String sendPickupPolicyText(BusinessConfig config) =>
    'Người nhận có ${config.sendPickupHoursLimit} giờ để lấy hàng kể từ lúc '
    'bạn bỏ hàng vào ô. ${overtimePolicyText(config)}';

/// Hạn lấy hàng của đơn giao bằng drone + chính sách phí quá giờ.
String dronePickupPolicyText(BusinessConfig config) =>
    'Người nhận có ${config.dronePickupHoursLimit} giờ để lấy hàng kể từ lúc '
    'drone thả hàng vào ô. ${overtimePolicyText(config)}';
