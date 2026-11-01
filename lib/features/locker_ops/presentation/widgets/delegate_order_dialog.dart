import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:smart_laundry_locker/features/locker_ops/data/locker_ops_service.dart';
import 'package:smart_laundry_locker/features/locker_ops/presentation/widgets/ops_widgets.dart';
import 'package:smart_laundry_locker/shared/widgets/controller_disposer.dart';
import 'package:smart_laundry_locker/core/l10n/l10n.dart';

/// SĐT Việt Nam gõ tay: 9–11 chữ số (0xxx… hoặc 84xxx…).
bool isPlausiblePhone(String value) =>
    RegExp(r'^\d{9,11}$').hasMatch(value.trim());

/// "Ủy quyền lấy hộ": nhập SĐT (bắt buộc), tên và lời nhắn rồi gọi
/// `POST /api/orders/{id}/delegate`. Trả response đơn sau khi ủy quyền
/// (có PIN mới) hoặc `null` khi khách huỷ.
Future<Map<String, dynamic>?> showDelegateOrderDialog(
  BuildContext context, {
  required LockerOpsService service,
  required int orderId,
}) async {
  final phoneCtrl = TextEditingController();
  final nameCtrl = TextEditingController();
  final noteCtrl = TextEditingController();
  var sending = false;
  String? error;
  Map<String, dynamic>? result;
  await showDialog<void>(
    context: context,
    barrierDismissible: false,
    // Controller huỷ khi dialog gỡ khỏi cây (sau hiệu ứng đóng).
    builder: (ctx) => ControllerDisposer(
      controllers: [phoneCtrl, nameCtrl, noteCtrl],
      child: StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: Text(context.l10n.delegateTitle),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.delegateBody,
                  style: TextStyle(
                    fontSize: 12.5,
                    color: opsMutedText,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: phoneCtrl,
                  enabled: !sending,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  maxLength: 11,
                  decoration: InputDecoration(
                    labelText: context.l10n.delegatePhone,
                    counterText: '',
                  ),
                ),
                TextField(
                  controller: nameCtrl,
                  enabled: !sending,
                  maxLength: 100,
                  decoration: InputDecoration(
                    labelText: context.l10n.delegateName,
                    counterText: '',
                  ),
                ),
                TextField(
                  controller: noteCtrl,
                  enabled: !sending,
                  maxLines: 2,
                  maxLength: 500,
                  decoration: InputDecoration(
                    labelText: context.l10n.delegateMessage,
                    counterText: '',
                  ),
                ),
                if (error != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    error!,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFFDC2626),
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: sending ? null : () => Navigator.pop(ctx),
              child: Text(context.l10n.commonCancel),
            ),
            FilledButton(
              onPressed: sending
                  ? null
                  : () async {
                      final phone = phoneCtrl.text.trim();
                      if (!isPlausiblePhone(phone)) {
                        setLocal(
                          () => error = context.l10n.delegateInvalidPhone,
                        );
                        return;
                      }
                      setLocal(() {
                        sending = true;
                        error = null;
                      });
                      try {
                        result = await service.delegate(
                          orderId,
                          phone: phone,
                          name: nameCtrl.text,
                          note: noteCtrl.text,
                        );
                        if (ctx.mounted) Navigator.pop(ctx);
                      } catch (e) {
                        setLocal(() {
                          sending = false;
                          error = LockerOpsService.isEndpointUnavailable(e)
                              ? context.l10n.delegateNotSupported
                              : LockerOpsService.errorMessage(e);
                        });
                      }
                    },
              child: Text(sending ? context.l10n.commonSending : context.l10n.delegateAction),
            ),
          ],
        ),
      ),
    ),
  );
  return result;
}
