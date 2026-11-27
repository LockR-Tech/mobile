import 'package:flutter_map/flutter_map.dart';

/// Ô bản đồ đã tải được giữ 30 ngày (F3-G15): mở lại app không phải tải lại bản đồ, kể cả khi
/// máy chủ ô bản đồ chỉ cho giữ 1 ngày. Chính sách OSM yêu cầu giữ tối thiểu 7 ngày nên 30 ngày vẫn
/// đúng chính sách. Chỉ app gốc (Android/iOS) có bộ nhớ này; bản web dùng bộ nhớ đệm của trình duyệt.
const Duration mapTileFreshAge = Duration(days: 30);

/// Giới hạn dung lượng bộ nhớ ô bản đồ trên máy (vượt thì xoá ô cũ nhất lúc mở app).
const int mapTileCacheMaxBytes = 300 * 1024 * 1024;

/// Tạo bộ nhớ ô bản đồ dùng chung — gọi MỘT lần lúc khởi động, trước khi vẽ bản đồ nào, vì cấu
/// hình chỉ áp dụng cho lần tạo đầu tiên.
void initMapTileCache() {
  BuiltInMapCachingProvider.getOrCreateInstance(
    overrideFreshAge: mapTileFreshAge,
    maxCacheSize: mapTileCacheMaxBytes,
  );
}

/// Lớp nền bản đồ DÙNG CHUNG cho mọi màn của app (tủ, chỉ đường, chọn vị trí, drone) để bản đồ
/// trông giống nhau và cùng dùng bộ nhớ 30 ngày.
///
/// Không dùng thẳng `tile.openstreetmap.org`: từ app (Dart) kết nối tới openstreetmap.org
/// bị cắt ở bước bắt tay TLS trên nhiều mạng Việt Nam nên bản đồ chỉ còn nền xám (trình
/// duyệt vẫn vào được nhờ DNS mã hoá). CARTO cũng không dùng được: từ 2025 trả ô
/// "API KEY REQUIRED". Esri World Street Map không cần khoá và tải được từ Việt Nam; OSM chỉ
/// còn là dự phòng cho từng ô khi Esri lỗi. Web admin dùng cùng nguồn Esri.
TileLayer appBaseTileLayer() => TileLayer(
  urlTemplate:
      'https://server.arcgisonline.com/ArcGIS/rest/services/World_Street_Map/MapServer/tile/{z}/{y}/{x}',
  fallbackUrl: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
  userAgentPackageName: 'com.laundrylocker.mobile',
  maxNativeZoom: 19,
);
