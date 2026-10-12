import 'package:flutter_test/flutter_test.dart';
import 'package:smart_laundry_locker/features/locker/domain/utils/locker_layout_helper.dart';
import 'package:smart_laundry_locker/features/stores/domain/entities/store.dart';

void main() {
  group('bookingBlockReason — tủ mất kết nối / bảo trì không cho đặt ô', () {
    test('tủ hoạt động và online (hoặc server cũ chưa trả online) ⇒ đặt được', () {
      expect(LockerLayoutHelper.bookingBlockReason(status: 'ACTIVE', online: true), isNull);
      expect(LockerLayoutHelper.bookingBlockReason(status: 'ACTIVE', online: null), isNull);
      expect(LockerLayoutHelper.bookingBlockReason(status: null, online: null), isNull);
    });

    test('online == false ⇒ chặn, kể cả khi status ACTIVE', () {
      expect(
        LockerLayoutHelper.bookingBlockReason(status: 'ACTIVE', online: false),
        contains('mất kết nối'),
      );
      expect(
        LockerLayoutHelper.bookingBlockReason(status: 'DISCONNECTED'),
        contains('mất kết nối'),
      );
    });

    test('bảo trì / tạm ngưng ⇒ chặn với lý do riêng', () {
      expect(
        LockerLayoutHelper.bookingBlockReason(status: 'MAINTENANCE', online: true),
        contains('bảo trì'),
      );
      expect(
        LockerLayoutHelper.bookingBlockReason(status: 'INACTIVE', online: true),
        contains('tạm ngưng'),
      );
    });
  });

  group('loại ô theo cellType backend', () {
    test('ô #2/#3 thiếu cellType không bị coi là ô drone; cột 0 không bị ép là XL', () {
      final cells = LockerLayoutHelper.enrichCells([
        {'id': 1, 'boxNumber': 2, 'colIndex': 1, 'rowIndex': 1},
        {'id': 2, 'boxNumber': 3, 'colIndex': 2, 'rowIndex': 1, 'cellType': ''},
        {'id': 3, 'boxNumber': 1, 'colIndex': 0, 'rowIndex': 2, 'cellType': 'STANDARD'},
      ]);
      for (final cell in cells) {
        expect(LockerLayoutHelper.isDrone(cell), isFalse, reason: '$cell');
        expect(LockerLayoutHelper.isXl(cell), isFalse, reason: '$cell');
        expect(cell['cellType'], 'STANDARD');
      }
    });

    test('tin cellType DRONE / XL của backend', () {
      final cells = LockerLayoutHelper.enrichCells([
        {'id': 1, 'boxNumber': 7, 'colIndex': 2, 'cellType': 'drone'},
        {'id': 2, 'boxNumber': 8, 'colIndex': 1, 'cellType': 'XL'},
        {'id': 3, 'boxNumber': 9, 'size': 'XL'},
      ]);
      expect(LockerLayoutHelper.isDrone(cells[0]), isTrue);
      expect(cells[0]['isDrone'], isTrue);
      expect(LockerLayoutHelper.isXl(cells[1]), isTrue);
      // Thiếu cellType: chỉ size XL mới là ô vali.
      expect(LockerLayoutHelper.isXl(cells[2]), isTrue);
    });

    test('đếm ô trống theo loại cho thẻ bản đồ', () {
      final groups = LockerLayoutHelper.summarizeCells([
        {'cellType': 'STANDARD', 'size': 'MEDIUM', 'status': 'AVAILABLE'},
        {'cellType': 'STANDARD', 'size': 'MEDIUM', 'status': 'OCCUPIED'},
        {'cellType': 'DRONE', 'status': 'AVAILABLE'},
        {'cellType': 'XL', 'status': 'FAULT'},
      ]);
      expect(groups.map((g) => g.key), ['MEDIUM', 'XL', 'DRONE']);
      final medium = groups.first;
      expect((medium.available, medium.total), (1, 2));
      expect((groups[1].available, groups[1].total), (0, 1));
      expect((groups[2].available, groups[2].total), (1, 1));
    });
  });

  test('Store.hasLocation loại toạ độ NaN / ngoài phạm vi', () {
    expect(const Store(id: 1, name: 'A', latitude: 10.7, longitude: 106.6).hasLocation, isTrue);
    expect(const Store(id: 1, name: 'A', latitude: double.nan, longitude: 106.6).hasLocation, isFalse);
    expect(const Store(id: 1, name: 'A', latitude: 10.7, longitude: double.infinity).hasLocation, isFalse);
    expect(const Store(id: 1, name: 'A', latitude: 120, longitude: 10).hasLocation, isFalse);
    expect(const Store(id: 1, name: 'A').hasLocation, isFalse);
  });
}
