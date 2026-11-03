import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:smart_laundry_locker/core/l10n/l10n.dart';
import 'package:smart_laundry_locker/core/services/token_service.dart';
import 'package:smart_laundry_locker/features/profile/application/use_cases/get_profile_use_case.dart';
import 'package:smart_laundry_locker/features/profile/application/use_cases/update_profile_use_case.dart';
import 'package:smart_laundry_locker/features/profile/domain/account_reminders.dart';
import 'package:smart_laundry_locker/features/profile/domain/legal_document.dart';
import 'package:smart_laundry_locker/features/profile/domain/legal_text.dart';
import 'package:smart_laundry_locker/features/profile/infrastructure/data_sources/profile_remote_data_source.dart';
import 'package:smart_laundry_locker/features/profile/infrastructure/models/user_profile_model.dart';
import 'package:smart_laundry_locker/features/profile/infrastructure/repositories/profile_repository_impl.dart';
import 'package:smart_laundry_locker/features/profile/presentation/pages/policy_page.dart';
import 'package:smart_laundry_locker/features/profile/presentation/providers/profile_provider.dart';

import '../../helpers/test_helpers.dart';

LegalText _read(LegalDocument doc, Locale locale) =>
    LegalText.parse(File(doc.assetPath(locale)).readAsStringSync());

void main() {
  group('nội dung văn bản', () {
    for (final doc in LegalDocument.values) {
      test(
        '${doc.id}: bản Việt và bản Anh cùng số mục, mục đánh số liên tục, link chéo trỏ đúng văn bản',
        () {
          final vi = _read(doc, L10n.vi);
          final en = _read(doc, L10n.en);

          expect(vi.sections.length, en.sections.length);
          expect(vi.sections, isNotEmpty);
          for (var i = 0; i < vi.sections.length; i++) {
            expect(vi.sections[i].number, '${i + 1}');
            expect(en.sections[i].number, '${i + 1}');
            expect(vi.sections[i].body, isNotEmpty);
          }
          // Dòng phiên bản khớp ngày điều khoản app gửi lên khi đồng ý.
          final date = currentTermsVersion.split('-').reversed.join('/');
          expect(vi.meta, contains(date));
          expect(en.meta, contains(date));

          final other = LegalDocument.values.firstWhere((d) => d != doc);
          expect(vi.intro, contains('](${other.id})'));
          expect(en.intro, contains('](${other.id})'));
        },
      );
    }

    test('tách tiêu đề, dòng phiên bản, lời mở đầu và mục', () {
      final text = LegalText.parse(
        '# Tiêu đề\r\n\r\nPhiên bản 1\r\n\r\nMở đầu.\r\n\r\n## 1. Một\r\n\r\n- a\r\n\r\n## Hai\r\nb\r\n',
      );
      expect(text.title, 'Tiêu đề');
      expect(text.meta, 'Phiên bản 1');
      expect(text.intro, 'Mở đầu.');
      expect(text.sections.map((s) => '${s.number}|${s.title}|${s.body}'), [
        '1|Một|- a',
        '2|Hai|b',
      ]);
    });

    test('route cũ truyền map {assetPath} vẫn mở đúng văn bản', () {
      expect(
        LegalDocument.fromRouteExtra(LegalDocument.terms),
        LegalDocument.terms,
      );
      expect(
        LegalDocument.fromRouteExtra({
          'assetPath': 'assets/markdown/terms_of_service.md',
        }),
        LegalDocument.terms,
      );
      expect(LegalDocument.fromRouteExtra(null), LegalDocument.privacy);
    });

    test('thời điểm đồng ý đọc từ hồ sơ; dạng không phải chuỗi thì bỏ qua', () {
      final at = UserProfileModel.fromJson({
        'id': 7,
        'termsAccepted': true,
        'termsAcceptedAt': '2026-11-03T09:30:00',
      }).toEntity().termsAcceptedAt;
      expect(at, DateTime(2026, 11, 3, 9, 30));
      expect(
        UserProfileModel.fromJson({
          'id': 7,
          'termsAcceptedAt': [2026, 11, 3],
        }).toEntity().termsAcceptedAt,
        isNull,
      );
    });
  });

  group('PolicyPage', () {
    late ProfileProvider provider;
    late DioAdapter adapter;
    late _FakeDataSource source;

    setUp(() {
      // rootBundle giữ Future của lần tải trước (tạo trong vùng async của test trước) ⇒ test sau chờ mãi.
      rootBundle.clear();
      L10n.load(L10n.vi);
      final mock = createAuthenticatedApiClient(roles: const ['CUSTOMER']);
      adapter = mock.adapter;
      TokenService.authState.value = true;
      source = _FakeDataSource();
      final repository = ProfileRepositoryImpl(remoteDataSource: source);
      provider = ProfileProvider(
        getProfileUseCase: GetProfileUseCase(repository),
        updateProfileUseCase: UpdateProfileUseCase(repository),
        apiClient: mock.apiClient,
      );
    });

    tearDown(() => TokenService.authState.value = false);

    Future<void> open(WidgetTester tester, LegalDocument doc) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.6;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        ChangeNotifierProvider<ProfileProvider>.value(
          value: provider,
          child: MaterialApp(
            locale: L10n.vi,
            supportedLocales: L10n.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            builder: FlutterSmartDialog.init(),
            navigatorObservers: [FlutterSmartDialog.observer],
            home: PolicyPage(document: doc),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets(
      'khách chưa đồng ý: thấy "Bạn chưa đồng ý", tích rồi bấm Đồng ý ⇒ POST /api/user/terms',
      (tester) async {
        source.termsAccepted = false;
        adapter.onPost(
          '/api/user/terms',
          (server) => server.reply(200, {'success': true, 'data': {}}),
          data: {'version': currentTermsVersion},
        );
        await open(tester, LegalDocument.privacy);

        expect(
          find.byKey(const ValueKey('legal-consent-pending')),
          findsOneWidget,
        );
        final accept = find.byKey(const ValueKey('legal-consent-accept'));
        expect(tester.widget<FilledButton>(accept).onPressed, isNull);

        await tester.tap(find.byKey(const ValueKey('legal-consent-check')));
        await tester.pump();
        await tester.tap(accept);
        await tester.pumpAndSettle();

        expect(provider.profile!.termsAccepted, isTrue);
        expect(
          find.byKey(const ValueKey('legal-consent-accepted')),
          findsOneWidget,
        );
        expect(accept, findsNothing);
        // Chờ toast "Đã ghi nhận…" tự tắt để không còn timer treo.
        await tester.pump(const Duration(seconds: 5));
        await tester.pumpAndSettle();
      },
    );

    testWidgets(
      'khách đã đồng ý: không có thanh đồng ý; chuyển sang tab Điều khoản dịch vụ',
      (tester) async {
        source.termsAccepted = true;
        await open(tester, LegalDocument.privacy);

        expect(
          find.byKey(const ValueKey('legal-consent-accepted')),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey('legal-consent-accept')),
          findsNothing,
        );
        expect(find.text('Dữ liệu chúng tôi thu thập'), findsWidgets);

        await tester.tap(
          find.byKey(const ValueKey('legal-tab-terms_of_service')),
        );
        await tester.pumpAndSettle();
        expect(find.text('Hàng gửi'), findsWidgets);
      },
    );
  });
}

class _FakeDataSource extends Fake implements ProfileRemoteDataSource {
  bool termsAccepted = true;

  @override
  Future<Map<String, dynamic>> getProfile() async => {
    'id': 7,
    'fullName': 'Nguyễn Văn An',
    'email': 'an@example.com',
    'phoneNumber': '0901000002',
    'termsAccepted': termsAccepted,
    if (termsAccepted) 'termsAcceptedAt': '2026-11-03T09:30:00',
  };
}
