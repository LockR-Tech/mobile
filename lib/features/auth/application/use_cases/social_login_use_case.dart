import 'package:dartz/dartz.dart';
import 'package:smart_laundry_locker/core/errors/failures.dart';
import 'package:smart_laundry_locker/features/auth/domain/entities/auth_token_entity.dart';
import 'package:smart_laundry_locker/features/auth/domain/repositories/auth_repository.dart';

class SocialLoginUseCase {
  final AuthRepository _repository;

  SocialLoginUseCase(this._repository);

  Future<Either<Failure, AuthTokenEntity>> call(String idToken) {
    return _repository.firebaseLogin(idToken: idToken);
  }
}
