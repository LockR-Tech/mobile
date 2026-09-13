import 'package:flutter/material.dart';

class TransactionDetailSkeleton extends StatefulWidget {
  const TransactionDetailSkeleton({super.key});

  @override
  State<TransactionDetailSkeleton> createState() =>
      _TransactionDetailSkeletonState();
}

class _TransactionDetailSkeletonState extends State<TransactionDetailSkeleton>
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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildShimmerRow(),
          const SizedBox(height: 12),
          _buildShimmerRow(),
          const SizedBox(height: 12),
          _buildShimmerRow(),
          const SizedBox(height: 12),
          _buildShimmerRow(),
        ],
      ),
    );
  }

  Widget _buildShimmerRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _shimmerBox(width: 100, height: 16),
        _shimmerBox(width: 150, height: 16),
      ],
    );
  }

  Widget _shimmerBox({required double width, required double height}) {
    return AnimatedBuilder(
      animation: _shimmerAnimation,
      builder: (context, child) {
        return Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              stops: const [0.0, 0.5, 1.0],
              colors: [Colors.grey[300]!, Colors.grey[100]!, Colors.grey[300]!],
              transform: _TranslateGradient(_shimmerAnimation.value),
            ),
          ),
        );
      },
    );
  }
}

class _TranslateGradient extends GradientTransform {
  final double value;
  const _TranslateGradient(this.value);

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.translationValues(bounds.width * value, 0, 0);
  }
}
