import 'package:smart_laundry_locker/features/locker/domain/entities/locker_location.dart';
import 'package:smart_laundry_locker/features/locker/domain/utils/locker_layout_helper.dart';
import 'package:smart_laundry_locker/features/locker_ops/presentation/widgets/location_services.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:smart_laundry_locker/shared/widgets/user_ui_kit.dart';

/// Modal hiển thị thông tin chi tiết của tủ trên bản đồ: tên, địa chỉ, trạng
/// thái kết nối (`online` của server) và số ô trống theo loại ô (từ layout).
class LockerInfoModal extends StatelessWidget {
  final LockerLocation location;
  final ScrollController scrollController;

  /// Số ô theo loại; null khi chưa tải xong.
  final List<LockerCellGroupCount>? cellGroups;
  final bool loadingCells;
  final String? cellsError;
  final VoidCallback? onRetryCells;

  /// Cờ kết nối mới nhất (layout); null ⇒ dùng `location.online`.
  final bool? online;

  /// Lý do không đặt được dịch vụ tại tủ; null = đặt được.
  final String? bookingBlockReason;

  /// Mở sơ đồ ô của tủ.
  final VoidCallback? onOpenGrid;

  const LockerInfoModal({
    super.key,
    required this.location,
    required this.scrollController,
    this.cellGroups,
    this.loadingCells = false,
    this.cellsError,
    this.onRetryCells,
    this.online,
    this.bookingBlockReason,
    this.onOpenGrid,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final dragHandleWidth = screenWidth * 0.15;
    const dragHandleHeight = 4.0;
    final horizontalPadding = screenWidth * 0.05;
    const verticalPadding = 16.0;
    final isOnline = online ?? location.online;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: SingleChildScrollView(
        controller: scrollController,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: dragHandleWidth,
              height: dragHandleHeight,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // header - tên tủ, địa chỉ
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: horizontalPadding,
                vertical: verticalPadding,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    location.name,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          location.address.isEmpty
                              ? 'Chưa có địa chỉ'
                              : location.address,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                            height: 1.4,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      _ConnectionBadge(online: isOnline),
                    ],
                  ),
                ],
              ),
            ),
            // Số ô theo loại — tải từ layout thật của tủ
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: horizontalPadding,
                vertical: verticalPadding,
              ),
              child: _buildCellCounts(),
            ),
            if (bookingBlockReason != null)
              Padding(
                padding: EdgeInsets.fromLTRB(
                  horizontalPadding,
                  0,
                  horizontalPadding,
                  8,
                ),
                child: Text(
                  bookingBlockReason!,
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: Color(0xFFB91C1C),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            // CTA: đặt dịch vụ tại địa điểm này (Thuê tủ / Gửi hàng)
            Padding(
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                4,
                horizontalPadding,
                16,
              ),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: bookingBlockReason != null
                          ? null
                          : () => showLocationServicesSheet(context, location),
                      icon: const Icon(LucideIcons.calendarPlus, size: 18),
                      label: const Text('Đặt dịch vụ'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AislBrand.navy,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                  if (onOpenGrid != null) ...[
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: onOpenGrid,
                        icon: const Icon(LucideIcons.layoutGrid, size: 18),
                        label: const Text('Xem sơ đồ ô tủ'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AislBrand.navy,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            SizedBox(height: MediaQuery.of(context).padding.bottom),
          ],
        ),
      ),
    );
  }

  Widget _buildCellCounts() {
    if (loadingCells && cellGroups == null) {
      return const Center(
        child: Text(
          'Đang tải số ô trống...',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }
    if (cellsError != null && cellGroups == null) {
      return Row(
        children: [
          Expanded(
            child: Text(
              'Chưa tải được số ô: $cellsError',
              style: const TextStyle(color: Colors.redAccent, fontSize: 13),
            ),
          ),
          if (onRetryCells != null)
            TextButton(onPressed: onRetryCells, child: const Text('Thử lại')),
        ],
      );
    }
    final groups = cellGroups ?? const <LockerCellGroupCount>[];
    if (groups.isEmpty) {
      return const Center(
        child: Text(
          'Tủ chưa có ô nào được cấu hình',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [for (final g in groups) _buildLockerSizeCard(g)],
    );
  }

  Widget _buildLockerSizeCard(LockerCellGroupCount group) {
    return Container(
      width: 104,
      decoration: BoxDecoration(
        color: const Color(0xFFF0F8FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AislBrand.chipBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: AislBrand.brandGradient,
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Center(
              child: Text(
                group.label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ô trống',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                const SizedBox(height: 4),
                Text(
                  '${group.available}/${group.total}',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ConnectionBadge extends StatelessWidget {
  const _ConnectionBadge({required this.online});

  final bool? online;

  @override
  Widget build(BuildContext context) {
    final (IconData icon, Color color, String label) = switch (online) {
      true => (LucideIcons.wifi, const Color(0xFF16A34A), 'Trực tuyến'),
      false => (LucideIcons.wifiOff, const Color(0xFFDC2626), 'Mất kết nối'),
      null => (LucideIcons.wifi, const Color(0xFF94A3B8), 'Chưa rõ kết nối'),
    };
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
