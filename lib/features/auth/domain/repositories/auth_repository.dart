import 'package:smart_laundry_locker/features/auth/domain/entities/face_verify_result_entity.dart';
import 'package:dartz/dartz.dart';
import 'dart:typed_data';
import 'package:smart_laundry_locker/core/errors/failures.dart';
import 'package:smart_laundry_locker/features/auth/domain/entities/auth_token_entity.dart';
import 'package:smart_laundry_locker/features/auth/domain/entities/register_entity.dart';

abstract class AuthRepository {
  Future<Either<Failure, RegisterEntity>> register({
    required String phoneNumber,
    String? fullName,
    String? email,
    String? password,
  });

  Future<Either<Failure, AuthTokenEntity>> login({
    required String email,
    required String password,
  });

  Future<Either<Failure, FaceVerifyResultEntity>> loginWithFace({
    required Uint8List imageBytes,
  });

  Future<Either<Failure, AuthTokenEntity>> firebaseLogin({
    required String idToken,
  });

  Future<Either<Failure, AuthTokenEntity>> verifyOtp({
    String? phoneNumber,
    String? email,
    required String otp,
  });

  Future<Either<Failure, void>> sendEmailLoginOtp(String email);
  Future<Either<Failure, AuthTokenEntity>> verifyEmailLoginOtp(String email, String otp);

  Future<Either<Failure, bool>> confirmQrLogin(String sessionId);

  Future<Either<Failure, bool>> faceRegister({
    required String userId,
    required List<Uint8List> imagesBytes,
  });

  Future<Either<Failure, bool>> sendPasswordResetOtp({required String email});

  Future<Either<Failure, bool>> resetPassword({
    required String email,
    required String otp,
    required String newPassword,
    required String confirmPassword,
  });
}
