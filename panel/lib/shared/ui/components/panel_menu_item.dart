import "package:typewriter_panel/typewriter_panel.dart";

/// One choice in a popover menu, without Material: a focusable row that
/// fills when focused or highlighted.
class PanelMenuItem extends HookWidget {
  const PanelMenuItem({
    required this.label,
    required this.onPressed,
    this.leading,
    this.trailing,
    this.enabled = true,
    this.highlighted = false,
    this.color,
    this.child,
    super.key,
  });

  final String label;
  final VoidCallback onPressed;
  final Widget? leading;
  final Widget? trailing;
  final bool enabled;

  /// Drawn as focused while focus stays elsewhere (a filtering field).
  final bool highlighted;

  /// The text and icon colour, such as red for a destructive choice.
  final Color? color;

  /// Shown in place of the [label] text, which still names the item.
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final focused = useState(false);
    final lit = enabled && (focused.value || highlighted);
    final tint = color ?? context.colors.contentPrimary;
    final foreground = enabled
        ? tint
        : color?.withValues(alpha: 0.6) ?? context.colors.contentSecondary;
    return Semantics(
      container: true,
      button: true,
      enabled: enabled,
      selected: highlighted,
      label: child == null ? null : label,
      child: FocusableActionDetector(
        enabled: enabled,
        onShowFocusHighlight: (value) => focused.value = value,
        onFocusChange: (value) => focused.value = value,
        actions: {
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (_) {
              onPressed();
              return null;
            },
          ),
        },
        mouseCursor: enabled ? SystemMouseCursors.click : MouseCursor.defer,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: enabled ? onPressed : null,
          child: ColoredBox(
            color: lit
                ? context.colors.surfaceEmphasized
                : context.colors.surface.withValues(alpha: 0),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: context.spacing.space3,
                vertical: context.spacing.space2,
              ),
              child: IconTheme.merge(
                data: IconThemeData(color: foreground, size: 16),
                child: Row(
                  spacing: context.spacing.space2,
                  children: [
                    ?leading,
                    Expanded(
                      child: DefaultTextStyle.merge(
                        style: context.theme.textTheme.labelLarge?.copyWith(
                          color: foreground,
                        ),
                        child: switch (child) {
                          null => Text(label),
                          final shown => ExcludeSemantics(child: shown),
                        },
                      ),
                    ),
                    ?trailing,
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
