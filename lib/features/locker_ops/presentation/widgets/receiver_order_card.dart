import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:smart_laundry_locker/features/locker_ops/data/locker_ops_service.dart';
import 'package:smart_laundry_locker/features/locker_ops/data/receiver_order.dart';
import 'package:smart_laundry_locker/features/locker_ops/presentation/utils/locker_maps.dart';
import 'package:smart_laundry_locker/features/locker_ops/presentation/widgets/locker_unlock_modal.dart';
import 'package:smart_laundry_locker/features/locker_ops/presentation/widgets/ops_widgets.dart';
import 'package:smart_laundry_locker/shared/widgets/app_lottie.dart';
import 'package:smart_laundry_locker/shared/widgets/user_ui_kit.dart';
import 'package:smart_laundry_locker/core/l10n/l10n.dart';

/// Mở ô của một đơn mình là người nhận / người lấy hộ: xác nhận đang đứng tại tủ
/// (Bluetooth hoặc quét tem QR trên tủ) rồi gọi `POST /api/iot/unlock-with-code`
/// bằng mã lấy hàng. Chỉ báo "đã mở" khi server trả `accepted`.
///
/// Trả `true` khi ô đã mở.
Future<bool> openReceiverOrderBox(
  BuildContext context, {
  required LockerOpsService service,
  required ReceiverOrder order,
}) async {
  final messenger = ScaffoldMessenger.of(context);
  void snack(String msg) => messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(msg)));

  final lockerId = order.lockerId;
  final pin = order.pickupPin;
  if (!order.canUnlockWithCode || lockerId == null || pin == null) {
    snack(L10n.current.recvNoCodeYet);
    return false;
  }

  final action = await LockerUnlockModal.show(
    context,
    lockerName: order.lockerName ?? L10n.current.ordLockrLocker,
    lockerCode: order.lockerCode ?? '',
    lockerId: lockerId,
    boxId: order.boxId,
    boxLabel: order.boxLabel,
    pinCode: pin,
  );
  if (action == null ||
      (action.type != LockerUnlockActionType.openViaBle &&
          action.type != LockerUnlockActionType.openViaQr)) {
    return false;
  }

  snack(L10n.current.ordSendingOpenCommand(order.boxLabel));
  try {
    final res = await service.unlockWithCode(lockerId, pin);
    final accepted = res['accepted'] == true;
    final msg = res['message']?.toString();
    snack(
      accepted
          ? L10n.current.recvBoxOpenedPickup(order.boxLabel)
          : L10n.current.ordBoxOpenFailed(
              order.boxLabel,
              msg != null && msg.isNotEmpty ? ': $msg' : '',
            ),
    );
    return accepted;
  } catch (e) {
    snack(
      LockerOpsService.isEndpointUnavailable(e)
          ? L10n.current.recvOpenByCodeNotSupported
          : LockerOpsService.errorMessage(e),
    );
    return false;
  }
}

/// Chỉ đường tới tủ của đơn bằng toạ độ/địa chỉ server trả về.
Future<void> openReceiverOrderDirections(
  BuildContext context,
  ReceiverOrder order,
) async {
  final messenger = ScaffoldMessenger.of(context);
  final result = await openLockerDirectionsResult(
    latitude: order.lockerLatitude,
    longitude: order.lockerLongitude,
    address: order.lockerAddress,
  );
  final msg = switch (result) {
    DirectionsResult.opened => null,
    DirectionsResult.noLocation => L10n.current.ordLockerNoLocation,
    DirectionsResult.launchFailed =>
      L10n.current.ordCantOpenMapsApp,
  };
  if (msg != null) {
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(msg)));
  }
}

/// Thẻ một đơn phía người nhận: đồng bộ phong cách với _OrderCard của "Đơn của tôi",
/// có minh hoạ 3D Lottie, tinh gọn thông tin và bo góc chuẩn Customer Design System.
class ReceiverOrderCard extends StatelessWidget {
  const ReceiverOrderCard({
    super.key,
    required this.order,
    required this.onUnlock,
    required this.onDirections,
    this.delegatedView = false,
    this.onTap,
  });

  final ReceiverOrder order;
  final VoidCallback onUnlock;
  final VoidCallback onDirections;

  /// `true` ở màn "Đơn ủy quyền" (mình là người lấy hộ).
  final bool delegatedView;

  /// Chạm thẻ ⇒ mở chi tiết đơn.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isDone = order.isFinished;
    final overdue = order.overdue && !isDone;
    final status = (order.type == 'DRONE_DELIVERY' &&
            (order.deliveryStage ?? '').isNotEmpty)
        ? order.deliveryStage
        : order.status;
    final sColor = statusColor(status);
    final isDrone = order.type == 'DRONE_DELIVERY';
    final lockerTitle = (order.lockerName ?? '').trim().isNotEmpty
        ? order.lockerName!.trim()
        : ((order.lockerCode ?? '').trim().isNotEmpty
            ? context.l10n.recvLockerWithCode('${order.lockerCode}')
            : L10n.current.ordLockrLocker);

    return Material(
      color: context.cardBg,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              clipBehavior: Clip.antiAlias,
              children: [
                // 3D Lottie asset in bottom-right corner (compact, elegant, non-obtrusive)
                Positioned(
                  bottom: -2,
                  right: -2,
                  child: IgnorePointer(
                    child: SizedBox(
                      width: isDrone ? 122 : 112,
                      height: isDrone ? 112 : 104,
                      child: AppLottie(
                        isDrone
                            ? AppLottieAssets.airplaneBox
                            : AppLottieAssets.box,
                        alignment: Alignment.bottomRight,
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Order Code + Status Badge Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Text(
                              order.displayCode,
                              style: TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w800,
                                color: context.textPrimary,
                                letterSpacing: -0.2,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 9,
                              vertical: 3.5,
                            ),
                            decoration: BoxDecoration(
                              color: (isDone
                                      ? const Color(0xFF16A34A)
                                      : overdue
                                          ? const Color(0xFFDC2626)
                                          : sColor)
                                  .withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              statusLabel(status),
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                color: isDone
                                    ? const Color(0xFF16A34A)
                                    : overdue
                                        ? const Color(0xFFDC2626)
                                        : sColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),

                      // Sender label / Service type + Deadline
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          if ((order.senderName ?? '').isNotEmpty) ...[
                            Text(
                              delegatedView ? context.l10n.recvDelegatorColon : context.l10n.recvSenderColon,
                              style: TextStyle(
                                fontSize: 12.5,
                                color: context.textMuted,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              order.senderName!,
                              style: TextStyle(
                                fontSize: 12.5,
                                color: context.textPrimary,
                                fontWeight: FontWeight.w700,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ] else
                            Text(
                              isDrone
                                  ? 'Giao Drone'
                                  : (delegatedView ? context.l10n.recvDelegatedPickup : context.l10n.recvIncomingParcel),
                              style: TextStyle(
                                fontSize: 12.5,
                                color: context.textMuted,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          if (order.pickupDeadline != null) ...[
                            Text(
                              '•',
                              style: TextStyle(
                                fontSize: 12,
                                color: context.textMuted,
                              ),
                            ),
                            Text(
                              context.l10n.ordPickupDeadlineValue(fmtDateTime(order.pickupDeadline)),
                              style: TextStyle(
                                fontSize: 12,
                                color: overdue
                                    ? const Color(0xFFDC2626)
                                    : context.textMuted,
                                fontWeight: overdue
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                              ),
                            ),
                          ],
                        ],
                      ),
                      if (delegatedView && (order.delegateNote ?? '').isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          order.delegateNote!,
                          style: TextStyle(
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                            color: context.textMuted,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      const SizedBox(height: 12),

                      // Route: Tủ and Ô
                      Padding(
                        padding: const EdgeInsets.only(right: 120),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _RouteRow(
                              isOrigin: true,
                              text: lockerTitle,
                            ),
                            Padding(
                              padding: const EdgeInsets.only(
                                left: 7.25,
                                top: 2,
                                bottom: 2,
                              ),
                              child: Container(
                                width: 1.5,
                                height: 10,
                                color: const Color(0xFFCBD5E1),
                              ),
                            ),
                            _RouteRow(
                              isOrigin: false,
                              text: order.boxNumber != null
                                  ? context.l10n.boxNumberLabel('${order.boxNumber}')
                                  : context.l10n.recvStorageBox,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),

                      if (!delegatedView && order.delegated)
                        OpsBanner(
                          tone: OpsBannerTone.info,
                          icon: LucideIcons.userCheck,
                          text:
                              context.l10n.recvCodeMovedShort,
                        )
                      else if (order.isActive && (order.pickupPin ?? '').isNotEmpty) ...[
                        Center(
                          child: AccessCredentials(
                            pin: order.pickupPin,
                            qrToken: order.qrToken,
                            caption: context.l10n.recvCredCaptionShort,
                            showSuccessAnimation: false,
                          ),
                        ),
                        const SizedBox(height: 10),
                      ] else if (!order.isFinished) ...[
                        OpsBanner(
                          tone: OpsBannerTone.info,
                          icon: LucideIcons.hourglass,
                          text:
                              context.l10n.recvNotReady,
                        ),
                        const SizedBox(height: 10),
                      ],

                      // Bottom action row: Status text or PIN preview + Action Button
                      Wrap(
                        spacing: 12,
                        runSpacing: 8,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          if (isDone)
                            Text(
                              context.l10n.recvReceived,
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF16A34A),
                              ),
                            )
                          else if (order.delegated)
                            Text(
                              context.l10n.recvDelegated,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: context.textMuted,
                              ),
                            ),

                          // Action button pill
                          Builder(
                            builder: (ctx) {
                              final String actionLabel;
                              final Color? actionBgColor;
                              final Color actionTextColor;
                              final BorderSide actionBorderSide;

                              if (order.canUnlockWithCode) {
                                actionLabel = context.l10n.recvOpenBoxPickup(order.boxLabel);
                                actionBgColor = const Color(0xFF0284C7)
                                    .withValues(alpha: 0.12);
                                actionTextColor = const Color(0xFF0284C7);
                                actionBorderSide = const BorderSide(
                                  color: Color(0xFF0284C7),
                                  width: 1.4,
                                );
                              } else {
                                actionLabel = context.l10n.commonDetails;
                                actionBgColor = null;
                                actionTextColor = context.textPrimary;
                                actionBorderSide = BorderSide(
                                  color: context.borderColor,
                                  width: 1.5,
                                );
                              }

                              return GestureDetector(
                                onTap: () {
                                  if (order.canUnlockWithCode) {
                                    onUnlock();
                                  } else if (onTap != null) {
                                    onTap!();
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: actionBgColor,
                                    border: Border.fromBorderSide(
                                      actionBorderSide,
                                    ),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    actionLabel,
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w700,
                                      color: actionTextColor,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // Overdue banner (if any)
            if (overdue)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                color: const Color(0xFFFEF2F2),
                child: Row(
                  children: [
                    Icon(
                      LucideIcons.triangleAlert,
                      size: 13,
                      color: Color(0xFFDC2626),
                    ),
                    SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        context.l10n.recvOverdueHurry,
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFDC2626),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // Delegated notice banner (if delegated)
            if (!delegatedView && order.delegated)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                color: const Color(0xFFF0F9FF),
                child: Row(
                  children: [
                    Icon(
                      LucideIcons.userCheck,
                      size: 13,
                      color: Color(0xFF0284C7),
                    ),
                    SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        context.l10n.recvCodeTransferred,
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF0369A1),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _RouteRow extends StatelessWidget {
  const _RouteRow({required this.isOrigin, required this.text});
  final bool isOrigin;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              shape: isOrigin ? BoxShape.circle : BoxShape.rectangle,
              borderRadius: isOrigin ? null : BorderRadius.circular(4),
              border: Border.all(
                color: isOrigin
                    ? const Color(0xFF94A3B8)
                    : const Color(0xFF0F172A),
                width: 2,
              ),
            ),
            child: isOrigin
                ? null
                : Center(
                    child: Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F172A),
                        borderRadius: BorderRadius.circular(1),
                      ),
                    ),
                  ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1F2937),
              height: 1.25,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
