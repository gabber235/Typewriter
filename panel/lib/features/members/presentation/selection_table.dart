import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

/// The rows a members or join codes tab owns and the ids selected among
/// them; a tab builds it once and hands it to whichever of its table or list
/// the window shows.
@immutable
final class SelectableRows<T> {
  const SelectableRows({required this.rows, required this.selectedIds});

  final AnimatedRows<T> rows;
  final ValueNotifier<Set<skir.RecordId>> selectedIds;
}

/// A table of selectable rows on a surface, filling the rest of the scroll
/// view: a header row with a select all checkbox, one column per label in
/// [labels], and an unlabelled actions column. The first labelled column is
/// the row's main text, where a hold shows its line and refusal. The members
/// and join code tables share it; each builds its own rows.
class SelectionTable<T> extends StatelessWidget {
  const SelectionTable({
    required this.selection,
    required this.idOf,
    required this.labels,
    required this.columnWidths,
    required this.emptyBuilder,
    required this.rowBuilder,
    this.hasScrollBody = true,
    super.key,
  });

  final SelectableRows<T> selection;

  /// The id a row is selected by.
  final skir.RecordId Function(T item) idOf;

  /// The labelled columns between the checkbox and the actions column.
  final List<String> labels;
  final Map<int, TableColumnWidth> columnWidths;
  final WidgetBuilder emptyBuilder;
  final AnimatedTableRowBuilder<T> rowBuilder;
  final bool hasScrollBody;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final SelectableRows(:rows, :selectedIds) = selection;
    final items = rows.items;
    final selected = selectedIds.value;
    final allSelected = items.isNotEmpty && selected.length == items.length;
    final someSelected = selected.isNotEmpty && selected.length < items.length;
    final cellPadding = EdgeInsets.symmetric(
      horizontal: context.spacing.space2,
      vertical: context.spacing.space3,
    );

    return SliverRowAnchor(
      sliver: SliverFillRemaining(
        hasScrollBody: hasScrollBody,
        child: AnimatedTable<T>(
          rows: rows,
          lineColumn: 1,
          columnWidths: columnWidths,
          defaultVerticalAlignment: TableCellVerticalAlignment.middle,
          headerRows: [
            TableRow(
              decoration: BoxDecoration(color: Surface.colorOf(context)),
              children: [
                TableCell(
                  verticalAlignment: TableCellVerticalAlignment.middle,
                  child: Padding(
                    padding: cellPadding,
                    child: SelectionCheck(
                      value: allSelected ? true : (someSelected ? null : false),
                      onChanged: () =>
                          selectedIds.value = allSelected || someSelected
                          ? {}
                          : items.map(idOf).toSet(),
                    ),
                  ),
                ),
                for (final label in labels)
                  TableCell(
                    child: Padding(
                      padding: cellPadding,
                      child: Text(
                        label,
                        style: theme.textTheme.bodyMedium!.copyWith(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                const TableCell(child: SizedBox.shrink()),
              ],
            ),
          ],
          emptyBuilder: emptyBuilder,
          tableBuilder: (context, table) => Surface(
            color: Surface.colorOf(context),
            child: ClipRRect(
              borderRadius: context.shapes.mediumBorderRadius,
              child: table,
            ),
          ),
          rowBuilder: rowBuilder,
        ),
      ),
    );
  }
}
