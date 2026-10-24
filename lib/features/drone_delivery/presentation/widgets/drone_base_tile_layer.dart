import 'package:flutter_map/flutter_map.dart';

/// Lớp nền bản đồ cho các màn drone.
///
/// Không dùng thẳng `tile.openstreetmap.org`: từ app (Dart) kết nối tới openstreetmap.org
/// bị cắt ở bước bắt tay TLS trên nhiều mạng Việt Nam nên bản đồ chỉ còn nền xám (trình
/// duyệt vẫn vào được nhờ DNS mã hoá, nên web admin không bị). CARTO cũng không dùng được:
/// từ 2025 trả ô "API KEY REQUIRED". Esri World Street Map không cần khoá và tải được từ
/// Việt Nam; OSM chỉ còn là dự phòng cho từng ô khi Esri lỗi.
TileLayer droneBaseTileLayer() => TileLayer(
  urlTemplate:
      'https://server.arcgisonline.com/ArcGIS/rest/services/World_Street_Map/MapServer/tile/{z}/{y}/{x}',
  fallbackUrl: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
  userAgentPackageName: 'com.laundrylocker.mobile',
  maxNativeZoom: 19,
);
