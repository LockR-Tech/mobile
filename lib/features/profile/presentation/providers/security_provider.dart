import 'package:smart_laundry_locker/features/profile/application/use_cases/change_password_use_case.dart';
import 'package:smart_laundry_locker/features/profile/application/use_cases/verify_current_password_use_case.dart';
import 'package:flutter/foundation.dart';

class SecurityProvider extends ChangeNotifier {
  final VerifyCurrentPasswordUseCase _verifyCurrentPasswordUseCase;
  final ChangePasswordUseCase _changePasswordUseCase;

  SecurityProvider({
    required VerifyCurrentPasswordUseCase verifyCurrentPasswordUseCase,
    required ChangePasswordUseCase changePasswordUseCase,
  }) : _verifyCurrentPasswordUseCase = verifyCurrentPasswordUseCase,
       _changePasswordUseCase = changePasswordUseCase;

  bool _isVerifying = false;
  bool get isVerifying => _isVerifying;

  bool _isChangingPassword = false;
  bool get isChangingPassword => _isChangingPassword;

  bool _isCurrentPasswordValid = false;
  bool get isCurrentPasswordValid => _isCurrentPasswordValid;

  String? _error;
  String? get error => _error;

  Future<void> verifyCurrentPassword({
    required String email,
    required String currentPassword,
  }) async {
    _isVerifying = true;
    _error = null;
    notifyListeners();

    final result = await _verifyCurrentPasswordUseCase(
      VerifyCurrentPasswordParams(
        email: email,
        currentPassword: currentPassword,
      ),
    );

    result.fold(
      (failure) {
        _isCurrentPasswordValid = false;
        _error = failure.message;
      },
      (isValid) {
        _isCurrentPasswordValid = isValid;
        _error = isValid ? null : 'Mật khẩu hiện tại không đúng.';
      },
    );

    _isVerifying = false;
    notifyListeners();
  }

  Future<bool> changePassword({
    required String email,
    required String newPassword,
  }) async {
    _isChangingPassword = true;
    _error = null;
    notifyListeners();

    final result = await _changePasswordUseCase(
      ChangePasswordParams(email: email, newPassword: newPassword),
    );

    bool success = false;
    result.fold(
      (failure) {
        _error = failure.message;
      },
      (ok) {
        success = ok;
        if (!ok) _error = 'Đổi mật khẩu thất bại.';
      },
    );

    _isChangingPassword = false;
    notifyListeners();
    return success;
  }

  void resetValidation() {
    _isCurrentPasswordValid = false;
    _error = null;
    notifyListeners();
  }
}
