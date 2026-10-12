import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:smart_laundry_locker/features/locker_ops/data/locker_ops_service.dart';
import 'package:smart_laundry_locker/features/locker_ops/data/receiver_order.dart';
import 'package:smart_laundry_locker/features/locker_ops/presentation/utils/locker_maps.dart';
import 'package:smart_laundry_locker/features/locker_ops/presentation/widgets/locker_unlock_modal.dart';
import 'package:smart_laundry_locker/features/locker_ops/presentation/widgets/ops_widgets.dart';

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
    snack('Đơn chưa có mã lấy hàng — hàng có thể chưa được bỏ vào ô.');
    return false;
  }

  final action = await LockerUnlockModal.show(
    context,
    lockerName: order.lockerName ?? 'Tủ Lock.R',
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

  snack('Đang gửi lệnh mở ${order.boxLabel} tới tủ...');
  try {
    final res = await service.unlockWithCode(lockerId, pin);
    final accepted = res['accepted'] == true;
    final msg = res['message']?.toString();
    snack(
      accepted
          ? 'Tủ đã mở ${order.boxLabel} — lấy hàng rồi đóng cửa tủ lại.'
          : 'Không mở được ${order.boxLabel}'
                '${msg != null && msg.isNotEmpty ? ': $msg' : ''}',
    );
    return accepted;
  } catch (e) {
    snack(
      LockerOpsService.isEndpointUnavailable(e)
          ? 'Máy chủ chưa hỗ trợ mở ô bằng mã. Hãy nhập mã tại màn hình tủ.'
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
    DirectionsResult.noLocation => 'Tủ chưa có vị trí để chỉ đường.',
    DirectionsResult.launchFailed =>
      'Không mở được ứng dụng bản đồ trên máy này.',
  };
  if (msg != null) {
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(msg)));
  }
}

/// Thẻ một đơn phía người nhận: người gửi, tủ/ô, hạn lấy, mã lấy hàng khi đã sẵn
/// sàng, nút mở ô và chỉ đường.
class ReceiverOrderCard extends StatelessWidget {
  const ReceiverOrderCard({
    super.key,
    required this.order,
    required this.onUnlock,
    required this.onDirections,
    this.delegatedView = false,
  });

  final ReceiverOrder order;
  final VoidCallback onUnlock;
  final VoidCallback onDirections;

  /// `true` ở màn "Đơn ủy quyền" (mình là người lấy hộ).
  final bool delegatedView;

  @override
  Widget build(BuildContext context) {
    final status =
        (order.type == 'DRONE_DELIVERY' &&
            (order.deliveryStage ?? '').isNotEmpty)
        ? order.deliveryStage
        : order.status;
    final hasLocation =
        order.lockerLatitude != null && order.lockerLongitude != null ||
        (order.lockerAddress ?? '').isNotEmpty;
    final lockerLine = [
      order.lockerName ?? 'Tủ Lock.R',
      if ((order.lockerCode ?? '').isNotEmpty) '(${order.lockerCode})',
    ].join(' ');
    final ownerLabel = delegatedView ? 'Người ủy quyền' : 'Người gửi';

    return OpsCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  order.displayCode,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14.5,
                    color: opsDark,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              StatusChip(status),
            ],
          ),
          const SizedBox(height: 8),
          if ((order.senderName ?? '').isNotEmpty)
            OpsInfoRow(
              icon: LucideIcons.user,
              label: ownerLabel,
              value: order.senderName!,
            ),
          OpsInfoRow(
            icon: LucideIcons.warehouse,
            label: 'Tủ',
            value: lockerLine,
          ),
          if ((order.lockerAddress ?? '').isNotEmpty)
            OpsInfoRow(
              icon: LucideIcons.mapPin,
              label: 'Địa điểm',
              value: order.lockerAddress!,
            ),
          if (order.boxNumber != null)
            OpsInfoRow(
              icon: LucideIcons.grid3x3,
              label: 'Ô',
              value: 'Ô số ${order.boxNumber}',
            ),
          if (order.pickupDeadline != null)
            OpsInfoRow(
              icon: LucideIcons.clock,
              label: 'Hạn lấy',
              value: fmtDateTime(order.pickupDeadline!.toIso8601String()),
              valueColor: order.overdue ? const Color(0xFFDC2626) : null,
            ),
          if (delegatedView && (order.delegateNote ?? '').isNotEmpty)
            OpsInfoRow(
              icon: LucideIcons.stickyNote,
              label: 'Lời nhắn',
              value: order.delegateNote!,
            ),
          const SizedBox(height: 10),
          if (!delegatedView && order.delegated)
            const OpsBanner(
              tone: OpsBannerTone.info,
              icon: LucideIcons.userCheck,
              text:
                  'Chủ đơn đã ủy quyền người khác lấy hộ nên mã lấy hàng không '
                  'còn hiện ở đây.',
            )
          else if (order.isActive && (order.pickupPin ?? '').isNotEmpty) ...[
            Center(
              child: AccessCredentials(
                pin: order.pickupPin,
                qrToken: order.qrToken,
                caption: 'Nhập PIN tại tủ hoặc mở ô ngay trên app',
              ),
            ),
            if (order.overdue) ...[
              const SizedBox(height: 8),
              const OpsBanner(
                tone: OpsBannerTone.danger,
                icon: LucideIcons.triangleAlert,
                text: 'Đơn đã quá hạn lấy — có thể phát sinh phí quá giờ.',
              ),
            ],
          ] else if (!order.isFinished)
            const OpsBanner(
              tone: OpsBannerTone.info,
              icon: LucideIcons.hourglass,
              text:
                  'Hàng chưa sẵn sàng. Mã lấy hàng sẽ hiện khi hàng đã nằm trong ô.',
            ),
          const SizedBox(height: 10),
          if (order.canUnlockWithCode)
            OpsSheetAction(
              label: 'Mở ${order.boxLabel} lấy hàng',
              icon: LucideIcons.doorOpen,
              primary: true,
              onTap: onUnlock,
            ),
          if (hasLocation && !order.isFinished)
            OpsSheetAction(
              label: 'Chỉ đường tới tủ',
              icon: LucideIcons.map,
              onTap: onDirections,
            ),
        ],
      ),
    );
  }
}
