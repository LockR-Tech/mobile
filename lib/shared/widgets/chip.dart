import 'package:flutter/cupertino.dart';

class CustomChip extends StatelessWidget {
  final String label;
  final Color backgroundColor;
  final Color textColor;
  final double fontSize;
  final FontWeight fontWeight;
  final EdgeInsetsGeometry padding;
  final BorderRadius borderRadius;
  final VoidCallback? onTap;

  const CustomChip({
    Key? key,
    required this.label,
    this.backgroundColor = const Color(0xFFE5E5EA),
    this.textColor = CupertinoColors.black,
    this.fontSize = 12,
    this.fontWeight = FontWeight.w500,
    this.padding = const EdgeInsets.symmetric(
      horizontal: 6,
      vertical: 1,
    ), // giảm padding
    this.borderRadius = const BorderRadius.all(Radius.circular(12)),
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      padding: padding,
      minSize: 0, // giảm chiều cao tối thiểu
      borderRadius: borderRadius,
      color: backgroundColor,
      onPressed: onTap ?? () {},
      child: Text(
        label,
        style: TextStyle(
          fontSize: fontSize,
          color: textColor,
          fontWeight: fontWeight,
        ),
      ),
    );
  }
}
