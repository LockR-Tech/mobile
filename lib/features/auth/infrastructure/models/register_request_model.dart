import 'package:json_annotation/json_annotation.dart';

part 'register_request_model.g.dart';

@JsonSerializable()
class RegisterRequestModel {
  @JsonKey(name: 'phoneNumber')
  final String phoneNumber;

  @JsonKey(name: 'password', includeIfNull: false)
  final String? password;

  @JsonKey(name: 'fullName', includeIfNull: false)
  final String? fullName;

  @JsonKey(name: 'email', includeIfNull: false)
  final String? email;

  @JsonKey(name: 'role')
  final String role;

  @JsonKey(name: 'notificationType')
  final String notificationType;

  const RegisterRequestModel({
    required this.phoneNumber,
    this.password,
    this.fullName,
    this.email,
    this.role = 'CUSTOMER',
    this.notificationType = 'EMAIL',
  });

  factory RegisterRequestModel.fromJson(Map<String, dynamic> json) =>
      _$RegisterRequestModelFromJson(json);

  Map<String, dynamic> toJson() => _$RegisterRequestModelToJson(this);

  factory RegisterRequestModel.fromForm({
    required String phoneNumber,
    String? fullName,
    String? email,
    String? password,
  }) {
    return RegisterRequestModel(
      phoneNumber: phoneNumber,
      fullName: fullName,
      email: email,
      password: password,
      role: 'CUSTOMER',
      notificationType: 'EMAIL',
    );
  }
}
