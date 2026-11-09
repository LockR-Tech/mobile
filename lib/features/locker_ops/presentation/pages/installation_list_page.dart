import 'package:flutter/material.dart';
import 'package:smart_laundry_locker/core/l10n/l10n.dart';
import 'package:smart_laundry_locker/features/locker_ops/data/installation_api.dart';
import 'package:smart_laundry_locker/features/locker_ops/data/locker_ops_service.dart';
import 'package:smart_laundry_locker/features/locker_ops/presentation/pages/installation_detail_page.dart';
import 'package:smart_laundry_locker/features/locker_ops/presentation/widgets/installation_widgets.dart';
import 'package:smart_laundry_locker/features/locker_ops/presentation/widgets/ops_widgets.dart';

/// Hồ sơ lắp đặt tủ admin giao cho KTV (F3-G12). [initialInstallationId] (deep link từ thông báo) ⇒ mở
/// thẳng hồ sơ đó.
class InstallationListPage extends StatefulWidget {
  const InstallationListPage({super.key, this.initialInstallationId, this.api});

  final int? initialInstallationId;
  final InstallationApi? api;

  @override
  State<InstallationListPage> createState() => _InstallationListPageState();
}

class _InstallationListPageState extends State<InstallationListPage> {
  late final InstallationApi _api = widget.api ?? InstallationApi();
  List<Installation> _items = const [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
    final initial = widget.initialInstallationId;
    if (initial != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _open(initial));
    }
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final items = await _api.mine();
      if (!mounted) return;
      setState(() => _items = items);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = LockerOpsService.errorMessage(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _open(int id) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => InstallationDetailPage(installationId: id, api: _api)),
    );
    if (mounted) _load();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FA),
      appBar: AppBar(title: Text(l10n.instListTitle)),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (_loading && _items.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 80),
                child: Center(child: CircularProgressIndicator(color: opsPrimary)),
              )
            else if (_error != null && _items.isEmpty)
              InstallationNotice(icon: Icons.error_outline, color: const Color(0xFFDC2626), text: _error!)
            else if (_items.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 64),
                child: Column(
                  children: [
                    const Icon(Icons.construction_outlined, size: 48, color: Color(0xFF94A3B8)),
                    const SizedBox(height: 12),
                    Text(l10n.instListEmpty, textAlign: TextAlign.center,
                        style: const TextStyle(color: Color(0xFF64748B))),
                  ],
                ),
              )
            else ...[
              Text(l10n.instListHint, style: const TextStyle(fontSize: 12.5, color: Color(0xFF64748B))),
              const SizedBox(height: 12),
              for (final item in _items) ...[
                _InstallationCard(installation: item, onTap: () => _open(item.id)),
                const SizedBox(height: 10),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

class _InstallationCard extends StatelessWidget {
  const _InstallationCard({required this.installation, required this.onTap});

  final Installation installation;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final total = installation.checks.length;
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.construction_outlined, color: opsPrimary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(installation.displayName,
                        style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w700)),
                  ),
                  InstallationStatusChip(status: installation.status),
                ],
              ),
              const SizedBox(height: 8),
              if (installation.scheduledAt != null)
                Text(l10n.instScheduledAt(formatInstallationTime(installation.scheduledAt)),
                    style: const TextStyle(fontSize: 13, color: Color(0xFF475569))),
              if (total > 0) ...[
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: installation.doneCount / total,
                    minHeight: 6,
                    color: const Color(0xFF10B981),
                    backgroundColor: const Color(0xFFE2E8F0),
                  ),
                ),
                const SizedBox(height: 4),
                Text(l10n.instProgress(installation.doneCount, total),
                    style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
              ],
              if (installation.returnReason != null && installation.status == InstallationStatus.inProgress) ...[
                const SizedBox(height: 8),
                Text(l10n.instReturnedReason(installation.returnReason!),
                    style: const TextStyle(fontSize: 12.5, color: Color(0xFFB45309))),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
