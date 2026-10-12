/// Tách/ghép họ tên theo đúng cách backend lưu.
///
/// user-service lưu `firstName` + `lastName` và ghép lại thành
/// `fullName = "$firstName $lastName"`. Lúc đăng ký app tách ô "Họ và tên":
/// từ cuối cùng là `lastName`, phần còn lại là `firstName`
/// ("Nguyễn Văn An" → firstName "Nguyễn Văn", lastName "An"), nên ghép lại vẫn
/// ra đúng chuỗi người dùng nhập. Sửa hồ sơ phải tách giống hệt — trước đây app
/// gửi `fullName` mà backend bỏ qua nên đổi tên không bao giờ lưu.
class PersonName {
  final String firstName;
  final String lastName;

  const PersonName({required this.firstName, required this.lastName});

  /// `"$firstName $lastName"` đã bỏ khoảng trắng thừa — khớp `fullName` backend trả.
  String get fullName => '$firstName $lastName'.trim();

  @override
  bool operator ==(Object other) =>
      other is PersonName &&
      other.firstName == firstName &&
      other.lastName == lastName;

  @override
  int get hashCode => Object.hash(firstName, lastName);

  @override
  String toString() => 'PersonName($firstName | $lastName)';
}

/// Tách "Họ và tên" thành `firstName`/`lastName` như lúc đăng ký.
///
/// Một từ ⇒ `firstName` là từ đó, `lastName` rỗng (gửi rỗng để xoá tên cũ).
PersonName splitFullName(String fullName) {
  final normalized = fullName.trim().replaceAll(RegExp(r'\s+'), ' ');
  if (normalized.isEmpty) {
    return const PersonName(firstName: '', lastName: '');
  }
  final parts = normalized.split(' ');
  if (parts.length == 1) {
    return PersonName(firstName: parts.first, lastName: '');
  }
  final lastName = parts.removeLast();
  return PersonName(firstName: parts.join(' '), lastName: lastName);
}

/// Tên mặc định backend đặt cho tài khoản tạo nhanh (đăng nhập OTP email,
/// đăng ký nhanh ở kiosk, đăng nhập SĐT/Firebase lần đầu = "User") khi người
/// dùng chưa nhập tên.
const _placeholderNames = {'customer', 'khach', 'khách', 'người dùng', 'user'};

/// `true` khi tên chỉ là tên mặc định — form sửa hồ sơ để trống ô tên thay vì
/// điền sẵn "Customer" để người dùng nhập tên thật.
bool isPlaceholderName(String? fullName) {
  final value = (fullName ?? '').trim().toLowerCase();
  return value.isEmpty || _placeholderNames.contains(value);
}
