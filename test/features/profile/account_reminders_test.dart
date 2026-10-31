import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_laundry_locker/features/profile/application/use_cases/get_profile_use_case.dart';
import 'package:smart_laundry_locker/features/profile/application/use_cases/update_profile_use_case.dart';
import 'package:smart_laundry_locker/features/profile/domain/account_reminders.dart';
import 'package:smart_laundry_locker/features/profile/domain/entities/user_profile.dart';
import 'package:smart_laundry_locker/features/profile/infrastructure/data_sources/profile_remote_data_source.dart';
import 'package:smart_laundry_locker/features/profile/infrastructure/models/user_profile_model.dart';
import 'package:smart_laundry_locker/features/profile/infrastructure/repositories/profile_repository_impl.dart';
import 'package:smart_laundry_locker/features/profile/presentation/providers/profile_provider.dart';
import 'package:smart_laundry_locker/features/profile/presentation/widgets/profile_reminder_sheet.dart';
import 'package:smart_laundry_locker/features/profile/presentation/widgets/terms_consent_dialog.dart';

import '../../helpers/test_helpers.dart';

UserProfile _profile({String email = '', String phone = '', bool terms = true}) => UserProfile(
  id: '7',
  fullName: 'Nguyễn Văn An',
  email: email,
  phoneNumber: phone,
  status: UserStatus.ACTIVE,
  isVerified: true,
  isActive: true,
  termsAccepted: terms,
);

void main() {
  group('luật nhắc', () {
    test('đăng ký bằng SĐT (chưa có email) ⇒ nhắc email; đủ cả hai ⇒ không nhắc', () {
      expect(missingContactFields(_profile(phone: '0901000002')), ['email']);
      expect(missingContactFields(_profile(email: 'an@example.com')), ['số điện thoại']);
      expect(missingContactFields(_profile()), ['email', 'số điện thoại']);
      expect(missingContactFields(_profile(email: 'an@example.com', phone: '0901000002')), isEmpty);
      expect(missingContactSentence(['email', 'số điện thoại']),
          'Tài khoản của bạn chưa có email và số điện thoại.');
    });

    test('lần đầu (chưa hoãn) nhắc ngay; còn trong hạn hoãn thì chưa nhắc lại', () {
      final now = DateTime(2026, 10, 31, 9);
      expect(reminderDue(null, now), isTrue);
      expect(reminderDue(now.add(reminderSnooze), now), isFalse);
      expect(reminderDue(now.subtract(const Duration(minutes: 1)), now), isTrue);
    });

    test('chưa đồng ý điều khoản ⇒ hỏi; backend cũ không trả field ⇒ coi như đã đồng ý', () {
      expect(needsTermsConsent(_profile(terms: false)), isTrue);
      expect(needsTermsConsent(_profile()), isFalse);
      expect(const UserProfileModel(id: '7').toEntity().termsAccepted, isTrue);
      expect(UserProfileModel.fromJson({'id': 7, 'termsAccepted': false}).toEntity().termsAccepted, isFalse);
    });
  });

  group('TermsConsentDialog', () {
    late ProfileProvider provider;
    late DioAdapter adapter;
    bool? result;
    var signedOut = false;

    setUp(() {
      final mock = createMockApiClient();
      adapter = mock.adapter;
      final repository = ProfileRepositoryImpl(remoteDataSource: _NoopDataSource());
      provider = ProfileProvider(
        getProfileUseCase: GetProfileUseCase(repository),
        updateProfileUseCase: UpdateProfileUseCase(repository),
        apiClient: mock.apiClient,
      );
      result = null;
      signedOut = false;
    });

    Future<void> open(WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () async => result = await TermsConsentDialog.show(
                  context,
                  profileProvider: provider,
                  onSignOut: () async => signedOut = true,
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
    }

    testWidgets('phải tích ô đồng ý mới bấm được; đồng ý ⇒ POST /api/user/terms kèm phiên bản', (tester) async {
      // Body khác {'version': currentTermsVersion} thì adapter không khớp ⇒ lưu lỗi ⇒ test hỏng.
      adapter.onPost(
        '/api/user/terms',
        (server) => server.reply(200, {'success': true, 'data': {}}),
        data: {'version': currentTermsVersion},
      );
      await open(tester);

      final accept = find.byKey(const ValueKey('terms-consent-accept'));
      expect(tester.widget<ElevatedButton>(accept).onPressed, isNull);

      await tester.tap(find.byKey(const ValueKey('terms-consent-check')));
      await tester.pump();
      expect(tester.widget<ElevatedButton>(accept).onPressed, isNotNull);

      await tester.tap(accept);
      await tester.pumpAndSettle();
      expect(result, isTrue);
      expect(find.byKey(const ValueKey('terms-consent-dialog')), findsNothing);
    });

    testWidgets('không đóng được bằng nút quay lại; chọn đăng xuất ⇒ trả false', (tester) async {
      await open(tester);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('terms-consent-dialog')), findsOneWidget);

      await tester.tap(find.text('Đăng xuất'));
      await tester.pumpAndSettle();
      expect(result, isFalse);
      expect(signedOut, isTrue);
    });

    testWidgets('lưu lỗi ⇒ báo lỗi, hộp thoại vẫn mở', (tester) async {
      adapter.onPost('/api/user/terms', (server) => server.reply(500, {'success': false}),
          data: Matchers.any);
      await open(tester);

      await tester.tap(find.byKey(const ValueKey('terms-consent-check')));
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('terms-consent-accept')));
      await tester.pumpAndSettle();

      expect(find.text('Chưa lưu được. Kiểm tra mạng rồi thử lại.'), findsOneWidget);
      expect(find.byKey(const ValueKey('terms-consent-dialog')), findsOneWidget);
    });
  });

  testWidgets('ProfileReminderSheet: nêu đúng thông tin thiếu, "Để sau" trả later', (tester) async {
    ProfileReminderChoice? choice;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async => choice = await ProfileReminderSheet.show(context, const ['email']),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Tài khoản của bạn chưa có email.'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('profile-reminder-later')));
    await tester.pumpAndSettle();
    expect(choice, ProfileReminderChoice.later);
  });
}

class _NoopDataSource extends Fake implements ProfileRemoteDataSource {}
