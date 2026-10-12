import 'package:smart_laundry_locker/core/services/token_service.dart';
import 'package:smart_laundry_locker/features/profile/application/use_cases/change_password_use_case.dart';
import 'package:smart_laundry_locker/features/profile/application/use_cases/get_profile_use_case.dart';
import 'package:smart_laundry_locker/features/profile/domain/password_change.dart';
import 'package:flutter/foundation.dart';

/// Lưu cặp token mới backend trả sau khi đổi mật khẩu. Tách ra để test.
typedef SaveTokens = Future<void> Function(String accessToken, String refreshToken);

/// Màn "Bảo mật": đọc `hasPassword` từ hồ sơ để chọn form đổi / đặt mật khẩu,
/// rồi gửi đúng MỘT lời gọi `PUT /api/user/password`.
class SecurityProvider extends ChangeNotifier {
  final GetProfileUseCase _getProfileUseCase;
  final ChangePasswordUseCase _changePasswordUseCase;
  final SaveTokens _saveTokens;

  SecurityProvider({
    required GetProfileUseCase getProfileUseCase,
    required ChangePasswordUseCase changePasswordUseCase,
    SaveTokens? saveTokens,
  }) : _getProfileUseCase = getProfileUseCase,
       _changePasswordUseCase = changePasswordUseCase,
       _saveTokens = saveTokens ?? TokenService.saveTokens;

  bool _isDisposed = false;

  bool _isLoadingProfile = true;
  bool get isLoadingProfile => _isLoadingProfile;

  /// Lỗi tải hồ sơ (không biết tài khoản đã có mật khẩu hay chưa).
  String? _profileError;
  String? get profileError => _profileError;

  PasswordFormMode _mode = PasswordFormMode.change;
  PasswordFormMode get mode => _mode;

  bool _isChangingPassword = false;
  bool get isChangingPassword => _isChangingPassword;

  String? _error;
  String? get error => _error;

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  @override
  void notifyListeners() {
    if (!_isDisposed) super.notifyListeners();
  }

  Future<void> loadPasswordState() async {
    _isLoadingProfile = true;
    _profileError = null;
    notifyListeners();

    final result = await _getProfileUseCase();
    result.fold(
      (failure) => _profileError = failure.message,
      (profile) =>
          _mode = passwordFormModeFor(hasPassword: profile.hasPassword),
    );
    _isLoadingProfile = false;
    notifyListeners();
  }

  /// Gửi form. Trả `true` khi backend xác nhận; token mới (nếu có) đã được lưu.
  Future<bool> submit({
    String? currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    final invalid = validatePasswordForm(
      mode: _mode,
      currentPassword: currentPassword,
      newPassword: newPassword,
      confirmPassword: confirmPassword,
    );
    if (invalid != null) {
      _error = invalid;
      notifyListeners();
      return false;
    }

    _isChangingPassword = true;
    _error = null;
    notifyListeners();

    final result = await _changePasswordUseCase(
      ChangePasswordParams(
        mode: _mode,
        currentPassword: currentPassword,
        newPassword: newPassword,
      ),
    );

    var success = false;
    await result.fold(
      (failure) async => _error = failure.message,
      (changed) async {
        success = true;
        if (changed.hasTokens) {
          await _saveTokens(changed.accessToken!, changed.refreshToken!);
        }
        // Vừa đặt mật khẩu lần đầu ⇒ lần sau là đổi mật khẩu.
        _mode = PasswordFormMode.change;
      },
    );

    _isChangingPassword = false;
    notifyListeners();
    return success;
  }

  void clearError() {
    if (_error == null) return;
    _error = null;
    notifyListeners();
  }
}
