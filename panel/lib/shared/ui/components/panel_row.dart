import "package:typewriter_panel/typewriter_panel.dart";

/// A list row without Material: [leading], a [title] over an optional
/// [subtitle], and [trailing]. With [onPressed] it is a bare [Button], so
/// press, hover and focus follow the motion tokens; [selected] fills it.
class PanelRow extends StatelessWidget {
  const PanelRow({
    required this.title,
    this.leading,
    this.subtitle,
    this.trailing,
    this.onPressed,
    this.label = "",
    this.selected = false,
    this.selectedColor,
    this.dense = false,
    this.padding,
    super.key,
  });

  final Widget title;
  final Widget? leading;
  final Widget? subtitle;
  final Widget? trailing;
  final FutureOr<void> Function()? onPressed;

  /// The button's name, read in place of the title and subtitle text;
  /// empty when the row's own text names it, which is then read as a
  /// button.
  final String label;
  final bool selected;

  /// The fill of a selected row; brand by default.
  final Color? selectedColor;

  /// A compact row, as in menus and pickers.
  final bool dense;

  /// Replaces the row's own inset, such as zero inside a padded list.
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final text = context.theme.textTheme;
    final fill = selectedColor ?? context.colors.brand;
    final Widget row = ColoredBox(
      color: fill.withValues(alpha: selected ? 0.10 : 0),
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: dense ? 44 : 56),
        child: Padding(
          padding:
              padding ??
              EdgeInsets.symmetric(
                horizontal: dense
                    ? context.spacing.space3
                    : context.spacing.space4,
                vertical: context.spacing.space1,
              ),
          child: IconTheme.merge(
            data: IconThemeData(color: Surface.secondaryForegroundOf(context)),
            child: Row(
              spacing: dense ? context.spacing.space3 : context.spacing.space4,
              children: [
                ?leading,
                Expanded(
                  child: ExcludeSemantics(
                    excluding: onPressed != null && label.isNotEmpty,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        DefaultTextStyle.merge(
                          style: (dense ? text.bodyMedium : text.bodyLarge)
                              ?.copyWith(color: Surface.foregroundOf(context)),
                          child: title,
                        ),
                        if (subtitle case final subtitle?)
                          DefaultTextStyle.merge(
                            style: text.bodySmall?.copyWith(
                              color: Surface.secondaryForegroundOf(context),
                            ),
                            child: subtitle,
                          ),
                      ],
                    ),
                  ),
                ),
                ?trailing,
              ],
            ),
          ),
        ),
      ),
    );
    if (onPressed == null) return row;
    // One node per row, as a list row reads: its button, state and text.
    return MergeSemantics(
      child: Button(
        face: ButtonFace.bare,
        label: label,
        onPressed: onPressed,
        child: Semantics(button: true, selected: selected, child: row),
      ),
    );
  }
}
