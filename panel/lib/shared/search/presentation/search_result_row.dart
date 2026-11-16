import "package:typewriter_panel/typewriter_panel.dart";

/// How much room a result row takes. The surface showing the results decides:
/// dropdowns use compact rows, modals use cards.
enum SearchResultDensity { compact, card }

/// The uniform chrome of a search result or picker row: a [title] with an
/// [accent] and [leading] icon, a [kindLabel], and optional [body] details
/// and [footer] below the title.
///
/// The entire row owns activation. Supplied leading, body and footer content is
/// decorative: focus and pointer input are excluded so portable presentations
/// cannot install competing child interactions inside a search result.
final class SearchResultRow extends StatelessWidget {
  const SearchResultRow({
    required this.row,
    required this.density,
    this.title,
    this.body,
    this.accent,
    this.leading,
    this.kindLabel = "",
    this.footer,
    super.key,
  }) : assert(title != null || body != null);

  final SearchResultRowContext row;
  final SearchResultDensity density;

  /// The name of the result, such as a resource label.
  final String? title;

  /// Details below the title, or the whole content without a title.
  final Widget? body;
  final Color? accent;
  final Widget? leading;
  final String kindLabel;
  final Widget? footer;

  Widget decorative(Widget child) =>
      ExcludeFocus(child: IgnorePointer(child: child));

  @override
  Widget build(BuildContext context) {
    final color = accent ?? Theme.of(context).colorScheme.primary;
    final heading = title == null
        ? null
        : SearchResultTitle(title: title!, working: row.loading);
    final details = [?body, ?footer];
    final content = switch ((heading, details)) {
      (final heading?, []) => heading,
      (null, [final only]) => only,
      _ => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: context.spacing.space1,
        children: [?heading, ...details],
      ),
    };
    if (density == SearchResultDensity.compact) {
      final subtitle = switch (details) {
        [] => null,
        [final only] => only,
        _ => Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: context.spacing.space1,
          children: details,
        ),
      };
      // The cursor is the layer's travelling ring, never a selected fill.
      return RingCursor(
        active: row.focused,
        borderRadius: context.shapes.mediumBorderRadius,
        child: PanelRow(
          dense: true,
          selected: row.selected,
          selectedColor: color,
          leading: leading == null
              ? null
              : decorative(
                  IconTheme.merge(
                    data: IconThemeData(color: color),
                    child: leading!,
                  ),
                ),
          title: decorative(heading ?? subtitle!),
          subtitle: heading == null || subtitle == null
              ? null
              : decorative(subtitle),
          trailing: kindLabel.isEmpty
              ? null
              : SearchResultSuffix(
                  label: kindLabel,
                  shortcutActivator: row.shortcutActivator,
                  selected: row.selected,
                ),
          onPressed: row.onTap,
        ),
      );
    }
    return SearchResultCard(
      color: color,
      selected: row.selected,
      focused: row.focused,
      onTap: row.onTap,
      prefix: leading == null
          ? null
          : SearchResultIconTile(
              color: color,
              onColor: color.on(context),
              icon: decorative(leading!),
            ),
      content: decorative(content),
      suffix: SearchResultSuffix(
        label: kindLabel,
        shortcutActivator: row.shortcutActivator,
        selected: row.selected,
      ),
    );
  }
}
