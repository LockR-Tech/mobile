import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:smart_laundry_locker/core/config/business_config_service.dart';

/// Nút "Giả lập thanh toán" cho màn VietQR — chỉ hiện khi admin bật
/// `app.payment.simulation-enabled` (Cài đặt → Thanh toán → Giả lập thanh toán).
/// Bấm ⇒ nhập số tiền (mặc định đủ số), server coi như vừa nhận chuyển khoản
/// đó; nhập ít hơn để thử trường hợp chuyển thiếu. Không có tiền thật.
class PaymentSimulationButton extends StatelessWidget {
  const PaymentSimulationButton({
    super.key,
    required this.defaultAmount,
    required this.onSimulate,
  });

  /// Số tiền điền sẵn (đủ số của giao dịch).
  final num defaultAmount;

  /// Gửi yêu cầu giả lập với số tiền khách nhập.
  final Future<void> Function(num amount) onSimulate;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: BusinessConfigService.instance.listenable,
      builder: (context, config, _) {
        if (!config.paymentSimulationEnabled) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
          child: OutlinedButton.icon(
            key: const Key('payment-simulate'),
            onPressed: () => _simulate(context),
            icon: const Icon(LucideIcons.flaskConical, size: 18),
            label: const Text('Giả lập thanh toán (test)'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 46),
              foregroundColor: const Color(0xFF7C3AED),
              side: const BorderSide(color: Color(0xFFA78BFA), width: 1.2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _simulate(BuildContext context) async {
    final messenger = ScaffoldMessenger.maybeOf(context);
    final amount = await showDialog<num>(
      context: context,
      useRootNavigator: true,
      builder: (_) => _SimulationAmountDialog(defaultAmount: defaultAmount),
    );
    if (amount == null) return;
    try {
      await onSimulate(amount);
    } catch (e) {
      messenger?.showSnackBar(
        SnackBar(content: Text('Không giả lập được: ${_message(e)}')),
      );
    }
  }

  static String _message(Object e) {
    final text = e.toString();
    return text.startsWith('Exception: ') ? text.substring(11) : text;
  }
}

class _SimulationAmountDialog extends StatefulWidget {
  const _SimulationAmountDialog({required this.defaultAmount});

  final num defaultAmount;

  @override
  State<_SimulationAmountDialog> createState() => _SimulationAmountDialogState();
}

class _SimulationAmountDialogState extends State<_SimulationAmountDialog> {
  late final TextEditingController _amount = TextEditingController(
    text: widget.defaultAmount.round().toString(),
  );

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  void _submit() {
    final value = int.tryParse(_amount.text.trim());
    if (value == null || value <= 0) return;
    Navigator.of(context).pop(value);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Giả lập đã chuyển khoản'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Chỉ dùng để test — không có tiền thật. Nhập ít hơn số cần trả để '
            'thử trường hợp chuyển thiếu.',
            style: TextStyle(fontSize: 13),
          ),
          const SizedBox(height: 12),
          TextField(
            key: const Key('payment-simulate-amount'),
            controller: _amount,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(
              labelText: 'Số tiền đã nhận',
              suffixText: 'đ',
            ),
            onSubmitted: (_) => _submit(),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Huỷ'),
        ),
        FilledButton(
          key: const Key('payment-simulate-confirm'),
          onPressed: _submit,
          child: const Text('Giả lập'),
        ),
      ],
    );
  }
}
