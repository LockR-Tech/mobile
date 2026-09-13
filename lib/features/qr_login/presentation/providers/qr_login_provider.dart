import 'package:smart_laundry_locker/features/qr_login/infrastructure/data_sources/qr_login_remote_datasource.dart';
import 'package:flutter/material.dart';

class QrLoginProvider extends ChangeNotifier {
  final QrLoginRemoteDataSource _remoteDataSource;

  QrLoginProvider({QrLoginRemoteDataSource? remoteDataSource})
    : _remoteDataSource = remoteDataSource ?? QrLoginRemoteDataSourceImpl();

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  Future<bool> confirmQrLogin(String sessionId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _remoteDataSource.confirmQrLogin(sessionId);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}
