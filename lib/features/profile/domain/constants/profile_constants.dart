/// Profile-related constants for the Edit Profile feature.
class ProfileConstants {
  ProfileConstants._();

  /// List of available specialties shown in the profile form.
  static const List<String> specialties = <String>[
    'Môi giới bất động sản',
    'Tư vấn bất động sản',
    'Đầu tư bất động sản',
    'Định giá bất động sản',
    'Quản lý bất động sản',
    'Kiến trúc sư',
    'Kỹ sư xây dựng',
    'Thiết kế nội thất',
    'Phong thủy',
    'Luật sư bất động sản',
    'Marketing bất động sản',
    'Nhiếp ảnh bất động sản',
    'Khác',
  ];

  /// Language options (Vietnamese copy without diacritics for compatibility).
  static const List<String> languageOptionsVi = <String>[
    'Tiếng Việt',
    'English',
    'Tiếng Trung (Chinese)',
    'Tiếng Nhật (Japanese)',
    'Tiếng Hàn (Korean)',
    'Tiếng Pháp (French)',
    'Tiếng Đức (German)',
    'Tiếng Tây Ban Nha (Spanish)',
    'Tiếng Nga (Russian)',
    'Tiếng Thái (Thai)',
  ];

  /// User status options shared across roles.
  static const List<String> statusOptions = <String>[
    'Online',
    'Invisible',
    'Idle',
    'DoNotDisturb',
  ];

  /// Status labels shown to the user.
  static const Map<String, String> statusLabels = <String, String>{
    'Online': 'Trực tuyến',
    'Invisible': 'Ẩn',
    'Idle': 'Đang bận',
    'DoNotDisturb': 'Không làm phiền',
  };

  /// Validation constants.
  static const int minFullNameLength = 2;
  static const int maxFullNameLength = 50;
  static const int minUserNameLength = 3;
  static const int maxUserNameLength = 30;
  static const int maxAboutLength = 1000;
  static const int maxCompanyNameLength = 100;
  static const int maxCompletedDealsDescLength = 500;
  static const int minYearsExperience = 0;
  static const int maxYearsExperience = 50;
  static const int minAge = 18;
  static const int maxAge = 100;
  static const int vnPhoneLength = 10;
  static const int maxServiceLocations = 12;
  static const int otpCodeLength = 6;
  static const int otpCooldownSeconds = 60;

  /// VN Phone validation regex: starts with 0, exactly 10 digits.
  static final RegExp vnPhoneRegex = RegExp(r'^0\d{9}$');

  /// Full name validation regex: letters (any locale) and spaces only.
  static final RegExp fullNameRegex = RegExp(r'^[\p{L} ]+$', unicode: true);

  /// Date format for birthdate.
  static const String dateFormat = 'yyyy-MM-dd';

  /// Year range for birthdate selection (Admin/Saler).
  static const int minBirthYear = 1924;

  /// Get max birth year (current year - minAge).
  static int get maxBirthYear => DateTime.now().year - minAge;

  /// Get display label for status, fallback to raw value when missing.
  static String getStatusLabel(String status) {
    return statusLabels[status] ?? status;
  }

  /// Check if status is valid.
  static bool isValidStatus(String status) {
    return statusOptions.contains(status);
  }
}
