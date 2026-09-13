class UserProfile {
  final String id;
  final String fullName;
  final String email;
  final String phoneNumber;
  final UserStatus status;
  final String? avatarUrl;
  final bool isVerified;
  final bool isActive;

  const UserProfile({
    required this.id,
    required this.fullName,
    required this.email,
    required this.phoneNumber,
    required this.status,
    this.avatarUrl,
    required this.isVerified,
    required this.isActive,
  });

  bool get canEdit => status != UserStatus.BLOCKED;

  bool get hasAvatar => avatarUrl != null && avatarUrl!.isNotEmpty;
}

enum UserStatus { ACTIVE, INACTIVE, BLOCKED }
