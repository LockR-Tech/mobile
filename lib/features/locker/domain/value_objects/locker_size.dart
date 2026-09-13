/// Value Object: LockerSize
/// Đại diện cho kích thước của locker (S, M, L).
/// Value Object là immutable và được so sánh theo giá trị.
class LockerSize {
  final String id;
  final String label; // S, M, L
  final double width;
  final double height;
  final double depth;
  final String? description;

  const LockerSize({
    required this.id,
    required this.label,
    required this.width,
    required this.height,
    required this.depth,
    this.description,
  });

  /// Business logic: Lấy dimensions dạng string
  String get dimensions => '${width}x${height}x$depth';

  /// Business logic: Tính thể tích
  double get volume => width * height * depth;

  /// Factory constructors cho các size phổ biến
  factory LockerSize.small({String id = 'size_s'}) => LockerSize(
    id: id,
    label: 'S',
    width: 57,
    height: 42.8,
    depth: 12.6,
    description: 'Kích thước nhỏ, phù hợp cho túi xách, ví',
  );

  factory LockerSize.medium({String id = 'size_m'}) => LockerSize(
    id: id,
    label: 'M',
    width: 57,
    height: 42.8,
    depth: 24.4,
    description: 'Kích thước trung bình, phù hợp cho ba lô',
  );

  factory LockerSize.large({String id = 'size_l'}) => LockerSize(
    id: id,
    label: 'L',
    width: 57,
    height: 42.8,
    depth: 49.2,
    description: 'Kích thước lớn, phù hợp cho vali',
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LockerSize &&
          runtimeType == other.runtimeType &&
          label == other.label &&
          width == other.width &&
          height == other.height &&
          depth == other.depth;

  @override
  int get hashCode => Object.hash(label, width, height, depth);

  @override
  String toString() => 'LockerSize($label: $dimensions)';
}
