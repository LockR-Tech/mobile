import 'package:json_annotation/json_annotation.dart';

part 'qr_confirm_request_model.g.dart';

@JsonSerializable()
class QrConfirmRequestModel {
  final String sessionId;

  const QrConfirmRequestModel({required this.sessionId});

  factory QrConfirmRequestModel.fromJson(Map<String, dynamic> json) =>
      _$QrConfirmRequestModelFromJson(json);

  Map<String, dynamic> toJson() => _$QrConfirmRequestModelToJson(this);
}
