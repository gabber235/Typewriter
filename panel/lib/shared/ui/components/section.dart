import "package:typewriter_panel/typewriter_panel.dart";

/// Groups related content in a themed, clipped surface card.
///
/// Use this shared container when the content should inherit its background
/// through [Surface]. [margin] controls the space outside the card.
class Section extends StatelessWidget {
  const Section({
    required this.child,
    this.margin = const EdgeInsets.all(8),
    this.backgroundColor,
    super.key,
  });

  /// Content rendered inside the section's surface and clipping boundary.
  final Widget child;

  final Color? backgroundColor;

  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext context) {
    final color =
        backgroundColor ?? Theme.of(context).colorScheme.surfaceContainerLowest;
    final radius = context.shapes.largeBorderRadius;

    return Card(
      elevation: 0,
      color: color,
      margin: margin,
      shape: RoundedRectangleBorder(borderRadius: radius),
      child: Surface(
        color: color,
        foreground: backgroundColor == null
            ? context.colors.contentPrimary
            : Color.alphaBlend(color, Surface.colorOf(context)).on(context),
        secondaryForeground: backgroundColor == null
            ? context.colors.contentSecondary
            : null,
        child: ClipRRect(borderRadius: radius, child: child),
      ),
    );
  }
}
