import 'package:flutter/material.dart';

/// App color constants following Material Design 3
class AppColors {
  // Primary Colors
  static const Color primary = Color(0xFFD32F2F); // Red
  static const Color primaryContainer = Color(0xFFFFDAD6);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color onPrimaryContainer = Color(0xFF410002);

  // Secondary Colors
  static const Color secondary = Color(0xFF775652);
  static const Color secondaryContainer = Color(0xFFFFDAD6);
  static const Color onSecondary = Color(0xFFFFFFFF);
  static const Color onSecondaryContainer = Color(0xFF2C1512);

  // Tertiary Colors
  static const Color tertiary = Color(0xFF6B5B2F);
  static const Color tertiaryContainer = Color(0xFFF4E0A6);
  static const Color onTertiary = Color(0xFFFFFFFF);
  static const Color onTertiaryContainer = Color(0xFF231B00);

  // Error Colors
  static const Color error = Color(0xFFBA1A1A);
  static const Color errorContainer = Color(0xFFFFDAD6);
  static const Color onError = Color(0xFFFFFFFF);
  static const Color onErrorContainer = Color(0xFF410002);

  // Background Colors
  static const Color background = Color(0xFFFFFBF9);
  static const Color onBackground = Color(0xFF201A18);
  static const Color surface = Color(0xFFFFFBF9);
  static const Color onSurface = Color(0xFF201A18);

  // Surface Variants
  static const Color surfaceVariant = Color(0xFFF4DDD9);
  static const Color onSurfaceVariant = Color(0xFF524341);
  static const Color outline = Color(0xFF857370);
  static const Color outlineVariant = Color(0xFFD8C2BE);

  // Shadow
  static const Color shadow = Color(0xFF000000);
  static const Color scrim = Color(0xFF000000);

  // Inverse Colors
  static const Color inverseSurface = Color(0xFF362F2D);
  static const Color onInverseSurface = Color(0xFFFBEEEC);
  static const Color inversePrimary = Color(0xFFFFB4AB);

  // Custom Colors
  static const Color success = Color(
    0xFFFF6600,
  ); // Orange - Primary theme color
  static const Color warning = Color(0xFFFF9800);
  static const Color info = Color(0xFF2196F3);

  // Neutral & Border Colors
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);
  static const Color grey50 = Color(0xFFFAFAFA);
  static const Color grey100 = Color(0xFFF5F5F5);
  static const Color grey200 = Color(0xFFEEEEEE);
  static const Color grey300 = Color(0xFFE0E0E0);
  static const Color grey400 = Color(0xFFBDBDBD);
  static const Color grey500 = Color(0xFF9E9E9E);
  static const Color grey600 = Color(0xFF757575);
  static const Color grey700 = Color(0xFF616161);
  static const Color grey800 = Color(0xFF424242);
  static const Color grey900 = Color(0xFF212121);

  // Convenient border color for inputs / cards
  static const Color border = grey200;

  // Property Status Colors
  static const Color forSale = Color(0xFF4CAF50);
  static const Color forRent = Color(0xFF2196F3);
  static const Color sold = Color(0xFF9E9E9E);
  static const Color rented = Color(0xFF9E9E9E);

  // Property Type Colors
  static const Color apartment = Color(0xFFE91E63);
  static const Color house = Color(0xFF9C27B0);
  static const Color villa = Color(0xFF673AB7);
  static const Color commercial = Color(0xFFFF9800);
  static const Color land = Color(0xFF4CAF50);
}
