import 'package:smart_laundry_locker/features/auth/domain/entities/auth_token_entity.dart';
import 'package:json_annotation/json_annotation.dart';

part 'auth_token_model.g.dart';

@JsonSerializable()
class AuthTokenModel {
  @JsonKey(name: 'accessToken')
  final String accessToken;

  @JsonKey(name: 'refreshToken')
  final String refreshToken;

  const AuthTokenModel({required this.accessToken, required this.refreshToken});

  factory AuthTokenModel.fromJson(Map<String, dynamic> json) =>
      _$AuthTokenModelFromJson(json);

  Map<String, dynamic> toJson() => _$AuthTokenModelToJson(this);

  AuthTokenEntity toEntity() {
    return AuthTokenEntity(
      accessToken: accessToken,
      refreshToken: refreshToken,
    );
  }
}
