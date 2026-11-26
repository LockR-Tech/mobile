import 'package:flutter/widgets.dart';
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

  group('đăng nhập: ngôn ngữ đi theo tài khoản (F3-G15)', () {
    test('tài khoản đã chọn tiếng Anh ở máy khác ⇒ máy này đổi sang tiếng Anh', () async {
      final client = createAuthenticatedApiClient();
      client.adapter.onGet('/api/user/profile', (server) {
        server.reply(200, {'success': true, 'data': {'id': 5, 'language': 'en'}});
      });
      final applied = <Locale>[];

      await UserLanguageSync.adoptAccountLanguage(
        apiClient: client.apiClient,
        apply: (locale) async => applied.add(locale),
      );

      expect(applied, [const Locale('en')]);
      // Không báo ngược lại server ngôn ngữ cũ của máy này.
      expect(UserLanguageSync.lastSynced, 'en');
    });

    test('vừa tự bấm VI/EN ở màn đăng nhập ⇒ giữ lựa chọn và báo server', () async {
      final client = createAuthenticatedApiClient();
      client.adapter.onGet('/api/user/profile', (server) {
        server.reply(200, {'success': true, 'data': {'id': 5, 'language': 'vi'}});
      });
      client.adapter.onPut('/api/user/language', (server) {
        server.reply(200, {'success': true});
      }, data: {'language': 'en'});
      L10n.load(L10n.en);
      UserLanguageSync.markChosenBeforeLogin();
      final applied = <Locale>[];

      await UserLanguageSync.adoptAccountLanguage(
        apiClient: client.apiClient,
        apply: (locale) async => applied.add(locale),
      );

      expect(applied, isEmpty);
      expect(UserLanguageSync.lastSynced, 'en');
    });

    test('tài khoản chưa có ngôn ngữ ⇒ báo server ngôn ngữ của máy này', () async {
      final client = createAuthenticatedApiClient();
      client.adapter.onGet('/api/user/profile', (server) {
        server.reply(200, {'success': true, 'data': {'id': 5, 'language': null}});
      });
      client.adapter.onPut('/api/user/language', (server) {
        server.reply(200, {'success': true});
      }, data: {'language': 'vi'});
      final applied = <Locale>[];

      await UserLanguageSync.adoptAccountLanguage(
        apiClient: client.apiClient,
        apply: (locale) async => applied.add(locale),
      );

      expect(applied, isEmpty);
      expect(UserLanguageSync.lastSynced, 'vi');
    });
  });
}
