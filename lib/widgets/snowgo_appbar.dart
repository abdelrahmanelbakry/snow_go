import 'package:flutter/material.dart';

/// Drop-in app bar that prevents overflow, centers a logo like the mockups,
/// and stays responsive across screen sizes.
///
/// How to use:
///   Scaffold(
///     appBar: BrandedAppBar(
///       title: 'SnowGo',
///       subtitle: 'Find reliable snow clearing', // optional
///       logo: const AssetImage('assets/logo_white.png'), // or NetworkImage
///       actions: [
///         IconButton(icon: const Icon(Icons.notifications_none), onPressed: () {}),
///         const SizedBox(width: 4),
///       ],
///     ),
///     body: ...
///   );
class BrandedAppBar extends StatelessWidget implements PreferredSizeWidget {
  const BrandedAppBar({
    super.key,
    this.title,
    this.subtitle,
    this.leading,
    this.actions,
    this.backgroundColor,
    this.elevation = 0,
    this.toolbarHeight = 88,
    this.logo,
    this.logoHeight = 28,
    this.centerTitle = true,
    this.showBottomDivider = true,
  });

  /// Main title (shown beside/under the logo depending on space)
  final String? title;

  /// Optional subtitle. Will automatically hide on narrow widths.
  final String? subtitle;

  /// Optional leading widget. If null, no back button spacing is reserved.
  final Widget? leading;

  /// App bar actions.
  final List<Widget>? actions;

  /// Background color
  final Color? backgroundColor;

  /// Elevation (shadow)
  final double elevation;

  /// Height of the toolbar area
  final double toolbarHeight;

  /// Optional logo image (AssetImage/NetworkImage/etc.)
  final ImageProvider? logo;

  /// Height for the logo image
  final double logoHeight;

  /// Whether to center the title block
  final bool centerTitle;

  /// Show a 1px divider at the bottom for visual separation
  final bool showBottomDivider;

  @override
  Size get preferredSize => Size.fromHeight(toolbarHeight + (showBottomDivider ? 1 : 0));

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // The actual AppBar with a custom flexibleSpace for precise layout control.
    return Material(
      color: backgroundColor ?? theme.colorScheme.primary,
      elevation: elevation,
      child: SafeArea(
        bottom: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: toolbarHeight,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final isTight = constraints.maxWidth < 360;
                    final showSubtitle = subtitle != null && constraints.maxWidth >= 400;

                    // Leading area (kept a fixed width so center stays centered even with/without leading)
                    const leadingWidth = 48.0;
                    final actionWidth = _estimateActionsWidth(actions);

                    // Center area gets the remaining width and uses FittedBox/Overflow handling.
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: leadingWidth,
                          child: leading,
                        ),
                        // Center content
                        Expanded(
                          child: Align(
                            alignment: centerTitle ? Alignment.center : Alignment.centerLeft,
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                // Keep a little slack so center doesn't collide with actions
                                maxWidth: constraints.maxWidth - leadingWidth - actionWidth - 16,
                              ),
                              child: _TitleCluster(
                                title: title,
                                subtitle: showSubtitle ? subtitle : null,
                                logo: logo,
                                logoHeight: logoHeight,
                                isTight: isTight,
                              ),
                            ),
                          ),
                        ),
                        // Actions (kept compact)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: actions ?? const <Widget>[],
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
            if (showBottomDivider)
              Container(
                height: 1,
                color: theme.colorScheme.onPrimary.withOpacity(0.08),
              ),
          ],
        ),
      ),
    );
  }

  static double _estimateActionsWidth(List<Widget>? actions) {
    if (actions == null || actions.isEmpty) return 0;
    // A rough, safe estimate per icon button including padding.
    // This helps reserve room so the center cluster never overflows.
    const perAction = 48.0;
    return (actions.length * perAction) + 4; // include trailing padding
  }
}

class _TitleCluster extends StatelessWidget {
  const _TitleCluster({
    required this.title,
    required this.subtitle,
    required this.logo,
    required this.logoHeight,
    required this.isTight,
  });

  final String? title;
  final String? subtitle;
  final ImageProvider? logo;
  final double logoHeight;
  final bool isTight;

  @override
  Widget build(BuildContext context) {
    final onPrimary = Theme.of(context).colorScheme.onPrimary;

    // Layout adapts:
    //  - Wide:  logo + vertical title/subtitle
    //  - Tight: logo + single-line (title only), with scaleDown to avoid overflow
    final titleText = Text(
      title ?? '',
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
        color: onPrimary,
        fontWeight: FontWeight.w600,
      ),
    );

    final subtitleText = (subtitle == null)
        ? const SizedBox.shrink()
        : Text(
      subtitle!,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: Theme.of(context).textTheme.labelMedium?.copyWith(
        color: onPrimary.withOpacity(0.8),
        fontWeight: FontWeight.w400,
      ),
    );

    final logoWidget = (logo == null)
        ? const SizedBox.shrink()
        : Image(
      image: logo!,
      height: logoHeight,
      fit: BoxFit.contain,
    );

    if (isTight) {
      // Compact: logo + title horizontally, scale down if needed to avoid overflow
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (logo != null) logoWidget,
          if (logo != null) const SizedBox(width: 8),
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: titleText,
            ),
          ),
        ],
      );
    }

    // Regular/wide: logo left, then stacked title+subtitle
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (logo != null) logoWidget,
        if (logo != null) const SizedBox(width: 10),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: titleText,
                ),
              ),
              if (subtitle != null) const SizedBox(height: 2),
              if (subtitle != null) subtitleText,
            ],
          ),
        ),
      ],
    );
  }
}

/// Optional: A SliverAppBar version for scrollable pages with the same look
/// and responsive/overflow-safe behavior.
class BrandedSliverAppBar extends StatelessWidget {
  const BrandedSliverAppBar({
    super.key,
    this.title,
    this.subtitle,
    this.leading,
    this.actions,
    this.backgroundColor,
    this.pinned = true,
    this.floating = false,
    this.expandedHeight = 140,
    this.logo,
    this.logoHeight = 36,
    this.showBottomDivider = true,
  });

  final String? title;
  final String? subtitle;
  final Widget? leading;
  final List<Widget>? actions;
  final Color? backgroundColor;
  final bool pinned;
  final bool floating;
  final double expandedHeight;
  final ImageProvider? logo;
  final double logoHeight;
  final bool showBottomDivider;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SliverAppBar(
      backgroundColor: backgroundColor ?? theme.colorScheme.primary,
      elevation: 0,
      pinned: pinned,
      floating: floating,
      expandedHeight: expandedHeight,
      leading: leading,
      actions: actions,
      bottom: showBottomDivider
          ? PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(
          height: 1,
          color: theme.colorScheme.onPrimary.withOpacity(0.08),
        ),
      )
          : null,
      flexibleSpace: LayoutBuilder(
        builder: (context, constraints) {
          final available = constraints.biggest.height;
          final tight = available < 96;
          final showSubtitle = !tight && subtitle != null;

          return SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Align(
                alignment: Alignment.bottomCenter,
                child: _TitleCluster(
                  title: title,
                  subtitle: showSubtitle ? subtitle : null,
                  logo: logo,
                  logoHeight: logoHeight,
                  isTight: tight,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
