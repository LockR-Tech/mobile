class TopUpRequestDto {
  final int amount;
  final String returnUrl;
  final String bankCode;
  final String locale;

  const TopUpRequestDto({
    required this.amount,
    required this.returnUrl,
    this.bankCode = '',
    this.locale = 'vn',
  });

  Map<String, dynamic> toJson() => {
    'amount': amount,
    'returnUrl': returnUrl,
    'bankCode': bankCode,
    'locale': locale,
  };
}
