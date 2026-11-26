import 'package:flutter/material.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:smart_laundry_locker/core/l10n/l10n.dart';
import 'package:smart_laundry_locker/core/routing/role_routes.dart';
import 'package:smart_laundry_locker/core/services/token_service.dart';

/// Đổi vai trò cho tài khoản nhiều vai trò (F3-G15): một email vừa là KTV vừa là khách… chọn vai trò lúc
/// đăng nhập và đổi lại trong Hồ sơ (khách, KTV, trang "dùng web" của admin).

String roleName(BuildContext context, AppRole role) => switch (role) {
  AppRole.customer => context.l10n.roleNameCustomer,
  AppRole.lockerTechnician => context.l10n.roleNameLockerTech,
  AppRole.droneTechnician => context.l10n.roleNameDroneTech,
  AppRole.admin => context.l10n.roleNameAdmin,
};

String _roleDescription(BuildContext context, AppRole role) => switch (role) {
  AppRole.customer => context.l10n.roleDescCustomer,
  AppRole.lockerTechnician => context.l10n.roleDescLockerTech,
  AppRole.droneTechnician => context.l10n.roleDescDroneTech,
  AppRole.admin => context.l10n.roleDescAdmin,
};

IconData _roleIcon(AppRole role) => switch (role) {
  AppRole.customer => LucideIcons.user,
  AppRole.lockerTechnician => LucideIcons.wrench,
  AppRole.droneTechnician => LucideIcons.plane,
  AppRole.admin => LucideIcons.shieldCheck,
};

/// Vừa đăng nhập: tài khoản nhiều vai trò thì hỏi vào với vai trò nào. Đóng sheet không chọn ⇒ giữ vai trò
/// đã chọn lần trước (hoặc theo thứ tự ưu tiên). Trả về vai trò sẽ dùng.
Future<AppRole> chooseRoleAfterLogin(
  BuildContext context,
  List<String> roles,
) async {
  final options = accountRoles(roles);
  final current = primaryRole(roles);
  if (options.length < 2 || !context.mounted) return current;
  final picked = await showRolePicker(
    context,
    options: options,
    current: current,
  );
  if (picked != null) await ActiveRole.choose(picked);
  return primaryRole(roles);
}

/// Hồ sơ › "Đổi vai trò": chọn vai trò khác ⇒ lưu và mở trang chủ của vai trò đó.
Future<void> switchRoleFromProfile(BuildContext context) async {
  final roles = await TokenService.getCurrentRoles();
  if (!context.mounted) return;
  final options = accountRoles(roles);
  final current = primaryRole(roles);
  final picked = await showRolePicker(
    context,
    options: options,
    current: current,
  );
  if (picked == null || picked == current || !context.mounted) return;
  await ActiveRole.choose(picked);
  if (!context.mounted) return;
  SmartDialog.showToast(context.l10n.roleSwitched(roleName(context, picked)));
  context.go(homeForRole(picked));
}

Future<AppRole?> showRolePicker(
  BuildContext context, {
  required List<AppRole> options,
  required AppRole current,
}) => showModalBottomSheet<AppRole>(
  context: context,
  useRootNavigator: true,
  isScrollControlled: true,
  backgroundColor: Colors.transparent,
  builder: (_) => RolePickerSheet(options: options, current: current),
);

/// Sheet liệt kê các vai trò của tài khoản; đóng sheet trả về vai trò được chọn.
class RolePickerSheet extends StatelessWidget {
  const RolePickerSheet({
    required this.options,
    required this.current,
    super.key,
  });

  final List<AppRole> options;
  final AppRole current;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF0A2342) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final mutedColor = isDark
        ? const Color(0xFF94A3B8)
        : const Color(0xFF64748B);

    return SafeArea(
      top: false,
      child: Container(
        decoration: BoxDecoration(
          color: bg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: mutedColor.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Text(
              context.l10n.rolePickerTitle,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: textColor,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              context.l10n.rolePickerMessage,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: mutedColor),
            ),
            const SizedBox(height: 18),
            for (final role in options) ...[
              _RoleOption(
                key: ValueKey('role-option-${role.name}'),
                icon: _roleIcon(role),
                label: roleName(context, role),
                description: _roleDescription(context, role),
                selected: role == current,
                onTap: () => Navigator.pop(context, role),
              ),
              const SizedBox(height: 10),
            ],
          ],
        ),
      ),
    );
  }
}

class _RoleOption extends StatelessWidget {
  const _RoleOption({
    required this.icon,
    required this.label,
    required this.description,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final IconData icon;
  final String label;
  final String description;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const navy = Color(0xFF003D5B);
    final borderColor = selected
        ? navy.withValues(alpha: isDark ? 0.7 : 0.4)
        : (isDark ? const Color(0xFF1E4976) : const Color(0xFFE2E8F0));
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final mutedColor = isDark
        ? const Color(0xFF94A3B8)
        : const Color(0xFF64748B);

    return Semantics(
      button: true,
      selected: selected,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: selected
                ? navy.withValues(alpha: isDark ? 0.35 : 0.08)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: borderColor, width: selected ? 1.5 : 1),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: selected
                      ? navy.withValues(alpha: 0.12)
                      : (isDark
                            ? const Color(0xFF0D2B4A)
                            : const Color(0xFFF0F4F8)),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  size: 20,
                  color: selected ? navy : mutedColor,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            label,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: textColor,
                            ),
                          ),
                        ),
                        if (selected) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: navy.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              context.l10n.roleCurrentBadge,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: navy,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      description,
                      style: TextStyle(fontSize: 12.5, color: mutedColor),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Chỉ dựng [builder] khi tài khoản đang đăng nhập có nhiều vai trò (dòng "Đổi vai trò" ở các trang Hồ sơ).
class RoleSwitchGate extends StatelessWidget {
  const RoleSwitchGate({required this.builder, this.rolesLoader, super.key});

  final Widget Function(BuildContext context, AppRole current) builder;

  /// Cho test thay nguồn role (mặc định đọc từ token đăng nhập).
  final Future<List<String>> Function()? rolesLoader;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<String>>(
      future: (rolesLoader ?? TokenService.getCurrentRoles)(),
      builder: (context, snap) {
        final roles = snap.data;
        if (roles == null || !canSwitchRole(roles))
          return const SizedBox.shrink();
        return builder(context, primaryRole(roles));
      },
    );
  }
}
