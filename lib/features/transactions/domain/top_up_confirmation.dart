import 'package:smart_laundry_locker/features/transactions/domain/entities/transaction.dart';
import 'package:smart_laundry_locker/features/transactions/domain/entities/transaction_extensions.dart';

/// Kết quả xác nhận nạp ví sau khi rời cổng thanh toán.
enum TopUpConfirmationStatus {
  /// Ví đã có giao dịch cộng tiền với `referenceId == txnRef`.
  confirmed,

  /// Hết thời gian chờ mà chưa thấy giao dịch — có thể webhook SePay
  /// tới muộn. KHÔNG được báo thành công.
  pending,
}

class TopUpConfirmation {
  final TopUpConfirmationStatus status;

  /// Giao dịch cộng tiền khớp mã (khi [status] là confirmed).
  final Transaction? transaction;

  const TopUpConfirmation._(this.status, this.transaction);

  const TopUpConfirmation.pending() : this._(TopUpConfirmationStatus.pending, null);

  const TopUpConfirmation.confirmed(Transaction transaction)
    : this._(TopUpConfirmationStatus.confirmed, transaction);

  bool get isConfirmed => status == TopUpConfirmationStatus.confirmed;
}

/// Giao dịch nạp ví khớp [txnRef] trong [transactions] (hoặc `null`).
///
/// payment-service cộng ví với `referenceId` = mã tham chiếu thanh toán
/// (`txnRef` trả về khi tạo link nạp), nguồn `TOPUP`.
Transaction? findTopUpCredit(Iterable<Transaction> transactions, String txnRef) {
  final ref = txnRef.trim();
  if (ref.isEmpty) return null;
  for (final tx in transactions) {
    if ((tx.referenceId ?? '').trim() == ref && tx.isCredit) return tx;
  }
  return null;
}

/// Hỏi lại lịch sử ví cho tới khi thấy giao dịch nạp khớp [txnRef].
///
/// Trang quay về của SePay chỉ cho biết trình duyệt đã quay lại, KHÔNG
/// chứng minh tiền đã vào ví (return SePay chỉ đọc trạng thái; tiền cộng khi
/// webhook/IPN tới). Vì vậy chỉ báo thành công khi chính ví có giao dịch.
///
/// - Hỏi tối đa [attempts] lần, cách nhau [interval] (mặc định 20 × 3 s ≈ 60 s).
/// - Lỗi mạng ở một lần hỏi không dừng vòng lặp.
/// - [isCancelled] trả `true` (người dùng bấm "Kiểm tra sau") ⇒ dừng, pending.
/// - Không có [txnRef] ⇒ không thể đối chiếu ⇒ pending ngay.
Future<TopUpConfirmation> waitForTopUpCredit({
  required String txnRef,
  required Future<List<Transaction>> Function() fetchTransactions,
  int attempts = 20,
  Duration interval = const Duration(seconds: 3),
  Future<void> Function(Duration duration)? delay,
  bool Function()? isCancelled,
}) async {
  if (txnRef.trim().isEmpty) return const TopUpConfirmation.pending();
  final wait = delay ?? Future<void>.delayed;
  final tries = attempts < 1 ? 1 : attempts;

  for (var i = 0; i < tries; i++) {
    if (isCancelled?.call() ?? false) break;
    try {
      final match = findTopUpCredit(await fetchTransactions(), txnRef);
      if (match != null) return TopUpConfirmation.confirmed(match);
    } catch (_) {
      // Mạng chập chờn: thử lại ở lần sau.
    }
    if (i < tries - 1) {
      if (isCancelled?.call() ?? false) break;
      await wait(interval);
    }
  }
  return const TopUpConfirmation.pending();
}
