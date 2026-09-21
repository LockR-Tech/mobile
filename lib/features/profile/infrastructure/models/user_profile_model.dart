import 'package:smart_laundry_locker/features/profile/domain/entities/user_profile.dart';
import 'package:json_annotation/json_annotation.dart';

part 'user_profile_model.g.dart';

@JsonSerializable()
class UserProfileModel {
  final String? id;
  final String? fullName;
  final String? email;
  final String? phoneNumber;
  final String? status;
  final String? avatarUrl;
  final bool? isVerified;
  final bool? isActive;

  const UserProfileModel({
    this.id,
    this.fullName,
    this.email,
    this.phoneNumber,
    this.status,
    this.avatarUrl,
    this.isVerified,
    this.isActive,
  });

  factory UserProfileModel.fromJson(Map<String, dynamic> json) {
    final avatar =
        json['avatarUrl'] ?? json['imageUrl'] ?? json['image_url'] ?? json['avatar'];
    final normalized = Map<String, dynamic>.from(json);
    if (avatar != null && avatar.toString().isNotEmpty) {
      normalized['avatarUrl'] = avatar.toString();
    }
    if ((normalized['fullName'] == null ||
            normalized['fullName'].toString().trim().isEmpty) &&
        json['name'] != null) {
      normalized['fullName'] = json['name'].toString();
    }
    if ((normalized['fullName'] == null ||
            normalized['fullName'].toString().trim().isEmpty) &&
        json['username'] != null) {
      normalized['fullName'] = json['username'].toString();
    }
    return _$UserProfileModelFromJson(normalized);
  }

  Map<String, dynamic> toJson() => _$UserProfileModelToJson(this);

  UserProfile toEntity() {
    return UserProfile(
      id: id ?? '',
      fullName: fullName ?? 'Người dùng',
      email: email ?? '',
      phoneNumber: phoneNumber ?? '',
      status: _parseStatus(status ?? 'INACTIVE'),
      avatarUrl: avatarUrl,
      isVerified: isVerified ?? false,
      isActive: isActive ?? false,
    );
  }

  UserStatus _parseStatus(String statusString) {
    switch (statusString.toUpperCase()) {
      case 'ACTIVE':
        return UserStatus.ACTIVE;
      case 'INACTIVE':
        return UserStatus.INACTIVE;
      case 'BLOCKED':
        return UserStatus.BLOCKED;
      default:
        return UserStatus.INACTIVE;
    }
  }
}
