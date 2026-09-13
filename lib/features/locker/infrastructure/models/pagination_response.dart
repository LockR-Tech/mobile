import 'package:json_annotation/json_annotation.dart';

part 'pagination_response.g.dart';

/// Pagination Response Model
/// Model chung cho pagination từ API
@JsonSerializable()
class PaginationResponse {
  final int total;

  @JsonKey(defaultValue: 1)
  final int page;

  @JsonKey(defaultValue: 10)
  final int limit;

  const PaginationResponse({
    required this.total,
    this.page = 1,
    this.limit = 10,
  });

  factory PaginationResponse.fromJson(Map<String, dynamic> json) =>
      _$PaginationResponseFromJson(json);

  Map<String, dynamic> toJson() => _$PaginationResponseToJson(this);

  /// Tổng số trang
  int get totalPages => limit > 0 ? (total / limit).ceil() : 0;

  /// Có trang tiếp theo không
  bool get hasNextPage => page < totalPages;

  /// Có trang trước không
  bool get hasPreviousPage => page > 1;
}
