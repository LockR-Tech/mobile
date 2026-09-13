import 'package:smart_laundry_locker/core/network/api_client.dart';
import 'package:smart_laundry_locker/features/profile/infrastructure/data_sources/profile_remote_data_source.dart';
import 'package:dio/dio.dart';

class ProfileRemoteDataSourceImpl implements ProfileRemoteDataSource {
  final ApiClient _apiClient;

  // Current backend (laundry-locker-microservices) user-service endpoints.
  // Self profile lives under /api/user/** (singular); get-by-id is /api/users/{id}.
  static const String _basePath = '/api/user';
  static const String _courierBasePath = '/api/staff-applications';

  ProfileRemoteDataSourceImpl(this._apiClient);

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
    required String userId,
    required Map<String, dynamic> data,
  }) async {
    // Self-update endpoint resolves the user from the JWT (X-User-Id), no id in path.
    final response = await _apiClient.put('$_basePath/profile', data: data);
    return _extractData(response);
  }

  @override
  Future<Map<String, dynamic>> getCourierProfile(String userId) async {
    final response = await _apiClient.get('$_courierBasePath/user/$userId');
    return _extractData(response);
  }

  @override
  Future<Map<String, dynamic>> uploadAvatar({
    required String userId,
    required String filePath,
  }) async {
    final fileName = filePath.split('/').last.split('\\').last;
    final formData = FormData.fromMap({
      'files': await MultipartFile.fromFile(filePath, filename: fileName),
    });

    // NOTE: backend PUT /api/user/avatar expects a JSON {imageUrl} (a hosted URL),
    // not a multipart file upload. Until an image-hosting endpoint exists this
    // will not persist the avatar; path is aligned so it no longer 404s.
    final response = await _apiClient.put('$_basePath/avatar', data: formData);

    return _extractData(response);
  }

  @override
  Future<bool> verifyCurrentPassword({
    required String email,
    required String currentPassword,
  }) async {
    final response = await _apiClient.post(
      '/api/auth/login',
      data: {'identifier': email, 'password': currentPassword},
    );

    final data = _extractData(response);
    final accessToken = data['accessToken'] ?? data['access_token'];
    return accessToken != null && accessToken.toString().isNotEmpty;
  }

  @override
  Future<bool> changePassword({
    required String email,
    required String newPassword,
  }) async {
    // Self password change resolves the user from the JWT (X-User-Id).
    final response = await _apiClient.put(
      '$_basePath/password',
      data: {'newPassword': newPassword},
    );
    final data = response.data;
    if (data is Map<String, dynamic>) {
      final success = data['success'];
      if (success is bool) return success;
    }
    return true;
  }

  @override
  Future<bool> getFaceRegistrationStatus(String userId) async {
    final response = await _apiClient.get<dynamic>(
      '/auth/ai/registered/$userId',
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
