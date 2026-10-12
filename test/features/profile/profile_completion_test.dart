import 'package:flutter/material.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_laundry_locker/features/auth/presentation/widgets/complete_profile_dialog.dart';
import 'package:smart_laundry_locker/features/profile/application/use_cases/get_profile_use_case.dart';
import 'package:smart_laundry_locker/features/profile/application/use_cases/update_profile_use_case.dart';
import 'package:smart_laundry_locker/features/profile/domain/entities/user_profile.dart';
import 'package:smart_laundry_locker/features/profile/domain/profile_completion.dart';
import 'package:smart_laundry_locker/features/profile/infrastructure/data_sources/profile_remote_data_source.dart';
import 'package:smart_laundry_locker/features/profile/infrastructure/repositories/profile_repository_impl.dart';
import 'package:smart_laundry_locker/features/profile/presentation/providers/profile_provider.dart';

import '../../helpers/test_helpers.dart';

UserProfile _profile(String fullName, {String email = ''}) => UserProfile(
  id: '7',
  fullName: fullName,
  email: email,
  phoneNumber: '+84912345678',
  status: UserStatus.ACTIVE,
  isVerified: true,
  isActive: true,
);

/// Tài khoản backend vừa tự tạo khi đăng nhập SĐT lần đầu.
class _FakeProfileDataSource implements ProfileRemoteDataSource {
  Map<String, dynamic>? lastUpdate;
  Map<String, dynamic> profile = {
    'id': '7',
    'fullName': 'User',
    'firstName': 'User',
    'lastName': '',
    'email': '',
    'phoneNumber': '+84912345678',
    'status': 'ACTIVE',
  };

  @override
  Future<Map<String, dynamic>> getProfile() async => profile;

  @override
  Future<Map<String, dynamic>> updateProfile({
    required Map<String, dynamic> data,
  }) async {
    lastUpdate = data;
    final first = data['firstName'] ?? profile['firstName'];
    final last = data['lastName'] ?? profile['lastName'];
    profile = {
      ...profile,
      'firstName': first,
      'lastName': last,
      'fullName': '$first $last'.trim(),
      if (data['email'] != null) 'email': data['email'],
    };
    return profile;
  }

  @override
  Future<dynamic> changePassword(Map<String, dynamic> body) async => null;

  @override
  Future<Map<String, dynamic>> deleteAvatar() async => profile;

  @override
  Future<bool> getFaceRegistrationStatus(String userId) async => false;

  @override
  Future<Map<String, dynamic>> uploadAvatar({
    required String userId,
    required String filePath,
  }) async => profile;
}

void main() {
  group('needsProfileCompletion', () {
    test('tên mặc định "User" (đăng nhập SĐT lần đầu) / "Customer" / rỗng ⇒ hỏi', () {
      expect(needsProfileCompletion(_profile('User')), isTrue);
      expect(needsProfileCompletion(_profile('user ')), isTrue);
      expect(needsProfileCompletion(_profile('Customer')), isTrue);
      expect(needsProfileCompletion(_profile('')), isTrue);
    });

    test('đã có tên thật hoặc chưa tải được hồ sơ ⇒ không hỏi', () {
      expect(needsProfileCompletion(_profile('Nguyễn Văn An')), isFalse);
      expect(needsProfileCompletion(null), isFalse);
    });
  });

  group('validators', () {
    test('họ tên bắt buộc, chỉ chữ cái, không được là tên mặc định', () {
      expect(validateCompletionFullName(''), isNotNull);
      expect(validateCompletionFullName('A'), isNotNull);
      expect(validateCompletionFullName('User'), isNotNull);
      expect(validateCompletionFullName('Nam 123'), isNotNull);
      expect(validateCompletionFullName('  Nguyễn   Thị Bình '), isNull);
    });

    test('email không bắt buộc nhưng nhập thì phải đúng dạng', () {
      expect(validateOptionalEmail(''), isNull);
      expect(validateOptionalEmail('  '), isNull);
      expect(validateOptionalEmail('an@example.com'), isNull);
      expect(validateOptionalEmail('an@'), isNotNull);
    });
  });

  group('CompleteProfileDialog', () {
    late _FakeProfileDataSource dataSource;
    late ProfileProvider provider;

    setUp(() {
      dataSource = _FakeProfileDataSource();
      final repository = ProfileRepositoryImpl(remoteDataSource: dataSource);
      provider = ProfileProvider(
        getProfileUseCase: GetProfileUseCase(repository),
        updateProfileUseCase: UpdateProfileUseCase(repository),
        apiClient: createMockApiClient().apiClient,
      );
    });

    Future<void> openDialog(WidgetTester tester, {bool askEmail = true}) async {
      await tester.pumpWidget(
        MaterialApp(
          builder: FlutterSmartDialog.init(),
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => showDialog<void>(
                  context: context,
                  builder: (_) => CompleteProfileDialog(
                    profileProvider: provider,
                    askEmail: askEmail,
                  ),
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(find.text('Hoàn tất đăng ký'), findsOneWidget);
    }

    testWidgets('lưu họ tên + email: tách firstName/lastName như lúc đăng ký', (
      tester,
    ) async {
      await openDialog(tester);

      await tester.enterText(find.byType(TextFormField).at(0), 'Nguyễn Văn An');
      await tester.enterText(find.byType(TextFormField).at(1), 'an@example.com');
      await tester.tap(find.text('Lưu'));
      await tester.pumpAndSettle();

      expect(dataSource.lastUpdate, {
        'firstName': 'Nguyễn Văn',
        'lastName': 'An',
        'email': 'an@example.com',
      });
      expect(find.text('Hoàn tất đăng ký'), findsNothing);
      expect(needsProfileCompletion(provider.profile), isFalse);

      // Chờ toast "Đã lưu…" tự đóng để không còn timer treo.
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
    });

    testWidgets('email để trống thì không gửi email', (tester) async {
      await openDialog(tester);

      await tester.enterText(find.byType(TextFormField).at(0), 'Minh');
      await tester.tap(find.text('Lưu'));
      await tester.pumpAndSettle();

      expect(dataSource.lastUpdate, {'firstName': 'Minh', 'lastName': ''});
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
    });

    testWidgets('tên không hợp lệ ⇒ báo lỗi, không gọi API', (tester) async {
      await openDialog(tester, askEmail: false);

      expect(find.byType(TextFormField), findsOneWidget);
      await tester.enterText(find.byType(TextFormField), 'User');
      await tester.tap(find.text('Lưu'));
      await tester.pumpAndSettle();

      expect(find.text('Vui lòng nhập tên thật của bạn'), findsOneWidget);
      expect(dataSource.lastUpdate, isNull);
    });

    testWidgets('"Để sau" đóng hộp thoại, hồ sơ giữ nguyên để lần sau hỏi lại', (
      tester,
    ) async {
      await openDialog(tester);

      await tester.tap(find.text('Để sau'));
      await tester.pumpAndSettle();

      expect(find.text('Hoàn tất đăng ký'), findsNothing);
      expect(dataSource.lastUpdate, isNull);
    });
  });
}
