import 'package:json_annotation/json_annotation.dart';

part 'login_request_model.g.dart';

@JsonSerializable()
class LoginRequestModel {
  @JsonKey(name: 'email')
  final String email;

  @JsonKey(name: 'password')
  final String password;

  const LoginRequestModel({required this.email, required this.password});

  factory LoginRequestModel.fromJson(Map<String, dynamic> json) =>
      _$LoginRequestModelFromJson(json);

  Map<String, dynamic> toJson() => _$LoginRequestModelToJson(this);

  factory LoginRequestModel.fromForm({
    required String email,
    required String password,
  }) {
    return LoginRequestModel(email: email, password: password);
  }
}
