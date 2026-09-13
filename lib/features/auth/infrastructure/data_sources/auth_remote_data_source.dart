import 'package:smart_laundry_locker/features/auth/infrastructure/models/login_request_model.dart';
import 'package:smart_laundry_locker/features/auth/infrastructure/models/qr_confirm_request_model.dart';
import 'package:smart_laundry_locker/features/auth/infrastructure/models/register_request_model.dart';
import 'package:smart_laundry_locker/features/auth/infrastructure/models/verify_otp_request_model.dart';

abstract class AuthRemoteDataSource {
  Future<Map<String, dynamic>> register(RegisterRequestModel request);
  Future<Map<String, dynamic>> login(LoginRequestModel request);
  Future<Map<String, dynamic>> faceVerify({
    required String imageBase64,
    required double threshold,
  });
  Future<Map<String, dynamic>> verifyOtp(VerifyOtpRequestModel request);

  Future<void> sendEmailLoginOtp({required String email});
  Future<Map<String, dynamic>> verifyEmailLoginOtp({
    required String email,
    required String otp,
  });
  Future<Map<String, dynamic>> confirmQrLogin(QrConfirmRequestModel request);

  Future<Map<String, dynamic>> firebaseLogin({required String idToken});

  Future<Map<String, dynamic>> faceRegister({
    required String userId,
    required List<String> imagesBase64,
  });

  Future<void> sendPasswordResetOtp({required String email});

  Future<void> resetPassword({
    required String email,
    required String otp,
    required String newPassword,
    required String confirmPassword,
  });
}
