import 'package:flutter_test/flutter_test.dart';
import 'package:smart_laundry_locker/features/transactions/domain/entities/transaction.dart';
import 'package:smart_laundry_locker/features/transactions/domain/entities/transaction_extensions.dart';
import 'package:smart_laundry_locker/features/transactions/infrastructure/models/transaction_model.dart';

Transaction _tx({
  String id = '1',
  required String type,
  required String source,
  String description = '',
  String? ref,
  int? orderId,
  String? orderCode,
  double amount = 10000,
}) => Transaction(
  id: id,
  referenceId: ref,
  relatedOrderId: orderId,
  orderCode: orderCode,
  amount: amount,
  type: type,
  source: source,
  description: description,
  balanceAfter: 0,
  createdAt: DateTime(2026, 10, 12),
);

void main() {
  test('nạp ví (TOPUP) ⇒ "Nạp tiền vào ví"', () {
    final tx = _tx(type: 'CREDIT', source: 'TOPUP', description: 'Nạp ví qua SePay');
    expect(tx.detectedService, 'TOPUP');
    expect(tx.detectedMethod, 'SEPAY');
    expect(tx.displayTitle, 'Nạp tiền vào ví');
    expect(tx.isCredit, isTrue);
  });

  test('nạp qua VNPay nhận đúng cổng', () {
    final tx = _tx(type: 'CREDIT', source: 'TOPUP', description: 'Nạp ví qua VNPay');
    expect(tx.detectedMethod, 'VNPAY');
  });

  test('CREDIT không phải lúc nào cũng là nạp tiền: hoàn tiền', () {
    final tx = _tx(
      type: 'CREDIT',
      source: 'REFUND',
      ref: 'RF-WDR-7-1700000000',
      description: 'Hoàn tiền yêu cầu rút WDR-7-1700000000 bị từ chối: sai STK',
    );
    expect(tx.detectedService, 'REFUND');
    expect(tx.detectedServiceLabel, 'Hoàn tiền');
    expect(tx.detectedMethod, 'WALLET');
    expect(tx.displayTitle, 'Hoàn tiền vào ví');
  });

  test('admin điều chỉnh số dư (ADJUST) cộng / trừ', () {
    final plus = _tx(type: 'CREDIT', source: 'ADJUST', description: 'Thưởng');
    final minus = _tx(type: 'DEBIT', source: 'ADJUST', description: 'Thu hồi');
    expect(plus.detectedService, 'ADJUST');
    expect(plus.displayTitle, 'Điều chỉnh số dư (cộng)');
    expect(minus.displayTitle, 'Điều chỉnh số dư (trừ)');
    expect(minus.detectedServiceLabel, 'Điều chỉnh số dư');
  });

  test('rút tiền: bỏ "[Chờ duyệt]" ghi cứng trong mô tả', () {
    final tx = _tx(
      type: 'DEBIT',
      source: 'WITHDRAW',
      ref: 'WDR-7-1700000000',
      description: 'Rút tiền về MB - STK: 0123 (NGUYEN VAN A) [Chờ duyệt]',
    );
    expect(tx.detectedService, 'WITHDRAW');
    expect(tx.detectedMethod, 'WITHDRAW');
    expect(tx.displayTitle, 'Rút tiền về tài khoản ngân hàng');
    expect(tx.displayDescription, 'Rút tiền về MB - STK: 0123 (NGUYEN VAN A)');
  });

  test('thanh toán đơn bằng ví theo mã đơn', () {
    final tx = _tx(
      type: 'DEBIT',
      source: 'ORDER_PAYMENT',
      ref: 'ORDERPAY-42',
      orderId: 42,
      orderCode: 'ORD-STG-42',
      description: 'Thanh toán đơn',
    );
    expect(tx.detectedService, 'RENTAL');
    expect(tx.detectedMethod, 'WALLET');
    expect(tx.displayTitle, 'Thanh toán đơn bằng ví');
    expect(tx.affectsWalletBalance, isTrue);
  });

  test('thanh toán đơn trực tiếp bằng tiền mặt (dòng id âm, không đổi số dư ví)', () {
    final tx = _tx(
      id: '-15',
      type: 'DEBIT',
      source: 'CASH',
      orderId: 9,
      description: 'Thanh toán đơn #9 qua CASH',
    );
    expect(tx.detectedMethod, 'CASH');
    expect(tx.detectedMethodLabel, 'Tiền mặt');
    expect(tx.detectedService, 'ORDER');
    expect(tx.displayTitle, 'Thanh toán đơn qua Tiền mặt');
    expect(tx.affectsWalletBalance, isFalse);
  });

  test('tổng tiền vào / tiền ra tách riêng', () {
    final totals = sumIncomeExpense([
      _tx(type: 'CREDIT', source: 'TOPUP', amount: 100000),
      _tx(type: 'CREDIT', source: 'REFUND', amount: 20000),
      _tx(type: 'DEBIT', source: 'ORDER_PAYMENT', amount: 30000),
      _tx(type: 'DEBIT', source: 'WITHDRAW', amount: 50000),
    ]);
    expect(totals.income, 120000);
    expect(totals.expense, 80000);
  });

  test('giờ giao dịch đọc LocalDateTime trần như UTC', () {
    final tx = TransactionModel.fromJson({
      'id': 3,
      'type': 'CREDIT',
      'source': 'TOPUP',
      'amount': 50000,
      'createdAt': '2026-10-12T01:30:00',
    });
    expect(tx.createdAt, DateTime.utc(2026, 10, 12, 1, 30).toLocal());
  });
}
