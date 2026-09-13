class RegisterEntity {
  final bool success;
  final String? message;
  final String? userId;

  const RegisterEntity({required this.success, this.message, this.userId});

  factory RegisterEntity.success({String? message, String? userId}) {
    return RegisterEntity(success: true, message: message, userId: userId);
  }

  factory RegisterEntity.failure({String? message}) {
    return RegisterEntity(success: false, message: message);
  }
}
