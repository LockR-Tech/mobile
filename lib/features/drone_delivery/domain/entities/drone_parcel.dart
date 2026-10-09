/// Khai báo kiện hàng của một đơn drone — khớp phần khai báo trong
/// `CreateDroneDeliveryOrderRequest` của order-service.
library;

/// Mã loại hàng backend chấp nhận → nhãn hiển thị. Thứ tự là thứ tự hiện trên form.
const droneParcelCategories = <String, String>{
  'DOCUMENT': 'Tài liệu',
  'FOOD': 'Đồ ăn',
  'CLOTHING': 'Quần áo',
  'ELECTRONICS': 'Điện tử',
  'COSMETICS': 'Mỹ phẩm',
  'OTHER': 'Khác',
};

String droneParcelCategoryLabel(String? code) {
  final key = (code ?? '').toUpperCase();
  if (key.isEmpty) return '—';
  return droneParcelCategories[key] ?? code!;
}

/// `30 × 20 × 10 cm`; null khi người gửi không khai kích thước.
String? droneParcelSizeLabel(int? lengthCm, int? widthCm, int? heightCm) =>
    lengthCm == null || widthCm == null || heightCm == null
    ? null
    : '$lengthCm × $widthCm × $heightCm cm';

/// Kiện xoay được: so cạnh dài nhất với cạnh dài nhất của khoang, v.v. — cùng cách
/// tính với `OrderService.validateDroneParcelDeclaration`.
bool droneParcelFits(List<int> parcelCm, List<int> bayCm) {
  final parcel = [...parcelCm]..sort();
  final bay = [...bayCm]..sort();
  if (parcel.length != 3 || bay.length != 3) return false;
  for (var i = 0; i < 3; i++) {
    if (parcel[i] > bay[i]) return false;
  }
  return true;
}

/// Kiện chờ trả đang ở đâu (`parcelHeldAt` của read model).
String droneParcelHeldAtLabel(String? code) =>
    switch ((code ?? '').toUpperCase()) {
      'SOURCE_BOX' => 'Còn trong ô gửi',
      'FLIGHT_TEAM' => 'Đội bay đang giữ',
      _ => '—',
    };

class DroneParcelDeclaration {
  const DroneParcelDeclaration({
    this.category = 'OTHER',
    this.lengthCm,
    this.widthCm,
    this.heightCm,
    this.declaredValue,
    this.fragile = false,
    required this.prohibitedItemsDeclared,
  });

  final String category;

  /// Kích thước tuỳ chọn; có thì đủ cả ba cạnh.
  final int? lengthCm;
  final int? widthCm;
  final int? heightCm;

  /// Giá trị khai báo (VND) làm căn cứ bồi thường, tuỳ chọn.
  final int? declaredValue;
  final bool fragile;

  /// Người gửi cam kết kiện không chứa hàng cấm bay — backend bắt buộc true.
  final bool prohibitedItemsDeclared;

  Map<String, dynamic> toJson() => {
    'parcelCategory': category,
    if (lengthCm != null) 'parcelLengthCm': lengthCm,
    if (widthCm != null) 'parcelWidthCm': widthCm,
    if (heightCm != null) 'parcelHeightCm': heightCm,
    if (declaredValue != null) 'declaredValue': declaredValue,
    'fragile': fragile,
    'prohibitedItemsDeclared': prohibitedItemsDeclared,
  };
}
