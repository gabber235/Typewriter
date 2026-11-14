import "package:typewriter_panel/typewriter_panel.dart";

/// A row of [children] that acts as one control, such as a switch or a
/// check with its label.
///
/// A click, or Space or Enter once let go as a button acts, calls
/// [onPressed]; without it the row takes no focus. The row is heard as one
/// node described by [semantics], which says whether it is enabled.
class PressableRow extends StatelessWidget {
  const PressableRow({
    required this.semantics,
    required this.children,
    this.onPressed,
    super.key,
  });

  final SemanticsProperties semantics;
  final List<Widget> children;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    return MergeSemantics(
      child: Semantics.fromProperties(
        properties: semantics,
        child: KeyPress(
          enabled: enabled,
          child: FocusableActionDetector(
            enabled: enabled,
            mouseCursor: enabled
                ? SystemMouseCursors.click
                : SystemMouseCursors.basic,
            actions: {
              ActivateIntent: CallbackAction<ActivateIntent>(
                onInvoke: (_) => onPressed?.call(),
              ),
            },
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onPressed,
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: context.spacing.space3,
                  vertical: context.spacing.space2,
                ),
                child: Row(spacing: context.spacing.space3, children: children),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
