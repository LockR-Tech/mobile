import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:smart_laundry_locker/core/l10n/l10n.dart';
import 'package:smart_laundry_locker/features/locker_ops/data/installation_api.dart';
import 'package:smart_laundry_locker/features/locker_ops/data/locker_ops_service.dart';
import 'package:smart_laundry_locker/features/locker_ops/presentation/widgets/installation_widgets.dart';
import 'package:smart_laundry_locker/features/locker_ops/presentation/widgets/ops_widgets.dart';

/// Gán bộ điều khiển (Pi) vào tủ đang lắp: quét QR `LOCKR-PI:<MAC>` trên màn kiosk của Pi chưa gán;
/// không quét được thì chọn trong danh sách Pi đang online chưa gán tủ. Trả `true` khi đã gửi lệnh gán.
class ControllerPairingSheet extends StatefulWidget {
  const ControllerPairingSheet({super.key, required this.lockerId, required this.api});

  final int lockerId;
  final InstallationApi api;

  static Future<bool?> show(BuildContext context, {required int lockerId, required InstallationApi api}) =>
      showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        useRootNavigator: true,
        backgroundColor: Colors.white,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        builder: (_) => ControllerPairingSheet(lockerId: lockerId, api: api),
      );

  @override
  State<ControllerPairingSheet> createState() => _ControllerPairingSheetState();
}

class _ControllerPairingSheetState extends State<ControllerPairingSheet> {
  final MobileScannerController _scanner = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    facing: CameraFacing.back,
  );
  bool _scanMode = true;
  bool _binding = false;
  String? _error;
  List<ControllerCandidate>? _candidates;
  bool _loadingCandidates = false;

  @override
  void dispose() {
    _scanner.dispose();
    super.dispose();
  }

  Future<void> _bind(String raw) async {
    if (_binding) return;
    final mac = parseControllerMac(raw);
    if (mac == null) {
      HapticFeedback.vibrate();
      setState(() => _error = context.l10n.instPairInvalidQr);
      return;
    }
    setState(() {
      _binding = true;
      _error = null;
    });
    try {
      await widget.api.bindController(widget.lockerId, mac);
      HapticFeedback.mediumImpact();
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = LockerOpsService.errorMessage(e));
    } finally {
      if (mounted) setState(() => _binding = false);
    }
  }

  Future<void> _showCandidates() async {
    setState(() {
      _scanMode = false;
      _loadingCandidates = true;
      _error = null;
    });
    try {
      final list = await widget.api.controllerCandidates(widget.lockerId);
      if (mounted) setState(() => _candidates = list);
    } catch (e) {
      if (mounted) setState(() => _error = LockerOpsService.errorMessage(e));
    } finally {
      if (mounted) setState(() => _loadingCandidates = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final height = MediaQuery.of(context).size.height * 0.82;
    return SafeArea(
      child: SizedBox(
        height: height,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(color: const Color(0xFFCBD5E1), borderRadius: BorderRadius.circular(4)),
                ),
              ),
              const SizedBox(height: 12),
              Text(l10n.instPairTitle, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              Text(l10n.instPairHint, style: const TextStyle(fontSize: 13, color: Color(0xFF475569), height: 1.35)),
              const SizedBox(height: 12),
              SegmentedButton<bool>(
                segments: [
                  ButtonSegment(value: true, icon: const Icon(Icons.qr_code_scanner), label: Text(l10n.instPairScan)),
                  ButtonSegment(value: false, icon: const Icon(Icons.list_alt), label: Text(l10n.instPairPick)),
                ],
                selected: {_scanMode},
                onSelectionChanged: (value) {
                  if (value.first) {
                    setState(() {
                      _scanMode = true;
                      _error = null;
                    });
                  } else {
                    _showCandidates();
                  }
                },
              ),
              const SizedBox(height: 12),
              if (_error != null) ...[
                InstallationNotice(icon: Icons.error_outline, color: const Color(0xFFDC2626), text: _error!),
                const SizedBox(height: 12),
              ],
              Expanded(child: _scanMode ? _buildScanner(context) : _buildCandidates(context)),
              if (_binding) ...[
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: opsPrimary),
                    ),
                    const SizedBox(width: 10),
                    Text(l10n.instPairBinding),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScanner(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Stack(
        fit: StackFit.expand,
        children: [
          MobileScanner(
            controller: _scanner,
            onDetect: (capture) {
              if (_binding) return;
              final raw = capture.barcodes.isEmpty ? null : capture.barcodes.first.rawValue;
              if (raw != null && raw.trim().isNotEmpty) _bind(raw);
            },
          ),
          Center(
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 3),
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCandidates(BuildContext context) {
    final l10n = context.l10n;
    if (_loadingCandidates) {
      return const Center(child: CircularProgressIndicator(color: opsPrimary));
    }
    final list = _candidates ?? const <ControllerCandidate>[];
    return RefreshIndicator(
      onRefresh: _showCandidates,
      child: ListView(
        children: [
          if (list.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 32),
              child: Text(l10n.instPairNoCandidates,
                  textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFF64748B))),
            )
          else ...[
            Text(l10n.instPairPickHint, style: const TextStyle(fontSize: 12.5, color: Color(0xFF64748B))),
            const SizedBox(height: 8),
            for (final c in list)
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                child: ListTile(
                  leading: Icon(Icons.memory, color: c.online ? const Color(0xFF059669) : const Color(0xFF94A3B8)),
                  title: Text(c.macAddress,
                      style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.w700)),
                  subtitle: Text(c.lockerId == widget.lockerId
                      ? l10n.instPairAlreadyThisLocker
                      : l10n.instPairLastSeen(formatInstallationTime(c.lastSeenAt))),
                  trailing: FilledButton(
                    onPressed: _binding ? null : () => _bind(c.macAddress),
                    child: Text(l10n.instPairBind),
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}
