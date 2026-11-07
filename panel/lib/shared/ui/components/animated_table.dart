import "package:typewriter_panel/typewriter_panel.dart";

/// Wraps the assembled table without taking ownership of its rows.
typedef AnimatedTableBuilder = Widget Function(
  BuildContext context,
  Table table,
);

/// A table over the rows of one [useAnimatedRows]: rows that load join the
/// load run one slot per row, rows added later slide in with rowIn, and
/// rows that leave squash shut with listOut, all cells of a row as one.
/// Leaving and sending rows are excluded from semantics, traversal and
/// pointer input without losing focus. The empty state shows once the last
/// leaving row is gone.
class AnimatedTable<T> extends HookWidget {
  const AnimatedTable({
    required this.rows,
    required this.rowBuilder,
    this.headerRows = const [],
    this.emptyBuilder,
    this.tableBuilder,
    this.columnWidths,
    this.defaultColumnWidth = const FlexColumnWidth(),
    this.textDirection,
    this.border,
    this.defaultVerticalAlignment = TableCellVerticalAlignment.top,
    this.textBaseline,
    super.key,
  });

  final AnimatedRows<T> rows;
  final AnimatedTableRowBuilder<T> rowBuilder;
  final List<TableRow> headerRows;
  final WidgetBuilder? emptyBuilder;
  final AnimatedTableBuilder? tableBuilder;
  final Map<int, TableColumnWidth>? columnWidths;
  final TableColumnWidth defaultColumnWidth;
  final TextDirection? textDirection;
  final TableBorder? border;
  final TableCellVerticalAlignment defaultVerticalAlignment;
  final TextBaseline? textBaseline;

  TableRow _row(BuildContext context, RowEntry<T> entry) {
    final source = rowBuilder(context, entry);
    return TableRow(
      key: ValueKey(entry.id),
      // The per row hook point; cells stay unaffected.
      decoration: entry.rowDecoration(context, source.decoration),
      children: [
        for (final child in source.children) _cell(child, entry.motion),
      ],
    );
  }

  TableRow _header(TableRow header, Object slot) => TableRow(
    key: header.key,
    decoration: header.decoration,
    children: [
      for (final child in header.children)
        _cell(
          child,
          (content) =>
              Enter(token: MotionToken.loadIn, group: slot, child: content),
        ),
    ],
  );

  Widget _cell(Widget child, Widget Function(Widget content) wrap) {
    if (child is! TableCell) return wrap(child);
    return TableCell(
      key: child.key,
      verticalAlignment: child.verticalAlignment,
      child: wrap(child.child),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Header rows join the load run as one slot each, like data rows.
    final headerSlots = useMemoized(() => <Object>[]);
    while (headerSlots.length < headerRows.length) {
      headerSlots.add(Object());
    }
    final empty = emptyBuilder;
    if (empty == null || rows.entries.isNotEmpty) {
      // Row height follows Enter and Leave, so the table needs no
      // AnimatedSize.
      final table = Table(
        columnWidths: columnWidths,
        defaultColumnWidth: defaultColumnWidth,
        textDirection: textDirection,
        border: border,
        defaultVerticalAlignment: defaultVerticalAlignment,
        textBaseline: textBaseline,
        children: [
          for (final (index, header) in headerRows.indexed)
            _header(header, headerSlots[index]),
          for (final entry in rows.entries) _row(context, entry),
        ],
      );
      return tableBuilder?.call(context, table) ?? table;
    }
    // The last row has squashed shut. The empty state arrives as a row
    // would: with the load if the table started empty, otherwise from the
    // left.
    return Enter(
      token: rows.everHadRows ? MotionToken.rowIn : MotionToken.loadIn,
      child: KeyedSubtree(key: const ValueKey("empty"), child: empty(context)),
    );
  }
}
