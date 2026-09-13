import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:smart_laundry_locker/core/routing/app_router.dart';
import 'package:smart_laundry_locker/core/theme/shadcn_theme.dart';
import 'package:smart_laundry_locker/features/locker/domain/entities/locker_location.dart';
import 'package:smart_laundry_locker/shared/widgets/user_ui_kit.dart';

/// A bookable service that can be ordered AT a given locker location.
/// These are the 3 location-scoped entries lifted from the old home
/// "Dịch vụ tiện ích" grid (rent / send / laundry).
class _BookableService {
  const _BookableService({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.route,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final String route;
}

const List<_BookableService> _bookableServices = [
  _BookableService(
    title: 'Thuê tủ giữ đồ',
    subtitle: 'Thuê ô theo giờ, PIN dùng nhiều lần',
    icon: LucideIcons.key,
    color: Color(0xFF2563EB),
    route: AppRouter.rentLocker,
  ),
  _BookableService(
    title: 'Gửi hàng qua tủ',
    subtitle: 'Bỏ hàng vào ô, gửi PIN cho người nhận',
    icon: LucideIcons.send,
    color: Color(0xFF16A34A),
    route: AppRouter.sendParcel,
  ),
];

/// Opens the "Đặt dịch vụ" sheet for [location]. Selecting a service routes
/// to its existing flow with the chosen locker pre-selected so the user does
/// not have to pick the location again.
Future<void> showLocationServicesSheet(
  BuildContext context,
  LockerLocation location,
) {
  final int? lockerId = int.tryParse(location.id);
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.white,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
    ),
    builder: (sheetContext) {
      return SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Đặt dịch vụ',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AISLShadcnTheme.navyPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(
                    LucideIcons.mapPin,
                    size: 14,
                    color: Color(0xFF64748B),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      location.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              for (final service in _bookableServices) ...[
                _ServiceTile(
                  service: service,
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    context.push(
                      service.route,
                      extra: <String, dynamic>{
                        'initialLockerId': lockerId,
                        'locationName': location.name,
                      },
                    );
                  },
                ),
                const SizedBox(height: 10),
              ],
            ],
          ),
        ),
      );
    },
  );
}

class _ServiceTile extends StatelessWidget {
  const _ServiceTile({required this.service, required this.onTap});

  final _BookableService service;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: service.color.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(service.icon, color: service.color, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      service.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      service.subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                LucideIcons.chevronRight,
                size: 18,
                color: Color(0xFF94A3B8),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A compact row of locker utilities that are NOT location-scoped orders
/// (pickup by OTP, my locker orders, authorized opening). Shown on the
/// "Tủ" tab so these shortcuts remain reachable after the home grid moved.
class LockerUtilitiesRow extends StatelessWidget {
  const LockerUtilitiesRow({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _UtilityChip(
          icon: LucideIcons.package,
          label: 'Đơn tủ',
          color: const Color(0xFFE91E63),
          onTap: () => context.go(AppRouter.orders),
        ),
        const SizedBox(width: 10),
        _UtilityChip(
          icon: LucideIcons.lockOpen,
          label: 'Ủy quyền',
          color: AISLShadcnTheme.navyPrimary,
          onTap: () => context.push(AppRouter.authorizedOpening),
        ),
      ],
    );
  }
}

class _UtilityChip extends StatelessWidget {
  const _UtilityChip({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Material(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: context.borderColor),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(height: 6),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: context.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
