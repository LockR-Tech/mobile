import 'package:smart_laundry_locker/features/delegations/presentation/providers/delegation_provider.dart';
import 'package:smart_laundry_locker/features/orders/domain/entities/order.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:smart_laundry_locker/shared/widgets/app_bar.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';

class SearchDelegateePage extends StatefulWidget {
  final Order order;
  const SearchDelegateePage({super.key, required this.order});

  @override
  State<SearchDelegateePage> createState() => _SearchDelegateePageState();
}

class _SearchDelegateePageState extends State<SearchDelegateePage> {
  final TextEditingController _searchController = TextEditingController();
  bool _hasSearched = false;
  String _searchedEmail = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _performSearch() {
    if (_searchController.text.trim().isEmpty) return;

    setState(() {
      _hasSearched = true;
      _searchedEmail = _searchController.text.trim();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: const CustomAppBar(
        title: 'Tìm người ủy quyền',
        showBackButton: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: TextField(
                      controller: _searchController,
                      style: const TextStyle(color: Colors.black87),
                      decoration: InputDecoration(
                        hintText: 'Nhập email người nhận...',
                        hintStyle: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 14,
                        ),
                        prefixIcon: const Icon(
                          LucideIcons.search,
                          color: Colors.grey,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                      ),
                      onSubmitted: (_) => _performSearch(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                    icon: const Icon(LucideIcons.search, color: Colors.white),
                    onPressed: _performSearch,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            if (_hasSearched && _searchedEmail.isNotEmpty)
              _buildDelegateeCard(context),
            if (!_hasSearched)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        LucideIcons.search,
                        size: 48,
                        color: Colors.grey[300],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Nhập email để tìm kiếm người ủy quyền',
                        style: TextStyle(color: Colors.black54, fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDelegateeCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(LucideIcons.user, color: Colors.blue),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Thành viên',
                  style: TextStyle(fontSize: 12, color: Colors.black54),
                ),
                Text(
                  _searchedEmail,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () => _showConfirmDelegationModal(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Ủy quyền',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _showConfirmDelegationModal(BuildContext context) {
    SmartDialog.show<void>(
      builder: (_) => Container(
        width: 320,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                LucideIcons.userCheck,
                color: Colors.blue,
                size: 32,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Xác nhận ủy quyền',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
                children: [
                  const TextSpan(
                    text: 'Bạn có xác nhận ủy quyền lấy hàng cho ',
                  ),
                  TextSpan(
                    text: _searchedEmail,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const TextSpan(text: ' không?'),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => SmartDialog.dismiss<void>(),
                    child: const Text(
                      'Hủy',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      SmartDialog.dismiss<void>();
                      await _handleDelegate(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      shape: const StadiumBorder(),
                    ),
                    child: const Text(
                      'Xác nhận',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleDelegate(BuildContext context) async {
    final provider = context.read<DelegationProvider>();
    SmartDialog.showLoading<void>(msg: 'Đang xử lý...');

    final success = await provider.createDelegation(
      widget.order.id,
      _searchedEmail,
    );
    SmartDialog.dismiss<void>();

    if (success) {
      SmartDialog.showToast('Ủy quyền thành công');
      if (context.mounted) {
        Navigator.pop(context);
      }
    } else {
      SmartDialog.showToast(provider.error ?? 'Ủy quyền thất bại');
    }
  }
}
