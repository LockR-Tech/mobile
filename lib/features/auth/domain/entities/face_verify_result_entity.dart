import 'package:smart_laundry_locker/features/auth/domain/entities/auth_token_entity.dart';

class FaceVerifyResultEntity {
  final AuthTokenEntity? token;
  final String? matchedUserId;

  const FaceVerifyResultEntity._({
    required this.token,
    required this.matchedUserId,
  });

  const FaceVerifyResultEntity.token(AuthTokenEntity token)
    : this._(token: token, matchedUserId: null);

  const FaceVerifyResultEntity.matchedUserId(String matchedUserId)
    : this._(token: null, matchedUserId: matchedUserId);

  bool get isTokenVerified => token != null;
}
