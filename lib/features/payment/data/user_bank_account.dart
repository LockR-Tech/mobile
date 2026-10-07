class UserBankAccount {
  final int? id;
  final int? userId;
  final String bankName;
  final String bankCode;
  final String accountNumber;
  final String accountHolderName;

  UserBankAccount({
    this.id,
    this.userId,
    required this.bankName,
    required this.bankCode,
    required this.accountNumber,
    required this.accountHolderName,
  });

  factory UserBankAccount.fromJson(Map<String, dynamic> json) {
    return UserBankAccount(
      id: json['id'] is int ? json['id'] as int : int.tryParse('${json['id']}'),
      userId: json['userId'] is int ? json['userId'] as int : int.tryParse('${json['userId']}'),
      bankName: json['bankName'] as String? ?? '',
      bankCode: json['bankCode'] as String? ?? '',
      accountNumber: json['accountNumber'] as String? ?? '',
      accountHolderName: json['accountHolderName'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'bankName': bankName,
      'bankCode': bankCode,
      'accountNumber': accountNumber,
      'accountHolderName': accountHolderName,
    };
  }
}
