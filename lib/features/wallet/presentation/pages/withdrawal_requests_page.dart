import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:smart_laundry_locker/core/theme/shadcn_theme.dart';
import 'package:smart_laundry_locker/core/utils/app_date_time.dart';
import 'package:smart_laundry_locker/core/utils/currency_formatter.dart';
import 'package:smart_laundry_locker/features/wallet/domain/withdrawal_request.dart';
import 'package:smart_laundry_locker/features/wallet/presentation/providers/wallet_provider.dart';
import 'package:smart_laundry_locker/shared/shared.dart';
import 'package:smart_laundry_locker/shared/widgets/user_ui_kit.dart';

/// Danh sách yêu cầu rút tiền của tôi: trạng thái (chờ duyệt / đã chuyển
/// khoản / bị từ chối) và lý do từ chối do quản trị viên nhập.
class WithdrawalRequestsPage extends StatefulWidget {
  const WithdrawalRequestsPage({super.key});

  @override
  State<WithdrawalRequestsPage> createState() => _WithdrawalRequestsPageState();
}

class _WithdrawalRequestsPageState extends State<WithdrawalRequestsPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<WalletProvider>().fetchWithdrawals();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Consumer<WalletProvider>(
        builder: (context, wallet, _) {
          return Column(
            children: [
              BrandHeroHeader(
                title: 'Yêu cầu rút tiền',
                subtitle: 'Theo dõi trạng thái duyệt chuyển khoản',
                onBack: () => Navigator.of(context).pop(),
                trailing: BrandCircleIconButton(
                  icon: LucideIcons.refreshCw,
                  onTap: wallet.fetchWithdrawals,
                ),
              ),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: wallet.fetchWithdrawals,
                  child: _buildBody(wallet),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBody(WalletProvider wallet) {
    if (wallet.isLoadingWithdrawals && wallet.withdrawals.isEmpty) {
      return const Center(
        child: AppLoadingIndicator(message: 'Đang tải yêu cầu rút tiền...'),
      );
    }
    if (wallet.withdrawalsError != null && wallet.withdrawals.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(32),
        children: [
          const SizedBox(height: 60),
          Icon(LucideIcons.cloudOff, size: 52, color: Colors.grey.shade400),
          const SizedBox(height: 14),
          Text(
            wallet.withdrawalsError!,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade600),
          ),
          const SizedBox(height: 12),
          Center(
            child: TextButton(
              onPressed: wallet.fetchWithdrawals,
              child: const Text('Thử lại'),
            ),
          ),
        ],
      );
    }
    if (wallet.withdrawals.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(32),
        children: [
          const SizedBox(height: 60),
          Icon(LucideIcons.landmark, size: 52, color: Colors.grey.shade300),
          const SizedBox(height: 14),
          Text(
            'Bạn chưa có yêu cầu rút tiền nào',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 15),
          ),
        ],
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      itemCount: wallet.withdrawals.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) => _WithdrawalCard(request: wallet.withdrawals[i]),
    );
  }
}

class _WithdrawalCard extends StatelessWidget {
  const _WithdrawalCard({required this.request});

  final WithdrawalRequest request;

  @override
  Widget build(BuildContext context) {
    final color = withdrawalStatusColor(request.status);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  CurrencyFormatter.formatVnd(request.amount),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  withdrawalStatusLabel(request.status).split(' · ').first,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _row('Ngân hàng', request.bankName),
          _row(
            'Tài khoản',
            '${request.maskedAccountNumber} · ${request.accountHolderName}',
          ),
          _row('Gửi lúc', formatDateTimeVn(request.createdAt)),
          if (request.processedAt != null)
            _row('Xử lý lúc', formatDateTimeVn(request.processedAt)),
          if (request.referenceId.isNotEmpty) _row('Mã GD', request.referenceId),
          if (request.status == WithdrawalStatus.pending) ...[
            const SizedBox(height: 8),
            const Text(
              'Đang chờ quản trị viên duyệt chuyển khoản. Số tiền đã được tạm trừ khỏi ví.',
              style: TextStyle(fontSize: 12.5, color: Color(0xFF92400E)),
            ),
          ],
          if (request.status == WithdrawalStatus.rejected) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                request.rejectionReason != null
                    ? 'Lý do từ chối: ${request.rejectionReason}\nSố tiền đã được hoàn lại vào ví.'
                    : 'Yêu cầu bị từ chối. Số tiền đã được hoàn lại vào ví.',
                style: const TextStyle(fontSize: 12.5, color: Color(0xFF991B1B)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 84,
            child: Text(
              label,
              style: const TextStyle(fontSize: 12.5, color: Color(0xFF64748B)),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: AISLShadcnTheme.navyPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
