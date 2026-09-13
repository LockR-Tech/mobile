import 'package:smart_laundry_locker/features/locker/infrastructure/models/locker_model.dart';
import 'package:smart_laundry_locker/features/locker/infrastructure/models/pagination_response.dart';
import 'package:json_annotation/json_annotation.dart';

part 'lockers_response.g.dart';

/// GET /lockers/available | GET /lockers/cabinet/:id Response
@JsonSerializable(explicitToJson: true)
class LockersResponse {
  final List<LockerModel> lockers;
  final PaginationResponse? pagination;

  const LockersResponse({required this.lockers, this.pagination});

  factory LockersResponse.fromJson(Map<String, dynamic> json) =>
      _$LockersResponseFromJson(json);

  Map<String, dynamic> toJson() => _$LockersResponseToJson(this);
}

/// Model cho mỗi locker size count item từ API
class LockerSizeCount {
  final String sizeId;
  final String sizeName;
  final int totalLockers;
  final double width;
  final double height;
  final double depth;

  const LockerSizeCount({
    required this.sizeId,
    required this.sizeName,
    required this.totalLockers,
    required this.width,
    required this.height,
    required this.depth,
  });

  /// Getter for dimensions string (W x H x D cm)
  String get dimensions =>
      '${width.toInt()} x ${height.toInt()} x ${depth.toInt()} cm';

  factory LockerSizeCount.fromJson(Map<String, dynamic> json) {
    return LockerSizeCount(
      sizeId: json['sizeId'] as String? ?? '',
      sizeName: json['sizeName'] as String? ?? '',
      totalLockers: json['totalLockers'] as int? ?? 0,
      width: (json['width'] as num?)?.toDouble() ?? 0,
      height: (json['height'] as num?)?.toDouble() ?? 0,
      depth: (json['depth'] as num?)?.toDouble() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'sizeId': sizeId,
    'sizeName': sizeName,
    'totalLockers': totalLockers,
    'width': width,
    'height': height,
    'depth': depth,
  };
}

/// GET /lockers/count/:locationId Response
/// API trả về: { items: [{sizeId, sizeName, totalLockers}, ...] }
class LockerCountResponse {
  final List<LockerSizeCount> items;

  const LockerCountResponse({required this.items});

  /// Convenience getter for counts map (sizeName -> totalLockers)
  Map<String, int> get counts {
    final result = <String, int>{};
    for (final item in items) {
      if (item.sizeName.isNotEmpty) {
        result[item.sizeName] = item.totalLockers;
      }
    }
    return result;
  }

  /// Parse từ API response format
  /// { items: [{sizeId, sizeName, totalLockers}, ...] }
  factory LockerCountResponse.fromJson(Map<String, dynamic> json) {
    final itemsList = json['items'] as List<dynamic>? ?? [];
    final items = itemsList
        .map((item) => LockerSizeCount.fromJson(item as Map<String, dynamic>))
        .toList();
    return LockerCountResponse(items: items);
  }

  Map<String, dynamic> toJson() => {
    'items': items.map((item) => item.toJson()).toList(),
  };
}
