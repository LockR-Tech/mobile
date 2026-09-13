import 'package:json_annotation/json_annotation.dart';

part 'qr_confirm_response_model.g.dart';

@JsonSerializable()
class QrConfirmResponseModel {
  @JsonKey(defaultValue: true)
  final bool success;

  const QrConfirmResponseModel({this.success = true});

  factory QrConfirmResponseModel.fromJson(Map<String, dynamic> json) =>
      _$QrConfirmResponseModelFromJson(json);

  Map<String, dynamic> toJson() => _$QrConfirmResponseModelToJson(this);
}
