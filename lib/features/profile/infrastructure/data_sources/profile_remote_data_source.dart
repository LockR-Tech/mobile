abstract class ProfileRemoteDataSource {
  Future<Map<String, dynamic>> getProfile();

  /// `PUT /api/user/profile` — body `{firstName, lastName, phoneNumber?, email?}`.
  Future<Map<String, dynamic>> updateProfile({
    required Map<String, dynamic> data,
  });

  /// Upload avatar (Cloudinary signed upload → PUT /api/user/avatar),
  /// trả về profile đã update
  Future<Map<String, dynamic>> uploadAvatar({
    required String userId,
    required String filePath,
  });

  /// Xoá ảnh đại diện (DELETE /api/user/avatar), trả về profile đã update
  Future<Map<String, dynamic>> deleteAvatar();

  /// `PUT /api/user/password` — body `{currentPassword?, newPassword}`.
  /// Trả nguyên body response (có `data` = cặp token mới khi backend hỗ trợ).
  Future<dynamic> changePassword(Map<String, dynamic> body);

  Future<bool> getFaceRegistrationStatus(String userId);
}
