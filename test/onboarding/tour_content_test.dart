// Kiểm nội dung hướng dẫn lần đầu (F3-G13) kèm theo app — đỏ là chưa xong:
// cấu trúc, đủ chữ vi/en, mọi neo của bước mobile có TourAnchor trong lib/, mọi mobileRoute có trong router,
// và bản kèm app khớp nguồn ở repo frontend (khi repo đó nằm cạnh).
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:smart_laundry_locker/features/onboarding/domain/tour_engine.dart';
import 'package:smart_laundry_locker/features/onboarding/domain/tour_models.dart';

Map<String, dynamic> _read(String path) => jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;

void main() {
  final raw = _read('assets/onboarding/tours.json');
  final content = TourContent.fromJson(raw);
  final locales = {for (final l in ['vi', 'en']) l: _read('assets/onboarding/locales/$l.json')};
  final steps = [for (final g in content.groups) ...g.steps];

  test('tours.json đúng cấu trúc', () {
    final errors = <String>[];
    final groupIds = <String>{};
    final stepIds = <String>{};
    if (content.schemaVersion != 1) errors.add('schemaVersion phải là 1');
    for (final g in content.groups) {
      if (!idPattern.hasMatch(g.id)) errors.add('mã nhóm sai: ${g.id}');
      if (!groupIds.add(g.id)) errors.add('trùng nhóm ${g.id}');
      if (g.version < 1) errors.add('${g.id}: phiên bản < 1');
      if (g.roles.isEmpty || g.roles.any((r) => !tourRoles.contains(r))) errors.add('${g.id}: vai trò sai');
      if (g.steps.isEmpty) errors.add('${g.id}: không có bước');
      for (final s in g.steps) {
        if (!idPattern.hasMatch(s.id) || !s.id.startsWith('${g.id}-')) errors.add('id bước sai: ${s.id}');
        if (!stepIds.add(s.id)) errors.add('trùng bước ${s.id}');
        if (s.platforms.isEmpty || s.platforms.any((p) => !tourPlatforms.contains(p))) errors.add('${s.id}: platforms');
        if (!tourPlacements.contains(s.placement)) errors.add('${s.id}: placement');
        if (s.anchor != null && !idPattern.hasMatch(s.anchor!)) errors.add('${s.id}: neo sai');
      }
    }
    expect(errors, isEmpty);
  });

  test('đủ chữ ở mọi ngôn ngữ (vi, en)', () {
    final missing = <String>[];
    for (final MapEntry(key: lang, value: data) in locales.entries) {
      for (final g in content.groups) {
        for (final key in textKeys(g)) {
          final v = lookupText(data, key);
          if (v is! String || v.trim().isEmpty) missing.add('$lang: $key');
        }
      }
    }
    expect(missing, isEmpty);
  });

  test('mọi neo của bước mobile có TourAnchor trong mã app', () {
    final dart = Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'))
        .map((f) => f.readAsStringSync())
        .join('\n');
    final missing = steps
        .where((s) => s.platforms.contains('mobile') && s.anchor != null)
        .where((s) => !RegExp("TourAnchor\\(\\s*(id:\\s*)?['\"]${RegExp.escape(s.anchor!)}['\"]").hasMatch(dart))
        .map((s) => '${s.id} → TourAnchor(\'${s.anchor}\')')
        .toList();
    expect(missing, isEmpty);
  });

  test('mọi mobileRoute có trong router', () {
    final router = File('lib/core/routing/app_router.dart').readAsStringSync();
    final missing = steps
        .where((s) => s.mobileRoute != null)
        .where((s) => !router.contains("'${s.mobileRoute}'"))
        .map((s) => '${s.id} → ${s.mobileRoute}')
        .toList();
    expect(missing, isEmpty);
  });

  test('bản kèm app khớp nguồn ở repo frontend (chạy tool/sync_onboarding.sh nếu đỏ)', () {
    final fe = Directory('../frontend/fe/public/onboarding');
    if (!fe.existsSync()) {
      markTestSkipped('không có repo frontend cạnh repo mobile');
      return;
    }
    expect(jsonDecode(File('${fe.path}/tours.json').readAsStringSync()), raw);
    for (final lang in ['vi', 'en']) {
      expect(jsonDecode(File('${fe.path}/locales/$lang.json').readAsStringSync()), locales[lang], reason: lang);
    }
  });
}
