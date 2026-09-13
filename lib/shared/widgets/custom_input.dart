import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

/// Custom input widget with border radius 16 and no focus ring
class CustomInput extends StatefulWidget {
  final TextEditingController? controller;
  final String? placeholder;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final bool obscureText;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final VoidCallback? onTap;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final bool enabled;
  final int? maxLines;
  final int? maxLength;
  final TextStyle? style;
  final Color? backgroundColor;
  final Color? borderColor;
  final double? height;
  final EdgeInsetsGeometry? contentPadding;
  final FocusNode? focusNode;
  final List<TextInputFormatter>? inputFormatters;
  final double? borderRadius;
  final TextAlign? textAlign;
  final Color? cursorColor;
  const CustomInput({
    super.key,
    this.controller,
    this.placeholder,
    this.keyboardType,
    this.textInputAction,
    this.obscureText = false,
    this.prefixIcon,
    this.suffixIcon,
    this.onTap,
    this.onChanged,
    this.onSubmitted,
    this.enabled = true,
    this.maxLines = 1,
    this.maxLength,
    this.style,
    this.backgroundColor,
    this.borderColor,
    this.height,
    this.contentPadding,
    this.focusNode,
    this.inputFormatters,
    this.borderRadius,
    this.textAlign,
    this.cursorColor,
  });

  @override
  State<CustomInput> createState() => _CustomInputState();
}

class _CustomInputState extends State<CustomInput> {
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
  }

  @override
  void dispose() {
    if (widget.focusNode == null) {
      _focusNode.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);

    return Container(
      height: widget.height ?? 56,
      decoration: BoxDecoration(
        color: widget.backgroundColor ?? theme.colorScheme.muted,
        borderRadius: BorderRadius.circular(widget.borderRadius ?? 16),
        border: Border.all(
          color: widget.borderColor ?? theme.colorScheme.border,
        ),
      ),
      child: Center(
        child: Theme(
          data: Theme.of(context).copyWith(
            textSelectionTheme: TextSelectionThemeData(
              selectionColor: theme.colorScheme.mutedForeground.withOpacity(
                0.3,
              ),
              selectionHandleColor: theme.colorScheme.mutedForeground,
              cursorColor: widget.cursorColor ?? theme.colorScheme.foreground,
            ),
          ),
          child: TextField(
            textAlign: widget.textAlign ?? TextAlign.start,
            controller: widget.controller,
            focusNode: _focusNode,
            keyboardType: widget.keyboardType,
            textInputAction: widget.textInputAction,
            obscureText: widget.obscureText,
            onTap: widget.onTap,
            onChanged: widget.onChanged,
            onSubmitted: widget.onSubmitted,
            enabled: widget.enabled,
            maxLines: widget.maxLines,
            maxLength: widget.maxLength,
            inputFormatters: widget.inputFormatters,
            textAlignVertical: TextAlignVertical.center,
            style:
                widget.style ??
                theme.textTheme.p.copyWith(color: theme.colorScheme.foreground),
            decoration: InputDecoration(
              hintText: widget.placeholder,
              hintStyle: theme.textTheme.p.copyWith(
                color: theme.colorScheme.mutedForeground,
              ),
              prefixIcon: widget.prefixIcon,
              suffixIcon: widget.suffixIcon,
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              errorBorder: InputBorder.none,
              focusedErrorBorder: InputBorder.none,
              disabledBorder: InputBorder.none,
              contentPadding:
                  widget.contentPadding ??
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 0),
              counterText: '', // Hide character counter
              isDense: true,
            ),
          ),
        ),
      ),
    );
  }
}
