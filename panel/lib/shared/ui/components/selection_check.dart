import "package:typewriter_panel/typewriter_panel.dart";

/// A check that says whether something is selected: [value] true is
/// selected, false is not, and null is partly, as a select all over a
/// list where only some rows are.
///
/// The check fills with the accent as it turns on; it never adds an
/// outline. [onChanged] runs on a click, or when Space or Enter is let go;
/// without it the check is heard as unavailable and takes no focus. Inside
/// a row that owns selection keys, wrap it in [ExcludeFocus] so the row
/// stays the one focus stop.
class SelectionCheck extends HookWidget {
  const SelectionCheck({
    required this.value,
    this.onChanged,
    this.semanticLabel,
    this.autofocus = false,
    super.key,
  });

  final bool? value;
  final VoidCallback? onChanged;
  final String? semanticLabel;
  final bool autofocus;

  static const double _box = 18;
  static const double _target = 40;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final enabled = onChanged != null;
    final on = useMotion(MotionToken.ink, value == false ? 0 : 1);
    final t = on.value.clamp(0.0, 1.0);
    final accent = enabled ? colors.accent : colors.contentDisabled;
    final fill = Color.lerp(
      colors.contentSecondary.withValues(alpha: 0.16),
      accent,
      t,
    )!;
    return Semantics(
      label: semanticLabel,
      checked: value ?? false,
      mixed: value == null,
      enabled: enabled,
      // Space or Enter presses the check and flips it once let go, as a
      // button acts.
      child: KeyPress(
        enabled: enabled,
        child: FocusableActionDetector(
          enabled: enabled,
          autofocus: autofocus,
          mouseCursor: enabled
              ? SystemMouseCursors.click
              : SystemMouseCursors.basic,
          actions: {
            ActivateIntent: CallbackAction<ActivateIntent>(
              onInvoke: (_) => onChanged?.call(),
            ),
          },
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onChanged,
            child: SizedBox.square(
              dimension: _target,
              child: Center(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: fill,
                    borderRadius: BorderRadius.circular(context.shapes.small),
                  ),
                  child: SizedBox.square(
                    dimension: _box,
                    child: Opacity(
                      opacity: t,
                      child: Transform.scale(
                        scale: 0.6 + 0.4 * t,
                        child: Icon(
                          value == null
                              ? Icons.remove_rounded
                              : Icons.check_rounded,
                          size: 14,
                          color: fill.contrastingForeground,
                        ),
                      ),
                    ),
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
