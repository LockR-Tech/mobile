import 'package:flutter_map/flutter_map.dart';

/// Lớp nền bản đồ cho các màn drone.
///
/// Không dùng thẳng `tile.openstreetmap.org`: nhiều nhà mạng ở Việt Nam chặn tên miền
/// openstreetmap.org (bắt tay TLS thất bại) nên bản đồ chỉ còn nền xám. CARTO phục vụ
/// cùng dữ liệu OpenStreetMap qua CDN riêng; OSM chỉ còn là dự phòng khi CARTO lỗi.
TileLayer droneBaseTileLayer() => TileLayer(
  urlTemplate:
      'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}.png',
  subdomains: const ['a', 'b', 'c', 'd'],
  fallbackUrl: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
  userAgentPackageName: 'com.laundrylocker.mobile',
  maxNativeZoom: 19,
);
