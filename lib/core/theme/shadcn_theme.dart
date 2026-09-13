import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

/// Custom shadcn/ui theme configuration for Smart Laundry Locker.
class AISLShadcnTheme {
  static const Color navyPrimary = Color(0xFF0A2342);
  static const Color navySecondary = Color(0xFF12355B);
  static const Color navyAccent = Color(0xFF1E5A8A);
  static const Color navySurface = Color(0xFFF6F8FB);
  static const Color bluePrimary = navyAccent;

  /// Light theme configuration
  static ShadThemeData get lightTheme {
    return ShadThemeData(
      brightness: Brightness.light,
      colorScheme: const ShadColorScheme(
        primary: navyPrimary,
        primaryForeground: Color(0xFFFFFFFF),
        secondary: navySurface,
        secondaryForeground: navyPrimary,
        background: navySurface,
        foreground: Color(0xFF0F172A),
        muted: Color(0xFFEFF4F8),
        mutedForeground: Color(0xFF64748B),
        accent: Color(0xFFE7F0F8),
        accentForeground: navyPrimary,
        destructive: Color(0xFFEF4444),
        destructiveForeground: Color(0xFFFFFFFF),
        border: Color(0xFFE2E8F0),
        input: Color(0xFFE2E8F0),
        ring: navyAccent,
        card: Color(0xFFFFFFFF),
        cardForeground: Color(0xFF0F172A),
        popover: Color(0xFFFFFFFF),
        popoverForeground: Color(0xFF0F172A),
        selection: navyAccent,
      ),
      textTheme: ShadTextTheme(family: 'Manrope'),
      // Global button theme with rounded corners
      primaryButtonTheme: ShadButtonTheme(
        decoration: ShadDecoration(
          border: ShadBorder(
            radius: BorderRadius.circular(16), // Global button border radius
          ),
        ),
      ),
      // Apply same radius to all button variants
      secondaryButtonTheme: ShadButtonTheme(
        decoration: ShadDecoration(
          border: ShadBorder(radius: BorderRadius.circular(16)),
        ),
      ),
      destructiveButtonTheme: ShadButtonTheme(
        decoration: ShadDecoration(
          border: ShadBorder(radius: BorderRadius.circular(16)),
        ),
      ),
      outlineButtonTheme: ShadButtonTheme(
        decoration: ShadDecoration(
          border: ShadBorder(radius: BorderRadius.circular(16)),
        ),
      ),
      ghostButtonTheme: ShadButtonTheme(
        decoration: ShadDecoration(
          border: ShadBorder(radius: BorderRadius.circular(16)),
        ),
      ),
      // Global input theme with rounded corners
      inputTheme: ShadInputTheme(
        decoration: ShadDecoration(
          border: ShadBorder(
            radius: BorderRadius.circular(16), // Global input border radius
          ),
          focusedBorder: ShadBorder(radius: BorderRadius.circular(16)),
        ),
        // Consistent placeholder text size
        placeholderStyle: const TextStyle(
          fontSize: 16, // Same size as input text
          fontFamily: 'Manrope',
        ),
      ),
    );
  }

  /// Dark theme configuration
  static ShadThemeData get darkTheme {
    return ShadThemeData(
      brightness: Brightness.dark,
      colorScheme: const ShadColorScheme(
        primary: navyAccent,
        primaryForeground: Color(0xFFFFFFFF),
        secondary: Color(0xFF12355B),
        secondaryForeground: Color(0xFFFFFFFF),
        background: Color(0xFF061A30),
        foreground: Color(0xFFFFFFFF),
        muted: Color(0xFF0A2342),
        mutedForeground: Color(0xFFCBD5E1),
        accent: Color(0xFF12355B),
        accentForeground: Color(0xFFFFFFFF),
        destructive: Color(0xFFEF4444),
        destructiveForeground: Color(0xFFFFFFFF),
        border: Color(0xFF12355B),
        input: Color(0xFF12355B),
        ring: navyAccent,
        card: Color(0xFF0A2342),
        cardForeground: Color(0xFFFFFFFF),
        popover: Color(0xFF0A2342),
        popoverForeground: Color(0xFFFFFFFF),
        selection: navyAccent,
      ),
      textTheme: ShadTextTheme(family: 'Manrope'),
      // Global button theme with rounded corners
      primaryButtonTheme: ShadButtonTheme(
        decoration: ShadDecoration(
          border: ShadBorder(
            radius: BorderRadius.circular(16), // Global button border radius
          ),
        ),
      ),
      // Apply same radius to all button variants
      secondaryButtonTheme: ShadButtonTheme(
        decoration: ShadDecoration(
          border: ShadBorder(radius: BorderRadius.circular(16)),
        ),
      ),
      destructiveButtonTheme: ShadButtonTheme(
        decoration: ShadDecoration(
          border: ShadBorder(radius: BorderRadius.circular(16)),
        ),
      ),
      outlineButtonTheme: ShadButtonTheme(
        decoration: ShadDecoration(
          border: ShadBorder(radius: BorderRadius.circular(16)),
        ),
      ),
      ghostButtonTheme: ShadButtonTheme(
        decoration: ShadDecoration(
          border: ShadBorder(radius: BorderRadius.circular(16)),
        ),
      ),
      // Global input theme with rounded corners
      inputTheme: ShadInputTheme(
        decoration: ShadDecoration(
          border: ShadBorder(
            radius: BorderRadius.circular(16), // Global input border radius
          ),
          focusedBorder: ShadBorder(radius: BorderRadius.circular(16)),
        ),
        // Consistent placeholder text size
        placeholderStyle: const TextStyle(
          fontSize: 16, // Same size as input text
          fontFamily: 'Manrope',
        ),
      ),
    );
  }
}
