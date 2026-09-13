import 'package:flutter_test/flutter_test.dart';
import 'package:smart_laundry_locker/core/theme/shadcn_theme.dart';

void main() {
  test('uses navy brand palette', () {
    expect(AISLShadcnTheme.navyPrimary.value, 0xFF0A2342);
    expect(AISLShadcnTheme.navySecondary.value, 0xFF12355B);
    expect(AISLShadcnTheme.navyAccent.value, 0xFF1E5A8A);
  });
}
