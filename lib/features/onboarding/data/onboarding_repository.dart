import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:smart_laundry_locker/core/network/api_client.dart';

import '../domain/tour_models.dart';

/// Nội dung tour (file tĩnh của web admin, dùng chung web + mobile) và trạng thái "đã xem" ở user-service (F3-G13).
class OnboardingRepository {
  OnboardingRepository({ApiClient? api, Dio? http})
      : _api = api ?? ApiClient(),
        _http = http ??
            Dio(BaseOptions(
              connectTimeout: const Duration(seconds: 5),
              receiveTimeout: const Duration(seconds: 5),
              responseType: ResponseType.plain,
            ));

  /// Bản mới nhất nằm cùng admin web; sửa nội dung chỉ cần deploy frontend, app không phải phát hành lại.
  static const remoteBase = 'https://admin.locker-drone.tech/onboarding';
  static const assetBase = 'assets/onboarding';
  static const languages = ['vi', 'en'];

  final ApiClient _api;
  final Dio _http;

  Future<Map<String, dynamic>> _json(String path) async {
    try {
      final res = await _http.get<String>('$remoteBase/$path');
      final decoded = jsonDecode(res.data ?? '');
      if (decoded is Map<String, dynamic>) return decoded;
    } catch (e) {
      debugPrint('Onboarding: không tải được $path, dùng bản kèm app ($e)');
    }
    return jsonDecode(await rootBundle.loadString('$assetBase/$path')) as Map<String, dynamic>;
  }

  Future<TourContent> loadContent() async => TourContent.fromJson(await _json('tours.json'));

  Future<Map<String, Map<String, dynamic>>> loadTexts() async => {
        for (final lang in languages) lang: await _json('locales/$lang.json'),
      };

  OnboardingState _state(Response<dynamic> res) {
    final body = res.data;
    final data = body is Map ? body['data'] : null;
    return OnboardingState.fromJson(data is Map ? Map<String, dynamic>.from(data) : null);
  }

  Future<OnboardingState> getState() async => _state(await _api.get<dynamic>('/api/user/onboarding'));

  Future<OnboardingState> setAutoShow(bool autoShow) async =>
      _state(await _api.put<dynamic>('/api/user/onboarding/auto-show', data: {'autoShow': autoShow}));

  Future<OnboardingState> markSeen(String group, int version) async =>
      _state(await _api.post<dynamic>('/api/user/onboarding/seen', data: {'group': group, 'version': version}));
}
