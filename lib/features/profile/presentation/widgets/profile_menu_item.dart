import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:smart_laundry_locker/shared/widgets/user_ui_kit.dart';

/// Profile menu item widget
class ProfileMenuItem extends StatelessWidget {
  const ProfileMenuItem({
    required this.icon,
    required this.title,
    super.key,
    this.subtitle,
    this.onTap,
    this.trailing,
    this.iconColor,
    this.textColor,
    this.showDivider = true,
  });
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final Widget? trailing;
  final Color? iconColor;
  final Color? textColor;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          leading: Icon(
            icon,
            color: iconColor ?? ShadTheme.of(context).colorScheme.primary,
            size: 24,
          ),

          title: Text(
            title,
            style: TextStyle(
              fontFamily: 'Manrope',
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: textColor ?? context.textPrimary,
            ),
          ),
          subtitle: subtitle != null
              ? Text(
                  subtitle!,
                  style: TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 14,
                    color: context.textMuted,
                    fontWeight: FontWeight.w500,
                  ),
                )
              : null,
          trailing:
              trailing ??
              Icon(LucideIcons.chevronRight, size: 18, color: context.textMuted),
          onTap: onTap,
        ),
      ],
    );
  }
}

/// Profile menu item with switch
class ProfileMenuSwitchItem extends StatelessWidget {
  const ProfileMenuSwitchItem({
    required this.icon,
    required this.title,
    required this.value,
    super.key,
    this.subtitle,
    this.onChanged,
    this.iconColor,
    this.showDivider = true,
  });
  final IconData icon;
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool>? onChanged;
  final Color? iconColor;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: (iconColor ?? ShadTheme.of(context).colorScheme.primary)
                  .withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: iconColor ?? ShadTheme.of(context).colorScheme.primary,
              size: 20,
            ),
          ),
          title: Text(
            title,
            style: TextStyle(
              fontFamily: 'Manrope',
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: context.textPrimary,
            ),
          ),
          subtitle: subtitle != null
              ? Text(
                  subtitle!,
                  style: TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 14,
                    color: context.textMuted,
                  ),
                )
              : null,
          trailing: Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: ShadTheme.of(context).colorScheme.primary,
          ),
          onTap: () => onChanged?.call(!value),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 4,
          ),
        ),
        if (showDivider) const Divider(height: 1, indent: 72, endIndent: 16),
      ],
    );
  }
}

/// Profile menu item with badge
class ProfileMenuBadgeItem extends StatelessWidget {
  const ProfileMenuBadgeItem({
    required this.icon,
    required this.title,
    super.key,
    this.subtitle,
    this.onTap,
    this.badgeText,
    this.badgeColor,
    this.iconColor,
    this.showDivider = true,
  });
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final String? badgeText;
  final Color? badgeColor;
  final Color? iconColor;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: (iconColor ?? ShadTheme.of(context).colorScheme.primary)
                  .withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: iconColor ?? ShadTheme.of(context).colorScheme.primary,
              size: 20,
            ),
          ),
          title: Text(
            title,
            style: TextStyle(
              fontFamily: 'Manrope',
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: context.textPrimary,
            ),
          ),
          subtitle: subtitle != null
              ? Text(
                  subtitle!,
                  style: TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 14,
                    color: context.textMuted,
                  ),
                )
              : null,
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (badgeText != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color:
                        badgeColor ?? ShadTheme.of(context).colorScheme.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    badgeText!,
                    style: TextStyle(
                      fontFamily: 'Manrope',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: ShadTheme.of(
                        context,
                      ).colorScheme.primaryForeground,
                    ),
                  ),
                ),
              const SizedBox(width: 8),
              Icon(LucideIcons.chevronRight, size: 16, color: context.textMuted),
            ],
          ),
          onTap: onTap,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 4,
          ),
        ),
        if (showDivider) const Divider(height: 1, indent: 72, endIndent: 16),
      ],
    );
  }
}
