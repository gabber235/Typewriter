import "package:typewriter_panel/typewriter_panel.dart";

/// Renders a selectable grid card with an optional badge and title.
///
/// This widget is presentation only. It does not manage selection, focus, or
/// hover state. Provide those states through the constructor and keep tap,
/// keyboard focus, and selection ownership in the parent.
class GridSelectableCard extends HookWidget {
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

  /// Focus state, for callers that style text. The card draws no focus
  /// itself: the focus ring layer rings it.
  final bool isFocused;

  /// Raises the card with `hoverIn` and drives the
  /// [PresentationInteractionScope] observation.
  final bool isHovered;

  /// Fixed width for the card container.
  final double width;

  /// Fixed height for the card container.
  final double height;

  /// Corner radius for the card container and badge.
  final double borderRadius;

  /// Inner padding for the card contents.
  final EdgeInsets padding;

  /// Optional badge label rendered at the top left.
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
      return baseColor;
    }
    return baseColor.withValues(alpha: baseColor.a * 0.15);
  }

  @override
  Widget build(BuildContext context) {
    final onBase =
        onBaseColor ?? Theme.of(context).colorScheme.surfaceContainerLowest;

    final interaction = PresentationInteraction(
      selected: isSelected,
      focused: isFocused,
      hovered: isHovered,
    );
    final decoration = BoxDecoration(
      color: _backgroundColor(),
      borderRadius: .circular(borderRadius),
    );
    // The fill plays the move the token table picks for the state change:
    // selection fades with ink.
    final motion = useStateMotion(interaction.widgetStates, target: decoration);

    final card = SurfaceContainer(
      motion: motion,
      foreground: isSelected ? onBase : baseColor,
      width: width,
      height: height,
      decoration: decoration,
      padding: padding,
      child: Builder(
        builder: (context) => Column(
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
            Expanded(
              child: Align(
                alignment: Alignment.bottomLeft,
                child: Text(
                  title,
                  maxLines: 3,
                  overflow: .ellipsis,
                  style:
                      titleStyle ??
                      Theme.of(context).textTheme.titleMedium!.copyWith(
                        fontSize: 16,
                        fontVariations: [.weight(600)],
                      ),
                ),
              ),
            ),
            if (footer != null) ...[const SizedBox(height: 6), footer!],
          ],
        ),
      ),
    );

    return PresentationInteractionScope(
      value: interaction,
      child: Rise(raised: isHovered, child: card),
    );
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
      padding: EdgeInsets.symmetric(
        horizontal: 10,
        vertical: context.spacing.space1,
      ),
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
