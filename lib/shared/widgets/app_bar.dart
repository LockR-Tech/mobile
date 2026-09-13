import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../core/constants/app_colors.dart';

/// Custom SliverAppBar with dynamic title scaling and stretch functionality
class CustomSliverAppBar extends StatelessWidget {
  final String title;
  final List<Widget>? actions;
  final Widget? leading;
  final bool showBackButton;
  final VoidCallback? onBackPressed;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final Future<void> Function()? onStretch;
  final double expandedHeight;
  final bool pinned;
  final bool floating;
  final bool stretch;
  final bool automaticallyImplyLeading;

  const CustomSliverAppBar({
    super.key,
    required this.title,
    this.actions,
    this.leading,
    this.showBackButton = false,
    this.onBackPressed,
    this.backgroundColor,
    this.foregroundColor,
    this.onStretch,
    this.expandedHeight = 120.0,
    this.pinned = true,
    this.floating = false,
    this.stretch = true,
    this.automaticallyImplyLeading = true,
  });

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      expandedHeight: expandedHeight,
      floating: floating,
      pinned: pinned,
      stretch: stretch,
      backgroundColor: backgroundColor ?? Colors.transparent,
      foregroundColor: foregroundColor ?? AppColors.onSurface,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      // Prevents color change on scroll
      shadowColor: Colors.transparent,
      // Prevents shadow color changes
      automaticallyImplyLeading: automaticallyImplyLeading && (showBackButton || leading != null),
      leading: leading ?? (showBackButton ? _buildBackButton(context) : null),
      actions: actions != null
          ? [...actions!, const SizedBox(width: 10)]
          : null,
      systemOverlayStyle: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
      onStretchTrigger: onStretch,
      flexibleSpace: Container(
        // Force consistent background color throughout scroll
        decoration: BoxDecoration(color: backgroundColor ?? Colors.transparent),
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Calculate the ratio for animation
            final double appBarHeight = constraints.biggest.height;
            final double statusBarHeight = MediaQuery.of(context).padding.top;
            final double toolbarHeight = kToolbarHeight;
            final double maxExtent = expandedHeight + statusBarHeight;
            final double minExtent = toolbarHeight + statusBarHeight;

            // Calculate shrink ratio (0.0 = fully expanded, 1.0 = fully collapsed)
            final double shrinkRatio = math.max(
              0.0,
              math.min(
                1.0,
                (maxExtent - appBarHeight) / (maxExtent - minExtent),
              ),
            );

            return Stack(
              children: [
                // Main flexible space content
                FlexibleSpaceBar(
                  titlePadding: EdgeInsets.zero,
                  title: _buildAnimatedTitle(
                    context,
                    shrinkRatio,
                    showBackButton,
                  ),
                ),

                // Bottom border line when collapsed
                if (shrinkRatio > 0.8)
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 1,
                      decoration: BoxDecoration(
                        color: (foregroundColor ?? AppColors.onSurface)
                            .withOpacity(0.1),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildAnimatedTitle(
    BuildContext context,
    double shrinkRatio,
    bool? isBackButton,
  ) {
    // Calculate title properties based on shrink ratio
    final double titleFontSize = 24.0 - (3.0 * shrinkRatio); // 32px -> 20px
    final FontWeight titleFontWeight = shrinkRatio > 0.5
        ? FontWeight.w700
        : FontWeight.w700;

    // Check if there's a leading widget (back button or custom leading)
    final bool hasLeading = leading != null || showBackButton;

    // Adjust left padding based on whether there's a leading widget
    // When collapsed (shrinkRatio > 0.5), give more space if there's a back button
    final double leftPadding = hasLeading && shrinkRatio > 0.5
        ? 56.0 // Space for back button when collapsed
        : 24.0; // Normal padding when expanded or no back button

    final double topPadding = shrinkRatio < 1.0 ? 0.0 : 0.0;
    final double bottomPadding = shrinkRatio < 1.0 ? 16.0 : 14.0;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        left: leftPadding,
        top: topPadding,
        right: 20.0, // Leave space for actions
        bottom: bottomPadding,
      ),
      child: Align(
        alignment: Alignment.bottomLeft,
        child: Text(
          title,
          style: TextStyle(
            fontFamily: 'Manrope',
            fontSize: titleFontSize,
            fontWeight: titleFontWeight,
            color: foregroundColor ?? AppColors.onSurface,
            height: 1.2,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  Widget _buildBackButton(BuildContext context) {
    return Row(
      children: [
        const SizedBox(width: 8),
        ShadButton.ghost(
          onPressed: onBackPressed ?? () => Navigator.of(context).pop(),
          decoration: const ShadDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
          width: 40,
          height: 40,
          padding: EdgeInsets.zero,
          child: Icon(
            LucideIcons.arrowLeft,
            size: 16,
            color: foregroundColor ?? Colors.black,
          ),
        ),
      ],
    );
  }
}

/// Custom app bar widget with consistent styling (kept for backward compatibility)
class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final Widget? leading;
  final bool showBackButton;
  final VoidCallback? onBackPressed;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final Color? foregroundColorButton;
  final double? elevation;
  final bool centerTitle;
  final PreferredSizeWidget? bottom;
  final Widget? titleWidget;

  const CustomAppBar({
    super.key,
    this.title = '',
    this.actions,
    this.leading,
    this.showBackButton = false,
    this.onBackPressed,
    this.backgroundColor,
    this.foregroundColor,
    this.elevation,
    this.centerTitle = true,
    this.bottom,
    this.foregroundColorButton,
    this.titleWidget,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title:
          titleWidget ??
          Text(
            title,
            style: TextStyle(
              fontFamily: 'Manrope',
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: foregroundColor ?? AppColors.onSurface,
            ),
          ),
      backgroundColor: backgroundColor ?? AppColors.surface,
      foregroundColor: foregroundColor ?? AppColors.onSurface,
      elevation: elevation ?? 0,
      centerTitle: centerTitle,
      leading: leading ?? (showBackButton ? _buildBackButton(context) : null),
      actions: actions,
      bottom: bottom,
      systemOverlayStyle: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    );
  }

  Widget _buildBackButton(BuildContext context) {
    return IconButton(
      icon: Icon(LucideIcons.arrowLeft, color: foregroundColorButton),
      onPressed: onBackPressed ?? () => Navigator.of(context).pop(),
    );
  }

  @override
  Size get preferredSize =>
      Size.fromHeight(kToolbarHeight + (bottom?.preferredSize.height ?? 0));
}

/// App bar with search functionality
class SearchAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String hintText;
  final ValueChanged<String>? onSearchChanged;
  final VoidCallback? onSearchTap;
  final List<Widget>? actions;
  final Widget? leading;
  final bool showBackButton;
  final VoidCallback? onBackPressed;

  const SearchAppBar({
    super.key,
    this.hintText = 'Tìm kiếm...',
    this.onSearchChanged,
    this.onSearchTap,
    this.actions,
    this.leading,
    this.showBackButton = false,
    this.onBackPressed,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.surface,
      foregroundColor: AppColors.onSurface,
      elevation: 0,
      leading: leading ?? (showBackButton ? _buildBackButton(context) : null),
      actions: actions,
      title: _buildSearchField(context),
      systemOverlayStyle: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    );
  }

  Widget _buildSearchField(BuildContext context) {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(20),
      ),
      child: TextField(
        onChanged: onSearchChanged,
        onTap: onSearchTap,
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(color: AppColors.onSurfaceVariant, fontSize: 16),
          prefixIcon: Icon(
            LucideIcons.search,
            color: AppColors.onSurfaceVariant,
            size: 20,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
        ),
      ),
    );
  }

  Widget _buildBackButton(BuildContext context) {
    return IconButton(
      icon: const Icon(LucideIcons.arrowLeft),
      onPressed: onBackPressed ?? () => Navigator.of(context).pop(),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

/// App bar with filter functionality
class FilterAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final VoidCallback? onFilterTap;
  final List<Widget>? actions;
  final Widget? leading;
  final bool showBackButton;
  final VoidCallback? onBackPressed;
  final int? filterCount;

  const FilterAppBar({
    super.key,
    required this.title,
    this.onFilterTap,
    this.actions,
    this.leading,
    this.showBackButton = false,
    this.onBackPressed,
    this.filterCount,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(
        title,
        style: const TextStyle(
          fontFamily: 'Manrope',
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: AppColors.onSurface,
        ),
      ),
      backgroundColor: AppColors.surface,
      foregroundColor: AppColors.onSurface,
      elevation: 0,
      centerTitle: true,
      leading: leading ?? (showBackButton ? _buildBackButton(context) : null),
      actions: [
        if (onFilterTap != null) _buildFilterButton(context),
        ...?actions,
      ],
      systemOverlayStyle: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    );
  }

  Widget _buildFilterButton(BuildContext context) {
    return Stack(
      children: [
        IconButton(
          icon: const Icon(LucideIcons.slidersHorizontal),
          onPressed: onFilterTap,
        ),
        if (filterCount != null && filterCount! > 0)
          Positioned(
            right: 8,
            top: 8,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
              child: Text(
                filterCount.toString(),
                style: const TextStyle(
                  color: AppColors.onPrimary,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildBackButton(BuildContext context) {
    return IconButton(
      icon: const Icon(LucideIcons.arrowLeft),
      onPressed: onBackPressed ?? () => Navigator.of(context).pop(),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
