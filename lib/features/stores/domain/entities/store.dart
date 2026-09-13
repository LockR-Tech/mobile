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
          : 'Cửa hàng',
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

  bool get hasLocation => latitude != null && longitude != null;

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
      userName:
          (json['userName'] ?? json['user_name'] ?? json['customerName'])
              as String?,
      createdAt: _asDate(json['createdAt'] ?? json['created_at']),
    );
  }

  final double rating;
  final String? comment;
  final String? userName;
  final DateTime? createdAt;

  static DateTime? _asDate(Object? value) {
    if (value == null) return null;
    return DateTime.tryParse('$value');
  }
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
