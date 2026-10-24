import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:smart_laundry_locker/features/drone_delivery/domain/entities/drone_booking.dart';

/// Đổi qua lại giữa toạ độ và địa chỉ cho điểm lấy hàng.
///
/// Nguồn chính là Photon (komoot, dữ liệu OpenStreetMap) — trả kết quả theo từng chữ gõ
/// nên hợp cho gợi ý địa chỉ, và không nằm trên tên miền openstreetmap.org mà nhiều nhà
/// mạng Việt Nam đang chặn. Nominatim chỉ là dự phòng khi Photon lỗi hoặc rỗng.
class PickupGeocoder {
  PickupGeocoder({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  static const _timeout = Duration(seconds: 8);

  // Trung tâm TP.HCM — kéo kết quả gần vùng phục vụ lên trước (chỉ ưu tiên, không giới hạn).
  static const _biasLat = '10.7769';
  static const _biasLon = '106.7009';

  // Cả Photon và Nominatim đều yêu cầu User-Agent nhận diện ứng dụng — Photon trả 403
  // cho User-Agent mặc định của Dart (`Dart/x (dart:io)`).
  static const _headers = {
    'User-Agent': 'SmartLaundryLocker/1.0 (contact@laundrylocker.vn)',
    'Accept-Language': 'vi',
  };

  /// Địa chỉ của một điểm trên bản đồ; null khi không tra được (mất mạng, dịch vụ bận).
  Future<String?> addressOf(double latitude, double longitude) async {
    final photon = await _photon(
      Uri.https('photon.komoot.io', '/reverse', {
        'lat': '$latitude',
        'lon': '$longitude',
        'limit': '1',
      }),
    );
    if (photon.isNotEmpty) return photon.first.address;
    return _nominatimReverse(latitude, longitude);
  }

  /// Gợi ý địa chỉ cho chữ người dùng đang gõ (chỉ Việt Nam). Rỗng khi không có kết quả
  /// hoặc lỗi.
  Future<List<PickupLocation>> search(String query) async {
    final text = query.trim();
    if (text.length < 3) return const [];
    final photon = await _photon(
      Uri.https('photon.komoot.io', '/api/', {
        'q': text,
        'lat': _biasLat,
        'lon': _biasLon,
        'limit': '10',
      }),
    );
    if (photon.isNotEmpty) return photon.take(6).toList();
    return _nominatimSearch(text);
  }

  Future<List<PickupLocation>> _photon(Uri uri) async {
    try {
      final response = await _client
          .get(uri, headers: _headers)
          .timeout(_timeout);
      if (response.statusCode != 200) return const [];
      final data = json.decode(utf8.decode(response.bodyBytes));
      if (data is! Map || data['features'] is! List) return const [];
      final results = <PickupLocation>[];
      final seen = <String>{};
      for (final feature in data['features'] as List) {
        if (feature is! Map) continue;
        final props = feature['properties'];
        final coords = feature['geometry'] is Map
            ? (feature['geometry'] as Map)['coordinates']
            : null;
        if (props is! Map || coords is! List || coords.length < 2) continue;
        if ('${props['countrycode'] ?? ''}'.toUpperCase() != 'VN') continue;
        final longitude = (coords[0] as num?)?.toDouble();
        final latitude = (coords[1] as num?)?.toDouble();
        final address = photonLabel(props);
        if (latitude == null || longitude == null || address.isEmpty) continue;
        if (!seen.add(address)) continue;
        results.add(
          PickupLocation(
            latitude: latitude,
            longitude: longitude,
            address: address,
          ),
        );
      }
      return results;
    } catch (_) {
      return const [];
    }
  }

  /// Ghép địa chỉ dễ đọc từ các trường Photon: tên địa điểm, số nhà + đường, khu phố,
  /// phường/quận, thành phố.
  static String photonLabel(Map props) {
    String field(String key) => '${props[key] ?? ''}'.trim();
    final street = [
      field('housenumber'),
      field('street'),
    ].where((part) => part.isNotEmpty).join(' ');
    final parts = <String>[];
    for (final part in [
      field('name'),
      street,
      field('locality'),
      field('district'),
      field('city'),
      field('state'),
    ]) {
      if (part.isNotEmpty && !parts.contains(part)) parts.add(part);
    }
    return parts.join(', ');
  }

  Future<String?> _nominatimReverse(double latitude, double longitude) async {
    try {
      final uri = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?format=json'
        '&lat=$latitude&lon=$longitude&zoom=18&addressdetails=1',
      );
      final response = await _client
          .get(uri, headers: _headers)
          .timeout(_timeout);
      if (response.statusCode != 200) return null;
      final data = json.decode(utf8.decode(response.bodyBytes));
      if (data is! Map) return null;
      final name = '${data['display_name'] ?? ''}'.trim();
      return name.isEmpty ? null : name;
    } catch (_) {
      return null;
    }
  }

  Future<List<PickupLocation>> _nominatimSearch(String text) async {
    try {
      final uri = Uri.https('nominatim.openstreetmap.org', '/search', {
        'format': 'json',
        'q': text,
        'countrycodes': 'vn',
        // Nominatim uses left,top,right,bottom for viewbox (bias, not bounded).
        'viewbox': '106.35,11.15,107.05,10.35',
        'addressdetails': '1',
        'dedupe': '1',
        'limit': '6',
      });
      final response = await _client
          .get(uri, headers: _headers)
          .timeout(_timeout);
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
          PickupLocation(
            latitude: latitude,
            longitude: longitude,
            address: name,
          ),
        );
      }
      return results;
    } catch (_) {
      return const [];
    }
  }
}
