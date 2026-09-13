import 'package:smart_laundry_locker/core/errors/failures.dart';
import 'package:smart_laundry_locker/features/auth/domain/entities/register_entity.dart';
import 'package:smart_laundry_locker/features/auth/domain/repositories/auth_repository.dart';
import 'package:dartz/dartz.dart';

class RegisterUseCase {
  final AuthRepository _repository;

  RegisterUseCase(this._repository);

  Future<Either<Failure, RegisterEntity>> call(RegisterParams params) async {
    return await _repository.register(
      phoneNumber: params.phoneNumber,
      fullName: params.fullName,
      email: params.email,
      password: params.password,
    );
  }
}

class RegisterParams {
  final String phoneNumber;
  final String? fullName;
  final String? email;
  final String? password;

  const RegisterParams({
    required this.phoneNumber,
    this.fullName,
    this.email,
    this.password,
  });

  factory RegisterParams.fromForm({
    required String phoneNumber,
    String? fullName,
    String? email,
    String? password,
  }) {
    return RegisterParams(
      phoneNumber: phoneNumber,
      fullName: fullName,
      email: email,
      password: password,
    );
  }
}
