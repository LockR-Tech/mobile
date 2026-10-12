import 'package:flutter_test/flutter_test.dart';
import 'package:smart_laundry_locker/core/network/api_client.dart';
import 'package:smart_laundry_locker/features/profile/domain/utils/person_name.dart';
import 'package:smart_laundry_locker/features/profile/infrastructure/data_sources/profile_remote_data_source.dart';
import 'package:smart_laundry_locker/features/profile/infrastructure/models/user_profile_model.dart';
import 'package:smart_laundry_locker/features/profile/infrastructure/repositories/profile_repository_impl.dart';

class _FakeProfileDataSource implements ProfileRemoteDataSource {
  _FakeProfileDataSource({this.updateError});

  final Exception? updateError;
  Map<String, dynamic>? lastUpdate;
  Map<String, dynamic> profile = {
    'id': '5',
    'fullName': 'Nguyễn Văn An',
    'firstName': 'Nguyễn Văn',
    'lastName': 'An',
    'email': 'an@example.com',
    'phoneNumber': '0901234567',
    'status': 'ACTIVE',
    'hasPassword': false,
  };

  @override
  Future<Map<String, dynamic>> getProfile() async => profile;

  @override
  Future<Map<String, dynamic>> updateProfile({
    required Map<String, dynamic> data,
  }) async {
    lastUpdate = data;
    if (updateError != null) throw updateError!;
    return {'id': '5', 'fullName': 'x', 'status': 'ACTIVE'};
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
  group('splitFullName — giống cách tách lúc đăng ký', () {
    test('từ cuối là lastName, phần còn lại là firstName', () {
      expect(
        splitFullName('Nguyễn Văn An'),
        const PersonName(firstName: 'Nguyễn Văn', lastName: 'An'),
      );
      expect(splitFullName('Nguyễn Văn An').fullName, 'Nguyễn Văn An');
    });

    test('gộp khoảng trắng thừa', () {
      expect(
        splitFullName('  Trần   Thị  Bình '),
        const PersonName(firstName: 'Trần Thị', lastName: 'Bình'),
      );
    });

    test('một từ ⇒ lastName rỗng (xoá họ cũ)', () {
      expect(
        splitFullName('Minh'),
        const PersonName(firstName: 'Minh', lastName: ''),
      );
    });

    test('rỗng ⇒ cả hai rỗng', () {
      expect(splitFullName('   '), const PersonName(firstName: '', lastName: ''));
    });
  });

  test('tên mặc định của tài khoản OTP không được coi là tên thật', () {
    expect(isPlaceholderName('Customer'), isTrue);
    expect(isPlaceholderName(' khach '), isTrue);
    expect(isPlaceholderName(''), isTrue);
    expect(isPlaceholderName('Nguyễn Văn An'), isFalse);
  });

  group('buildProfileUpdateBody', () {
    test('gửi firstName/lastName thay vì fullName', () {
      final body = buildProfileUpdateBody(fullName: 'Lê Hoàng Nam');
      expect(body, {'firstName': 'Lê Hoàng', 'lastName': 'Nam'});
      expect(body.containsKey('fullName'), isFalse);
    });

    test('chỉ gửi định danh có giá trị', () {
      final body = buildProfileUpdateBody(
        fullName: 'Nam',
        phoneNumber: ' 0909000111 ',
        email: '',
      );
      expect(body, {'firstName': 'Nam', 'lastName': '', 'phoneNumber': '0909000111'});
    });
  });

  test('UserProfileModel đọc hasPassword/firstName/lastName, thiếu thì mặc định', () {
    final withFields = UserProfileModel.fromJson({
      'id': 5,
      'fullName': 'Nguyễn Văn An',
      'firstName': 'Nguyễn Văn',
      'lastName': 'An',
      'hasPassword': false,
    }).toEntity();
    expect(withFields.id, '5');
    expect(withFields.hasPassword, isFalse);
    expect(withFields.lastName, 'An');

    final legacy = UserProfileModel.fromJson({'id': 1, 'fullName': 'A'}).toEntity();
    expect(legacy.hasPassword, isTrue);
    expect(legacy.firstName, '');
  });

  group('ProfileRepositoryImpl.updateProfile', () {
    test('lưu tên bằng firstName/lastName rồi đọc lại hồ sơ đầy đủ', () async {
      final ds = _FakeProfileDataSource();
      final repo = ProfileRepositoryImpl(remoteDataSource: ds);

      final result = await repo.updateProfile(fullName: 'Nguyễn Văn An');

      expect(ds.lastUpdate, {'firstName': 'Nguyễn Văn', 'lastName': 'An'});
      final profile = result.getOrElse(() => throw StateError('expected Right'));
      expect(profile.hasPassword, isFalse);
      expect(profile.email, 'an@example.com');
    });

    test('SĐT trùng tài khoản khác ⇒ hiện đúng thông báo backend', () async {
      final ds = _FakeProfileDataSource(
        updateError: ValidationException(
          'Số điện thoại đã được dùng cho người dùng khác: 0909000111',
        ),
      );
      final repo = ProfileRepositoryImpl(remoteDataSource: ds);

      final result = await repo.updateProfile(phoneNumber: '0909000111');

      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) => expect(
          failure.message,
          'Số điện thoại đã được dùng cho người dùng khác: 0909000111',
        ),
        (_) => fail('expected Left'),
      );
    });

    test('mã lỗi trần ⇒ thông báo tiếng Việt', () async {
      final ds = _FakeProfileDataSource(
        updateError: ValidationException('AUTH_EMAIL_TAKEN'),
      );
      final repo = ProfileRepositoryImpl(remoteDataSource: ds);

      final result = await repo.updateProfile(email: 'a@b.vn');

      expect(
        result.fold((f) => f.message, (_) => ''),
        'Email này đã được dùng cho tài khoản khác',
      );
    });
  });
}
