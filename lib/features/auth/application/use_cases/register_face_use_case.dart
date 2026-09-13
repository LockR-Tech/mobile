import 'dart:typed_data';
import 'package:smart_laundry_locker/core/errors/failures.dart';
import 'package:smart_laundry_locker/features/auth/domain/repositories/auth_repository.dart';
import 'package:dartz/dartz.dart';

class RegisterFaceUseCase {
  final AuthRepository _repository;

  RegisterFaceUseCase(this._repository);

  Future<Either<Failure, bool>> call(RegisterFaceParams params) async {
    return _repository.faceRegister(
      userId: params.userId,
      imagesBytes: params.imagesBytes,
    );
  }
}

class RegisterFaceParams {
  final String userId;
  final List<Uint8List> imagesBytes;

  const RegisterFaceParams({required this.userId, required this.imagesBytes});
}
