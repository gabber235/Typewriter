import "package:typewriter_panel/typewriter_panel.dart";

/// A table of selectable rows on a surface, filling the rest of the scroll
/// view: a header row and one column per label in [labels]. The members and
/// join code tables share it.
///
/// Each row is one [Selector] on the row's own focus node, in the page's
/// [SelectionSurface]: the first cell holds it, with the item's check in
/// select mode, and a click anywhere on the row selects through it. Rows
/// change nothing themselves: the inspector, the context menu and their
/// keys run the selection's operations. The first labelled column is the
/// row's main text, where a hold shows its line and refusal.
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
    this.hasScrollBody = true,
    super.key,
  });

  final AnimatedRows<T> rows;
  final SelectableIdentifier Function(T item) selectableOf;

  /// What a screen reader names the row by.
  final String Function(T item) labelOf;

  /// The labelled columns after the selector column.
  final List<String> labels;
  final Map<int, TableColumnWidth> columnWidths;
  final WidgetBuilder emptyBuilder;

  /// The selector cell's content beside the check, such as an avatar.
  final Widget Function(BuildContext context, T item) leadingBuilder;

  /// The row's cells after the selector cell, one per label.
  final List<Widget> Function(BuildContext context, T item) cellsBuilder;
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
                  child: RowStop.attachedByChild(
                    bounds: RingBounds.tableRow,
                    borderRadius: context.shapes.mediumBorderRadius,
                    child: Selector(
                      selectableId: selectable,
                      focusNode: entry.focus,
                      link: link,
                      builder: (_, _, _) => Semantics(
                        label: labelOf(item),
                        child: Padding(
                          padding: cellPadding,
                          child: SelectorCheck(
                            child: leadingBuilder(context, item),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                for (final cell in cellsBuilder(context, item))
                  TableCell(
                    child: RowStop(
                      role: RowRole.part,
                      child: SelectorLinkRegion(link: link, child: cell),
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
/// in place and changes nothing itself. In select mode each card shows its
/// check at its corner.
class SelectionCardList<T> extends HookConsumerWidget {
  const SelectionCardList({
    required this.rows,
    required this.selectableOf,
    required this.labelOf,
    required this.emptyBuilder,
    required this.contentBuilder,
    super.key,
  });

  final AnimatedRows<T> rows;
  final SelectableIdentifier Function(T item) selectableOf;

  /// What a screen reader names the card by.
  final String Function(T item) labelOf;
  final WidgetBuilder emptyBuilder;
  final Widget Function(BuildContext context, T item) contentBuilder;

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
                      child: contentBuilder(context, item),
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

/// A [SelectionCardList] card while its list loads: an avatar, a name over
/// an email, and [trailing] where the card shows more.
class SelectionCardShimmer extends StatelessWidget {
  const SelectionCardShimmer({this.trailing, super.key});

  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Surface(
      color: Surface.colorOf(context),
      child: Padding(
        padding: EdgeInsets.all(context.spacing.space3),
        child: Row(
          spacing: context.spacing.space3,
          children: [
            const ShimmerBox.circle(width: 40, height: 40),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: context.spacing.space2,
                children: [
                  ShimmerBox.rectangle(width: 140, height: 15),
                  ShimmerBox.rectangle(width: 210, height: 13),
                ],
              ),
            ),
            ?trailing,
          ],
        ),
      ),
    );
  }
}

/// Publishes a membership page's rows.
extension MembershipRowsUpkeep on WidgetRef {
  /// Publishes [rows] as the rows of [list] while the calling widget is
  /// mounted.
  void useMembershipRows({
    required MembershipList list,
    required HoldRows rows,
  }) {
    final shown = watch(membershipRowsProvider);
    useEffect(() {
      shown.show(list, rows);
      return () => shown.hide(list, rows);
    }, [shown, list, rows]);
  }
}
