class Transaction {
  final String id;

  /// `WalletTransactionResponse.referenceId` — mã tham chiếu backend sinh ra
  /// (VD: `ORDERPAY-42`, `TOPUP_7_...`). Đây là "mã giao dịch" hiển thị trên app,
  /// cùng field admin web dùng làm "Mã tham chiếu" — hai bên phải luôn khớp.
  final String? referenceId;

  /// Id nội bộ của đơn liên quan, chỉ có khi [source] = `ORDER_PAYMENT`.
  final int? relatedOrderId;

  /// Mã đơn hiển thị (`ORD-...`), backend order-service resolve sẵn cho cả admin lẫn
  /// app từ cùng một chỗ (`WalletTransactionRefs` + `PaymentReferenceResolver`).
  final String? orderCode;

  final double amount;
  final String type;
  final String source;
  final String description;
  final double balanceAfter;
  final DateTime createdAt;

  const Transaction({
    required this.id,
    this.referenceId,
    this.relatedOrderId,
    this.orderCode,
    required this.amount,
    required this.type,
    required this.source,
    required this.description,
    required this.balanceAfter,
    required this.createdAt,
  });
}
