import 'package:flutter_test/flutter_test.dart';
import 'package:smart_laundry_locker/core/network/api_client.dart';
import 'package:smart_laundry_locker/features/profile/application/use_cases/change_password_use_case.dart';
import 'package:smart_laundry_locker/features/profile/application/use_cases/get_profile_use_case.dart';
import 'package:smart_laundry_locker/features/profile/domain/password_change.dart';
import 'package:smart_laundry_locker/features/profile/infrastructure/data_sources/profile_remote_data_source.dart';
import 'package:smart_laundry_locker/features/profile/infrastructure/repositories/profile_repository_impl.dart';
import 'package:smart_laundry_locker/features/profile/presentation/providers/security_provider.dart';

class _FakeDataSource implements ProfileRemoteDataSource {
  _FakeDataSource({
    required this.hasPassword,
    this.passwordResponse,
    this.passwordError,
  });

  final bool hasPassword;
  final dynamic passwordResponse;
  final Exception? passwordError;
  final List<Map<String, dynamic>> passwordCalls = [];

  @override
  Future<Map<String, dynamic>> getProfile() async => {
    'id': '7',
    'fullName': 'Khách',
    'status': 'ACTIVE',
    'hasPassword': hasPassword,
  };

  @override
  Future<dynamic> changePassword(Map<String, dynamic> body) async {
    passwordCalls.add(body);
    if (passwordError != null) throw passwordError!;
    return passwordResponse;
  }

  @override
  Future<Map<String, dynamic>> updateProfile({
    required Map<String, dynamic> data,
  }) async => {};

  @override
  Future<Map<String, dynamic>> deleteAvatar() async => {};

  @override
  Future<bool> getFaceRegistrationStatus(String userId) async => false;

  @override
  Future<Map<String, dynamic>> uploadAvatar({
    required String userId,
    required String filePath,
  }) async => {};
}

SecurityProvider _provider(
  _FakeDataSource ds,
  List<(String, String)> savedTokens,
) {
  final repo = ProfileRepositoryImpl(remoteDataSource: ds);
  return SecurityProvider(
    getProfileUseCase: GetProfileUseCase(repo),
    changePasswordUseCase: ChangePasswordUseCase(repo),
    saveTokens: (access, refresh) async => savedTokens.add((access, refresh)),
  );
}

void main() {
  group('quyết định form', () {
    test('có mật khẩu ⇒ đổi mật khẩu; chưa có ⇒ đặt mật khẩu', () {
      expect(passwordFormModeFor(hasPassword: true), PasswordFormMode.change);
      expect(passwordFormModeFor(hasPassword: false), PasswordFormMode.set);
    });

    test('body chỉ kèm currentPassword khi đổi, mật khẩu được trim', () {
      expect(
        buildPasswordChangeBody(
          mode: PasswordFormMode.change,
          currentPassword: ' old123 ',
          newPassword: ' new456 ',
        ),
        {'currentPassword': 'old123', 'newPassword': 'new456'},
      );
      expect(
        buildPasswordChangeBody(
          mode: PasswordFormMode.set,
          currentPassword: 'ignored',
          newPassword: 'new456',
        ),
        {'newPassword': 'new456'},
      );
    });

    test('kiểm tra form', () {
      expect(
        validatePasswordForm(
          mode: PasswordFormMode.change,
          currentPassword: '',
          newPassword: 'abcdef',
          confirmPassword: 'abcdef',
        ),
        'Vui lòng nhập mật khẩu hiện tại',
      );
      expect(
        validatePasswordForm(
          mode: PasswordFormMode.set,
          newPassword: 'abc',
          confirmPassword: 'abc',
        ),
        contains('ít nhất'),
      );
      expect(
        validatePasswordForm(
          mode: PasswordFormMode.change,
          currentPassword: 'abcdef',
          newPassword: 'abcdef',
          confirmPassword: 'abcdef',
        ),
        contains('trùng'),
      );
      expect(
        validatePasswordForm(
          mode: PasswordFormMode.set,
          newPassword: 'abcdef',
          confirmPassword: 'abcdeg',
        ),
        contains('chưa khớp'),
      );
      expect(
        validatePasswordForm(
          mode: PasswordFormMode.set,
          newPassword: 'abcdef',
          confirmPassword: ' abcdef ',
        ),
        isNull,
      );
    });

    test('đọc cặp token mới từ response', () {
      final result = PasswordChangeResult.fromResponse({
        'success': true,
        'code': 'PASSWORD_CHANGED',
        'data': {'accessToken': 'a1', 'refreshToken': 'r1'},
      });
      expect(result.hasTokens, isTrue);
      expect(result.accessToken, 'a1');
      expect(PasswordChangeResult.fromResponse({'success': true}).hasTokens, isFalse);
      expect(PasswordChangeResult.fromResponse(null).hasTokens, isFalse);
    });
  });

  group('SecurityProvider', () {
    test('có mật khẩu: một lời gọi kèm currentPassword và lưu token mới', () async {
      final ds = _FakeDataSource(
        hasPassword: true,
        passwordResponse: {
          'success': true,
          'data': {'accessToken': 'new-access', 'refreshToken': 'new-refresh'},
        },
      );
      final saved = <(String, String)>[];
      final provider = _provider(ds, saved);

      await provider.loadPasswordState();
      expect(provider.mode, PasswordFormMode.change);

      final ok = await provider.submit(
        currentPassword: 'old123',
        newPassword: 'new456',
        confirmPassword: 'new456',
      );

      expect(ok, isTrue);
      expect(ds.passwordCalls, [
        {'currentPassword': 'old123', 'newPassword': 'new456'},
      ]);
      expect(saved, [('new-access', 'new-refresh')]);
    });

    test('chưa có mật khẩu: đặt mật khẩu không gửi currentPassword', () async {
      final ds = _FakeDataSource(hasPassword: false, passwordResponse: {'success': true});
      final saved = <(String, String)>[];
      final provider = _provider(ds, saved);

      await provider.loadPasswordState();
      expect(provider.mode, PasswordFormMode.set);

      final ok = await provider.submit(
        newPassword: 'new456',
        confirmPassword: 'new456',
      );

      expect(ok, isTrue);
      expect(ds.passwordCalls.single.containsKey('currentPassword'), isFalse);
      // Backend cũ không trả token ⇒ không lưu gì, không bịa token.
      expect(saved, isEmpty);
      // Đã đặt xong ⇒ lần sau là đổi mật khẩu.
      expect(provider.mode, PasswordFormMode.change);
    });

    test('sai mật khẩu hiện tại ⇒ báo lỗi, không lưu token', () async {
      final ds = _FakeDataSource(
        hasPassword: true,
        passwordError: ValidationException('Mật khẩu hiện tại không đúng'),
      );
      final saved = <(String, String)>[];
      final provider = _provider(ds, saved);
      await provider.loadPasswordState();

      final ok = await provider.submit(
        currentPassword: 'wrong1',
        newPassword: 'new456',
        confirmPassword: 'new456',
      );

      expect(ok, isFalse);
      expect(provider.error, 'Mật khẩu hiện tại không đúng');
      expect(saved, isEmpty);
    });

    test('form sai thì không gọi API', () async {
      final ds = _FakeDataSource(hasPassword: true);
      final provider = _provider(ds, []);
      await provider.loadPasswordState();

      final ok = await provider.submit(
        currentPassword: 'old123',
        newPassword: 'new456',
        confirmPassword: 'khac',
      );

      expect(ok, isFalse);
      expect(ds.passwordCalls, isEmpty);
    });

    test('backend chưa có endpoint (404) ⇒ thông báo rõ, không báo thành công', () async {
      final ds = _FakeDataSource(
        hasPassword: true,
        passwordError: NotFoundException('Not Found'),
      );
      final provider = _provider(ds, []);
      await provider.loadPasswordState();

      final ok = await provider.submit(
        currentPassword: 'old123',
        newPassword: 'new456',
        confirmPassword: 'new456',
      );

      expect(ok, isFalse);
      expect(provider.error, contains('chưa hỗ trợ'));
    });
  });
}
