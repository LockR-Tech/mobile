import 'dart:typed_data';
import 'package:smart_laundry_locker/features/auth/application/use_cases/register_face_use_case.dart';
import 'package:flutter/foundation.dart';

class FaceRegistrationProvider extends ChangeNotifier {
  final RegisterFaceUseCase _registerFaceUseCase;

  FaceRegistrationProvider({required RegisterFaceUseCase registerFaceUseCase})
    : _registerFaceUseCase = registerFaceUseCase;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  bool _isSuccess = false;
  bool get isSuccess => _isSuccess;

  final List<Uint8List> _samples = [];
  List<Uint8List> get samples => List.unmodifiable(_samples);

  int get sampleCount => _samples.length;
  static const int requiredSamples = 10;

  void addSample(Uint8List bytes) {
    if (_samples.length < requiredSamples) {
      _samples.add(bytes);
      notifyListeners();
    }
  }

  void clearSamples() {
    _samples.clear();
    notifyListeners();
  }

  Future<void> registerFace({required String userId}) async {
    if (_samples.isEmpty) {
      _error = 'Vui lòng lấy mẫu khuôn mặt trước';
      notifyListeners();
      return;
    }

    _isLoading = true;
    _error = null;
    _isSuccess = false;
    notifyListeners();

    final result = await _registerFaceUseCase(
      RegisterFaceParams(userId: userId, imagesBytes: _samples),
    );

    result.fold(
      (failure) {
        _isLoading = false;
        _error = failure.message;
        notifyListeners();
      },
      (success) {
        _isLoading = false;
        _isSuccess = success;
        notifyListeners();
      },
    );
  }

  void reset() {
    _isLoading = false;
    _error = null;
    _isSuccess = false;
    _samples.clear();
    notifyListeners();
  }
}
