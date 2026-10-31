class UserProfile {
  final String id;
  final String fullName;

  /// Phần tên backend lưu riêng (`GET /api/user/profile`). Backend cũ không trả
  /// ⇒ rỗng; form sửa hồ sơ tự tách lại từ [fullName].
  final String firstName;
  final String lastName;
  final String email;
  final String phoneNumber;
  final UserStatus status;
  final String? avatarUrl;
  final bool isVerified;
  final bool isActive;

  /// `false` = tài khoản Google/OTP chưa từng đặt mật khẩu ⇒ màn bảo mật cho
  /// "Đặt mật khẩu" không cần mật khẩu cũ. Backend không trả field này ⇒ coi
  /// như đã có mật khẩu (cùng mặc định với backend khi không đọc được).
  final bool hasPassword;

  /// `false` = chưa bấm "Đồng ý" Điều khoản dịch vụ (`termsAccepted` của `GET /api/user/profile`) ⇒ app hỏi
  /// trước khi dùng tiếp. Backend chưa có field này ⇒ coi như đã đồng ý để không chặn nhầm.
  final bool termsAccepted;

  const UserProfile({
    required this.id,
    required this.fullName,
    this.firstName = '',
    this.lastName = '',
    required this.email,
    required this.phoneNumber,
    required this.status,
    this.avatarUrl,
    required this.isVerified,
    required this.isActive,
    this.hasPassword = true,
    this.termsAccepted = true,
  });

  UserProfile copyWith({bool? termsAccepted}) => UserProfile(
    id: id,
    fullName: fullName,
    firstName: firstName,
    lastName: lastName,
    email: email,
    phoneNumber: phoneNumber,
    status: status,
    avatarUrl: avatarUrl,
    isVerified: isVerified,
    isActive: isActive,
    hasPassword: hasPassword,
    termsAccepted: termsAccepted ?? this.termsAccepted,
  );

  bool get canEdit => status != UserStatus.BLOCKED;

  bool get hasAvatar => avatarUrl != null && avatarUrl!.isNotEmpty;
}

enum UserStatus { ACTIVE, INACTIVE, BLOCKED }
