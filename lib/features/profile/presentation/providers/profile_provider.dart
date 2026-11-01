import 'dart:async';
import 'package:smart_laundry_locker/core/config/feature_flags.dart';
import 'package:smart_laundry_locker/core/network/api_client.dart';
import 'package:smart_laundry_locker/core/services/firebase_messaging_service.dart';
import 'package:smart_laundry_locker/features/profile/application/use_cases/get_profile_use_case.dart';
import 'package:smart_laundry_locker/features/profile/application/use_cases/update_profile_use_case.dart';
import 'package:smart_laundry_locker/features/profile/domain/entities/user_profile.dart';
import 'package:smart_laundry_locker/core/services/token_service.dart';
import 'package:flutter/foundation.dart';
import 'package:smart_laundry_locker/core/l10n/l10n.dart';

class ProfileProvider extends ChangeNotifier {
  final GetProfileUseCase _getProfileUseCase;
  final UpdateProfileUseCase _updateProfileUseCase;
  final ApiClient _apiClient;

  ProfileProvider({
    required GetProfileUseCase getProfileUseCase,
    required UpdateProfileUseCase updateProfileUseCase,
    required ApiClient apiClient,
  }) : _getProfileUseCase = getProfileUseCase,
       _updateProfileUseCase = updateProfileUseCase,
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

  /// `true` khi [profile] là dữ liệu thật từ `GET /api/user/profile`. Khi tải
  /// lỗi, [profile] có thể chỉ là bản dựng tạm từ token (tên/email) để các màn
  /// KTV vẫn có tên hiển thị — màn Hồ sơ dựa vào cờ này để báo lỗi + "Thử lại"
  /// thay vì coi như đã tải xong (hoặc đá người dùng ra màn đăng nhập).
  bool _hasServerProfile = false;
  bool get hasServerProfile => _hasServerProfile;

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
        if (_profile == null) {
          _hasServerProfile = false;
          final userName = await TokenService.getUserName();
          final userEmail = await TokenService.getUserEmail();
          final userId = await TokenService.getUserId();
          if (userName != null || userEmail != null) {
            _profile = UserProfile(
              id: userId ?? '',
              fullName: userName ?? userEmail?.split('@').first ?? 'Người dùng',
              email: userEmail ?? '',
              phoneNumber: '',
              status: UserStatus.ACTIVE,
              isVerified: true,
              isActive: true,
            );
          }
        }
        notifyListeners();
      },
      (profileEntity) async {
        _isLoading = false;
        _error = null;
        _isSuccess = true;
        _profile = profileEntity;
        _hasServerProfile = true;

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

  Future<void> updateProfile({
    String? fullName,
    String? phoneNumber,
    String? email,
  }) async {
    _isLoading = true;
    _error = null;
    _isSuccess = false;
    notifyListeners();

    final params = UpdateProfileParams.fromForm(
      fullName: fullName,
      phoneNumber: phoneNumber,
      email: email,
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
        _hasServerProfile = true;
        notifyListeners();
      },
    );
  }

  /// Bấm "Đồng ý" Điều khoản dịch vụ: `POST /api/user/terms {version}`. Trả `null` khi lưu được, ngược lại là
  /// câu báo lỗi để hiện trên hộp thoại.
  Future<String?> acceptTerms(String version) async {
    try {
      await _apiClient.post<dynamic>('/api/user/terms', data: {'version': version});
      final current = _profile;
      if (current != null) {
        _profile = current.copyWith(termsAccepted: true);
        notifyListeners();
      }
      return null;
    } catch (_) {
      return L10n.current.profSaveFailedNetwork;
    }
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
    _hasServerProfile = false;
    _isFaceRegistered = false;
    notifyListeners();
  }
}
