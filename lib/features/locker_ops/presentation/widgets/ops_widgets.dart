import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:smart_laundry_locker/shared/widgets/app_lottie.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:smart_laundry_locker/core/theme/shadcn_theme.dart';
import 'package:smart_laundry_locker/core/utils/app_date_time.dart';
import 'package:smart_laundry_locker/core/l10n/l10n.dart';

/// Shared design kit for the locker customer flows (SEND / RENTAL / orders).
/// Everything here is aligned to [AISLShadcnTheme] (navy + Roboto, 16px radius,
/// white cards with #E2E8F0 borders) so the locker screens match the rest of
/// the app instead of the old standalone blue palette.

// Backward-compatible aliases (manager/maintenance pages still import these).
const opsPrimary = AISLShadcnTheme.navyAccent; // #1E5A8A
const opsDark = AISLShadcnTheme.navyPrimary; // #0A2342
const opsSurface = AISLShadcnTheme.navySurface; // #F6F8FB
const opsBorder = Color(0xFFE2E8F0);
const opsMutedText = Color(0xFF64748B);

Color statusColor(String? status) => switch (status) {
  'AVAILABLE' => const Color(0xFF16A34A),
  'RESERVED' => const Color(0xFF2563EB),
  'OCCUPIED' => const Color(0xFFEA580C),
  'FAULT' => const Color(0xFFDC2626),
  'PENDING_CHECK' => const Color(0xFFEA580C),
  'OUT_OF_SERVICE' => const Color(0xFF6B7280),
  'CLEANING' => const Color(0xFF0891B2),
  'INITIALIZED' => const Color(0xFF2563EB),
  'AWAITING_DISPATCH' => const Color(0xFF2563EB),
  'ACCEPTED' => const Color(0xFF7C3AED),
  'LAUNCHING' => const Color(0xFFD97706),
  'DROP_REPORTED' => const Color(0xFFEA580C),
  'PICKUP_ASSIGNED' => const Color(0xFF7C3AED),
  'PICKED_UP' => const Color(0xFF7C3AED),
  'FAILED' => const Color(0xFFB91C1C),
  // Các chặng bay của đơn drone (deliveryStage).
  'DEPARTED' || 'EN_ROUTE' || 'APPROACHING' => const Color(0xFF1E5A8A),
  'ARRIVED' => const Color(0xFF0D9488),
  'READY_FOR_PICKUP' => const Color(0xFF0D9488),
  'STORING' => const Color(0xFFEA580C),
  'COLLECTED' => const Color(0xFF0891B2),
  'PROCESSING' => const Color(0xFF7C3AED),
  'READY' => const Color(0xFF0D9488),
  'RETURNED' => const Color(0xFF9333EA),
  'COMPLETED' => const Color(0xFF16A34A),
  'CANCELED' => const Color(0xFF6B7280),
  'EXPIRED' => const Color(0xFFB91C1C),
  'OPEN' => const Color(0xFFDC2626),
  'IN_PROGRESS' => const Color(0xFFD97706),
  'RESOLVED' => const Color(0xFF16A34A),
  'REJECTED' => const Color(0xFF64748B),
  _ => const Color(0xFF475569),
};

String statusLabel(String? status) => switch (status) {
  'AVAILABLE' => L10n.current.cellAvailable,
  'RESERVED' => L10n.current.cellReservedHeld,
  'OCCUPIED' => L10n.current.cellOccupied,
  'FAULT' => L10n.current.commonBroken,
  'PENDING_CHECK' => L10n.current.cellAwaitingTechCheck,
  'OUT_OF_SERVICE' => L10n.current.cellOutOfService,
  'CLEANING' => L10n.current.cellCleaning,
  'INITIALIZED' => L10n.current.stAwaitingDropoff,
  'AWAITING_DISPATCH' => L10n.current.stAwaitingDispatch,
  'ACCEPTED' => L10n.current.stAccepted,
  'LAUNCHING' => L10n.current.stLaunching,
  'DROP_REPORTED' => L10n.current.stDropReported,
  'PICKUP_ASSIGNED' => L10n.current.stPickupAssigned,
  'PICKED_UP' => L10n.current.stPickedUpByTech,
  'FAILED' => L10n.current.stFailed,
  'DEPARTED' => L10n.current.stDeparted,
  'EN_ROUTE' => L10n.current.stEnRoute,
  'APPROACHING' => L10n.current.stApproaching,
  'ARRIVED' => L10n.current.stArrived,
  'READY_FOR_PICKUP' => L10n.current.stReadyForPickup,
  'STORING' => L10n.current.stStoring,
  'COLLECTED' => L10n.current.stCollected,
  'PROCESSING' => L10n.current.stProcessing,
  'READY' => L10n.current.stReadyToReturn,
  'RETURNED' => L10n.current.ordTabAwaitingPickup,
  'COMPLETED' => L10n.current.commonDone,
  'CANCELED' => L10n.current.enumCancelled,
  'EXPIRED' => L10n.current.enumOverdue,
  'OPEN' => L10n.current.stNew,
  'IN_PROGRESS' => L10n.current.stProcessing,
  'RESOLVED' => L10n.current.stDone,
  // Phiếu KTV kiểm tra không đúng như mô tả (đã phản hồi người báo).
  'REJECTED' => L10n.current.stNotConfirmed,
  _ => status ?? '',
};

/// Phiếu sự cố đã đóng: hoàn tất, hoặc KTV kiểm tra không đúng mô tả
/// (`REJECTED` — đã phản hồi người báo).
bool isReportClosed(dynamic status) {
  final s = '${status ?? ''}'.toUpperCase();
  return s == 'RESOLVED' || s == 'CLOSED' || s == 'REJECTED';
}

String typeLabel(String? type) => switch (type) {
  'LAUNDRY' => L10n.current.typeLaundry,
  'SEND' => L10n.current.lockerSendParcel,
  'RENTAL' => L10n.current.homeRentLocker,
  'STORAGE' => L10n.current.typeStorage,
  'PARCEL' => L10n.current.typeParcel,
  'DRONE_DELIVERY' => L10n.current.homeDroneDelivery,
  _ => type ?? '',
};

IconData typeIcon(String? type) => switch (type) {
  'LAUNDRY' => LucideIcons.washingMachine,
  'SEND' => LucideIcons.packagePlus,
  'RENTAL' => LucideIcons.lockKeyhole,
  'PARCEL' => LucideIcons.packageCheck,
  _ => LucideIcons.package,
};

// ---- Formatting helpers (locale-safe, no async init) ----

/// `15000` / `"15000.00"` -> `15.000đ`.
String fmtPrice(dynamic value) {
  final n = ((value is num) ? value : num.tryParse('$value') ?? 0).round();
  final digits = n.abs().toString();
  final buffer = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buffer.write('.');
    buffer.write(digits[i]);
  }
  return '${n < 0 ? '-' : ''}$bufferđ';
}

DateTime? _parseDate(dynamic value) => parseServerDateTime(value);

/// Số tiền còn phải trả của đơn.
///
/// Gia hạn thuê tủ và phí quá hạn cộng thêm vào `totalPrice` rồi đặt lại
/// `paymentStatus = UNPAID`, nên thu theo `totalPrice` là bắt khách trả lại cả
/// phần đã thanh toán trước đó. Backend trả `amountDue`; nếu server chưa có
/// field này (chưa deploy) thì lùi về `totalPrice` như cũ.
double orderAmountDue(Map<String, dynamic> order) {
  final due = order['amountDue'];
  if (due is num) return due.toDouble();
  final parsedDue = num.tryParse('$due');
  if (parsedDue != null) return parsedDue.toDouble();
  final total = order['totalPrice'];
  if (total is num) return total.toDouble();
  return num.tryParse('$total')?.toDouble() ?? 0;
}

/// Ô của đơn (đang có hàng) bị báo sự cố, chưa xử lý xong: server dừng phí quá giờ
/// từ lúc báo và chưa cho gia hạn.
bool orderHasOpenBoxIncident(Map<String, dynamic> order) =>
    order['boxIncidentOpenedAt'] != null || orderBoxIncidentBlocksAccess(order);

/// Sự cố đã được xác nhận (KTV khoá ô / ô hỏng): không thu tiền, không mở ô bằng
/// mã, không tự kết thúc đơn tới khi KTV xử lý xong. Khách mới báo, ô còn chờ KTV
/// kiểm tra thì vẫn mở ô và lấy đồ được.
bool orderBoxIncidentBlocksAccess(Map<String, dynamic> order) =>
    '${order['accessBlockReason'] ?? ''}'.toUpperCase() == 'BOX_INCIDENT_OPEN';

/// Câu giải thích cho khách khi ô có sự cố đang mở.
String boxIncidentPausedText(Map<String, dynamic> order) {
  final since = order['boxIncidentOpenedAt'];
  final sinceText =
      since == null ? '' : L10n.current.incidentSince(fmtDateTime(since));
  if (!orderBoxIncidentBlocksAccess(order)) {
    return L10n.current.incidentReportedCanOpen(sinceText);
  }
  return L10n.current.incidentBlocked(sinceText);
}

String _two(int n) => n.toString().padLeft(2, '0');

/// ISO timestamp -> `HH:mm:ss dd/MM/yyyy`.
String fmtDateTime(dynamic value) {
  final d = _parseDate(value);
  if (d == null) return '—';
  return '${_two(d.hour)}:${_two(d.minute)}:${_two(d.second)} ${_two(d.day)}/${_two(d.month)}/${d.year}';
}

bool isOverdue(dynamic deadline) {
  final d = _parseDate(deadline);
  return d != null && DateTime.now().isAfter(d);
}

String _humanDuration(Duration d) {
  if (d.inDays > 0) return L10n.current.durDaysHours(d.inDays, d.inHours % 24);
  if (d.inHours > 0) {
    return L10n.current.durHoursMinutes(d.inHours, d.inMinutes % 60);
  }
  if (d.inMinutes > 0) return L10n.current.minutesShort(d.inMinutes);
  return L10n.current.durUnderMinute;
}

/// `Còn 5 giờ 12 phút` / `Quá hạn 2 giờ`.
String fmtRemaining(dynamic deadline) {
  final d = _parseDate(deadline);
  if (d == null) return '';
  final now = DateTime.now();
  return d.isAfter(now)
      ? L10n.current.timeRemaining(_humanDuration(d.difference(now)))
      : L10n.current.timeOverdueBy(_humanDuration(now.difference(d)));
}

DateTime? parseDate(dynamic value) => _parseDate(value);

String fmtOverdueDuration(dynamic deadline) {
  final d = _parseDate(deadline);
  if (d == null) return '';
  final now = DateTime.now();
  if (!now.isAfter(d)) return '';
  return _humanDuration(now.difference(d));
}

// ---- Reusable widgets ----

/// Small uppercase section label above a group of fields.
class OpsSectionLabel extends StatelessWidget {
  const OpsSectionLabel(this.text, {this.icon, super.key});
  final String text;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16, color: opsPrimary),
            const SizedBox(width: 6),
          ],
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 13,
                letterSpacing: 0.2,
                color: opsDark,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// White rounded card matching the stores/home cards.
class OpsCard extends StatelessWidget {
  const OpsCard({
    required this.child,
    this.padding,
    this.onTap,
    this.color,
    this.border,
    super.key,
  });
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final Color? color;
  final BoxBorder? border;

  @override
  Widget build(BuildContext context) {
    final decoration = BoxDecoration(
      color: color ?? Colors.white,
      borderRadius: BorderRadius.circular(18),
      border: border ?? Border.all(color: opsBorder),
      boxShadow: const [
        BoxShadow(
          color: Color(0x0A0A2342),
          blurRadius: 18,
          offset: Offset(0, 8),
        ),
      ],
    );

    if (onTap == null) {
      return Container(
        width: double.infinity,
        padding: padding ?? const EdgeInsets.all(16),
        decoration: decoration,
        child: child,
      );
    }

    return Container(
      width: double.infinity,
      decoration: decoration,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: padding ?? const EdgeInsets.all(16),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// Pill status chip.
class StatusChip extends StatelessWidget {
  const StatusChip(this.status, {super.key});
  final String? status;

  @override
  Widget build(BuildContext context) {
    final color = statusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        statusLabel(status),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

/// Label/value row used inside detail cards.
class OpsInfoRow extends StatelessWidget {
  const OpsInfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
    super.key,
  });
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: opsMutedText),
          const SizedBox(width: 8),
          // Nhãn tiếng Anh dài hơn tiếng Việt: cho xuống dòng thay vì tràn.
          Flexible(
            child: Text(
              label,
              style: const TextStyle(fontSize: 13, color: opsMutedText),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: valueColor ?? const Color(0xFF0F172A),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Inline info/warning banner.
class OpsBanner extends StatelessWidget {
  const OpsBanner({
    required this.text,
    this.title,
    this.icon = LucideIcons.info,
    this.tone = OpsBannerTone.info,
    super.key,
  });
  final String text;
  final String? title;
  final IconData icon;
  final OpsBannerTone tone;

  @override
  Widget build(BuildContext context) {
    final color = switch (tone) {
      OpsBannerTone.info => opsPrimary,
      OpsBannerTone.warning => const Color(0xFFB45309),
      OpsBannerTone.danger => const Color(0xFFDC2626),
      OpsBannerTone.success => const Color(0xFF16A34A),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: title != null ? 22 : 16, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (title != null) ...[
                  Text(
                    title!,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 4),
                ],
                Text(
                  text,
                  style: TextStyle(
                    fontSize: 12.5,
                    height: 1.35,
                    color: color,
                    fontWeight: title != null
                        ? FontWeight.w500
                        : FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

enum OpsBannerTone { info, warning, danger, success }

/// Full-width primary CTA with loading state.
class OpsPrimaryButton extends StatelessWidget {
  const OpsPrimaryButton({
    required this.label,
    required this.onPressed,
    this.icon,
    this.loading = false,
    this.color = opsDark,
    super.key,
  });
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool loading;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Material(
        color: onPressed == null || loading
            ? color.withValues(alpha: 0.5)
            : color,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: loading ? null : onPressed,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (loading)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                else ...[
                  if (icon != null) ...[
                    Icon(icon, size: 18, color: Colors.white),
                    const SizedBox(width: 8),
                  ],
                  // Flexible chứ không để Text tự do: nhãn tiếng Việt dài ("Kết thúc
                  // thuê & lấy đồ") lấy chiều rộng tự nhiên nên tràn khỏi nút trên máy
                  // hẹp. Flexible cho xuống dòng mà vẫn giữ nút căn giữa; Expanded thì
                  // chiếm hết chỗ còn lại và làm chữ lệch trái.
                  Flexible(
                    child: Text(
                      label,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Single action row used inside bottom sheets (order detail actions,
/// maintenance cell actions, etc). `primary` renders as a full-width CTA via
/// [OpsPrimaryButton]; otherwise a tinted tappable row.
class OpsSheetAction extends StatelessWidget {
  const OpsSheetAction({
    required this.label,
    this.icon,
    this.leading,
    required this.onTap,
    this.primary = false,
    this.danger = false,
    this.color,
    super.key,
  }) : assert(icon != null || leading != null);
  final String label;
  final IconData? icon;
  final Widget? leading;
  final VoidCallback onTap;
  final bool primary;
  final bool danger;

  /// Overrides the default primary/danger color when a row needs its own
  /// semantic color (e.g. a row of 5 differently-colored maintenance actions).
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final color = this.color ?? (danger ? const Color(0xFFDC2626) : opsPrimary);
    if (primary) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: OpsPrimaryButton(
          label: label,
          icon: icon ?? LucideIcons.circle,
          onPressed: onTap,
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                leading ?? Icon(icon!, size: 18, color: color),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
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

/// Empty / placeholder state.
class OpsEmptyState extends StatelessWidget {
  const OpsEmptyState({
    required this.icon,
    required this.title,
    this.subtitle,
    super.key,
  });
  final IconData icon;
  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: opsPrimary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 32, color: opsPrimary),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 15,
                color: opsDark,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 6),
              Text(
                subtitle!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, color: opsMutedText),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// `5 giờ 12 phút` — khoảng cách tới hạn (chưa tới hoặc đã quá), không kèm
/// "Còn"/"Quá hạn" — dùng khi nhãn bên cạnh đã nói rõ.
String fmtDeadlineDistance(dynamic deadline) {
  final d = _parseDate(deadline);
  if (d == null) return '';
  final now = DateTime.now();
  return _humanDuration(d.isAfter(now) ? d.difference(now) : now.difference(d));
}

/// PIN + QR access block shown once an order has an active credential.
/// PIN is rendered as tappable digit tiles (copy-to-clipboard); QR is framed.
class AccessCredentials extends StatelessWidget {
  const AccessCredentials({
    required this.pin,
    this.qrToken,
    this.caption,
    this.showSuccessAnimation = true,
    this.showQr = false,
    this.animationSize = 210,
    super.key,
  });
  final String? pin;
  final String? qrToken;
  final String? caption;
  final bool showSuccessAnimation;
  final bool showQr;
  final double animationSize;

  @override
  Widget build(BuildContext context) {
    if (pin == null || pin!.isEmpty) return const SizedBox.shrink();
    final digits = pin!.split('');
    return Column(
      children: [
        if (showQr && qrToken != null && qrToken!.isNotEmpty) ...[
          Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: opsBorder),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x140A2342),
                      blurRadius: 22,
                      offset: Offset(0, 10),
                    ),
                  ],
                ),
                child: QrImageView(
                  data: qrToken!,
                  size: 168,
                  eyeStyle: const QrEyeStyle(
                    eyeShape: QrEyeShape.square,
                    color: opsDark,
                  ),
                  dataModuleStyle: const QrDataModuleStyle(
                    dataModuleShape: QrDataModuleShape.square,
                    color: opsDark,
                  ),
                ),
              )
              .animate()
              .fadeIn(duration: 350.ms)
              .scale(begin: const Offset(0.92, 0.92)),
          const SizedBox(height: 16),
        ] else if (showSuccessAnimation) ...[
          SizedBox(
                width: animationSize,
                height: animationSize,
                child: AppLottie(
                  AppLottieAssets.daThanhToan,
                  fallback: (context) => Container(
                    width: 90,
                    height: 90,
                    decoration: const BoxDecoration(
                      color: Color(0xFFDCFCE7),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      LucideIcons.circleCheck,
                      size: 52,
                      color: Color(0xFF16A34A),
                    ),
                  ),
                ),
              )
              .animate()
              .fadeIn(duration: 350.ms)
              .scale(begin: const Offset(0.9, 0.9)),
          const SizedBox(height: 8),
        ],
        GestureDetector(
          onTap: () {
            Clipboard.setData(ClipboardData(text: pin!));
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(
                SnackBar(content: Text(context.l10n.credPinCopied)),
              );
          },
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (final d in digits)
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 2.5),
                      width: 32,
                      height: 42,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [opsDark, AISLShadcnTheme.navySecondary],
                        ),
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: Text(
                        d,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 19,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 5),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(LucideIcons.copy, size: 11, color: opsMutedText),
                  SizedBox(width: 4),
                  Text(
                    context.l10n.commonCopyTapHint,
                    style: TextStyle(fontSize: 10.5, color: opsMutedText),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Text(
          caption ?? context.l10n.credEnterPinAtLocker,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 11.5,
            color: opsMutedText,
            height: 1.3,
          ),
        ),
      ],
    );
  }
}

/// Compact chip shown at the top of an order form when the flow was opened
/// from a specific locker location ("Đặt dịch vụ" sheet) so the user sees
/// which place they are ordering at.
class LocationHint extends StatelessWidget {
  const LocationHint({super.key, required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: opsPrimary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: opsPrimary.withValues(alpha: 0.20)),
      ),
      child: Row(
        children: [
          const Icon(LucideIcons.mapPin, size: 16, color: opsPrimary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              context.l10n.credAt(name),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: opsDark,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
