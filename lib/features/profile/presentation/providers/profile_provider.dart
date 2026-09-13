import 'dart:async';
import 'package:smart_laundry_locker/core/config/feature_flags.dart';
import 'package:smart_laundry_locker/core/network/api_client.dart';
import 'package:smart_laundry_locker/core/services/firebase_messaging_service.dart';
import 'package:smart_laundry_locker/features/profile/application/use_cases/get_profile_use_case.dart';
import 'package:smart_laundry_locker/features/profile/application/use_cases/update_profile_use_case.dart';
import 'package:smart_laundry_locker/features/profile/application/use_cases/get_courier_profile_use_case.dart';
import 'package:smart_laundry_locker/features/profile/domain/entities/user_profile.dart';
import 'package:smart_laundry_locker/features/profile/domain/entities/courier_profile.dart';
import 'package:flutter/foundation.dart';

class ProfileProvider extends ChangeNotifier {
  final GetProfileUseCase _getProfileUseCase;
  final UpdateProfileUseCase _updateProfileUseCase;
  final GetCourierProfileUseCase _getCourierProfileUseCase;
  final ApiClient _apiClient;

  ProfileProvider({
    required GetProfileUseCase getProfileUseCase,
    required UpdateProfileUseCase updateProfileUseCase,
    required GetCourierProfileUseCase getCourierProfileUseCase,
    required ApiClient apiClient,
  }) : _getProfileUseCase = getProfileUseCase,
       _updateProfileUseCase = updateProfileUseCase,
       _getCourierProfileUseCase = getCourierProfileUseCase,
       _apiClient = apiClient;

  bool _isDisposed = false;

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  @override
  void notifyListeners() {
    if (!_isDisposed) {
      super.notifyListeners();
    }
  }

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  bool _isSuccess = false;
  bool get isSuccess => _isSuccess;

  UserProfile? _profile;
  UserProfile? get profile => _profile;

  CourierProfile? _courierProfile;
  CourierProfile? get courierProfile => _courierProfile;

  bool _isCourierLoading = false;
  bool get isCourierLoading => _isCourierLoading;

  String? _courierError;
  String? get courierError => _courierError;

  bool _isFaceRegistered = false;
  bool get isFaceRegistered => _isFaceRegistered;

  Future<void> loadProfile() async {
    _isLoading = true;
    _error = null;
    _isSuccess = false;
    notifyListeners();

    final result = await _getProfileUseCase();
    await result.fold(
      (failure) async {
        _isLoading = false;
        _error = failure.message;
        _isSuccess = false;
        _profile = null;
        notifyListeners();
      },
      (profileEntity) async {
        _isLoading = false;
        _error = null;
        _isSuccess = true;
        _profile = profileEntity;

        // Fetch face registration status
        final faceResult = await _getFaceRegistrationStatus(profileEntity.id);
        _isFaceRegistered = faceResult;

        // Sycn FCM token in background
        unawaited(
          FirebaseMessagingService.instance.updateBackendDeviceToken(
            _apiClient,
          ),
        );

        notifyListeners();
      },
    );
  }

  Future<bool> _getFaceRegistrationStatus(String userId) async {
    // Face-recognition is a legacy feature with no backend in the current
    // microservices stack (`/api/auth/ai/registered/{id}` trả 500). Tạm tắt
    // qua FeatureFlags để không gọi mạng (tránh lỗi đỏ trên Network/log).
    if (!FeatureFlags.faceRecognitionEnabled) return false;
    // Never let its failure abort profile loading.
    try {
      final result = await _apiClient.get<dynamic>(
        '/api/auth/ai/registered/$userId',
      );
      final data = result.data;
      if (data is Map<String, dynamic>) {
        final isReg = data['isRegistered'];
        if (isReg is bool) return isReg;

        final inner = data['data'];
        if (inner is Map<String, dynamic>) {
          final innerReg = inner['isRegistered'];
          if (innerReg is bool) return innerReg;
        }
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<void> updateProfile({String? fullName, String? phoneNumber}) async {
    _isLoading = true;
    _error = null;
    _isSuccess = false;
    notifyListeners();

    final params = UpdateProfileParams.fromForm(
      fullName: fullName,
      phoneNumber: phoneNumber,
    );

    final result = await _updateProfileUseCase(params);

    result.fold(
      (failure) {
        _isLoading = false;
        _error = failure.message;
        _isSuccess = false;
        notifyListeners();
      },
      (updatedProfile) {
        _isLoading = false;
        _error = null;
        _isSuccess = true;
        _profile = updatedProfile;
        notifyListeners();
      },
    );
  }

  Future<void> loadCourierProfile(String userId) async {
    _isCourierLoading = true;
    _courierError = null;
    notifyListeners();

    final result = await _getCourierProfileUseCase(userId);

    result.fold(
      (failure) {
        _isCourierLoading = false;
        _courierError = failure.message;
        notifyListeners();
      },
      (courierEntity) {
        _isCourierLoading = false;
        _courierError = null;
        _courierProfile = courierEntity;
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
    _profile = null;
    _courierProfile = null;
    _isCourierLoading = false;
    _courierError = null;
    notifyListeners();
  }
}
