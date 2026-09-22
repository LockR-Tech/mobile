class TopUpRequestDto {
  final int amount;
  final String returnUrl;
  final String bankCode;
  final String locale;
  final String method;

  const TopUpRequestDto({
    required this.amount,
    required this.returnUrl,
    this.bankCode = '',
    this.locale = 'vn',
    this.method = 'VNPAY',
  });

  Map<String, dynamic> toJson() => {
    'amount': amount,
    'returnUrl': returnUrl,
    'bankCode': bankCode,
    'locale': locale,
    'method': method,
  };
}
