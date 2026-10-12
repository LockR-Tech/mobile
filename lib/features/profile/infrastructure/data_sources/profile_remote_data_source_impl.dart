import 'package:image_picker/image_picker.dart';
import 'package:smart_laundry_locker/core/media/media_upload.dart';
import 'package:smart_laundry_locker/core/media/media_upload_service.dart';
import 'package:smart_laundry_locker/core/network/api_client.dart';
import 'package:smart_laundry_locker/features/profile/infrastructure/data_sources/profile_remote_data_source.dart';
import 'package:dio/dio.dart';

class ProfileRemoteDataSourceImpl implements ProfileRemoteDataSource {
  final ApiClient _apiClient;
  final MediaUploadService? _mediaUploadService;

  // Current backend (laundry-locker-microservices) user-service endpoints.
  // Self profile lives under /api/user/** (singular); get-by-id is /api/users/{id}.
  static const String _basePath = '/api/user';

  ProfileRemoteDataSourceImpl(
    this._apiClient, {
    MediaUploadService? mediaUploadService,
  }) : _mediaUploadService = mediaUploadService;

  Map<String, dynamic> _extractData(Response<dynamic> response) {
    final responseData = response.data as Map<String, dynamic>;
    final data = responseData['data'] as Map<String, dynamic>? ?? responseData;

    final nestedUser = data['user'];
    if (nestedUser is Map<String, dynamic>) {
      return _normalize(nestedUser);
    }

    return _normalize(data);
  }

  /// Backend returns numeric `id` (e.g. 2). The mobile models parse `id` as a
  /// String, so normalize it here to avoid a JSON cast crash.
  Map<String, dynamic> _normalize(Map<String, dynamic> raw) {
    final out = Map<String, dynamic>.from(raw);
    if (out['id'] != null) out['id'] = out['id'].toString();
    final avatar =
        out['avatarUrl'] ?? out['imageUrl'] ?? out['image_url'] ?? out['avatar'];
    if (avatar != null && avatar.toString().isNotEmpty) {
      out['avatarUrl'] = avatar.toString();
    }
    return out;
  }

  @override
  Future<Map<String, dynamic>> getProfile() async {
    final response = await _apiClient.get('$_basePath/profile');
    final profile = _extractData(response);
    final phone = profile['phoneNumber']?.toString();
    final userId = profile['id']?.toString();
    final needEnrichPhone = phone == null || phone.trim().isEmpty;
    if (needEnrichPhone && userId != null && userId.isNotEmpty) {
      try {
        final detailResponse = await _apiClient.get('/api/users/$userId');
        final detail = _extractData(detailResponse);
        return <String, dynamic>{
          ...detail,
          ...profile,
          'phoneNumber': detail['phoneNumber'] ?? profile['phoneNumber'],
        };
      } catch (_) {}
    }

    return profile;
  }

  @override
  Future<Map<String, dynamic>> updateProfile({
    required Map<String, dynamic> data,
  }) async {
    // Self-update endpoint resolves the user from the JWT (X-User-Id), no id in path.
    final response = await _apiClient.put('$_basePath/profile', data: data);
    return _extractData(response);
  }

  @override
  Future<Map<String, dynamic>> uploadAvatar({
    required String userId,
    required String filePath,
  }) async {
    // Cloudinary signed upload (docs/01-overview/media-storage.md):
    // chữ ký purpose AVATAR → upload thẳng Cloudinary (không JWT) →
    // PUT /api/user/avatar với body MediaUpload (JSON).
    final upload = await (_mediaUploadService ?? MediaUploadService())
        .uploadImage(XFile(filePath), MediaPurpose.avatar);
    final response = await _apiClient.put(
      '$_basePath/avatar',
      data: upload.toJson(),
    );
    return _extractData(response);
  }

  @override
  Future<Map<String, dynamic>> deleteAvatar() async {
    final response = await _apiClient.delete('$_basePath/avatar');
    return _extractData(response);
  }

  @override
  Future<dynamic> changePassword(Map<String, dynamic> body) async {
    // Self password change resolves the user from the JWT (X-User-Id).
    // `data` của response là cặp token mới (backend thu hồi refresh token cũ).
    final response = await _apiClient.put<dynamic>(
      '$_basePath/password',
      data: body,
    );
    return response.data;
  }

  @override
  Future<bool> getFaceRegistrationStatus(String userId) async {
    final response = await _apiClient.get<dynamic>(
      '/api/auth/ai/registered/$userId',
    );
    final data = response.data;
    if (data is Map<String, dynamic>) {
      final isRegistered = data['isRegistered'];
      if (isRegistered is bool) return isRegistered;

      // Handle nested data if necessary
      final innerData = data['data'];
      if (innerData is Map<String, dynamic>) {
        final innerRegistered = innerData['isRegistered'];
        if (innerRegistered is bool) return innerRegistered;
      }
    }
    return false;
  }
}
