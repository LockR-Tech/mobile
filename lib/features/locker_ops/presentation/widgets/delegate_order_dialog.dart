import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:smart_laundry_locker/features/locker_ops/data/locker_ops_service.dart';
import 'package:smart_laundry_locker/features/locker_ops/presentation/widgets/ops_widgets.dart';
import 'package:smart_laundry_locker/shared/widgets/controller_disposer.dart';

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
          title: const Text('Ủy quyền lấy hộ'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Người được ủy quyền thấy đơn và mã mở ô trong mục "Đơn ủy quyền" '
                  'của app (theo số điện thoại). Mã PIN hiện tại sẽ được đổi mới.',
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
                  decoration: const InputDecoration(
                    labelText: 'Số điện thoại người lấy hộ',
                    counterText: '',
                  ),
                ),
                TextField(
                  controller: nameCtrl,
                  enabled: !sending,
                  maxLength: 100,
                  decoration: const InputDecoration(
                    labelText: 'Tên người lấy hộ (không bắt buộc)',
                    counterText: '',
                  ),
                ),
                TextField(
                  controller: noteCtrl,
                  enabled: !sending,
                  maxLines: 2,
                  maxLength: 500,
                  decoration: const InputDecoration(
                    labelText: 'Lời nhắn (không bắt buộc)',
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
              child: const Text('Hủy'),
            ),
            FilledButton(
              onPressed: sending
                  ? null
                  : () async {
                      final phone = phoneCtrl.text.trim();
                      if (!isPlausiblePhone(phone)) {
                        setLocal(
                          () => error = 'Nhập số điện thoại hợp lệ (9–11 số).',
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
                              ? 'Máy chủ chưa hỗ trợ ủy quyền lấy hộ.'
                              : LockerOpsService.errorMessage(e);
                        });
                      }
                    },
              child: Text(sending ? 'Đang gửi...' : 'Ủy quyền'),
            ),
          ],
        ),
      ),
    ),
  );
  return result;
}
