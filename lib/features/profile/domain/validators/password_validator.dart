/// Password validation utility class
/// Follows the validation rules from Mobile_Change_Password_Implementation_Guide.md
class PasswordValidator {
  /// Special characters pattern for password validation
  static const String specialCharsPattern =
      r'[~!@#$%^&*()_\-=+\[{}\]\\|:;/?.,]';

  /// Minimum password length
  static const int minLength = 8;

  /// Check if password has minimum length
  static bool hasMinLength(String password) => password.length >= minLength;

  /// Check if password has at least one uppercase letter
  static bool hasUppercase(String password) =>
      RegExp(r'[A-Z]').hasMatch(password);

  /// Check if password has at least one lowercase letter
  static bool hasLowercase(String password) =>
      RegExp(r'[a-z]').hasMatch(password);

  /// Check if password has at least one number
  static bool hasNumber(String password) => RegExp(r'[0-9]').hasMatch(password);

  /// Check if password has at least one special character
  static bool hasSpecialChar(String password) =>
      RegExp(specialCharsPattern).hasMatch(password);

  /// Check if password meets all requirements
  static bool isValidPassword(String password) {
    return hasMinLength(password) &&
        hasUppercase(password) &&
        hasLowercase(password) &&
        hasNumber(password) &&
        hasSpecialChar(password);
  }

  /// Check if passwords match
  static bool passwordsMatch(String password, String confirmPassword) {
    return password == confirmPassword;
  }

  /// Get password strength level (0-4)
  /// 0 = No criteria met
  /// 1 = Weak (1 criteria)
  /// 2 = Medium (2 criteria)
  /// 3 = Strong (3 criteria)
  /// 4 = Very Strong (4+ criteria)
  static int getStrengthLevel(String password) {
    if (password.isEmpty) return 0;

    int score = 0;
    if (hasLowercase(password)) score++;
    if (hasUppercase(password)) score++;
    if (hasNumber(password)) score++;
    if (hasSpecialChar(password)) score++;

    return score;
  }

  /// Get strength label in Vietnamese
  static String getStrengthLabel(int level) {
    switch (level) {
      case 0:
        return 'Nhập mật khẩu';
      case 1:
        return 'Mật khẩu yếu';
      case 2:
        return 'Mật khẩu trung bình';
      case 3:
        return 'Mật khẩu mạnh';
      case 4:
        return 'Mật khẩu rất mạnh';
      default:
        return 'Nhập mật khẩu';
    }
  }

  /// Validate old password (required check only)
  static String? validateOldPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Vui lòng nhập mật khẩu hiện tại';
    }
    return null;
  }

  /// Validate new password with all requirements
  static String? validateNewPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Vui lòng nhập mật khẩu mới';
    }
    if (!hasMinLength(value)) {
      return 'Mật khẩu phải có ít nhất 8 ký tự';
    }
    if (!hasUppercase(value)) {
      return 'Mật khẩu phải có ít nhất 1 chữ cái viết hoa';
    }
    if (!hasLowercase(value)) {
      return 'Mật khẩu phải có ít nhất 1 chữ cái viết thường';
    }
    if (!hasNumber(value)) {
      return 'Mật khẩu phải có ít nhất 1 số';
    }
    if (!hasSpecialChar(value)) {
      return 'Mật khẩu phải có ít nhất 1 ký tự đặc biệt';
    }
    return null;
  }

  /// Validate confirm password
  static String? validateConfirmPassword(String? value, String newPassword) {
    if (value == null || value.isEmpty) {
      return 'Vui lòng xác nhận mật khẩu mới';
    }
    if (!passwordsMatch(newPassword, value)) {
      return 'Mật khẩu xác nhận không khớp';
    }
    return null;
  }

  /// Get list of password requirements status
  static List<PasswordRequirement> getRequirements(String password) {
    return [
      PasswordRequirement(
        text: 'Ít nhất 8 ký tự',
        isMet: hasMinLength(password),
      ),
      PasswordRequirement(
        text: 'Ít nhất 1 chữ viết hoa',
        isMet: hasUppercase(password),
      ),
      PasswordRequirement(
        text: 'Ít nhất 1 chữ viết thường',
        isMet: hasLowercase(password),
      ),
      PasswordRequirement(text: 'Ít nhất 1 số', isMet: hasNumber(password)),
      PasswordRequirement(
        text: 'Ít nhất 1 ký tự đặc biệt',
        isMet: hasSpecialChar(password),
      ),
    ];
  }
}

/// Password requirement model
class PasswordRequirement {
  const PasswordRequirement({required this.text, required this.isMet});

  final String text;
  final bool isMet;
}
