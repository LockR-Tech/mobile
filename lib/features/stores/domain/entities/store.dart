import 'package:smart_laundry_locker/core/utils/app_date_time.dart';
import 'package:smart_laundry_locker/core/l10n/l10n.dart';

/// A store/partner branch where lockers are hosted.
///
/// Mirrors the backend `StoreResponse` returned by `GET /api/stores` and
/// `GET /api/stores/{id}` (responses are wrapped in `{ "data": ... }`).
class Store {
  const Store({
    required this.id,
    required this.name,
    this.address,
    this.contactPhone,
    this.image,
    this.description,
    this.latitude,
    this.longitude,
    this.distanceKm,
    this.status,
    this.active = true,
  });

  factory Store.fromJson(Map<String, dynamic> json) {
    return Store(
      id: _asInt(json['id']),
      name: (json['name'] as String?)?.trim().isNotEmpty == true
          ? json['name'] as String
          : L10n.current.storeDefaultName,
      address: json['address'] as String?,
      contactPhone: (json['contactPhone'] ?? json['contact_phone']) as String?,
      image: (json['image'] ?? json['imageUrl']) as String?,
      description: json['description'] as String?,
      latitude: _asDouble(json['latitude']),
      longitude: _asDouble(json['longitude']),
      distanceKm: _asDouble(json['distanceKm'] ?? json['distance_km']),
      status: json['status'] as String?,
      active: _asBool(json['active'] ?? json['isActive'], fallback: true),
    );
  }

  final int id;
  final String name;
  final String? address;
  final String? contactPhone;
  final String? image;
  final String? description;
  final double? latitude;
  final double? longitude;
  final double? distanceKm;
  final String? status;
  final bool active;

  /// True when the store is open for business.
  bool get isActive =>
      active && (status == null || status!.toUpperCase() == 'ACTIVE');

  /// Có toạ độ dùng được để vẽ bản đồ / chỉ đường. Tủ thiếu toạ độ được map
  /// thành NaN ở danh sách tủ, nên phải loại cả NaN/vô cực và ngoài phạm vi.
  bool get hasLocation {
    final lat = latitude;
    final lng = longitude;
    if (lat == null || lng == null) return false;
    if (!lat.isFinite || !lng.isFinite) return false;
    return lat >= -90 && lat <= 90 && lng >= -180 && lng <= 180;
  }

  static int _asInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse('$value') ?? 0;
  }

  static double? _asDouble(Object? value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse('$value');
  }

  static bool _asBool(Object? value, {required bool fallback}) {
    if (value is bool) return value;
    if (value is String) return value.toLowerCase() == 'true';
    return fallback;
  }
}

/// A single customer rating for a store (sourced from order ratings).
class StoreRating {
  const StoreRating({
    required this.rating,
    this.comment,
    this.userName,
    this.createdAt,
  });

  factory StoreRating.fromJson(Map<String, dynamic> json) {
    return StoreRating(
      rating:
          Store._asDouble(json['rating'] ?? json['score'] ?? json['stars']) ??
          0,
      comment:
          (json['comment'] ?? json['content'] ?? json['review']) as String?,
      userName: _asName(
        json['userName'] ?? json['user_name'] ?? json['customerName'],
      ),
      createdAt: parseServerDateTime(json['createdAt'] ?? json['created_at']),
    );
  }

  /// Tên người đánh giá do backend trả (`userName`); rỗng ⇒ null để UI hiện
  /// "Khách hàng".
  static String? _asName(Object? value) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? null : text;
  }

  final double rating;
  final String? comment;
  final String? userName;
  final DateTime? createdAt;
}

/// Aggregated rating summary for a store.
class StoreRatingsSummary {
  const StoreRatingsSummary({required this.average, required this.count});

  factory StoreRatingsSummary.fromRatings(List<StoreRating> ratings) {
    if (ratings.isEmpty) return const StoreRatingsSummary(average: 0, count: 0);
    final total = ratings.fold<double>(0, (sum, r) => sum + r.rating);
    return StoreRatingsSummary(
      average: total / ratings.length,
      count: ratings.length,
    );
  }

  final double average;
  final int count;

  bool get hasRatings => count > 0;
}
