import 'package:smart_laundry_locker/features/locker/domain/entities/locker_location.dart';
import 'package:smart_laundry_locker/features/locker/infrastructure/models/responses/lockers_response.dart';
import 'package:smart_laundry_locker/features/locker_ops/presentation/widgets/location_services.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:smart_laundry_locker/shared/widgets/user_ui_kit.dart';

/// Modal hiển thị thông tin chi tiết của location
/// Bao gồm tên, địa chỉ và số lượng locker theo size
class LockerInfoModal extends StatelessWidget {
  final LockerLocation location;
  final List<LockerSizeCount> lockerSizeItems;
  final ScrollController scrollController;

  const LockerInfoModal({
    super.key,
    required this.location,
    required this.lockerSizeItems,
    required this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final dragHandleWidth = screenWidth * 0.15;
    const dragHandleHeight = 4.0;
    final horizontalPadding = screenWidth * 0.05;
    const verticalPadding = 16.0;

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
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // tên tủ
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
                            // địa chỉ
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Text(
                                    location.address,
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
                                Icon(
                                  LucideIcons.wifi,
                                  color: Colors.green[600],
                                  size: 20,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // danh sách locker counts theo size - dynamic từ API
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: horizontalPadding,
                vertical: verticalPadding,
              ),
              child: lockerSizeItems.isEmpty
                  ? const Center(
                      child: Text(
                        'Đang tải thông tin...',
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  : Row(children: _buildSizeCards()),
            ),
            // CTA: đặt dịch vụ tại địa điểm này (Thuê tủ / Gửi hàng / Giặt đồ)
            Padding(
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                4,
                horizontalPadding,
                16,
              ),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => showLocationServicesSheet(context, location),
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
            ),
            SizedBox(height: MediaQuery.of(context).padding.bottom),
          ],
        ),
      ),
    );
  }

  /// Build list of locker size cards with proper spacing
  List<Widget> _buildSizeCards() {
    final List<Widget> cards = [];
    for (int i = 0; i < lockerSizeItems.length; i++) {
      if (i > 0) {
        cards.add(const SizedBox(width: 12));
      }
      cards.add(
        Expanded(
          child: _buildLockerSizeCard(
            sizeName: lockerSizeItems[i].sizeName,
            availableCount: lockerSizeItems[i].totalLockers,
            dimensions: lockerSizeItems[i].dimensions,
          ),
        ),
      );
    }
    return cards;
  }

  Widget _buildLockerSizeCard({
    required String sizeName,
    required int availableCount,
    required String dimensions,
  }) {
    return Container(
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
            padding: const EdgeInsets.symmetric(vertical: 8),
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
                sizeName,
                style: const TextStyle(
                  fontSize: 16,
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
                  dimensions,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[700],
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Ngăn trống',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                const SizedBox(height: 4),
                Text(
                  availableCount.toString(),
                  style: const TextStyle(
                    fontSize: 24,
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
