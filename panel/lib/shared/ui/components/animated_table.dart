import "package:typewriter_panel/typewriter_panel.dart";

/// Builds one active row. The animation is complete for settled rows and
/// runs forward for inserted rows.
typedef AnimatedTableRowBuilder = TableRow Function(
  BuildContext context,
  int index,
  Animation<double> animation,
);

/// Builds a row that remains available while its removal animation reverses.
typedef AnimatedTableRemovedRowBuilder = TableRow Function(
  BuildContext context,
  Animation<double> animation,
);

/// Builds the transition applied independently to each cell or empty state.
typedef AnimatedTableTransitionBuilder = Widget Function(
  BuildContext context,
  Animation<double> animation,
  Widget child,
);

/// Wraps the assembled table without taking ownership of its rows.
typedef AnimatedTableBuilder = Widget Function(
  BuildContext context,
  Table table,
);

/// Maintains a table's active rows while animating insertion and removal.
///
/// Row indices are logical active indices. An outgoing row stays in the visual
/// list until its reverse animation completes, and is excluded from semantics,
/// focus, and pointer interaction during that period. Callers own the data
/// source and must update it consistently with the state methods.
class AnimatedTable extends StatefulWidget {
  const AnimatedTable({
    required this.initialItemCount,
    required this.rowBuilder,
    required this.transitionBuilder,
    this.headerRows = const [],
    this.emptyBuilder,
    this.emptyTransitionBuilder,
    this.tableBuilder,
    this.columnWidths,
    this.defaultColumnWidth = const FlexColumnWidth(),
    this.textDirection,
    this.border,
    this.defaultVerticalAlignment = TableCellVerticalAlignment.top,
    this.textBaseline,
    super.key,
  }) : assert(initialItemCount >= 0);

  final int initialItemCount;
  final AnimatedTableRowBuilder rowBuilder;
  final AnimatedTableTransitionBuilder transitionBuilder;
  final List<TableRow> headerRows;
  final WidgetBuilder? emptyBuilder;
  final AnimatedTableTransitionBuilder? emptyTransitionBuilder;
  final AnimatedTableBuilder? tableBuilder;
  final Map<int, TableColumnWidth>? columnWidths;
  final TableColumnWidth defaultColumnWidth;
  final TextDirection? textDirection;
  final TableBorder? border;
  final TableCellVerticalAlignment defaultVerticalAlignment;
  final TextBaseline? textBaseline;

  @override
  AnimatedTableState createState() => AnimatedTableState();
}

class AnimatedTableState extends State<AnimatedTable>
    with TickerProviderStateMixin, AnimatedRows<AnimatedTable, TableRow> {
  @override
  int get initialRowCount => widget.initialItemCount;

  TableRow _buildRow(AnimatedRow<TableRow> entry) {
    final source = entry.outgoing
        ? entry.removedBuilder!(context, entry.animation)
        : widget.rowBuilder(context, entry.index, entry.animation);
    return TableRow(
      key: entry.outgoing ? ObjectKey(entry) : source.key ?? ObjectKey(entry),
      decoration: source.decoration,
      children: source.children.map((child) {
        final content = child is TableCell ? child.child : child;
        var transitioned = widget.transitionBuilder(
          context,
          entry.animation,
          content,
        );
        if (entry.outgoing) {
          transitioned = ExcludeSemantics(
            child: ExcludeFocus(child: IgnorePointer(child: transitioned)),
          );
        }
        if (child is! TableCell) return transitioned;
        return TableCell(
          key: entry.outgoing && child.key != null
              ? ValueKey((entry, child.key))
              : child.key,
          verticalAlignment: child.verticalAlignment,
          child: transitioned,
        );
      }).toList(),
    );
  }

  Widget _buildTable() {
    final table = Table(
      columnWidths: widget.columnWidths,
      defaultColumnWidth: widget.defaultColumnWidth,
      textDirection: widget.textDirection,
      border: widget.border,
      defaultVerticalAlignment: widget.defaultVerticalAlignment,
      textBaseline: widget.textBaseline,
      children: [...widget.headerRows, ...rows.map(_buildRow)],
    );
    return widget.tableBuilder?.call(context, table) ?? table;
  }

  @override
  Widget build(BuildContext context) {
    final isVisuallyEmpty = rows.isEmpty;
    if (widget.emptyBuilder == null) {
      return AnimatedSize(
        duration: const Duration(milliseconds: 300),
        child: _buildTable(),
      );
    }
    final child = isVisuallyEmpty
        ? KeyedSubtree(
            key: const ValueKey("empty"),
            child: widget.emptyBuilder!(context),
          )
        : KeyedSubtree(key: const ValueKey("table"), child: _buildTable());
    return AnimatedSize(
      duration: const Duration(milliseconds: 300),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        layoutBuilder: (currentChild, previousChildren) {
          return Stack(
            alignment: Alignment.topCenter,
            children: [
              if (previousChildren.isNotEmpty) previousChildren.last,
              ?currentChild,
            ],
          );
        },
        transitionBuilder: (child, animation) {
          final transition =
              widget.emptyTransitionBuilder ?? widget.transitionBuilder;
          return transition(context, animation, child);
        },
        child: child,
      ),
    );
  }
}
