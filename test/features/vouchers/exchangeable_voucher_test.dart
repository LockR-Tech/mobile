import 'package:flutter_test/flutter_test.dart';
import 'package:smart_laundry_locker/features/vouchers/data/models/exchangeable_voucher_model.dart';
import 'package:smart_laundry_locker/features/vouchers/presentation/widgets/points_exchange_tab.dart';

void main() {
  test('đọc voucher đổi điểm từ /api/promotions/exchangeable', () {
    final v = ExchangeableVoucherModel.fromJson({
      'id': 36,
      'code': 'DOIDIEM10K',
      'name': 'Đổi điểm — giảm 10.000đ',
      'discountType': 'FIXED_AMOUNT',
      'discountValue': 10000.00,
      'minOrderAmount': 0,
      'pointsCost': 10000,
      'held': true,
      'lockerId': null,
    });
    expect(v.id, 36);
    expect(v.pointsCost, 10000);
    expect(v.held, isTrue);
    expect(v.lockerId, isNull);
    expect(exchangeVoucherRewardText(v), 'Giảm 10.000đ');
    expect(fmtPointsText(200000), '200.000 điểm');
  });

  test('voucher phần trăm hiện mức trần', () {
    final v = ExchangeableVoucherModel.fromJson({
      'id': 1,
      'code': 'DOI15P',
      'discountType': 'PERCENTAGE',
      'discountValue': 15,
      'maxDiscountAmount': 30000,
      'pointsCost': 15000,
    });
    expect(v.held, isFalse);
    expect(exchangeVoucherRewardText(v), 'Giảm 15% (tối đa 30.000đ)');
  });

  test('kết quả đổi: số điểm đã trừ và số dư còn lại', () {
    final r = VoucherExchangeOutcome.fromJson({
      'voucher': {'code': 'DOIDIEM10K'},
      'pointsSpent': 10000,
      'balance': 190000,
    });
    expect(r.pointsSpent, 10000);
    expect(r.balance, 190000);
  });
}
