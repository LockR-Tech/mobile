import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

/// Custom textarea widget styled similarly to `CustomInput`.
/// - Rounded border radius 16
/// - Uses Shad theme colors
/// - Hides default focus ring borders
class CustomTextarea extends StatefulWidget {
  final TextEditingController? controller;
  final String? placeholder;
  final int? minLines;
  final int? maxLines;
  final int? maxLength;
  final bool enabled;
  final ValueChanged<String>? onChanged;
  final TextStyle? style;
  final Color? backgroundColor;
  final Color? borderColor;
  final EdgeInsetsGeometry? contentPadding;
  final FocusNode? focusNode;

  const CustomTextarea({
    super.key,
    this.controller,
    this.placeholder,
    this.minLines,
    this.maxLines,
    this.maxLength,
    this.enabled = true,
    this.onChanged,
    this.style,
    this.backgroundColor,
    this.borderColor,
    this.contentPadding,
    this.focusNode,
  });

  @override
  State<CustomTextarea> createState() => _CustomTextareaState();
}

class _CustomTextareaState extends State<CustomTextarea> {
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
      decoration: BoxDecoration(
        color: widget.backgroundColor ?? theme.colorScheme.muted,
        borderRadius: BorderRadius.circular(16),
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
              cursorColor: theme.colorScheme.foreground,
            ),
          ),
          child: TextField(
            controller: widget.controller,
            focusNode: _focusNode,
            enabled: widget.enabled,
            maxLines: widget.maxLines ?? 6,
            minLines: widget.minLines ?? 4,
            maxLength: widget.maxLength,
            onChanged: widget.onChanged,
            style:
                widget.style ??
                theme.textTheme.p.copyWith(color: theme.colorScheme.foreground),
            decoration: InputDecoration(
              hintText: widget.placeholder,
              hintStyle: theme.textTheme.p.copyWith(
                color: theme.colorScheme.mutedForeground,
              ),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              errorBorder: InputBorder.none,
              focusedErrorBorder: InputBorder.none,
              disabledBorder: InputBorder.none,
              contentPadding:
                  widget.contentPadding ??
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              counterText: '',
              isDense: true,
            ),
          ),
        ),
      ),
    );
  }
}
