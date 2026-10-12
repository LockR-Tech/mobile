import 'package:smart_laundry_locker/core/errors/failures.dart';
import 'package:smart_laundry_locker/features/profile/domain/entities/user_profile.dart';
import 'package:smart_laundry_locker/features/profile/domain/password_change.dart';
import 'package:dartz/dartz.dart';

abstract class ProfileRepository {
  Future<Either<Failure, UserProfile>> getProfile();

  /// Lưu họ tên (tách `firstName`/`lastName`) và định danh. Field `null` = giữ
  /// nguyên. Email/SĐT trùng tài khoản khác ⇒ Left với thông báo của backend.
  Future<Either<Failure, UserProfile>> updateProfile({
    String? fullName,
    String? phoneNumber,
    String? email,
  });

  Future<Either<Failure, UserProfile>> uploadAvatar({
    required String userId,
    required String filePath,
  });

  Future<Either<Failure, UserProfile>> deleteAvatar();

  /// Đổi ([PasswordFormMode.change]) hoặc đặt lần đầu ([PasswordFormMode.set])
  /// mật khẩu trong một lời gọi.
  Future<Either<Failure, PasswordChangeResult>> changePassword({
    required PasswordFormMode mode,
    String? currentPassword,
    required String newPassword,
  });

  Future<Either<Failure, bool>> getFaceRegistrationStatus(String userId);
}
