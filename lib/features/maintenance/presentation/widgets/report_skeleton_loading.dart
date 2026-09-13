import 'package:flutter/material.dart';

/// Widget skeleton shimmer loading cho maintenance report list
class MaintenanceReportSkeleton extends StatefulWidget {
  final int itemCount;

  const MaintenanceReportSkeleton({Key? key, this.itemCount = 3})
    : super(key: key);

  @override
  State<MaintenanceReportSkeleton> createState() =>
      _MaintenanceReportSkeletonState();
}

class _MaintenanceReportSkeletonState extends State<MaintenanceReportSkeleton>
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
    return ListView.separated(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      padding: const EdgeInsets.all(16),
      itemCount: widget.itemCount,
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        return _buildSkeletonCard();
      },
    );
  }

  Widget _buildSkeletonCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _shimmerBox(width: 100, height: 18),
              _shimmerBox(width: 80, height: 20, borderRadius: 12),
            ],
          ),
          const SizedBox(height: 12),
          _shimmerBox(width: 150, height: 16),
          const SizedBox(height: 8),
          _shimmerBox(width: double.infinity, height: 14),
          const SizedBox(height: 4),
          _shimmerBox(width: 200, height: 14),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _shimmerBox(width: 120, height: 14),
              _shimmerBox(width: 40, height: 14),
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
