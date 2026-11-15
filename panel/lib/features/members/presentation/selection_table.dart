import "package:typewriter_panel/typewriter_panel.dart";

/// One cell of a [SelectionTable] row after its selector cell.
@immutable
final class SelectionTableCell {
  /// A cell a click selects through, as a click on the row does.
  const SelectionTableCell(this.child) : selects = true;

  /// A cell of controls, such as a roles dropdown or a remove button, that
  /// take their own clicks.
  const SelectionTableCell.controls(this.child) : selects = false;

  final Widget child;
  final bool selects;
}

/// A table of selectable rows on a surface, filling the rest of the scroll
/// view: a header row, one column per label in [labels], and an unlabelled
/// actions column. The members and join code tables share it.
///
/// Each row is one [Selector] on the row's own focus node, in the page's
/// [SelectionSurface]: the first cell holds it, with the item's check in
/// select mode, and the cells a click selects through take its gestures.
/// The first labelled column is the row's main text, where a hold shows its
/// line and refusal. [shortcutsOf] gives the row's own commands, such as
/// holding Delete, answered while focus is anywhere in the row.
class SelectionTable<T> extends HookConsumerWidget {
  const SelectionTable({
    required this.rows,
    required this.selectableOf,
    required this.labelOf,
    required this.labels,
    required this.columnWidths,
    required this.emptyBuilder,
    required this.leadingBuilder,
    required this.cellsBuilder,
    required this.shortcutsOf,
    this.hasScrollBody = true,
    super.key,
  });

  final AnimatedRows<T> rows;
  final SelectableIdentifier Function(T item) selectableOf;

  /// What a screen reader names the row by.
  final String Function(T item) labelOf;

  /// The labelled columns between the selector column and the actions
  /// column.
  final List<String> labels;
  final Map<int, TableColumnWidth> columnWidths;
  final WidgetBuilder emptyBuilder;

  /// The selector cell's content beside the check, such as an avatar.
  final Widget Function(BuildContext context, T item, bool selected)
  leadingBuilder;

  /// The row's cells after the selector cell: one per label, then actions.
  final List<SelectionTableCell> Function(BuildContext context, T item)
  cellsBuilder;
  final List<ActionShortcut> Function(T item) shortcutsOf;
  final bool hasScrollBody;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final selection = ref.watch(selectionProvider);
    final links = useMemoized(() => <Object, SelectorLink>{});
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
                const TableCell(child: SizedBox.shrink()),
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
          rowBuilder: (context, entry) {
            final item = entry.item;
            final selectable = selectableOf(item);
            final selected = selection.contains(selectable);
            final link = links.putIfAbsent(entry.id, SelectorLink.new);
            Widget withShortcuts(Widget child) =>
                ManagedActionSet(shortcuts: shortcutsOf(item), child: child);
            return TableRow(
              key: ValueKey(entry.id),
              decoration: BoxDecoration(
                // Fill means selected; the ring layer shows focus.
                color: selected
                    ? theme.colorScheme.primaryContainer.withValues(alpha: 0.12)
                    : null,
              ),
              children: [
                TableCell(
                  verticalAlignment: TableCellVerticalAlignment.middle,
                  child: withShortcuts(
                    RowStop.attachedByChild(
                      bounds: RingBounds.tableRow,
                      borderRadius: context.shapes.mediumBorderRadius,
                      child: Selector(
                        selectableId: selectable,
                        focusNode: entry.focus,
                        link: link,
                        builder: (selected, focused, hovered) => Semantics(
                          label: labelOf(item),
                          child: Padding(
                            padding: cellPadding,
                            child: SelectorCheck(
                              child: leadingBuilder(context, item, selected),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                for (final cell in cellsBuilder(context, item))
                  TableCell(
                    child: withShortcuts(
                      RowStop(
                        role: RowRole.part,
                        child: cell.selects
                            ? SelectorLinkRegion(link: link, child: cell.child)
                            : cell.child,
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// A list of selectable cards, one [Selector] each on the row's own focus
/// node, in the page's [SelectionSurface]: the touch layout of the members,
/// join codes and join requests pages.
///
/// A tap selects the card and the inspector shows it; the card never opens
/// in place. In select mode each card shows its check at its corner.
/// [shortcutsOf] gives the card's own commands, such as holding Delete.
class SelectionCardList<T> extends HookConsumerWidget {
  const SelectionCardList({
    required this.rows,
    required this.selectableOf,
    required this.labelOf,
    required this.emptyBuilder,
    required this.contentBuilder,
    required this.shortcutsOf,
    super.key,
  });

  final AnimatedRows<T> rows;
  final SelectableIdentifier Function(T item) selectableOf;

  /// What a screen reader names the card by.
  final String Function(T item) labelOf;
  final WidgetBuilder emptyBuilder;
  final Widget Function(BuildContext context, T item, bool selected)
  contentBuilder;
  final List<ActionShortcut> Function(T item) shortcutsOf;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    // The empty state shows once the last leaving row is gone.
    if (rows.entries.isEmpty) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: emptyBuilder(context),
      );
    }
    return SliverAnimatedRows<T>(
      rows: rows,
      itemBuilder: (context, entry) {
        final item = entry.item;
        return Padding(
          padding: EdgeInsets.only(bottom: context.spacing.space3),
          child: ManagedActionSet(
            shortcuts: shortcutsOf(item),
            child: RowStop.attachedByChild(
              borderRadius: context.shapes.mediumBorderRadius,
              child: Selector(
                selectableId: selectableOf(item),
                focusNode: entry.focus,
                // The card reads as its label alone; the inspector reads the
                // rest.
                builder: (selected, focused, hovered) => Semantics(
                  label: labelOf(item),
                  excludeSemantics: true,
                  child: Surface(
                    color: selected
                        ? Color.alphaBlend(
                            theme.colorScheme.primaryContainer.withValues(
                              alpha: 0.3,
                            ),
                            Surface.colorOf(context),
                          )
                        : Surface.colorOf(context),
                    child: SelectorCheck(
                      placement: SelectorCheckPlacement.corner,
                      child: Padding(
                        padding: EdgeInsets.all(context.spacing.space3),
                        child: contentBuilder(context, item, selected),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// What a row's own command acts on.
extension SelectionOrRow on WidgetRef {
  /// The selection when it holds [row], otherwise [row] alone.
  List<SelectableIdentifier> selectionOrRow(SelectableIdentifier row) {
    final selection = read(selectionProvider);
    return selection.contains(row) ? selection : [row];
  }
}

/// Keeps a membership page's selection and held rows in step with its live
/// rows.
extension MembershipRowsUpkeep on WidgetRef {
  /// Publishes [rows] as the rows of [list] while the calling widget is
  /// mounted, and drops every selected item of type [I] that [live] no
  /// longer holds, so a member removed elsewhere leaves the selection while
  /// a refused one stays. Null [live] is a list still loading.
  void useMembershipRows<I extends SelectableIdentifier>({
    required MembershipList list,
    required HoldRows rows,
    required Set<I>? live,
  }) {
    final shown = watch(membershipRowsProvider);
    useEffect(() {
      shown.show(list, rows);
      return () => shown.hide(list, rows);
    }, [shown, list, rows]);
    useEffect(() {
      if (live == null) return null;
      final gone = read(selectionProvider)
          .whereType<I>()
          .where((id) => !live.contains(id))
          .toList();
      if (gone.isNotEmpty) {
        // The selection changes after this build, as a provider may not
        // change while the tree builds.
        final selection = read(selectionProvider.notifier);
        Future.microtask(() => selection.unselectAll(gone));
      }
      return null;
    }, [live]);
  }
}
