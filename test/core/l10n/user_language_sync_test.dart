import 'package:flutter_test/flutter_test.dart';
import 'package:smart_laundry_locker/core/l10n/l10n.dart';
import 'package:smart_laundry_locker/core/l10n/user_language_sync.dart';

import '../../helpers/test_helpers.dart';

void main() {
  setUp(UserLanguageSync.reset);
  tearDown(() => L10n.load(L10n.vi));

  test('báo ngôn ngữ đang chọn cho server, đổi ngôn ngữ thì báo lại', () async {
    final client = createAuthenticatedApiClient();
    final sent = <Object?>[];
    client.adapter.onPut('/api/user/language', (server) {
      server.reply(200, {'success': true});
    }, data: {'language': 'vi'});
    client.adapter.onPut('/api/user/language', (server) {
      server.reply(200, {'success': true});
    }, data: {'language': 'en'});

    await UserLanguageSync.sync(apiClient: client.apiClient);
    sent.add(UserLanguageSync.lastSynced);
    // Cùng ngôn ngữ: không gửi lại.
    await UserLanguageSync.sync(apiClient: client.apiClient);
    L10n.load(L10n.en);
    await UserLanguageSync.sync(apiClient: client.apiClient);
    sent.add(UserLanguageSync.lastSynced);

    expect(sent, ['vi', 'en']);
  });

  test('chưa đăng nhập thì không gọi server', () async {
    final client = createMockApiClient();

    await UserLanguageSync.sync(apiClient: client.apiClient);

    expect(UserLanguageSync.lastSynced, isNull);
  });
}
