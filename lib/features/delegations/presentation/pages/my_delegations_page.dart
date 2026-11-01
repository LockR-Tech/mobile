import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import 'package:smart_laundry_locker/features/delegations/presentation/providers/delegation_provider.dart';
import 'package:smart_laundry_locker/features/locker_ops/data/receiver_order.dart';
import 'package:smart_laundry_locker/features/locker_ops/presentation/pages/receiver_order_detail_page.dart';
import 'package:smart_laundry_locker/features/locker_ops/presentation/widgets/ops_widgets.dart';
import 'package:smart_laundry_locker/features/locker_ops/presentation/widgets/receiver_order_card.dart';
import 'package:smart_laundry_locker/shared/widgets/user_ui_kit.dart';
import 'package:smart_laundry_locker/core/l10n/l10n.dart';

/// "Đơn ủy quyền": các đơn người khác ủy quyền cho mình lấy hộ (theo SĐT tài
/// khoản), kèm mã lấy hàng khi hàng đã sẵn sàng, mở ô và chỉ đường.
class MyDelegationsPage extends StatelessWidget {
  const MyDelegationsPage({super.key, this.provider});

  /// Cho test truyền provider có service giả.
  final DelegationProvider? provider;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => (provider ?? DelegationProvider())..fetchMyDelegations(),
      child: const _MyDelegationsView(),
    );
  }
}

class _MyDelegationsView extends StatelessWidget {
  const _MyDelegationsView();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DelegationProvider>();
    return Scaffold(
      backgroundColor: const Color(0xFFF2F3F5),
      body: BrandHeroScaffold(
        header: (collapse) => BrandHeroHeader(
          title: context.l10n.profileDelegations,
          subtitle: context.l10n.mdSubtitle,
          onBack: () => Navigator.of(context).maybePop(),
          collapseProgress: collapse,
          trailing: BrandCircleIconButton(
            icon: LucideIcons.refreshCw,
            onTap: provider.fetchMyDelegations,
            iconSize: 18,
          ),
        ),
        child: Builder(builder: (context) => _body(context, provider)),
      ),
    );
  }

  Widget _body(BuildContext context, DelegationProvider provider) {
    final orders = provider.myDelegations;
    if (provider.isLoading && orders.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: AislBrand.navy),
      );
    }
    if (provider.error != null && orders.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(LucideIcons.cloudOff, size: 36, color: opsMutedText),
              const SizedBox(height: 10),
              Text(
                provider.error!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13.5, color: opsDark),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: provider.fetchMyDelegations,
                child: Text(context.l10n.commonRetry),
              ),
            ],
          ),
        ),
      );
    }
    if (orders.isEmpty) {
      return RefreshIndicator(
        color: AislBrand.navy,
        onRefresh: provider.fetchMyDelegations,
        child: ListView(
          children: [
            SizedBox(height: 40),
            OpsEmptyState(
              icon: LucideIcons.packageOpen,
              title: context.l10n.mdEmpty,
              subtitle:
                  context.l10n.mdEmptyHint,
            ),
          ],
        ),
      );
    }
    final sorted = [...orders]
      ..sort((a, b) {
        if (a.isActive != b.isActive) return a.isActive ? -1 : 1;
        final da = a.delegatedAt ?? a.createdAt;
        final db = b.delegatedAt ?? b.createdAt;
        if (da == null || db == null) return 0;
        return db.compareTo(da);
      });
    return RefreshIndicator(
      color: AislBrand.navy,
      onRefresh: provider.fetchMyDelegations,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        itemCount: sorted.length,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (ctx, i) {
          final ReceiverOrder order = sorted[i];
          return ReceiverOrderCard(
            order: order,
            delegatedView: true,
            onUnlock: () async {
              final opened = await openReceiverOrderBox(
                ctx,
                service: provider.service,
                order: order,
              );
              if (opened) await provider.fetchMyDelegations();
            },
            onDirections: () => openReceiverOrderDirections(ctx, order),
            onTap: () async {
              await ReceiverOrderDetailPage.open(
                ctx,
                order: order,
                service: provider.service,
                delegatedView: true,
              );
              await provider.fetchMyDelegations();
            },
          );
        },
      ),
    );
  }
}
