import 'package:smart_laundry_locker/core/network/api_client.dart';
import 'package:smart_laundry_locker/features/auth/application/use_cases/confirm_qr_login_use_case.dart';
import 'package:smart_laundry_locker/features/auth/application/use_cases/forgot_password_use_case.dart';
import 'package:smart_laundry_locker/features/auth/application/use_cases/login_use_case.dart';
import 'package:smart_laundry_locker/features/auth/application/use_cases/login_with_face_use_case.dart';
import 'package:smart_laundry_locker/features/auth/application/use_cases/register_face_use_case.dart';
import 'package:smart_laundry_locker/features/auth/application/use_cases/register_use_case.dart';
import 'package:smart_laundry_locker/features/auth/application/use_cases/social_login_use_case.dart';
import 'package:smart_laundry_locker/features/auth/application/use_cases/verify_otp_use_case.dart';
import 'package:smart_laundry_locker/core/services/firebase_auth_service.dart';
import 'package:smart_laundry_locker/features/auth/domain/repositories/auth_repository.dart';
import 'package:smart_laundry_locker/features/auth/infrastructure/data_sources/auth_remote_data_source_impl.dart';
import 'package:smart_laundry_locker/features/auth/infrastructure/repositories/auth_repository_impl.dart';
import 'package:smart_laundry_locker/features/auth/presentation/providers/face_registration_provider.dart';
import 'package:smart_laundry_locker/features/auth/presentation/providers/forgot_password_provider.dart';
import 'package:smart_laundry_locker/features/auth/presentation/providers/login_provider.dart';
import 'package:smart_laundry_locker/features/auth/presentation/providers/register_provider.dart';
import 'package:smart_laundry_locker/features/auth/presentation/providers/verify_otp_provider.dart';

import 'package:smart_laundry_locker/features/auth/application/use_cases/send_email_login_otp_use_case.dart';
import 'package:smart_laundry_locker/features/auth/application/use_cases/verify_email_login_otp_use_case.dart';

class AuthInjection {
  static RegisterProvider provideRegisterProvider(ApiClient apiClient) {
    final remoteDataSource = AuthRemoteDataSourceImpl(apiClient);
    final repository = AuthRepositoryImpl(remoteDataSource: remoteDataSource);
    final registerUseCase = RegisterUseCase(repository);

    return RegisterProvider(registerUseCase: registerUseCase);
  }

  static LoginProvider provideLoginProvider(ApiClient apiClient) {
    final remoteDataSource = AuthRemoteDataSourceImpl(apiClient);
    final repository = AuthRepositoryImpl(remoteDataSource: remoteDataSource);
    final loginUseCase = LoginUseCase(repository);
    final loginWithFaceUseCase = LoginWithFaceUseCase(repository);
    final confirmQrLoginUseCase = ConfirmQrLoginUseCase(repository);
    final socialLoginUseCase = SocialLoginUseCase(repository);
    final sendEmailLoginOtpUseCase = SendEmailLoginOtpUseCase(repository);
    final verifyEmailLoginOtpUseCase = VerifyEmailLoginOtpUseCase(repository);
    final firebaseAuthService = FirebaseAuthService();

    return LoginProvider(
      loginUseCase: loginUseCase,
      loginWithFaceUseCase: loginWithFaceUseCase,
      confirmQrLoginUseCase: confirmQrLoginUseCase,
      socialLoginUseCase: socialLoginUseCase,
      sendEmailLoginOtpUseCase: sendEmailLoginOtpUseCase,
      verifyEmailLoginOtpUseCase: verifyEmailLoginOtpUseCase,
      firebaseAuthService: firebaseAuthService,
      apiClient: apiClient,
    );
  }

  static FaceRegistrationProvider provideFaceRegistrationProvider(
    ApiClient apiClient,
  ) {
    final repository = provideAuthRepository(apiClient);
    final useCase = RegisterFaceUseCase(repository);

    return FaceRegistrationProvider(registerFaceUseCase: useCase);
  }

  static AuthRepository provideAuthRepository(ApiClient apiClient) {
    final remoteDataSource = AuthRemoteDataSourceImpl(apiClient);
    return AuthRepositoryImpl(remoteDataSource: remoteDataSource);
  }

  static RegisterUseCase provideRegisterUseCase(ApiClient apiClient) {
    final repository = provideAuthRepository(apiClient);
    return RegisterUseCase(repository);
  }

  static LoginUseCase provideLoginUseCase(ApiClient apiClient) {
    final repository = provideAuthRepository(apiClient);
    return LoginUseCase(repository);
  }

  static LoginWithFaceUseCase provideLoginWithFaceUseCase(ApiClient apiClient) {
    final repository = provideAuthRepository(apiClient);
    return LoginWithFaceUseCase(repository);
  }

  static ForgotPasswordProvider provideForgotPasswordProvider(
    ApiClient apiClient,
  ) {
    final repository = provideAuthRepository(apiClient);
    return ForgotPasswordProvider(useCase: ForgotPasswordUseCase(repository));
  }

  static VerifyOtpProvider provideVerifyOtpProvider(ApiClient apiClient) {
    final remoteDataSource = AuthRemoteDataSourceImpl(apiClient);
    final repository = AuthRepositoryImpl(remoteDataSource: remoteDataSource);
    final verifyOtpUseCase = VerifyOtpUseCase(repository);

    return VerifyOtpProvider(
      verifyOtpUseCase: verifyOtpUseCase,
      apiClient: apiClient,
    );
  }
}
