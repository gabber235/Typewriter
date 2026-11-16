import "package:typewriter_panel/typewriter_panel.dart";

/// Presents one app bar action without replacing its focus owner on resize.
///
/// The feature owns the command, popup, and status. The control shortens its
/// decorative content when the layout assigns a compact width. [preferredWidth]
/// reserves a wide presentation for controls such as primary search.
class AppBarControl extends StatelessWidget {
  const AppBarControl({
    required this.contentBuilder,
    required this.onPressed,
    required this.tooltip,
    required this.semanticLabel,
    this.face = ButtonFace.quiet,
    this.focusNode,
    this.color,
    this.preferredWidth,
    super.key,
  });

  final Widget Function(BuildContext context, bool compact) contentBuilder;
  final VoidCallback onPressed;
  final String tooltip;
  final String semanticLabel;
  final FocusNode? focusNode;

  /// Overrides the face colour, as a status does.
  final Color? color;
  final double? preferredWidth;

  /// Quiet for most controls; filled for the bar's main action.
  final ButtonFace face;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final compact = constraints.maxWidth <= constraints.maxHeight;
      void reveal(bool focused) {
        if (!focused) return;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (context.mounted) {
            Scrollable.ensureVisible(context, alignment: .5);
          }
        });
      }

      return Focus(
        canRequestFocus: false,
        skipTraversal: true,
        onFocusChange: reveal,
        child: SizedBox(
          width: preferredWidth,
          child: Button(
            face: face,
            focusNode: focusNode,
            label: semanticLabel,
            tooltip: tooltip,
            color: color,
            onPressed: onPressed,
            child: contentBuilder(context, compact),
          ),
        ),
      );
    },
  );
}

/// Ordinary app bar decorations, with labels and shortcuts hidden when compact.
class AppBarControlContent extends StatelessWidget {
  const AppBarControlContent({
    required this.icon,
    required this.compact,
    this.label,
    this.shortcut,
    this.rippling = false,
    super.key,
  });

  final Widget icon;
  final bool compact;
  final String? label;
  final Widget? shortcut;

  /// The label is a status word of work still running, and ripples.
  final bool rippling;

  @override
  Widget build(BuildContext context) {
    // Compact shows the icon alone, also while the bar animates the control
    // narrower than the icon.
    if (compact) return icon;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        icon,
        if (label != null)
          Flexible(
            child: Padding(
              padding: EdgeInsets.only(left: context.spacing.space2),
              child: MotionLabel(label!, rippling: rippling),
            ),
          ),
        if (shortcut != null) ...[
          SizedBox(width: context.spacing.space2),
          shortcut!,
        ],
      ],
    );
  }
}
