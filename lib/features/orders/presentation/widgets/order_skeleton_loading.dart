import 'package:flutter/material.dart';

/// Widget skeleton shimmer loading cho order list
/// Hiển thị placeholder cards khi đang loading dữ liệu
class OrderSkeletonLoading extends StatefulWidget {
  /// Số lượng skeleton cards hiển thị
  final int itemCount;

  /// Kiểu skeleton: 'customer' hoặc 'courier'
  final String type;

  const OrderSkeletonLoading({
    Key? key,
    this.itemCount = 3,
    this.type = 'customer',
  }) : super(key: key);

  @override
  State<OrderSkeletonLoading> createState() => _OrderSkeletonLoadingState();
}

class _OrderSkeletonLoadingState extends State<OrderSkeletonLoading>
    with SingleTickerProviderStateMixin {
  late AnimationController _shimmerController;
  late Animation<double> _shimmerAnimation;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
    _shimmerAnimation = Tween<double>(begin: -2, end: 2).animate(
      CurvedAnimation(parent: _shimmerController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _shimmerAnimation,
      builder: (context, child) {
        return ListView.separated(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: widget.itemCount,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            if (widget.type == 'courier') {
              return _buildCourierSkeleton();
            }
            return _buildCustomerSkeleton();
          },
        );
      },
    );
  }

  Widget _buildCustomerSkeleton() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _shimmerBox(width: 80, height: 24, borderRadius: 12),
              _shimmerBox(width: 90, height: 20),
            ],
          ),
          const SizedBox(height: 16),
          _shimmerBox(width: 200, height: 18),
          const SizedBox(height: 8),
          _shimmerBox(width: 150, height: 14),
          const SizedBox(height: 8),
          _shimmerBox(width: 180, height: 12),
          const SizedBox(height: 16),
          _shimmerBox(width: double.infinity, height: 14),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _shimmerBox(width: 140, height: 16),
              _shimmerBox(width: 90, height: 36, borderRadius: 8),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCourierSkeleton() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline skeleton
          Column(
            children: [
              _shimmerBox(width: 24, height: 24, borderRadius: 12),
              const SizedBox(height: 4),
              _shimmerBox(width: 2, height: 30),
              const SizedBox(height: 4),
              _shimmerBox(width: 24, height: 24, borderRadius: 12),
            ],
          ),
          const SizedBox(width: 12),
          // Addresses skeleton
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _shimmerBox(width: 180, height: 16),
                const SizedBox(height: 6),
                _shimmerBox(width: 100, height: 14),
                const SizedBox(height: 14),
                _shimmerBox(width: 160, height: 16),
                const SizedBox(height: 6),
                _shimmerBox(width: 80, height: 14),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Payment/Distance skeleton
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _shimmerBox(width: 60, height: 14),
              const SizedBox(height: 4),
              _shimmerBox(width: 50, height: 24, borderRadius: 8),
              const SizedBox(height: 16),
              _shimmerBox(width: 60, height: 14),
              const SizedBox(height: 4),
              _shimmerBox(width: 40, height: 16),
            ],
          ),
        ],
      ),
    );
  }

  Widget _shimmerBox({
    required double height,
    double? width,
    double borderRadius = 4,
  }) {
    return AnimatedBuilder(
      animation: _shimmerAnimation,
      builder: (context, child) {
        return Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(borderRadius),
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: const [
                Color(0xFFE0E0E0),
                Color(0xFFF5F5F5),
                Color(0xFFE0E0E0),
              ],
              stops: [
                _clamp(_shimmerAnimation.value - 0.3),
                _clamp(_shimmerAnimation.value),
                _clamp(_shimmerAnimation.value + 0.3),
              ],
            ),
          ),
        );
      },
    );
  }

  double _clamp(double value) => value.clamp(0.0, 1.0);
}
