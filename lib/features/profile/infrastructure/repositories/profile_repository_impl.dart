import 'package:smart_laundry_locker/core/errors/failures.dart';
import 'package:smart_laundry_locker/core/network/api_client.dart';
import 'package:smart_laundry_locker/features/profile/domain/entities/user_profile.dart';
import 'package:smart_laundry_locker/features/profile/domain/password_change.dart';
import 'package:smart_laundry_locker/features/profile/domain/profile_errors.dart';
import 'package:smart_laundry_locker/features/profile/domain/repositories/profile_repository.dart';
import 'package:smart_laundry_locker/features/profile/domain/utils/person_name.dart';
import 'package:smart_laundry_locker/features/profile/infrastructure/data_sources/profile_remote_data_source.dart';
import 'package:smart_laundry_locker/features/profile/infrastructure/models/user_profile_model.dart';
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
    String? email,
  }) async {
    final updateData = buildProfileUpdateBody(
      fullName: fullName,
      phoneNumber: phoneNumber,
      email: email,
    );
    try {
      final response = await _remoteDataSource.updateProfile(data: updateData);
      // PUT trả UserSummary (không có firstName/lastName/hasPassword) ⇒ đọc lại
      // hồ sơ đầy đủ; đọc lại lỗi thì dùng tạm dữ liệu PUT trả về.
      final fresh = await getProfile();
      return fresh.fold(
        (_) => Right(UserProfileModel.fromJson(response).toEntity()),
        (profile) => Right(profile),
      );
    } on ServerException catch (e) {
      return Left(ServerFailure(profileUpdateErrorMessage(e.message)));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on ValidationException catch (e) {
      return Left(ValidationFailure(profileUpdateErrorMessage(e.message)));
    } on AuthenticationException catch (e) {
      return Left(AuthenticationFailure(e.message));
    } on AuthorizationException catch (e) {
      return Left(AuthorizationFailure(e.message));
    } on NotFoundException catch (e) {
      return Left(NotFoundFailure(profileUpdateErrorMessage(e.message)));
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
  Future<Either<Failure, UserProfile>> deleteAvatar() async {
    try {
      final response = await _remoteDataSource.deleteAvatar();
      return Right(UserProfileModel.fromJson(response).toEntity());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on AuthenticationException catch (e) {
      return Left(AuthenticationFailure(e.message));
    } on AuthorizationException catch (e) {
      return Left(AuthorizationFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, PasswordChangeResult>> changePassword({
    required PasswordFormMode mode,
    String? currentPassword,
    required String newPassword,
  }) async {
    try {
      final body = await _remoteDataSource.changePassword(
        buildPasswordChangeBody(
          mode: mode,
          currentPassword: currentPassword,
          newPassword: newPassword,
        ),
      );
      if (body is Map && body['success'] == false) {
        return Left(
          ValidationFailure(
            passwordChangeErrorMessage(body['message']?.toString() ?? ''),
          ),
        );
      }
      return Right(PasswordChangeResult.fromResponse(body));
    } on ServerException catch (e) {
      return Left(ServerFailure(passwordChangeErrorMessage(e.message)));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on ValidationException catch (e) {
      return Left(ValidationFailure(passwordChangeErrorMessage(e.message)));
    } on AuthenticationException catch (e) {
      return Left(AuthenticationFailure(e.message));
    } on AuthorizationException catch (e) {
      return Left(AuthorizationFailure(e.message));
    } on NotFoundException {
      return const Left(
        NotFoundFailure(
          'Máy chủ chưa hỗ trợ đổi mật khẩu từ ứng dụng. Vui lòng thử lại sau.',
        ),
      );
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

/// Body `PUT /api/user/profile`: họ tên tách `firstName`/`lastName` như lúc
/// đăng ký (backend bỏ qua `fullName` ở bản cũ nên tên không bao giờ lưu);
/// field `null` không gửi = giữ nguyên.
Map<String, dynamic> buildProfileUpdateBody({
  String? fullName,
  String? phoneNumber,
  String? email,
}) {
  final body = <String, dynamic>{};
  if (fullName != null && fullName.trim().isNotEmpty) {
    final name = splitFullName(fullName);
    body['firstName'] = name.firstName;
    body['lastName'] = name.lastName;
  }
  if (phoneNumber != null && phoneNumber.trim().isNotEmpty) {
    body['phoneNumber'] = phoneNumber.trim();
  }
  if (email != null && email.trim().isNotEmpty) {
    body['email'] = email.trim();
  }
  return body;
}
