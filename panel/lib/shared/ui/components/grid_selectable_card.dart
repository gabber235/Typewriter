import "package:flutter/material.dart";
import "package:flutter_animate/flutter_animate.dart";
import "package:typewriter_panel/typewriter_panel.dart";

/// A reusable, presentation-only grid card used to display a selectable item
/// with an optional badge and a title.
///
/// This widget is intentionally pure-UI: it does not manage selection, focus,
/// or hover state. Provide those states via the constructor. Interaction
/// (tap, keyboard focus, selection) should be handled by parent widgets.
class GridSelectableCard extends StatelessWidget {
  const GridSelectableCard({
    required this.title,
    required this.baseColor,
    this.onBaseColor,
    this.isSelected = false,
    this.isFocused = false,
    this.isHovered = false,
    this.width = 200,
    this.height = 160,
    this.borderRadius = 14,
    this.padding = const EdgeInsets.fromLTRB(14, 12, 14, 12),
    this.animationDuration = const Duration(milliseconds: 250),
    this.animationCurve = Curves.fastEaseInToSlowEaseOut,
    this.badgeLabel,
    this.badgeColor,
    this.badgeOnColor,
    this.titleStyle,
    this.header,
    this.footer,
    super.key,
  });

  /// Title shown at the bottom of the card.
  final String title;

  /// Base color used for the card background and title when not selected.
  final Color baseColor;

  /// Foreground color used for content on top of the selected background.
  /// Defaults to `Theme.of(context).colorScheme.surfaceContainerLowest`.
  final Color? onBaseColor;

  /// Selection state. When true, the background becomes `baseColor`.
  final bool isSelected;

  /// Focus state. When true, the border is highlighted in `baseColor` and
  /// selected background gets a slight transparency shift.
  final bool isFocused;

  /// Hover state. Included for parity; can be consumed by custom [header]/[footer].
  final bool isHovered;

  /// Fixed width for the card container.
  final double width;

  /// Fixed height for the card container.
  final double height;

  /// Corner radius for the card container and badge.
  final double borderRadius;

  /// Inner padding for the card contents.
  final EdgeInsets padding;

  /// Animation duration for selection and focus transitions.
  final Duration animationDuration;

  /// Animation curve for selection and focus transitions.
  final Curve animationCurve;

  /// Optional badge label rendered at the top-left.
  final String? badgeLabel;

  /// Badge background color. When selected, the badge inverts its colors.
  final Color? badgeColor;

  /// Badge foreground color. When selected, the badge inverts its colors.
  final Color? badgeOnColor;

  /// Optional override for the title text style.
  final TextStyle? titleStyle;

  /// Optional custom header placed at the top of the card, above the spacer.
  /// If provided alongside [badgeLabel], the header is shown below the badge.
  final Widget? header;

  /// Optional custom footer placed at the bottom of the card, below the title.
  final Widget? footer;

  Color _backgroundColor() {
    if (isSelected) {
      if (isFocused) {
        return baseColor.withValues(alpha: 0.70);
      }
      return baseColor;
    }
    return baseColor.withValues(alpha: 0.15);
  }

  @override
  Widget build(BuildContext context) {
    final onBase =
        onBaseColor ?? Theme.of(context).colorScheme.surfaceContainerLowest;

    final resolvedTitleStyle =
        (titleStyle ??
                Theme.of(context).textTheme.titleMedium!.copyWith(
                  fontSize: 16,
                  fontVariations: [.weight(600)],
                ))
            .copyWith(color: isSelected ? onBase : baseColor);

    final card = AnimatedContainer(
      duration: animationDuration,
      curve: animationCurve,
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: _backgroundColor(),
        borderRadius: .circular(borderRadius),
        border: .all(
          width: 2,
          color: isFocused ? baseColor : Colors.transparent,
        ),
      ),
      padding: padding,
      child: IconTheme(
        data: IconThemeData(color: isSelected ? onBase : baseColor),
        child: Column(
          crossAxisAlignment: .start,
          children: [
            if (badgeLabel != null)
              _Badge(
                label: badgeLabel!,
                isSelected: isSelected,
                color: (badgeColor ?? baseColor).withValues(alpha: 0.90),
                onColor: badgeOnColor ?? onBase,
              ),
            if (header != null) ...[
              if (badgeLabel != null) const SizedBox(height: 6),
              header!,
            ],
            const Spacer(),
            Text(
              title,
              maxLines: 3,
              overflow: .ellipsis,
              style: resolvedTitleStyle,
            ),
            if (footer != null) ...[const SizedBox(height: 6), footer!],
          ],
        ),
      ),
    ).animate(target: isHovered ? 1 : 0).hoverScale(isHovered);

    return Surface(color: _backgroundColor(), child: card);
  }
}

class _Badge extends StatelessWidget {
  const _Badge({
    required this.label,
    required this.isSelected,
    required this.color,
    required this.onColor,
  });

  final String label;
  final bool isSelected;
  final Color color;
  final Color onColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const .symmetric(horizontal: 10, vertical: 4),
      decoration: ShapeDecoration(
        color: isSelected ? onColor : color,
        shape: const StadiumBorder(),
      ),
      child: Text(
        label.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall!.copyWith(
          fontSize: 11,
          letterSpacing: 0.7,
          fontVariations: [.weight(700)],
          color: isSelected ? color : onColor,
        ),
      ),
    );
  }
}
