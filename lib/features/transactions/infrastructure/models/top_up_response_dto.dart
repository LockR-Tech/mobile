class TopUpResponseDto {
  final String paymentUrl;
  final String txnRef;

  const TopUpResponseDto({required this.paymentUrl, required this.txnRef});

  factory TopUpResponseDto.fromJson(Map<String, dynamic> json) {
    return TopUpResponseDto(
      paymentUrl: (json['paymentUrl'] as String?)?.trim() ?? '',
      txnRef: (json['txnRef'] as String?)?.trim() ?? '',
    );
  }
}
