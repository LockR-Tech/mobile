import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:smart_laundry_locker/features/locker_ops/data/locker_ops_service.dart';
import 'package:smart_laundry_locker/features/locker_ops/presentation/widgets/locker_picker.dart';
import 'package:smart_laundry_locker/features/locker_ops/presentation/widgets/locker_qr_scanner_dialog.dart';
import 'package:smart_laundry_locker/features/locker_ops/presentation/widgets/ops_widgets.dart';
import 'package:smart_laundry_locker/shared/widgets/user_ui_kit.dart';

/// "Mở tủ ủy quyền": người lấy hộ (hoặc người nhận) chọn tủ, nhập mã lấy hàng
/// rồi mở ô qua `POST /api/iot/unlock-with-code {lockerId, code}` — server tự tra
/// ô theo mã. Trước khi gửi lệnh, xác nhận đang đứng tại tủ bằng tem QR (hoặc
/// gõ mã tủ).
class AuthorizedOpeningPage extends StatefulWidget {
  const AuthorizedOpeningPage({
    super.key,
    this.orderId,
    this.orderCode,
    this.lockerId,
    this.accessCode,
    this.service,
  });

  final String? orderId;
  final String? orderCode;
  final String? lockerId;
  final String? accessCode;
  final LockerOpsService? service;

  @override
  State<AuthorizedOpeningPage> createState() => _AuthorizedOpeningPageState();
}

class _AuthorizedOpeningPageState extends State<AuthorizedOpeningPage> {
  late final LockerOpsService _service = widget.service ?? LockerOpsService();
  final _codeCtrl = TextEditingController();

  List<Map<String, dynamic>> _lockers = const [];
  int? _lockerId;
  bool _loadingLockers = true;
  String? _lockersError;
  bool _opening = false;
  String? _result;
  bool _resultOk = false;

  @override
  void initState() {
    super.initState();
    _codeCtrl.text = widget.accessCode ?? '';
    _lockerId = int.tryParse(widget.lockerId ?? '');
    _loadLockers();
  }

  @override
  void dispose() {
    _codeCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadLockers() async {
    setState(() {
      _loadingLockers = true;
      _lockersError = null;
    });
    try {
      final lockers = await _service.lockers();
      if (!mounted) return;
      setState(() {
        _lockers = lockers.where((l) => l['id'] is num).toList();
        _loadingLockers = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadingLockers = false;
        _lockersError = LockerOpsService.errorMessage(e);
      });
    }
  }

  Map<String, dynamic>? get _selectedLocker {
    for (final l in _lockers) {
      if ((l['id'] as num?)?.toInt() == _lockerId) return l;
    }
    return null;
  }

  Future<void> _open() async {
    final lockerId = _lockerId;
    final code = _codeCtrl.text.trim();
    if (lockerId == null) {
      setState(() {
        _result = 'Vui lòng chọn tủ.';
        _resultOk = false;
      });
      return;
    }
    if (code.length < 4) {
      setState(() {
        _result = 'Vui lòng nhập mã lấy hàng.';
        _resultOk = false;
      });
      return;
    }
    final locker = _selectedLocker;
    final atLocker = await LockerQrScannerDialog.show(
      context,
      expectedLockerCode: locker?['code']?.toString() ?? '',
      expectedLockerId: lockerId,
      lockerName: locker?['name']?.toString(),
      boxLabel: 'ô lấy hàng',
    );
    if (atLocker != true || !mounted) return;

    setState(() {
      _opening = true;
      _result = null;
    });
    try {
      final res = await _service.unlockWithCode(lockerId, code);
      final accepted = res['accepted'] == true;
      final msg = res['message']?.toString();
      if (!mounted) return;
      setState(() {
        _resultOk = accepted;
        _result = accepted
            ? 'Tủ đã mở ô — lấy hàng rồi đóng cửa tủ lại.'
            : 'Không mở được ô${msg != null && msg.isNotEmpty ? ': $msg' : '.'}';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _resultOk = false;
        _result = LockerOpsService.isEndpointUnavailable(e)
            ? 'Máy chủ chưa hỗ trợ mở ô bằng mã. Hãy nhập mã tại màn hình tủ.'
            : LockerOpsService.errorMessage(e);
      });
    } finally {
      if (mounted) setState(() => _opening = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F3F5),
      body: Column(
        children: [
          BrandHeroHeader(
            title: 'Mở tủ ủy quyền',
            subtitle: 'Lấy hàng bằng mã được gửi cho bạn',
            onBack: () => Navigator.of(context).maybePop(),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const OpsBanner(
                  icon: LucideIcons.keyRound,
                  text:
                      'Nhập mã lấy hàng (PIN) bạn nhận được — mã có trong mục "Đơn ủy quyền" '
                      'hoặc do người gửi chuyển cho bạn. Bạn cần đứng tại tủ để mở ô.',
                ),
                if ((widget.orderCode ?? '').isNotEmpty) ...[
                  const SizedBox(height: 12),
                  OpsInfoRow(
                    icon: LucideIcons.hash,
                    label: 'Đơn',
                    value: widget.orderCode!,
                  ),
                ],
                const SizedBox(height: 20),
                const OpsSectionLabel('Chọn tủ', icon: LucideIcons.warehouse),
                if (_loadingLockers)
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (_lockersError != null && _lockers.isEmpty)
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _lockersError!,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFFDC2626),
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: _loadLockers,
                        child: const Text('Thử lại'),
                      ),
                    ],
                  )
                else
                  LockerPickerField(
                    lockers: _lockers,
                    selectedId: _lockerId,
                    placeholder: 'Chạm để chọn tủ lấy hàng',
                    onSelected: (l) =>
                        setState(() => _lockerId = (l['id'] as num?)?.toInt()),
                  ),
                const SizedBox(height: 20),
                const OpsSectionLabel(
                  'Mã lấy hàng',
                  icon: LucideIcons.keyRound,
                ),
                TextField(
                  controller: _codeCtrl,
                  enabled: !_opening,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  maxLength: 8,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 6,
                  ),
                  decoration: InputDecoration(
                    hintText: '••••••',
                    counterText: '',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: opsBorder),
                    ),
                  ),
                ),
                if (_result != null) ...[
                  const SizedBox(height: 12),
                  OpsBanner(
                    tone: _resultOk
                        ? OpsBannerTone.success
                        : OpsBannerTone.danger,
                    icon: _resultOk
                        ? LucideIcons.circleCheck
                        : LucideIcons.circleX,
                    text: _result!,
                  ),
                ],
                const SizedBox(height: 20),
                OpsPrimaryButton(
                  label: 'Mở ô lấy hàng',
                  icon: LucideIcons.doorOpen,
                  loading: _opening,
                  onPressed: _opening ? null : _open,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
