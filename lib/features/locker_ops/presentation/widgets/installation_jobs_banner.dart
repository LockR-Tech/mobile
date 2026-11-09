import 'package:flutter/material.dart';
import 'package:smart_laundry_locker/core/l10n/l10n.dart';
import 'package:smart_laundry_locker/features/locker_ops/data/installation_api.dart';
import 'package:smart_laundry_locker/features/locker_ops/presentation/pages/installation_list_page.dart';
import 'package:smart_laundry_locker/features/locker_ops/presentation/widgets/ops_widgets.dart';

/// Băng báo "có N hồ sơ lắp đặt tủ đang mở" ở trang chủ KTV tủ; không có hồ sơ (hoặc lỗi) thì ẩn.
class InstallationJobsBanner extends StatefulWidget {
  const InstallationJobsBanner({super.key, this.api});

  final InstallationApi? api;

  @override
  State<InstallationJobsBanner> createState() => _InstallationJobsBannerState();
}

class _InstallationJobsBannerState extends State<InstallationJobsBanner> {
  late final InstallationApi _api = widget.api ?? InstallationApi();
  int _count = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final items = await _api.mine();
      if (mounted) setState(() => _count = items.length);
    } catch (_) {
      // Backend chưa có API lắp đặt / mất mạng ⇒ không hiện băng báo.
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_count == 0) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        key: const ValueKey('technician-installation-banner'),
        borderRadius: BorderRadius.circular(14),
        onTap: () async {
          await Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => InstallationListPage(api: _api)),
          );
          _load();
        },
        child: OpsBanner(
          icon: Icons.construction_outlined,
          title: context.l10n.instHomeBanner(_count),
          text: context.l10n.instListHint,
        ),
      ),
    );
  }
}
