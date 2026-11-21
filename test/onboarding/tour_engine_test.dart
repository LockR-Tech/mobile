// Logic tự mở / lọc nhóm / bước thiếu của hướng dẫn lần đầu (F3-G13). Cùng bộ ca với engine TypeScript ở web
// (frontend/fe/tests/fixtures/onboarding-cases.json, chép sang bằng tool/sync_onboarding.sh).
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:smart_laundry_locker/features/onboarding/domain/tour_engine.dart';
import 'package:smart_laundry_locker/features/onboarding/domain/tour_models.dart';

void main() {
  final cases = jsonDecode(File('test/onboarding/fixtures/onboarding-cases.json').readAsStringSync())
      as Map<String, dynamic>;
  final content = TourContent.fromJson(cases['content'] as Map<String, dynamic>);
  TourGroup byId(String id) => content.groups.firstWhere((g) => g.id == id);
  List<String> ids(List<TourGroup> gs) => gs.map((g) => g.id).toList();
  Map<String, int>? seenOf(Object? raw) =>
      raw == null ? null : {for (final e in (raw as Map).entries) '${e.key}': (e.value as num).toInt()};

  test('normalizeRoles: chuỗi, danh sách, tiền tố ROLE_, SUPER_ADMIN, trùng lặp', () {
    for (final c in cases['normalizeRoles'] as List) {
      expect(normalizeRoles(c['input']), c['expected'], reason: '${c['input']}');
    }
  });

  test('ownGroups: chỉ nhóm của vai trò mình và có bước ở nền tảng này', () {
    for (final c in cases['ownGroups'] as List) {
      final roles = (c['roles'] as List).cast<String>();
      expect(ids(ownGroups(content, roles, c['platform'] as String)), c['expected'], reason: '$roles @ ${c['platform']}');
    }
  });

  test('browseGroups: admin xem được nhóm mọi vai trò, người khác chỉ vai trò mình', () {
    for (final c in cases['browseGroups'] as List) {
      expect(ids(browseGroups(content, (c['roles'] as List).cast<String>())), c['expected'], reason: '${c['roles']}');
    }
  });

  test('groupStatus: mới / có cập nhật / đã xem theo phiên bản', () {
    for (final c in cases['groupStatus'] as List) {
      expect(groupStatus(byId(c['group'] as String), seenOf(c['seen'])), c['expected'], reason: '${c['seen']}');
    }
  });

  test('decideAutoOpen: bỏ qua phiên, bỏ qua vĩnh viễn, có nhóm mới, chưa qua bước bắt buộc', () {
    for (final c in cases['decideAutoOpen'] as List) {
      final i = c['input'] as Map<String, dynamic>;
      final got = decideAutoOpen(
        signedIn: i['signedIn'] as bool,
        inWorkspace: i['inWorkspace'] as bool,
        mandatoryDone: i['mandatoryDone'] as bool,
        autoShow: i['autoShow'] as bool,
        sessionSkipped: i['sessionSkipped'] as bool,
        shownThisSession: i['shownThisSession'] as bool,
        groups: (i['groups'] as List).map((g) => byId(g as String)).toList(),
        seen: seenOf(i['seen']),
      );
      final exp = c['expected'] as Map<String, dynamic>;
      expect(got.kind, exp['kind'], reason: c['name'] as String);
      if (exp['kind'] == 'none') {
        expect(got.reason, exp['reason'], reason: c['name'] as String);
      } else {
        expect(ids(got.groups), exp['groups'], reason: c['name'] as String);
      }
    }
  });

  test('resolveStep: thiếu phần tử thì bỏ qua (optional) hoặc báo ở giữa', () {
    for (final c in cases['resolveStep'] as List) {
      final step = TourStep.fromJson(Map<String, dynamic>.from(c['step'] as Map));
      expect(resolveStep(step, c['found'] as bool), c['expected'], reason: '$c');
    }
  });
}
