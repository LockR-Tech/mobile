import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_laundry_locker/core/routing/role_routes.dart';
import 'package:smart_laundry_locker/core/routing/role_switch.dart';

/// Đổi vai trò cho tài khoản nhiều vai trò (F3-G15).
void main() {
  tearDown(() => ActiveRole.chosenForTest = null);

  test('liệt kê vai trò app phục vụ theo thứ tự ưu tiên', () {
    expect(accountRoles(['CUSTOMER', 'LOCKER_TECHNICIAN']), [
      AppRole.lockerTechnician,
      AppRole.customer,
    ]);
    expect(accountRoles(['ROLE_ADMIN', 'ROLE_DRONE_TECHNICIAN']), [
      AppRole.admin,
      AppRole.droneTechnician,
    ]);
    expect(accountRoles(const []), [AppRole.customer]);
    expect(canSwitchRole(['LOCKER_TECHNICIAN']), isFalse);
    expect(canSwitchRole(['CUSTOMER', 'DRONE_TECHNICIAN']), isTrue);
  });

  test(
    'vai trò đã chọn thắng thứ tự ưu tiên — chỉ khi tài khoản có vai trò đó',
    () {
      const roles = ['CUSTOMER', 'LOCKER_TECHNICIAN'];
      expect(primaryRole(roles), AppRole.lockerTechnician);
      expect(homeForRoles(roles), '/technician-home');

      ActiveRole.chosenForTest = AppRole.customer;
      expect(primaryRole(roles), AppRole.customer);
      expect(homeForRoles(roles), '/home');
      // Trang KTV tủ giờ đưa về trang chủ khách.
      expect(
        routeRedirect(
          Uri.parse('/technician-home'),
          signedIn: true,
          roles: roles,
        ),
        '/home',
      );

      // Tài khoản khác không có vai trò khách ⇒ bỏ qua lựa chọn cũ.
      expect(primaryRole(['DRONE_TECHNICIAN']), AppRole.droneTechnician);
    },
  );

  test(
    'lưu vai trò đã chọn, khôi phục khi mở lại app, xoá khi đăng xuất',
    () async {
      SharedPreferences.setMockInitialValues({});
      await ActiveRole.choose(AppRole.customer);
      ActiveRole.chosenForTest = null;

      await ActiveRole.restore();
      expect(ActiveRole.chosen, AppRole.customer);

      await ActiveRole.clear();
      await ActiveRole.restore();
      expect(ActiveRole.chosen, isNull);
    },
  );

  testWidgets('dòng "Đổi vai trò" chỉ hiện với tài khoản nhiều vai trò', (
    tester,
  ) async {
    Widget gate(List<String> roles) => MaterialApp(
      home: Scaffold(
        body: RoleSwitchGate(
          rolesLoader: () async => roles,
          builder: (context, current) => Text('switch:${current.name}'),
        ),
      ),
    );

    await tester.pumpWidget(gate(['LOCKER_TECHNICIAN']));
    await tester.pumpAndSettle();
    expect(find.textContaining('switch:'), findsNothing);

    await tester.pumpWidget(gate(['CUSTOMER', 'LOCKER_TECHNICIAN']));
    await tester.pumpAndSettle();
    expect(find.text('switch:lockerTechnician'), findsOneWidget);
  });

  testWidgets('hộp chọn vai trò trả về vai trò được bấm', (tester) async {
    AppRole? picked;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () async => picked = await showRolePicker(
              context,
              options: const [AppRole.lockerTechnician, AppRole.customer],
              current: AppRole.lockerTechnician,
            ),
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('Đang dùng'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('role-option-customer')));
    await tester.pumpAndSettle();
    expect(picked, AppRole.customer);
  });
}
