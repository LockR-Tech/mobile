import 'package:flutter_test/flutter_test.dart';
import 'package:smart_laundry_locker/core/utils/server_note_keys.dart';

void main() {
  // Câu tiếng Anh lấy đúng từ backend common-lib i18n/server-text-en.json.
  test('tag tiếng Anh nhận ra như tag tiếng Việt', () {
    expect(
      serverNoteKeys('[BOX RELOCATED] Moved order ORD-1 to box #5.'),
      contains('[ĐIỀU CHUYỂN Ô]'),
    );
    expect(
      serverNoteKeys(
        '[SEALED TO HUB] Sealed the items (Seal code: S1) and sent to the Hub for storage.',
      ),
      contains('NIÊM PHONG'),
    );
    expect(
      serverNoteKeys(
        '[HANDED OVER IN PERSON] The technician handed the items over',
      ),
      contains('BÀN GIAO'),
    );
    expect(
      serverNoteKeys('[CONFIRMED & BOX LOCKED] ...'),
      contains('[XÁC NHẬN & KHÓA Ô]'),
    );
    expect(
      serverNoteKeys('Technician moved the parcel to box 7'),
      contains('ĐIỀU CHUYỂN'),
    );
  });

  test('ghi chú tiếng Việt giữ nguyên chữ HOA', () {
    expect(
      serverNoteKeys('[ĐIỀU CHUYỂN Ô] Đã chuyển đơn sang ô #5.'),
      '[ĐIỀU CHUYỂN Ô] ĐÃ CHUYỂN ĐƠN SANG Ô #5.',
    );
  });

  test('số ô trong ghi chú điều chuyển, cả hai ngôn ngữ', () {
    expect(
      relocatedBoxNumber('[ĐIỀU CHUYỂN Ô] Đã chuyển đơn hàng X sang ô #5.'),
      '5',
    );
    expect(relocatedBoxNumber('[BOX RELOCATED] Moved order X to box #5.'), '5');
    expect(
      lockedOrFirstBoxNumber('Đã chuyển đồ sang ô #5 và khóa bảo trì ô #3'),
      '3',
    );
    expect(
      lockedOrFirstBoxNumber('Moved the items to box #5 and locked box #3'),
      '3',
    );
    expect(lockedOrFirstBoxNumber('Box #3 locked for maintenance'), '3');
    expect(firstBoxNumber('KTV kiểm tra ô #9: ô hoạt động'), '9');
    expect(firstBoxNumber('Technician checked box #9: box working'), '9');
    expect(relocatedBoxNumber('không có gì'), isNull);
  });
}
