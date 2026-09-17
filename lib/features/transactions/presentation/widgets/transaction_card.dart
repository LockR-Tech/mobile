import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:smart_laundry_locker/features/transactions/domain/entities/transaction.dart';
import 'package:intl/intl.dart';

class TransactionCard extends StatefulWidget {
  final Transaction transaction;

  const TransactionCard({super.key, required this.transaction});

  @override
  State<TransactionCard> createState() => _TransactionCardState();
}

class _TransactionCardState extends State<TransactionCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
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
        onTap: () => setState(() => _isExpanded = !_isExpanded),
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

              // Expanded Content — dữ liệu đã có sẵn từ danh sách (GET /api/wallet/transactions
              // trả đủ field cho mỗi giao dịch), không cần gọi lại API để lấy "chi tiết".
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
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12.0),
                          child: _buildDetailContent(widget.transaction),
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

  Widget _buildDetailContent(Transaction tx) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (tx.referenceId != null && tx.referenceId!.isNotEmpty) ...[
          _buildDetailRow('Mã GD', tx.referenceId!),
          const SizedBox(height: 8),
        ],
        _buildDetailRow('Loại GD', tx.type),
        const SizedBox(height: 8),
        // Mã đơn resolve sẵn từ order-service — cùng giá trị admin web thấy cho cùng
        // biến động (xem WalletTransactionRefs / PaymentReferenceResolver ở payment-service).
        if (tx.orderCode != null && tx.orderCode!.isNotEmpty) ...[
          _buildDetailRow('Mã đơn hàng', tx.orderCode!),
          const SizedBox(height: 8),
        ],
        _buildDetailRow(
          'Số dư sau GD',
          NumberFormat.currency(
            locale: 'vi_VN',
            symbol: 'đ',
          ).format(tx.balanceAfter),
        ),
      ],
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
