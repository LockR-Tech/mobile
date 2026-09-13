import 'package:smart_laundry_locker/features/profile/domain/constants/profile_constants.dart';

/// Validators for profile form fields.
class ProfileValidators {
  ProfileValidators._();

  /// Validates full name.
  static String? validateFullName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Ho va ten khong duoc de trong';
    }

    final trimmed = value.trim();

    if (trimmed.length < ProfileConstants.minFullNameLength) {
      return 'Ho va ten phai co it nhat ${ProfileConstants.minFullNameLength} ky tu';
    }

    if (trimmed.length > ProfileConstants.maxFullNameLength) {
      return 'Ho va ten khong duoc vuot qua ${ProfileConstants.maxFullNameLength} ky tu';
    }

    if (!ProfileConstants.fullNameRegex.hasMatch(trimmed)) {
      return 'Ho va ten chi duoc chua chu cai va khoang trang';
    }

    return null;
  }

  /// Validates user name.
  static String? validateUserName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Ten nguoi dung khong duoc de trong';
    }

    final trimmed = value.trim();

    if (trimmed.length < ProfileConstants.minUserNameLength) {
      return 'Ten nguoi dung phai co it nhat ${ProfileConstants.minUserNameLength} ky tu';
    }

    if (trimmed.length > ProfileConstants.maxUserNameLength) {
      return 'Ten nguoi dung khong duoc vuot qua ${ProfileConstants.maxUserNameLength} ky tu';
    }

    return null;
  }

  /// Validates email format.
  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // optional in most flows
    }

    final trimmed = value.trim();
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );

    if (!emailRegex.hasMatch(trimmed)) {
      return 'Email khong hop le';
    }

    return null;
  }

  /// Validates Vietnamese phone number.
  static String? validateVNPhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // optional in most flows
    }

    final trimmed = value.trim();

    if (trimmed.length != ProfileConstants.vnPhoneLength) {
      return 'So dien thoai phai co ${ProfileConstants.vnPhoneLength} chu so';
    }

    if (!ProfileConstants.vnPhoneRegex.hasMatch(trimmed)) {
      return 'So dien thoai khong hop le (bat dau bang 0 va chi chua chu so)';
    }

    return null;
  }

  /// Validates about/bio field.
  static String? validateAbout(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null;
    }

    if (value.length > ProfileConstants.maxAboutLength) {
      return 'Gioi thieu khong duoc vuot qua ${ProfileConstants.maxAboutLength} ky tu';
    }

    return null;
  }

  /// Validates company name.
  static String? validateCompanyName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null;
    }

    if (value.length > ProfileConstants.maxCompanyNameLength) {
      return 'Ten cong ty khong duoc vuot qua ${ProfileConstants.maxCompanyNameLength} ky tu';
    }

    return null;
  }

  /// Validates years of experience.
  static String? validateYearsOfExperience(int? value) {
    if (value == null) {
      return null;
    }

    if (value < ProfileConstants.minYearsExperience) {
      return 'So nam kinh nghiem khong duoc nho hon ${ProfileConstants.minYearsExperience}';
    }

    if (value > ProfileConstants.maxYearsExperience) {
      return 'So nam kinh nghiem khong duoc vuot qua ${ProfileConstants.maxYearsExperience}';
    }

    return null;
  }

  /// Validates birthdate.
  static String? validateBirthdate(DateTime? value) {
    if (value == null) {
      return null;
    }

    final now = DateTime.now();

    if (value.isAfter(now)) {
      return 'Ngay sinh khong duoc lon hon hien tai';
    }

    final age = _calculateAge(value);

    if (age < ProfileConstants.minAge) {
      return 'Ban phai tu ${ProfileConstants.minAge} tuoi tro len';
    }

    if (age > ProfileConstants.maxAge) {
      return 'Tuoi khong duoc vuot qua ${ProfileConstants.maxAge}';
    }

    return null;
  }

  /// Validates birthdate string (YYYY-MM-DD format).
  static String? validateBirthdateString(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null;
    }

    try {
      final date = DateTime.parse(value);
      return validateBirthdate(date);
    } catch (_) {
      return 'Dinh dang ngay sinh khong hop le (YYYY-MM-DD)';
    }
  }

  /// Validates OTP code.
  static String? validateOTPCode(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Ma OTP khong duoc de trong';
    }

    final trimmed = value.trim();

    if (trimmed.length != ProfileConstants.otpCodeLength) {
      return 'Ma OTP phai co ${ProfileConstants.otpCodeLength} chu so';
    }

    if (!RegExp(r'^\d{6}$').hasMatch(trimmed)) {
      return 'Ma OTP chi duoc chua chu so';
    }

    return null;
  }

  /// Validates service locations count.
  static String? validateServiceLocationsCount(List<dynamic>? value) {
    if (value == null || value.isEmpty) {
      return null;
    }

    if (value.length > ProfileConstants.maxServiceLocations) {
      return 'Chi duoc chon toi da ${ProfileConstants.maxServiceLocations} khu vuc';
    }

    return null;
  }

  /// Calculate age from birthdate.
  static int _calculateAge(DateTime birthdate) {
    final now = DateTime.now();
    var age = now.year - birthdate.year;

    if (now.month < birthdate.month ||
        (now.month == birthdate.month && now.day < birthdate.day)) {
      age--;
    }

    return age;
  }

  /// Check if phone number is valid VN format.
  static bool isValidVNPhone(String? phone) {
    if (phone == null || phone.trim().isEmpty) {
      return false;
    }
    return ProfileConstants.vnPhoneRegex.hasMatch(phone.trim());
  }

  /// Check if email is valid.
  static bool isValidEmail(String? email) {
    if (email == null || email.trim().isEmpty) {
      return false;
    }
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegex.hasMatch(email.trim());
  }
}
