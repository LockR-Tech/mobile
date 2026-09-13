import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:smart_laundry_locker/features/transactions/domain/entities/transaction.dart';
import 'package:smart_laundry_locker/features/transactions/presentation/providers/transaction_provider.dart';
import 'package:smart_laundry_locker/features/transactions/presentation/widgets/transaction_detail_skeleton.dart';
import 'package:intl/intl.dart';

class TransactionCard extends StatefulWidget {
  final Transaction transaction;

  const TransactionCard({super.key, required this.transaction});

  @override
  State<TransactionCard> createState() => _TransactionCardState();
}

class _TransactionCardState extends State<TransactionCard> {
  bool _isExpanded = false;
  bool _isLoadingDetail = false;

  void _toggleExpand() async {
    setState(() {
      _isExpanded = !_isExpanded;
    });

    if (_isExpanded) {
      final provider = Provider.of<TransactionProvider>(context, listen: false);
      final cachedDetail = provider.getTransactionDetailFromCache(
        widget.transaction.id,
      );

      if (cachedDetail == null) {
        setState(() => _isLoadingDetail = true);
        await provider.fetchTransactionDetail(widget.transaction.id);
        if (mounted) {
          setState(() => _isLoadingDetail = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<TransactionProvider>(context);
    final detail = provider.getTransactionDetailFromCache(
      widget.transaction.id,
    );
    final isIncome =
        widget.transaction.type == 'TOP_UP' ||
        widget.transaction.type == 'DEPOSIT';
    final amountSign = isIncome ? '+' : '-';
    final amountColor = isIncome ? Colors.green : Colors.red;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      color: Colors.white,
      child: InkWell(
        onTap: _toggleExpand,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0A2342).withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      LucideIcons.arrowRightLeft,
                      color: const Color(0xFF0A2342),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.transaction.description,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          DateFormat(
                            'dd/MM/yyyy HH:mm',
                          ).format(widget.transaction.createdAt.toLocal()),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '$amountSign${NumberFormat.currency(locale: 'vi_VN', symbol: 'đ').format(widget.transaction.amount)}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: amountColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Icon(
                        _isExpanded
                            ? LucideIcons.chevronUp
                            : LucideIcons.chevronDown,
                        color: Colors.grey[400],
                        size: 20,
                      ),
                    ],
                  ),
                ],
              ),

              // Expanded Content
              if (_isExpanded)
                AnimatedSize(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  child: Container(
                    padding: const EdgeInsets.only(top: 16),
                    width: double.infinity,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Divider(),
                        if (_isLoadingDetail)
                          const TransactionDetailSkeleton()
                        else if (detail != null)
                          _buildDetailContent(detail)
                        else
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 16.0),
                            child: Text(
                              'Không thể tải chi tiết giao dịch',
                              style: TextStyle(color: Colors.black87),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailContent(Transaction detail) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDetailRow('Mã GD', detail.code),
          const SizedBox(height: 8),
          _buildDetailRow('Loại GD', detail.type),
          const SizedBox(height: 8),
          if (detail.orderId != null && detail.orderId!.isNotEmpty) ...[
            _buildDetailRow('Mã Đơn hàng', detail.orderId!),
            const SizedBox(height: 8),
          ],
          _buildDetailRow('Ví', detail.walletId),
          const SizedBox(height: 8),
          _buildDetailRow(
            'Số dư sau GD',
            NumberFormat.currency(
              locale: 'vi_VN',
              symbol: 'đ',
            ).format(detail.balanceAfter),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 14)),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 14,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }
}
