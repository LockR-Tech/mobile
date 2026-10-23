import 'package:smart_laundry_locker/core/config/business_config.dart';
import 'package:smart_laundry_locker/features/locker_ops/presentation/widgets/ops_widgets.dart';

/// Chuỗi hiển thị dựng từ [BusinessConfig] (giá trị admin cấu hình).
/// Chỉ để xem — server luôn tự tính tiền.

/// `5.000đ/giờ`.
String hourlyRateLabel(int rate) => '${fmtPrice(rate)}/giờ';

/// `5.000đ/giờ · 40.000đ/ngày` — bỏ phần ngày khi loại ô không có giá ngày.
String rentalRateLabel(BusinessConfig config, String cellType) {
  final hourly = hourlyRateLabel(config.rentalRateFor(cellType));
  final daily = config.rentalDailyRateFor(cellType);
  return daily > 0 ? '$hourly · ${fmtPrice(daily)}/ngày' : hourly;
}

/// `Thuê từ 1 giờ đến 30 ngày. Thuê từ 8 giờ trong một ngày chỉ tính giá ngày 40.000đ.`
String rentalDurationPolicyText(BusinessConfig config, String cellType) {
  String span(int hours) =>
      hours >= 48 && hours % 24 == 0 ? '${hours ~/ 24} ngày' : '$hours giờ';
  final range =
      'Thuê từ ${span(config.rentalMinHours)} đến ${span(config.rentalMaxHours)}.';
  final hourly = config.rentalRateFor(cellType);
  final daily = config.rentalDailyRateFor(cellType);
  if (daily <= 0 || hourly <= 0) return range;
  final capFrom = (daily / hourly).ceil();
  if (capFrom >= 24) return '$range Mỗi 24 giờ tính ${fmtPrice(daily)}.';
  return '$range Thuê từ $capFrom giờ trong một ngày chỉ tính giá ngày '
      '${fmtPrice(daily)}.';
}

/// `Quá giờ thuê tính 5.000đ/giờ cho tới khi lấy đồ hoặc gia hạn.`
String rentalOvertimePolicyText(BusinessConfig config, String cellType) =>
    'Quá giờ thuê tính '
    '${hourlyRateLabel(config.rentalOvertimeFeePerHourFor(cellType))} '
    'cho tới khi lấy đồ hoặc gia hạn.';

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

/// Cách tích điểm: `Tích 1 điểm cho mỗi 1.000đ bạn thanh toán, cộng khi đơn hoàn tất.`
String loyaltyEarnRuleText(BusinessConfig config) =>
    'Tích 1 điểm cho mỗi ${fmtPrice(config.loyaltyVndPerPoint)} bạn thanh '
    'toán, cộng khi đơn hoàn tất.';

/// Cách dùng điểm khi thanh toán:
/// `1 điểm = 100đ khi thanh toán, dùng tối đa 50% giá trị đơn (từ 10 điểm).`
String loyaltyRedeemRuleText(BusinessConfig config) {
  if (!config.redeemEnabled) {
    return 'Hiện chưa áp dụng dùng điểm để thanh toán.';
  }
  final min = config.redeemMinPoints > 0
      ? ' (từ ${config.redeemMinPoints} điểm)'
      : '';
  return '1 điểm = ${fmtPrice(config.redeemVndPerPoint)} khi thanh toán, dùng '
      'tối đa ${config.redeemMaxPercent}% giá trị đơn$min.';
}
