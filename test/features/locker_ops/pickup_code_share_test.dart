import 'package:flutter_test/flutter_test.dart';
import 'package:smart_laundry_locker/features/locker_ops/domain/pickup_code_share.dart';

void main() {
  group('buildPickupShareMessage', () {
    test('đủ thông tin: tủ, địa chỉ, ô, mã, hạn', () {
      final message = buildPickupShareMessage(
        code: '482913',
        lockerName: 'Tủ Thư viện',
        lockerAddress: 'Số 1 Đường Thử Nghiệm',
        boxNumber: 4,
        deadline: DateTime(2026, 10, 15, 18, 5),
      );

      expect(
        message,
        'Lock.R: Bạn có kiện hàng gửi tới tủ Tủ Thư viện, Số 1 Đường Thử '
        'Nghiệm. Ô số 4. Mã lấy hàng: 482913. Hạn lấy: 18:05 15/10. '
        'Nhập mã tại màn hình tủ (kiosk) để mở ô.',
      );
    });

    test('thiếu thông tin thì bỏ phần đó, vẫn có mã và hướng dẫn', () {
      final message = buildPickupShareMessage(code: ' 111222 ');

      expect(
        message,
        'Lock.R: Bạn có kiện hàng gửi tới tủ Lock.R. Mã lấy hàng: 111222. '
        'Nhập mã tại màn hình tủ (kiosk) để mở ô.',
      );
      expect(message, isNot(contains('Ô số')));
      expect(message, isNot(contains('Hạn lấy')));
    });

    test('tên/địa chỉ rỗng hoặc có dấu chấm cuối không làm hỏng câu', () {
      final message = buildPickupShareMessage(
        code: '123456',
        lockerName: '   ',
        lockerAddress: 'Toà A.',
      );

      expect(
        message,
        startsWith('Lock.R: Bạn có kiện hàng gửi tới tủ Lock.R, Toà A. Mã'),
      );
      expect(message, isNot(contains('..')));
    });

    test('đơn drone dùng lời giao bằng drone', () {
      final message = buildPickupShareMessage(
        code: '765432',
        kind: PickupShareKind.droneDelivery,
        lockerName: 'Tủ B',
        deadline: DateTime(2026, 1, 2, 9, 30),
      );

      expect(
        message,
        'Lock.R: Bạn có kiện hàng giao bằng drone đang chờ tại tủ Tủ B. '
        'Mã lấy hàng: 765432. Hạn lấy: 09:30 02/01. '
        'Nhập mã tại màn hình tủ (kiosk) để mở ô.',
      );
    });

    test('đủ trường (trừ địa chỉ) mà vẫn ngắn', () {
      final message = buildPickupShareMessage(
        code: '482913',
        lockerName: 'Tủ Thư viện',
        boxNumber: 12,
        deadline: DateTime(2026, 10, 15, 18, 5),
      );
      // Tin có dấu tính theo UCS-2 (67 ký tự mỗi phần khi ghép): khoảng 2–3 tin.
      expect(message.length, lessThanOrEqualTo(150));
    });
  });

  group('SMS', () {
    test('chuẩn hoá số: bỏ khoảng trắng/dấu, giữ + quốc tế', () {
      expect(normalizeSmsPhone('0909 123 456'), '0909123456');
      expect(normalizeSmsPhone('+84 909-123-456'), '+84909123456');
      expect(normalizeSmsPhone('(090) 912.3456'), '0909123456');
      expect(normalizeSmsPhone('0909'), isNull);
      expect(normalizeSmsPhone('   '), isNull);
      expect(normalizeSmsPhone(null), isNull);
    });

    test('Android: sms:<số>?body=<mã hoá %20>', () {
      final uri = buildPickupSmsUri('0909 123 456', 'Mã lấy hàng: 1 & 2');

      expect(uri, isNotNull);
      expect(uri!.scheme, 'sms');
      expect(
        uri.toString(),
        'sms:0909123456?body=M%C3%A3%20l%E1%BA%A5y%20h%C3%A0ng%3A%201%20%26%202',
      );
      // Không dùng dấu + cho khoảng trắng (ứng dụng SMS hiện nguyên dấu +).
      expect(uri.toString(), isNot(contains('+')));
    });

    test('iOS: nội dung sau &body=', () {
      final uri = buildPickupSmsUri('+84909123456', 'Ma 1', iosStyle: true);

      expect(uri.toString(), 'sms:+84909123456&body=Ma%201');
    });

    test('không có số hợp lệ thì không có link', () {
      expect(buildPickupSmsUri(null, 'x'), isNull);
      expect(buildPickupSmsUri('12', 'x'), isNull);
    });

    test('PickupCodeShare.smsUri gửi đúng tin nhắn', () {
      const share = PickupCodeShare(
        code: '111222',
        receiverPhone: '0909123456',
      );
      final uri = share.smsUri()!;

      expect(Uri.decodeComponent(uri.toString().split('body=').last),
          share.message);
      expect(share.smsPhone, '0909123456');
    });
  });

  group('pickupCodeShareForOrder', () {
    final now = DateTime.utc(2026, 10, 13, 3);
    Map<String, dynamic> sendOrder([Map<String, dynamic> extra = const {}]) => {
      'id': 61,
      'type': 'SEND',
      'status': 'STORING',
      'paymentStatus': 'PAID',
      'userId': 99,
      'receiverId': null,
      'pinCode': '654321',
      'receiverName': 'Bình',
      'receiverPhone': '0909123456',
      'pickupDeadline': '2026-10-14T03:00:00',
      ...extra,
    };

    test('đơn gửi đã vào ô: có mã, người nhận, hạn', () {
      final share = pickupCodeShareForOrder(
        sendOrder(),
        lockerName: 'Tủ A',
        lockerAddress: 'Toà B',
        boxNumber: 3,
        now: now,
      )!;

      expect(share.kind, PickupShareKind.lockerParcel);
      expect(share.code, '654321');
      expect(share.receiverName, 'Bình');
      expect(share.receiverPhone, '0909123456');
      expect(share.boxNumber, 3);
      expect(share.deadline, DateTime.utc(2026, 10, 14, 3).toLocal());
      expect(share.message, contains('Tủ A, Toà B. Ô số 3. Mã lấy hàng: 654321.'));
      expect(share.message, contains('Hạn lấy: '));
    });

    test('chưa bỏ hàng (PIN bỏ hàng của người gửi) thì không chia sẻ', () {
      expect(
        pickupCodeShareForOrder(sendOrder({'status': 'INITIALIZED'}), now: now),
        isNull,
      );
      expect(
        pickupCodeShareForOrder(sendOrder({'status': 'COMPLETED'}), now: now),
        isNull,
      );
    });

    test('không có mã thì không chia sẻ', () {
      expect(pickupCodeShareForOrder(sendOrder({'pinCode': null}), now: now),
          isNull);
      expect(pickupCodeShareForOrder(sendOrder({'pinCode': ' '}), now: now),
          isNull);
    });

    test('người nhận chính là người đặt thì không chia sẻ', () {
      expect(
        pickupCodeShareForOrder(sendOrder({'receiverId': 99}), now: now),
        isNull,
      );
      // Người nhận có tài khoản khác vẫn chia sẻ được.
      expect(
        pickupCodeShareForOrder(sendOrder({'receiverId': 7}), now: now),
        isNotNull,
      );
    });

    test('đơn thuê tủ / giặt không phải mã cho người nhận', () {
      expect(pickupCodeShareForOrder(sendOrder({'type': 'RENTAL'}), now: now),
          isNull);
      expect(pickupCodeShareForOrder(sendOrder({'type': 'LAUNDRY'}), now: now),
          isNull);
    });

    test('đơn drone đã thanh toán, hàng đã vào ô: lời drone', () {
      final share = pickupCodeShareForOrder(
        sendOrder({'type': 'DRONE_DELIVERY', 'receiverId': 7}),
        lockerName: 'Tủ nhận',
        now: now,
      )!;

      expect(share.kind, PickupShareKind.droneDelivery);
      expect(share.message, contains('giao bằng drone đang chờ tại tủ Tủ nhận'));
    });

    test('đơn drone chưa thanh toán thì không chia sẻ', () {
      expect(
        pickupCodeShareForOrder(
          sendOrder({'type': 'DRONE_DELIVERY', 'paymentStatus': 'UNPAID'}),
          now: now,
        ),
        isNull,
      );
    });

    test('đã quá hạn thì bỏ dòng hạn lấy', () {
      final share = pickupCodeShareForOrder(
        sendOrder({'pickupDeadline': '2026-10-12T03:00:00'}),
        now: now,
      )!;

      expect(share.deadline, isNull);
      expect(share.message, isNot(contains('Hạn lấy')));
    });
  });
}
