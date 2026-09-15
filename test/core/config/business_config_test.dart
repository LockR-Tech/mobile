import 'package:flutter_test/flutter_test.dart';
import 'package:smart_laundry_locker/core/config/business_config.dart';

void main() {
  final defaults = BusinessConfig.defaults();

  group('BusinessConfig.defaults', () {
    test('giữ đúng các giá trị app từng hardcode', () {
      expect(defaults.sendBaseFee, 15000);
      expect(defaults.droneDeliveryFee, 15000);
      expect(defaults.rentalRateStandard, 5000);
      expect(defaults.rentalRateXl, 10000);
      expect(defaults.rentalMinHours, 1);
      expect(defaults.rentalMaxHours, 72);
      expect(defaults.rentalDefaultHours, 4);
      expect(defaults.rentalQuickHours, [2, 4, 8, 12, 24]);
      expect(defaults.extendDefaultHours, 2);
      expect(defaults.extendMaxHours, 24);
      expect(defaults.droneDefaultParcelWeightGrams, 1200);
      expect(defaults.topupDefaultAmount, 100000);
      expect(
        defaults.topupPresets,
        [20000, 50000, 100000, 200000, 500000, 1000000],
      );
      expect(defaults.enabledPaymentMethods, ['CASH', 'WALLET', 'VNPAY', 'MOMO']);
      expect(defaults.reportPhotosPerRequestReporter, 5);
      expect(defaults.reportPhotosPerRequestStaff, 10);
      expect(defaults.cellDimensionsStandard, '45 × 30 × 50 cm');
      expect(defaults.cellDimensionsXl, '30 × 80 × 40 cm');
    });

    test('fromPublicMaps không có dữ liệu = defaults', () {
      expect(BusinessConfig.fromPublicMaps(), equals(defaults));
    });
  });

  group('BusinessConfig.fromPublicMaps', () {
    test('đọc đúng dữ liệu hợp lệ của mọi scope', () {
      final config = BusinessConfig.fromPublicMaps(
        order: {
          'app.order.send-base-fee': 18000,
          'app.order.drone-delivery-fee': 25000,
          'app.order.rental-rate-standard': 6000,
          'app.order.rental-rate-xl': 12000,
          'app.order.storage-item-fee': 7000,
          'app.order.pickup-overtime-fee-per-hour': 1000,
          'app.order.pickup-max-overtime-fee': 80000,
          'app.order.pickup-max-overtime-percent': 30,
          'app.order.send-pickup-hours-limit': 36,
          'app.order.drone-pickup-hours-limit': 12,
          'app.order.rental-min-hours': 2,
          'app.order.rental-max-hours': 48,
          'app.order.rental-default-hours': 6,
          'app.order.rental-quick-hours': [2, 6, 12],
          'app.order.extend-default-hours': 3,
          'app.order.extend-max-hours': 12,
          'app.order.require-payment-before-drop': false,
          'app.order.drone-default-parcel-weight-grams': 900,
        },
        payment: {
          'app.payment.topup-min-amount': 20000,
          'app.payment.topup-max-amount': 2000000,
          'app.payment.topup-default-amount': 50000,
          'app.payment.topup-presets': [50000, 100000],
          'app.payment.enabled-methods': 'WALLET, vnpay',
        },
        locker: {
          'app.maintenance.report-photos-per-request-reporter': 3,
          'app.maintenance.report-photos-per-request-staff': 8,
          'app.locker.cell-dimensions-standard': '40 × 40 × 40 cm',
          'app.locker.cell-dimensions-xl': '60 × 90 × 50 cm',
        },
        loyalty: {
          'app.loyalty.tier-silver-points': 600,
          'app.loyalty.tier-gold-points': 2500,
          'app.loyalty.tier-platinum-points': 6000,
          'app.loyalty.stamps-per-reward': 8,
          'app.loyalty.points-reward-cost': 1500,
        },
        store: {'app.store.nearby-default-radius-km': 7.5},
      );

      expect(config.sendBaseFee, 18000);
      expect(config.droneDeliveryFee, 25000);
      expect(config.rentalRateFor('STANDARD'), 6000);
      expect(config.rentalRateFor('XL'), 12000);
      expect(config.storageItemFee, 7000);
      expect(config.pickupOvertimeFeePerHour, 1000);
      expect(config.pickupMaxOvertimeFee, 80000);
      expect(config.pickupMaxOvertimePercent, 30);
      expect(config.sendPickupHoursLimit, 36);
      expect(config.dronePickupHoursLimit, 12);
      expect(config.rentalMinHours, 2);
      expect(config.rentalMaxHours, 48);
      expect(config.rentalDefaultHours, 6);
      expect(config.rentalQuickHours, [2, 6, 12]);
      expect(config.extendDefaultHours, 3);
      expect(config.extendMaxHours, 12);
      expect(config.requirePaymentBeforeDrop, isFalse);
      expect(config.droneDefaultParcelWeightGrams, 900);
      expect(config.topupMinAmount, 20000);
      expect(config.topupMaxAmount, 2000000);
      expect(config.topupDefaultAmount, 50000);
      expect(config.topupPresets, [50000, 100000]);
      expect(config.enabledPaymentMethods, ['WALLET', 'VNPAY']);
      expect(config.isPaymentMethodEnabled('cash'), isFalse);
      expect(config.isPaymentMethodEnabled('vnpay'), isTrue);
      expect(config.reportPhotosPerRequestReporter, 3);
      expect(config.reportPhotosPerRequestStaff, 8);
      expect(config.cellDimensionsFor('STANDARD'), '40 × 40 × 40 cm');
      expect(config.cellDimensionsFor('XL'), '60 × 90 × 50 cm');
      expect(config.tierSilverPoints, 600);
      expect(config.tierGoldPoints, 2500);
      expect(config.tierPlatinumPoints, 6000);
      expect(config.stampsPerReward, 8);
      expect(config.pointsRewardCost, 1500);
      expect(config.nearbyDefaultRadiusKm, 7.5);
    });

    test('dữ liệu một phần: key thiếu dùng mặc định', () {
      final config = BusinessConfig.fromPublicMaps(
        order: {'app.order.send-base-fee': 20000},
        payment: {'app.payment.topup-presets': '30000,60000'},
      );

      expect(config.sendBaseFee, 20000);
      expect(config.topupPresets, [30000, 60000]);
      expect(config.droneDeliveryFee, defaults.droneDeliveryFee);
      expect(config.rentalRateXl, defaults.rentalRateXl);
      expect(config.rentalQuickHours, defaults.rentalQuickHours);
      expect(config.enabledPaymentMethods, defaults.enabledPaymentMethods);
      expect(config.cellDimensionsXl, defaults.cellDimensionsXl);
      expect(config.tierGoldPoints, defaults.tierGoldPoints);
    });

    test('sai kiểu / ngoài miền hợp lệ ⇒ mặc định', () {
      final config = BusinessConfig.fromPublicMaps(
        order: {
          'app.order.send-base-fee': 'abc',
          'app.order.drone-delivery-fee': -5,
          'app.order.rental-rate-standard': 12.5,
          'app.order.rental-rate-xl': {'value': 1},
          'app.order.rental-quick-hours': 'x,y',
          'app.order.extend-max-hours': 0,
          'app.order.require-payment-before-drop': 'maybe',
          'app.order.drone-default-parcel-weight-grams': null,
        },
        payment: {
          'app.payment.topup-presets': [true, 'nope'],
          'app.payment.enabled-methods': '',
          'app.payment.topup-default-amount': false,
        },
        locker: {
          'app.maintenance.report-photos-per-request-reporter': '0',
          'app.locker.cell-dimensions-standard': '   ',
          'app.locker.cell-dimensions-xl': 42,
        },
        store: {'app.store.nearby-default-radius-km': 'far'},
      );

      expect(config, equals(defaults));
    });

    test('chấp nhận số dạng chuỗi và số thực nguyên', () {
      final config = BusinessConfig.fromPublicMaps(
        order: {
          'app.order.send-base-fee': '17000',
          'app.order.rental-rate-xl': 11000.0,
          'app.order.require-payment-before-drop': 'false',
        },
        store: {'app.store.nearby-default-radius-km': 5},
      );

      expect(config.sendBaseFee, 17000);
      expect(config.rentalRateXl, 11000);
      expect(config.requirePaymentBeforeDrop, isFalse);
      expect(config.nearbyDefaultRadiusKm, 5.0);
    });

    test('giữ ràng buộc min ≤ mặc định ≤ max cho giờ thuê và nạp ví', () {
      final swapped = BusinessConfig.fromPublicMaps(
        order: {
          'app.order.rental-min-hours': 10,
          'app.order.rental-max-hours': 5,
        },
        payment: {
          'app.payment.topup-min-amount': 900000,
          'app.payment.topup-max-amount': 100000,
        },
      );
      expect(swapped.rentalMinHours, defaults.rentalMinHours);
      expect(swapped.rentalMaxHours, defaults.rentalMaxHours);
      expect(swapped.topupMinAmount, defaults.topupMinAmount);
      expect(swapped.topupMaxAmount, defaults.topupMaxAmount);

      final clamped = BusinessConfig.fromPublicMaps(
        order: {
          'app.order.rental-min-hours': 2,
          'app.order.rental-max-hours': 10,
          'app.order.rental-default-hours': 48,
          'app.order.rental-quick-hours': [1, 4, 8, 24],
          'app.order.extend-max-hours': 6,
          'app.order.extend-default-hours': 12,
        },
        payment: {
          'app.payment.topup-min-amount': 50000,
          'app.payment.topup-max-amount': 500000,
          'app.payment.topup-default-amount': 10000,
          'app.payment.topup-presets': [20000, 1000000],
        },
      );
      expect(clamped.rentalDefaultHours, 10);
      expect(clamped.rentalQuickHours, [4, 8]);
      expect(clamped.clampRentalHours(72), 10);
      expect(clamped.extendDefaultHours, 6);
      expect(clamped.topupDefaultAmount, 50000);
      // Không mốc nào hợp lệ ⇒ còn lại đúng số tiền mặc định.
      expect(clamped.topupPresets, [50000]);
    });

    test('toPublicMaps → fromPublicMaps giữ nguyên giá trị', () {
      final original = BusinessConfig.fromPublicMaps(
        order: {'app.order.send-base-fee': 19000},
        payment: {'app.payment.enabled-methods': 'CASH'},
      );
      final maps = original.toPublicMaps();
      final restored = BusinessConfig.fromPublicMaps(
        order: maps['order'],
        payment: maps['payment'],
        locker: maps['locker'],
        loyalty: maps['loyalty'],
        store: maps['store'],
      );
      expect(restored, equals(original));
    });

    test('validateTopupAmount trả lỗi tiếng Việt khi ngoài giới hạn', () {
      String fmt(int v) => '$vđ';
      expect(defaults.validateTopupAmount(100000, fmt), isNull);
      expect(
        defaults.validateTopupAmount(1000, fmt),
        'Số tiền nạp phải từ 10000đ đến 50000000đ',
      );
      expect(defaults.validateTopupAmount(60000000, fmt), isNotNull);
    });
  });
}
