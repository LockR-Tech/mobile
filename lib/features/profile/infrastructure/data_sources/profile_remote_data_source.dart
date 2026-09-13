abstract class ProfileRemoteDataSource {
  Future<Map<String, dynamic>> getProfile();

  Future<Map<String, dynamic>> updateProfile({
    required String userId,
    required Map<String, dynamic> data,
  });

  Future<Map<String, dynamic>> getCourierProfile(String userId);

  /// Upload avatar lên backend, trả về profile đã update
  Future<Map<String, dynamic>> uploadAvatar({
    required String userId,
    required String filePath,
  });

  Future<bool> verifyCurrentPassword({
    required String email,
    required String currentPassword,
  });

  Future<bool> changePassword({
    required String email,
    required String newPassword,
  });

  Future<bool> getFaceRegistrationStatus(String userId);
}
