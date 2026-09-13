import 'package:smart_laundry_locker/core/network/api_client.dart';
import 'package:smart_laundry_locker/features/auth/infrastructure/data_sources/auth_remote_data_source.dart';
import 'package:smart_laundry_locker/features/auth/infrastructure/models/login_request_model.dart';
import 'package:smart_laundry_locker/features/auth/infrastructure/models/qr_confirm_request_model.dart';
import 'package:smart_laundry_locker/features/auth/infrastructure/models/register_request_model.dart';
import 'package:smart_laundry_locker/features/auth/infrastructure/models/verify_otp_request_model.dart';
import 'package:dio/dio.dart';

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final ApiClient _apiClient;

  static const String _basePath = '/auth';

  AuthRemoteDataSourceImpl(this._apiClient);

  Map<String, dynamic> _extractData(Response<dynamic> response) {
    final responseData = response.data as Map<String, dynamic>;
    return responseData['data'] as Map<String, dynamic>? ?? responseData;
  }

  @override
  Future<Map<String, dynamic>> register(RegisterRequestModel request) async {
    // Backend AuthController expects: {email, phoneNumber, firstName, lastName,
    // roles:Set<String>, password}. The form collects a single fullName + role,
    // so split the name and wrap the role into a roles array.
    final fullName = (request.fullName ?? '').trim();
    final parts = fullName.isEmpty
        ? <String>[]
        : fullName.split(RegExp(r'\s+'));
    final String lastName = parts.length > 1 ? parts.removeLast() : '';
    final String firstName = parts.isEmpty ? fullName : parts.join(' ');

    final body = <String, dynamic>{
      if (request.email != null && request.email!.isNotEmpty)
        'email': request.email,
      'phoneNumber': request.phoneNumber,
      'firstName': firstName,
      'lastName': lastName,
      'roles': <String>[request.role],
      'password': request.password,
    };

    final response = await _apiClient.post<Map<String, dynamic>>(
      '/api/auth/register',
      data: body,
    );

    return _extractData(response);
  }

  @override
  Future<Map<String, dynamic>> login(LoginRequestModel request) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      '/api/auth/login',
      data: {'identifier': request.email, 'password': request.password},
    );

    return _extractData(response);
  }

  @override
  Future<Map<String, dynamic>> faceVerify({
    required String imageBase64,
    required double threshold,
  }) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      '$_basePath/ai/verify',
      data: {'image_base64': imageBase64, 'threshold': threshold},
    );
    return _extractData(response);
  }

  @override
  Future<Map<String, dynamic>> verifyOtp(VerifyOtpRequestModel request) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      '$_basePath/verify-otp',
      data: request.toJson(),
    );

    return _extractData(response);
  }

  @override
  Future<void> sendEmailLoginOtp({required String email}) async {
    await _apiClient.post<dynamic>(
      '/api/auth/email/send-otp',
      data: {'email': email},
    );
  }

  @override
  Future<Map<String, dynamic>> verifyEmailLoginOtp({
    required String email,
    required String otp,
  }) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      '/api/auth/email/verify-otp',
      data: {'email': email, 'otp': otp},
    );
    final data = _extractData(response);

    if (data['isNewUser'] == true) {
      final regResponse = await _apiClient.post<Map<String, dynamic>>(
        '/api/auth/email/complete-registration',
        data: {
          'tempToken': data['tempToken'],
          'firstName': 'Customer',
        },
      );
      return _extractData(regResponse);
    }
    return data;
  }

  @override
  Future<Map<String, dynamic>> confirmQrLogin(
    QrConfirmRequestModel request,
  ) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      '/api/auth/qr-login/confirm',
      data: request.toJson(),
    );
    return _extractData(response);
  }

  @override
  Future<Map<String, dynamic>> firebaseLogin({required String idToken}) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      '/api/auth/firebase',
      data: {'idToken': idToken},
    );
    return _extractData(response);
  }

  @override
  Future<Map<String, dynamic>> faceRegister({
    required String userId,
    required List<String> imagesBase64,
  }) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      '$_basePath/ai/register',
      data: {'userId': userId, 'images_base64': imagesBase64},
    );
    return _extractData(response);
  }

  @override
  Future<void> sendPasswordResetOtp({required String email}) async {
    await _apiClient.post<Map<String, dynamic>>(
      '/api/auth/forgot-password',
      data: {'email': email},
    );
  }

  @override
  Future<void> resetPassword({
    required String email,
    required String otp,
    required String newPassword,
    required String confirmPassword,
  }) async {
    await _apiClient.post<Map<String, dynamic>>(
      '/api/auth/reset-password',
      data: {
        'email': email,
        'otp': otp,
        'newPassword': newPassword,
        'confirmPassword': confirmPassword,
      },
    );
  }
}
