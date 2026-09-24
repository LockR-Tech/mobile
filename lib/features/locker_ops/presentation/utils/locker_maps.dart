import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

/// Kết quả mở chỉ đường — tách "không có toạ độ" khỏi "không mở được app".
enum DirectionsResult {
  opened,

  /// Tủ chưa có toạ độ lẫn địa chỉ.
  noLocation,

  /// Có đích đến nhưng máy không mở được (không có trình duyệt/bản đồ).
  launchFailed,
}

/// Mở Google Maps chỉ đường tới tủ.
///
/// Không dùng `canLaunchUrl` làm cổng chặn: từ Android 11 (API 30) hệ thống lọc
/// package, nên nếu thiếu khai báo `<queries>` trong AndroidManifest thì hàm đó
/// trả `false` kể cả khi máy có Chrome/Maps — nút chỉ đường im lặng không làm gì.
/// Ở đây cứ gọi thẳng `launchUrl` rồi bắt lỗi.
Future<DirectionsResult> openLockerDirectionsResult({
  double? latitude,
  double? longitude,
  String? address,
}) async {
  final Uri? uri;
  if (latitude != null && longitude != null) {
    uri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1'
      '&destination=$latitude,$longitude'
      '&travelmode=driving',
    );
  } else if (address != null && address.trim().isNotEmpty) {
    uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1'
      '&query=${Uri.encodeComponent(address.trim())}',
    );
  } else {
    uri = null;
  }

  if (uri == null) return DirectionsResult.noLocation;

  try {
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (opened) return DirectionsResult.opened;
  } catch (error) {
    debugPrint('openLockerDirections externalApplication failed: $error');
  }

  // Máy không có app bản đồ/trình duyệt riêng — thử mở trong webview của app.
  try {
    final opened = await launchUrl(uri, mode: LaunchMode.platformDefault);
    return opened ? DirectionsResult.opened : DirectionsResult.launchFailed;
  } catch (error) {
    debugPrint('openLockerDirections platformDefault failed: $error');
    return DirectionsResult.launchFailed;
  }
}

/// Giữ chữ ký cũ cho nơi gọi chỉ cần biết thành công hay không.
Future<bool> openLockerDirections({
  double? latitude,
  double? longitude,
  String? address,
}) async =>
    await openLockerDirectionsResult(
      latitude: latitude,
      longitude: longitude,
      address: address,
    ) ==
    DirectionsResult.opened;
