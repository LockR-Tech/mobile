import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gal/gal.dart';
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

/// Lưu ảnh mã VietQR ở [url] vào Thư viện ảnh với tên [name]; `false` khi
/// không lưu được (không cấp quyền, tải ảnh lỗi…).
typedef QrGallerySaver = Future<bool> Function(String url, String name);

Future<bool> _saveQrToGallery(String url, String name) async {
  try {
    if (!await Gal.hasAccess() && !await Gal.requestAccess()) return false;
    final response = await Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 15),
      ),
    ).get<List<int>>(url, options: Options(responseType: ResponseType.bytes));
    final bytes = response.data;
    if (bytes == null || bytes.isEmpty) return false;
    await Gal.putImageBytes(Uint8List.fromList(bytes), name: name);
    return true;
  } catch (e) {
    debugPrint('Save VietQR to gallery failed: $e');
    return false;
  }
}

/// "Thanh toán bằng app ngân hàng": chọn app ngân hàng (danh sách của VietQR)
/// rồi mở app đó.
///
/// Link `dl.vietqr.io/pay` trên Android chỉ MỞ app ngân hàng, không chuyển STK,
/// số tiền, nội dung (kiểm 2026-11-07: MB, VCB, VietinBank, Techcombank…
/// đều chuyển hướng tới `intent://#Intent;scheme=…` trống). Cách duy nhất để
/// app ngân hàng tự điền đủ là quét chính mã VietQR — nên trước khi mở app,
/// Lock.R lưu ảnh mã vào Thư viện ảnh, sao chép nội dung chuyển khoản và chỉ
/// khách "Quét QR → chọn ảnh". Quay lại app, màn thanh toán tự kiểm tra đơn.
///
/// Trả `true` khi đã mở được app ngân hàng.
Future<bool> showBankAppPicker(
  BuildContext context, {
  required SepayTransfer transfer,
  VietQrService? service,
  ExternalUrlLauncher? launcher,
  QrGallerySaver? saveQr,
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
      saveQr: saveQr ?? _saveQrToGallery,
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
    required this.saveQr,
  });

  final SepayTransfer transfer;
  final VietQrService service;
  final ExternalUrlLauncher launcher;
  final QrGallerySaver saveQr;

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
        _error = context.l10n.bankUnknown;
      });
      return;
    }

    // Chuẩn bị để app ngân hàng điền sẵn: ảnh mã VietQR trong Thư viện ảnh
    // (quét từ ảnh ⇒ đủ STK, số tiền, nội dung) + nội dung trong bộ nhớ tạm.
    final qr = t.qrImageUrl;
    final saved = qr != null &&
        await widget.saveQr(qr, 'LockR-${_safeName(t.transferContent!)}');
    await Clipboard.setData(ClipboardData(text: t.transferContent!));
    if (!mounted) return;

    final go = await showDialog<bool>(
      context: context,
      builder: (_) => _BankStepsDialog(app: app, transfer: t, qrSaved: saved),
    );
    if (!mounted) return;
    if (go != true) {
      setState(() => _opening = false);
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
      _error = context.l10n.bankCantOpen(app.appName);
    });
  }

  static String _safeName(String content) =>
      content.replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '_');

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

/// Các bước trong app ngân hàng, hiện ngay trước khi rời Lock.R.
class _BankStepsDialog extends StatelessWidget {
  const _BankStepsDialog({
    required this.app,
    required this.transfer,
    required this.qrSaved,
  });

  final VietQrBankApp app;
  final SepayTransfer transfer;
  final bool qrSaved;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final amount = _fmtVnd(transfer.amount!);
    final content = transfer.transferContent!;
    final account = [
      transfer.accountNo!,
      if (transfer.accountName != null) transfer.accountName!,
    ].join(' · ');
    final steps = qrSaved
        ? [
            l10n.bankStepScanQr,
            l10n.bankStepPickImage,
            l10n.bankStepConfirm(amount),
          ]
        : [l10n.bankStepManual(amount, account), l10n.bankStepPaste(content)];
    return AlertDialog(
      title: Text(l10n.bankOpenApp(app.appName)),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: qrSaved
                    ? const Color(0xFFF0FDF4)
                    : const Color(0xFFFFF7ED),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    qrSaved ? LucideIcons.circleCheck : LucideIcons.info,
                    size: 18,
                    color: qrSaved
                        ? const Color(0xFF15803D)
                        : const Color(0xFFC2410C),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      qrSaved ? l10n.bankStepsSaved : l10n.bankStepsNotSaved,
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            for (var i = 0; i < steps.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 11,
                      backgroundColor: const Color(0xFF1E40AF),
                      child: Text(
                        '${i + 1}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        steps[i],
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 4),
            Text(
              l10n.bankStepsBack,
              style: const TextStyle(fontSize: 12.5, color: Color(0xFF64748B)),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(l10n.commonCancel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(l10n.bankOpenApp(app.appName)),
        ),
      ],
    );
  }

  static String _fmtVnd(int amount) {
    final digits = amount.toString();
    final buf = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) buf.write('.');
      buf.write(digits[i]);
    }
    return '$buf' 'đ';
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
