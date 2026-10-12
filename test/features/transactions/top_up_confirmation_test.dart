import 'package:flutter_test/flutter_test.dart';
import 'package:smart_laundry_locker/features/transactions/domain/entities/transaction.dart';
import 'package:smart_laundry_locker/features/transactions/domain/top_up_confirmation.dart';

Transaction _tx({
  String id = '1',
  String? ref,
  String type = 'CREDIT',
  String source = 'TOPUP',
  double amount = 50000,
}) => Transaction(
  id: id,
  referenceId: ref,
  amount: amount,
  type: type,
  source: source,
  description: 'Nạp ví qua SePay',
  balanceAfter: 0,
  createdAt: DateTime(2026, 10, 12),
);

Future<void> _noDelay(Duration _) async {}

void main() {
  test('tìm thấy giao dịch nạp khớp txnRef ở lần hỏi thứ 3 ⇒ confirmed', () async {
    var calls = 0;
    final result = await waitForTopUpCredit(
      txnRef: 'TOPUP_7_123',
      delay: _noDelay,
      fetchTransactions: () async {
        calls++;
        return calls < 3
            ? [_tx(ref: 'OTHER')]
            : [_tx(ref: 'OTHER'), _tx(id: '9', ref: 'TOPUP_7_123', amount: 70000)];
      },
    );

    expect(result.isConfirmed, isTrue);
    expect(result.transaction!.id, '9');
    expect(result.transaction!.amount, 70000);
    expect(calls, 3);
  });

  test('hết số lần hỏi mà chưa có ⇒ pending (không báo thành công)', () async {
    var calls = 0;
    final result = await waitForTopUpCredit(
      txnRef: 'TOPUP_7_123',
      attempts: 4,
      delay: _noDelay,
      fetchTransactions: () async {
        calls++;
        return [_tx(ref: 'KHAC')];
      },
    );

    expect(result.status, TopUpConfirmationStatus.pending);
    expect(result.transaction, isNull);
    expect(calls, 4);
  });

  test('dòng trừ tiền trùng mã không được tính là nạp thành công', () async {
    final result = await waitForTopUpCredit(
      txnRef: 'REF1',
      attempts: 1,
      delay: _noDelay,
      fetchTransactions: () async => [_tx(ref: 'REF1', type: 'DEBIT')],
    );
    expect(result.isConfirmed, isFalse);
  });

  test('lỗi mạng ở một lần hỏi không dừng vòng lặp', () async {
    var calls = 0;
    final result = await waitForTopUpCredit(
      txnRef: 'REF1',
      delay: _noDelay,
      fetchTransactions: () async {
        calls++;
        if (calls == 1) throw Exception('timeout');
        return [_tx(ref: 'REF1')];
      },
    );
    expect(result.isConfirmed, isTrue);
    expect(calls, 2);
  });

  test('không có txnRef ⇒ không đối chiếu được ⇒ pending ngay, không gọi API', () async {
    var calls = 0;
    final result = await waitForTopUpCredit(
      txnRef: '  ',
      delay: _noDelay,
      fetchTransactions: () async {
        calls++;
        return [_tx(ref: '')];
      },
    );
    expect(result.status, TopUpConfirmationStatus.pending);
    expect(calls, 0);
  });

  test('người dùng bấm "Kiểm tra sau" ⇒ dừng hỏi', () async {
    var calls = 0;
    var cancelled = false;
    final result = await waitForTopUpCredit(
      txnRef: 'REF1',
      attempts: 20,
      delay: (_) async => cancelled = true,
      isCancelled: () => cancelled,
      fetchTransactions: () async {
        calls++;
        return const [];
      },
    );
    expect(result.status, TopUpConfirmationStatus.pending);
    expect(calls, 1);
  });

  test('mặc định chờ khoảng 60 giây (20 lần × 3 giây)', () async {
    final waits = <Duration>[];
    await waitForTopUpCredit(
      txnRef: 'REF1',
      delay: (d) async => waits.add(d),
      fetchTransactions: () async => const [],
    );
    final total = waits.fold(Duration.zero, (a, b) => a + b);
    expect(total, const Duration(seconds: 57));
    expect(waits.length, 19);
  });

  test('findTopUpCredit bỏ qua khoảng trắng của mã', () {
    expect(findTopUpCredit([_tx(ref: ' REF1 ')], 'REF1'), isNotNull);
    expect(findTopUpCredit([_tx(ref: 'REF1')], ''), isNull);
  });
}
