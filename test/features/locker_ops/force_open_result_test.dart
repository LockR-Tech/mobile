import 'package:flutter_test/flutter_test.dart';
import 'package:smart_laundry_locker/features/locker_ops/data/force_open_result.dart';

void main() {
  group('ForceOpenResult.fromResponse', () {
    test('accepted = true (tủ xác nhận đã mở) ⇒ thành công', () {
      final result = ForceOpenResult.fromResponse({
        'accepted': true,
        'status': 'OPENED',
        'message': 'Đã mở ô khẩn cấp',
      });

      expect(result.accepted, isTrue);
      expect(result.status, 'OPENED');
    });

    test('accepted = false ⇒ thất bại, giữ nguyên lý do từ backend', () {
      const reason =
          'Tủ không phản hồi lệnh mở khẩn cấp sau 10 giây — ô có thể chưa mở, '
          'vui lòng kiểm tra tại tủ rồi thử lại';
      final result = ForceOpenResult.fromResponse({
        'accepted': false,
        'status': 'TIMEOUT',
        'message': reason,
      });

      expect(result.accepted, isFalse);
      expect(result.status, 'TIMEOUT');
      expect(result.failureMessage, reason);
    });

    test('accepted = false không kèm message ⇒ dùng câu dự phòng', () {
      final result = ForceOpenResult.fromResponse({
        'accepted': false,
        'status': 'JAMMED',
        'message': '  ',
      });

      expect(result.accepted, isFalse);
      expect(result.message, isNull);
      expect(result.failureMessage, ForceOpenResult.fallbackFailureMessage);
    });

    test('backend cũ không có accepted ⇒ coi như thành công', () {
      expect(ForceOpenResult.fromResponse({}).accepted, isTrue);
      expect(
        ForceOpenResult.fromResponse({'boxId': 5, 'lockerId': 7}).accepted,
        isTrue,
      );
    });
  });
}
