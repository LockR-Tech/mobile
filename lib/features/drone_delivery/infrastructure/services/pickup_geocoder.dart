import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:smart_laundry_locker/features/drone_delivery/domain/entities/drone_booking.dart';

/// Đổi qua lại giữa toạ độ và địa chỉ cho điểm lấy hàng, qua OpenStreetMap Nominatim —
/// cùng dịch vụ màn bản đồ tủ (`locker_map_page.dart`) đang dùng để hiện địa chỉ.
class PickupGeocoder {
  PickupGeocoder({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  // Nominatim yêu cầu User-Agent nhận diện ứng dụng.
  static const _headers = {
    'User-Agent': 'SmartLaundryLocker/1.0 (contact@laundrylocker.vn)',
    'Accept-Language': 'vi',
  };

  /// Địa chỉ của một điểm trên bản đồ; null khi không tra được (mất mạng, dịch vụ bận).
  Future<String?> addressOf(double latitude, double longitude) async {
    try {
      final uri = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?format=json'
        '&lat=$latitude&lon=$longitude&zoom=18&addressdetails=1',
      );
      final response = await _client
          .get(uri, headers: _headers)
          .timeout(const Duration(seconds: 8));
      if (response.statusCode != 200) return null;
      final data = json.decode(utf8.decode(response.bodyBytes));
      if (data is! Map) return null;
      final name = '${data['display_name'] ?? ''}'.trim();
      return name.isEmpty ? null : name;
    } catch (_) {
      return null;
    }
  }

  /// Tìm địa chỉ người dùng gõ (ưu tiên Việt Nam). Rỗng khi không có kết quả hoặc lỗi.
  Future<List<PickupLocation>> search(String query) async {
    final text = query.trim();
    if (text.length < 3) return const [];
    try {
      final uri = Uri.https('nominatim.openstreetmap.org', '/search', {
        'format': 'json',
        'q': text,
        'countrycodes': 'vn',
        'limit': '6',
      });
      final response = await _client
          .get(uri, headers: _headers)
          .timeout(const Duration(seconds: 8));
      if (response.statusCode != 200) return const [];
      final data = json.decode(utf8.decode(response.bodyBytes));
      if (data is! List) return const [];
      final results = <PickupLocation>[];
      for (final item in data) {
        if (item is! Map) continue;
        final latitude = double.tryParse('${item['lat']}');
        final longitude = double.tryParse('${item['lon']}');
        final name = '${item['display_name'] ?? ''}'.trim();
        if (latitude == null || longitude == null || name.isEmpty) continue;
        results.add(
          PickupLocation(latitude: latitude, longitude: longitude, address: name),
        );
      }
      return results;
    } catch (_) {
      return const [];
    }
  }
}
