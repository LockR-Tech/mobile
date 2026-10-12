import 'package:flutter/material.dart';
import 'package:smart_laundry_locker/core/utils/app_date_time.dart';

/// Trạng thái yêu cầu rút tiền (payment-service `withdrawal_requests.status`).
enum WithdrawalStatus { pending, completed, rejected, unknown }

WithdrawalStatus parseWithdrawalStatus(String? raw) {
  switch ((raw ?? '').trim().toUpperCase()) {
    case 'PENDING':
      return WithdrawalStatus.pending;
    case 'COMPLETED':
    case 'APPROVED':
      return WithdrawalStatus.completed;
    case 'REJECTED':
      return WithdrawalStatus.rejected;
    default:
      return WithdrawalStatus.unknown;
  }
}

String withdrawalStatusLabel(WithdrawalStatus status) {
  switch (status) {
    case WithdrawalStatus.pending:
      return 'Chờ duyệt';
    case WithdrawalStatus.completed:
      return 'Đã chuyển khoản';
    case WithdrawalStatus.rejected:
      return 'Bị từ chối · đã hoàn tiền vào ví';
    case WithdrawalStatus.unknown:
      return 'Không rõ trạng thái';
  }
}

Color withdrawalStatusColor(WithdrawalStatus status) {
  switch (status) {
    case WithdrawalStatus.pending:
      return const Color(0xFFD97706);
    case WithdrawalStatus.completed:
      return const Color(0xFF16A34A);
    case WithdrawalStatus.rejected:
      return const Color(0xFFDC2626);
    case WithdrawalStatus.unknown:
      return const Color(0xFF64748B);
  }
}

/// Một yêu cầu rút tiền của chính người dùng (`GET /api/wallet/withdrawals`).
class WithdrawalRequest {
  final int id;

  /// `WDR-{userId}-{ms}` — trùng `referenceId` của giao dịch ví trừ tiền.
  final String referenceId;
  final double amount;
  final String bankName;
  final String accountNumber;
  final String accountHolderName;
  final WithdrawalStatus status;
  final String? rejectionReason;
  final DateTime? createdAt;
  final DateTime? processedAt;

  const WithdrawalRequest({
    required this.id,
    required this.referenceId,
    required this.amount,
    required this.bankName,
    required this.accountNumber,
    required this.accountHolderName,
    required this.status,
    this.rejectionReason,
    this.createdAt,
    this.processedAt,
  });

  factory WithdrawalRequest.fromJson(Map<String, dynamic> json) {
    final amount = json['amount'];
    final reason = json['rejectionReason']?.toString().trim();
    return WithdrawalRequest(
      id: json['id'] is num
          ? (json['id'] as num).toInt()
          : int.tryParse('${json['id']}') ?? 0,
      referenceId: json['referenceId']?.toString() ?? '',
      amount: amount is num
          ? amount.toDouble()
          : double.tryParse('$amount') ?? 0,
      bankName: json['bankName']?.toString() ?? '',
      accountNumber: json['accountNumber']?.toString() ?? '',
      accountHolderName: json['accountHolderName']?.toString() ?? '',
      status: parseWithdrawalStatus(json['status']?.toString()),
      rejectionReason: (reason == null || reason.isEmpty) ? null : reason,
      createdAt: parseServerDateTime(json['createdAt']),
      processedAt: parseServerDateTime(json['processedAt']),
    );
  }

  String get statusLabel => withdrawalStatusLabel(status);

  /// STK chỉ hiện 4 số cuối.
  String get maskedAccountNumber {
    final n = accountNumber.trim();
    if (n.length <= 4) return n;
    return '•••• ${n.substring(n.length - 4)}';
  }
}
