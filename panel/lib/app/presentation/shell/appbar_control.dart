import "package:typewriter_panel/typewriter_panel.dart";

enum _AppBarControlFamily { text, filled }

/// Presents one app bar action without replacing its focus owner on resize.
///
/// The feature owns the command, popup, and status. The control shortens its
/// decorative content when the layout assigns a compact width. [preferredWidth]
/// reserves a wide presentation for controls such as primary search.
class AppBarControl extends StatelessWidget {
  const AppBarControl.text({
    required this.icon,
    required this.onPressed,
    required this.tooltip,
    required this.semanticLabel,
    this.label,
    this.shortcut,
    this.focusNode,
    this.style,
    this.preferredWidth,
    super.key,
  }) : _family = _AppBarControlFamily.text;

  const AppBarControl.filled({
    required this.icon,
    required this.onPressed,
    required this.tooltip,
    required this.semanticLabel,
    this.label,
    this.shortcut,
    this.focusNode,
    this.style,
    this.preferredWidth,
    super.key,
  }) : _family = _AppBarControlFamily.filled;

  final Widget icon;
  final VoidCallback onPressed;
  final String tooltip;
  final String semanticLabel;
  final String? label;
  final Widget? shortcut;
  final FocusNode? focusNode;
  final ButtonStyle? style;
  final double? preferredWidth;
  final _AppBarControlFamily _family;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final compact = constraints.maxWidth <= constraints.maxHeight;
      final geometry = ButtonStyle(
        minimumSize: const WidgetStatePropertyAll(Size(40, 40)),
        padding: WidgetStatePropertyAll(
          EdgeInsets.symmetric(horizontal: context.spacing.space2),
        ),
      ).merge(style);
      final content = ExcludeSemantics(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            icon,
            if (!compact && label != null)
              Flexible(
                child: Padding(
                  padding: EdgeInsets.only(left: context.spacing.space2),
                  child: Text(label!, overflow: TextOverflow.ellipsis),
                ),
              ),
            if (!compact && shortcut != null) ...[
              SizedBox(width: context.spacing.space2),
              shortcut!,
            ],
          ],
        ),
      );
      void reveal(bool focused) {
        if (!focused) return;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (context.mounted) {
            Scrollable.ensureVisible(context, alignment: .5);
          }
        });
      }

      return Tooltip(
        message: tooltip,
        child: Semantics(
          label: semanticLabel,
          child: SizedBox(
            width: preferredWidth,
            child: switch (_family) {
              _AppBarControlFamily.text => TextButton(
                focusNode: focusNode,
                onFocusChange: reveal,
                style: geometry,
                onPressed: onPressed,
                child: content,
              ),
              _AppBarControlFamily.filled => FilledButton(
                focusNode: focusNode,
                onFocusChange: reveal,
                style: geometry,
                onPressed: onPressed,
                child: content,
              ),
            },
          ),
        ),
      );
    },
  );
}
