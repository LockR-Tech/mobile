import 'package:smart_laundry_locker/core/errors/failures.dart';
import 'package:smart_laundry_locker/features/profile/domain/entities/user_profile.dart';
import 'package:smart_laundry_locker/features/profile/domain/entities/courier_profile.dart';
import 'package:dartz/dartz.dart';

abstract class ProfileRepository {
  Future<Either<Failure, UserProfile>> getProfile();

  Future<Either<Failure, UserProfile>> updateProfile({
    String? fullName,
    String? phoneNumber,
  });

  Future<Either<Failure, CourierProfile>> getCourierProfile(String userId);

  Future<Either<Failure, UserProfile>> uploadAvatar({
    required String userId,
    required String filePath,
  });

  Future<Either<Failure, bool>> verifyCurrentPassword({
    required String email,
    required String currentPassword,
  });

  Future<Either<Failure, bool>> changePassword({
    required String email,
    required String newPassword,
  });

  Future<Either<Failure, bool>> getFaceRegistrationStatus(String userId);
}
