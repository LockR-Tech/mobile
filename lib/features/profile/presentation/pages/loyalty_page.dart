import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:smart_laundry_locker/core/config/business_config_provider.dart';
import 'package:smart_laundry_locker/core/services/app_event_bus.dart';
import 'package:smart_laundry_locker/core/theme/shadcn_theme.dart';
import 'package:smart_laundry_locker/core/utils/app_date_time.dart';
import 'package:smart_laundry_locker/core/utils/user_error_message.dart';
import 'package:smart_laundry_locker/features/locker_ops/presentation/utils/business_rules_text.dart';
import 'package:smart_laundry_locker/features/profile/domain/entities/loyalty.dart';
import 'package:smart_laundry_locker/features/profile/infrastructure/data_sources/loyalty_remote_data_source.dart';
import 'package:smart_laundry_locker/shared/shared.dart';
import 'package:smart_laundry_locker/shared/widgets/user_ui_kit.dart';

/// "Điểm thưởng": điểm hiện có, hạng thành viên và lịch sử cộng/trừ điểm.
/// Điểm do backend tự cộng khi đơn hoàn tất (mỗi đơn một lần); dùng điểm để
/// giảm tiền khi đặt đơn. Hạng tính theo tổng điểm đã tích (tiêu điểm không
/// tụt hạng).
class LoyaltyPage extends StatefulWidget {
  const LoyaltyPage({super.key, this.dataSource});

  final LoyaltyRemoteDataSource? dataSource;

  @override
  State<LoyaltyPage> createState() => _LoyaltyPageState();
}

class _LoyaltyPageState extends State<LoyaltyPage>
    with BusinessConfigStateMixin {
  late final LoyaltyRemoteDataSource _dataSource =
      widget.dataSource ?? LoyaltyRemoteDataSource();

  LoyaltySummary? _summary;
  List<PointTransaction> _history = const [];
  bool _loading = true;
  String? _error;
  String? _historyError;
  StreamSubscription<AppEvent>? _eventSub;

  @override
  void initState() {
    super.initState();
    _load();
    // Điểm cộng khi đơn hoàn tất, thu hồi khi hoàn tiền, admin điều chỉnh ⇒
    // cập nhật ngay (tải ngầm, giữ số đang hiện).
    _eventSub = AppEventBus.instance.events.listen((event) {
      if (mounted && event is LoyaltyUpdatedEvent) _load(silent: true);
    });
  }

  @override
  void dispose() {
    _eventSub?.cancel();
    super.dispose();
  }

  Future<void> _load({bool silent = false}) async {
    // Chưa có dữ liệu thì không có gì để giữ ⇒ tải như thường.
    final quiet = silent && _summary != null;
    if (!quiet) {
      setState(() {
        _loading = true;
        _error = null;
        _historyError = null;
      });
    }
    try {
      final summary = await _dataSource.getSummary();
      List<PointTransaction> history = const [];
      String? historyError;
      try {
        history = await _dataSource.getHistory();
      } catch (e) {
        historyError = userErrorMessage(
          e,
          notFound: 'Máy chủ chưa hỗ trợ xem lịch sử điểm.',
        );
      }
      if (!mounted) return;
      setState(() {
        _summary = summary;
        _history = history;
        _historyError = historyError;
        _loading = false;
      });
    } catch (e) {
      if (!mounted || quiet) return;
      setState(() {
        _error = userErrorMessage(
          e,
          notFound: 'Máy chủ chưa hỗ trợ điểm thưởng. Vui lòng thử lại sau.',
        );
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.pageBg,
      body: Column(
        children: [
          BrandHeroHeader(
            title: 'Điểm thưởng',
            subtitle: 'Tích điểm khi đơn hàng hoàn tất',
            onBack: () => Navigator.of(context).pop(),
            trailing: BrandCircleIconButton(
              icon: LucideIcons.refreshCw,
              onTap: () {
                if (!_loading) _load();
              },
            ),
          ),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_loading && _summary == null) {
      return const Center(
        child: AppLoadingIndicator(message: 'Đang tải điểm thưởng...'),
      );
    }
    if (_error != null && _summary == null) {
      return ListView(
        padding: const EdgeInsets.all(32),
        children: [
          const SizedBox(height: 60),
          Icon(LucideIcons.cloudOff, size: 52, color: context.textMuted),
          const SizedBox(height: 14),
          Text(
            _error!,
            textAlign: TextAlign.center,
            style: TextStyle(color: context.textMuted, fontSize: 14),
          ),
          const SizedBox(height: 16),
          Center(
            child: FilledButton.icon(
              onPressed: _load,
              style: FilledButton.styleFrom(
                backgroundColor: AISLShadcnTheme.navyPrimary,
              ),
              icon: const Icon(LucideIcons.refreshCw, size: 16),
              label: const Text('Thử lại'),
            ),
          ),
        ],
      );
    }

    final summary = _summary!;
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          _buildSummaryCard(summary),
          const SizedBox(height: 12),
          _buildRulesCard(),
          const SizedBox(height: 18),
          Text(
            'Lịch sử điểm',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: context.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          if (_historyError != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                _historyError!,
                style: const TextStyle(color: Color(0xFFDC2626), fontSize: 13),
              ),
            )
          else if (_history.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Text(
                'Chưa có biến động điểm. Điểm được cộng tự động khi đơn hàng của bạn hoàn tất.',
                textAlign: TextAlign.center,
                style: TextStyle(color: context.textMuted, fontSize: 13),
              ),
            )
          else
            ..._history.map(_buildHistoryRow),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(LoyaltySummary summary) {
    final config = businessConfig;
    // Hạng theo tổng điểm đã tích, không theo điểm còn lại sau khi tiêu.
    final next = nextLoyaltyTier(
      summary.tierPoints,
      silverPoints: config.tierSilverPoints,
      goldPoints: config.tierGoldPoints,
      platinumPoints: config.tierPlatinumPoints,
    );

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF003D5B), Color(0xFF0077B6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(LucideIcons.sparkles, color: Color(0xFFFACC15)),
              const SizedBox(width: 8),
              const Text(
                'Điểm hiện có',
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(LucideIcons.crown, size: 13, color: Colors.white),
                    const SizedBox(width: 4),
                    Text(
                      'Hạng ${summary.tierLabel}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '${summary.points} điểm',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 30,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            next == null
                ? 'Bạn đang ở hạng cao nhất.'
                : 'Còn ${next.missing} điểm để lên hạng ${next.name}.',
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
          if (summary.lifetimePoints != null) ...[
            const SizedBox(height: 4),
            Text(
              'Tổng điểm đã tích: ${summary.lifetimePoints} điểm '
              '(dùng để xếp hạng, tiêu điểm không tụt hạng)',
              style: const TextStyle(color: Colors.white60, fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }

  /// Cách tích và dùng điểm theo cấu hình admin (public settings).
  Widget _buildRulesCard() {
    final config = businessConfig;
    return Container(
      key: const ValueKey('loyalty-rules'),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ruleLine(LucideIcons.gift, loyaltyEarnRuleText(config)),
          const SizedBox(height: 8),
          _ruleLine(LucideIcons.wallet, loyaltyRedeemRuleText(config)),
        ],
      ),
    );
  }

  Widget _ruleLine(IconData icon, String text) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(icon, size: 16, color: const Color(0xFFCA8A04)),
      const SizedBox(width: 8),
      Expanded(
        child: Text(
          text,
          style: TextStyle(
            fontSize: 13,
            color: context.textPrimary,
            height: 1.35,
          ),
        ),
      ),
    ],
  );

  IconData _historyIcon(PointTransaction tx) => switch (tx.type) {
    'ORDER_REDEEM' => LucideIcons.wallet,
    'ORDER_REDEEM_REFUND' => LucideIcons.undo2,
    'ORDER_EARN_REVERSAL' => LucideIcons.rotateCcw,
    'VOUCHER_EXCHANGE' => LucideIcons.ticketPercent,
    'VOUCHER_EXCHANGE_REFUND' => LucideIcons.undo2,
    'ADJUSTMENT' => LucideIcons.slidersHorizontal,
    _ => tx.isCredit ? LucideIcons.arrowDownLeft : LucideIcons.arrowUpRight,
  };

  Widget _buildHistoryRow(PointTransaction tx) {
    final color = tx.isCredit
        ? const Color(0xFF16A34A)
        : const Color(0xFFDC2626);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(_historyIcon(tx), size: 18, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tx.typeLabel,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: context.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  formatDateTimeVn(tx.createdAt),
                  style: TextStyle(fontSize: 12, color: context.textMuted),
                ),
              ],
            ),
          ),
          Text(
            '${tx.isCredit ? '+' : ''}${tx.points}',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 15,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
