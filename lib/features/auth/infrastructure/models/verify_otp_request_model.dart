import 'package:json_annotation/json_annotation.dart';

part 'verify_otp_request_model.g.dart';

@JsonSerializable()
class VerifyOtpRequestModel {
  @JsonKey(name: 'phoneNumber', includeIfNull: false)
  final String? phoneNumber;

  @JsonKey(name: 'email', includeIfNull: false)
  final String? email;

  @JsonKey(name: 'otp')
  final String otp;

  const VerifyOtpRequestModel({
    this.phoneNumber,
    this.email,
    required this.otp,
  });

  factory VerifyOtpRequestModel.fromJson(Map<String, dynamic> json) =>
      _$VerifyOtpRequestModelFromJson(json);

  Map<String, dynamic> toJson() => _$VerifyOtpRequestModelToJson(this);

  factory VerifyOtpRequestModel.fromForm({
    String? phoneNumber,
    String? email,
    required String otp,
  }) {
    return VerifyOtpRequestModel(
      phoneNumber: phoneNumber,
      email: email,
      otp: otp,
    );
  }
}
