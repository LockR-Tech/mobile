import 'dart:convert';

import 'package:flutter/foundation.dart';

/// Quy tắc nghiệp vụ (giá, phí, thời hạn, giới hạn…) do admin cấu hình.
///
/// App đọc từ `GET /api/settings/{scope}/public` (xem ADR-0005). Mọi giá trị
/// ở đây **chỉ để hiển thị / kiểm tra phía client** — server luôn tự tính tiền
/// và tự kiểm tra lại giới hạn.
///
/// [BusinessConfig.defaults] giữ các giá trị app từng hardcode: khi backend
/// chưa triển khai (404/5xx) hoặc trả thiếu/sai kiểu một key, app dùng giá trị
/// mặc định tương ứng và vẫn chạy bình thường.
@immutable
class BusinessConfig {
  const BusinessConfig({
    required this.sendBaseFee,
    required this.droneDeliveryFee,
    required this.rentalRateStandard,
    required this.rentalRateXl,
    required this.storageItemFee,
    required this.pickupOvertimeFeePerHour,
    required this.pickupMaxOvertimeFee,
    required this.pickupMaxOvertimePercent,
    required this.sendPickupHoursLimit,
    required this.dronePickupHoursLimit,
    required this.rentalMinHours,
    required this.rentalMaxHours,
    required this.rentalDefaultHours,
    required this.rentalQuickHours,
    required this.extendDefaultHours,
    required this.extendMaxHours,
    required this.requirePaymentBeforeDrop,
    required this.droneDefaultParcelWeightGrams,
    required this.topupMinAmount,
    required this.topupMaxAmount,
    required this.topupDefaultAmount,
    required this.topupPresets,
    required this.enabledPaymentMethods,
    required this.reportPhotosPerRequestReporter,
    required this.reportPhotosPerRequestStaff,
    required this.cellDimensionsStandard,
    required this.cellDimensionsXl,
    required this.tierSilverPoints,
    required this.tierGoldPoints,
    required this.tierPlatinumPoints,
    required this.stampsPerReward,
    required this.pointsRewardCost,
    required this.nearbyDefaultRadiusKm,
  });

  // ---- Scope `order` ----
  /// Phí mỗi đơn gửi hàng (VND).
  final int sendBaseFee;

  /// Phí mỗi đơn giao bằng drone (VND).
  final int droneDeliveryFee;

  /// Giá thuê ô STANDARD mỗi giờ (VND/giờ).
  final int rentalRateStandard;

  /// Giá thuê ô XL mỗi giờ (VND/giờ).
  final int rentalRateXl;

  /// Đơn giá mỗi món khi lưu trữ (VND).
  final int storageItemFee;

  /// Phí quá hạn mỗi giờ (VND/giờ).
  final int pickupOvertimeFeePerHour;

  /// Trần phí quá hạn (VND).
  final int pickupMaxOvertimeFee;

  /// Trần phí quá hạn theo % tổng tiền đơn.
  final int pickupMaxOvertimePercent;

  /// Số giờ người nhận có để lấy hàng gửi (tính từ lúc bỏ hàng).
  final int sendPickupHoursLimit;

  /// Số giờ người nhận có để lấy hàng drone (tính từ lúc drone thả hàng).
  final int dronePickupHoursLimit;

  final int rentalMinHours;
  final int rentalMaxHours;
  final int rentalDefaultHours;

  /// Nút chọn nhanh số giờ thuê.
  final List<int> rentalQuickHours;

  final int extendDefaultHours;
  final int extendMaxHours;

  /// Chặn xác nhận bỏ hàng / kết thúc thuê khi đơn chưa thanh toán.
  final bool requirePaymentBeforeDrop;

  final int droneDefaultParcelWeightGrams;

  // ---- Scope `payment` ----
  final int topupMinAmount;
  final int topupMaxAmount;
  final int topupDefaultAmount;
  final List<int> topupPresets;

  /// Mã phương thức thanh toán đang bật, viết hoa (`CASH`, `WALLET`, …).
  final List<String> enabledPaymentMethods;

  // ---- Scope `locker` ----
  /// Số ảnh hiện trường tối đa mỗi lần người báo gửi (stage REPORT).
  final int reportPhotosPerRequestReporter;

  /// Số ảnh tối đa mỗi lần KTV/admin gửi (INSPECTION/PROGRESS/RESOLUTION).
  final int reportPhotosPerRequestStaff;

  /// Kích thước ô hiển thị trên app (dài × rộng × cao).
  final String cellDimensionsStandard;
  final String cellDimensionsXl;

  // ---- Scope `loyalty` ----
  final int tierSilverPoints;
  final int tierGoldPoints;
  final int tierPlatinumPoints;
  final int stampsPerReward;
  final int pointsRewardCost;

  // ---- Scope `store` ----
  /// Bán kính tìm cửa hàng gần đây mặc định (km).
  final double nearbyDefaultRadiusKm;

  /// Các scope app đọc từ `/api/settings/{scope}/public`.
  static const scopes = ['order', 'payment', 'locker', 'loyalty', 'store'];

  static const _defaults = BusinessConfig(
    sendBaseFee: 15000,
    droneDeliveryFee: 15000,
    rentalRateStandard: 5000,
    rentalRateXl: 10000,
    storageItemFee: 5000,
    pickupOvertimeFeePerHour: 500,
    pickupMaxOvertimeFee: 50000,
    pickupMaxOvertimePercent: 50,
    sendPickupHoursLimit: 48,
    dronePickupHoursLimit: 24,
    rentalMinHours: 1,
    rentalMaxHours: 72,
    rentalDefaultHours: 4,
    rentalQuickHours: [2, 4, 8, 12, 24],
    extendDefaultHours: 2,
    extendMaxHours: 24,
    requirePaymentBeforeDrop: true,
    droneDefaultParcelWeightGrams: 1200,
    topupMinAmount: 10000,
    topupMaxAmount: 50000000,
    topupDefaultAmount: 100000,
    topupPresets: [20000, 50000, 100000, 200000, 500000, 1000000],
    enabledPaymentMethods: ['CASH', 'WALLET', 'VNPAY', 'MOMO'],
    reportPhotosPerRequestReporter: 5,
    reportPhotosPerRequestStaff: 10,
    cellDimensionsStandard: '45 × 30 × 50 cm',
    cellDimensionsXl: '30 × 80 × 40 cm',
    tierSilverPoints: 500,
    tierGoldPoints: 2000,
    tierPlatinumPoints: 5000,
    stampsPerReward: 10,
    pointsRewardCost: 1000,
    nearbyDefaultRadiusKm: 10,
  );

  /// Giá trị mặc định = các giá trị app dùng trước khi có cấu hình admin.
  factory BusinessConfig.defaults() => _defaults;

  /// Dựng cấu hình từ `data` của từng scope public. Scope `null` (không tải
  /// được), key thiếu, sai kiểu hoặc ngoài miền hợp lệ ⇒ dùng mặc định.
  factory BusinessConfig.fromPublicMaps({
    Map<String, dynamic>? order,
    Map<String, dynamic>? payment,
    Map<String, dynamic>? locker,
    Map<String, dynamic>? loyalty,
    Map<String, dynamic>? store,
  }) {
    const d = _defaults;
    final o = order ?? const <String, dynamic>{};
    final p = payment ?? const <String, dynamic>{};
    final l = locker ?? const <String, dynamic>{};
    final y = loyalty ?? const <String, dynamic>{};
    final s = store ?? const <String, dynamic>{};

    // Thuê tủ: min ≤ mặc định ≤ max, nút nhanh nằm trong [min, max].
    var rentalMin = _int(o['app.order.rental-min-hours'], d.rentalMinHours, min: 1);
    var rentalMax = _int(o['app.order.rental-max-hours'], d.rentalMaxHours, min: 1);
    if (rentalMin > rentalMax) {
      rentalMin = d.rentalMinHours;
      rentalMax = d.rentalMaxHours;
    }
    final rentalDefault = _int(
      o['app.order.rental-default-hours'],
      d.rentalDefaultHours,
      min: 1,
    ).clamp(rentalMin, rentalMax);
    var quickHours = _intList(
      o['app.order.rental-quick-hours'],
      d.rentalQuickHours,
    ).where((h) => h >= rentalMin && h <= rentalMax).toList(growable: false);
    if (quickHours.isEmpty) quickHours = [rentalDefault];

    final extendMax = _int(o['app.order.extend-max-hours'], d.extendMaxHours, min: 1);
    final extendDefault = _int(
      o['app.order.extend-default-hours'],
      d.extendDefaultHours,
      min: 1,
    ).clamp(1, extendMax);

    // Nạp ví: min ≤ mặc định ≤ max, mốc nạp nhanh nằm trong [min, max].
    var topupMin = _int(p['app.payment.topup-min-amount'], d.topupMinAmount, min: 1);
    var topupMax = _int(p['app.payment.topup-max-amount'], d.topupMaxAmount, min: 1);
    if (topupMin > topupMax) {
      topupMin = d.topupMinAmount;
      topupMax = d.topupMaxAmount;
    }
    final topupDefault = _int(
      p['app.payment.topup-default-amount'],
      d.topupDefaultAmount,
      min: 1,
    ).clamp(topupMin, topupMax);
    var presets = _intList(p['app.payment.topup-presets'], d.topupPresets)
        .where((a) => a >= topupMin && a <= topupMax)
        .toList(growable: false);
    if (presets.isEmpty) presets = [topupDefault];

    return BusinessConfig(
      sendBaseFee: _int(o['app.order.send-base-fee'], d.sendBaseFee),
      droneDeliveryFee: _int(o['app.order.drone-delivery-fee'], d.droneDeliveryFee),
      rentalRateStandard: _int(o['app.order.rental-rate-standard'], d.rentalRateStandard),
      rentalRateXl: _int(o['app.order.rental-rate-xl'], d.rentalRateXl),
      storageItemFee: _int(o['app.order.storage-item-fee'], d.storageItemFee),
      pickupOvertimeFeePerHour: _int(
        o['app.order.pickup-overtime-fee-per-hour'],
        d.pickupOvertimeFeePerHour,
      ),
      pickupMaxOvertimeFee: _int(
        o['app.order.pickup-max-overtime-fee'],
        d.pickupMaxOvertimeFee,
      ),
      pickupMaxOvertimePercent: _int(
        o['app.order.pickup-max-overtime-percent'],
        d.pickupMaxOvertimePercent,
      ),
      sendPickupHoursLimit: _int(
        o['app.order.send-pickup-hours-limit'],
        d.sendPickupHoursLimit,
        min: 1,
      ),
      dronePickupHoursLimit: _int(
        o['app.order.drone-pickup-hours-limit'],
        d.dronePickupHoursLimit,
        min: 1,
      ),
      rentalMinHours: rentalMin,
      rentalMaxHours: rentalMax,
      rentalDefaultHours: rentalDefault,
      rentalQuickHours: List.unmodifiable(quickHours),
      extendDefaultHours: extendDefault,
      extendMaxHours: extendMax,
      requirePaymentBeforeDrop: _bool(
        o['app.order.require-payment-before-drop'],
        d.requirePaymentBeforeDrop,
      ),
      droneDefaultParcelWeightGrams: _int(
        o['app.order.drone-default-parcel-weight-grams'],
        d.droneDefaultParcelWeightGrams,
        min: 1,
      ),
      topupMinAmount: topupMin,
      topupMaxAmount: topupMax,
      topupDefaultAmount: topupDefault,
      topupPresets: List.unmodifiable(presets),
      enabledPaymentMethods: List.unmodifiable(
        _methods(p['app.payment.enabled-methods'], d.enabledPaymentMethods),
      ),
      reportPhotosPerRequestReporter: _int(
        l['app.maintenance.report-photos-per-request-reporter'],
        d.reportPhotosPerRequestReporter,
        min: 1,
      ),
      reportPhotosPerRequestStaff: _int(
        l['app.maintenance.report-photos-per-request-staff'],
        d.reportPhotosPerRequestStaff,
        min: 1,
      ),
      cellDimensionsStandard: _string(
        l['app.locker.cell-dimensions-standard'],
        d.cellDimensionsStandard,
      ),
      cellDimensionsXl: _string(l['app.locker.cell-dimensions-xl'], d.cellDimensionsXl),
      tierSilverPoints: _int(y['app.loyalty.tier-silver-points'], d.tierSilverPoints),
      tierGoldPoints: _int(y['app.loyalty.tier-gold-points'], d.tierGoldPoints),
      tierPlatinumPoints: _int(
        y['app.loyalty.tier-platinum-points'],
        d.tierPlatinumPoints,
      ),
      stampsPerReward: _int(y['app.loyalty.stamps-per-reward'], d.stampsPerReward, min: 1),
      pointsRewardCost: _int(y['app.loyalty.points-reward-cost'], d.pointsRewardCost, min: 1),
      nearbyDefaultRadiusKm: _double(
        s['app.store.nearby-default-radius-km'],
        d.nearbyDefaultRadiusKm,
      ),
    );
  }

  // ---- Tiện ích hiển thị ----

  /// Giá thuê mỗi giờ theo loại ô (`XL` hoặc mọi loại khác = STANDARD).
  int rentalRateFor(String cellType) =>
      cellType.toUpperCase() == 'XL' ? rentalRateXl : rentalRateStandard;

  /// Kích thước ô hiển thị theo loại ô.
  String cellDimensionsFor(String cellType) =>
      cellType.toUpperCase() == 'XL' ? cellDimensionsXl : cellDimensionsStandard;

  bool isPaymentMethodEnabled(String method) =>
      enabledPaymentMethods.contains(method.toUpperCase());

  /// Kéo số giờ thuê về trong [rentalMinHours, rentalMaxHours].
  int clampRentalHours(num hours) =>
      hours.round().clamp(rentalMinHours, rentalMaxHours);

  /// Kiểm tra số tiền nạp. Trả `null` nếu hợp lệ, ngược lại là thông báo lỗi.
  String? validateTopupAmount(int amount, String Function(int) formatMoney) {
    if (amount < topupMinAmount || amount > topupMaxAmount) {
      return 'Số tiền nạp phải từ ${formatMoney(topupMinAmount)} '
          'đến ${formatMoney(topupMaxAmount)}';
    }
    return null;
  }

  /// Dữ liệu dạng `/public` của từng scope — dùng để lưu last-known value.
  Map<String, Map<String, dynamic>> toPublicMaps() => {
    'order': {
      'app.order.send-base-fee': sendBaseFee,
      'app.order.drone-delivery-fee': droneDeliveryFee,
      'app.order.rental-rate-standard': rentalRateStandard,
      'app.order.rental-rate-xl': rentalRateXl,
      'app.order.storage-item-fee': storageItemFee,
      'app.order.pickup-overtime-fee-per-hour': pickupOvertimeFeePerHour,
      'app.order.pickup-max-overtime-fee': pickupMaxOvertimeFee,
      'app.order.pickup-max-overtime-percent': pickupMaxOvertimePercent,
      'app.order.send-pickup-hours-limit': sendPickupHoursLimit,
      'app.order.drone-pickup-hours-limit': dronePickupHoursLimit,
      'app.order.rental-min-hours': rentalMinHours,
      'app.order.rental-max-hours': rentalMaxHours,
      'app.order.rental-default-hours': rentalDefaultHours,
      'app.order.rental-quick-hours': rentalQuickHours,
      'app.order.extend-default-hours': extendDefaultHours,
      'app.order.extend-max-hours': extendMaxHours,
      'app.order.require-payment-before-drop': requirePaymentBeforeDrop,
      'app.order.drone-default-parcel-weight-grams': droneDefaultParcelWeightGrams,
    },
    'payment': {
      'app.payment.topup-min-amount': topupMinAmount,
      'app.payment.topup-max-amount': topupMaxAmount,
      'app.payment.topup-default-amount': topupDefaultAmount,
      'app.payment.topup-presets': topupPresets,
      'app.payment.enabled-methods': enabledPaymentMethods.join(','),
    },
    'locker': {
      'app.maintenance.report-photos-per-request-reporter':
          reportPhotosPerRequestReporter,
      'app.maintenance.report-photos-per-request-staff':
          reportPhotosPerRequestStaff,
      'app.locker.cell-dimensions-standard': cellDimensionsStandard,
      'app.locker.cell-dimensions-xl': cellDimensionsXl,
    },
    'loyalty': {
      'app.loyalty.tier-silver-points': tierSilverPoints,
      'app.loyalty.tier-gold-points': tierGoldPoints,
      'app.loyalty.tier-platinum-points': tierPlatinumPoints,
      'app.loyalty.stamps-per-reward': stampsPerReward,
      'app.loyalty.points-reward-cost': pointsRewardCost,
    },
    'store': {'app.store.nearby-default-radius-km': nearbyDefaultRadiusKm},
  };

  String get _signature => jsonEncode(toPublicMaps());

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BusinessConfig && other._signature == _signature;

  @override
  int get hashCode => _signature.hashCode;

  @override
  String toString() => 'BusinessConfig($_signature)';

  // ---- Parser chịu lỗi ----

  static int _int(dynamic raw, int fallback, {int min = 0}) {
    int? value;
    if (raw is int) {
      value = raw;
    } else if (raw is num && raw.isFinite && raw == raw.roundToDouble()) {
      value = raw.toInt();
    } else if (raw is String) {
      value = int.tryParse(raw.trim());
    }
    return value != null && value >= min ? value : fallback;
  }

  static double _double(dynamic raw, double fallback) {
    double? value;
    if (raw is num) {
      value = raw.toDouble();
    } else if (raw is String) {
      value = double.tryParse(raw.trim());
    }
    return value != null && value.isFinite && value > 0 ? value : fallback;
  }

  static bool _bool(dynamic raw, bool fallback) {
    if (raw is bool) return raw;
    if (raw is String) {
      switch (raw.trim().toLowerCase()) {
        case 'true':
          return true;
        case 'false':
          return false;
      }
    }
    return fallback;
  }

  static String _string(dynamic raw, String fallback) {
    if (raw is String && raw.trim().isNotEmpty) return raw.trim();
    return fallback;
  }

  /// Nhận `[2, 4, 8]` hoặc `"2,4,8"`. Phần tử sai bị bỏ; rỗng ⇒ mặc định.
  static List<int> _intList(dynamic raw, List<int> fallback) {
    final Iterable<dynamic> items;
    if (raw is List) {
      items = raw;
    } else if (raw is String) {
      items = raw.split(',');
    } else {
      return fallback;
    }
    final values = <int>[];
    for (final item in items) {
      final v = _int(item, -1, min: 1);
      if (v > 0 && !values.contains(v)) values.add(v);
    }
    if (values.isEmpty) return fallback;
    values.sort();
    return values;
  }

  /// Nhận `"CASH,WALLET"` hoặc `["CASH", "WALLET"]`. Rỗng/sai ⇒ mặc định
  /// (không bao giờ ẩn hết phương thức thanh toán vì dữ liệu hỏng).
  static List<String> _methods(dynamic raw, List<String> fallback) {
    final Iterable<dynamic> items;
    if (raw is String) {
      items = raw.split(',');
    } else if (raw is List) {
      items = raw;
    } else {
      return fallback;
    }
    final values = <String>[];
    for (final item in items) {
      if (item is! String) continue;
      final code = item.trim().toUpperCase();
      if (code.isNotEmpty && !values.contains(code)) values.add(code);
    }
    return values.isEmpty ? fallback : values;
  }
}
