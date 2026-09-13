class Transaction {
  final String id;
  final String code;
  final String walletId;
  final String? orderId;
  final double amount;
  final String type;
  final String description;
  final double balanceAfter;
  final DateTime createdAt;

  const Transaction({
    required this.id,
    required this.code,
    required this.walletId,
    this.orderId,
    required this.amount,
    required this.type,
    required this.description,
    required this.balanceAfter,
    required this.createdAt,
  });
}
