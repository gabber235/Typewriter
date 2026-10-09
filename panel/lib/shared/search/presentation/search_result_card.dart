import "package:typewriter_panel/typewriter_panel.dart";

/// Shared interactive surface for one editor search result.
///
/// Result specific widgets supply content and semantic color. The shared search controller owns
/// selection and focus; this card only projects those flags into visual state and forwards tap
/// callbacks. A missing callback deliberately leaves the corresponding interaction disabled.
class SearchResultCard extends HookWidget {
  const SearchResultCard({
    required this.color,
    required this.content,
    this.prefix,
    this.suffix,
    this.selected = false,
    this.focused = false,
    this.onTap,
    this.onLongPress,
    super.key,
  });

  final Color color;
  final Widget? prefix;
  final Widget content;
  final Widget? suffix;
  final bool selected;
  final bool focused;

  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final states = useWidgetStatesController();
    final surfaceColor = Surface.colorOf(context);
    final surfaceBrightness = ThemeData.estimateBrightnessForColor(
      surfaceColor,
    );
    final alpha = selected ? 0.22 : 0.06;
    final backgroundColor = focused
        ? color
        : Color.alphaBlend(color.withValues(alpha: alpha), surfaceColor);
    final borderColor = selected ? color : Colors.transparent;

    return SurfaceContainer(
      duration: 180.ms,
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        color: focused ? color : color.withValues(alpha: color.a * alpha),
        borderRadius: context.shapes.mediumBorderRadius,
        border: Border.all(color: borderColor, width: 1.4),
      ),
      foregroundFor: (context, displayed) =>
          focused ? displayed.on(context) : context.colors.contentPrimary,
      child: Material(
        color: Colors.transparent,
        borderRadius: context.shapes.mediumBorderRadius,
        child: InkWell(
          statesController: states,
          borderRadius: context.shapes.mediumBorderRadius,
          onTap: onTap,
          onLongPress: onLongPress,
          hoverColor: switch ((focused, surfaceBrightness)) {
            (true, Brightness.dark) => backgroundColor.lighter(0.1),
            (true, Brightness.light) => backgroundColor.darker(0.1),
            (false, _) => Color.alphaBlend(
              color.withValues(alpha: alpha + 0.1),
              surfaceColor,
            ),
          },
          splashColor: switch ((focused, surfaceBrightness)) {
            (true, Brightness.dark) => backgroundColor.lighter(0.2),
            (true, Brightness.light) => backgroundColor.darker(0.2),
            (false, _) => Color.alphaBlend(
              color.withValues(alpha: alpha + 0.3),
              surfaceColor,
            ),
          },
          highlightColor: Colors.transparent,
          child: ValueListenableBuilder<Set<WidgetState>>(
            valueListenable: states,
            builder: (context, value, _) => PresentationInteractionScope(
              value: PresentationInteraction.fromWidgetStates(value).copyWith(
                selected: selected,
                focused: focused || value.contains(WidgetState.focused),
              ),
              child: ClipRRect(
                borderRadius: context.shapes.mediumBorderRadius,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 64),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      if (prefix != null)
                        Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: context.spacing.space1,
                          ),
                          child: prefix,
                        ),
                      Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(
                            top: context.spacing.space2,
                            right: 10,
                            bottom: context.spacing.space2,
                            left: 10,
                          ),
                          child: content,
                        ),
                      ),
                      if (suffix != null)
                        Padding(
                          padding: const EdgeInsets.only(
                            top: 10,
                            right: 10,
                            bottom: 10,
                          ),
                          child: suffix,
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
