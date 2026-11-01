import 'package:smart_laundry_locker/core/config/business_config.dart';
import 'package:smart_laundry_locker/core/utils/app_date_time.dart';
import 'package:smart_laundry_locker/features/locker_ops/presentation/widgets/ops_widgets.dart';
import 'package:smart_laundry_locker/core/l10n/l10n.dart';

/// Chuỗi hiển thị dựng từ [BusinessConfig] (giá trị admin cấu hình).
/// Chỉ để xem — server luôn tự tính tiền.

/// `5.000đ/giờ`.
String hourlyRateLabel(int rate) => L10n.current.pricePerHour(fmtPrice(rate));

/// `5.000đ/giờ · 40.000đ/ngày` — bỏ phần ngày khi loại ô không có giá ngày.
String rentalRateLabel(BusinessConfig config, String cellType) {
  final hourly = hourlyRateLabel(config.rentalRateFor(cellType));
  final daily = config.rentalDailyRateFor(cellType);
  return daily > 0
      ? '$hourly · ${L10n.current.pricePerDay(fmtPrice(daily))}'
      : hourly;
}

/// `Thuê từ 1 giờ đến 30 ngày. Thuê từ 8 giờ trong một ngày chỉ tính giá ngày 40.000đ.`
String rentalDurationPolicyText(BusinessConfig config, String cellType) {
  String span(int hours) =>
      hours >= 48 && hours % 24 == 0
          ? L10n.current.daysValue(hours ~/ 24)
          : L10n.current.hoursValue(hours);
  final range = L10n.current.rulesRentRange(
    span(config.rentalMinHours),
    span(config.rentalMaxHours),
  );
  final hourly = config.rentalRateFor(cellType);
  final daily = config.rentalDailyRateFor(cellType);
  if (daily <= 0 || hourly <= 0) return range;
  final capFrom = (daily / hourly).ceil();
  if (capFrom >= 24) {
    return '$range ${L10n.current.rulesEvery24h(fmtPrice(daily))}';
  }
  return '$range ${L10n.current.rulesDailyCapFrom(capFrom, fmtPrice(daily))}';
}

/// `Quá giờ thuê tính 5.000đ/giờ cho tới khi lấy đồ hoặc gia hạn.`
String rentalOvertimePolicyText(BusinessConfig config, String cellType) =>
    L10n.current.rulesRentalOvertime(
      hourlyRateLabel(config.rentalOvertimeFeePerHourFor(cellType)),
    );

/// `Phí quá giờ 500đ/giờ (tối đa 50.000đ và 50% giá trị đơn).`
String overtimePolicyText(BusinessConfig config) {
  if (config.pickupOvertimeFeePerHour <= 0) {
    return L10n.current.rulesNoOvertimeFee;
  }
  final caps = <String>[
    if (config.pickupMaxOvertimeFee > 0) fmtPrice(config.pickupMaxOvertimeFee),
    if (config.pickupMaxOvertimePercent > 0)
      L10n.current.rulesPercentOfOrder(config.pickupMaxOvertimePercent),
  ];
  final capText = caps.isEmpty
      ? ''
      : L10n.current.rulesCapSuffix(caps.join(L10n.current.rulesAnd));
  return L10n.current.rulesOvertimeFee(
    hourlyRateLabel(config.pickupOvertimeFeePerHour),
    capText,
  );
}

/// Hạn lấy hàng của đơn gửi qua tủ + chính sách phí quá giờ.
String sendPickupPolicyText(BusinessConfig config) =>
    L10n.current.rulesSendPickup(
      config.sendPickupHoursLimit,
      overtimePolicyText(config),
    );

/// Hạn lấy hàng của đơn giao bằng drone + chính sách phí quá giờ. Hạn được tính
/// lúc drone thả hàng nên trước đó chưa có giờ cụ thể, xem [droneStoredUntilText].
String dronePickupPolicyText(BusinessConfig config) =>
    L10n.current.rulesDronePickup(
      config.dronePickupHoursLimit,
      overtimePolicyText(config),
    );

/// `Đơn hàng được lưu trữ 24 giờ, vui lòng lấy trước 14:30 ngày 01/11/2026.`
String droneStoredUntilText(int hours, DateTime deadline) =>
    L10n.current.rulesDroneStoredUntil(hours, formatDeadlineVn(deadline));

/// Cách tích điểm, quy ra % số tiền theo giá trị 1 điểm khi dùng:
/// `Tích 10% số tiền bạn thanh toán thành điểm (1 điểm = 1đ), cộng khi đơn hoàn tất.`
String loyaltyEarnRuleText(BusinessConfig config) {
  final perPoint = config.loyaltyVndPerPoint < 1 ? 1 : config.loyaltyVndPerPoint;
  final percent = ((config.redeemVndPerPoint * 100 / perPoint) * 10).round() / 10;
  final label = percent == percent.roundToDouble()
      ? percent.toInt().toString()
      : percent.toStringAsFixed(1).replaceAll('.', ',');
  return L10n.current.rulesLoyaltyEarn(
    label,
    fmtPrice(config.redeemVndPerPoint),
  );
}

/// Cách dùng điểm khi thanh toán:
/// `1 điểm = 1đ khi thanh toán, dùng tối đa 50% giá trị đơn (từ 1000 điểm).`
String loyaltyRedeemRuleText(BusinessConfig config) {
  if (!config.redeemEnabled) {
    return L10n.current.rulesRedeemDisabled;
  }
  final min = config.redeemMinPoints > 0
      ? L10n.current.rulesRedeemMin(config.redeemMinPoints)
      : '';
  return L10n.current.rulesRedeem(
    fmtPrice(config.redeemVndPerPoint),
    config.redeemMaxPercent,
    min,
  );
}
