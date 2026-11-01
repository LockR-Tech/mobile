import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:smart_laundry_locker/features/payment/data/vietqr_service.dart';
import 'package:smart_laundry_locker/features/payment/domain/sepay_transfer.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:smart_laundry_locker/core/l10n/l10n.dart';

/// Mở link [url] ra ngoài app; `false` khi không có app nào nhận.
typedef ExternalUrlLauncher = Future<bool> Function(Uri url);

Future<bool> _launchExternal(Uri url) async {
  try {
    return await launchUrl(url, mode: LaunchMode.externalApplication);
  } catch (e) {
    debugPrint('Open bank app failed: $e');
    return false;
  }
}

/// "Thanh toán bằng app ngân hàng": chọn app ngân hàng (danh sách deeplink của
/// VietQR, chỉ app hỗ trợ tự điền) rồi mở app với STK, số tiền và nội dung
/// chuyển khoản đã điền sẵn — khách chỉ cần xác nhận. Quay lại app, màn thanh
/// toán tự kiểm tra lại trạng thái đơn.
///
/// Trả `true` khi đã mở được app ngân hàng.
Future<bool> showBankAppPicker(
  BuildContext context, {
  required SepayTransfer transfer,
  VietQrService? service,
  ExternalUrlLauncher? launcher,
}) async {
  final opened = await showModalBottomSheet<bool>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    showDragHandle: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
    ),
    builder: (_) => BankAppPickerSheet(
      transfer: transfer,
      service: service ?? VietQrService.instance,
      launcher: launcher ?? _launchExternal,
    ),
  );
  return opened == true;
}

class BankAppPickerSheet extends StatefulWidget {
  const BankAppPickerSheet({
    super.key,
    required this.transfer,
    required this.service,
    required this.launcher,
  });

  final SepayTransfer transfer;
  final VietQrService service;
  final ExternalUrlLauncher launcher;

  @override
  State<BankAppPickerSheet> createState() => _BankAppPickerSheetState();
}

class _BankAppPickerSheetState extends State<BankAppPickerSheet> {
  late Future<List<VietQrBankApp>> _apps;
  late final Future<String?> _bankCode;
  final _search = TextEditingController();
  String _query = '';
  String? _error;
  bool _opening = false;

  @override
  void initState() {
    super.initState();
    _apps = _loadApps();
    final bin = widget.transfer.bankBin;
    _bankCode = bin == null
        ? Future<String?>.value()
        : widget.service.bankCodeForBin(bin);
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<List<VietQrBankApp>> _loadApps() => widget.service.bankApps(
    ios: !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS,
  );

  Future<void> _open(VietQrBankApp app) async {
    final t = widget.transfer;
    setState(() {
      _opening = true;
      _error = null;
    });
    final code = await _bankCode;
    if (!mounted) return;
    if (code == null || !t.canOpenBankApp) {
      setState(() {
        _opening = false;
        _error =
            context.l10n.bankUnknown;
      });
      return;
    }
    final url = buildVietQrPayDeeplink(
      appId: app.appId,
      accountNo: t.accountNo!,
      bankCode: code,
      amount: t.amount!,
      transferContent: t.transferContent!,
    );
    final ok = await widget.launcher(Uri.parse(url));
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pop(true);
      return;
    }
    setState(() {
      _opening = false;
      _error =
          context.l10n.bankCantOpen(app.appName);
    });
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.sizeOf(context).height * 0.75;
    return SizedBox(
      height: height,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          0,
          20,
          MediaQuery.viewInsetsOf(context).bottom + 12,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              context.l10n.bankTitle,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 17,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              context.l10n.bankIntro,
              style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _search,
              onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
              decoration: InputDecoration(
                hintText: context.l10n.bankSearch,
                prefixIcon: const Icon(LucideIcons.search, size: 18),
                isDense: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFFECACA)),
                ),
                child: Text(
                  _error!,
                  style: const TextStyle(color: Color(0xFFB91C1C), fontSize: 13),
                ),
              ),
            ],
            const SizedBox(height: 8),
            Expanded(
              child: FutureBuilder<List<VietQrBankApp>>(
                future: _apps,
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final apps = snapshot.data ?? const <VietQrBankApp>[];
                  if (snapshot.hasError || apps.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            context.l10n.bankLoadFailed,
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Color(0xFF64748B)),
                          ),
                          TextButton(
                            onPressed: () =>
                                setState(() => _apps = _loadApps()),
                            child: Text(context.l10n.commonRetry),
                          ),
                        ],
                      ),
                    );
                  }
                  final filtered = _query.isEmpty
                      ? apps
                      : apps
                            .where(
                              (a) =>
                                  a.appName.toLowerCase().contains(_query) ||
                                  a.appId.toLowerCase().contains(_query),
                            )
                            .toList();
                  if (filtered.isEmpty) {
                    return Center(
                      child: Text(
                        context.l10n.bankNoMatch,
                        style: TextStyle(color: Color(0xFF64748B)),
                      ),
                    );
                  }
                  return ListView.separated(
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, i) {
                      final app = filtered[i];
                      return ListTile(
                        enabled: !_opening,
                        contentPadding: EdgeInsets.zero,
                        leading: _BankLogo(url: app.appLogo),
                        title: Text(
                          app.appName,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        trailing: const Icon(LucideIcons.chevronRight, size: 18),
                        onTap: () => _open(app),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BankLogo extends StatelessWidget {
  const _BankLogo({this.url});
  final String? url;

  @override
  Widget build(BuildContext context) {
    const fallback = Icon(LucideIcons.landmark, color: Color(0xFF0284C7));
    final src = url;
    return SizedBox(
      width: 40,
      height: 40,
      child: src == null || src.isEmpty
          ? fallback
          : ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                src,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => fallback,
              ),
            ),
    );
  }
}
