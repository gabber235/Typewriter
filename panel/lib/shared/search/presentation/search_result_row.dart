import "package:typewriter_panel/typewriter_panel.dart";

enum SearchResultDensity { compact, card }

/// Composes a result renderer into a compact row or an accent card.
///
/// The entire row owns activation. Supplied leading, body and footer content is
/// decorative: focus and pointer input are excluded so portable presentations
/// cannot install competing child interactions inside a search result.
final class SearchResultRow extends StatelessWidget {
  const SearchResultRow({
    required this.row,
    required this.body,
    required this.density,
    this.accent,
    this.leading,
    this.kindLabel = "",
    this.footer,
    super.key,
  });

  final SearchResultRowContext row;
  final Widget body;
  final SearchResultDensity density;
  final Color? accent;
  final Widget? leading;
  final String kindLabel;
  final Widget? footer;

  Widget decorative(Widget child) =>
      ExcludeFocus(child: IgnorePointer(child: child));

  @override
  Widget build(BuildContext context) {
    final color = accent ?? Theme.of(context).colorScheme.primary;
    final content = footer == null
        ? body
        : Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: context.spacing.space1,
            children: [body, footer!],
          );
    if (density == SearchResultDensity.compact) {
      return ListTile(
        dense: true,
        minTileHeight: 44,
        contentPadding: EdgeInsets.symmetric(
          horizontal: context.spacing.space3,
        ),
        selected: row.selected || row.focused,
        selectedTileColor: color.withValues(alpha: 0.10),
        leading: row.loading
            ? const SizedBox.square(
                dimension: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : leading == null
            ? null
            : decorative(leading!),
        title: decorative(body),
        subtitle: footer == null ? null : decorative(footer!),
        trailing: kindLabel.isEmpty
            ? null
            : SearchResultSuffix(
                label: kindLabel,
                shortcutActivator: row.shortcutActivator,
                selected: row.selected,
              ),
        onTap: row.onTap,
      );
    }
    return SearchResultCard(
      color: color,
      selected: row.selected,
      focused: row.focused,
      onTap: row.onTap,
      prefix: leading == null && !row.loading
          ? null
          : SearchResultIconTile(
              color: color,
              onColor: color.on(context),
              focused: row.focused,
              loading: row.loading,
              icon: decorative(leading ?? const SizedBox.shrink()),
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
