import 'package:smart_laundry_locker/features/auth/application/use_cases/register_use_case.dart';
import 'package:smart_laundry_locker/features/auth/domain/entities/register_entity.dart';
import 'package:flutter/foundation.dart';

class RegisterProvider extends ChangeNotifier {
  final RegisterUseCase _registerUseCase;

  RegisterProvider({required RegisterUseCase registerUseCase})
    : _registerUseCase = registerUseCase;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  bool _isSuccess = false;
  bool get isSuccess => _isSuccess;

  RegisterEntity? _registerResult;
  RegisterEntity? get registerResult => _registerResult;

  Future<void> register({
    required String phoneNumber,
    String? fullName,
    String? email,
    String? password,
  }) async {
    _isLoading = true;
    _error = null;
    _isSuccess = false;
    notifyListeners();

    final params = RegisterParams.fromForm(
      phoneNumber: phoneNumber,
      fullName: fullName,
      email: email,
      password: password,
    );

    final result = await _registerUseCase(params);

    result.fold(
      (failure) {
        _isLoading = false;
        _error = failure.message;
        _isSuccess = false;
        notifyListeners();
      },
      (entity) {
        _isLoading = false;
        // check nếu entity.success = false (Saga rollback), hiển thị error message
        if (entity.success) {
          _error = null;
          _isSuccess = true;
        } else {
          _error = entity.message ?? 'Đăng ký thất bại. Vui lòng thử lại.';
          _isSuccess = false;
        }
        _registerResult = entity;
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
    _registerResult = null;
    notifyListeners();
  }
}
