import 'package:smart_laundry_locker/core/network/api_client.dart';
import 'package:smart_laundry_locker/core/services/token_service.dart';
import 'package:smart_laundry_locker/features/auth/application/use_cases/verify_otp_use_case.dart';
import 'package:smart_laundry_locker/features/auth/domain/entities/auth_token_entity.dart';
import 'package:flutter/foundation.dart';

class VerifyOtpProvider extends ChangeNotifier {
  final VerifyOtpUseCase _verifyOtpUseCase;
  final ApiClient _apiClient;

  VerifyOtpProvider({
    required VerifyOtpUseCase verifyOtpUseCase,
    required ApiClient apiClient,
  }) : _verifyOtpUseCase = verifyOtpUseCase,
       _apiClient = apiClient;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  bool _isSuccess = false;
  bool get isSuccess => _isSuccess;

  AuthTokenEntity? _authToken;
  AuthTokenEntity? get authToken => _authToken;

  Future<void> verifyOtp({
    String? phoneNumber,
    String? email,
    required String otp,
  }) async {
    _isLoading = true;
    _error = null;
    _isSuccess = false;
    notifyListeners();

    final params = VerifyOtpParams.fromForm(
      phoneNumber: phoneNumber,
      email: email,
      otp: otp,
    );

    final result = await _verifyOtpUseCase(params);

    result.fold(
      (failure) {
        _isLoading = false;
        _error = failure.message;
        _isSuccess = false;
        notifyListeners();
      },
      (tokenEntity) async {
        _isLoading = false;
        _error = null;
        _isSuccess = true;
        _authToken = tokenEntity;

        await TokenService.saveTokens(
          tokenEntity.accessToken,
          tokenEntity.refreshToken,
        );

        _apiClient.setAuthToken(tokenEntity.accessToken);

        notifyListeners();
      },
    );
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void reset() {
    _isLoading = false;
    _error = null;
    _isSuccess = false;
    _authToken = null;
    notifyListeners();
  }
}
