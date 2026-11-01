import 'package:smart_laundry_locker/core/l10n/l10n.dart';
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
        return L10n.current.pwStrengthEnter;
      case 1:
        return L10n.current.pwStrengthWeak;
      case 2:
        return L10n.current.pwStrengthMedium;
      case 3:
        return L10n.current.pwStrengthStrong;
      case 4:
        return L10n.current.pwStrengthVeryStrong;
      default:
        return L10n.current.pwStrengthEnter;
    }
  }

  /// Validate old password (required check only)
  static String? validateOldPassword(String? value) {
    if (value == null || value.isEmpty) {
      return L10n.current.pwEnterCurrent;
    }
    return null;
  }

  /// Validate new password with all requirements
  static String? validateNewPassword(String? value) {
    if (value == null || value.isEmpty) {
      return L10n.current.pwEnterNew;
    }
    if (!hasMinLength(value)) {
      return L10n.current.pwMin8;
    }
    if (!hasUppercase(value)) {
      return L10n.current.pwNeedUpper;
    }
    if (!hasLowercase(value)) {
      return L10n.current.pwNeedLower;
    }
    if (!hasNumber(value)) {
      return L10n.current.pwNeedNumber;
    }
    if (!hasSpecialChar(value)) {
      return L10n.current.pwNeedSpecial;
    }
    return null;
  }

  /// Validate confirm password
  static String? validateConfirmPassword(String? value, String newPassword) {
    if (value == null || value.isEmpty) {
      return L10n.current.pwConfirmNew;
    }
    if (!passwordsMatch(newPassword, value)) {
      return L10n.current.pwConfirmNotMatch;
    }
    return null;
  }

  /// Get list of password requirements status
  static List<PasswordRequirement> getRequirements(String password) {
    return [
      PasswordRequirement(
        text: L10n.current.pwReq8,
        isMet: hasMinLength(password),
      ),
      PasswordRequirement(
        text: L10n.current.pwReqUpper,
        isMet: hasUppercase(password),
      ),
      PasswordRequirement(
        text: L10n.current.pwReqLower,
        isMet: hasLowercase(password),
      ),
      PasswordRequirement(text: L10n.current.pwReqNumber, isMet: hasNumber(password)),
      PasswordRequirement(
        text: L10n.current.pwReqSpecial,
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
