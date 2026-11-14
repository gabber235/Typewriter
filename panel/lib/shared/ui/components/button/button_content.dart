import "package:typewriter_panel/typewriter_panel.dart";

/// The face of every faced [Button]: a soft filled shape with its icon and
/// label, painted from the theme tokens. No face draws a border or a shadow;
/// depth appears only in motion.
class ButtonContent extends StatelessWidget {
  const ButtonContent({
    required this.face,
    required this.unavailable,
    this.color,
    this.icon,
    this.label,
    this.content,
    this.dense = false,
    this.ink,
    super.key,
  });

  final ButtonFace face;

  /// The button cannot be pressed. It shows pressed in through its [Button],
  /// never as faded text.
  final bool unavailable;

  /// Overrides the face colour.
  final Color? color;
  final Widget? icon;
  final Widget? label;

  /// Painted in place of [icon] and [label].
  final Widget? content;

  /// A compact face: 8 px smaller each way, as authored compact density.
  final bool dense;

  /// The press splash, painted over the fill and under the label.
  final PressInk? ink;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final accent = color ?? colors.brand;
    final (fill, foreground) = switch (face) {
      ButtonFace.filled || ButtonFace.floating => (accent, accent.on(context)),
      ButtonFace.outlined => (
        accent.withValues(alpha: context.stateTokens.hoverOpacity),
        color ?? colors.brandText,
      ),
      ButtonFace.quiet ||
      ButtonFace.icon => (colors.clear, color ?? colors.contentPrimary),
      ButtonFace.bare => throw StateError(
        "A bare button paints its own child.",
      ),
    };
    // Content brings its own inner spacing, as an app bar control's does.
    final padding = switch (face) {
      _ when content != null => EdgeInsets.all(context.spacing.space2),
      ButtonFace.icon => EdgeInsets.all(context.spacing.space2),
      ButtonFace.floating => EdgeInsets.all(context.spacing.space4),
      _ => EdgeInsets.symmetric(
        horizontal: context.spacing.space3,
        vertical: context.spacing.space2,
      ),
    };
    final shrink = dense ? 8.0 : 0.0;
    return ConstrainedBox(
      constraints: BoxConstraints(
        minHeight: (context.isMobile ? 44 : 32) - shrink,
        minWidth: 32 - shrink,
      ),
      child: DecoratedBox(
        decoration: ShapeDecoration(shape: face.shapeIn(context), color: fill),
        child: ClipPath(
          clipper: ShapeBorderClipper(shape: face.shapeIn(context)),
          child: CustomPaint(
            painter: ink,
            child: Padding(
              padding: dense ? padding - EdgeInsets.all(shrink / 2) : padding,
              child: IconTheme.merge(
                data: IconThemeData(color: foreground, size: 20),
                child: DefaultTextStyle.merge(
                  style: context.theme.textTheme.labelLarge?.copyWith(
                    color: foreground,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    spacing: context.spacing.space2,
                    children: [
                      if (content case final content?)
                        Flexible(child: content)
                      else ...[
                        ?icon,
                        if (label case final label?) Flexible(child: label),
                      ],
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
