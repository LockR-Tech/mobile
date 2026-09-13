import 'dart:convert';
import 'dart:typed_data';

import 'package:smart_laundry_locker/core/errors/failures.dart';
import 'package:smart_laundry_locker/core/network/api_client.dart';
import 'package:smart_laundry_locker/core/services/token_service.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:smart_laundry_locker/features/auth/domain/entities/auth_token_entity.dart';
import 'package:smart_laundry_locker/features/auth/domain/entities/face_verify_result_entity.dart';
import 'package:smart_laundry_locker/features/auth/domain/entities/register_entity.dart';
import 'package:smart_laundry_locker/features/auth/domain/repositories/auth_repository.dart';
import 'package:smart_laundry_locker/features/auth/infrastructure/data_sources/auth_remote_data_source.dart';
import 'package:smart_laundry_locker/features/auth/infrastructure/models/auth_token_model.dart';
import 'package:smart_laundry_locker/features/auth/infrastructure/models/login_request_model.dart';
import 'package:smart_laundry_locker/features/auth/infrastructure/models/qr_confirm_request_model.dart';
import 'package:smart_laundry_locker/features/auth/infrastructure/models/qr_confirm_response_model.dart';
import 'package:smart_laundry_locker/features/auth/infrastructure/models/register_request_model.dart';
import 'package:smart_laundry_locker/features/auth/infrastructure/models/verify_otp_request_model.dart';
import 'package:dartz/dartz.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource _remoteDataSource;

  AuthRepositoryImpl({required AuthRemoteDataSource remoteDataSource})
    : _remoteDataSource = remoteDataSource;

  @override
  Future<Either<Failure, RegisterEntity>> register({
    required String phoneNumber,
    String? fullName,
    String? email,
    String? password,
  }) async {
    try {
      final request = RegisterRequestModel.fromForm(
        phoneNumber: phoneNumber,
        fullName: fullName,
        email: email,
        password: password,
      );

      final response = await _remoteDataSource.register(request);

      final success = response['success'] as bool? ?? true;
      final message = response['message'] as String?;
      final userId =
          response['userId'] as String? ??
          response['id'] as String? ??
          response['user']?['id'] as String?;

      // check nếu saga trả về success: false (saga rollback hoặc lỗi)
      if (success == false) {
        return Right(
          RegisterEntity.failure(
            message: message ?? 'Đăng ký thất bại. Vui lòng thử lại.',
          ),
        );
      }

      return Right(
        RegisterEntity.success(
          message: message ?? 'Registration successful',
          userId: userId,
        ),
      );
    } on ServerException catch (e) {
      return Left(_mapRegisterBackendFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on ValidationException catch (e) {
      return Left(_mapRegisterBackendFailure(e.message));
    } on AuthenticationException catch (e) {
      return Left(AuthenticationFailure(e.message));
    } on AuthorizationException catch (e) {
      return Left(AuthorizationFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, AuthTokenEntity>> login({
    required String email,
    required String password,
  }) async {
    try {
      final request = LoginRequestModel.fromForm(
        email: email,
        password: password,
      );

      final response = await _remoteDataSource.login(request);

      final tokenModel = AuthTokenModel.fromJson(response);
      return Right(tokenModel.toEntity());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on ValidationException catch (e) {
      return Left(ValidationFailure(e.message));
    } on AuthenticationException catch (e) {
      return Left(AuthenticationFailure(e.message));
    } on AuthorizationException catch (e) {
      return Left(AuthorizationFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, FaceVerifyResultEntity>> loginWithFace({
    required Uint8List imageBytes,
  }) async {
    try {
      final compressedBytes = await FlutterImageCompress.compressWithList(
        imageBytes,
        minWidth: 640,
        minHeight: 480,
        quality: 60,
        format: CompressFormat.jpeg,
      );

      final imageBase64 = base64Encode(compressedBytes);

      final response = await _remoteDataSource.faceVerify(
        imageBase64: imageBase64,
        threshold: 0.8,
      );

      final dynamic auth = response['auth'];
      final dynamic accessTokenRaw =
          auth?['accessToken'] ??
          auth?['access_token'] ??
          response['accessToken'] ??
          response['access_token'];
      final dynamic refreshTokenRaw =
          auth?['refreshToken'] ??
          auth?['refresh_token'] ??
          response['refreshToken'] ??
          response['refresh_token'];

      if (accessTokenRaw != null && refreshTokenRaw != null) {
        final token = AuthTokenEntity(
          accessToken: accessTokenRaw.toString(),
          refreshToken: refreshTokenRaw.toString(),
        );
        return Right(FaceVerifyResultEntity.token(token));
      }

      final dynamic matched = response['matched'];
      final dynamic matchedUserIdRaw =
          matched?['bestCandidate']?['userId'] ??
          response['matchedUserId'] ??
          response['matched_user_id'] ??
          response['matchedUser'] ??
          response['matched_user'];
      if (matchedUserIdRaw != null) {
        return Right(
          FaceVerifyResultEntity.matchedUserId(matchedUserIdRaw.toString()),
        );
      }

      // Fallback: if backend doesn't return expected fields.
      return const Left(
        AuthenticationFailure('Khuôn mặt không khớp hoặc chưa được đăng ký'),
      );
    } on AuthenticationException {
      return const Left(
        AuthenticationFailure('Khuôn mặt không khớp hoặc chưa được đăng ký'),
      );
    } on AuthorizationException {
      return const Left(
        AuthorizationFailure('Khuôn mặt không khớp hoặc chưa được đăng ký'),
      );
    } on ValidationException {
      return const Left(
        ValidationFailure('Hệ thống AI đang bận hoặc ảnh không hợp lệ'),
      );
    } on ServerException {
      return const Left(
        ServerFailure('Hệ thống AI đang bận hoặc ảnh không hợp lệ'),
      );
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (_) {
      return const Left(
        UnknownFailure('Khuôn mặt không khớp hoặc chưa được đăng ký'),
      );
    }
  }

  @override
  Future<Either<Failure, AuthTokenEntity>> firebaseLogin({
    required String idToken,
  }) async {
    try {
      final response = await _remoteDataSource.firebaseLogin(idToken: idToken);
      final tokenModel = AuthTokenModel.fromJson(response);
      return Right(tokenModel.toEntity());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on AuthenticationException catch (e) {
      return Left(AuthenticationFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, AuthTokenEntity>> verifyOtp({
    String? phoneNumber,
    String? email,
    required String otp,
  }) async {
    try {
      final request = VerifyOtpRequestModel.fromForm(
        phoneNumber: phoneNumber,
        email: email,
        otp: otp,
      );

      final response = await _remoteDataSource.verifyOtp(request);

      final tokenModel = AuthTokenModel.fromJson(response);
      return Right(tokenModel.toEntity());
    } on ServerException catch (e) {
      return Left(_mapVerifyOtpBackendFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on ValidationException catch (e) {
      return Left(_mapVerifyOtpBackendFailure(e.message));
    } on AuthenticationException catch (e) {
      return Left(AuthenticationFailure(e.message));
    } on AuthorizationException catch (e) {
      return Left(AuthorizationFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> sendEmailLoginOtp(String email) async {
    try {
      await _remoteDataSource.sendEmailLoginOtp(email: email);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on ValidationException catch (e) {
      return Left(ValidationFailure(e.message));
    } on AuthenticationException catch (e) {
      return Left(AuthenticationFailure(e.message));
    } on AuthorizationException catch (e) {
      return Left(AuthorizationFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, AuthTokenEntity>> verifyEmailLoginOtp(
    String email,
    String otp,
  ) async {
    try {
      final response = await _remoteDataSource.verifyEmailLoginOtp(
        email: email,
        otp: otp,
      );

      final tokenEntity = AuthTokenEntity(
        accessToken:
            response['accessToken']?.toString() ??
            response['access_token']?.toString() ??
            '',
        refreshToken:
            response['refreshToken']?.toString() ??
            response['refresh_token']?.toString() ??
            '',
      );

      if (tokenEntity.accessToken.isEmpty) {
        return const Left(
          AuthenticationFailure('Không nhận được token xác thực từ server.'),
        );
      }

      return Right(tokenEntity);
    } on ServerException catch (e) {
      return Left(_mapVerifyOtpBackendFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on ValidationException catch (e) {
      return Left(_mapVerifyOtpBackendFailure(e.message));
    } on AuthenticationException catch (e) {
      return Left(AuthenticationFailure(e.message));
    } on AuthorizationException catch (e) {
      return Left(AuthorizationFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> confirmQrLogin(String sessionId) async {
    try {
      final access = await TokenService.getAccessToken();
      if (access == null || access.isEmpty) {
        return const Left(
          AuthenticationFailure(
            'Token không hợp lệ. Vui lòng đăng nhập lại trên ứng dụng.',
          ),
        );
      }

      final responseMap = await _remoteDataSource.confirmQrLogin(
        QrConfirmRequestModel(sessionId: sessionId),
      );
      final model = QrConfirmResponseModel.fromJson(responseMap);
      return Right(model.success);
    } on AuthenticationException catch (e) {
      return Left(_mapQrConfirmBackendMessage(e.message));
    } on ValidationException catch (e) {
      return Left(_mapQrConfirmBackendMessage(e.message));
    } on NotFoundException catch (e) {
      return Left(_mapQrConfirmBackendMessage(e.message));
    } on ServerException catch (e) {
      return Left(_mapQrConfirmBackendMessage(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> faceRegister({
    required String userId,
    required List<Uint8List> imagesBytes,
  }) async {
    try {
      final List<String> imagesBase64 = [];
      for (final bytes in imagesBytes) {
        final compressed = await FlutterImageCompress.compressWithList(
          bytes,
          minWidth: 640,
          minHeight: 480,
          quality: 60,
          format: CompressFormat.jpeg,
        );
        imagesBase64.add(base64Encode(compressed));
      }

      final response = await _remoteDataSource.faceRegister(
        userId: userId,
        imagesBase64: imagesBase64,
      );

      final success = response['success'] as bool? ?? true;
      if (success) {
        return const Right(true);
      } else {
        return Left(
          ServerFailure(
            response['message']?.toString() ?? 'Đăng ký khuôn mặt thất bại',
          ),
        );
      }
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on ValidationException catch (e) {
      return Left(ValidationFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> sendPasswordResetOtp({
    required String email,
  }) async {
    try {
      await _remoteDataSource.sendPasswordResetOtp(email: email);
      return const Right(true);
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      return Left(_mapPasswordResetBackendFailure(e));
    }
  }

  @override
  Future<Either<Failure, bool>> resetPassword({
    required String email,
    required String otp,
    required String newPassword,
    required String confirmPassword,
  }) async {
    try {
      await _remoteDataSource.resetPassword(
        email: email,
        otp: otp,
        newPassword: newPassword,
        confirmPassword: confirmPassword,
      );
      return const Right(true);
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      return Left(_mapPasswordResetBackendFailure(e));
    }
  }
}

Failure _mapPasswordResetBackendFailure(Object error) {
  final message = switch (error) {
    ServerException e => e.message,
    ValidationException e => e.message,
    NotFoundException e => e.message,
    AuthenticationException e => e.message,
    AuthorizationException e => e.message,
    _ => error.toString(),
  };
  final m = message.toLowerCase().trim();
  if (m.contains('user not found') || m.contains('not found')) {
    return const ValidationFailure(
      'Email chưa được đăng ký tài khoản. Vui lòng kiểm tra lại.',
    );
  }
  if (m.contains('otp')) {
    return const ValidationFailure('Mã OTP không hợp lệ hoặc đã hết hạn.');
  }
  if (m.contains('do not match') || m.contains('mismatch')) {
    return const ValidationFailure('Mật khẩu nhập lại không khớp.');
  }
  return ServerFailure(
    message.isNotEmpty
        ? message
        : 'Không thể đặt lại mật khẩu. Vui lòng thử lại.',
  );
}

Failure _mapQrConfirmBackendMessage(String message) {
  final m = message.toLowerCase().trim();
  if (m.contains('qr session expired') ||
      (m.contains('expired') && m.contains('session'))) {
    return const QrExpiredFailure();
  }
  if (m.contains('already used')) {
    return const QrAlreadyUsedFailure();
  }
  if (m.contains('invalid mobile token')) {
    return const AuthenticationFailure(
      'Token không hợp lệ. Vui lòng đăng nhập lại trên ứng dụng.',
    );
  }
  if (m.contains('not found')) {
    return const QrExpiredFailure('Mã QR không hợp lệ hoặc phiên đã hết hạn.');
  }
  return AuthenticationFailure(message);
}

Failure _mapRegisterBackendFailure(String message) {
  final m = message.toLowerCase().trim();

  if (m.contains('duplicate key') ||
      m.contains('unique constraint') ||
      m.contains('already exists') ||
      m.contains('đã tồn tại')) {
    if (m.contains('email')) {
      return const ValidationFailure(
        'Email đã được đăng ký. Vui lòng dùng email khác.',
      );
    }
    if (m.contains('phone') ||
        m.contains('phone_number') ||
        m.contains('phonenumber') ||
        m.contains('số điện thoại')) {
      return const ValidationFailure(
        'Số điện thoại đã được đăng ký. Vui lòng dùng số khác.',
      );
    }
    return const ValidationFailure('Email hoặc số điện thoại đã được đăng ký.');
  }

  if (m.contains('thất bại trong quá trình đăng ký') ||
      m.contains('register failed')) {
    return ValidationFailure(
      message.isNotEmpty ? message : 'Đăng ký thất bại. Vui lòng thử lại.',
    );
  }

  return ServerFailure(
    message.isNotEmpty ? message : 'Lỗi server khi đăng ký. Vui lòng thử lại.',
  );
}

Failure _mapVerifyOtpBackendFailure(String message) {
  final m = message.toLowerCase().trim();

  if (m.contains('cannot read properties of null') &&
      m.contains('accesstoken')) {
    return const ServerFailure(
      'Mã OTP đúng nhưng hệ thống xác thực đang lỗi nội bộ (chưa trả được token). Vui lòng thử lại sau ít phút.',
    );
  }

  if (m.contains('otp') &&
      (m.contains('invalid') ||
          m.contains('expired') ||
          m.contains('hết hạn') ||
          m.contains('không hợp lệ'))) {
    return const ValidationFailure('Mã OTP không hợp lệ hoặc đã hết hạn.');
  }

  return ServerFailure(
    message.isNotEmpty ? message : 'Không thể xác thực OTP. Vui lòng thử lại.',
  );
}
