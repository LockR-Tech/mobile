import 'package:smart_laundry_locker/core/errors/failures.dart';
import 'package:smart_laundry_locker/features/auth/domain/entities/auth_token_entity.dart';
import 'package:smart_laundry_locker/features/auth/domain/repositories/auth_repository.dart';
import 'package:dartz/dartz.dart';

class LoginUseCase {
  final AuthRepository _repository;

  LoginUseCase(this._repository);

  Future<Either<Failure, AuthTokenEntity>> call(LoginParams params) async {
    return await _repository.login(
      email: params.email,
      password: params.password,
    );
  }
}

class LoginParams {
  final String email;
  final String password;

  const LoginParams({required this.email, required this.password});

  factory LoginParams.fromForm({
    required String email,
    required String password,
  }) {
    return LoginParams(email: email, password: password);
  }
}
