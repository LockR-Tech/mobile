import 'package:flutter_test/flutter_test.dart';
import 'package:smart_laundry_locker/features/drone_mission/data/mission_repository.dart';

void main() {
  test(
    'tên file kế hoạch bay bỏ dấu tiếng Việt thay vì thành dấu gạch dưới',
    () {
      expect(missionFileBaseName('Kế hoạch bay mới'), 'Ke hoach bay moi');
      expect(
        missionFileBaseName('Bay kiểm tra quanh trạm FPT'),
        'Bay kiem tra quanh tram FPT',
      );
      expect(missionFileBaseName('ĐƯỜNG BAY Ổ 2'), 'DUONG BAY O 2');
    },
  );

  test(
    'ký tự không hợp lệ cho tên file đổi thành gạch dưới, tên rỗng thành mission',
    () {
      expect(missionFileBaseName('a/b:c'), 'a_b_c');
      expect(missionFileBaseName('   '), 'mission');
    },
  );
}
