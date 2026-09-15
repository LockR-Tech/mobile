import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:smart_laundry_locker/core/config/business_config.dart';
import 'package:smart_laundry_locker/core/config/business_config_service.dart';

import '../../helpers/test_helpers.dart';

class _MemoryStore implements BusinessConfigStore {
  String? value;
  int writes = 0;

  @override
  Future<String?> read() async => value;

  @override
  Future<void> write(String value) async {
    this.value = value;
    writes++;
  }
}

void _replyOk(DioAdapter adapter, String scope, Map<String, dynamic> data) {
  adapter.onGet(
    '/api/settings/$scope/public',
    (server) => server.reply(200, apiOk(data)),
  );
}

void _replyStatus(DioAdapter adapter, String scope, int status) {
  adapter.onGet(
    '/api/settings/$scope/public',
    (server) => server.reply(status, apiError('Không tìm thấy', code: status)),
  );
}

void main() {
  late DioAdapter adapter;
  late _MemoryStore store;
  late DateTime now;
  late BusinessConfigService service;

  setUp(() {
    final mock = createMockDio();
    adapter = mock.adapter;
    store = _MemoryStore();
    now = DateTime(2026, 9, 15, 9);
    service = BusinessConfigService(
      dio: mock.dio,
      store: store,
      clock: () => now,
    );
  });

  test('bắt đầu bằng giá trị mặc định', () {
    expect(service.current, equals(BusinessConfig.defaults()));
    expect(service.isFresh, isFalse);
  });

  test('tải các scope và phát giá trị mới', () async {
    _replyOk(adapter, 'order', {
      'app.order.send-base-fee': 20000,
      'app.order.rental-quick-hours': [1, 3, 6],
    });
    _replyOk(adapter, 'payment', {
      'app.payment.topup-presets': [30000, 90000],
      'app.payment.enabled-methods': 'WALLET,VNPAY',
    });
    _replyOk(adapter, 'locker', {
      'app.locker.cell-dimensions-xl': '50 × 90 × 50 cm',
    });
    _replyOk(adapter, 'loyalty', {'app.loyalty.tier-gold-points': 3000});
    _replyOk(adapter, 'store', {'app.store.nearby-default-radius-km': 3});

    var notified = 0;
    service.listenable.addListener(() => notified++);

    final config = await service.refresh();

    expect(config.sendBaseFee, 20000);
    expect(config.rentalQuickHours, [1, 3, 6]);
    expect(config.topupPresets, [30000, 90000]);
    expect(config.enabledPaymentMethods, ['WALLET', 'VNPAY']);
    expect(config.cellDimensionsXl, '50 × 90 × 50 cm');
    expect(config.tierGoldPoints, 3000);
    expect(config.nearbyDefaultRadiusKm, 3);
    expect(service.current, same(config));
    expect(service.isFresh, isTrue);
    expect(notified, 1);

    // Đã lưu last-known.
    await Future<void>.delayed(Duration.zero);
    expect(store.writes, 1);
    final saved = jsonDecode(store.value!) as Map<String, dynamic>;
    expect(saved['scopes']['order']['app.order.send-base-fee'], 20000);
  });

  test('backend chưa triển khai (404) ⇒ giữ mặc định, không lưu', () async {
    for (final scope in BusinessConfig.scopes) {
      _replyStatus(adapter, scope, 404);
    }

    final config = await service.refresh();

    expect(config, equals(BusinessConfig.defaults()));
    expect(service.isFresh, isFalse);
    expect(store.writes, 0);
  });

  test('một scope lỗi 5xx ⇒ scope đó dùng mặc định, scope khác vẫn nhận', () async {
    _replyOk(adapter, 'order', {'app.order.rental-rate-xl': 15000});
    _replyStatus(adapter, 'payment', 503);
    // locker/loyalty/store không có route mock ⇒ adapter ném lỗi.

    final config = await service.refresh();

    expect(config.rentalRateXl, 15000);
    expect(config.topupPresets, BusinessConfig.defaults().topupPresets);
    expect(config.cellDimensionsStandard,
        BusinessConfig.defaults().cellDimensionsStandard);
    expect(service.isFresh, isTrue);
  });

  test('phản hồi success=false hoặc data sai dạng bị bỏ qua', () async {
    adapter.onGet(
      '/api/settings/order/public',
      (server) => server.reply(200, {
        'success': false,
        'data': {'app.order.send-base-fee': 99999},
      }),
    );
    adapter.onGet(
      '/api/settings/payment/public',
      (server) => server.reply(200, apiOk(['not', 'a', 'map'])),
    );

    final config = await service.refresh();

    expect(config, equals(BusinessConfig.defaults()));
  });

  test('trong TTL không gọi lại mạng; hết TTL thì làm mới', () async {
    _replyOk(adapter, 'order', {'app.order.send-base-fee': 20000});
    await service.refresh();

    // Server đổi giá nhưng cache còn mới.
    _replyOk(adapter, 'order', {'app.order.send-base-fee': 25000});
    now = now.add(const Duration(minutes: 4));
    expect((await service.refresh()).sendBaseFee, 20000);

    now = now.add(const Duration(minutes: 2));
    expect(service.isFresh, isFalse);
    expect((await service.refresh()).sendBaseFee, 25000);
  });

  test('force bỏ qua TTL', () async {
    _replyOk(adapter, 'order', {'app.order.send-base-fee': 20000});
    await service.refresh();

    _replyOk(adapter, 'order', {'app.order.send-base-fee': 30000});
    expect((await service.refresh(force: true)).sendBaseFee, 30000);
  });

  test('lỗi sau khi đã tải thành công ⇒ giữ last-known', () async {
    _replyOk(adapter, 'order', {'app.order.send-base-fee': 20000});
    await service.refresh();

    _replyStatus(adapter, 'order', 500);
    final config = await service.refresh(force: true);

    expect(config.sendBaseFee, 20000);
  });

  test('restore dùng giá trị đã lưu cho lần hiển thị đầu', () async {
    store.value = jsonEncode({
      'savedAt': '2026-09-14T10:00:00.000',
      'scopes': {
        'order': {'app.order.rental-rate-standard': 7000},
        'locker': {'app.locker.cell-dimensions-standard': '1 × 2 × 3 cm'},
      },
    });

    await service.restore();

    expect(service.current.rentalRateStandard, 7000);
    expect(service.current.cellDimensionsStandard, '1 × 2 × 3 cm');
    // Giá trị khôi phục không được coi là "mới" ⇒ vẫn làm mới khi mở màn.
    expect(service.isFresh, isFalse);
  });

  test('init: dữ liệu lưu hỏng + backend lỗi ⇒ vẫn chạy với mặc định', () async {
    store.value = '{not json';
    for (final scope in BusinessConfig.scopes) {
      _replyStatus(adapter, scope, 404);
    }

    await service.init();

    expect(service.current, equals(BusinessConfig.defaults()));
  });
}
