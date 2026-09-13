import 'package:smart_laundry_locker/features/locker/domain/value_objects/locker_size.dart';
import 'package:smart_laundry_locker/features/locker/domain/value_objects/locker_status.dart';

/// Domain Entity: Locker
/// Đại diện cho một ngăn locker riêng lẻ trong cabinet.
class Locker {
  final String id;
  final String cabinetId;
  final String? sizeId;
  final int row;
  final int column;
  final LockerStatus status;
  final bool isOpen;
  final bool isLocked;
  final bool isActive;
  final LockerSize? size;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Locker({
    required this.id,
    required this.cabinetId,
    this.sizeId,
    required this.row,
    required this.column,
    required this.status,
    this.isOpen = false,
    this.isLocked = true,
    this.isActive = true,
    this.size,
    this.createdAt,
    this.updatedAt,
  });

  /// Business logic: Kiểm tra locker có sẵn để thuê không
  bool get isAvailable =>
      status == LockerStatus.available && isActive && !isOpen;

  /// Business logic: Kiểm tra locker đang được sử dụng
  bool get isInUse =>
      status == LockerStatus.inUse ||
      status == LockerStatus.occupied ||
      status == LockerStatus.reserved;

  /// Business logic: Lấy vị trí hiển thị (1-indexed)
  String get displayPosition => '${row}x${column}';

  /// Business logic: Lấy label của size
  String get sizeLabel => size?.label ?? 'Unknown';

  Locker copyWith({
    String? id,
    String? cabinetId,
    String? sizeId,
    int? row,
    int? column,
    LockerStatus? status,
    bool? isOpen,
    bool? isLocked,
    bool? isActive,
    LockerSize? size,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Locker(
      id: id ?? this.id,
      cabinetId: cabinetId ?? this.cabinetId,
      sizeId: sizeId ?? this.sizeId,
      row: row ?? this.row,
      column: column ?? this.column,
      status: status ?? this.status,
      isOpen: isOpen ?? this.isOpen,
      isLocked: isLocked ?? this.isLocked,
      isActive: isActive ?? this.isActive,
      size: size ?? this.size,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Locker && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
