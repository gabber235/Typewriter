import "package:typewriter_panel/typewriter_panel.dart";

/// Renders the compact, shared app bar treatment for an interaction mode.
///
/// [label] is uppercased for presentation. [color] controls the text and
/// default translucent background; [backgroundColor] overrides that derived
/// background when a mode needs a stronger visual surface.
class ModeDisplayChip extends StatelessWidget {
  const ModeDisplayChip({
    required this.label,
    required this.color,
    this.backgroundColor,
    super.key,
  });

  /// Text shown in uppercase inside the chip.
  final String label;

  /// Foreground color and the basis for the default background.
  final Color color;

  /// Optional explicit background color. When null, a theme aware alpha of
  /// [color] is used.
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: context.spacing.space2,
        vertical: context.spacing.space1,
      ),
      decoration: BoxDecoration(
        color:
            backgroundColor ??
            color.withValues(alpha: context.isDarkMode ? .1 : .2),
        borderRadius: context.shapes.smallBorderRadius,
      ),
      child: Text(
        label.toUpperCase(),
        style: Theme.of(context).textTheme.bodyMedium!
            .copyWith(fontSize: 12, color: color, fontWeight: FontWeight.w500),
      ),
    );
  }
}
