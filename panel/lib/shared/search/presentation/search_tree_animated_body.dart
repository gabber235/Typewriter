import "package:typewriter_panel/typewriter_panel.dart";

/// Displays tree rows in a sliver list keyed by [SearchTreeRow.key].
///
/// Search state and expansion state remain owned by the controller. Rows the
/// user's typing or expanding adds slide in with rowIn, rows it drops squash
/// shut with listOut, and a reordered result moves in place.
class SearchTreeAnimatedBody extends HookWidget {
  const SearchTreeAnimatedBody({
    required this.rows,
    required this.rowRenderers,
    super.key,
  });

  final List<SearchTreeRow> rows;
  final Map<String, SearchResultRowBuilder> rowRenderers;

  @override
  Widget build(BuildContext context) {
    final animated = useAnimatedRows(items: rows, identity: (row) => row.key);
    return SliverAnimatedRows(
      rows: animated,
      itemBuilder: (context, entry) =>
          SearchTreeRowWidget(row: entry.item, rowRenderers: rowRenderers),
    );
  }
}
