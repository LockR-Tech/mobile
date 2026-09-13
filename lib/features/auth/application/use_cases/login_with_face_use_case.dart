import 'package:smart_laundry_locker/core/errors/failures.dart';
import 'package:smart_laundry_locker/features/auth/domain/entities/face_verify_result_entity.dart';
import 'package:smart_laundry_locker/features/auth/domain/repositories/auth_repository.dart';
import 'package:dartz/dartz.dart';
import 'dart:typed_data';

class LoginWithFaceUseCase {
  final AuthRepository _repository;

  LoginWithFaceUseCase(this._repository);

  Future<Either<Failure, FaceVerifyResultEntity>> call(
    LoginWithFaceParams params,
  ) async {
    return _repository.loginWithFace(imageBytes: params.imageBytes);
  }
}

class LoginWithFaceParams {
  final Uint8List imageBytes;

  const LoginWithFaceParams({required this.imageBytes});
}
