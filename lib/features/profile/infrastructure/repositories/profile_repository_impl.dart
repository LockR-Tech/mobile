import 'package:smart_laundry_locker/core/errors/failures.dart';
import 'package:smart_laundry_locker/core/network/api_client.dart';
import 'package:smart_laundry_locker/features/profile/domain/entities/user_profile.dart';
import 'package:smart_laundry_locker/features/profile/domain/entities/courier_profile.dart';
import 'package:smart_laundry_locker/features/profile/domain/repositories/profile_repository.dart';
import 'package:smart_laundry_locker/features/profile/infrastructure/data_sources/profile_remote_data_source.dart';
import 'package:smart_laundry_locker/features/profile/infrastructure/models/user_profile_model.dart';
import 'package:smart_laundry_locker/features/profile/infrastructure/models/courier_profile_model.dart';
import 'package:dartz/dartz.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  final ProfileRemoteDataSource _remoteDataSource;

  ProfileRepositoryImpl({required ProfileRemoteDataSource remoteDataSource})
    : _remoteDataSource = remoteDataSource;

  @override
  Future<Either<Failure, UserProfile>> getProfile() async {
    try {
      final response = await _remoteDataSource.getProfile();
      final profileModel = UserProfileModel.fromJson(response);
      return Right(profileModel.toEntity());
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
    } on NotFoundException catch (e) {
      return Left(NotFoundFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, UserProfile>> updateProfile({
    String? fullName,
    String? phoneNumber,
  }) async {
    try {
      final currentProfileResult = await getProfile();

      return await currentProfileResult.fold((failure) => Left(failure), (
        currentProfile,
      ) async {
        final updateData = <String, dynamic>{};
        if (fullName != null) {
          updateData['fullName'] = fullName;
        }
        if (phoneNumber != null) {
          updateData['phoneNumber'] = phoneNumber;
        }

        final response = await _remoteDataSource.updateProfile(
          userId: currentProfile.id,
          data: updateData,
        );

        final profileModel = UserProfileModel.fromJson(response);
        return Right(profileModel.toEntity());
      });
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
    } on NotFoundException catch (e) {
      return Left(NotFoundFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, CourierProfile>> getCourierProfile(
    String userId,
  ) async {
    try {
      final response = await _remoteDataSource.getCourierProfile(userId);
      final courierModel = CourierProfileModel.fromJson(response);
      return Right(courierModel.toEntity());
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
    } on NotFoundException catch (e) {
      return Left(NotFoundFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, UserProfile>> uploadAvatar({
    required String userId,
    required String filePath,
  }) async {
    try {
      final response = await _remoteDataSource.uploadAvatar(
        userId: userId,
        filePath: filePath,
      );
      final profileModel = UserProfileModel.fromJson(response);
      return Right(profileModel.toEntity());
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
    } on NotFoundException catch (e) {
      return Left(NotFoundFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> verifyCurrentPassword({
    required String email,
    required String currentPassword,
  }) async {
    try {
      final ok = await _remoteDataSource.verifyCurrentPassword(
        email: email,
        currentPassword: currentPassword,
      );
      return Right(ok);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on ValidationException catch (e) {
      return Left(ValidationFailure(e.message));
    } on AuthenticationException {
      return const Left(
        ValidationFailure('Mật khẩu hiện tại không đúng. Vui lòng nhập lại.'),
      );
    } on AuthorizationException catch (e) {
      return Left(AuthorizationFailure(e.message));
    } on NotFoundException catch (e) {
      return Left(NotFoundFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> changePassword({
    required String email,
    required String newPassword,
  }) async {
    try {
      final ok = await _remoteDataSource.changePassword(
        email: email,
        newPassword: newPassword,
      );
      return Right(ok);
    } on ServerException catch (e) {
      return Left(_mapChangePasswordFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on ValidationException catch (e) {
      return Left(_mapChangePasswordFailure(e.message));
    } on AuthenticationException catch (e) {
      return Left(AuthenticationFailure(e.message));
    } on AuthorizationException catch (e) {
      return Left(AuthorizationFailure(e.message));
    } on NotFoundException catch (e) {
      return Left(NotFoundFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> getFaceRegistrationStatus(String userId) async {
    try {
      final isRegistered = await _remoteDataSource.getFaceRegistrationStatus(
        userId,
      );
      return Right(isRegistered);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }
}

Failure _mapChangePasswordFailure(String message) {
  final m = message.toLowerCase().trim();
  if ((m.contains('phiên đặt lại mật khẩu') && m.contains('hết hạn')) ||
      (m.contains('reset password') && m.contains('expired')) ||
      (m.contains('otp') && m.contains('hết hạn'))) {
    return const ValidationFailure(
      'Phiên đổi mật khẩu đã hết hạn. Vui lòng dùng tính năng "Quên mật khẩu" để nhận OTP mới rồi thử lại.',
    );
  }
  return ValidationFailure(
    message.isNotEmpty ? message : 'Đổi mật khẩu thất bại. Vui lòng thử lại.',
  );
}
