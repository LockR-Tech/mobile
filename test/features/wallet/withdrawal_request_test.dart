import 'package:flutter_test/flutter_test.dart';
import 'package:smart_laundry_locker/features/wallet/domain/withdrawal_request.dart';

void main() {
  test('đọc yêu cầu rút tiền từ GET /api/wallet/withdrawals', () {
    final w = WithdrawalRequest.fromJson({
      'id': 12,
      'referenceId': 'WDR-7-1700000000',
      'amount': 150000,
      'bankName': 'MB - Ngân hàng Quân đội',
      'bankCode': 'MB',
      'accountNumber': '0123456789',
      'accountHolderName': 'NGUYEN VAN A',
      'status': 'REJECTED',
      'rejectionReason': '  Sai tên chủ tài khoản ',
      'createdAt': '2026-10-12T01:00:00',
      'processedAt': null,
    });

    expect(w.id, 12);
    expect(w.amount, 150000);
    expect(w.status, WithdrawalStatus.rejected);
    expect(w.rejectionReason, 'Sai tên chủ tài khoản');
    expect(w.statusLabel, contains('Bị từ chối'));
    expect(w.maskedAccountNumber, '•••• 6789');
    expect(w.createdAt, DateTime.utc(2026, 10, 12, 1).toLocal());
    expect(w.processedAt, isNull);
  });

  test('nhãn trạng thái đúng nghĩa (không còn "Giao dịch thành công" cho đơn chờ duyệt)', () {
    expect(withdrawalStatusLabel(parseWithdrawalStatus('PENDING')), 'Chờ duyệt');
    expect(
      withdrawalStatusLabel(parseWithdrawalStatus('COMPLETED')),
      'Đã chuyển khoản',
    );
    expect(parseWithdrawalStatus('weird'), WithdrawalStatus.unknown);
  });

  test('lý do từ chối rỗng ⇒ null', () {
    final w = WithdrawalRequest.fromJson({
      'id': 1,
      'status': 'PENDING',
      'rejectionReason': '',
      'amount': '50000',
    });
    expect(w.rejectionReason, isNull);
    expect(w.amount, 50000);
  });
}
