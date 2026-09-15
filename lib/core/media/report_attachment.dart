/// `stage` của ảnh phiếu sự cố (docs/01-overview/media-storage.md §3).
abstract final class ReportStage {
  static const report = 'REPORT';
  static const inspection = 'INSPECTION';
  static const progress = 'PROGRESS';
  static const resolution = 'RESOLUTION';

  /// Thứ tự hiển thị theo quy trình thực tế.
  static const ordered = [report, inspection, progress, resolution];

  static String label(String stage) => switch (stage) {
    report => 'Ảnh báo lỗi',
    inspection => 'Ảnh xác nhận hiện trường',
    progress => 'Ảnh quá trình sửa',
    resolution => 'Ảnh nghiệm thu',
    _ => 'Ảnh',
  };
}

/// **ReportAttachmentResponse**.
class ReportAttachment {
  const ReportAttachment({
    required this.stage,
    required this.url,
    this.id,
    this.reportId,
    this.repairLogId,
    this.thumbnailUrl,
    this.publicId,
    this.format,
    this.bytes,
    this.width,
    this.height,
    this.caption,
    this.latitude,
    this.longitude,
    this.capturedAt,
    this.uploadedByUserId,
    this.createdAt,
  });

  final int? id;
  final int? reportId;
  final int? repairLogId;
  final String stage;
  final String url;
  final String? thumbnailUrl;
  final String? publicId;
  final String? format;
  final int? bytes;
  final int? width;
  final int? height;
  final String? caption;
  final double? latitude;
  final double? longitude;
  final DateTime? capturedAt;
  final int? uploadedByUserId;
  final DateTime? createdAt;

  /// URL cho lưới/thumbnail — rơi về [url] nếu backend không có thumbnail.
  String get previewUrl =>
      (thumbnailUrl != null && thumbnailUrl!.isNotEmpty) ? thumbnailUrl! : url;

  bool get hasLocation => latitude != null && longitude != null;

  factory ReportAttachment.fromJson(Map<String, dynamic> json) {
    return ReportAttachment(
      id: _asInt(json['id']),
      reportId: _asInt(json['reportId']),
      repairLogId: _asInt(json['repairLogId']),
      stage: '${json['stage'] ?? ReportStage.report}'.toUpperCase(),
      url: '${json['url'] ?? json['secureUrl'] ?? ''}',
      thumbnailUrl: json['thumbnailUrl']?.toString(),
      publicId: json['publicId']?.toString(),
      format: json['format']?.toString(),
      bytes: _asInt(json['bytes']),
      width: _asInt(json['width']),
      height: _asInt(json['height']),
      caption: json['caption']?.toString(),
      latitude: _asDouble(json['latitude']),
      longitude: _asDouble(json['longitude']),
      capturedAt: _asDate(json['capturedAt']),
      uploadedByUserId: _asInt(json['uploadedByUserId']),
      createdAt: _asDate(json['createdAt']),
    );
  }

  /// Ảnh cũ chỉ có URL (dán trong mô tả phiếu trước khi có Cloudinary).
  factory ReportAttachment.legacyUrl(
    String url, {
    String stage = ReportStage.report,
  }) => ReportAttachment(stage: stage, url: url);

  /// Parse `attachments[]` bất kỳ (null/không phải List ⇒ rỗng); bỏ phần tử
  /// không có URL.
  static List<ReportAttachment> listFrom(dynamic raw) {
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((e) => ReportAttachment.fromJson(Map<String, dynamic>.from(e)))
        .where((a) => a.url.isNotEmpty)
        .toList(growable: false);
  }

  /// Nhóm theo stage, giữ thứ tự [ReportStage.ordered] (stage lạ xếp cuối).
  /// Chỉ trả về nhóm có ảnh.
  static Map<String, List<ReportAttachment>> groupByStage(
    Iterable<ReportAttachment> attachments,
  ) {
    final buckets = <String, List<ReportAttachment>>{};
    for (final a in attachments) {
      buckets.putIfAbsent(a.stage, () => []).add(a);
    }
    final ordered = <String, List<ReportAttachment>>{};
    for (final stage in ReportStage.ordered) {
      final list = buckets.remove(stage);
      if (list != null && list.isNotEmpty) ordered[stage] = list;
    }
    ordered.addAll(buckets);
    return ordered;
  }
}

int? _asInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse('${value ?? ''}');
}

double? _asDouble(dynamic value) {
  if (value is double) return value;
  if (value is num) return value.toDouble();
  return double.tryParse('${value ?? ''}');
}

DateTime? _asDate(dynamic value) {
  if (value == null) return null;
  return DateTime.tryParse('$value');
}
